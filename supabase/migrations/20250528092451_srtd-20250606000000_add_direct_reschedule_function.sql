-- Generated with srtd from template: supabase/migrations-templates/20250606000000_add_direct_reschedule_function.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- ========================================
-- Direct Reschedule Function for Creators
-- ========================================
-- This migration adds a direct reschedule function that gives creators
-- total control to reschedule appointments without requiring client approval,
-- replacing the old reschedule_appointment_request functionality.

drop function if exists public.reschedule_appointment_direct;

-- Function for creators to directly reschedule appointments with full control
CREATE OR REPLACE FUNCTION public.reschedule_appointment_direct(
  p_appointment_id UUID,
  p_new_date TIMESTAMPTZ,
  p_duration INTEGER DEFAULT NULL,
  p_message TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_location RECORD;
  v_chat_room_id UUID;
  v_message_id UUID;
  v_result JSON;
  v_original_date TIMESTAMPTZ;
  v_new_duration INTEGER;
  v_service_name TEXT;
  v_client_name TEXT;
  v_provider_name TEXT;
  v_message_content TEXT;
  v_action_buttons JSONB;
  v_location_address TEXT;
BEGIN
  -- Get appointment details with FOR UPDATE (without location join)
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
  WHERE ap.id = p_appointment_id
    AND ap.status NOT IN ('cancelled'::appointment_status_enum, 'completed'::appointment_status_enum)
    AND pu.owner_id = auth.uid() -- Only creator/provider can directly reschedule
  FOR UPDATE OF ap;

  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found, already completed/cancelled, or you do not have permission to reschedule it';
  END IF;

  -- Get location details separately if location_id exists
  IF v_appointment.location_id IS NOT NULL THEN
    SELECT 
      l.name as location_name,
      l.line_1,
      l.line_2,
      l.city,
      l.country,
      l.postcode,
      l.coordinates as location_coordinates
    INTO v_location
    FROM public.locations l
    WHERE l.id = v_appointment.location_id;
  END IF;

  -- Store original values
  v_original_date := v_appointment.appointment_date;
  v_new_duration := COALESCE(p_duration, v_appointment.duration);
  v_service_name := v_appointment.service_name;
  v_client_name := v_appointment.client_name;
  v_provider_name := v_appointment.provider_name;

  -- Build location address from components if location exists
  IF v_location IS NOT NULL THEN
    v_location_address := TRIM(CONCAT_WS(', ',
      NULLIF(v_location.line_1, ''),
      NULLIF(v_location.line_2, ''),
      NULLIF(v_location.city, ''),
      NULLIF(v_location.country, ''),
      NULLIF(v_location.postcode, '')
    ));
  END IF;

  -- Check for scheduling conflicts (excluding this appointment)
  IF public.check_schedule_conflicts(
    v_appointment.owner_id,
    p_new_date,
    p_new_date + (v_new_duration || ' minutes')::INTERVAL,
    p_appointment_id
  ) THEN
    RAISE EXCEPTION 'The new time slot conflicts with existing appointments';
  END IF;

  -- Update appointment with new date/time and duration
  UPDATE public.appointment_purchases
  SET 
    appointment_date = p_new_date,
    duration = v_new_duration,
    status = CASE 
      WHEN status = 'pending_payment'::appointment_status_enum THEN 'pending_payment'::appointment_status_enum
      WHEN status = 'pending_approval'::appointment_status_enum THEN 'pending_approval'::appointment_status_enum
      ELSE 'confirmed'::appointment_status_enum
    END,
    metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
      'reschedule_history', COALESCE(metadata->'reschedule_history', '[]'::jsonb) || 
        jsonb_build_array(jsonb_build_object(
          'original_date', v_original_date,
          'original_duration', v_appointment.duration,
          'new_date', p_new_date,
          'new_duration', v_new_duration,
          'rescheduled_at', extract(epoch from now()),
          'rescheduled_by', 'provider',
          'provider_message', p_message,
          'method', 'direct_reschedule'
        ))
    ),
    updated_at = now()
  WHERE id = p_appointment_id;

  -- Get or create chat room for this appointment
  v_chat_room_id := public.get_or_create_appointment_chat(
    p_appointment_id,
    v_appointment.client_id,
    v_appointment.owner_id,
    v_service_name,
    p_new_date
  );

  -- Build reschedule notification message content
  v_message_content := format(
    '📅 **Appointment Rescheduled**

Your appointment for **%s** has been rescheduled by %s.

**Original Time:** %s
**New Time:** %s
**Duration:** %s minutes',
    v_service_name,
    v_provider_name,
    to_char(v_original_date AT TIME ZONE 'UTC', 'Day, DD Mon YYYY at HH24:MI UTC'),
    to_char(p_new_date AT TIME ZONE 'UTC', 'Day, DD Mon YYYY at HH24:MI UTC'),
    v_new_duration
  );

  -- Add provider message if provided
  IF p_message IS NOT NULL AND trim(p_message) != '' THEN
    v_message_content := v_message_content || format(
      '

**Message from %s:**
%s',
      v_provider_name,
      p_message
    );
  END IF;

  -- Add service-specific information
  IF v_appointment.service_delivery_type = 'online'::event_type_enum OR v_appointment.service_delivery_type = 'hybrid'::event_type_enum THEN
    IF v_appointment.meeting_url IS NOT NULL THEN
      v_message_content := v_message_content || format(
        '

🔗 **Meeting Link:** %s',
        v_appointment.meeting_url
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



  -- Build action buttons based on appointment status
  v_action_buttons := public.build_appointment_action_buttons(
    v_appointment.status::TEXT,
    p_appointment_id,
    NULL, -- payment_url will be generated if needed
    v_appointment.meeting_url
  );

  -- Create reschedule notification message
  v_message_id := public.create_or_update_appointment_message(
    v_chat_room_id,
    v_appointment.owner_id, -- Sent by provider
    p_appointment_id,
    v_appointment.status::TEXT,
    v_message_content,
    v_action_buttons,
    jsonb_build_object(
      'appointment_id', p_appointment_id,
      'status', v_appointment.status::TEXT,
      'timestamp', extract(epoch from now()),
      'reschedule_info', jsonb_build_object(
        'original_date', v_original_date,
        'new_date', p_new_date,
        'original_duration', v_appointment.duration,
        'new_duration', v_new_duration,
        'rescheduled_by', 'provider'
      )
    )
  );

  -- Build response
  v_result := json_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', v_appointment.status,
    'original_date', v_original_date,
    'new_date', p_new_date,
    'original_duration', v_appointment.duration,
    'new_duration', v_new_duration,
    'chat_room_id', v_chat_room_id,
    'message_id', v_message_id,
    'provider_message', p_message,
    'service_name', v_service_name,
    'client_name', v_client_name
  );

  RETURN v_result;
END $$;

-- ========================================
-- Comments and Documentation
-- ========================================

COMMENT ON FUNCTION public.reschedule_appointment_direct(UUID, TIMESTAMPTZ, INTEGER, TEXT) IS 
'Allows creators/providers to directly reschedule appointments with full control. 
Updates appointment date/time, duration, checks for conflicts, maintains reschedule history, 
and sends notification to client via chat. Replaces the old reschedule_appointment_request functionality.'; 



COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
