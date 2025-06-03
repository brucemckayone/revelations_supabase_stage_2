-- Generated with srtd from template: supabase/migrations-templates/20250605000001_fix_payment_link_encoding.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Generated with srtd from template: supabase/migrations-templates/20250605000001_fix_payment_link_encoding.sql

-- You very likely **DO NOT** want to manually edit this generated file.

-- ========================================
-- Fix Payment Link Encoding and Action Button Integration
-- ========================================

drop function if exists public.generate_payment_link;
-- Fix the generate_payment_link function to create proper encoded data for frontend
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
  v_encoded_data TEXT;
  v_appointment_data JSONB;
BEGIN
  -- Get appointment and service details with correct table joins
  SELECT 
    ap.*,
    p.title as service_name,
    pu.user_id as client_id,
    pu.owner_id,
    s.post_id
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  WHERE ap.id = p_appointment_id;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found: %', p_appointment_id;
  END IF;

  -- Build appointment data structure that matches frontend AppointmentData interface
  v_appointment_data := jsonb_build_object(
    'purchase_id', v_appointment.purchase_id,
    'appointment_id', p_appointment_id,
    'user_id', v_appointment.client_id,
    'owner_id', v_appointment.owner_id,
    'service_id', v_appointment.service_id,
    'post_id', v_appointment.post_id,
    'appointment_date', v_appointment.appointment_date,
    'duration', v_appointment.duration,
    'price', p_amount,
    'purchase_type', 'appointment'
  );

  -- Encode the JSON data as base64
  v_encoded_data := encode(v_appointment_data::text::bytea, 'base64');

  -- Update appointment with payment link
  UPDATE public.appointment_purchases
  SET 
    payment_link = '/app/checkout/appointment/secure?data=' || v_encoded_data
  WHERE id = p_appointment_id;

  RETURN '/app/checkout/appointment/secure?data=' || v_encoded_data;
END $$;

-- Enhanced action button creation function that generates encoded payment links
CREATE OR REPLACE FUNCTION public.create_payment_action_button(
  p_appointment_id UUID,
  p_amount NUMERIC DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_payment_link TEXT;
  v_amount NUMERIC;
BEGIN
  -- Get appointment details if amount not provided
  IF p_amount IS NULL THEN
    SELECT 
      pu.amount
    INTO v_amount
    FROM public.appointment_purchases ap
    JOIN public.purchases pu ON ap.purchase_id = pu.id
    WHERE ap.id = p_appointment_id;
    
    IF v_amount IS NULL THEN
      v_amount := 0;
    END IF;
  ELSE
    v_amount := p_amount;
  END IF;

  -- Generate encoded payment link
  v_payment_link := public.generate_payment_link(
    p_appointment_id,
    v_amount,
    'USD',
    NULL -- Let function generate description
  );

  -- Return payment action button with encoded data
  RETURN jsonb_build_object(
    'type', 'payment',
    'label', 'Complete Payment',
    'url', v_payment_link,
    'style', 'primary',
    'amount', v_amount,
    'appointment_id', p_appointment_id
  );
END $$;


drop function if exists public.build_appointment_action_buttons;
-- Enhanced build_appointment_action_buttons function with encoded payment links
CREATE OR REPLACE FUNCTION public.build_appointment_action_buttons(
  p_status TEXT,
  p_appointment_id UUID,
  p_payment_url TEXT DEFAULT NULL,
  p_meeting_url TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_buttons JSONB := '[]';
  v_payment_button JSONB;
BEGIN
  CASE p_status
    WHEN 'pending_approval' THEN
      -- No actions for client during pending approval
      v_buttons := '[]';
      
    WHEN 'pending_payment' THEN
      -- Create encoded payment button (ignore p_payment_url, generate our own)
      v_payment_button := public.create_payment_action_button(p_appointment_id);
      
      v_buttons := jsonb_build_array(
        v_payment_button,
        jsonb_build_object(
          'type', 'cancel',
          'label', 'Cancel Appointment',
          'action', 'cancel_appointment',
          'style', 'danger',
          'confirm', 'Are you sure you want to cancel this appointment?'
        )
      );
      
    WHEN 'confirmed' THEN
      v_buttons := jsonb_build_array(
        jsonb_build_object(
          'type', 'reschedule',
          'label', 'Reschedule',
          'action', 'reschedule_appointment',
          'style', 'secondary'
        ),
        jsonb_build_object(
          'type', 'cancel',
          'label', 'Cancel',
          'action', 'cancel_appointment',
          'style', 'danger',
          'confirm', 'Are you sure you want to cancel this appointment?'
        )
      );
      
      -- Add meeting link if available
      IF p_meeting_url IS NOT NULL THEN
        v_buttons := v_buttons || jsonb_build_array(
          jsonb_build_object(
            'type', 'meeting',
            'label', 'Join Meeting',
            'url', p_meeting_url,
            'style', 'success'
          )
        );
      END IF;
      
    WHEN 'cancelled' THEN
      v_buttons := jsonb_build_array(
        jsonb_build_object(
          'type', 'rebook',
          'label', 'Book Again',
          'action', 'rebook_appointment',
          'style', 'primary'
        )
      );
      
    ELSE
      v_buttons := '[]';
  END CASE;

  RETURN v_buttons;
END $$;

-- Function to regenerate action buttons for existing appointments
CREATE OR REPLACE FUNCTION public.regenerate_appointment_action_buttons(
  p_appointment_id UUID
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status TEXT;
  v_meeting_url TEXT;
  v_action_buttons JSONB;
  v_message_id UUID;
BEGIN
  -- Get current appointment status and meeting URL
  SELECT 
    ap.status::TEXT,
    ap.meeting_url
  INTO v_status, v_meeting_url
  FROM public.appointment_purchases ap
  WHERE ap.id = p_appointment_id;

  IF v_status IS NULL THEN
    RAISE EXCEPTION 'Appointment not found: %', p_appointment_id;
  END IF;

  -- Generate new action buttons
  v_action_buttons := public.build_appointment_action_buttons(
    v_status,
    p_appointment_id,
    NULL, -- Don't use old payment URL
    v_meeting_url
  );

  -- Update the latest appointment message with new action buttons
  UPDATE public.chat_messages
  SET 
    action_buttons = v_action_buttons
  WHERE id IN (
    SELECT cm.id
    FROM public.chat_messages cm
    JOIN public.chat_rooms cr ON cm.chat_room_id = cr.id
    WHERE cr.associated_appointment_id = p_appointment_id
      AND cr.type = 'appointment_booking'
      AND cm.message_type = 'appointment_status'
      AND cm.superseded_by IS NULL
    ORDER BY cm.created_at DESC
    LIMIT 1
  )
  RETURNING id INTO v_message_id;

  RETURN jsonb_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'message_id', v_message_id,
    'action_buttons', v_action_buttons
  );
END $$;


-- Comments for documentation
COMMENT ON FUNCTION public.generate_payment_link(UUID, NUMERIC, TEXT, TEXT) IS 
'Generates payment links with base64 encoded appointment data that matches frontend AppointmentData interface.';

COMMENT ON FUNCTION public.create_payment_action_button(UUID, NUMERIC) IS 
'Creates a payment action button with encoded checkout data for secure payment processing.';

COMMENT ON FUNCTION public.regenerate_appointment_action_buttons(UUID) IS 
'Regenerates action buttons for an existing appointment and updates the latest chat message.'; 



COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
