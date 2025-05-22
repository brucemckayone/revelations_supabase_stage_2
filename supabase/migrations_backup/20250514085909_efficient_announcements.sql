-- Migration: Add efficient announcement system to avoid duplicate notifications
BEGIN;

-- Create a new enum type for audience targeting
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_audience_type') THEN
    CREATE TYPE public.notification_audience_type AS ENUM (
      'individual',   -- Sent to specific users
      'all',          -- Broadcasted to all users
      'segment'       -- Targeted to a specific segment/group
    );
  END IF;
END
$$;

-- Add a new audience_type column to notifications table
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS audience_type public.notification_audience_type 
DEFAULT 'individual'::public.notification_audience_type;

-- Add a column for audience segment criteria (for filtered broadcasts)
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS audience_criteria JSONB DEFAULT NULL;

-- Create notification templates table for reusable notifications
CREATE TABLE IF NOT EXISTS notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES auth.users(id) NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  type public.notification_type NOT NULL DEFAULT 'general',
  action_url TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create announcement-specific function for efficient broadcasting
CREATE OR REPLACE FUNCTION public.create_broadcast_announcement(
  p_title TEXT,
  p_content TEXT,
  p_action_url TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_reference_type TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::JSONB,
  p_audience_type public.notification_audience_type DEFAULT 'all',
  p_audience_criteria JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sender_id UUID := auth.uid();
  v_notification_id UUID;
BEGIN
  -- Check permission based on audience type
  IF p_audience_type = 'all' AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_sender_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admin users can send broadcasts to all users';
  END IF;
  
  -- Create a single broadcast notification record
  INSERT INTO notifications (
    user_id,                  -- Set this to NULL for broadcast announcements
    sender_id,
    title,
    content,
    type,
    action_url,
    reference_id,
    reference_type,
    metadata,
    audience_type,           -- New field
    audience_criteria        -- New field
  )
  VALUES (
    NULL,                    -- NULL user_id indicates it's a broadcast
    v_sender_id,
    p_title,
    p_content,
    'announcement'::public.notification_type,
    p_action_url,
    p_reference_id,
    COALESCE(p_reference_type, 'announcement'),
    p_metadata || jsonb_build_object('broadcast_created_at', now()),
    p_audience_type,
    p_audience_criteria
  )
  RETURNING id INTO v_notification_id;
  
  -- Create notification delivery records for tracking purposes
  -- This will allow us to track metrics without creating duplicate notifications
  WITH eligible_users AS (
    SELECT id FROM auth.users 
    WHERE id != v_sender_id -- Skip the sender
  )
  INSERT INTO notification_deliveries (
    notification_id,
    user_id,
    status,
    delivery_type
  )
  SELECT 
    v_notification_id,
    id,
    'pending',
    'in_app'
  FROM eligible_users;
  
  RETURN v_notification_id;
END;
$$;

-- Optimize the user-facing view to efficiently show announcements once per user
CREATE OR REPLACE VIEW user_notifications_with_broadcasts AS
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
  COALESCE(n.is_read, FALSE) as is_read,
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

-- Update notification endpoint RLS policy to include broadcasts
CREATE OR REPLACE FUNCTION public.user_can_view_notification(notification_row notifications)
RETURNS BOOLEAN
AS $$
BEGIN
  RETURN (
    -- User can view their own notifications
    notification_row.user_id = auth.uid() 
    OR 
    -- User can view broadcasts where they're included in the audience
    (
      notification_row.user_id IS NULL 
      AND notification_row.audience_type = 'all'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT; 