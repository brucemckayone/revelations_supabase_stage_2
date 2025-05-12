-- filename: supabase/migrations/20250512094252_notification_core_functions.sql

-- Core notification creation function
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_title TEXT,
  p_content TEXT,
  p_type TEXT,
  p_action_url TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_reference_type TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
  v_user_prefs RECORD;
BEGIN
  -- Validate notification type
  IF NOT (p_type IN ('appointment', 'message', 'system', 'payment', 'reminder')) THEN
    RAISE EXCEPTION 'Invalid notification type: %', p_type;
  END IF;
  
  -- Special permission check for system notifications
  IF p_type = 'system' AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admin users can send system notifications';
  END IF;
  
  -- Create the notification record
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
    p_user_id,
    p_title,
    p_content,
    p_type,
    p_action_url,
    p_reference_id,
    p_reference_type,
    p_metadata
  )
  RETURNING id INTO v_notification_id;
  
  -- Get user preferences for this notification type
  SELECT * INTO v_user_prefs 
  FROM notification_preferences
  WHERE user_id = p_user_id AND type = p_type;
  
  -- If no preferences found, use system defaults
  IF NOT FOUND THEN
    INSERT INTO notification_preferences (user_id, type)
    VALUES (p_user_id, p_type)
    RETURNING * INTO v_user_prefs;
  END IF;
  
  -- Create delivery records based on preferences
  -- In-app notification (always created)
  INSERT INTO notification_deliveries (notification_id, channel, status)
  VALUES (v_notification_id, 'in_app', 'delivered');
  
  -- Email notification
  IF v_user_prefs.email THEN
    INSERT INTO notification_deliveries (notification_id, channel, status)
    VALUES (v_notification_id, 'email', 'pending');
  END IF;
  
  -- Push notification
  IF v_user_prefs.push THEN
    INSERT INTO notification_deliveries (notification_id, channel, status)
    VALUES (v_notification_id, 'push', 'pending');
  END IF;
  
  -- SMS notification (for future implementation)
  IF v_user_prefs.sms THEN
    INSERT INTO notification_deliveries (notification_id, channel, status)
    VALUES (v_notification_id, 'sms', 'pending');
  END IF;
  
  RETURN v_notification_id;
END;
$$;

COMMENT ON FUNCTION create_notification IS 'Creates a new notification for a user with delivery records based on preferences';

-- Function to mark notifications as read
CREATE OR REPLACE FUNCTION mark_notifications_as_read(
  p_notification_ids UUID[] DEFAULT NULL,
  p_mark_all BOOLEAN DEFAULT FALSE
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  -- Prevent empty array input
  IF p_notification_ids IS NOT NULL AND array_length(p_notification_ids, 1) = 0 THEN
    RETURN 0;
  END IF;
  
  -- If mark_all is true, update all unread notifications for the user
  IF p_mark_all THEN
    UPDATE notifications
    SET 
      is_read = TRUE,
      updated_at = NOW()
    WHERE 
      user_id = auth.uid() AND 
      is_read = FALSE;
  ELSE
    -- Otherwise update only specified notification IDs
    UPDATE notifications
    SET 
      is_read = TRUE,
      updated_at = NOW()
    WHERE 
      id = ANY(p_notification_ids) AND
      user_id = auth.uid() AND
      is_read = FALSE;
  END IF;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION mark_notifications_as_read IS 'Marks notifications as read, either specific IDs or all';

-- Function to update notification preferences
CREATE OR REPLACE FUNCTION update_notification_preferences(
  p_type TEXT,
  p_in_app BOOLEAN DEFAULT NULL,
  p_email BOOLEAN DEFAULT NULL,
  p_push BOOLEAN DEFAULT NULL,
  p_sms BOOLEAN DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_exists BOOLEAN;
BEGIN
  -- Validate notification type
  IF NOT (p_type IN ('appointment', 'message', 'system', 'payment', 'reminder')) THEN
    RAISE EXCEPTION 'Invalid notification type: %', p_type;
  END IF;
  
  -- Check if preference exists
  SELECT EXISTS (
    SELECT 1 FROM notification_preferences 
    WHERE user_id = v_user_id AND type = p_type
  ) INTO v_exists;
  
  IF v_exists THEN
    -- Update existing preferences, only updating non-NULL values
    UPDATE notification_preferences
    SET
      in_app = COALESCE(p_in_app, in_app),
      email = COALESCE(p_email, email),
      push = COALESCE(p_push, push),
      sms = COALESCE(p_sms, sms),
      updated_at = NOW()
    WHERE
      user_id = v_user_id AND
      type = p_type;
  ELSE
    -- Create new preference with defaults for any NULL values
    INSERT INTO notification_preferences (
      user_id,
      type,
      in_app,
      email,
      push,
      sms
    ) VALUES (
      v_user_id,
      p_type,
      COALESCE(p_in_app, TRUE),
      COALESCE(p_email, TRUE),
      COALESCE(p_push, TRUE),
      COALESCE(p_sms, FALSE)
    );
  END IF;
  
  RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION update_notification_preferences IS 'Updates a user''s notification preferences for a given type';

-- Function to register a FCM token
CREATE OR REPLACE FUNCTION register_fcm_token(
  p_token TEXT,
  p_device_info JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_token_id UUID;
BEGIN
  -- Insert or update the token
  INSERT INTO user_fcm_tokens (
    user_id,
    token,
    device_info,
    is_active,
    last_used_at
  )
  VALUES (
    v_user_id,
    p_token,
    p_device_info,
    TRUE,
    NOW()
  )
  ON CONFLICT (user_id, token) DO UPDATE
  SET
    is_active = TRUE,
    device_info = EXCLUDED.device_info,
    last_used_at = EXCLUDED.last_used_at,
    updated_at = NOW()
  RETURNING id INTO v_token_id;
  
  RETURN v_token_id;
END;
$$;

COMMENT ON FUNCTION register_fcm_token IS 'Registers or reactivates an FCM token for the current user';

-- Function to deactivate a FCM token
CREATE OR REPLACE FUNCTION deactivate_fcm_token(
  p_token TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_count INTEGER;
BEGIN
  UPDATE user_fcm_tokens
  SET
    is_active = FALSE,
    updated_at = NOW()
  WHERE
    user_id = v_user_id AND
    token = p_token;
    
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count > 0;
END;
$$;

COMMENT ON FUNCTION deactivate_fcm_token IS 'Deactivates an FCM token for the current user';