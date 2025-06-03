-- Generated with srtd from template: supabase/migrations-templates/20250605000000_enhance_appointment_messages_with_meeting_location.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Generated with srtd from template: supabase/migrations-templates/20250605000000_enhance_appointment_messages_with_meeting_location.sql
-- You very likely **DO NOT** want to manually edit this generated file.

-- ========================================
-- Enhanced Appointment Messages with Meeting Links and Location Info
-- ========================================



-- Enhanced function to build appointment status message content with meeting links and location
CREATE OR REPLACE FUNCTION public.build_appointment_message_content(
  p_status TEXT,
  p_service_name TEXT,
  p_appointment_date TIMESTAMPTZ,
  p_client_name TEXT,
  p_owner_name TEXT,
  p_payment_amount NUMERIC DEFAULT NULL,
  p_service_type TEXT DEFAULT NULL,
  p_meeting_url TEXT DEFAULT NULL,
  p_location_info JSONB DEFAULT NULL
) RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_content TEXT;
  v_date_formatted TEXT := to_char(p_appointment_date, 'Day, DD Month YYYY at HH24:MI');
  v_meeting_section TEXT := '';
  v_location_section TEXT := '';
BEGIN
  -- Build meeting section for online/hybrid services
  IF p_service_type IN ('online', 'hybrid') AND p_meeting_url IS NOT NULL THEN
    v_meeting_section := format(E'\n\n🔗 **Meeting Link:** %s', p_meeting_url);
  END IF;

  -- Build location section for in-person/hybrid services
  IF p_service_type IN ('in-person', 'hybrid') AND p_location_info IS NOT NULL THEN
    DECLARE
      v_location_name TEXT := p_location_info->>'name';
      v_address_line1 TEXT := p_location_info->>'line_1';
      v_address_line2 TEXT := p_location_info->>'line_2';
      v_city TEXT := p_location_info->>'city';
      v_country TEXT := p_location_info->>'country';
      v_postcode TEXT := p_location_info->>'postcode';
      v_maps_link TEXT := p_location_info->>'maps_link';
      v_full_address TEXT := '';
    BEGIN
      -- Build full address
      IF v_address_line1 IS NOT NULL THEN
        v_full_address := v_address_line1;
      END IF;
      IF v_address_line2 IS NOT NULL THEN
        v_full_address := v_full_address || CASE WHEN v_full_address != '' THEN ', ' ELSE '' END || v_address_line2;
      END IF;
      IF v_city IS NOT NULL THEN
        v_full_address := v_full_address || CASE WHEN v_full_address != '' THEN ', ' ELSE '' END || v_city;
      END IF;
      IF v_postcode IS NOT NULL THEN
        v_full_address := v_full_address || CASE WHEN v_full_address != '' THEN ' ' ELSE '' END || v_postcode;
      END IF;
      IF v_country IS NOT NULL THEN
        v_full_address := v_full_address || CASE WHEN v_full_address != '' THEN ', ' ELSE '' END || v_country;
      END IF;

      -- Build location section
      v_location_section := format(E'\n\n📍 **Location:** %s', COALESCE(v_location_name, 'Location'));
      IF v_full_address != '' THEN
        v_location_section := v_location_section || format(E'\n**Address:** %s', v_full_address);
      END IF;
      IF v_maps_link IS NOT NULL THEN
        v_location_section := v_location_section || format(E'\n**Directions:** %s', v_maps_link);
      END IF;
    END;
  END IF;

  CASE p_status
    WHEN 'pending_approval' THEN
      v_content := format(
        '📅 **Appointment Request Submitted**

**Service:** %s
**Date & Time:** %s
**Client:** %s

Your appointment request has been submitted and is awaiting approval from %s. You''ll receive a notification once it''s reviewed.%s%s',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        COALESCE(p_client_name, 'Unknown Client'),
        COALESCE(p_owner_name, 'Service Provider'),
        v_meeting_section,
        v_location_section
      );
      

    WHEN 'pending_payment' THEN
      v_content := format(
        '✅ **Appointment Approved - Payment Required**

**Service:** %s
**Date & Time:** %s
**Amount:** %s

Your appointment has been approved! Please complete the payment to confirm your booking.%s%s',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        CASE WHEN p_payment_amount IS NOT NULL 
             THEN '$' || p_payment_amount::TEXT 
             ELSE 'TBD' END,
        v_meeting_section,
        v_location_section
      );
      
    WHEN 'confirmed' THEN
      v_content := format(
        '🎉 **Appointment Confirmed**

**Service:** %s
**Date & Time:** %s
**Provider:** %s

Your appointment is confirmed! You''ll receive a reminder before the session.%s%s',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        COALESCE(p_owner_name, 'Service Provider'),
        v_meeting_section,
        v_location_section
      );
      
    WHEN 'cancelled' THEN
      v_content := format(
        '❌ **Appointment Cancelled**

**Service:** %s
**Date & Time:** %s

This appointment has been cancelled. You can book a new appointment anytime.%s%s',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        v_meeting_section,
        v_location_section
      );
      
    WHEN 'completed' THEN
      v_content := format(
        '✨ **Appointment Completed**

**Service:** %s
**Date & Time:** %s

Thank you for your session! We hope it was valuable for you.%s%s',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        v_meeting_section,
        v_location_section
      );
      
    WHEN 'rescheduled' THEN
      v_content := format(
        '🔄 **Appointment Rescheduled**

**Service:** %s
**New Date & Time:** %s

Your appointment has been rescheduled. Please note the new time.%s%s',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        v_meeting_section,
        v_location_section
      );
      
    ELSE
      v_content := format(
        '📋 **Appointment Update**

**Service:** %s
**Date & Time:** %s
**Status:** %s%s%s',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        p_status,
        v_meeting_section,
        v_location_section
      );
  END CASE;

  RETURN v_content;
END $$;

-- Enhanced function to handle appointment status changes and update chat with meeting/location info
CREATE OR REPLACE FUNCTION public.update_appointment_chat_message(
  p_appointment_id UUID,
  p_new_status TEXT,
  p_payment_url TEXT DEFAULT NULL,
  p_meeting_url TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_chat_room_id UUID;
  v_service_name TEXT;
  v_appointment_date TIMESTAMPTZ;
  v_client_name TEXT;
  v_owner_name TEXT;
  v_owner_id UUID;
  v_payment_amount NUMERIC;
  v_service_type TEXT;
  v_stored_meeting_url TEXT;
  v_location_info JSONB;
  v_message_content TEXT;
  v_action_buttons JSONB;
  v_appointment_context JSONB;
  v_message_id UUID;
  v_final_meeting_url TEXT;
BEGIN
  -- Get chat room for this appointment
  SELECT cr.id, cr.created_by INTO v_chat_room_id, v_owner_id
  FROM public.chat_rooms cr
  WHERE cr.associated_appointment_id = p_appointment_id
    AND cr.type = 'appointment_booking';

  -- Exit if no chat room exists
  IF v_chat_room_id IS NULL THEN
    RETURN NULL;
  END IF;

  -- Get appointment details with service type, meeting URL, and location info
  SELECT 
    p.title,
    ap.appointment_date,
    COALESCE(uc.full_name, 'Unknown Client'),
    COALESCE(uo.full_name, 'Unknown Provider'),
    COALESCE(pu.amount, 0),
    s.type::TEXT,
    ap.meeting_url,
    CASE 
      WHEN s.type IN ('in-person', 'hybrid') AND l.id IS NOT NULL THEN
        jsonb_build_object(
          'name', l.name,
          'line_1', l.line_1,
          'line_2', l.line_2,
          'city', l.city,
          'country', l.country,
          'postcode', l.postcode,
          'maps_link', l.maps_link
        )
      ELSE NULL
    END
  INTO 
    v_service_name,
    v_appointment_date,
    v_client_name,
    v_owner_name,
    v_payment_amount,
    v_service_type,
    v_stored_meeting_url,
    v_location_info
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  JOIN public.profiles uc ON pu.user_id = uc.id
  JOIN public.profiles uo ON pu.owner_id = uo.id
  LEFT JOIN public.locations l ON s.location_id = l.id
  WHERE ap.id = p_appointment_id;

  -- Use provided meeting URL or stored meeting URL
  v_final_meeting_url := COALESCE(p_meeting_url, v_stored_meeting_url);

  -- Build message content with enhanced information
  v_message_content := public.build_appointment_message_content(
    p_new_status,
    v_service_name,
    v_appointment_date,
    v_client_name,
    v_owner_name,
    v_payment_amount,
    v_service_type,
    v_final_meeting_url,
    v_location_info
  );


  -- Build action buttons
  v_action_buttons := public.build_appointment_action_buttons(
    p_new_status,
    p_appointment_id,
    p_payment_url,
    v_final_meeting_url
  );

  -- Build appointment context with enhanced information
  v_appointment_context := jsonb_build_object(
    'appointment_id', p_appointment_id,
    'status', p_new_status,
    'service_name', v_service_name,
    'service_type', v_service_type,
    'appointment_date', v_appointment_date,
    'payment_url', p_payment_url,
    'meeting_url', v_final_meeting_url,
    'location_info', v_location_info,
    'timestamp', extract(epoch from now())
  );

  -- Create/update living message
  v_message_id := public.create_or_update_appointment_message(
    v_chat_room_id,
    v_owner_id,
    p_appointment_id,
    p_new_status,
    v_message_content,
    v_action_buttons,
    v_appointment_context
  );

  RETURN v_message_id;
END $$; 



COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
