-- Helper function to create on_demand_media record
CREATE OR REPLACE FUNCTION public.create_ondemand_media(
    p_post_id UUID,
    p_media_type media_type_enum,
    p_duration INTERVAL,
    p_price NUMERIC(10, 2),
    p_user_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_ondemand_media_id UUID;
    v_user_id UUID;
BEGIN
    v_user_id := COALESCE(p_user_id, auth.uid());
    INSERT INTO public.on_demand_media (
        post_id, user_id, media_type, duration, price
    ) VALUES (
        p_post_id, v_user_id, p_media_type, 
        (p_duration || ' seconds')::interval,  -- Convert seconds to interval
        p_price
    ) RETURNING id INTO v_ondemand_media_id;

    IF v_ondemand_media_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create on_demand_media record';
    END IF;

    RETURN v_ondemand_media_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating on_demand_media: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Helper function to create protected_media_data record
CREATE OR REPLACE FUNCTION public.create_protected_media_data(
    p_content_id UUID,
    p_status publish_status_enum,
    p_url TEXT
) RETURNS UUID AS $$
DECLARE
    v_protected_media_id UUID;
BEGIN
    INSERT INTO public.protected_media_data (
        content_id, status, url, updated_at
    ) VALUES (
        p_content_id, p_status, p_url, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_protected_media_id;

    IF v_protected_media_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create protected_media_data record';
    END IF;

    RETURN v_protected_media_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating protected_media_data: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Helper function to add emotional focuses
CREATE OR REPLACE FUNCTION public.add_emotional_focuses(
    p_post_id UUID,
    p_emotional_focuses TEXT[]
) RETURNS VOID AS $$
DECLARE
    v_emotional_focus TEXT;
    v_emotional_focus_id UUID;
BEGIN
    FOREACH v_emotional_focus IN ARRAY p_emotional_focuses
    LOOP
        -- First, ensure the emotional focus exists
        INSERT INTO public.emotional_focuses (value)
        VALUES (v_emotional_focus)
        ON CONFLICT (value) DO NOTHING
        RETURNING id INTO v_emotional_focus_id;

        -- If we didn't get an id from the insert, we need to select it
        IF v_emotional_focus_id IS NULL THEN
            SELECT id INTO v_emotional_focus_id
            FROM public.emotional_focuses
            WHERE value = v_emotional_focus;
        END IF;

        -- Now add the association
        INSERT INTO public.post_emotional_focuses (post_id, emotional_focus_id)
        VALUES (p_post_id, v_emotional_focus_id)
        ON CONFLICT (post_id, emotional_focus_id) DO NOTHING;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding emotional focuses: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Helper function to add playlist associations
CREATE OR REPLACE FUNCTION public.add_playlist_associations(
    p_content_id UUID,
    p_playlist_ids UUID[]
) RETURNS VOID AS $$
DECLARE
    v_playlist_id UUID;
BEGIN
    FOREACH v_playlist_id IN ARRAY p_playlist_ids
    LOOP
        INSERT INTO public.spotify_playlist_join (content_id, playlist_id)
        VALUES (p_content_id, v_playlist_id)
        ON CONFLICT (content_id, playlist_id) DO NOTHING;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding playlist associations: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Helper function to create movement record
CREATE OR REPLACE FUNCTION public.create_movement(
    p_content_id UUID,
    p_instructor_name VARCHAR(100),
    p_session_theme VARCHAR(255),
    p_energy_level INTEGER,
    p_spiritual_elements TEXT,
    p_emotional_focus TEXT,
    p_recommended_environment TEXT,
    p_body_focus TEXT
) RETURNS UUID AS $$
DECLARE
    v_movement_id UUID;
BEGIN
    INSERT INTO public.movements (
        content_id, instructor_name, session_theme, energy_level, 
        spiritual_elements, emotional_focus, recommended_environment, body_focus
    ) VALUES (
        p_content_id, p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment, p_body_focus
    ) RETURNING id INTO v_movement_id;

    IF v_movement_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create movement record';
    END IF;

    RETURN v_movement_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating movement: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Helper function to add movement props
CREATE OR REPLACE FUNCTION public.add_movement_props(
    p_movement_id UUID,
    p_props TEXT[]
) RETURNS VOID AS $$
DECLARE
    v_prop TEXT;
    v_prop_id UUID;
BEGIN
    FOREACH v_prop IN ARRAY p_props
    LOOP
        -- First, ensure the prop exists
        INSERT INTO public.movement_props (name)
        VALUES (v_prop)
        ON CONFLICT (name) DO NOTHING
        RETURNING id INTO v_prop_id;

        -- If we didn't get an id from the insert, we need to select it
        IF v_prop_id IS NULL THEN
            SELECT id INTO v_prop_id
            FROM public.movement_props
            WHERE name = v_prop;
        END IF;

        -- Now add the association
        INSERT INTO public.movement_props_join (movement_id, prop_id)
        VALUES (p_movement_id, v_prop_id)
        ON CONFLICT (movement_id, prop_id) DO NOTHING;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding movement props: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- First, create a composite type for the return value
CREATE TYPE public.ondemand_content_creation_result AS (
    post_id UUID,
    ondemand_media_id UUID,
    movement_id UUID,
    protected_media_id UUID,
    slug TEXT
);



-- Main function to create on-demand content
CREATE OR REPLACE FUNCTION public.create_ondemand_content_with_details(
    p_title TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_content TEXT,
    p_thumbnail_url TEXT,
    p_tags TEXT[],
    p_status publish_status_enum,
    p_media_type media_type_enum,
    p_post_type post_type_enum,
    p_duration INTERVAL,
    p_price NUMERIC(10, 2),
    p_protected_media_url TEXT,
    p_emotional_focuses TEXT[],
    p_playlist_ids UUID[],
    p_instructor_name VARCHAR(100),
    p_session_theme VARCHAR(255),
    p_energy_level INTEGER,
    p_spiritual_elements TEXT,
    p_emotional_focus TEXT,
    p_recommended_environment TEXT,
    p_body_focus TEXT,
    p_props TEXT[],
    p_user_id UUID DEFAULT NULL
) RETURNS ondemand_content_creation_result AS $$
DECLARE
    v_post_id UUID;
    v_ondemand_media_id UUID;
    v_movement_id UUID;
    v_protected_media_id UUID;
    v_result ondemand_content_creation_result;
BEGIN
    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        p_post_type,
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

    -- Create the movement record
    v_movement_id := public.create_movement(
        v_ondemand_media_id,
        p_instructor_name,
        p_session_theme,
        p_energy_level,
        p_spiritual_elements,
        p_emotional_focus,
        p_recommended_environment,
        p_body_focus
    );

    -- Add movement props
    PERFORM public.add_movement_props(v_movement_id, p_props);

    -- Prepare the result
    v_result := (v_post_id, v_ondemand_media_id, v_movement_id, v_protected_media_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating on-demand content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Function to update on-demand content
CREATE OR REPLACE FUNCTION public.update_ondemand_content_with_details(
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
    p_emotional_focuses TEXT[],
    p_playlist_ids UUID[],
    p_instructor_name VARCHAR(100),
    p_session_theme VARCHAR(255),
    p_energy_level INTEGER,
    p_spiritual_elements TEXT,
    p_emotional_focus TEXT,
    p_recommended_environment TEXT,
    p_body_focus TEXT,
    p_props TEXT[]
) RETURNS public.ondemand_content_creation_result AS $$
DECLARE
    v_ondemand_media_id UUID;
    v_movement_id UUID;
    v_protected_media_id UUID;
    v_result public.ondemand_content_creation_result;
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
    RETURNING id, id INTO v_ondemand_media_id, v_result.ondemand_media_id;

    -- Update protected_media_data
    UPDATE public.protected_media_data
    SET status = p_status,
        url = p_protected_media_url
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_protected_media_id;

    -- Update emotional focuses
    DELETE FROM public.post_emotional_focuses WHERE post_id = p_post_id;
    PERFORM public.add_emotional_focuses(p_post_id, p_emotional_focuses);

    -- Update playlist associations
    DELETE FROM public.spotify_playlist_join WHERE content_id = v_ondemand_media_id;
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Update movement
    UPDATE public.movements
    SET instructor_name = p_instructor_name,
        session_theme = p_session_theme,
        energy_level = p_energy_level,
        spiritual_elements = p_spiritual_elements,
        emotional_focus = p_emotional_focus,
        recommended_environment = p_recommended_environment,
        body_focus = p_body_focus,
        updated_at = NOW()
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_movement_id;

    -- Update movement props
    DELETE FROM public.movement_props_join WHERE movement_id = v_movement_id;
    PERFORM public.add_movement_props(v_movement_id, p_props);

    -- Prepare the result
    v_result := (p_post_id, v_ondemand_media_id, v_movement_id, v_protected_media_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating on-demand content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;