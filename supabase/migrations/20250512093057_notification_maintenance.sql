-- filename: supabase/migrations/20250512093057_notification_maintenance.sql

-- Enable pg_cron extension for scheduled jobs
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Function to process pending notifications
CREATE OR REPLACE FUNCTION process_pending_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_processed_count INTEGER := 0;
  v_ids UUID[];
BEGIN
  -- Get IDs of notifications that need to be processed
  SELECT array_agg(id) INTO v_ids
  FROM notification_deliveries
  WHERE 
    status = 'pending' 
    AND (next_attempt_at IS NULL OR next_attempt_at <= NOW())
    AND attempt_count < 3
  LIMIT 100;
  
  IF v_ids IS NOT NULL AND array_length(v_ids, 1) > 0 THEN
    -- Update next_attempt_at to avoid concurrent processing
    UPDATE notification_deliveries
    SET next_attempt_at = NOW() + INTERVAL '5 minutes'
    WHERE id = ANY(v_ids);
    
    -- Call edge functions using pg_net or other method
    -- In practice, you would trigger the edge functions via webhook or another mechanism
    -- This is a placeholder
    
    v_processed_count := array_length(v_ids, 1);
  END IF;
  
  RETURN v_processed_count;
END;
$$;

-- Function to clean up old read notifications
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_deleted_count INTEGER;
  v_retention_days INTEGER := 90; -- Keep notifications for 90 days
BEGIN
  -- Delete old read notifications
  WITH deleted AS (
    DELETE FROM notifications
    WHERE 
      is_read = TRUE 
      AND created_at < NOW() - (v_retention_days * INTERVAL '1 day')
    RETURNING id
  )
  SELECT count(*) INTO v_deleted_count FROM deleted;
  
  RETURN v_deleted_count;
END;
$$;

-- Function to update notification statistics
CREATE OR REPLACE FUNCTION update_notification_statistics()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_date DATE := CURRENT_DATE;
BEGIN
  -- Insert or update notification statistics for today
  INSERT INTO notification_statistics (
    date,
    total_count,
    read_count,
    type_counts,
    channel_counts,
    updated_at
  )
  VALUES (
    current_date,
    (SELECT COUNT(*) FROM notifications WHERE DATE(created_at) = current_date),
    (SELECT COUNT(*) FROM notifications WHERE DATE(created_at) = current_date AND is_read = TRUE),
    (
      SELECT jsonb_object_agg(type, cnt)
      FROM (
        SELECT type, COUNT(*) as cnt
        FROM notifications
        WHERE DATE(created_at) = current_date
        GROUP BY type
      ) t
    ),
    (
      SELECT jsonb_object_agg(channel, cnt)
      FROM (
        SELECT channel, COUNT(*) as cnt
        FROM notification_deliveries
        WHERE DATE(created_at) = current_date
        GROUP BY channel
      ) c
    ),
    NOW()
  )
  ON CONFLICT (date)
  DO UPDATE SET
    total_count = (SELECT COUNT(*) FROM notifications WHERE DATE(created_at) = current_date),
    read_count = (SELECT COUNT(*) FROM notifications WHERE DATE(created_at) = current_date AND is_read = TRUE),
    type_counts = (
      SELECT jsonb_object_agg(type, cnt)
      FROM (
        SELECT type, COUNT(*) as cnt
        FROM notifications
        WHERE DATE(created_at) = current_date
        GROUP BY type
      ) t
    ),
    channel_counts = (
      SELECT jsonb_object_agg(channel, cnt)
      FROM (
        SELECT channel, COUNT(*) as cnt
        FROM notification_deliveries
        WHERE DATE(created_at) = current_date
        GROUP BY channel
      ) c
    ),
    updated_at = NOW();
END;
$$;

-- Create notification statistics table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.notification_statistics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE UNIQUE NOT NULL,
  total_count INTEGER NOT NULL,
  read_count INTEGER NOT NULL,
  type_counts JSONB NOT NULL,
  channel_counts JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.notification_statistics IS 'Daily notification statistics for analytics';

-- Schedule the jobs to run periodically
-- Process pending notifications every 5 minutes
SELECT cron.schedule(
  'process-pending-notifications',
  '*/5 * * * *',
  $$SELECT process_pending_notifications()$$
);

-- Clean up old notifications once a day
SELECT cron.schedule(
  'cleanup-old-notifications',
  '0 2 * * *', -- Run at 2 AM every day
  $$SELECT cleanup_old_notifications()$$
);

-- Update notification statistics hourly
SELECT cron.schedule(
  'update-notification-statistics',
  '5 * * * *', -- Run at 5 minutes past every hour
  $$SELECT update_notification_statistics()$$
); 