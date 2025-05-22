-- Generated with srtd from template: supabase/migrations-templates/fix_approve_appointment_function.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Fix approve_appointment_request function to use chat_messages instead of messages
DROP FUNCTION IF EXISTS public.approve_appointment_request;

CREATE OR REPLACE FUNCTION public.approve_appointment_request(p_appointment_id UUID, p_price NUMERIC, p_message TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
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
BEGIN
  -- Get appointment details
  SELECT 
    ap.purchase_id, 
    p.user_id, 
    p.owner_id, 
    ap.service_id, 
    p.post_id,
    ap.appointment_date,
    ap.duration
  INTO 
    v_purchase_id, 
    v_user_id, 
    v_owner_id, 
    v_service_id, 
    v_post_id,
    v_appointment_date,
    v_duration
  FROM 
    appointment_purchases ap
    JOIN purchases p ON ap.purchase_id = p.id
  WHERE 
    ap.id = p_appointment_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Appointment not found');
  END IF;
  
  -- Update appointment status
  UPDATE appointment_purchases
  SET status = 'pending_payment',
      updated_at = NOW()
  WHERE id = p_appointment_id;
  
  -- Update purchase with price
  UPDATE purchases
  SET amount = p_price,
      payment_status = 'pending',
      updated_at = NOW()
  WHERE id = v_purchase_id;
  
  -- First, look for direct 1-on-1 chat rooms between these specific users
  SELECT cr.id INTO v_chat_room_id
  FROM chat_rooms cr
  JOIN chat_participants cp1 ON cr.id = cp1.chat_room_id AND cp1.user_id = v_user_id
  JOIN chat_participants cp2 ON cr.id = cp2.chat_room_id AND cp2.user_id = v_owner_id
  WHERE cr.type = 'private'
  AND (
    -- Ensure the room has exactly 2 participants
    SELECT COUNT(*) FROM chat_participants cp 
    WHERE cp.chat_room_id = cr.id
  ) = 2
  LIMIT 1;
  
  -- If no chat room exists, create one
  IF v_chat_room_id IS NULL THEN
    INSERT INTO chat_rooms (name, type, created_by)
    VALUES ('Appointment Chat', 'private', v_owner_id)
    RETURNING id INTO v_chat_room_id;
    
    -- Add participants with ON CONFLICT DO NOTHING to prevent unique constraint violations
    INSERT INTO chat_participants (chat_room_id, user_id)
    VALUES 
      (v_chat_room_id, v_user_id),
      (v_chat_room_id, v_owner_id)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
  ELSE
    -- Even if room exists, ensure both users are participants (handles edge cases)
    INSERT INTO chat_participants (chat_room_id, user_id)
    VALUES 
      (v_chat_room_id, v_user_id),
      (v_chat_room_id, v_owner_id)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
  END IF;
  
  -- Send message in chat
  BEGIN
    INSERT INTO chat_messages (
      chat_room_id,
      sender_id,
      message,
      status
    ) VALUES (
      v_chat_room_id,
      v_owner_id,
      COALESCE(p_message, 'Your appointment request has been approved. Please complete payment to confirm.'),
      'delivered'
    );
    v_message_success := TRUE;
  EXCEPTION WHEN OTHERS THEN
    -- If chat message fails, fall back to notifications
    v_message_success := FALSE;
    
    -- Check if notifications table exists and try to use it
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
        COALESCE(p_message, 'Your appointment request has been approved. Please complete payment to confirm.'),
        'appointment',
        '/appointments/' || p_appointment_id,
        p_appointment_id,
        'appointment',
        jsonb_build_object(
          'appointment_id', p_appointment_id,
          'purchase_id', v_purchase_id,
          'service_id', v_service_id,
          'appointment_date', v_appointment_date,
          'duration', v_duration,
          'price', p_price,
          'status', 'pending',
          'payment_required', true
        )
      );
    EXCEPTION WHEN OTHERS THEN
      -- Just continue if this fails too, we'll still return the result
      NULL;
    END;
  END;
  
  -- Build result with payment metadata
  v_result := jsonb_build_object(
    'purchase_id', v_purchase_id,
    'appointment_id', p_appointment_id,
    'user_id', v_user_id,
    'owner_id', v_owner_id,
    'service_id', v_service_id,
    'post_id', v_post_id,
    'appointment_date', v_appointment_date,
    'duration', v_duration,
    'price', p_price,
    'status', 'pending',
    'message_sent', v_message_success,
    'chat_room_id', v_chat_room_id
  );
  
  -- Trigger email notification (in future implementation)
  PERFORM pg_notify('appointment_approved', v_result::text);
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.approve_appointment_request(UUID, NUMERIC, TEXT) IS 'Approves an appointment request and generates payment info for the user';

-- Remove the unnecessary messages table from previous fix
DROP TABLE IF EXISTS public.messages;

COMMIT;

-- Last built: 20250517170351_srtd-fix_approve_appointment_function.sql
-- Built with https://github.com/t1mmen/srtd
