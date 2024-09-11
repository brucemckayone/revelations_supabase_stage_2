-- Create a new type for dance content creation result
CREATE TYPE public.dance_content_creation_result AS (
    post_id UUID,
    ondemand_media_id UUID,
    movement_id UUID,
    protected_media_id UUID,
    dance_id UUID,
    slug TEXT
);

drop function if exists create_dance_content_with_details;
-- Main function to create dance content
CREATE OR REPLACE FUNCTION public.create_dance_content_with_details(
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
    p_freeform_movement BOOLEAN,
    p_user_id UUID DEFAULT NULL
) RETURNS public.dance_content_creation_result AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_dance_id UUID;
    v_result public.dance_content_creation_result;
BEGIN
    -- Create base on-demand content
    v_base_result := public.create_ondemand_content_with_details(
        p_title, p_slug, p_description, p_content, p_thumbnail_url,
        p_tags, p_status, p_media_type,'dance'::post_type_enum, p_duration, p_price,
        p_protected_media_url, p_emotional_focuses, p_playlist_ids,
        p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment,
        p_body_focus, p_props, p_user_id
    );

    -- Create the dance record
    INSERT INTO public.dance (
        movement_id,
        freeform_movement
    ) VALUES (
        v_base_result.movement_id,
        p_freeform_movement
    ) RETURNING id INTO v_dance_id;

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_dance_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating dance content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;


drop function if exists  update_dance_content_with_details;
-- Function to update dance content
CREATE OR REPLACE FUNCTION public.update_dance_content_with_details(
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
    p_freeform_movement BOOLEAN
) RETURNS public.dance_content_creation_result AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_dance_id UUID;
    v_result public.dance_content_creation_result;
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

    -- Update or create the dance record
    INSERT INTO public.dance (
        movement_id,
        freeform_movement
    ) VALUES (
        v_base_result.movement_id,
        p_freeform_movement
    )
    ON CONFLICT (movement_id) DO UPDATE
    SET freeform_movement = EXCLUDED.freeform_movement
    RETURNING id INTO v_dance_id;

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_dance_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating dance content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;