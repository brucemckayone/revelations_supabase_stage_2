-- Generated with srtd from template: supabase/migrations-templates/20250602000000_refactor_payment_system.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- =============================================================================
-- PAYMENT SYSTEM REFACTOR - COMPREHENSIVE CLEANUP AND ENHANCEMENT
-- =============================================================================
-- This migration refactors the payment system to be more robust and eliminate 
-- null content notification issues mentioned in the conversation.

-- =============================================================================
-- 1. EXTEND PAYMENT STATUS ENUM
-- =============================================================================

-- Add canceled status to payment enum
ALTER TYPE public.purchase_payment_status_enum ADD VALUE IF NOT EXISTS 'canceled';

-- =============================================================================
-- 2. ENHANCE APPOINTMENT_PURCHASES TABLE
-- =============================================================================

-- Add better payment tracking fields
DO $$
BEGIN
  -- Add payment reference for better tracking
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'appointment_purchases' 
    AND column_name = 'payment_reference'
  ) THEN
    ALTER TABLE public.appointment_purchases 
    ADD COLUMN payment_reference TEXT;
  END IF;

  -- Add payment method tracking
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'appointment_purchases' 
    AND column_name = 'payment_method'
  ) THEN
    ALTER TABLE public.appointment_purchases 
    ADD COLUMN payment_method TEXT;
  END IF;

  -- Add payment failure reason
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'appointment_purchases' 
    AND column_name = 'payment_failure_reason'
  ) THEN
    ALTER TABLE public.appointment_purchases 
    ADD COLUMN payment_failure_reason TEXT;
  END IF;

  -- Ensure we have transaction_reference column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'appointment_purchases' 
    AND column_name = 'transaction_reference'
  ) THEN
    ALTER TABLE public.appointment_purchases 
    ADD COLUMN transaction_reference TEXT;
  END IF;
END $$;

-- =============================================================================
-- 3. IMPROVED PAYMENT PROCESSING FUNCTIONS  
-- =============================================================================

-- Enhanced payment processing function with better error handling
CREATE OR REPLACE FUNCTION public.process_payment_webhook(
  p_appointment_id UUID,
  p_payment_status TEXT,
  p_transaction_reference TEXT DEFAULT NULL,
  p_payment_method TEXT DEFAULT NULL,
  p_failure_reason TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_result JSON;
BEGIN
  -- Get appointment with lock
  SELECT * INTO v_appointment
  FROM public.appointment_purchases
  WHERE id = p_appointment_id
  FOR UPDATE;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found: %', p_appointment_id;
  END IF;

  CASE p_payment_status
    WHEN 'completed', 'succeeded' THEN
      -- Update appointment to confirmed
      UPDATE public.appointment_purchases
      SET 
        status = 'confirmed',
        transaction_reference = p_transaction_reference,
        payment_method = p_payment_method,
        payment_failure_reason = NULL,
        confirmed_at = now(),
        updated_at = now()
      WHERE id = p_appointment_id;

      v_result := json_build_object(
        'success', true,
        'appointment_id', p_appointment_id,
        'status', 'confirmed',
        'transaction_reference', p_transaction_reference,
        'message', 'Payment processed successfully'
      );

    WHEN 'failed', 'cancelled', 'canceled' THEN
      -- Update with failure details but keep in pending_payment
      UPDATE public.appointment_purchases
      SET 
        payment_failure_reason = p_failure_reason,
        payment_method = p_payment_method,
        updated_at = now()
      WHERE id = p_appointment_id;

      v_result := json_build_object(
        'success', false,
        'appointment_id', p_appointment_id,
        'status', 'payment_failed',
        'failure_reason', p_failure_reason,
        'message', 'Payment failed - client can retry'
      );

    WHEN 'pending', 'processing' THEN
      -- Update with payment reference but keep pending
      UPDATE public.appointment_purchases
      SET 
        payment_reference = p_transaction_reference,
        payment_method = p_payment_method,
        updated_at = now()
      WHERE id = p_appointment_id;

      v_result := json_build_object(
        'success', true,
        'appointment_id', p_appointment_id,
        'status', 'payment_processing',
        'transaction_reference', p_transaction_reference,
        'message', 'Payment is being processed'
      );

    ELSE
      RAISE EXCEPTION 'Unknown payment status: %', p_payment_status;
  END CASE;

  RETURN v_result;
END $$;

-- =============================================================================
-- 4. PAYMENT LINK GENERATION HELPER
-- =============================================================================

-- Function to generate consistent payment links
CREATE OR REPLACE FUNCTION public.generate_payment_link(
  p_appointment_id UUID,
  p_amount NUMERIC,
  p_currency TEXT DEFAULT 'USD',
  p_description TEXT DEFAULT NULL
) RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_service_name TEXT;
  v_payment_link TEXT;
BEGIN
  -- Get appointment and service details
  SELECT 
    ap.*,
    s.name as service_name,
    p.user_id as client_id
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.purchases p ON ap.purchase_id = p.id
  WHERE ap.id = p_appointment_id;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found: %', p_appointment_id;
  END IF;

  -- Build description if not provided
  IF p_description IS NULL THEN
    p_description := 'Payment for ' || COALESCE(v_appointment.service_name, 'service') ||
                     ' appointment on ' || 
                     to_char(v_appointment.requested_date, 'DD/MM/YYYY HH24:MI');
  END IF;

  -- This would typically integrate with your payment provider (Stripe, etc.)
  -- For now, return a placeholder that can be replaced with actual implementation
  v_payment_link := format(
    '/payments/checkout?appointment_id=%s&amount=%s&currency=%s&description=%s',
    p_appointment_id,
    p_amount,
    p_currency,
    encode(p_description::bytea, 'base64')
  );

  -- Update appointment with payment link
  UPDATE public.appointment_purchases
  SET 
    payment_link = v_payment_link,
    quoted_price = p_amount,
    updated_at = now()
  WHERE id = p_appointment_id;

  RETURN v_payment_link;
END $$;

-- =============================================================================
-- 5. PAYMENT STATUS VALIDATION
-- =============================================================================

-- Function to validate payment status transitions
CREATE OR REPLACE FUNCTION public.validate_payment_status_transition(
  p_current_status TEXT,
  p_new_status TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  -- Define valid status transitions
  CASE p_current_status
    WHEN 'pending_approval' THEN
      RETURN p_new_status IN ('pending_payment', 'pending_auto_payment', 'cancelled');
    WHEN 'pending_payment' THEN
      RETURN p_new_status IN ('confirmed', 'cancelled', 'pending_payment');
    WHEN 'pending_auto_payment' THEN
      RETURN p_new_status IN ('confirmed', 'cancelled');
    WHEN 'confirmed' THEN
      RETURN p_new_status IN ('completed', 'cancelled', 'rescheduled');
    WHEN 'completed' THEN
      RETURN p_new_status IN ('completed'); -- Final state
    WHEN 'cancelled' THEN
      RETURN p_new_status IN ('pending_approval'); -- Allow rebooking
    WHEN 'rescheduled' THEN
      RETURN p_new_status IN ('pending_approval', 'pending_payment', 'confirmed');
    ELSE
      RETURN false;
  END CASE;
END $$;

-- =============================================================================
-- 6. CLEANUP NULL CONTENT ISSUES
-- =============================================================================

-- Update any appointments with null content that might cause notification issues
UPDATE public.appointment_purchases
SET notes = COALESCE(notes, '')
WHERE notes IS NULL;

-- Ensure all payment links are properly formatted or null
UPDATE public.appointment_purchases
SET payment_link = NULL
WHERE payment_link = '' OR payment_link = 'null';

-- =============================================================================
-- 7. INDEXES FOR PERFORMANCE
-- =============================================================================

-- Index for payment reference lookups
CREATE INDEX IF NOT EXISTS idx_appointment_purchases_payment_reference 
ON public.appointment_purchases (payment_reference) 
WHERE payment_reference IS NOT NULL;

-- Index for transaction reference lookups
CREATE INDEX IF NOT EXISTS idx_appointment_purchases_transaction_reference 
ON public.appointment_purchases (transaction_reference) 
WHERE transaction_reference IS NOT NULL;

-- Index for payment method analytics
CREATE INDEX IF NOT EXISTS idx_appointment_purchases_payment_method 
ON public.appointment_purchases (payment_method) 
WHERE payment_method IS NOT NULL;

-- =============================================================================
-- 8. COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION public.process_payment_webhook(UUID, TEXT, TEXT, TEXT, TEXT) IS 
'Processes payment webhook updates with comprehensive error handling and status tracking.';

COMMENT ON FUNCTION public.generate_payment_link(UUID, NUMERIC, TEXT, TEXT) IS 
'Generates consistent payment links for appointments with proper descriptions.';

COMMENT ON FUNCTION public.validate_payment_status_transition(TEXT, TEXT) IS 
'Validates that appointment status transitions follow business rules.';

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

-- Summary of changes:
-- 1. Enhanced appointment_purchases table with better payment tracking
-- 2. Comprehensive payment webhook processing function
-- 3. Payment link generation helper
-- 4. Payment status validation
-- 5. Cleanup of null content issues
-- 6. Performance indexes for payment lookups
-- 7. Proper documentation and comments 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
