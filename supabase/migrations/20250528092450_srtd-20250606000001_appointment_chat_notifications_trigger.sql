-- Generated with srtd from template: supabase/migrations-templates/20250606000001_appointment_chat_notifications_trigger.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- ========================================
-- Appointment Chat Notifications Trigger
-- ========================================
-- This migration adds a trigger that automatically creates chat messages
-- for all appointment status changes, ensuring consistent notifications.

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS appointment_chat_notifications_trigger ON public.appointment_purchases;

drop function if exists public.handle_appointment_chat_notifications;


-- Function to handle chat message creation for appointment status changes
CREATE OR REPLACE FUNCTION public.handle_appointment_chat_notifications()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_chat_room_id UUID;
  v_message_id UUID;
  v_appointment RECORD;
  v_location RECORD;
  v_message_content TEXT;
  v_action_buttons JSONB;
  v_location_address TEXT;
BEGIN
  -- Only process status changes or new appointments
  IF TG_OP = 'UPDATE' AND (NEW.status = OLD.status) THEN
    RETURN NEW;
  END IF;

  -- Get appointment details
  SELECT 
    ap.*,
    p.title as service_name,
    pu.user_id as client_id,
    pu.owner_id,
    COALESCE(uc.full_name, 'Unknown Client') as client_name,
    COALESCE(uo.full_name, 'Unknown Provider') as provider_name,
    s.type as service_delivery_type,
    s.location_id,
    ap.meeting_url
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  JOIN public.profiles uc ON pu.user_id = uc.id
  JOIN public.profiles uo ON pu.owner_id = uo.id
  WHERE ap.id = NEW.id;

  -- Get location details if exists
  IF v_appointment.location_id IS NOT NULL THEN
    SELECT 
      l.name as location_name,
      l.line_1,
      l.line_2,
      l.city,
      l.country,
      l.postcode
    INTO v_location
    FROM public.locations l
    WHERE l.id = v_appointment.location_id;

    -- Build location address
    IF v_location IS NOT NULL THEN
      v_location_address := TRIM(CONCAT_WS(', ',
        NULLIF(v_location.line_1, ''),
        NULLIF(v_location.line_2, ''),
        NULLIF(v_location.city, ''),
        NULLIF(v_location.country, ''),
        NULLIF(v_location.postcode, '')
      ));
    END IF;
  END IF;

  -- Get or create chat room
  v_chat_room_id := public.get_or_create_appointment_chat(
    NEW.id,
    v_appointment.client_id,
    v_appointment.owner_id,
    v_appointment.service_name,
    NEW.appointment_date
  );

  -- Build status-specific message content
  CASE NEW.status::TEXT
    WHEN 'pending_approval' THEN
      v_message_content := format(
        '📋 **Appointment Request Submitted**

**Service:** %s
**Date & Time:** %s
**Duration:** %s minutes

Your appointment request has been submitted and is awaiting approval from %s.',
        v_appointment.service_name,
        to_char(NEW.appointment_date AT TIME ZONE 'UTC', 'Day, DD Mon YYYY at HH24:MI UTC'),
        NEW.duration,
        v_appointment.provider_name
      );

    WHEN 'pending_payment', 'pending_auto_payment' THEN
      v_message_content := format(
        '✅ **Appointment Approved - Payment Required**

**Service:** %s
**Date & Time:** %s
**Duration:** %s minutes

Your appointment has been approved! Please complete payment to confirm your booking.',
        v_appointment.service_name,
        to_char(NEW.appointment_date AT TIME ZONE 'UTC', 'Day, DD Mon YYYY at HH24:MI UTC'),
        NEW.duration
      );

    WHEN 'confirmed' THEN
      v_message_content := format(
        '🎉 **Appointment Confirmed**

**Service:** %s
**Date & Time:** %s
**Duration:** %s minutes

Your appointment is confirmed! We look forward to seeing you.',
        v_appointment.service_name,
        to_char(NEW.appointment_date AT TIME ZONE 'UTC', 'Day, DD Mon YYYY at HH24:MI UTC'),
        NEW.duration
      );

    WHEN 'cancelled' THEN
      v_message_content := format(
        '❌ **Appointment Cancelled**

**Service:** %s
**Original Date & Time:** %s

This appointment has been cancelled.',
        v_appointment.service_name,
        to_char(NEW.appointment_date AT TIME ZONE 'UTC', 'Day, DD Mon YYYY at HH24:MI UTC')
      );

    WHEN 'completed' THEN
      v_message_content := format(
        '✨ **Appointment Completed**

**Service:** %s
**Date & Time:** %s

Thank you for your appointment! We hope you had a great experience.',
        v_appointment.service_name,
        to_char(NEW.appointment_date AT TIME ZONE 'UTC', 'Day, DD Mon YYYY at HH24:MI UTC')
      );

    ELSE
      v_message_content := format(
        '📱 **Appointment Update**

**Service:** %s
**Date & Time:** %s
**Status:** %s',
        v_appointment.service_name,
        to_char(NEW.appointment_date AT TIME ZONE 'UTC', 'Day, DD Mon YYYY at HH24:MI UTC'),
        NEW.status::TEXT
      );
  END CASE;

  -- Add service-specific information
  IF v_appointment.service_delivery_type = 'online'::event_type_enum OR v_appointment.service_delivery_type = 'hybrid'::event_type_enum THEN
    IF NEW.meeting_url IS NOT NULL THEN
      v_message_content := v_message_content || format(
        '

🔗 **Meeting Link:** %s',
        NEW.meeting_url
      );
    END IF;
  END IF;

  IF v_appointment.service_delivery_type = 'in-person'::event_type_enum OR v_appointment.service_delivery_type = 'hybrid'::event_type_enum THEN
    IF v_location IS NOT NULL AND v_location.location_name IS NOT NULL THEN
      v_message_content := v_message_content || format(
        '

📍 **Location:** %s',
        v_location.location_name
      );
      
      IF v_location_address IS NOT NULL AND v_location_address != '' THEN
        v_message_content := v_message_content || format(
          '
**Address:** %s',
          v_location_address
        );
      END IF;
    END IF;
  END IF;

  -- Build action buttons
  v_action_buttons := public.build_appointment_action_buttons(
    NEW.status::TEXT,
    NEW.id,
    NULL, -- payment_url will be generated if needed
    NEW.meeting_url
  );

  -- Create chat message
  v_message_id := public.create_or_update_appointment_message(
    v_chat_room_id,
    v_appointment.owner_id, -- Sent by provider
    NEW.id,
    NEW.status::TEXT,
    v_message_content,
    v_action_buttons,
    jsonb_build_object(
      'appointment_id', NEW.id,
      'status', NEW.status::TEXT,
      'timestamp', extract(epoch from now()),
      'trigger_source', 'status_change'
    )
  );

  RETURN NEW;
END $$;

-- ========================================
-- Create Trigger
-- ========================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS appointment_chat_notifications_trigger ON public.appointment_purchases;

-- Create new trigger for chat notifications
CREATE TRIGGER appointment_chat_notifications_trigger
  AFTER INSERT OR UPDATE OF status ON public.appointment_purchases
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_appointment_chat_notifications();


-- ========================================
-- Comments
-- ========================================

COMMENT ON FUNCTION public.handle_appointment_chat_notifications() IS 
'Automatically creates chat messages for all appointment status changes to ensure consistent notifications in appointment chat rooms.';

COMMENT ON TRIGGER appointment_chat_notifications_trigger ON public.appointment_purchases IS 
'Triggers chat message creation whenever an appointment status changes or a new appointment is created.'; 



COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
