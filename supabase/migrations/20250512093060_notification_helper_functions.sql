-- filename: supabase/migrations/20250512093059_notification_helper_functions.sql

-- Function to notify event attendees about updates
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
  v_current_user_id UUID := auth.uid();
BEGIN
  -- Check if event exists and get owner info
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

  -- Check if user is authorized to send notifications
  IF v_event.owner_id != v_current_user_id AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_current_user_id AND role = 'admin'
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
      'system',
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
  v_current_user_id UUID := auth.uid();
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
  IF v_service.owner_id != v_current_user_id AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_current_user_id AND role = 'admin'
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