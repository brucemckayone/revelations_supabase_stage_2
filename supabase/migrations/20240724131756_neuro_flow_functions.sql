-- Create a new type for neuro flow content creation result
CREATE TYPE public.neuroflow_content_creation_result AS (
    post_id UUID,
    ondemand_media_id UUID,
    movement_id UUID,
    protected_media_id UUID,
    neuroflow_id UUID,
    slug TEXT
);

-- Main function to create neuro flow content
CREATE OR REPLACE FUNCTION public.create_neuroflow_content_with_details(
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
    p_props TEXT[],
    p_techniques_used TEXT,
    p_session_focus TEXT,
    p_personal_growth_outcomes TEXT,
    p_user_id UUID DEFAULT NULL
) RETURNS public.neuroflow_content_creation_result AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_neuroflow_id UUID;
    v_result public.neuroflow_content_creation_result;
BEGIN
    -- Create base on-demand content
    v_base_result := public.create_ondemand_content_with_details(
        p_title, p_slug, p_description, p_content, p_thumbnail_url,
        p_tags, p_status, p_media_type, 'neuro_flow'::post_type_enum, p_duration, p_price,
        p_protected_media_url, p_emotional_focuses, p_playlist_ids,
        p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment,
        p_body_focus, p_props, p_user_id
    );

    -- Create the neuro flow record
    INSERT INTO public.neuroflow (
        movement_id,
        techniques_used,
        session_focus,
        personal_growth_outcomes
    ) VALUES (
        v_base_result.movement_id,
        p_techniques_used,
        p_session_focus,
        p_personal_growth_outcomes
    ) RETURNING id INTO v_neuroflow_id;

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_neuroflow_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating neuro flow content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;


-- Function to update neuro flow content
CREATE OR REPLACE FUNCTION public.update_neuroflow_content_with_details(
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
    p_props TEXT[],
    p_techniques_used TEXT,
    p_session_focus TEXT,
    p_personal_growth_outcomes TEXT
) RETURNS public.neuroflow_content_creation_result AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_neuroflow_id UUID;
    v_result public.neuroflow_content_creation_result;
BEGIN
    -- Update base on-demand content
    v_base_result := public.update_ondemand_content_with_details(
        p_post_id, p_title, p_slug, p_description, p_content, p_thumbnail_url,
        p_tags, p_status, p_media_type, p_duration, p_price,
        p_protected_media_url, p_emotional_focuses, p_playlist_ids,
        p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment,
        p_body_focus, p_props
    );

    -- Update or create the neuro flow record
    INSERT INTO public.neuroflow (
        movement_id,
        techniques_used,
        session_focus,
        personal_growth_outcomes
    ) VALUES (
        v_base_result.movement_id,
        p_techniques_used,
        p_session_focus,
        p_personal_growth_outcomes
    )
    ON CONFLICT (movement_id) DO UPDATE
    SET techniques_used = EXCLUDED.techniques_used,
        session_focus = EXCLUDED.session_focus,
        personal_growth_outcomes = EXCLUDED.personal_growth_outcomes
    RETURNING id INTO v_neuroflow_id;

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_neuroflow_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating neuro flow content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;