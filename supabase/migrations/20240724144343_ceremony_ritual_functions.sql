-- First, create a composite type for the ceremony content creation result
CREATE TYPE public.ceremony_content_creation_result AS (
    post_id UUID,
    ondemand_media_id UUID,
    protected_media_id UUID,
    ceremony_id UUID,
    slug TEXT
);

-- Main function to create ceremony content
CREATE OR REPLACE FUNCTION public.create_ceremony_content_with_details(
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
    p_ceremony_type TEXT,
    p_ceremony_theme TEXT,
    p_ceremony_focus TEXT,
    p_what_to_bring TEXT,
    p_space_holder_names TEXT
) RETURNS ceremony_content_creation_result AS $$
DECLARE
    v_post_id UUID;
    v_ondemand_media_id UUID;
    v_protected_media_id UUID;
    v_ceremony_id UUID;
    v_result ceremony_content_creation_result;
BEGIN
    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'ceremony'::post_type_enum,
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

    -- Create the ceremony record
    INSERT INTO public.ceremony (
        content_id,
        ceremony_type,
        ceremony_theme,
        ceremony_focus,
        what_to_bring,
        space_holder_names
    ) VALUES (
        v_ondemand_media_id,
        p_ceremony_type,
        p_ceremony_theme,
        p_ceremony_focus,
        p_what_to_bring,
        p_space_holder_names
    ) RETURNING id INTO v_ceremony_id;

    -- Prepare the result
    v_result := (v_post_id, v_ondemand_media_id, v_protected_media_id, v_ceremony_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating ceremony content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Function to update ceremony content
CREATE OR REPLACE FUNCTION public.update_ceremony_content_with_details(
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
    p_ceremony_type TEXT,
    p_ceremony_theme TEXT,
    p_ceremony_focus TEXT,
    p_what_to_bring TEXT,
    p_space_holder_names TEXT
) RETURNS public.ceremony_content_creation_result AS $$
DECLARE
    v_ondemand_media_id UUID;
    v_protected_media_id UUID;
    v_ceremony_id UUID;
    v_result public.ceremony_content_creation_result;
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

    -- Update ceremony
    UPDATE public.ceremony
    SET ceremony_type = p_ceremony_type,
        ceremony_theme = p_ceremony_theme,
        ceremony_focus = p_ceremony_focus,
        what_to_bring = p_what_to_bring,
        space_holder_names = p_space_holder_names
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_ceremony_id;

    -- Prepare the result
    v_result := (p_post_id, v_ondemand_media_id, v_protected_media_id, v_ceremony_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating ceremony content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;