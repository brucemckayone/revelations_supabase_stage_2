-- Migration: Add creator-to-followers broadcast notification system
BEGIN;

-- Add a new audience_type value for followers
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_audience_type') THEN
    CREATE TYPE public.notification_audience_type AS ENUM (
      'individual',   -- Sent to specific users
      'all',          -- Broadcasted to all users
      'followers',    -- Broadcasted to creator's followers
      'segment'       -- Targeted to a specific segment/group
    );
  ELSE 
    -- Type exists, try to add the value if it doesn't exist
    BEGIN
      ALTER TYPE public.notification_audience_type ADD VALUE IF NOT EXISTS 'followers';
    EXCEPTION WHEN duplicate_object THEN
      -- Value already exists, ignore
    END;
  END IF;
END
$$;

-- Create a notification_recipients junction table to track who receives broadcast notifications
CREATE TABLE IF NOT EXISTS notification_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES notifications(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(notification_id, user_id)
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_notification_recipients_notification_id ON notification_recipients(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_recipients_user_id ON notification_recipients(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_recipients_is_read ON notification_recipients(is_read);

-- Create a function to send a broadcast notification to specified followers
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
    'broadcast'::public.notification_type,
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

-- Update the view to include broadcast notifications for followers
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
  n.type = 'announcement';

-- Add RLS policies
ALTER TABLE notification_recipients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view notifications they receive" 
  ON notification_recipients
  FOR SELECT
  USING (auth.uid() = user_id);

-- Function to mark a user's broadcast notification as read
CREATE OR REPLACE FUNCTION public.mark_broadcast_notification_read(
  p_notification_id UUID,
  p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated BOOLEAN;
BEGIN
  -- Check authentication
  IF p_user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Update the is_read status in notification_recipients
  UPDATE notification_recipients
  SET 
    is_read = TRUE,
    read_at = now(),
    updated_at = now()
  WHERE 
    notification_id = p_notification_id AND
    user_id = p_user_id;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  
  RETURN v_updated > 0;
END;
$$;

-- Update the mark_notifications_as_read function to handle broadcast notifications
CREATE OR REPLACE FUNCTION public.mark_notifications_as_read(
  p_notification_ids UUID[],
  p_user_id UUID DEFAULT auth.uid()
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  -- Verify user is authenticated
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated';
  END IF;

  -- For each notification ID
  FOREACH v_notification_id IN ARRAY p_notification_ids
  LOOP
    -- Check notification type and handle appropriately
    IF EXISTS (
      SELECT 1 FROM notifications 
      WHERE id = v_notification_id AND user_id = p_user_id
    ) THEN
      -- Individual notification
      UPDATE notifications
      SET is_read = TRUE
      WHERE id = v_notification_id AND user_id = p_user_id;
      
    ELSIF EXISTS (
      SELECT 1 FROM notifications 
      WHERE id = v_notification_id AND audience_type = 'followers'
    ) THEN
      -- Follower broadcast notification
      UPDATE notification_recipients
      SET 
        is_read = TRUE,
        read_at = now(),
        updated_at = now()
      WHERE 
        notification_id = v_notification_id AND
        user_id = p_user_id;
        
    ELSIF EXISTS (
      SELECT 1 FROM notifications 
      WHERE id = v_notification_id AND audience_type = 'all'
    ) THEN
      -- Global announcement
      INSERT INTO notification_read_receipts (notification_id, user_id)
      VALUES (v_notification_id, p_user_id)
      ON CONFLICT (user_id, notification_id) DO NOTHING;
    END IF;
  END LOOP;
END;
$$;

COMMIT; 