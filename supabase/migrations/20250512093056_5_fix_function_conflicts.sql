-- filename: supabase/migrations/20250512093056_5_fix_function_conflicts.sql

-- First drop the conflicting functions
DROP FUNCTION IF EXISTS create_notification_for_all_users;

-- Recreate the function with consistent return type
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

COMMENT ON FUNCTION create_notification_for_all_users IS 'Creates notifications for all users, returns count of notifications created';

-- Also ensure the create_notifications_batch function has consistent signature
DROP FUNCTION IF EXISTS create_notifications_batch CASCADE;

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

COMMENT ON FUNCTION create_notifications_batch IS 'Creates notifications for multiple users at once, returns notification IDs'; 