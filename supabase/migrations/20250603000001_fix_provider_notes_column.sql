-- =============================================================================
-- FIX PROVIDER NOTES COLUMN ISSUE
-- =============================================================================
-- This migration fixes the issue where some functions reference 'provider_notes' 
-- column that doesn't exist in the appointment_purchases table.

-- =============================================================================
-- 1. ADD PROVIDER_NOTES COLUMN FOR BACKWARD COMPATIBILITY
-- =============================================================================

-- Add provider_notes column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'appointment_purchases' 
    AND column_name = 'provider_notes'
    AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.appointment_purchases 
    ADD COLUMN provider_notes TEXT;
    
    COMMENT ON COLUMN public.appointment_purchases.provider_notes IS 
    'Notes from the provider about the appointment (separate from client notes)';
  END IF;
END $$;

-- =============================================================================
-- 2. UPDATE EXISTING RESPOND_TO_APPOINTMENT_REQUEST FUNCTION
-- =============================================================================

-- Drop and recreate the function with proper column names
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(uuid, text, timestamptz, text, text) CASCADE;

CREATE OR REPLACE FUNCTION public.respond_to_appointment_request(
  p_appointment_id UUID,
  p_action TEXT,
  p_alternative_time TIMESTAMPTZ DEFAULT NULL,
  p_provider_notes TEXT DEFAULT NULL,
  p_base_url TEXT DEFAULT '/checkout/appointment'
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_appointment_record RECORD;
    v_result JSONB;
    v_new_status TEXT;
    v_payment_url TEXT;
BEGIN
    -- Get appointment details
    SELECT 
        ap.*,
        p.user_id AS client_id,
        p.owner_id AS provider_id,
        p.payment_status,
        p.amount AS price,
        s.post_id,
        s.type AS service_type,
        COALESCE(po.title, s.name, 'Service') AS service_name
    INTO v_appointment_record
    FROM 
        public.appointment_purchases ap
        JOIN public.purchases p ON ap.purchase_id = p.id
        JOIN public.services s ON ap.service_id = s.id
        LEFT JOIN public.posts po ON s.post_id = po.id
    WHERE 
        ap.id = p_appointment_id;
    
    -- Check if appointment exists
    IF v_appointment_record.id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Appointment not found'
        );
    END IF;
    
    -- Check if the current user is the provider
    IF v_appointment_record.provider_id != auth.uid() THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'You are not authorized to respond to this appointment request'
        );
    END IF;
    
    -- Process the action
    CASE p_action
        WHEN 'confirm' THEN
            -- Check if the appointment needs confirmation
            IF v_appointment_record.status NOT IN ('pending_approval', 'pending_reschedule') THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'This appointment is not in a state that can be confirmed'
                );
            END IF;
            
            -- Set new status to pending_payment or confirmed based on payment status
            IF v_appointment_record.payment_status = 'completed' THEN
                v_new_status := 'confirmed';
            ELSE
                v_new_status := 'pending_payment';
                
                -- Generate payment URL
                v_payment_url := p_base_url || '/' || v_appointment_record.id;
            END IF;
            
            -- Update appointment
            UPDATE public.appointment_purchases
            SET 
                status = v_new_status::appointment_status_enum,
                provider_notes = p_provider_notes,
                updated_at = NOW()
            WHERE 
                id = p_appointment_id;
            
            v_new_status := v_new_status;
            
        WHEN 'reject' THEN
            -- Update appointment to cancelled
            UPDATE public.appointment_purchases
            SET 
                status = 'cancelled'::appointment_status_enum,
                provider_notes = p_provider_notes,
                updated_at = NOW()
            WHERE 
                id = p_appointment_id;
            
            v_new_status := 'cancelled';
            
        WHEN 'suggest' THEN
            -- Check if alternative time is provided
            IF p_alternative_time IS NULL THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Alternative time must be provided for suggestion'
                );
            END IF;
            
            -- Update appointment to pending reschedule
            UPDATE public.appointment_purchases
            SET 
                status = 'pending_reschedule'::appointment_status_enum,
                provider_notes = p_provider_notes,
                metadata = jsonb_build_object(
                    'alternative_time', p_alternative_time,
                    'original_time', v_appointment_record.appointment_date
                ),
                updated_at = NOW()
            WHERE 
                id = p_appointment_id;
            
            v_new_status := 'pending_reschedule';
            
        ELSE
            RETURN jsonb_build_object(
                'success', FALSE,
                'error', 'Invalid action. Valid actions are: confirm, reject, suggest'
            );
    END CASE;
    
    -- Build result
    v_result := jsonb_build_object(
        'success', TRUE,
        'appointment_id', p_appointment_id,
        'status', v_new_status,
        'action', p_action,
        'client_id', v_appointment_record.client_id,
        'provider_id', v_appointment_record.provider_id,
        'appointment_date', v_appointment_record.appointment_date
    );
    
    -- Add alternative time if provided
    IF p_alternative_time IS NOT NULL THEN
        v_result := v_result || jsonb_build_object('alternative_time', p_alternative_time);
    END IF;
    
    -- Add payment URL if generated
    IF v_payment_url IS NOT NULL THEN
        v_result := v_result || jsonb_build_object('payment_url', v_payment_url);
    END IF;
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', FALSE,
        'error', SQLERRM,
        'detail', SQLSTATE
    );
END $$;

-- =============================================================================
-- 3. UPDATE THE NEW SIMPLIFIED FUNCTIONS TO USE PROVIDER_NOTES PROPERLY
-- =============================================================================

-- Update the respond_to_appointment_request function from the new migrations to also use provider_notes
CREATE OR REPLACE FUNCTION public.respond_to_appointment_request_v2(
  p_appointment_id UUID,
  p_action TEXT,
  p_quoted_price NUMERIC DEFAULT NULL,
  p_payment_link TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
  CASE p_action
    WHEN 'approve' THEN
      IF p_quoted_price IS NULL OR p_payment_link IS NULL THEN
        RAISE EXCEPTION 'Quoted price and payment link required for approval';
      END IF;
      
      v_result := public.approve_appointment_request(
        p_appointment_id,
        p_quoted_price,
        p_payment_link,
        p_notes
      );
      
    WHEN 'reject' THEN
      -- Update appointment status to cancelled
      UPDATE public.appointment_purchases
      SET 
        status = 'cancelled',
        provider_notes = p_notes,  -- Use provider_notes for rejection reason
        updated_at = now()
      WHERE id = p_appointment_id
        AND status = 'pending_approval';
      
      -- Update chat message if room exists
      PERFORM public.update_appointment_chat_message(
        p_appointment_id,
        'cancelled',
        NULL,
        NULL
      );
      
      v_result := json_build_object(
        'success', true,
        'appointment_id', p_appointment_id,
        'status', 'cancelled',
        'action', 'rejected',
        'provider_notes', p_notes
      );
      
    ELSE
      RAISE EXCEPTION 'Invalid action. Must be "approve" or "reject"';
  END CASE;

  RETURN v_result;
END $$;

-- =============================================================================
-- 4. CREATE INDEXES FOR PERFORMANCE
-- =============================================================================

-- Index for provider_notes for text search if needed
CREATE INDEX IF NOT EXISTS idx_appointment_purchases_provider_notes 
  ON public.appointment_purchases USING gin (to_tsvector('english', provider_notes))
  WHERE provider_notes IS NOT NULL;

-- =============================================================================
-- 5. COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION public.respond_to_appointment_request(uuid, text, timestamptz, text, text) IS 
'Updated function to handle appointment responses with proper provider_notes column support. Handles confirm, reject, and suggest actions.';

COMMENT ON FUNCTION public.respond_to_appointment_request_v2(uuid, text, numeric, text, text) IS 
'Simplified version of appointment response function that focuses on approve/reject actions only with provider_notes support.';

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

-- Summary of changes:
-- 1. Added provider_notes column to appointment_purchases table
-- 2. Updated respond_to_appointment_request function to use correct column names
-- 3. Created v2 function that properly handles provider_notes for rejection
-- 4. Added appropriate indexes and documentation
-- 5. All functions now properly handle the provider_notes field 