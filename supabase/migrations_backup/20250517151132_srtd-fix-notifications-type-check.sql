-- Generated with srtd from template: supabase/migrations-templates/fix-notifications-type-check.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Migration template to fix the notifications.type check constraint to allow 'broadcast' value
BEGIN;

-- Remove existing check constraint if it exists
ALTER TABLE public.notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;

-- We'll recreate a constraint that matches the enum values including 'broadcast'
-- First, let's get the enum values
DO $$
DECLARE
  enum_values TEXT;
BEGIN
  -- Create a check constraint based on the enum values
  SELECT string_agg(quote_literal(enumlabel), ', ')
  INTO enum_values
  FROM pg_enum
  WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'notification_type');

  -- Execute dynamic SQL to add the constraint back
  EXECUTE format('ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check CHECK (type::text = ANY (ARRAY[%s]::text[]))', enum_values);
END $$;

-- Also make a change to the create_follower_broadcast function
-- to ensure it uses the right type value
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

-- Function to debug notification types
CREATE OR REPLACE FUNCTION public.debug_notification_type()
RETURNS TABLE (enumlabel text) AS $$
BEGIN
  RETURN QUERY
  SELECT pg_enum.enumlabel::text
  FROM pg_enum
  WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'notification_type')
  ORDER BY enumsortorder;
END;
$$ LANGUAGE plpgsql;

COMMIT; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
