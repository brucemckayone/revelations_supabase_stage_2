-- Generated with srtd from template: supabase/migrations-templates/creator-sent-notificatinos.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Drop the existing view first to avoid column name change error
DROP VIEW IF EXISTS creator_sent_notifications;

-- Then create the view with the new column names
CREATE VIEW creator_sent_notifications AS
SELECT 
  n.id,
  n.sender_id,
  n.title,
  n.content,
  n.type,
  n.reference_id,
  n.reference_type,
  n.created_at,
  COUNT(nd.id) AS total_recipients,
  SUM(CASE WHEN nd.status = 'delivered' THEN 1 ELSE 0 END) AS delivered_count,
  jsonb_agg(DISTINCT jsonb_build_object(
    'user_id', n.user_id,
    'is_read', n.is_read
  )) AS recipients
FROM 
  notifications n
  JOIN notification_deliveries nd ON n.id = nd.notification_id
WHERE 
  n.sender_id IS NOT NULL
GROUP BY 
  n.id, n.sender_id, n.title, n.content, n.type, n.reference_id, n.reference_type, n.created_at
ORDER BY 
  n.created_at DESC;

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
