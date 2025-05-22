-- Generated with srtd from template: supabase/migrations-templates/creator-sent-notificatinos.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;


CREATE OR REPLACE VIEW creator_sent_notifications AS
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

-- Last built: 20250514085810_srtd-creator-sent-notificatinos.sql
-- Built with https://github.com/t1mmen/srtd
