-- Fix accessible_media view with fully qualified column references

-- Drop the view if it exists
DROP VIEW IF EXISTS accessible_media;

-- Recreate it with fully qualified columns
CREATE OR REPLACE VIEW accessible_media AS
SELECT 
    odm.id AS content_id,
    p.id AS post_id,
    p.title,
    p.description,
    p.thumbnail_url,
    odm.duration,
    odm.media_type,
    CASE 
        WHEN p.user_id = auth.uid() THEN true -- Creator always has access
        WHEN odm.price = 0 THEN true -- Free content is accessible
        ELSE can_access_content_v2(odm.id) -- Check purchase/subscription using our fixed function
    END AS has_access,
    pmd.url AS media_url,
    CASE 
        WHEN p.user_id = auth.uid() THEN 'creator'
        WHEN odm.price = 0 THEN 'free'
        WHEN EXISTS (
            SELECT 1 
            FROM content_purchases cp
            JOIN purchases pur ON cp.purchase_id = pur.id
            WHERE cp.content_id = odm.id
            AND pur.user_id = auth.uid()
        ) THEN 'purchased'
        WHEN EXISTS (
            SELECT 1
            FROM subscriptions s
            JOIN purchases pur ON s.purchase_id = pur.id
            WHERE pur.user_id = auth.uid()
            AND pur.owner_id = p.user_id
            AND s.status IN ('active', 'trial')
        ) THEN 'subscription'
        ELSE 'not_purchased'
    END AS access_type
FROM
    on_demand_media odm
JOIN
    posts p ON odm.post_id = p.id
LEFT JOIN
    protected_media_data pmd ON odm.id = pmd.content_id
WHERE
    p.status = 'public';

COMMENT ON VIEW accessible_media IS 'View that shows media content with access control information with fixed column references'; 