CREATE OR REPLACE FUNCTION get_on_page_neuro_flow(p_slug text)
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
    techniques_used TEXT,
    session_focus TEXT,
    personal_growth_outcomes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        neuro_det.id,
        neuro_det.title,
        neuro_det.description,
        pmd.url AS protected_media_url,
        neuro_det.user_id,
        neuro_det.slug,
        neuro_det.content,
        neuro_det.post_type,
        neuro_det.status,
        neuro_det.thumbnail_url,
        neuro_det.created_at,
        neuro_det.updated_at,
        neuro_det.featured,
        neuro_det.tags,
        neuro_det.profile_id,
        neuro_det.profile_full_name,
        neuro_det.profile_avatar_url,
        neuro_det.event_subtype,
        neuro_det.service_subtype,
        neuro_det.on_demand_media_id,
        neuro_det.media_type,
        neuro_det.duration,
        neuro_det.price,
        neuro_det.on_demand_created_at,
        neuro_det.on_demand_updated_at,
        neuro_det.spotify_playlist_iframes,
        neuro_det.spotify_playlist_ids,
        neuro_det.movement_id,
        neuro_det.instructor_name,
        neuro_det.session_theme,
        neuro_det.energy_level,
        neuro_det.spiritual_elements,
        neuro_det.emotional_focus,
        neuro_det.recommended_environment,
        neuro_det.body_focus,
        neuro_det.movement_created_at,
        neuro_det.movement_updated_at,
        neuro_det.techniques_used,
        neuro_det.session_focus,
        neuro_det.personal_growth_outcomes
    FROM
        neuroflow_details neuro_det
    LEFT JOIN 
        public.media_access_control mac 
        ON mac.content_id = neuro_det.on_demand_media_id 
        AND mac.user_id = auth.uid()
    LEFT JOIN
        public.protected_media_data pmd 
        ON pmd.content_id = mac.content_id
    WHERE neuro_det.slug = p_slug;
END;
$$ LANGUAGE plpgsql;