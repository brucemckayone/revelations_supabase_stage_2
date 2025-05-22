-- Generated with srtd from template: supabase/migrations-templates/service_functions_with_booking.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- SERVICE APPOINTMENT FUNCTIONS WITH BOOKING WORKFLOW
-- Adds booking workflow parameters to service creation and update functions

-- Drop existing functions without specifying parameters
-- This makes it easier to change parameter signatures later
DROP FUNCTION IF EXISTS public.create_service_content_with_details;
DROP FUNCTION IF EXISTS public.update_service_content_with_details;

-- Update the create_service_content_with_details function to include booking workflow parameters
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
    p_booking_workflow TEXT DEFAULT 'pre-approval',
    p_auto_confirm BOOLEAN DEFAULT false,
    p_confirmation_deadline_hours INTEGER DEFAULT 24,
    user_id UUID DEFAULT NULL
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

    -- Create the service record with booking workflow parameters
    INSERT INTO public.services (
        post_id,
        location_id,
        content,
        price,
        duration,
        type,
        booking_workflow,
        auto_confirm,
        confirmation_deadline_hours
    ) VALUES (
        v_post_id,
        p_location_id,
        p_content,
        p_price,
        p_duration,
        p_type,
        p_booking_workflow,
        p_auto_confirm,
        p_confirmation_deadline_hours
    ) RETURNING id INTO v_service_id;

    -- Prepare the result
    v_result := (v_post_id, v_service_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating service content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Update the update_service_content_with_details function to include booking workflow parameters
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
    p_type public.event_type_enum,
    p_booking_workflow TEXT DEFAULT NULL,
    p_auto_confirm BOOLEAN DEFAULT NULL,
    p_confirmation_deadline_hours INTEGER DEFAULT NULL
) RETURNS public.service_content_creation_result AS $$
DECLARE
    v_service_id UUID;
    v_result public.service_content_creation_result;
    v_current_workflow TEXT;
    v_current_auto_confirm BOOLEAN;
    v_current_deadline INTEGER;
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

    -- Update or keep existing booking workflow parameters
    SELECT booking_workflow, auto_confirm, confirmation_deadline_hours 
    INTO v_current_workflow, v_current_auto_confirm, v_current_deadline
    FROM public.services
    WHERE post_id = p_post_id;

    -- Update the service
    UPDATE public.services
    SET location_id = p_location_id,
        content = p_content,
        price = p_price,
        duration = p_duration,
        type = p_type,
        booking_workflow = COALESCE(p_booking_workflow, v_current_workflow),
        auto_confirm = COALESCE(p_auto_confirm, v_current_auto_confirm),
        confirmation_deadline_hours = COALESCE(p_confirmation_deadline_hours, v_current_deadline),
        updated_at = NOW()
    WHERE post_id = p_post_id
    RETURNING id INTO v_service_id;

    -- Handle the tags separately using the update_post_tags function
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Prepare the result
    v_result := (p_post_id, v_service_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating service content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
