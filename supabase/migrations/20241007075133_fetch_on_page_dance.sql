CREATE OR REPLACE FUNCTION get_on_page_meditation(p_slug text)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    protected_media_url TEXT,
    user_id UUID,
    slug TEXT,
    content TEXT,
    post_type TEXT,
    status TEXT,
    thumbnail_url TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    featured BOOLEAN,
    tags TEXT,
    profile_id UUID,
    profile_full_name TEXT,
    profile_avatar_url TEXT,
    event_subtype TEXT,
    service_subtype TEXT,
    on_demand_media_id UUID,
    media_type TEXT,
    duration INTERVAL,
    price NUMERIC,
    on_demand_created_at TIMESTAMP,
    on_demand_updated_at TIMESTAMP,
    spotify_playlist_iframes TEXT,
    spotify_playlist_ids TEXT,
    meditation_type TEXT,
    meditation_theme TEXT,
    meditation_focus TEXT,
    what_to_bring TEXT,
    space_holder_names TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dance_det.id,
        dance_det.title,
        dance_det.description,
        pmd.url AS protected_media_url,
        dance_det.user_id,
        dance_det.slug,
        dance_det.content,
        dance_det.post_type,
        dance_det.status,
        dance_det.thumbnail_url,
        dance_det.created_at,
        dance_det.updated_at,
        dance_det.featured,
        dance_det.tags,
        dance_det.profile_id,
        dance_det.profile_full_name,
        dance_det.profile_avatar_url,
        dance_det.event_subtype,
        dance_det.service_subtype,
        dance_det.on_demand_media_id,
        dance_det.media_type,
        dance_det.duration,
        dance_det.price,
        dance_det.on_demand_created_at,
        dance_det.on_demand_updated_at,
        dance_det.spotify_playlist_iframes,
        dance_det.spotify_playlist_ids,
        dance_det.meditation_type,
        dance_det.meditation_theme,
        dance_det.meditation_focus,
        dance_det.what_to_bring,
        dance_det.space_holder_names
    FROM
        dance_details dance_det
    LEFT JOIN 
        public.media_access_control mac 
        ON mac.content_id = dance_det.on_demand_media_id 
        AND mac.user_id = auth.uid()
    LEFT JOIN
        public.protected_media_data pmd 
        ON pmd.content_id = mac.content_id
    WHERE dance_det.slug = p_slug;
END;
$$ LANGUAGE plpgsql;