
-- Drop existing functions
DROP FUNCTION IF EXISTS public.approve_appointment_request(UUID, NUMERIC, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.process_appointment_payment_confirmation(UUID, TEXT);
DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER, TEXT, TEXT, TIMESTAMP WITH TIME ZONE[]);
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(UUID, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.suggest_appointment_dates(UUID, TIMESTAMP WITH TIME ZONE[], TEXT, TEXT);


-- Create the functions with proper syntax
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
  
  -- Update appointment status
  UPDATE appointment_purchases
  SET 
    status = 'pending_payment',
    updated_at = NOW()
  WHERE id = p_appointment_id;
  
  -- Update purchase with price
  UPDATE purchases
  SET 
    amount = p_price,
    payment_status = 'pending',
    updated_at = NOW()
  WHERE id = v_purchase_id;
  
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
    'metadata', v_metadata
  );
  
  -- Trigger notification
  PERFORM pg_notify('appointment_approved', v_result::text);
  
  RETURN v_result;
END;
$$;

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
    
    -- Update appointment with meeting URL
    UPDATE appointment_purchases
    SET 
      status = 'confirmed',
      meeting_url = v_meeting_url,
      meeting_id = NULL,
      updated_at = NOW()
    WHERE purchase_id = p_purchase_id;
  ELSE
    -- For in-person appointments, just update status
    UPDATE appointment_purchases
    SET 
      status = 'confirmed',
      meeting_id = NULL,
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
        -- Get user preferences
        SELECT * INTO v_user_preference 
        FROM notification_preferences 
        WHERE user_id = v_user_id AND type = 'appointment';
        
        -- Default preferences if none set
        IF NOT FOUND THEN
          v_user_preference := ROW(NULL, v_user_id, 'appointment', TRUE, TRUE, TRUE, FALSE)::notification_preferences;
        END IF;
        
        -- Get owner preferences
        SELECT * INTO v_owner_preference 
        FROM notification_preferences 
        WHERE user_id = v_owner_id AND type = 'appointment';
        
        -- Default preferences if none set
        IF NOT FOUND THEN
          v_owner_preference := ROW(NULL, v_owner_id, 'appointment', TRUE, TRUE, TRUE, FALSE)::notification_preferences;
        END IF;
        
        -- Send notifications based on preferences
        IF v_user_preference.in_app THEN
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
            'Appointment Confirmed',
            v_message_text,
            'appointment',
            '/appointments/' || v_appointment_id,
            v_appointment_id,
            'appointment',
            v_notification_metadata
          );
        END IF;
        
        -- Notify provider
        IF v_owner_preference.in_app THEN
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
            v_owner_id,
            'Payment Received',
            'Payment completed for appointment on ' || to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM'),
            'appointment',
            '/appointments/' || v_appointment_id,
            v_appointment_id,
            'appointment',
            v_notification_metadata
          );
        END IF;
        
        -- Email notifications
        IF v_user_preference.email THEN
          PERFORM pg_notify('email_notification', 
            jsonb_build_object(
              'recipient_id', v_user_id,
              'type', 'appointment_confirmed',
              'data', v_notification_metadata
            )::text
          );
        END IF;
        
        IF v_owner_preference.email THEN
          PERFORM pg_notify('email_notification', 
            jsonb_build_object(
              'recipient_id', v_owner_id,
              'type', 'appointment_payment_received',
              'data', v_notification_metadata
            )::text
          );
        END IF;
        
        -- Push notifications
        IF v_user_preference.push THEN
          PERFORM pg_notify('push_notification', 
            jsonb_build_object(
              'recipient_id', v_user_id,
              'title', 'Appointment Confirmed',
              'body', 'Your appointment on ' || to_char(v_appointment_date, 'DD MMM') || ' has been confirmed',
              'data', v_notification_metadata
            )::text
          );
        END IF;
        
        IF v_owner_preference.push THEN
          PERFORM pg_notify('push_notification', 
            jsonb_build_object(
              'recipient_id', v_owner_id,
              'title', 'Payment Received',
              'body', 'Payment received for appointment on ' || to_char(v_appointment_date, 'DD MMM'),
              'data', v_notification_metadata
            )::text
          );
        END IF;
        
        -- SMS notifications
        IF v_user_preference.sms THEN
          PERFORM pg_notify('sms_notification', 
            jsonb_build_object(
              'recipient_id', v_user_id,
              'message', 'Your appointment on ' || to_char(v_appointment_date, 'DD MMM') || ' has been confirmed' ||
                CASE WHEN v_meeting_url IS NOT NULL THEN '. Meeting URL: ' || v_meeting_url ELSE '' END,
              'data', v_notification_metadata
            )::text
          );
        END IF;
        
        IF v_owner_preference.sms THEN
          PERFORM pg_notify('sms_notification', 
            jsonb_build_object(
              'recipient_id', v_owner_id,
              'message', 'Payment received for appointment on ' || to_char(v_appointment_date, 'DD MMM'),
              'data', v_notification_metadata
            )::text
          );
        END IF;
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

COMMENT ON FUNCTION public.process_appointment_payment_confirmation(UUID, TEXT) IS 'Processes payment confirmation, generates meeting URL for online/hybrid appointments, and sends notifications based on user preferences'; 

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
  
  -- Prepare notification metadata
  v_notification_metadata := jsonb_build_object(
    'appointment_id', p_appointment_id,
    'purchase_id', v_purchase_id,
    'service_id', v_service_id,
    'old_date', v_old_date,
    'new_date', p_new_date,
    'duration', v_duration,
    'status', 'rescheduled',
    'service_type', v_service_type,
    'method', v_method,
    'price', v_price,
    'service_name', v_service_name,
    'provider_name', v_provider_name,
    'client_name', v_client_name
  );
  
  -- Add alternative dates to metadata if provided
  IF v_alt_dates_json IS NOT NULL THEN
    v_notification_metadata := v_notification_metadata || jsonb_build_object('alternative_dates', v_alt_dates_json);
  END IF;
  
  -- Add URLs to metadata
  v_notification_metadata := v_notification_metadata || jsonb_build_object(
    'confirm_url', COALESCE(v_payment_url, v_confirm_url),
    'reschedule_url', v_reschedule_url,
    'suggest_multiple_dates_url', v_suggest_multiple_dates_url,
    'cancel_url', v_cancel_url
  );
  
  -- Add meeting URL to metadata if it exists
  IF v_meeting_url IS NOT NULL THEN
    v_notification_metadata := v_notification_metadata || jsonb_build_object('meeting_url', v_meeting_url);
  END IF;
  
  -- Create message text with appropriate context
  v_message_text := COALESCE(
    p_message,
    'Your ' || v_service_name || ' appointment has been rescheduled from ' || 
    to_char(v_old_date, 'FMDay, FMDD Month YYYY at HH12:MI AM') || 
    ' to ' || 
    to_char(p_new_date, 'FMDay, FMDD Month YYYY at HH12:MI AM')
  );
  
  -- Add meeting URL to message if applicable
  IF v_meeting_url IS NOT NULL AND (v_method = 'video' OR v_service_type IN ('online', 'hybrid')) THEN
    v_message_text := v_message_text || E'\n\nJoin the meeting at: [Join Meeting](' || v_meeting_url || '){button}';
  END IF;
  
  -- Add actionable links to the message
  v_message_text := v_message_text || E'\n\nPlease choose one of the following options:';
  
  -- If payment is required, provide payment link
  IF v_price IS NOT NULL AND v_price > 0 AND v_payment_url IS NOT NULL THEN
    v_message_text := v_message_text || E'\n\n1. [Confirm and Pay](' || v_payment_url || '){button}';
  ELSE 
    v_message_text := v_message_text || E'\n\n1. [Confirm Appointment](' || v_confirm_url || '){button}';
  END IF;
  
  v_message_text := v_message_text || 
                    E'\n\n2. [Suggest Alternative Dates](' || v_suggest_multiple_dates_url || '){button}' || 
                    E'\n\n3. [Request Different Time](' || v_reschedule_url || '){button}' || 
                    E'\n\n4. [Cancel Appointment](' || v_cancel_url || '){button}';
  
  -- Send notification message via chat system
  BEGIN
    INSERT INTO chat_messages (chat_room_id, sender_id, message, status)
    VALUES (v_chat_room_id, v_owner_id, v_message_text, 'delivered');
  EXCEPTION 
    WHEN OTHERS THEN
      -- Fallback to notifications
      BEGIN
        -- Check user preferences
        SELECT * INTO v_user_preference 
        FROM notification_preferences 
        WHERE user_id = v_user_id AND type = 'appointment';
        
        -- Default preferences if none set
        IF NOT FOUND THEN
          v_user_preference := ROW(NULL, v_user_id, 'appointment', TRUE, TRUE, TRUE, FALSE)::notification_preferences;
        END IF;
        
        -- Notify client based on preferences
        IF v_user_preference.in_app THEN
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
            'Appointment Rescheduled',
            v_message_text,
            'appointment',
            COALESCE(v_payment_url, v_confirm_url),
            p_appointment_id,
            'appointment',
            v_notification_metadata
          );
        END IF;
        
        -- Email notification
        IF v_user_preference.email THEN
          PERFORM pg_notify('email_notification', 
            jsonb_build_object(
              'recipient_id', v_user_id,
              'type', 'appointment_rescheduled',
              'data', v_notification_metadata
            )::text
          );
        END IF;
        
        -- Push notification
        IF v_user_preference.push THEN
          PERFORM pg_notify('push_notification', 
            jsonb_build_object(
              'recipient_id', v_user_id,
              'title', 'Appointment Rescheduled',
              'body', 'Your ' || v_service_name || ' appointment has been rescheduled. Tap to confirm or suggest alternative times.',
              'data', v_notification_metadata
            )::text
          );
        END IF;
        
        -- SMS notification
        IF v_user_preference.sms THEN
          PERFORM pg_notify('sms_notification', 
            jsonb_build_object(
              'recipient_id', v_user_id,
              'message', 'Your ' || v_service_name || ' appointment with ' || v_provider_name || 
                        ' has been rescheduled to ' || to_char(p_new_date, 'DD MMM, HH12:MI AM') || 
                        '. Check your email or app to confirm or suggest alternative times.',
              'data', v_notification_metadata
            )::text
          );
        END IF;
      END;
  END;
  
  -- Build result
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
    'service_name', v_service_name,
    'suggested_dates', v_alt_dates_json,
    'suggested_dates_count', array_length(p_alternative_dates, 1)
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
  
  -- Trigger notification
  PERFORM pg_notify('appointment_rescheduled', v_result::text);
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER, TEXT, TEXT, TIMESTAMP WITH TIME ZONE[]) IS 'Reschedules an appointment with support for suggesting multiple alternative dates and sending notifications with actionable links'; 

-- Create a new function to handle client suggesting multiple dates for an appointment
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
      -- Fallback to notifications
      BEGIN
        -- Check provider preferences
        SELECT * INTO v_owner_preference 
        FROM notification_preferences 
        WHERE user_id = v_owner_id AND type = 'appointment';
        
        -- Default preferences if none set
        IF NOT FOUND THEN
          v_owner_preference := ROW(NULL, v_owner_id, 'appointment', TRUE, TRUE, TRUE, FALSE)::notification_preferences;
        END IF;
        
        -- Send in-app notification to provider
        IF v_owner_preference.in_app THEN
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
            v_owner_id,
            'Reschedule Request: ' || v_service_name,
            'Client has suggested ' || array_length(p_suggested_dates, 1) || ' alternative dates for their appointment',
            'appointment',
            p_base_url || '/appointments/manage/' || p_appointment_id,
            p_appointment_id,
            'appointment',
            v_notification_metadata
          );
        END IF;
        
        -- Email notification
        IF v_owner_preference.email THEN
          PERFORM pg_notify('email_notification', 
            jsonb_build_object(
              'recipient_id', v_owner_id,
              'type', 'appointment_reschedule_request',
              'data', v_notification_metadata
            )::text
          );
        END IF;
        
        -- Push notification
        IF v_owner_preference.push THEN
          PERFORM pg_notify('push_notification', 
            jsonb_build_object(
              'recipient_id', v_owner_id,
              'title', 'Reschedule Request',
              'body', v_client_name || ' suggested ' || array_length(p_suggested_dates, 1) || ' alternative dates for their ' || v_service_name,
              'data', v_notification_metadata
            )::text
          );
        END IF;
        
        -- SMS notification
        IF v_owner_preference.sms THEN
          PERFORM pg_notify('sms_notification', 
            jsonb_build_object(
              'recipient_id', v_owner_id,
              'message', 'Reschedule request from ' || v_client_name || ' for ' || v_service_name || '. They suggested ' || 
                       array_length(p_suggested_dates, 1) || ' alternative dates. Check your email or app to respond.',
              'data', v_notification_metadata
            )::text
          );
        END IF;
      END;
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

-- Create or replace respond_to_appointment_request function
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
BEGIN
  -- Get appointment details
  SELECT 
    ap.id, 
    ap.status, 
    ap.service_id,
    ap.appointment_date,
    ap.method,
    ap.meeting_url,
    ap.duration,
    ap.metadata,
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
  
  -- Extract client suggested dates if available in metadata
  IF v_appointment_record.metadata IS NOT NULL AND v_appointment_record.metadata ? 'client_suggested_dates' THEN
    v_client_dates := v_appointment_record.metadata->'client_suggested_dates';
  END IF;
  
  -- Create a descriptive chat room name
  v_chat_room_name := v_service_name || ' - ' || 
                     to_char(v_appointment_date, 'DD Mon YYYY HH12:MI AM') || ' - ' ||
                     v_provider_name || ' & ' || v_client_name;
  
  -- Generate confirmation and reschedule URLs with secure tokens
  v_confirmation_url := p_base_url || '/appointments/confirm?id=' || p_appointment_id || '&token=' || 
                      encode(hmac(p_appointment_id::text, current_setting('app.settings.jwt_secret'), 'sha256'), 'hex');
                      
  v_reschedule_url := p_base_url || '/appointments/reschedule?id=' || p_appointment_id || '&token=' || 
                     encode(hmac(p_appointment_id::text, current_setting('app.settings.jwt_secret'), 'sha256'), 'hex');
  
  -- Process the response based on source system
  IF v_source = 'appointment_purchase' THEN
    -- Handle appointment_purchases
    IF p_action = 'confirm' THEN
      IF v_current_status NOT IN ('pending_approval', 'pending_payment') THEN
        RETURN jsonb_build_object(
          'success', FALSE,
          'error', 'Appointment cannot be confirmed in its current status: ' || v_current_status
        );
      END IF;
      
      -- Update to confirmed
      UPDATE appointment_purchases
      SET 
        status = 'confirmed',
        notes = CASE 
          WHEN p_provider_notes IS NOT NULL THEN 
            COALESCE(notes, '') || E'\nProvider notes: ' || p_provider_notes
          ELSE notes
        END,
        updated_at = NOW()
      WHERE id = p_appointment_id;
      
      -- Also update purchase if needed
      IF v_current_status = 'pending_approval' THEN
        UPDATE purchases
        SET payment_status = 'completed'
        WHERE id = v_purchase_id;
      END IF;
      
      -- Generate meeting URL for online/hybrid services if not exists
      IF (v_method = 'video' OR v_service_type IN ('online', 'hybrid')) AND v_meeting_url IS NULL THEN
        v_meeting_url := p_base_url || '/meeting/private/' || gen_random_uuid();
        
        -- Update appointment with meeting URL
        UPDATE appointment_purchases
        SET 
          meeting_url = v_meeting_url,
          meeting_id = NULL
        WHERE id = p_appointment_id;
      END IF;
      
      v_message_text := 'Your appointment has been confirmed for ' || 
                       to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM');
                       
      IF v_meeting_url IS NOT NULL THEN
        v_message_text := v_message_text || E'\n\nJoin the meeting at: [Join Meeting](' || v_meeting_url || '){button}';
      END IF;
      
      IF p_provider_notes IS NOT NULL AND LENGTH(TRIM(p_provider_notes)) > 0 THEN
        v_message_text := v_message_text || E'\n\nNotes from provider: ' || p_provider_notes;
      END IF;
      
      v_result := jsonb_build_object(
        'success', TRUE,
        'action', 'confirm',
        'appointment_id', p_appointment_id,
        'status', 'confirmed'
      );
      
    ELSIF p_action = 'reject' THEN
      IF v_current_status NOT IN ('pending_approval', 'pending_payment', 'confirmed') THEN
        RETURN jsonb_build_object(
          'success', FALSE,
          'error', 'Appointment cannot be rejected in its current status: ' || v_current_status
        );
      END IF;
      
      -- Update to cancelled
      UPDATE appointment_purchases
      SET 
        status = 'cancelled',
        notes = CASE 
          WHEN p_provider_notes IS NOT NULL THEN 
            COALESCE(notes, '') || E'\nRejection reason: ' || p_provider_notes
          ELSE notes
        END,
        updated_at = NOW()
      WHERE id = p_appointment_id;
      
      -- If payment was already made, set to refunded
      IF v_current_status IN ('confirmed', 'pending_payment') THEN
        UPDATE purchases
        SET payment_status = 'refunded'
        WHERE id = v_purchase_id;
      END IF;
      
      v_message_text := 'Your appointment request for ' || 
                       to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM') || 
                       ' has been rejected.';
                       
      IF p_provider_notes IS NOT NULL AND LENGTH(TRIM(p_provider_notes)) > 0 THEN
        v_message_text := v_message_text || E'\n\nReason: ' || p_provider_notes;
      END IF;
      
      v_message_text := v_message_text || E'\n\nIf you would like to book another appointment, please visit our scheduling page.';
      
      v_result := jsonb_build_object(
        'success', TRUE,
        'action', 'reject',
        'appointment_id', p_appointment_id,
        'status', 'cancelled'
      );
      
    ELSIF p_action = 'select_client_date' THEN
      -- This action is for when a provider selects one of the client's suggested dates
      IF v_current_status <> 'pending_reschedule' OR p_alternative_time IS NULL THEN
        RETURN jsonb_build_object(
          'success', FALSE,
          'error', 'Cannot select client date in current status or missing date parameter'
        );
      END IF;
      
      -- Store the old date before updating
      v_old_date := v_appointment_date;
      
      -- Update appointment with the selected date
      UPDATE appointment_purchases
      SET 
        appointment_date = p_alternative_time,
        status = 'confirmed',
        notes = CASE 
          WHEN p_provider_notes IS NOT NULL THEN 
            COALESCE(notes, '') || E'\nProvider selected client suggested date: ' || 
            TO_CHAR(p_alternative_time, 'YYYY-MM-DD HH24:MI:SS')
          ELSE notes
        END,
        metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
          'rescheduled_from', v_old_date,
          'rescheduled_to', p_alternative_time,
          'provider_selected_client_date', TRUE
        ),
        updated_at = NOW()
      WHERE id = p_appointment_id;
      
      -- Update purchase dates
      UPDATE purchases
      SET 
        start_date = p_alternative_time,
        end_date = p_alternative_time + (v_duration || ' minutes')::interval,
        updated_at = NOW()
      WHERE id = v_purchase_id;
      
      -- Update chat room name with new date
      v_chat_room_name := v_service_name || ' - ' || 
                         to_char(p_alternative_time, 'DD Mon YYYY HH12:MI AM') || ' - ' ||
                         v_provider_name || ' & ' || v_client_name;
      
      -- Find chat room and update name
      SELECT chat_room_id INTO v_chat_room_id
      FROM chat_participants
      WHERE user_id = v_user_id
      GROUP BY chat_room_id
      HAVING COUNT(*) = 2 AND
             EXISTS (
               SELECT 1 
               FROM chat_participants 
               WHERE chat_room_id = chat_participants.chat_room_id 
               AND user_id = v_provider_id
             );
             
      IF v_chat_room_id IS NOT NULL THEN
        UPDATE chat_rooms
        SET name = v_chat_room_name
        WHERE id = v_chat_room_id;
      END IF;
      
      -- Generate meeting URL for online/hybrid services if not exists
      IF (v_method = 'video' OR v_service_type IN ('online', 'hybrid')) AND v_meeting_url IS NULL THEN
        v_meeting_url := p_base_url || '/meeting/private/' || gen_random_uuid();
        
        -- Update appointment with meeting URL
        UPDATE appointment_purchases
        SET 
          meeting_url = v_meeting_url,
          meeting_id = NULL
        WHERE id = p_appointment_id;
      END IF;
      
      v_message_text := 'Good news! I''ve selected one of your suggested dates for the ' || v_service_name || ' appointment.' ||
                      E'\n\nYour appointment is now confirmed for ' || 
                      to_char(p_alternative_time, 'FMDay, FMDD Month YYYY at HH12:MI AM');
                       
      IF v_meeting_url IS NOT NULL THEN
        v_message_text := v_message_text || E'\n\nJoin the meeting at: [Join Meeting](' || v_meeting_url || '){button}';
      END IF;
      
      IF p_provider_notes IS NOT NULL AND LENGTH(TRIM(p_provider_notes)) > 0 THEN
        v_message_text := v_message_text || E'\n\nNotes from provider: ' || p_provider_notes;
      END IF;
      
      v_result := jsonb_build_object(
        'success', TRUE,
        'action', 'select_client_date',
        'appointment_id', p_appointment_id,
        'old_date', v_old_date,
        'new_date', p_alternative_time,
        'status', 'confirmed'
      );
      
    ELSIF p_action = 'suggest_alternative' THEN
      IF v_current_status NOT IN ('pending_approval', 'pending_payment', 'pending_reschedule') OR p_alternative_time IS NULL THEN
        RETURN jsonb_build_object(
          'success', FALSE,
          'error', 'Cannot suggest alternative time'
        );
      END IF;
      
      -- Create a record of the suggestion in metadata
      UPDATE appointment_purchases
      SET 
        notes = COALESCE(notes, '') || E'\nAlternative time suggested: ' || 
          TO_CHAR(p_alternative_time, 'YYYY-MM-DD HH24:MI:SS'),
        metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
          'alternative_time', p_alternative_time,
          'suggestion_notes', p_provider_notes
        ),
        updated_at = NOW()
      WHERE id = p_appointment_id;
      
      v_message_text := 'Your appointment request for ' || 
                       to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM') || 
                       ' could not be accommodated at the requested time.' || 
                       E'\n\nThe provider has suggested an alternative time: ' || 
                       to_char(p_alternative_time, 'FMDay, FMDD Month YYYY at HH12:MI AM');
                       
      IF p_provider_notes IS NOT NULL AND LENGTH(TRIM(p_provider_notes)) > 0 THEN
        v_message_text := v_message_text || E'\n\nProvider message: ' || p_provider_notes;
      END IF;
      
      v_message_text := v_message_text || 
                       E'\n\nPlease use one of the following options:' ||
                       E'\n\n1. [Accept Suggested Time](' || v_confirmation_url || '){button}' || 
                       E'\n\n2. [Suggest Another Time](' || v_reschedule_url || '){button}';
      
      v_result := jsonb_build_object(
        'success', TRUE,
        'action', 'suggest_alternative',
        'appointment_id', p_appointment_id,
        'suggested_time', p_alternative_time
      );
    ELSE
      RETURN jsonb_build_object(
        'success', FALSE,
        'error', 'Invalid action: ' || p_action
      );
    END IF;
    
    -- Find or create chat room for messaging
    WITH room_participants AS (
      SELECT 
        cr.id as room_id,
        COUNT(*) as participant_count,
        SUM(CASE WHEN cp.user_id IN (v_user_id, v_provider_id) THEN 1 ELSE 0 END) as target_users_count
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
      VALUES (v_chat_room_name, 'private', v_provider_id)
      RETURNING id INTO v_chat_room_id;
      
      -- Add participants
      INSERT INTO chat_participants (chat_room_id, user_id)
      VALUES 
        (v_chat_room_id, v_user_id),
        (v_chat_room_id, v_provider_id)
      ON CONFLICT (chat_room_id, user_id) DO NOTHING;
    END IF;
    
    -- Prepare notification metadata
    v_notification_metadata := jsonb_build_object(
      'appointment_id', p_appointment_id,
      'purchase_id', v_purchase_id,
      'service_id', v_service_id,
      'status', CASE 
        WHEN p_action = 'confirm' THEN 'confirmed'
        WHEN p_action = 'reject' THEN 'cancelled'
        WHEN p_action = 'suggest_alternative' THEN 'pending_reschedule'
        WHEN p_action = 'select_client_date' THEN 'confirmed'
        ELSE v_current_status
      END,
      'appointment_date', CASE
        WHEN p_action = 'select_client_date' THEN p_alternative_time
        ELSE v_appointment_date
      END,
      'service_type', v_service_type,
      'action', p_action,
      'service_name', v_service_name,
      'provider_name', v_provider_name,
      'client_name', v_client_name
    );
    
    -- Add meeting URL to metadata if it exists
    IF v_meeting_url IS NOT NULL THEN
      v_notification_metadata := v_notification_metadata || jsonb_build_object('meeting_url', v_meeting_url);
    END IF;
    
    -- Add alternative time to metadata if provided
    IF p_alternative_time IS NOT NULL THEN
      v_notification_metadata := v_notification_metadata || jsonb_build_object('alternative_time', p_alternative_time);
    END IF;
    
    -- If selecting client date, add old date to metadata
    IF p_action = 'select_client_date' THEN
      v_notification_metadata := v_notification_metadata || jsonb_build_object('old_date', v_old_date);
    END IF;
    
    -- Send message in chat
    BEGIN
      INSERT INTO chat_messages (chat_room_id, sender_id, message, status)
      VALUES (v_chat_room_id, v_provider_id, v_message_text, 'delivered');
      v_message_success := TRUE;
    EXCEPTION 
      WHEN OTHERS THEN
        -- Fallback to notifications
        v_message_success := FALSE;
        
        BEGIN
          -- Check user preferences
          SELECT * INTO v_user_preference 
          FROM notification_preferences 
          WHERE user_id = v_user_id AND type = 'appointment';
          
          -- Default preferences if none set
          IF NOT FOUND THEN
            v_user_preference := ROW(NULL, v_user_id, 'appointment', TRUE, TRUE, TRUE, FALSE)::notification_preferences;
          END IF;
          
          -- Notify client based on preferences
          IF v_user_preference.in_app THEN
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
              CASE 
                WHEN p_action = 'confirm' THEN 'Appointment Confirmed'
                WHEN p_action = 'reject' THEN 'Appointment Rejected'
                WHEN p_action = 'suggest_alternative' THEN 'Alternative Time Suggested'
                WHEN p_action = 'select_client_date' THEN 'Your Suggested Date Confirmed'
              END,
              v_message_text,
              'appointment',
              CASE 
                WHEN p_action = 'suggest_alternative' THEN v_confirmation_url
                ELSE '/appointments/' || p_appointment_id
              END,
              p_appointment_id,
              'appointment',
              v_notification_metadata
            );
          END IF;
          
          -- Email notification
          IF v_user_preference.email THEN
            PERFORM pg_notify('email_notification', 
              jsonb_build_object(
                'recipient_id', v_user_id,
                'type', 'appointment_' || p_action,
                'data', v_notification_metadata
              )::text
            );
          END IF;
          
          -- Push notification
          IF v_user_preference.push THEN
            PERFORM pg_notify('push_notification', 
              jsonb_build_object(
                'recipient_id', v_user_id,
                'title', CASE 
                  WHEN p_action = 'confirm' THEN 'Appointment Confirmed'
                  WHEN p_action = 'reject' THEN 'Appointment Rejected'
                  WHEN p_action = 'suggest_alternative' THEN 'New Time Suggested'
                  WHEN p_action = 'select_client_date' THEN 'New Time Selected'
                END,
                'body', CASE 
                  WHEN p_action = 'confirm' THEN 'Your appointment has been confirmed'
                  WHEN p_action = 'reject' THEN 'Your appointment request was rejected'
                  WHEN p_action = 'suggest_alternative' THEN 'An alternative time has been suggested for your appointment'
                  WHEN p_action = 'select_client_date' THEN 'One of your suggested dates has been selected'
                END,
                'data', v_notification_metadata
              )::text
            );
          END IF;
          
          -- SMS notification
          IF v_user_preference.sms THEN
            PERFORM pg_notify('sms_notification', 
              jsonb_build_object(
                'recipient_id', v_user_id,
                'message', CASE 
                  WHEN p_action = 'confirm' THEN 'Your appointment on ' || to_char(v_appointment_date, 'DD MMM') || ' has been confirmed'
                  WHEN p_action = 'reject' THEN 'Your appointment request for ' || to_char(v_appointment_date, 'DD MMM') || ' has been rejected'
                  WHEN p_action = 'suggest_alternative' THEN 'Alternative time suggested for your appointment: ' || to_char(p_alternative_time, 'DD MMM, HH12:MI AM')
                  WHEN p_action = 'select_client_date' THEN 'One of your suggested dates has been selected: ' || to_char(p_alternative_time, 'DD MMM, HH12:MI AM')
                END,
                'data', v_notification_metadata
              )::text
            );
          END IF;
        END;
    END;
    
    -- Add notification details to result
    v_result := v_result || jsonb_build_object(
      'message_sent', v_message_success,
      'chat_room_id', v_chat_room_id,
      'chat_room_name', v_chat_room_name
    );
    
    -- Add URLs to result
    IF p_action = 'suggest_alternative' THEN
      v_result := v_result || jsonb_build_object(
        'confirmation_url', v_confirmation_url,
        'reschedule_url', v_reschedule_url
      );
    END IF;
    
    -- Add meeting URL to result if it exists
    IF v_meeting_url IS NOT NULL AND (p_action = 'confirm' OR p_action = 'select_client_date') THEN
      v_result := v_result || jsonb_build_object('meeting_url', v_meeting_url);
    END IF;
    
  ELSE
    -- Handle legacy appointments
    IF p_action = 'confirm' THEN
      UPDATE appointments
      SET status = 'confirmed'
      WHERE id = p_appointment_id AND status = 'pending';
      
    ELSIF p_action = 'reject' THEN
      UPDATE appointments
      SET status = 'rejected'
      WHERE id = p_appointment_id AND status = 'pending';
      
    ELSIF p_action = 'suggest_alternative' AND p_alternative_time IS NOT NULL THEN
      UPDATE appointments
      SET 
        status = 'suggested',
        start_time = p_alternative_time,
        end_time = p_alternative_time + interval '1 hour'
      WHERE id = p_appointment_id AND status = 'pending';
    ELSE
      RETURN jsonb_build_object(
        'success', FALSE,
        'error', 'Invalid action for legacy appointment'
      );
    END IF;
    
    v_result := jsonb_build_object(
      'success', TRUE,
      'action', p_action,
      'appointment_id', p_appointment_id
    );
  END IF;
  
  -- Trigger notification
  PERFORM pg_notify('appointment_' || p_action, v_result::text);
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.respond_to_appointment_request(UUID, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, TEXT) IS 'Responds to an appointment request with confirmation, rejection, alternative time suggestion, or selection of client-suggested date, including detailed messaging and action links';

-- Remove the unnecessary messages table from previous fix if it exists
DROP TABLE IF EXISTS public.messages; 