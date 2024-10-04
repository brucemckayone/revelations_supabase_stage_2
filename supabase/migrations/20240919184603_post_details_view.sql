

CREATE VIEW post_details AS
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
    s.type AS service_subtype
FROM 
    public.posts p
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
    p.featured, pr.id, pr.full_name, pr.avatar_url, e.type, s.type;
