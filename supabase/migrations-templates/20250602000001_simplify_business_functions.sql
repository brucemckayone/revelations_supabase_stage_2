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
  p_appointment_id UUID,
  p_transaction_reference TEXT
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
  WHERE ap.id = p_appointment_id
    AND ap.status = 'pending_payment'
  FOR UPDATE;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found or not in pending payment status';
  END IF;

  -- Update appointment status
  UPDATE public.appointment_purchases
  SET 
    status = 'confirmed',
    transaction_reference = p_transaction_reference,
    updated_at = now()
  WHERE id = p_appointment_id;

  -- Get existing appointment chat room
  SELECT id INTO v_chat_room_id
  FROM public.chat_rooms
  WHERE associated_appointment_id = p_appointment_id
    AND type = 'appointment_booking';

  -- Update appointment status message with confirmation
  v_message_id := public.update_appointment_chat_message(
    p_appointment_id,
    'confirmed',
    NULL, -- remove payment link
    NULL -- meeting URL can be added later
  );

  -- Build response
  v_result := json_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', 'confirmed',
    'transaction_reference', p_transaction_reference,
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
'Payment confirmation function that updates specialized appointment chat with confirmed status and removes payment actions.';

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
