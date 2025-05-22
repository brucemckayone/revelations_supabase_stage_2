-- Generated with srtd from template: supabase/migrations-templates/update_notification_functions.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Migration: Add sender tracking to specialized notification functions
BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'notifications'
      AND column_name = 'sender_id'
      AND table_schema = 'public'
  ) THEN
    ALTER TABLE notifications ADD COLUMN sender_id uuid REFERENCES auth.users(id);
  END IF;
END;
$$;


-- Update the notify_event_attendees function to include sender_id tracking
CREATE OR REPLACE FUNCTION public.notify_event_attendees(
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
  v_sender_id UUID := auth.uid(); -- Store sender ID
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
  IF v_event.owner_id != v_sender_id AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_sender_id AND role = 'admin'
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
  
  -- Create notifications for all attendees directly to ensure sender_id is set
  WITH inserted_notifications AS (
    INSERT INTO notifications (
      user_id,
      sender_id,
      title,
      content,
      type,
      action_url,
      reference_id,
      reference_type,
      metadata
    )
    SELECT 
      user_id,
      v_sender_id,
      p_title,
      p_content,
      'event'::public.notification_type,
      COALESCE(p_action_url, '/events/' || p_event_id),
      p_event_id,
      'event',
      jsonb_build_object(
        'event_id', p_event_id,
        'event_title', v_event.event_title,
        'notification_type', 'event_update',
        'sender_id', v_sender_id
      ) || p_metadata
    FROM UNNEST(v_user_ids) AS user_id
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM inserted_notifications;
  
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.notify_event_attendees IS 'Sends notifications to all attendees of an event with sender tracking';

-- Update the notify_service_subscribers function to include sender_id tracking
CREATE OR REPLACE FUNCTION public.notify_service_subscribers(
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
  v_sender_id UUID := auth.uid(); -- Store sender ID
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
  IF v_service.owner_id != v_sender_id AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_sender_id AND role = 'admin'
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
  
  -- Insert notifications directly to ensure sender_id is set
  WITH inserted_notifications AS (
    INSERT INTO notifications (
      user_id,
      sender_id,
      title,
      content,
      type,
      action_url,
      reference_id,
      reference_type,
      metadata
    )
    SELECT 
      user_id,
      v_sender_id,
      p_title,
      p_content,
      'service'::public.notification_type,
      COALESCE(p_action_url, '/services/' || v_service.post_id),
      p_service_id,
      'service',
      jsonb_build_object(
        'service_id', p_service_id,
        'service_title', v_service.service_title,
        'notification_type', 'service_update',
        'sender_id', v_sender_id
      ) || p_metadata
    FROM UNNEST(v_user_ids) AS user_id
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM inserted_notifications;
  
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.notify_service_subscribers IS 'Sends notifications to all users who have purchased a service with sender tracking';

-- Update the create_notification_for_all_users function to include sender_id tracking
CREATE OR REPLACE FUNCTION public.create_notification_for_all_users(
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
  v_sender_id UUID := auth.uid(); -- Store sender ID
BEGIN
  -- Check if user has admin role
  IF NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_sender_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admin users can send notifications to all users';
  END IF;
  
  -- Get all user IDs
  SELECT ARRAY_AGG(au.id) INTO v_user_ids
  FROM auth.users au
  WHERE au.id != v_sender_id; -- Skip the sending admin
  
  -- Insert notifications directly to ensure sender_id is set
  WITH inserted_notifications AS (
    INSERT INTO notifications (
      user_id,
      sender_id,
      title,
      content,
      type,
      action_url,
      reference_id,
      reference_type,
      metadata
    )
    SELECT 
      user_id,
      v_sender_id,
      p_title,
      p_content,
      p_type::public.notification_type,
      p_action_url,
      p_reference_id,
      p_reference_type,
      jsonb_build_object('sender_id', v_sender_id) || p_metadata
    FROM UNNEST(v_user_ids) AS user_id
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM inserted_notifications;
  
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.create_notification_for_all_users IS 'Creates notifications for all users - admin only, with sender tracking';

-- Create index for sender_id if it doesn't exist yet
CREATE INDEX IF NOT EXISTS notifications_sender_id_idx ON public.notifications(sender_id);

-- Create a function to get notifications sent by a specific creator
CREATE OR REPLACE FUNCTION public.get_sent_notifications(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0,
  p_type TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  content TEXT,
  type public.notification_type,
  reference_id UUID,
  reference_type TEXT,
  created_at TIMESTAMPTZ,
  recipient_count BIGINT,
  read_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.id,
    n.title,
    n.content,
    n.type,
    n.reference_id,
    n.reference_type,
    n.created_at,
    COUNT(DISTINCT n.user_id) AS recipient_count,
    COUNT(DISTINCT CASE WHEN n.is_read THEN n.user_id END) AS read_count
  FROM notifications n
  WHERE 
    n.sender_id = auth.uid()
    AND (p_type IS NULL OR n.type::TEXT = p_type)
    AND (p_reference_id IS NULL OR n.reference_id = p_reference_id)
    AND (p_start_date IS NULL OR n.created_at >= p_start_date)
    AND (n.created_at <= p_end_date)
  GROUP BY 
    n.id, n.title, n.content, n.type, n.reference_id, n.reference_type, n.created_at
  ORDER BY n.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION public.get_sent_notifications IS 'Retrieves notifications sent by the current user with read statistics';

-- Grant permissions for the new function
GRANT EXECUTE ON FUNCTION public.get_sent_notifications TO authenticated;

COMMIT; 





COMMIT;

-- Last built: 20250514085808_srtd-update_notification_functions.sql
-- Built with https://github.com/t1mmen/srtd
