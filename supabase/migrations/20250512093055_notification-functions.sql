-- filename: supabase/migrations/20250512093055_notification-functions.sql

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
  v_in_app BOOLEAN;
  v_email BOOLEAN;
  v_push BOOLEAN;
  v_sms BOOLEAN;
BEGIN
  -- Ensure notification type is valid
  IF NOT (p_type IN ('appointment', 'message', 'system', 'payment', 'reminder')) THEN
    RAISE EXCEPTION 'Invalid notification type: %', p_type;
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

-- Batch notification creation function
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
BEGIN
  -- Ensure notification type is valid (reusing the same check from create_notification)
  IF NOT (p_type IN ('appointment', 'message', 'system', 'payment', 'reminder')) THEN
    RAISE EXCEPTION 'Invalid notification type: %', p_type;
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

-- Create notification for all users
CREATE OR REPLACE FUNCTION create_notification_for_all_users(
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
  v_user_ids UUID[];
BEGIN
  -- Get all active user IDs
  SELECT array_agg(id) INTO v_user_ids
  FROM auth.users
  WHERE disabled = FALSE;
  
  -- Call batch notification function
  RETURN QUERY SELECT * FROM create_notifications_batch(
    v_user_ids,
    p_title,
    p_content,
    p_type,
    p_action_url,
    p_reference_id,
    p_reference_type,
    p_metadata
  );
END;
$$;

-- Mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_as_read(p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated BOOLEAN;
BEGIN
  UPDATE notifications
  SET 
    is_read = TRUE,
    updated_at = NOW()
  WHERE 
    id = p_notification_id
    AND user_id = auth.uid() -- Ensure user can only mark their own notifications as read
  RETURNING TRUE INTO v_updated;
  
  RETURN COALESCE(v_updated, FALSE);
END;
$$;

-- Mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_as_read()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE notifications
  SET 
    is_read = TRUE,
    updated_at = NOW()
  WHERE 
    user_id = auth.uid() -- Ensure user can only mark their own notifications as read
    AND is_read = FALSE
  RETURNING COUNT(*) INTO v_count;
  
  RETURN COALESCE(v_count, 0);
END;
$$;

-- Updated timestamp trigger function
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Add updated_at triggers
CREATE TRIGGER notifications_updated_at_trigger
BEFORE UPDATE ON notifications
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER notification_deliveries_updated_at_trigger
BEFORE UPDATE ON notification_deliveries
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER notification_preferences_updated_at_trigger
BEFORE UPDATE ON notification_preferences
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER email_templates_updated_at_trigger
BEFORE UPDATE ON email_templates
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER user_fcm_tokens_updated_at_trigger
BEFORE UPDATE ON user_fcm_tokens
FOR EACH ROW
EXECUTE FUNCTION update_timestamp(); 