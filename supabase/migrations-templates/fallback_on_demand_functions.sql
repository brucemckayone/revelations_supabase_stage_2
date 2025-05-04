-- Type for generic on-demand content result (no movement_id)
CREATE TYPE public.generic_ondemand_content_creation_result AS (
    post_id UUID,
    ondemand_media_id UUID,
    protected_media_id UUID,
    slug TEXT
);

-- Function to create generic on-demand content (without movement details)
CREATE OR REPLACE FUNCTION public.create_generic_ondemand_content(
    p_title TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_content TEXT,
    p_thumbnail_url TEXT,
    p_tags TEXT[],
    p_status publish_status_enum,
    p_media_type media_type_enum,
    p_duration INTERVAL,
    p_price NUMERIC(10, 2),
    p_protected_media_url TEXT,
    p_emotional_focuses TEXT[],
    p_playlist_ids UUID[],
    p_user_id UUID DEFAULT NULL
) RETURNS public.generic_ondemand_content_creation_result AS $$
DECLARE
    v_post_id UUID;
    v_ondemand_media_id UUID;
    v_protected_media_id UUID;
    v_result public.generic_ondemand_content_creation_result;
BEGIN
    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'on_demand'::post_type_enum, -- Specify 'on_demand' post type
        p_status,
        p_thumbnail_url,
        p_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the on_demand_media record
    v_ondemand_media_id := public.create_ondemand_media(
        v_post_id,
        p_media_type,
        p_duration,
        p_price,
        p_user_id
    );

    -- Create the protected_media_data record
    v_protected_media_id := public.create_protected_media_data(
        v_ondemand_media_id,
        p_status,
        p_protected_media_url
    );

    -- Add emotional focuses
    PERFORM public.add_emotional_focuses(v_post_id, p_emotional_focuses);

    -- Add playlist associations
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Prepare the result (no movement_id)
    v_result := (v_post_id, v_ondemand_media_id, v_protected_media_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating generic on-demand content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
