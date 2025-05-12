-- Simple service views without appointment functionality
-- The full appointment system will be added in later migrations

-- First, let's create a view to get service information with creator details
CREATE OR REPLACE VIEW public.service_details_view AS
SELECT 
    -- Service base info
    s.id AS service_id,
    p.id AS post_id,
    p.slug,
    p.title,
    p.description,
    s.content,
    p.thumbnail_url,
    s.type AS service_type,
    s.price,
    s.duration,
    p.featured,
    p.created_at,
    p.updated_at,
    p.user_id AS creator_id,
    
    -- Location info (for in-person services)
    CASE 
        WHEN s.type = 'online' THEN 
            jsonb_build_object('name', 'Online Service')
        ELSE 
            jsonb_build_object(
                'id', l.id,
                'name', l.name,
                'description', l.description,
                'image_url', l.image_url,
                'address', jsonb_build_object(
                    'line_1', l.line_1,
                    'line_2', l.line_2,
                    'city', l.city,
                    'country', l.country,
                    'postcode', l.postcode,
                    'maps_link', l.maps_link
                ),
                'coordinates', CASE 
                    WHEN l.coordinates IS NOT NULL THEN jsonb_build_object(
                        'latitude', ST_Y(l.coordinates::geometry),
                        'longitude', ST_X(l.coordinates::geometry)
                    )
                    ELSE NULL
                END
            )
    END AS location,
    
    -- Creator profile
    jsonb_build_object(
        'id', pr.id,
        'full_name', pr.full_name,
        'avatar_url', pr.avatar_url
    ) AS creator,
    
    -- Tags as an array
    COALESCE(
        array_agg(t.name) FILTER (WHERE t.id IS NOT NULL),
        '{}'::text[]
    ) AS tags
FROM 
    public.services s
JOIN 
    public.posts p ON s.post_id = p.id
LEFT JOIN 
    public.locations l ON s.location_id = l.id
LEFT JOIN 
    public.profiles pr ON p.user_id = pr.id
LEFT JOIN 
    public.post_tags pt ON p.id = pt.post_id
LEFT JOIN 
    public.tags t ON pt.tag_id = t.id
WHERE 
    p.post_type = 'service'
GROUP BY
    s.id,
    p.id,
    p.slug,
    p.title,
    p.description,
    s.content,
    p.thumbnail_url,
    s.type,
    s.price,
    s.duration,
    p.featured,
    p.created_at,
    p.updated_at,
    p.user_id,
    l.id,
    l.name,
    l.description,
    l.image_url,
    l.line_1,
    l.line_2,
    l.city,
    l.country,
    l.postcode,
    l.maps_link,
    l.coordinates,
    pr.id,
    pr.full_name,
    pr.avatar_url;

-- Function to get detailed service information
CREATE OR REPLACE FUNCTION get_service_details(service_slug TEXT)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT 
        jsonb_build_object(
            'service_id', sv.service_id,
            'post_id', sv.post_id,
            'slug', sv.slug,
            'title', sv.title,
            'description', sv.description,
            'content', sv.content,
            'thumbnail_url', sv.thumbnail_url,
            'service_type', sv.service_type,
            'price', sv.price,
            'duration', sv.duration,
            'featured', sv.featured,
            'created_at', sv.created_at,
            'updated_at', sv.updated_at,
            'location', sv.location,
            'creator', sv.creator,
            'tags', sv.tags
        )
    INTO result
    FROM 
        public.service_details_view sv
    WHERE 
        sv.slug = service_slug;
        
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Simple service details view for backward compatibility
CREATE OR REPLACE VIEW public.service_details AS
SELECT
    s.id,
    p.id AS post_id,
    p.user_id,
    p.title,
    p.slug,
    p.description,
    p.content,
    p.post_type,
    p.status,
    p.thumbnail_url,
    p.created_at,
    p.updated_at,
    p.featured,
    s.price,
    s.location_id,
    l.name AS location_name,
    s.duration,
    s.type AS service_type,
    s.content AS service_content,
    pr.id AS profile_id,
    pr.full_name AS profile_full_name,
    pr.avatar_url AS profile_avatar_url,
    -- Add tags as JSONB array
    COALESCE(
        (
            SELECT jsonb_agg(t.name)
            FROM public.post_tags pt
            JOIN public.tags t ON pt.tag_id = t.id
            WHERE pt.post_id = p.id
        ),
        '[]'::jsonb
    ) AS tags
FROM
    public.services s
JOIN
    public.posts p ON s.post_id = p.id
LEFT JOIN
    public.locations l ON s.location_id = l.id
LEFT JOIN
    public.profiles pr ON p.user_id = pr.id;

-- Grant appropriate permissions
GRANT SELECT ON public.service_details_view TO authenticated;
GRANT SELECT ON public.service_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_service_details TO authenticated;
