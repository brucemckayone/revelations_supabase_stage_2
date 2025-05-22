-- Generated with srtd from template: supabase/migrations-templates/override-broadcast-type.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Migration template to update the create_follower_broadcast function with a valid type value
BEGIN;

-- Create or replace the function to use a valid notification type value
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
  v_notification_type public.notification_type;
BEGIN
  -- Check if the user is authenticated
  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated to send broadcasts';
  END IF;
  
  -- Use a known good notification type value while we're troubleshooting
  -- 'broadcast' might not be recognized yet, so use 'announcement' temporarily
  v_notification_type := 'announcement'::public.notification_type;
  
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
    v_notification_type,  -- Using a known good enum value
    p_action_url,
    p_reference_id,
    COALESCE(p_reference_type, 'broadcast'),
    jsonb_build_object(
      'broadcast_created_at', now(),
      'recipient_count', array_length(p_follower_ids, 1),
      'original_type', 'broadcast'  -- Store the intended type in metadata
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

COMMIT; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
