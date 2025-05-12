-- filename: supabase/migrations/20250512094358_notification_batch_functions.sql

-- Function to create notifications for multiple users at once
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
  -- Ensure notification type is valid
  IF NOT (p_type IN ('appointment', 'message', 'system', 'payment', 'reminder')) THEN
    RAISE EXCEPTION 'Invalid notification type: %', p_type;
  END IF;
  
  -- Check if user has admin role for system type notifications
  IF p_type = 'system' AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admin users can send system notifications';
  END IF;
  
  -- Loop through each user ID and create notification
  FOREACH v_user_id IN ARRAY p_user_ids
  LOOP
    -- Create a notification for this user
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
    
    -- Return this notification ID to the result set
    IF v_notification_id IS NOT NULL THEN
      RETURN NEXT v_notification_id;
    END IF;
  END LOOP;
  
  RETURN;
END;
$$;

COMMENT ON FUNCTION create_notifications_batch IS 'Creates notifications for multiple users at once';

-- Function to send notification to all users (admin only)
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
BEGIN
  -- Check if user has admin role
  IF NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admin users can send notifications to all users';
  END IF;
  
  -- Get all user IDs
  SELECT ARRAY_AGG(au.id) INTO v_user_ids
  FROM auth.users au
  WHERE au.id != auth.uid(); -- Skip the sending admin
  
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

COMMENT ON FUNCTION create_notification_for_all_users IS 'Creates notifications for all users - admin only';

-- Function to notify event attendees
CREATE OR REPLACE FUNCTION notify_event_attendees(
  p_event_id UUID,
  p_title TEXT,
  p_content TEXT,
  p_action_url TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event RECORD;
  v_user_ids UUID[];
  v_count INTEGER;
BEGIN
  -- Check if user is the event owner
  SELECT 
    e.id,
    e.post_id,
    p.title as event_title,
    p.user_id as owner_id
  INTO v_event
  FROM 
    events e
    JOIN posts p ON e.post_id = p.id
  WHERE 
    e.id = p_event_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found';
  END IF;
  
  -- Check if user is authorized to send notifications for this event
  IF v_event.owner_id != auth.uid() AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only the event owner or admin can send notifications to attendees';
  END IF;
  
  -- Get all attendee user IDs
  SELECT ARRAY_AGG(DISTINCT p.user_id) INTO v_user_ids
  FROM 
    purchases p
    JOIN event_bookings eb ON p.id = eb.purchase_id
  WHERE 
    p.event_id = p_event_id AND
    eb.status IN ('confirmed', 'attended');
  
  -- If no attendees, return 0
  IF v_user_ids IS NULL OR array_length(v_user_ids, 1) = 0 THEN
    RETURN 0;
  END IF;
  
  -- Create notifications for all attendees
  WITH inserted_notifications AS (
    SELECT id FROM create_notifications_batch(
      v_user_ids,
      p_title,
      p_content,
      'event',
      COALESCE(p_action_url, '/events/' || p_event_id),
      p_event_id,
      'event',
      jsonb_build_object(
        'event_id', p_event_id,
        'event_title', v_event.event_title,
        'notification_type', 'event_update'
      ) || p_metadata
    )
  )
  SELECT COUNT(*) INTO v_count FROM inserted_notifications;
  
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION notify_event_attendees IS 'Sends notifications to all attendees of an event';

-- Function to notify service subscribers
CREATE OR REPLACE FUNCTION notify_service_subscribers(
  p_service_id UUID,
  p_title TEXT,
  p_content TEXT,
  p_action_url TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_service RECORD;
  v_user_ids UUID[];
  v_count INTEGER;
BEGIN
  -- Check if service exists and get owner info
  SELECT 
    s.id,
    s.post_id,
    p.title as service_title,
    p.user_id as owner_id
  INTO v_service
  FROM 
    services s
    JOIN posts p ON s.post_id = p.id
  WHERE 
    s.id = p_service_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Service not found';
  END IF;
  
  -- Check if user is authorized to send notifications
  IF v_service.owner_id != auth.uid() AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only the service owner or admin can send notifications to subscribers';
  END IF;
  
  -- Get all user IDs who have purchased this service
  SELECT ARRAY_AGG(DISTINCT user_id) INTO v_user_ids
  FROM purchases
  WHERE service_id = p_service_id AND payment_status = 'completed';
  
  -- If no subscribers, return 0
  IF v_user_ids IS NULL OR array_length(v_user_ids, 1) = 0 THEN
    RETURN 0;
  END IF;
  
  -- Create notifications for all subscribers
  WITH inserted_notifications AS (
    SELECT id FROM create_notifications_batch(
      v_user_ids,
      p_title,
      p_content,
      'system',
      COALESCE(p_action_url, '/services/' || v_service.post_id),
      p_service_id,
      'service',
      jsonb_build_object(
        'service_id', p_service_id,
        'service_title', v_service.service_title,
        'notification_type', 'service_update'
      ) || p_metadata
    )
  )
  SELECT COUNT(*) INTO v_count FROM inserted_notifications;
  
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION notify_service_subscribers IS 'Sends notifications to all users who have purchased a service';