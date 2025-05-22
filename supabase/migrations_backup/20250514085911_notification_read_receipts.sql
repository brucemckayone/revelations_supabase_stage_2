-- Migration: Add notification read receipts for more efficient broadcasts
BEGIN;

-- Create a table to track which broadcast notifications users have read
CREATE TABLE IF NOT EXISTS notification_read_receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  notification_id UUID NOT NULL REFERENCES notifications(id),
  read_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(user_id, notification_id)
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_notification_read_receipts_user_id ON notification_read_receipts(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_read_receipts_notification_id ON notification_read_receipts(notification_id);

-- Update the user_notifications_with_broadcasts view to include read status for broadcasts
DROP VIEW IF EXISTS user_notifications_with_broadcasts;

CREATE VIEW user_notifications_with_broadcasts AS
SELECT 
  COALESCE(n.id, b.id) as id,
  CASE 
    WHEN n.id IS NOT NULL THEN n.user_id 
    ELSE u.id
  END as user_id,
  COALESCE(n.sender_id, b.sender_id) as sender_id,
  COALESCE(n.title, b.title) as title,
  COALESCE(n.content, b.content) as content,
  COALESCE(n.type, b.type) as type,
  COALESCE(n.action_url, b.action_url) as action_url,
  COALESCE(n.reference_id, b.reference_id) as reference_id,
  COALESCE(n.reference_type, b.reference_type) as reference_type,
  CASE
    WHEN n.id IS NOT NULL THEN n.is_read
    ELSE (EXISTS (
      SELECT 1 FROM notification_read_receipts nr 
      WHERE nr.notification_id = b.id AND nr.user_id = u.id
    ))
  END as is_read,
  COALESCE(n.created_at, b.created_at) as created_at,
  COALESCE(n.metadata, b.metadata) as metadata,
  CASE 
    WHEN n.id IS NOT NULL THEN 'individual'::public.notification_audience_type
    ELSE b.audience_type
  END as audience_type
FROM 
  auth.users u
LEFT JOIN notifications n ON u.id = n.user_id AND n.user_id IS NOT NULL
LEFT JOIN LATERAL (
  SELECT n.*
  FROM notifications n
  WHERE 
    n.user_id IS NULL  -- Broadcast notifications have NULL user_id
    AND n.audience_type = 'all'
    AND n.type = 'announcement'
  ORDER BY n.created_at DESC
) b ON TRUE
ORDER BY COALESCE(n.created_at, b.created_at) DESC;

-- Create a function to mark notifications as read (handles both individual and broadcast)
CREATE OR REPLACE FUNCTION public.mark_notifications_as_read(
  p_notification_ids UUID[],
  p_user_id UUID DEFAULT auth.uid()
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verify user is authenticated
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated';
  END IF;

  -- Split notifications into individual and broadcast types
  WITH notification_types AS (
    SELECT 
      id,
      CASE WHEN user_id IS NULL THEN 'broadcast' ELSE 'individual' END as type
    FROM notifications
    WHERE id = ANY(p_notification_ids)
  ),
  individual_notifications AS (
    SELECT id FROM notification_types WHERE type = 'individual'
  ),
  broadcast_notifications AS (
    SELECT id FROM notification_types WHERE type = 'broadcast'
  )
  
  -- Update individual notifications directly
  UPDATE notifications
  SET is_read = TRUE
  WHERE id IN (SELECT id FROM individual_notifications)
    AND user_id = p_user_id;
  
  -- Insert read receipts for broadcast notifications
  INSERT INTO notification_read_receipts (notification_id, user_id)
  SELECT id, p_user_id
  FROM broadcast_notifications
  ON CONFLICT (user_id, notification_id) DO NOTHING;
  
END;
$$;

-- Add RLS policies
ALTER TABLE notification_read_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own read receipts" 
  ON notification_read_receipts
  FOR SELECT
  USING (auth.uid() = user_id);
  
CREATE POLICY "Users can insert their own read receipts" 
  ON notification_read_receipts
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

COMMIT; 