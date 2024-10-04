-- Create a composite type for the service content creation result
CREATE TYPE public.service_content_creation_result AS (
    post_id UUID,
    service_id UUID,
    slug TEXT
);

CREATE OR REPLACE FUNCTION public.create_service_content_with_details(
    p_title TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_content TEXT,
    p_thumbnail_url TEXT,
    p_tags TEXT[],
    p_status publish_status_enum,
    p_location_id UUID,
    p_price NUMERIC(10, 2),
    p_duration INTERVAL,
    p_type public.event_type_enum,
    user_id UUID default null
) RETURNS service_content_creation_result AS $$
DECLARE
    v_post_id UUID;
    v_service_id UUID;
    v_result service_content_creation_result;
    v_user_id UUID;
BEGIN
    -- If user_id is not provided, use the authenticated user's ID
    IF user_id IS NULL THEN
       v_user_id := auth.uid();
    ELSE
       v_user_id := user_id;
    END IF;

    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'service'::post_type_enum,
        p_status,
        p_thumbnail_url,
        v_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the service record
    INSERT INTO public.services (
        post_id,
        location_id,
        content,
        price,
        duration,
        type
    ) VALUES (
        v_post_id,
        p_location_id,
        p_content,
        p_price,
        p_duration,
        p_type
    ) RETURNING id INTO v_service_id;

    -- Prepare the result
    v_result := (v_post_id, v_service_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating service content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;


-- Function to update service content
CREATE OR REPLACE FUNCTION public.update_service_content_with_details(
    p_post_id UUID,
    p_title TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_content TEXT,
    p_thumbnail_url TEXT,
    p_tags TEXT[],
    p_status publish_status_enum,
    p_location_id UUID,
    p_price NUMERIC(10, 2),
    p_duration INTERVAL,
    p_type public.event_type_enum
) RETURNS public.service_content_creation_result AS $$
DECLARE
    v_service_id UUID;
    v_result public.service_content_creation_result;
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

    -- Update service
    UPDATE public.services
    SET location_id = p_location_id,
        content = p_content,
        price = p_price,
        duration = p_duration,
        type = p_type,
        updated_at = NOW()
    WHERE post_id = p_post_id
    RETURNING id INTO v_service_id;

    -- Prepare the result
    v_result := (p_post_id, v_service_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating service content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;