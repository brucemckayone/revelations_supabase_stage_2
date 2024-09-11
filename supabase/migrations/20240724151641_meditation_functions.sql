-- First, create a composite type for the meditation content creation result
CREATE TYPE public.meditation_content_creation_result AS (
    post_id UUID,
    ondemand_media_id UUID,
    protected_media_id UUID,
    meditation_id UUID,
    slug TEXT
);


-- Main function to create meditation content
CREATE OR REPLACE FUNCTION public.create_meditation_content_with_details(
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
    p_playlist_ids UUID[],
    p_meditation_type TEXT,
    p_meditation_theme TEXT,
    p_meditation_focus TEXT
) RETURNS meditation_content_creation_result AS $$
DECLARE
    v_post_id UUID;
    v_ondemand_media_id UUID;
    v_protected_media_id UUID;
    v_meditation_id UUID;
    v_result meditation_content_creation_result;
BEGIN
    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'meditation'::post_type_enum,
        p_status,
        p_thumbnail_url
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the on_demand_media record
    v_ondemand_media_id := public.create_ondemand_media(
        v_post_id,
        p_media_type,
        p_duration,
        p_price
    );

    -- Create the protected_media_data record
    v_protected_media_id := public.create_protected_media_data(
        v_ondemand_media_id,
        p_status,
        p_protected_media_url
    );

    -- Add playlist associations
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Create the meditation record
    INSERT INTO public.meditations (
        content_id,
        meditation_type,
        meditation_theme,
        meditation_focus
    ) VALUES (
        v_ondemand_media_id,
        p_meditation_type,
        p_meditation_theme,
        p_meditation_focus
    ) RETURNING id INTO v_meditation_id;

    -- Prepare the result
    v_result := (v_post_id, v_ondemand_media_id, v_protected_media_id, v_meditation_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating meditation content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Function to update meditation content
CREATE OR REPLACE FUNCTION public.update_meditation_content_with_details(
    p_post_id UUID,
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
    p_playlist_ids UUID[],
    p_meditation_type TEXT,
    p_meditation_theme TEXT,
    p_meditation_focus TEXT
) RETURNS public.meditation_content_creation_result AS $$
DECLARE
    v_ondemand_media_id UUID;
    v_protected_media_id UUID;
    v_meditation_id UUID;
    v_result public.meditation_content_creation_result;
BEGIN
    -- Update the post
    UPDATE public.posts
    SET title = p_title,
        slug = p_slug,
        description = p_description,
        content = p_content,
        thumbnail_url = p_thumbnail_url,
        status = p_status,
        updated_at = NOW()
    WHERE id = p_post_id;

    -- Update tags
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Update on_demand_media
    UPDATE public.on_demand_media
    SET media_type = p_media_type,
        duration = p_duration,
        price = p_price,
        updated_at = NOW()
    WHERE post_id = p_post_id
    RETURNING id INTO v_ondemand_media_id;

    -- Update protected_media_data
    UPDATE public.protected_media_data
    SET status = p_status,
        url = p_protected_media_url
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_protected_media_id;

    -- Update playlist associations
    DELETE FROM public.spotify_playlist_join WHERE content_id = v_ondemand_media_id;
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Update meditation
    UPDATE public.meditations
    SET meditation_type = p_meditation_type,
        meditation_theme = p_meditation_theme,
        meditation_focus = p_meditation_focus
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_meditation_id;

    -- Prepare the result
    v_result := (p_post_id, v_ondemand_media_id, v_protected_media_id, v_meditation_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating meditation content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;