CREATE OR REPLACE FUNCTION get_on_page_yoga(p_slug text)
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
    movement_id UUID,
    instructor_name TEXT,
    session_theme TEXT,
    energy_level INTEGER,
    spiritual_elements TEXT,
    emotional_focus TEXT,
    recommended_environment TEXT,
    body_focus TEXT,
    movement_created_at TIMESTAMP,
    movement_updated_at TIMESTAMP,
    yoga_style TEXT,
    chakras TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        yoga_det.id,
        yoga_det.title,
        yoga_det.description,
        pmd.url AS protected_media_url,
        yoga_det.user_id,
        yoga_det.slug,
        yoga_det.content,
        yoga_det.post_type,
        yoga_det.status,
        yoga_det.thumbnail_url,
        yoga_det.created_at,
        yoga_det.updated_at,
        yoga_det.featured,
        yoga_det.tags,
        yoga_det.profile_id,
        yoga_det.profile_full_name,
        yoga_det.profile_avatar_url,
        yoga_det.event_subtype,
        yoga_det.service_subtype,
        yoga_det.on_demand_media_id,
        yoga_det.media_type,
        yoga_det.duration,
        yoga_det.price,
        yoga_det.on_demand_created_at,
        yoga_det.on_demand_updated_at,
        yoga_det.spotify_playlist_iframes,
        yoga_det.spotify_playlist_ids,
        yoga_det.movement_id,
        yoga_det.instructor_name,
        yoga_det.session_theme,
        yoga_det.energy_level,
        yoga_det.spiritual_elements,
        yoga_det.emotional_focus,
        yoga_det.recommended_environment,
        yoga_det.body_focus,
        yoga_det.movement_created_at,
        yoga_det.movement_updated_at,
        yoga_det.yoga_style,
        yoga_det.chakras
    FROM
        yoga_details yoga_det
    LEFT JOIN 
        public.media_access_control mac 
        ON mac.content_id = yoga_det.on_demand_media_id 
        AND mac.user_id = auth.uid()
    LEFT JOIN
        public.protected_media_data pmd 
        ON pmd.content_id = mac.content_id
    WHERE yoga_det.slug = p_slug;
END;
$$ LANGUAGE plpgsql;