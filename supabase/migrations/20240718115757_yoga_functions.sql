-- Helper function to create yoga record
CREATE OR REPLACE FUNCTION public.create_yoga(
    p_movement_id UUID,
    p_yoga_style TEXT,
    p_chakras TEXT
) RETURNS UUID AS $$
DECLARE
    v_yoga_id UUID;
BEGIN
    INSERT INTO public.yoga (
        movement_id, yoga_style, chakras
    ) VALUES (
        p_movement_id, p_yoga_style, p_chakras
    ) RETURNING id INTO v_yoga_id;

    IF v_yoga_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create yoga record';
    END IF;

    RETURN v_yoga_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating yoga record: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Create a new type for yoga content creation result
CREATE TYPE public.yoga_content_creation_result AS (
    post_id UUID,
    ondemand_media_id UUID,
    movement_id UUID,
    protected_media_id UUID,
    yoga_id UUID,
    slug TEXT
);

drop function if exists create_yoga_content_with_details;
-- Main function to create yoga content
CREATE OR REPLACE FUNCTION public.create_yoga_content_with_details(
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
    p_yoga_style TEXT,
    p_chakras TEXT,
    p_user_id UUID DEFAULT NULL
) RETURNS public.yoga_content_creation_result AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_yoga_id UUID;
    v_result public.yoga_content_creation_result;
BEGIN
    
    -- Create base on-demand content
    v_base_result := public.create_ondemand_content_with_details(
        p_title, p_slug, p_description, p_content, p_thumbnail_url,
        p_tags, p_status, p_media_type, 'yoga'::post_type_enum, p_duration, p_price,
        p_protected_media_url, p_emotional_focuses, p_playlist_ids,
        p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment,
        p_body_focus, p_props, p_user_id
    );

    -- Create the yoga record
    v_yoga_id := public.create_yoga(
        v_base_result.movement_id,
        p_yoga_style,
        p_chakras
    );

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_yoga_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating yoga content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;


drop function if exists update_yoga_content_with_details;
-- Update the function
CREATE OR REPLACE FUNCTION public.update_yoga_content_with_details(
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
    p_yoga_style TEXT,
    p_chakras TEXT
) RETURNS public.yoga_content_creation_result AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_yoga_id UUID;
    v_result public.yoga_content_creation_result;
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

    -- Update or create the yoga record
    INSERT INTO public.yoga (
        movement_id, yoga_style, chakras
    ) VALUES (
        v_base_result.movement_id, p_yoga_style, p_chakras
    )
    ON CONFLICT (movement_id) DO UPDATE
    SET yoga_style = EXCLUDED.yoga_style,
        chakras = EXCLUDED.chakras
    RETURNING id INTO v_yoga_id;

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_yoga_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating yoga content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;