-- filename: supabase/migrations/20250512093058_fcm_token_management.sql

-- Create FCM token management functions

-- Function to register a new FCM token
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
  -- Verify user is authenticated
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  
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
    device_info = COALESCE(EXCLUDED.device_info, user_fcm_tokens.device_info),
    last_used_at = NOW(),
    updated_at = NOW()
  RETURNING id INTO v_token_id;
  
  RETURN v_token_id;
END;
$$;

COMMENT ON FUNCTION register_fcm_token IS 'Registers or reactivates an FCM token for the current user';

-- Function to deactivate an FCM token
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
  -- Verify user is authenticated
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  
  -- Deactivate the token
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

-- Function to update the create_notification function with proper permission checks for system notifications
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
  v_in_app BOOLEAN;
  v_email BOOLEAN;
  v_push BOOLEAN;
  v_sms BOOLEAN;
  v_current_user_id UUID := auth.uid();
BEGIN
  -- Ensure notification type is valid
  IF NOT (p_type IN ('appointment', 'message', 'system', 'payment', 'reminder')) THEN
    RAISE EXCEPTION 'Invalid notification type: %', p_type;
  END IF;
  
  -- Special permission check for system notifications
  IF p_type = 'system' AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_current_user_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admin users can send system notifications';
  END IF;
  
  -- Get user preferences (or use defaults if not set)
  SELECT
    COALESCE(np.in_app, TRUE),
    COALESCE(np.email, TRUE),
    COALESCE(np.push, TRUE),
    COALESCE(np.sms, FALSE)
  INTO
    v_in_app,
    v_email,
    v_push,
    v_sms
  FROM
    (SELECT p_user_id) u
    LEFT JOIN notification_preferences np ON np.user_id = u.p_user_id AND np.type = p_type;
  
  -- Create base notification record
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
  ) RETURNING id INTO v_notification_id;
  
  -- Create delivery records based on preferences
  
  -- In-app notification
  IF v_in_app THEN
    INSERT INTO notification_deliveries (
      notification_id,
      channel,
      status,
      next_attempt_at
    ) VALUES (
      v_notification_id,
      'in_app',
      'delivered', -- In-app notifications are considered delivered immediately
      NULL
    );
  END IF;
  
  -- Email notification
  IF v_email THEN
    INSERT INTO notification_deliveries (
      notification_id,
      channel,
      status,
      next_attempt_at
    ) VALUES (
      v_notification_id,
      'email',
      'pending',
      NOW() -- Set for immediate processing
    );
  END IF;
  
  -- Push notification
  IF v_push THEN
    INSERT INTO notification_deliveries (
      notification_id,
      channel,
      status,
      next_attempt_at
    ) VALUES (
      v_notification_id,
      'push',
      'pending',
      NOW() -- Set for immediate processing
    );
  END IF;
  
  -- SMS notification
  IF v_sms THEN
    INSERT INTO notification_deliveries (
      notification_id,
      channel,
      status,
      next_attempt_at
    ) VALUES (
      v_notification_id,
      'sms',
      'pending',
      NOW() -- Set for immediate processing
    );
  END IF;
  
  RETURN v_notification_id;
END;
$$;

-- Update batch notification creation function with proper permission checks
CREATE OR REPLACE FUNCTION create_notifications_batch(
  p_user_ids UUID[],
  p_title TEXT,
  p_content TEXT,
  p_type TEXT,
  p_action_url TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_reference_type TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS SETOF UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_notification_id UUID;
  v_current_user_id UUID := auth.uid();
BEGIN
  -- Ensure notification type is valid
  IF NOT (p_type IN ('appointment', 'message', 'system', 'payment', 'reminder')) THEN
    RAISE EXCEPTION 'Invalid notification type: %', p_type;
  END IF;
  
  -- Special permission check for system notifications
  IF p_type = 'system' AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_current_user_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admin users can send system notifications';
  END IF;

  -- Process each user
  FOREACH v_user_id IN ARRAY p_user_ids
  LOOP
    -- Call the single notification creation function for each user
    v_notification_id := create_notification(
      v_user_id,
      p_title,
      p_content,
      p_type,
      p_action_url,
      p_reference_id,
      p_reference_type,
      p_metadata
    );
    
    -- Return the notification ID
    RETURN NEXT v_notification_id;
  END LOOP;
  
  RETURN;
END;
$$;

-- Update create notification for all users function with permission checks
CREATE OR REPLACE FUNCTION create_notification_for_all_users(
  p_title TEXT,
  p_content TEXT,
  p_type TEXT,
  p_action_url TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_reference_type TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_ids UUID[];
  v_count INTEGER;
  v_current_user_id UUID := auth.uid();
BEGIN
  -- Check if user has admin role
  IF NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_current_user_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admin users can send notifications to all users';
  END IF;
  
  -- Get all active user IDs
  SELECT array_agg(id) INTO v_user_ids
  FROM auth.users
  WHERE disabled = FALSE;
  
  -- Create notifications in batches for better performance
  WITH inserted_notifications AS (
    SELECT id FROM create_notifications_batch(
      v_user_ids,
      p_title,
      p_content,
      p_type,
      p_action_url,
      p_reference_id,
      p_reference_type,
      p_metadata
    )
  )
  SELECT COUNT(*) INTO v_count FROM inserted_notifications;
  
  RETURN v_count;
END;
$$; 