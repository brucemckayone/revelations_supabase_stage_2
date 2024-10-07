drop function get_on_page_meditation_by_slug;
CREATE OR REPLACE FUNCTION get_on_page_meditation_by_slug(p_slug text)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    title TEXT,
    slug TEXT,
    description TEXT,
    content text,
    post_type TEXT,
    status TEXT,
    thumbnail_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    featured BOOLEAN,
    tags varchar[],
    profile_id UUID,
    profile_full_name TEXT,
    profile_avatar_url TEXT,
    event_subtype event_type_enum,
    service_subtype event_type_enum,
    on_demand_media_id UUID,
    media_type media_type_enum,
    duration INTERVAL,
    price NUMERIC,
    on_demand_created_at TIMESTAMP WITH TIME ZONE,
    on_demand_updated_at TIMESTAMP WITH TIME ZONE,
    spotify_playlist_iframes TEXT[],
    spotify_playlist_ids UUID[],
    meditation_type TEXT,
    meditation_theme TEXT,
    meditation_focus TEXT,
    what_to_bring TEXT,
    space_holder_names TEXT,
    protected_media_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        med_det.id,
        med_det.user_id,
        med_det.title,
        med_det.slug,
        med_det.description,
        med_det.content,
        med_det.post_type,
        med_det.status,
        med_det.thumbnail_url,
        med_det.created_at,
        med_det.updated_at,
        med_det.featured,
        med_det.tags,
        med_det.profile_id,
        med_det.profile_full_name,
        med_det.profile_avatar_url,
        med_det.event_subtype,
        med_det.service_subtype,
        med_det.on_demand_media_id,
        med_det.media_type,
        med_det.duration,
        med_det.price,
        med_det.on_demand_created_at,
        med_det.on_demand_updated_at,
        med_det.spotify_playlist_iframes,
        med_det.spotify_playlist_ids,
        med_det.meditation_type,
        med_det.meditation_theme,
        med_det.meditation_focus,
        med_det.what_to_bring,
        med_det.space_holder_names,
        pmd.url AS protected_media_url
    FROM
        meditation_details med_det
    LEFT JOIN 
        public.media_access_control mac 
        ON mac.content_id = med_det.on_demand_media_id 
        AND mac.user_id = auth.uid()
    LEFT JOIN
        public.protected_media_data pmd 
        ON pmd.content_id = mac.content_id
    where med_det.slug = p_slug;
END;
$$ LANGUAGE plpgsql;
