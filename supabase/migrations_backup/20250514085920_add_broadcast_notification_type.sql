-- Migration for adding 'broadcast' value to notification_type enum
-- First transaction: just add the new enum value
BEGIN;

-- Add the 'broadcast' value to the notification_type enum if it doesn't exist already
DO $$
BEGIN
  -- Check if the 'broadcast' value already exists in the enum
  IF NOT EXISTS (
    SELECT 1
    FROM pg_enum
    WHERE enumlabel = 'broadcast' 
    AND enumtypid = (
      SELECT oid 
      FROM pg_type 
      WHERE typname = 'notification_type'
    )
  ) THEN
    -- Add the new value to the enum
    ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'broadcast';
  END IF;
END
$$;

COMMIT;

-- Second transaction: update functions and views using the new enum value
BEGIN;

-- Update the create_follower_broadcast function to use the 'broadcast' notification type
CREATE OR REPLACE FUNCTION public.create_follower_broadcast(
  p_follower_ids UUID[], -- List of follower user IDs
  p_title TEXT,
  p_content TEXT,
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
  v_sender_id UUID := auth.uid();
  v_notification_id UUID;
BEGIN
  -- Check if the user is authenticated
  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated to send broadcasts';
  END IF;
  
  -- Create a single broadcast notification record
  INSERT INTO notifications (
    user_id,                   -- NULL for broadcast notifications
    sender_id,                 -- Creator's user ID
    title,
    content,
    type,
    action_url,
    reference_id,
    reference_type,
    metadata,
    audience_type
  )
  VALUES (
    NULL,
    v_sender_id,
    p_title,
    p_content,
    'broadcast'::public.notification_type,  -- Using the updated enum value
    p_action_url,
    p_reference_id,
    COALESCE(p_reference_type, 'broadcast'),
    jsonb_build_object(
      'broadcast_created_at', now(),
      'recipient_count', array_length(p_follower_ids, 1)
    ) || p_metadata,
    'followers'::public.notification_audience_type
  )
  RETURNING id INTO v_notification_id;
  
  -- Create notification recipient records for each follower
  INSERT INTO notification_recipients (
    notification_id,
    user_id,
    is_read
  )
  SELECT 
    v_notification_id,
    id,
    FALSE
  FROM unnest(p_follower_ids) as id;
  
  RETURN v_notification_id;
END;
$$;

-- Update any views that filter on notification type to include 'broadcast'
CREATE OR REPLACE VIEW user_notifications_view AS
SELECT 
  -- Regular individual notifications directly to the user
  n.id,
  n.user_id,
  n.sender_id,
  n.title,
  n.content,
  n.type,
  n.action_url,
  n.reference_id,
  n.reference_type,
  n.is_read,
  n.created_at,
  n.metadata,
  'individual'::public.notification_audience_type as audience_type
FROM 
  notifications n
WHERE 
  n.user_id IS NOT NULL

UNION ALL

-- Broadcast notifications where the user is a recipient
SELECT 
  n.id,
  nr.user_id,
  n.sender_id,
  n.title,
  n.content,
  n.type,
  n.action_url,
  n.reference_id,
  n.reference_type,
  nr.is_read,
  n.created_at,
  n.metadata,
  n.audience_type
FROM 
  notifications n
JOIN 
  notification_recipients nr ON n.id = nr.notification_id
WHERE 
  n.user_id IS NULL AND
  n.audience_type = 'followers'

UNION ALL

-- Global announcement notifications (for all users)
SELECT 
  n.id,
  u.id as user_id,
  n.sender_id,
  n.title,
  n.content,
  n.type,
  n.action_url,
  n.reference_id,
  n.reference_type,
  EXISTS (
    SELECT 1 FROM notification_read_receipts nrr 
    WHERE nrr.notification_id = n.id AND nrr.user_id = u.id
  ) as is_read,
  n.created_at,
  n.metadata,
  n.audience_type
FROM 
  notifications n
CROSS JOIN
  auth.users u
WHERE 
  n.user_id IS NULL AND
  n.audience_type = 'all' AND
  (n.type = 'announcement' OR n.type = 'broadcast');  -- Include both types

COMMIT; 