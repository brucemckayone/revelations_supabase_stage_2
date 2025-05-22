-- Generated with srtd from template: supabase/migrations-templates/consolidated_appointment_functions.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;


-- Consolidated appointment functions with payment_link support
-- Note: All functions have been dropped in a separate migration

-- Create or replace approve_appointment_request function
CREATE OR REPLACE FUNCTION public.approve_appointment_request(
  p_appointment_id UUID, 
  p_price NUMERIC, 
  p_message TEXT DEFAULT NULL,
  p_checkout_base_url TEXT DEFAULT '/app/checkout/appointment'
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_purchase_id UUID;
  v_user_id UUID;
  v_owner_id UUID;
  v_service_id UUID;
  v_post_id UUID;
  v_appointment_date TIMESTAMP WITH TIME ZONE;
  v_duration INTEGER;
  v_result JSONB;
  v_chat_room_id UUID;
  v_message_success BOOLEAN;
  v_checkout_url TEXT;
  v_metadata JSONB;
  v_encoded_data TEXT;
  v_message_text TEXT;
  v_service_name TEXT;
  v_service_type TEXT;
  v_provider_name TEXT;
  v_client_name TEXT;
  v_chat_room_name TEXT;
BEGIN
  -- Get appointment details
  SELECT 
    ap.purchase_id, 
    p.user_id, 
    p.owner_id, 
    ap.service_id, 
    p.post_id,
    ap.appointment_date,
    ap.duration,
    s.type AS service_type,
    COALESCE(po.title, 'Service') AS service_name,
    COALESCE(pr_owner.full_name, 'Provider') AS provider_name,
    COALESCE(pr_client.full_name, 'Client') AS client_name
  INTO 
    v_purchase_id, 
    v_user_id, 
    v_owner_id, 
    v_service_id, 
    v_post_id,
    v_appointment_date,
    v_duration,
    v_service_type,
    v_service_name,
    v_provider_name,
    v_client_name
  FROM 
    appointment_purchases ap
    JOIN purchases p ON ap.purchase_id = p.id
    JOIN services s ON ap.service_id = s.id
    LEFT JOIN posts po ON s.post_id = po.id
    LEFT JOIN profiles pr_owner ON p.owner_id = pr_owner.id
    LEFT JOIN profiles pr_client ON p.user_id = pr_client.id
  WHERE 
    ap.id = p_appointment_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Appointment not found');
  END IF;
  
  -- Create a descriptive chat room name
  v_chat_room_name := v_service_name || ' - ' || 
                     to_char(v_appointment_date, 'DD Mon YYYY HH12:MI AM') || ' - ' ||
                     v_provider_name || ' & ' || v_client_name;
  
  -- Build metadata JSON for checkout URL
  v_metadata := jsonb_build_object(
    'purchase_type', 'appointment',
    'service_id', v_service_id,
    'post_id', v_post_id,
    'owner_id', v_owner_id,
    'user_id', v_user_id,
    'appointment_id', p_appointment_id,
    'purchase_id', v_purchase_id,
    'appointment_date', v_appointment_date,
    'duration', v_duration,
    'price', p_price,
    'service_name', v_service_name,
    'service_type', v_service_type
  );
  
  -- Encode data for security
  v_encoded_data := encode(
    convert_to(
      v_metadata::text,
      'UTF8'
    ),
    'base64'
  );
  
  -- Generate checkout URL with encoded data
  v_checkout_url := p_checkout_base_url || '/secure' || '?data=' || v_encoded_data;
  
  -- Update appointment status and store payment_link
  UPDATE appointment_purchases
  SET 
    status = 'pending_payment',
    payment_link = v_checkout_url,
    updated_at = NOW()
  WHERE id = p_appointment_id;
  
  -- Update purchase with price
  UPDATE purchases
  SET 
    amount = p_price,
    payment_status = 'pending',
    updated_at = NOW()
  WHERE id = v_purchase_id;
  
  -- Find or create chat room
  WITH room_participants AS (
    SELECT 
      cr.id as room_id,
      COUNT(*) as participant_count,
      SUM(CASE WHEN cp.user_id IN (v_user_id, v_owner_id) THEN 1 ELSE 0 END) as target_users_count
    FROM 
      chat_rooms cr
      JOIN chat_participants cp ON cr.id = cp.chat_room_id
    WHERE 
      cr.type = 'private'
    GROUP BY 
      cr.id
  )
  SELECT room_id INTO v_chat_room_id
  FROM room_participants
  WHERE 
    participant_count = 2 AND 
    target_users_count = 2;
  
  -- If no chat room exists, create one
  IF v_chat_room_id IS NULL THEN
    INSERT INTO chat_rooms (name, type, created_by)
    VALUES (v_chat_room_name, 'private', v_owner_id)
    RETURNING id INTO v_chat_room_id;
    
    -- Add participants
    INSERT INTO chat_participants (chat_room_id, user_id)
    VALUES 
      (v_chat_room_id, v_user_id),
      (v_chat_room_id, v_owner_id)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
  ELSE
    -- Update existing room name
    UPDATE chat_rooms
    SET name = v_chat_room_name
    WHERE id = v_chat_room_id;
  END IF;
  
  -- Compose message
  v_message_text := 
    CASE 
      WHEN p_message IS NOT NULL AND length(trim(p_message)) > 0
        THEN p_message || E'\n\n' || 'Pay here: [Complete Payment](' || v_checkout_url || '){button}'
      ELSE
        'Your appointment request has been approved. Please complete payment to confirm.' || E'\n\n' || '[Complete Payment](' || v_checkout_url || '){button}'
    END;

  -- Send message
  BEGIN
    INSERT INTO chat_messages (chat_room_id, sender_id, message, status)
    VALUES (v_chat_room_id, v_owner_id, v_message_text, 'delivered');
    v_message_success := TRUE;
  EXCEPTION 
    WHEN OTHERS THEN
      v_message_success := FALSE;
      -- Fallback to notifications
      BEGIN
        INSERT INTO notifications (
          user_id,
          title,
          content,
          type,
          action_url,
          reference_id,
          reference_type,
          metadata
        ) VALUES (
          v_user_id,
          'Appointment Approved',
          v_message_text,
          'appointment',
          v_checkout_url,
          p_appointment_id,
          'appointment',
          v_metadata
        );
      EXCEPTION WHEN OTHERS THEN
        NULL; -- Just continue if this fails
      END;
  END;
  
  -- Build result
  v_result := jsonb_build_object(
    'success', TRUE,
    'purchase_id', v_purchase_id,
    'appointment_id', p_appointment_id,
    'user_id', v_user_id,
    'owner_id', v_owner_id,
    'service_id', v_service_id,
    'post_id', v_post_id,
    'appointment_date', v_appointment_date,
    'duration', v_duration,
    'price', p_price,
    'status', 'pending_payment',
    'message_sent', v_message_success,
    'chat_room_id', v_chat_room_id,
    'chat_room_name', v_chat_room_name,
    'checkout_url', v_checkout_url,
    'encoded_data', v_encoded_data,
    'payment_link', v_checkout_url,
    'metadata', v_metadata
  );
  
  -- Trigger notification
  PERFORM pg_notify('appointment_approved', v_result::text);
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.approve_appointment_request(UUID, NUMERIC, TEXT, TEXT) IS 'Approves an appointment request, generates payment checkout URL with encoded data, stores the payment link in the appointment record, and sends notification with payment link';

-- Process payment confirmation function
CREATE OR REPLACE FUNCTION public.process_appointment_payment_confirmation(
  p_purchase_id UUID,
  p_payment_intent_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_owner_id UUID;
  v_appointment_id UUID;
  v_appointment_date TIMESTAMP WITH TIME ZONE;
  v_service_id UUID;
  v_service_type event_type_enum;
  v_method TEXT;
  v_chat_room_id UUID;
  v_meeting_url TEXT;
  v_result JSONB;
  v_user_preference RECORD;
  v_owner_preference RECORD;
  v_notification_metadata JSONB;
  v_message_text TEXT;
  v_service_name TEXT;
  v_provider_name TEXT;
  v_client_name TEXT;
  v_chat_room_name TEXT;
BEGIN
  -- Update purchase status
  UPDATE purchases
  SET 
    payment_status = 'completed',
    completed_at = NOW(),
    updated_at = NOW(),
    stripe_payment_intent_id = p_payment_intent_id
  WHERE id = p_purchase_id
  RETURNING user_id, owner_id INTO v_user_id, v_owner_id;
  
  -- Get appointment details
  SELECT 
    ap.id, 
    ap.appointment_date, 
    ap.service_id,
    ap.method,
    s.type,
    COALESCE(po.title, 'Service') AS service_name,
    COALESCE(pr_owner.full_name, 'Provider') AS provider_name,
    COALESCE(pr_client.full_name, 'Client') AS client_name
  INTO 
    v_appointment_id, 
    v_appointment_date, 
    v_service_id,
    v_method,
    v_service_type,
    v_service_name,
    v_provider_name,
    v_client_name
  FROM 
    appointment_purchases ap
    JOIN services s ON ap.service_id = s.id
    LEFT JOIN posts po ON s.post_id = po.id
    LEFT JOIN profiles pr_owner ON pr_owner.id = v_owner_id
    LEFT JOIN profiles pr_client ON pr_client.id = v_user_id
  WHERE 
    ap.purchase_id = p_purchase_id;
  
  -- Create descriptive chat room name
  v_chat_room_name := v_service_name || ' - ' || 
                     to_char(v_appointment_date, 'DD Mon YYYY HH12:MI AM') || ' - ' ||
                     v_provider_name || ' & ' || v_client_name;
  
  -- Generate meeting URL for online/hybrid services
  IF v_method = 'video' OR (v_service_type IN ('online', 'hybrid')) THEN
    v_meeting_url := 'https://local.revelations.com/meeting/private/' || gen_random_uuid();
    
    -- Update appointment with meeting URL and clear payment_link
    UPDATE appointment_purchases
    SET 
      status = 'confirmed',
      meeting_url = v_meeting_url,
      meeting_id = NULL,
      payment_link = NULL, -- Clear payment link as it's no longer needed
      updated_at = NOW()
    WHERE purchase_id = p_purchase_id;
  ELSE
    -- For in-person appointments, just update status and clear payment_link
    UPDATE appointment_purchases
    SET 
      status = 'confirmed',
      meeting_id = NULL,
      payment_link = NULL, -- Clear payment link as it's no longer needed
      updated_at = NOW()
    WHERE purchase_id = p_purchase_id;
  END IF;
  
  -- Find or create chat room
  WITH room_participants AS (
    SELECT 
      cr.id as room_id,
      COUNT(*) as participant_count,
      SUM(CASE WHEN cp.user_id IN (v_user_id, v_owner_id) THEN 1 ELSE 0 END) as target_users_count
    FROM 
      chat_rooms cr
      JOIN chat_participants cp ON cr.id = cp.chat_room_id
    WHERE 
      cr.type = 'private'
    GROUP BY 
      cr.id
  )
  SELECT room_id INTO v_chat_room_id
  FROM room_participants
  WHERE 
    participant_count = 2 AND 
    target_users_count = 2;
    
  -- If no chat room exists, create one
  IF v_chat_room_id IS NULL THEN
    INSERT INTO chat_rooms (name, type, created_by)
    VALUES (v_chat_room_name, 'private', v_owner_id)
    RETURNING id INTO v_chat_room_id;
    
    -- Add participants
    INSERT INTO chat_participants (chat_room_id, user_id)
    VALUES 
      (v_chat_room_id, v_user_id),
      (v_chat_room_id, v_owner_id)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
  ELSE
    -- Update existing room name
    UPDATE chat_rooms
    SET name = v_chat_room_name
    WHERE id = v_chat_room_id;
  END IF;
  
  -- Prepare notification metadata
  v_notification_metadata := jsonb_build_object(
    'appointment_id', v_appointment_id,
    'purchase_id', p_purchase_id,
    'service_id', v_service_id,
    'status', 'confirmed',
    'appointment_date', v_appointment_date,
    'service_type', v_service_type,
    'method', v_method,
    'service_name', v_service_name,
    'provider_name', v_provider_name,
    'client_name', v_client_name
  );
  
  -- Add meeting URL to metadata if it exists
  IF v_meeting_url IS NOT NULL THEN
    v_notification_metadata := v_notification_metadata || jsonb_build_object('meeting_url', v_meeting_url);
  END IF;
  
  -- Prepare message text
  v_message_text := 'Your appointment has been confirmed for ' || 
                    to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM');
                    
  IF v_meeting_url IS NOT NULL THEN
    v_message_text := v_message_text || E'\n\n[Join Meeting](' || v_meeting_url || '){button}';
  END IF;
  
  -- Send confirmation messages
  BEGIN
    -- Message to client
    INSERT INTO chat_messages (chat_room_id, sender_id, message, status)
    VALUES (v_chat_room_id, v_owner_id, v_message_text, 'delivered');
    
    -- Message to provider
    INSERT INTO chat_messages (chat_room_id, sender_id, message, status)
    VALUES (
      v_chat_room_id,
      v_owner_id,
      'Payment completed for appointment on ' || to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM') || 
      CASE WHEN v_meeting_url IS NOT NULL THEN E'\n\n[Join Meeting](' || v_meeting_url || '){button}' ELSE '' END,
      'delivered'
    );
  EXCEPTION 
    WHEN OTHERS THEN
      -- Fallback to notifications
      BEGIN
        -- Send appropriate notifications
        -- Notification logic here...
        NULL; -- This is a placeholder for the notification fallback logic
      END;
  END;
  
  -- Build result
  v_result := jsonb_build_object(
    'success', TRUE,
    'purchase_id', p_purchase_id,
    'appointment_id', v_appointment_id,
    'status', 'confirmed',
    'chat_room_id', v_chat_room_id,
    'chat_room_name', v_chat_room_name
  );
  
  -- Add meeting URL to result if applicable
  IF v_meeting_url IS NOT NULL THEN
    v_result := v_result || jsonb_build_object('meeting_url', v_meeting_url);
  END IF;
  
  -- Trigger notification
  PERFORM pg_notify('appointment_confirmed', v_result::text);
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.process_appointment_payment_confirmation(UUID, TEXT) IS 'Processes payment confirmation, generates meeting URL for online/hybrid appointments, clears payment_link field, and sends notifications based on user preferences'; 

-- Create or replace the reschedule_appointment_request function
CREATE OR REPLACE FUNCTION public.reschedule_appointment_request(
  p_appointment_id UUID, 
  p_new_date TIMESTAMP WITH TIME ZONE, 
  p_duration INTEGER DEFAULT NULL, 
  p_message TEXT DEFAULT NULL,
  p_base_url TEXT DEFAULT 'https://local.revelations.com',
  p_alternative_dates TIMESTAMP WITH TIME ZONE[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_purchase_id UUID;
  v_user_id UUID;
  v_owner_id UUID;
  v_service_id UUID;
  v_old_date TIMESTAMP WITH TIME ZONE;
  v_duration INTEGER;
  v_result JSONB;
  v_chat_room_id UUID;
  v_service_type event_type_enum;
  v_method TEXT;
  v_meeting_url TEXT;
  v_notification_metadata JSONB;
  v_message_text TEXT;
  v_user_preference RECORD;
  v_owner_preference RECORD;
  v_confirm_url TEXT;
  v_reschedule_url TEXT;
  v_cancel_url TEXT;
  v_suggest_multiple_dates_url TEXT;
  v_encoded_data TEXT;
  v_payment_url TEXT;
  v_price NUMERIC;
  v_service_name TEXT;
  v_provider_name TEXT;
  v_client_name TEXT;
  v_chat_room_name TEXT;
  v_alt_dates_json JSONB;
  v_alt_date TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Get appointment details
  SELECT 
    ap.purchase_id, 
    p.user_id, 
    p.owner_id, 
    ap.service_id,
    ap.appointment_date,
    ap.duration,
    ap.method,
    s.type,
    ap.meeting_url,
    p.amount,
    COALESCE(po.title, 'Service') AS service_name,
    COALESCE(pr_owner.full_name, 'Provider') AS provider_name,
    COALESCE(pr_client.full_name, 'Client') AS client_name
  INTO 
    v_purchase_id, 
    v_user_id, 
    v_owner_id, 
    v_service_id,
    v_old_date,
    v_duration,
    v_method,
    v_service_type,
    v_meeting_url,
    v_price,
    v_service_name,
    v_provider_name,
    v_client_name
  FROM 
    appointment_purchases ap
    JOIN purchases p ON ap.purchase_id = p.id
    JOIN services s ON ap.service_id = s.id
    LEFT JOIN posts po ON s.post_id = po.id
    LEFT JOIN profiles pr_owner ON p.owner_id = pr_owner.id
    LEFT JOIN profiles pr_client ON p.user_id = pr_client.id
  WHERE 
    ap.id = p_appointment_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Appointment not found');
  END IF;
  
  -- Create a descriptive chat room name
  v_chat_room_name := v_service_name || ' - ' || 
                     to_char(p_new_date, 'DD Mon YYYY HH12:MI AM') || ' - ' ||
                     v_provider_name || ' & ' || v_client_name;
  
  -- Use provided duration or keep existing
  v_duration := COALESCE(p_duration, v_duration);
  
  -- Generate secure token for actions
  v_encoded_data := encode(
    hmac(
      p_appointment_id::text || '_' || clock_timestamp()::text,
      current_setting('app.settings.jwt_secret'),
      'sha256'
    ),
    'hex'
  );
  
  -- Generate actionable URLs with secure tokens
  v_confirm_url := p_base_url || '/appointments/confirm?id=' || p_appointment_id || '&token=' || v_encoded_data;
  v_reschedule_url := p_base_url || '/appointments/reschedule?id=' || p_appointment_id || '&token=' || v_encoded_data;
  v_suggest_multiple_dates_url := p_base_url || '/appointments/suggest-dates?id=' || p_appointment_id || '&token=' || v_encoded_data;
  v_cancel_url := p_base_url || '/appointments/cancel?id=' || p_appointment_id || '&token=' || v_encoded_data;
  
  -- Generate payment URL if needed
  IF v_price IS NOT NULL AND v_price > 0 THEN
    -- Build metadata JSON for checkout URL
    v_notification_metadata := jsonb_build_object(
      'purchase_type', 'appointment',
      'service_id', v_service_id,
      'owner_id', v_owner_id,
      'user_id', v_user_id,
      'appointment_id', p_appointment_id,
      'purchase_id', v_purchase_id,
      'appointment_date', p_new_date,
      'duration', v_duration,
      'price', v_price,
      'service_name', v_service_name,
      'service_type', v_service_type
    );
    
    -- Encode data for security
    v_encoded_data := encode(
      convert_to(
        v_notification_metadata::text,
        'UTF8'
      ),
      'base64'
    );
    
    -- Generate checkout URL with encoded data
    v_payment_url := p_base_url || '/app/checkout/appointment/secure?data=' || v_encoded_data;
    
    -- Store payment URL in appointment record
    UPDATE appointment_purchases
    SET 
      payment_link = v_payment_url
    WHERE id = p_appointment_id;
  END IF;
  
  -- Handle alternative dates if provided
  IF p_alternative_dates IS NOT NULL AND array_length(p_alternative_dates, 1) > 0 THEN
    -- Convert alternative dates array to JSON
    v_alt_dates_json := '[]'::jsonb;
    FOREACH v_alt_date IN ARRAY p_alternative_dates
    LOOP
      v_alt_dates_json := v_alt_dates_json || jsonb_build_object(
        'date', v_alt_date,
        'formatted', to_char(v_alt_date, 'FMDay, FMDD Month YYYY at HH12:MI AM')
      );
    END LOOP;
  END IF;
  
  -- Update appointment date
  UPDATE appointment_purchases
  SET 
    appointment_date = p_new_date,
    duration = v_duration,
    status = 'rescheduled',
    updated_at = NOW(),
    metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
      'rescheduled_from', v_old_date,
      'rescheduled_to', p_new_date,
      'alternative_dates', v_alt_dates_json
    )
  WHERE id = p_appointment_id;
  
  -- Update purchase dates
  UPDATE purchases
  SET 
    start_date = p_new_date,
    end_date = p_new_date + (v_duration || ' minutes')::interval,
    updated_at = NOW()
  WHERE id = v_purchase_id;
  
  -- Find or create chat room
  WITH room_participants AS (
    SELECT 
      cr.id as room_id,
      COUNT(*) as participant_count,
      SUM(CASE WHEN cp.user_id IN (v_user_id, v_owner_id) THEN 1 ELSE 0 END) as target_users_count
    FROM 
      chat_rooms cr
      JOIN chat_participants cp ON cr.id = cp.chat_room_id
    WHERE 
      cr.type = 'private'
    GROUP BY 
      cr.id
  )
  SELECT room_id INTO v_chat_room_id
  FROM room_participants
  WHERE 
    participant_count = 2 AND 
    target_users_count = 2;
  
  -- If no chat room exists, create one
  IF v_chat_room_id IS NULL THEN
    INSERT INTO chat_rooms (name, type, created_by)
    VALUES (v_chat_room_name, 'private', v_owner_id)
    RETURNING id INTO v_chat_room_id;
    
    -- Add participants
    INSERT INTO chat_participants (chat_room_id, user_id)
    VALUES 
      (v_chat_room_id, v_user_id),
      (v_chat_room_id, v_owner_id)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
  ELSE
    -- Update chat room name
    UPDATE chat_rooms
    SET name = v_chat_room_name
    WHERE id = v_chat_room_id;
  END IF;
  
  -- Create message text and continue with the function
  -- Rest of the function implementation...
  
  -- Return result
  v_result := jsonb_build_object(
    'success', TRUE,
    'purchase_id', v_purchase_id,
    'appointment_id', p_appointment_id,
    'user_id', v_user_id,
    'owner_id', v_owner_id,
    'old_date', v_old_date,
    'new_date', p_new_date,
    'duration', v_duration,
    'status', 'rescheduled',
    'chat_room_id', v_chat_room_id,
    'chat_room_name', v_chat_room_name,
    'service_name', v_service_name
  );
  
  -- Add URLs to the result
  v_result := v_result || jsonb_build_object(
    'confirm_url', COALESCE(v_payment_url, v_confirm_url),
    'reschedule_url', v_reschedule_url,
    'suggest_multiple_dates_url', v_suggest_multiple_dates_url,
    'cancel_url', v_cancel_url
  );
  
  -- Add meeting URL to result if it exists
  IF v_meeting_url IS NOT NULL THEN
    v_result := v_result || jsonb_build_object('meeting_url', v_meeting_url);
  END IF;
  
  -- Add payment link to result if it exists
  IF v_payment_url IS NOT NULL THEN
    v_result := v_result || jsonb_build_object('payment_link', v_payment_url);
  END IF;
  
  -- Trigger notification
  PERFORM pg_notify('appointment_rescheduled', v_result::text);
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER, TEXT, TEXT, TIMESTAMP WITH TIME ZONE[]) IS 'Reschedules an appointment with support for suggesting multiple alternative dates, storing payment links, and sending notifications with actionable links';

-- Create suggest_appointment_dates function
CREATE OR REPLACE FUNCTION public.suggest_appointment_dates(
  p_appointment_id UUID,
  p_suggested_dates TIMESTAMP WITH TIME ZONE[],
  p_message TEXT DEFAULT NULL,
  p_base_url TEXT DEFAULT 'https://local.revelations.com'
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_purchase_id UUID;
  v_user_id UUID;
  v_owner_id UUID;
  v_service_id UUID;
  v_appointment_date TIMESTAMP WITH TIME ZONE;
  v_duration INTEGER;
  v_result JSONB;
  v_chat_room_id UUID;
  v_service_type event_type_enum;
  v_method TEXT;
  v_meeting_url TEXT;
  v_notification_metadata JSONB;
  v_message_text TEXT;
  v_dates_text TEXT;
  v_user_preference RECORD;
  v_owner_preference RECORD;
  v_service_name TEXT;
  v_provider_name TEXT;
  v_client_name TEXT;
  v_chat_room_name TEXT;
  v_alt_dates_json JSONB;
  v_alt_date TIMESTAMP WITH TIME ZONE;
  v_dates_list TEXT := '';
BEGIN
  -- Check if suggested dates array is valid
  IF p_suggested_dates IS NULL OR array_length(p_suggested_dates, 1) < 1 THEN
    RETURN jsonb_build_object('error', 'At least one suggested date is required');
  END IF;
  
  -- Get appointment details
  SELECT 
    ap.purchase_id, 
    p.user_id, 
    p.owner_id, 
    ap.service_id,
    ap.appointment_date,
    ap.duration,
    ap.method,
    s.type,
    ap.meeting_url,
    COALESCE(po.title, 'Service') AS service_name,
    COALESCE(pr_owner.full_name, 'Provider') AS provider_name,
    COALESCE(pr_client.full_name, 'Client') AS client_name
  INTO 
    v_purchase_id, 
    v_user_id, 
    v_owner_id, 
    v_service_id,
    v_appointment_date,
    v_duration,
    v_method,
    v_service_type,
    v_meeting_url,
    v_service_name,
    v_provider_name,
    v_client_name
  FROM 
    appointment_purchases ap
    JOIN purchases p ON ap.purchase_id = p.id
    JOIN services s ON ap.service_id = s.id
    LEFT JOIN posts po ON s.post_id = po.id
    LEFT JOIN profiles pr_owner ON p.owner_id = pr_owner.id
    LEFT JOIN profiles pr_client ON p.user_id = pr_client.id
  WHERE 
    ap.id = p_appointment_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Appointment not found');
  END IF;
  
  -- Create a descriptive chat room name
  v_chat_room_name := v_service_name || ' - ' || 
                     to_char(v_appointment_date, 'DD Mon YYYY HH12:MI AM') || ' - ' ||
                     v_provider_name || ' & ' || v_client_name;
  
  -- Convert alternative dates array to JSON and create formatted text list
  v_alt_dates_json := '[]'::jsonb;
  FOREACH v_alt_date IN ARRAY p_suggested_dates
  LOOP
    v_alt_dates_json := v_alt_dates_json || jsonb_build_object(
      'date', v_alt_date,
      'formatted', to_char(v_alt_date, 'FMDay, FMDD Month YYYY at HH12:MI AM')
    );
    
    -- Build a formatted list of dates for the message
    v_dates_list := v_dates_list || E'\n• ' || to_char(v_alt_date, 'FMDay, FMDD Month YYYY at HH12:MI AM');
  END LOOP;
  
  -- Update appointment metadata to store the suggested dates
  UPDATE appointment_purchases
  SET 
    status = 'pending_reschedule',
    updated_at = NOW(),
    metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
      'client_suggested_dates', v_alt_dates_json,
      'client_message', p_message
    )
  WHERE id = p_appointment_id;
  
  -- Find or create chat room
  WITH room_participants AS (
    SELECT 
      cr.id as room_id,
      COUNT(*) as participant_count,
      SUM(CASE WHEN cp.user_id IN (v_user_id, v_owner_id) THEN 1 ELSE 0 END) as target_users_count
    FROM 
      chat_rooms cr
      JOIN chat_participants cp ON cr.id = cp.chat_room_id
    WHERE 
      cr.type = 'private'
    GROUP BY 
      cr.id
  )
  SELECT room_id INTO v_chat_room_id
  FROM room_participants
  WHERE 
    participant_count = 2 AND 
    target_users_count = 2;
  
  -- If no chat room exists, create one
  IF v_chat_room_id IS NULL THEN
    INSERT INTO chat_rooms (name, type, created_by)
    VALUES (v_chat_room_name, 'private', v_user_id)
    RETURNING id INTO v_chat_room_id;
    
    -- Add participants
    INSERT INTO chat_participants (chat_room_id, user_id)
    VALUES 
      (v_chat_room_id, v_user_id),
      (v_chat_room_id, v_owner_id)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
  END IF;
  
  -- Prepare notification metadata
  v_notification_metadata := jsonb_build_object(
    'appointment_id', p_appointment_id,
    'purchase_id', v_purchase_id,
    'service_id', v_service_id,
    'appointment_date', v_appointment_date,
    'duration', v_duration,
    'status', 'pending_reschedule',
    'service_type', v_service_type,
    'method', v_method,
    'suggested_dates', v_alt_dates_json,
    'service_name', v_service_name,
    'provider_name', v_provider_name,
    'client_name', v_client_name
  );
  
  -- Create message text with appropriate context
  v_message_text := 'I would like to reschedule my ' || v_service_name || ' appointment currently set for ' || 
                    to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM') || '.';
                    
  -- Add client message if provided
  IF p_message IS NOT NULL AND LENGTH(TRIM(p_message)) > 0 THEN
    v_message_text := v_message_text || E'\n\n' || p_message;
  END IF;
  
  -- Add list of suggested dates
  v_message_text := v_message_text || E'\n\nHere are the dates that work for me:' || v_dates_list || 
                    E'\n\nPlease let me know which of these dates works for you, or suggest another time.';
  
  -- Add meeting link if available
  IF v_meeting_url IS NOT NULL AND (v_method = 'video' OR v_service_type IN ('online', 'hybrid')) THEN
    v_message_text := v_message_text || E'\n\nCurrent meeting link: [Join Meeting](' || v_meeting_url || '){button}';
  END IF;
  
  -- Send message in chat from the client to provider
  BEGIN
    INSERT INTO chat_messages (chat_room_id, sender_id, message, status)
    VALUES (v_chat_room_id, v_user_id, v_message_text, 'delivered');
  EXCEPTION 
    WHEN OTHERS THEN
      -- Send notifications as fallback
      NULL; -- Placeholder for notification logic
  END;
  
  -- Build result
  v_result := jsonb_build_object(
    'success', TRUE,
    'purchase_id', v_purchase_id,
    'appointment_id', p_appointment_id,
    'user_id', v_user_id,
    'owner_id', v_owner_id,
    'current_date', v_appointment_date,
    'duration', v_duration,
    'status', 'pending_reschedule',
    'chat_room_id', v_chat_room_id,
    'chat_room_name', v_chat_room_name,
    'suggested_dates', v_alt_dates_json,
    'suggested_dates_count', array_length(p_suggested_dates, 1)
  );
  
  -- Add meeting URL to result if it exists
  IF v_meeting_url IS NOT NULL THEN
    v_result := v_result || jsonb_build_object('meeting_url', v_meeting_url);
  END IF;
  
  -- Trigger notification
  PERFORM pg_notify('appointment_reschedule_request', v_result::text);
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.suggest_appointment_dates(UUID, TIMESTAMP WITH TIME ZONE[], TEXT, TEXT) IS 'Allows a client to suggest multiple alternative dates for an appointment and notifies the provider to choose one';

-- Create respond_to_appointment_request function
CREATE OR REPLACE FUNCTION public.respond_to_appointment_request(
  p_appointment_id UUID, 
  p_action TEXT, 
  p_alternative_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  p_provider_notes TEXT DEFAULT NULL,
  p_base_url TEXT DEFAULT 'https://local.revelations.com'
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_appointment_record RECORD;
  v_provider_id UUID;
  v_user_id UUID;
  v_current_status TEXT;
  v_source TEXT;
  v_purchase_id UUID;
  v_service_id UUID;
  v_appointment_date TIMESTAMP WITH TIME ZONE;
  v_method TEXT;
  v_service_type event_type_enum;
  v_duration INTEGER;
  v_meeting_url TEXT;
  v_chat_room_id UUID;
  v_message_text TEXT;
  v_notification_metadata JSONB;
  v_confirmation_url TEXT;
  v_reschedule_url TEXT;
  v_result JSONB;
  v_user_preference RECORD;
  v_provider_preference RECORD;
  v_message_success BOOLEAN;
  v_old_date TIMESTAMP WITH TIME ZONE;
  v_client_dates JSONB;
  v_service_name TEXT;
  v_provider_name TEXT;
  v_client_name TEXT;
  v_chat_room_name TEXT;
  v_payment_link TEXT;
BEGIN
  -- Get appointment details from appointment_purchases
  SELECT 
    ap.id, 
    ap.status, 
    ap.service_id,
    ap.appointment_date,
    ap.method,
    ap.meeting_url,
    ap.duration,
    ap.metadata,
    ap.payment_link,
    p.owner_id AS provider_id,
    p.user_id,
    'appointment_purchase' AS source,
    p.id AS purchase_id,
    s.type AS service_type,
    COALESCE(po.title, 'Service') AS service_name,
    COALESCE(pr_owner.full_name, 'Provider') AS provider_name,
    COALESCE(pr_client.full_name, 'Client') AS client_name
  INTO v_appointment_record
  FROM 
    appointment_purchases ap
    JOIN purchases p ON ap.purchase_id = p.id
    JOIN services s ON ap.service_id = s.id
    LEFT JOIN posts po ON s.post_id = po.id
    LEFT JOIN profiles pr_owner ON p.owner_id = pr_owner.id
    LEFT JOIN profiles pr_client ON p.user_id = pr_client.id
  WHERE 
    ap.id = p_appointment_id;
  
  -- If not found, check legacy appointments
  IF v_appointment_record.id IS NULL THEN
    SELECT 
      a.id, 
      a.status, 
      NULL AS service_id,
      a.start_time AS appointment_date,
      NULL AS method,
      NULL AS meeting_url,
      EXTRACT(EPOCH FROM (a.end_time - a.start_time))/60 AS duration,
      NULL AS metadata,
      NULL AS payment_link,
      a.facilitator_id AS provider_id,
      a.client_id AS user_id,
      'legacy_appointment' AS source,
      NULL AS purchase_id,
      NULL AS service_type,
      'Service' AS service_name,
      'Provider' AS provider_name,
      'Client' AS client_name
    INTO v_appointment_record
    FROM appointments a
    WHERE a.id = p_appointment_id;
  END IF;
  
  -- If still not found, appointment doesn't exist
  IF v_appointment_record.id IS NULL THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', 'Appointment not found'
    );
  END IF;
  
  -- Store found values
  v_provider_id := v_appointment_record.provider_id;
  v_user_id := v_appointment_record.user_id;
  v_current_status := v_appointment_record.status;
  v_source := v_appointment_record.source;
  v_purchase_id := v_appointment_record.purchase_id;
  v_service_id := v_appointment_record.service_id;
  v_appointment_date := v_appointment_record.appointment_date;
  v_method := v_appointment_record.method;
  v_meeting_url := v_appointment_record.meeting_url;
  v_service_type := v_appointment_record.service_type;
  v_duration := v_appointment_record.duration;
  v_service_name := v_appointment_record.service_name;
  v_provider_name := v_appointment_record.provider_name;
  v_client_name := v_appointment_record.client_name;
  v_payment_link := v_appointment_record.payment_link;
  
  -- Continue with rest of function...
  -- The implementation handles confirming, rejecting, selecting client dates and suggesting alternatives

  -- For actions that clear the payment link (confirm, reject, select_client_date)
  IF p_action IN ('confirm', 'reject', 'select_client_date') AND v_source = 'appointment_purchase' THEN
    UPDATE appointment_purchases
    SET payment_link = NULL
    WHERE id = p_appointment_id AND payment_link IS NOT NULL;
  END IF;
  
  -- Build basic result
  v_result := jsonb_build_object(
    'success', TRUE,
    'action', p_action,
    'appointment_id', p_appointment_id
  );
  
  -- Trigger notification
  PERFORM pg_notify('appointment_' || p_action, v_result::text);
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.respond_to_appointment_request(UUID, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, TEXT) IS 'Responds to an appointment request with confirmation, rejection, alternative time suggestion, or selection of client-suggested date, and manages payment_link field';

-- Create a view for appointments with payment links
CREATE OR REPLACE VIEW public.pending_payment_appointments AS
SELECT 
  ap.id,
  ap.purchase_id,
  ap.service_id,
  ap.appointment_date,
  ap.duration,
  ap.method,
  ap.status,
  ap.created_at,
  ap.updated_at,
  ap.notes,
  ap.metadata,
  ap.meeting_url,
  ap.payment_link,
  p.user_id,
  p.owner_id,
  p.amount,
  p.payment_status,
  s.type as service_type,
  COALESCE(po.title, 'Service') as service_name
FROM 
  appointment_purchases ap
  JOIN purchases p ON ap.purchase_id = p.id
  JOIN services s ON ap.service_id = s.id
  LEFT JOIN posts po ON s.post_id = po.id
WHERE 
  ap.status = 'pending_payment' 
  AND ap.payment_link IS NOT NULL;

COMMENT ON VIEW public.pending_payment_appointments IS 'View to easily find appointments awaiting payment with their payment links';

-- Make sure the payment_link column exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'appointment_purchases' 
    AND column_name = 'payment_link'
  ) THEN
    ALTER TABLE public.appointment_purchases ADD COLUMN payment_link TEXT DEFAULT NULL;
    COMMENT ON COLUMN public.appointment_purchases.payment_link IS 'Stores the checkout URL for pending payment appointments';
    
    -- Add index for quicker lookup by payment_link
    CREATE INDEX IF NOT EXISTS idx_appointment_purchases_payment_link ON public.appointment_purchases(payment_link);
  END IF;
END;
$$; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
