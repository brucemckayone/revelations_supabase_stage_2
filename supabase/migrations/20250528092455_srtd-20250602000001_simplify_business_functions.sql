-- Generated with srtd from template: supabase/migrations-templates/20250602000001_simplify_business_functions.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- =============================================================================
-- SIMPLIFY BUSINESS FUNCTIONS - REMOVE MANUAL NOTIFICATION CREATION  
-- =============================================================================
-- This migration simplifies business logic functions by removing manual 
-- notification creation. All notifications are now handled by the
-- handle_appointment_notifications() trigger function.

-- Drop all existing appointment functions (since they need to be rewritten)
DROP FUNCTION IF EXISTS public.approve_appointment_request(uuid, numeric, text, text) CASCADE;
DROP FUNCTION IF EXISTS public.process_appointment_payment_confirmation(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(uuid, text, numeric, text, text) CASCADE;
DROP FUNCTION IF EXISTS public.process_appointment_payment_v2(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.auto_confirm_appointment_v2(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.update_appointment_with_meeting_link(uuid, text) CASCADE;

-- ========================================
-- Updated Appointment Business Functions
-- Using Specialized Chat Channels System
-- ========================================


-- Simplified appointment approval function
CREATE FUNCTION public.approve_appointment_request(
  p_appointment_id UUID,
  p_quoted_price NUMERIC,
  p_payment_link TEXT,
  p_notes TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_chat_room_id UUID;
  v_message_id UUID;
  v_result JSON;
BEGIN
  -- Get appointment details with locks to prevent race conditions
  SELECT 
    ap.*,
    p.title as service_name,
    pu.owner_id,
    COALESCE(uc.full_name, 'Unknown Client') as client_name,
    COALESCE(uo.full_name, 'Unknown Provider') as owner_name,
    pu.user_id as client_id
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  JOIN public.profiles uc ON pu.user_id = uc.id
  JOIN public.profiles uo ON pu.owner_id = uo.id
  WHERE ap.id = p_appointment_id
    AND ap.status = 'pending_approval'
  FOR UPDATE;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found or not in pending approval status';
  END IF;

  -- Update appointment status and price
  UPDATE public.appointment_purchases
  SET 
    status = 'pending_payment',
    quoted_price = p_quoted_price,
    payment_link = p_payment_link,
    notes = COALESCE(p_notes, notes),
    updated_at = now()
  WHERE id = p_appointment_id;

  -- Get or create specialized appointment chat room
  v_chat_room_id := public.get_or_create_appointment_chat(
    p_appointment_id,
    v_appointment.client_id,
    v_appointment.owner_id,
    v_appointment.service_name,
    v_appointment.requested_date
  );

  -- Update appointment status message in specialized chat
  v_message_id := public.update_appointment_chat_message(
    p_appointment_id,
    'pending_payment',
    p_payment_link,
    NULL -- no meeting URL yet
  );

  -- Build response
  v_result := json_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', 'pending_payment',
    'quoted_price', p_quoted_price,
    'payment_link', p_payment_link,
    'chat_room_id', v_chat_room_id,
    'message_id', v_message_id,
    'client_name', v_appointment.client_name,
    'service_name', v_appointment.service_name,
    'appointment_date', v_appointment.requested_date
  );

  RETURN v_result;
END $$;

-- Payment confirmation function with specialized chat integration
CREATE FUNCTION public.process_appointment_payment_confirmation(
  p_purchase_id UUID,
  p_payment_intent_id TEXT
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_chat_room_id UUID;
  v_message_id UUID;
  v_result JSON;
  v_user_id UUID;
  v_owner_id UUID;
  v_appointment_id UUID;
BEGIN
  -- Update purchase status and get user details
  UPDATE public.purchases
  SET 
    payment_status = 'completed'::purchase_payment_status_enum,
    completed_at = NOW(),
    updated_at = NOW(),
    stripe_payment_intent_id = p_payment_intent_id
  WHERE id = p_purchase_id
  RETURNING user_id, owner_id INTO v_user_id, v_owner_id;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Purchase not found: %', p_purchase_id;
  END IF;

  -- Get appointment details
  SELECT 
    ap.*,
    p.title as service_name,
    pu.owner_id,
    uc.full_name as client_name,
    uo.full_name as owner_name
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  JOIN public.profiles uc ON pu.user_id = uc.id
  JOIN public.profiles uo ON pu.owner_id = uo.id
  WHERE ap.purchase_id = p_purchase_id
    AND ap.status = 'pending_payment'
  FOR UPDATE;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found or not in pending payment status';
  END IF;

  v_appointment_id := v_appointment.id;

  -- Update appointment status
  UPDATE public.appointment_purchases
  SET 
    status = 'confirmed',
    updated_at = now()
  WHERE id = v_appointment_id;

  -- Get existing appointment chat room
  SELECT id INTO v_chat_room_id
  FROM public.chat_rooms
  WHERE associated_appointment_id = v_appointment_id
    AND type = 'appointment_booking';



  -- Update appointment status message with confirmation
  v_message_id := public.update_appointment_chat_message(
    v_appointment_id,
    'confirmed',
    NULL, -- remove payment link
    NULL -- meeting URL can be added later
  );

  -- Build response
  v_result := json_build_object(
    'success', true,
    'purchase_id', p_purchase_id,
    'appointment_id', v_appointment_id,
    'status', 'confirmed',
    'payment_intent_id', p_payment_intent_id,
    'chat_room_id', v_chat_room_id,
    'message_id', v_message_id
  );

  RETURN v_result;
END $$;

-- Combined approval and payment function for direct payments
CREATE FUNCTION public.respond_to_appointment_request(
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
        notes = COALESCE(p_notes, notes),
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
        'action', 'rejected'
      );
      
    ELSE
      RAISE EXCEPTION 'Invalid action. Must be "approve" or "reject"';
  END CASE;

  RETURN v_result;
END $$;

-- Payment processing function for Stripe webhooks (renamed to avoid conflict)
CREATE FUNCTION public.process_appointment_payment_v2(
  p_appointment_id UUID,
  p_payment_status TEXT
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
  CASE p_payment_status
    WHEN 'completed' THEN
      v_result := public.process_appointment_payment_confirmation(
        p_appointment_id,
        'stripe_webhook_' || extract(epoch from now())::text
      );
      
    WHEN 'failed' THEN
      -- Reset to pending_payment status
      UPDATE public.appointment_purchases
      SET 
        status = 'pending_payment',
        updated_at = now()
      WHERE id = p_appointment_id;
      
      -- Update chat message to show payment failure
      PERFORM public.update_appointment_chat_message(
        p_appointment_id,
        'pending_payment',
        (SELECT payment_link FROM public.appointment_purchases WHERE id = p_appointment_id),
        NULL
      );
      
      v_result := json_build_object(
        'success', true,
        'appointment_id', p_appointment_id,
        'status', 'pending_payment',
        'message', 'Payment failed, please retry'
      );
      
    ELSE
      RAISE EXCEPTION 'Invalid payment status: %', p_payment_status;
  END CASE;

  RETURN v_result;
END $$;

-- Auto-confirmation function for pre-paid services (renamed to avoid conflict)
CREATE FUNCTION public.auto_confirm_appointment_v2(
  p_appointment_id UUID
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_chat_room_id UUID;
  v_message_id UUID;
  v_result JSON;
BEGIN
  -- Get appointment details
  SELECT 
    ap.*,
    p.title as service_name,
    pu.user_id as client_id,
    pu.owner_id,
    ap.appointment_date as requested_date
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  WHERE ap.id = p_appointment_id
    AND ap.status IN ('pending_approval', 'pending_auto_payment')
  FOR UPDATE;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found or not eligible for auto-confirmation';
  END IF;

  -- Auto-confirm the appointment to pending_payment status (skip approval, but still need payment)
  UPDATE public.appointment_purchases
  SET 
    status = 'pending_payment',
    updated_at = now()
  WHERE id = p_appointment_id;

  -- Get or create specialized appointment chat room
  v_chat_room_id := public.get_or_create_appointment_chat(
    p_appointment_id,
    v_appointment.client_id,
    v_appointment.owner_id,
    v_appointment.service_name,
    v_appointment.requested_date
  );

  -- Update appointment status message
  v_message_id := public.update_appointment_chat_message(
    p_appointment_id,
    'pending_payment',
    v_appointment.payment_link, -- include payment link for pending_payment status
    NULL
  );

  -- Build response
  v_result := json_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', 'pending_payment',
    'chat_room_id', v_chat_room_id,
    'message_id', v_message_id,
    'auto_confirmed', true
  );

  RETURN v_result;
END $$;

-- ========================================
-- Enhanced Chat Integration Function
-- ========================================

-- Function to handle appointment updates with meeting links
CREATE FUNCTION public.update_appointment_with_meeting_link(
  p_appointment_id UUID,
  p_meeting_url TEXT
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_message_id UUID;
BEGIN
  -- Get current appointment
  SELECT status INTO v_appointment
  FROM public.appointment_purchases
  WHERE id = p_appointment_id;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found';
  END IF;

  -- Update appointment with meeting URL
  UPDATE public.appointment_purchases
  SET 
    meeting_url = p_meeting_url,
    updated_at = now()
  WHERE id = p_appointment_id;

  -- Update chat message with meeting link
  v_message_id := public.update_appointment_chat_message(
    p_appointment_id,
    v_appointment.status,
    NULL, -- no payment URL for confirmed appointments
    p_meeting_url
  );

  RETURN json_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'meeting_url', p_meeting_url,
    'message_id', v_message_id
  );
END $$;

-- ========================================
-- Function Comments
-- ========================================

COMMENT ON FUNCTION public.approve_appointment_request(uuid, numeric, text, text) IS 
'Simplified appointment approval function using specialized chat channels. Creates appointment-specific chat room and living status messages.';

COMMENT ON FUNCTION public.process_appointment_payment_confirmation(uuid, text) IS 
'Payment confirmation function that updates specialized appointment chat with confirmed status and removes payment actions. Uses purchase_id and payment_intent_id parameters for future multi-appointment support.';

COMMENT ON FUNCTION public.respond_to_appointment_request(uuid, text, numeric, text, text) IS 
'Unified function to approve or reject appointment requests with specialized chat integration.';

COMMENT ON FUNCTION public.process_appointment_payment_v2(uuid, text) IS 
'Processes payment status updates from Stripe webhooks with specialized chat integration. V2 to avoid conflicts.';

COMMENT ON FUNCTION public.auto_confirm_appointment_v2(uuid) IS 
'Auto-confirms appointments for services that skip manual approval, moving them to pending_payment status with specialized chat room creation. V2 to avoid conflicts.';

COMMENT ON FUNCTION public.update_appointment_with_meeting_link(uuid, text) IS 
'Updates appointment with meeting URL and refreshes chat message with join meeting button.';

-- =============================================================================
-- SUMMARY OF CHANGES:
-- =============================================================================
-- 1. approve_appointment_request() simplified to focus on status updates and payment links
-- 2. process_appointment_payment() simplified to handle payment logic only  
-- 3. auto_confirm_appointment() updated to use simplified approval function
-- 4. respond_to_appointment_request() simplified to remove manual notifications
-- 5. process_appointment_payment_confirmation() simplified to focus on business logic
-- 
-- All notification creation is now handled by the handle_appointment_notifications() trigger function

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

-- Summary of changes:
-- 1. approve_appointment_request() simplified - removes all manual notification logic
-- 2. process_appointment_payment() simplified - removes notification logic  
-- 3. auto_confirm_appointment() updated to use simplified approval function
-- 4. All notifications now handled consistently by trigger system
-- 5. Business logic functions focus on their core responsibilities
-- 6. Consistent patterns and better maintainability 

-- =============================================================================
-- RESCHEDULE WORKFLOW FUNCTIONS
-- =============================================================================

drop function if exists public.request_appointment_reschedule;
-- Function for client to request reschedule with suggested times
CREATE FUNCTION public.request_appointment_reschedule(
  p_appointment_id UUID,
  p_suggested_times JSONB, -- Array of suggested datetime objects
  p_client_notes TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_chat_room_id UUID;
  v_message_id UUID;
  v_result JSON;
BEGIN
  -- Get appointment details
  SELECT 
    ap.*,
    p.title as service_name,
    pu.user_id as client_id,
    pu.owner_id,
    COALESCE(uc.full_name, 'Unknown Client') as client_name,
    COALESCE(uo.full_name, 'Unknown Provider') as owner_name
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  JOIN public.profiles uc ON pu.user_id = uc.id
  JOIN public.profiles uo ON pu.owner_id = uo.id
  WHERE ap.id = p_appointment_id
    AND ap.status NOT IN ('cancelled', 'completed')
    AND pu.user_id = auth.uid() -- Only client can request reschedule
  FOR UPDATE;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found or cannot be rescheduled';
  END IF;

  -- Update appointment status to pending_reschedule
  UPDATE public.appointment_purchases
  SET 
    status = 'pending_reschedule',
    metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
      'reschedule_request', jsonb_build_object(
        'suggested_times', p_suggested_times,
        'client_notes', p_client_notes,
        'requested_at', extract(epoch from now()),
        'original_date', v_appointment.appointment_date
      )
    ),
    updated_at = now()
  WHERE id = p_appointment_id;

  -- Get chat room for this appointment
  SELECT id INTO v_chat_room_id
  FROM public.chat_rooms
  WHERE associated_appointment_id = p_appointment_id
    AND type = 'appointment_booking';

  -- Create reschedule request message
  IF v_chat_room_id IS NOT NULL THEN
    v_message_id := public.update_appointment_chat_message(
      p_appointment_id,
      'pending_reschedule',
      NULL,
      NULL
    );
  END IF;

  -- Build response
  v_result := json_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', 'pending_reschedule',
    'chat_room_id', v_chat_room_id,
    'message_id', v_message_id,
    'suggested_times', p_suggested_times,
    'original_date', v_appointment.appointment_date
  );

  RETURN v_result;
END $$;

drop function if exists public.accept_reschedule_time;
-- Function for provider to accept a suggested reschedule time
CREATE FUNCTION public.accept_reschedule_time(
  p_appointment_id UUID,
  p_new_datetime TIMESTAMPTZ,
  p_provider_notes TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_chat_room_id UUID;
  v_message_id UUID;
  v_result JSON;
  v_original_date TIMESTAMPTZ;
BEGIN
  -- Get appointment details
  SELECT 
    ap.*,
    p.title as service_name,
    pu.user_id as client_id,
    pu.owner_id,
    COALESCE(uc.full_name, 'Unknown Client') as client_name,
    COALESCE(uo.full_name, 'Unknown Provider') as owner_name
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  JOIN public.profiles uc ON pu.user_id = uc.id
  JOIN public.profiles uo ON pu.owner_id = uo.id
  WHERE ap.id = p_appointment_id
    AND ap.status = 'pending_reschedule'
    AND pu.owner_id = auth.uid() -- Only provider can accept reschedule
  FOR UPDATE;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found or not in reschedule status';
  END IF;

  v_original_date := v_appointment.appointment_date;

  -- Update appointment with new time
  UPDATE public.appointment_purchases
  SET 
    appointment_date = p_new_datetime,
    status = 'confirmed',
    provider_notes = p_provider_notes,
    metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
      'reschedule_history', COALESCE(metadata->'reschedule_history', '[]'::jsonb) || 
        jsonb_build_array(jsonb_build_object(
          'original_date', v_original_date,
          'new_date', p_new_datetime,
          'rescheduled_at', extract(epoch from now()),
          'provider_notes', p_provider_notes,
          'rescheduled_by', 'provider'
        ))
    ),
    updated_at = now()
  WHERE id = p_appointment_id;

  -- Get chat room for this appointment
  SELECT id INTO v_chat_room_id
  FROM public.chat_rooms
  WHERE associated_appointment_id = p_appointment_id
    AND type = 'appointment_booking';

  -- Update chat message
  IF v_chat_room_id IS NOT NULL THEN
    v_message_id := public.update_appointment_chat_message(
      p_appointment_id,
      'confirmed',
      NULL,
      NULL
    );
  END IF;

  -- Build response
  v_result := json_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', 'confirmed',
    'original_date', v_original_date,
    'new_date', p_new_datetime,
    'chat_room_id', v_chat_room_id,
    'message_id', v_message_id,
    'provider_notes', p_provider_notes
  );

  RETURN v_result;
END $$;

drop function if exists public.propose_alternative_reschedule_times;
-- Function for provider to propose alternative times when client suggestions don't work
CREATE FUNCTION public.propose_alternative_reschedule_times(
  p_appointment_id UUID,
  p_alternative_times JSONB,
  p_provider_notes TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_chat_room_id UUID;
  v_message_id UUID;
  v_result JSON;
BEGIN
  -- Get appointment details
  SELECT 
    ap.*,
    p.title as service_name,
    pu.user_id as client_id,
    pu.owner_id,
    COALESCE(uc.full_name, 'Unknown Client') as client_name,
    COALESCE(uo.full_name, 'Unknown Provider') as owner_name
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  JOIN public.profiles uc ON pu.user_id = uc.id
  JOIN public.profiles uo ON pu.owner_id = uo.id
  WHERE ap.id = p_appointment_id
    AND ap.status = 'pending_reschedule'
    AND pu.owner_id = auth.uid() -- Only provider can propose alternatives
  FOR UPDATE;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found or not in reschedule status';
  END IF;

  -- Update appointment metadata with provider's alternative suggestions
  UPDATE public.appointment_purchases
  SET 
    metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
      'provider_alternatives', jsonb_build_object(
        'suggested_times', p_alternative_times,
        'provider_notes', p_provider_notes,
        'proposed_at', extract(epoch from now())
      )
    ),
    provider_notes = p_provider_notes,
    updated_at = now()
  WHERE id = p_appointment_id;

  -- Get chat room for this appointment
  SELECT id INTO v_chat_room_id
  FROM public.chat_rooms
  WHERE associated_appointment_id = p_appointment_id
    AND type = 'appointment_booking';

  -- Update chat message (status stays pending_reschedule)
  IF v_chat_room_id IS NOT NULL THEN
    v_message_id := public.update_appointment_chat_message(
      p_appointment_id,
      'pending_reschedule',
      NULL,
      NULL
    );
  END IF;

  -- Build response
  v_result := json_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', 'pending_reschedule',
    'alternative_times', p_alternative_times,
    'chat_room_id', v_chat_room_id,
    'message_id', v_message_id,
    'provider_notes', p_provider_notes
  );

  RETURN v_result;
END $$;

drop function if exists public.accept_alternative_reschedule_time;
-- Function for client to accept provider's alternative time
CREATE FUNCTION public.accept_alternative_reschedule_time(
  p_appointment_id UUID,
  p_selected_datetime TIMESTAMPTZ,
  p_client_notes TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_chat_room_id UUID;
  v_message_id UUID;
  v_result JSON;
  v_original_date TIMESTAMPTZ;
BEGIN
  -- Get appointment details
  SELECT 
    ap.*,
    p.title as service_name,
    pu.user_id as client_id,
    pu.owner_id,
    COALESCE(uc.full_name, 'Unknown Client') as client_name,
    COALESCE(uo.full_name, 'Unknown Provider') as owner_name
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  JOIN public.profiles uc ON pu.user_id = uc.id
  JOIN public.profiles uo ON pu.owner_id = uo.id
  WHERE ap.id = p_appointment_id
    AND ap.status = 'pending_reschedule'
    AND pu.user_id = auth.uid() -- Only client can accept alternatives
  FOR UPDATE;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found or not in reschedule status';
  END IF;

  v_original_date := v_appointment.appointment_date;

  -- Update appointment with selected time
  UPDATE public.appointment_purchases
  SET 
    appointment_date = p_selected_datetime,
    status = 'confirmed',
    notes = COALESCE(notes, '') || 
      CASE WHEN notes IS NOT NULL AND notes != '' THEN E'\n\n' ELSE '' END ||
      'Client accepted alternative time: ' || COALESCE(p_client_notes, 'No additional notes'),
    metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
      'reschedule_history', COALESCE(metadata->'reschedule_history', '[]'::jsonb) || 
        jsonb_build_array(jsonb_build_object(
          'original_date', v_original_date,
          'new_date', p_selected_datetime,
          'rescheduled_at', extract(epoch from now()),
          'client_notes', p_client_notes,
          'rescheduled_by', 'client_accepted_alternative'
        ))
    ),
    updated_at = now()
  WHERE id = p_appointment_id;

  -- Get chat room for this appointment
  SELECT id INTO v_chat_room_id
  FROM public.chat_rooms
  WHERE associated_appointment_id = p_appointment_id
    AND type = 'appointment_booking';

  -- Update chat message
  IF v_chat_room_id IS NOT NULL THEN
    v_message_id := public.update_appointment_chat_message(
      p_appointment_id,
      'confirmed',
      NULL,
      NULL
    );
  END IF;

  -- Build response
  v_result := json_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', 'confirmed',
    'original_date', v_original_date,
    'new_date', p_selected_datetime,
    'chat_room_id', v_chat_room_id,
    'message_id', v_message_id,
    'client_notes', p_client_notes
  );

  RETURN v_result;
END $$;

-- Function to get available times for rescheduling (uses existing calendar availability)
drop function if exists public.get_reschedule_availability;
CREATE FUNCTION public.get_reschedule_availability(
  p_appointment_id UUID,
  p_days_ahead INTEGER DEFAULT 30
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_service_id UUID;
  v_provider_id UUID;
  v_duration INTEGER;
  v_availability JSONB;
BEGIN
  -- Get appointment details
  SELECT 
    ap.service_id,
    pu.owner_id,
    ap.duration
  INTO v_service_id, v_provider_id, v_duration
  FROM public.appointment_purchases ap
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  WHERE ap.id = p_appointment_id;

  IF v_service_id IS NULL THEN
    RETURN jsonb_build_object('error', 'Appointment not found');
  END IF;

  -- Get service calendar availability using existing function
  SELECT public.get_service_calendar_availability(v_service_id, p_days_ahead) INTO v_availability;

  -- Add appointment context
  v_availability := v_availability || jsonb_build_object(
    'appointment_id', p_appointment_id,
    'duration', v_duration,
    'context', 'reschedule'
  );

  RETURN v_availability;
END $$;

-- =============================================================================
-- RESCHEDULE FUNCTION COMMENTS
-- =============================================================================

COMMENT ON FUNCTION public.request_appointment_reschedule(uuid, jsonb, text) IS 
'Client function to request appointment reschedule with suggested times. Updates status to pending_reschedule and stores suggestions in metadata.';

COMMENT ON FUNCTION public.accept_reschedule_time(uuid, timestamptz, text) IS 
'Provider function to accept one of the client-suggested reschedule times. Updates appointment date and confirms the booking.';

COMMENT ON FUNCTION public.propose_alternative_reschedule_times(uuid, jsonb, text) IS 
'Provider function to propose alternative times when client suggestions are not available. Keeps status as pending_reschedule.';

COMMENT ON FUNCTION public.accept_alternative_reschedule_time(uuid, timestamptz, text) IS 
'Client function to accept one of the provider-proposed alternative times. Updates appointment date and confirms the booking.';

COMMENT ON FUNCTION public.get_reschedule_availability(uuid, integer) IS 
'Gets available times for rescheduling a specific appointment using the existing calendar availability system.';



COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
