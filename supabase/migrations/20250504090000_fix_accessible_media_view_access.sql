-- Fix accessible_media view to properly control access to media URL
-- This view was exposing the media URL without checking if the user has actual access

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
        ELSE can_access_content(odm.id) -- Check purchase/subscription
    END AS has_access,
    -- Only expose media URL when user has access
    CASE 
        WHEN p.user_id = auth.uid() THEN pmd.url -- Creator always has access
        WHEN odm.price = 0 THEN pmd.url -- Free content is accessible 
        WHEN can_access_content(odm.id) THEN pmd.url -- User has purchased or has subscription
        ELSE NULL
    END AS media_url,
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

COMMENT ON VIEW accessible_media IS 'View that shows media content with proper access control for media URLs'; 