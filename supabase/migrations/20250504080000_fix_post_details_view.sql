-- Fix post_details view to respect access control for media_key
-- This view was exposing protected media URLs without permission checks
CREATE OR REPLACE VIEW post_details AS
SELECT 
    p.id,
    p.user_id,
    p.title,
    p.slug,
    p.description,
    p.content,
    p.post_type::TEXT AS post_type,
    p.status::TEXT AS status,
    p.thumbnail_url,
    p.created_at,
    p.updated_at,
    p.featured,
    COALESCE(
        ARRAY_AGG(t.name) FILTER (WHERE t.name IS NOT NULL),
        ARRAY[]::TEXT[]
    ) AS tags,
    pr.id AS profile_id,
    pr.full_name AS profile_full_name,
    pr.avatar_url AS profile_avatar_url,
    e.type AS event_subtype,
    s.type AS service_subtype,
    -- Only expose the media URL if:
    -- 1. The user is the creator (p.user_id = auth.uid())
    -- 2. The content is accessible (can_access_content returns true)
    CASE
        WHEN p.user_id = auth.uid() THEN odm.protected_media_url
        WHEN odm.content_id IS NOT NULL AND can_access_content(odm.content_id) THEN odm.protected_media_url
        ELSE NULL
    END as media_key
FROM 
    public.posts p
LEFT JOIN (
    SELECT
        odm.post_id,
        odm.id AS content_id,
        pmd.url AS protected_media_url
    FROM
        public.on_demand_media odm
    LEFT JOIN
        public.protected_media_data pmd ON odm.id = pmd.content_id
) odm ON p.id = odm.post_id
LEFT JOIN 
    public.post_tags pt ON p.id = pt.post_id
LEFT JOIN 
    public.tags t ON pt.tag_id = t.id
LEFT JOIN 
    public.profiles pr ON p.user_id = pr.id
LEFT JOIN 
    public.events e ON p.id = e.post_id
LEFT JOIN 
    public.services s ON p.id = s.post_id
GROUP BY 
    p.id, p.user_id, p.title, p.slug, p.description, p.content, 
    p.post_type, p.status, p.thumbnail_url, p.created_at, p.updated_at, 
    p.featured, pr.id, pr.full_name, pr.avatar_url, e.type, s.type, 
    odm.protected_media_url, odm.content_id; 