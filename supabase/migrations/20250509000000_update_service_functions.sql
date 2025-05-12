-- SERVICE APPOINTMENT SYSTEM: UPDATE SERVICE CREATION FUNCTIONS
-- Adds booking workflow parameters to service creation and update functions

-- Drop existing functions with their parameter signatures to handle overloads
DROP FUNCTION IF EXISTS public.create_service_content_with_details(
    TEXT, TEXT, TEXT, TEXT, TEXT, TEXT[], 
    public.publish_status_enum, UUID, NUMERIC, INTERVAL, 
    public.event_type_enum, UUID
);

DROP FUNCTION IF EXISTS public.update_service_content_with_details(
    UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT[], 
    public.publish_status_enum, UUID, NUMERIC, INTERVAL, 
    public.event_type_enum
);

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

    -- Update tags
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Get current workflow values if not provided
    SELECT 
        booking_workflow, 
        auto_confirm, 
        confirmation_deadline_hours
    INTO 
        v_current_workflow, 
        v_current_auto_confirm, 
        v_current_deadline
    FROM public.services
    WHERE post_id = p_post_id;

    -- Update service with workflow parameters or keep current values
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

    -- Prepare the result
    v_result := (p_post_id, v_service_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating service content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Function to update just the booking workflow settings for a service
CREATE OR REPLACE FUNCTION update_service_booking_settings(
    p_service_id UUID,
    p_booking_workflow TEXT,
    p_auto_confirm BOOLEAN,
    p_confirmation_deadline_hours INTEGER DEFAULT 24
) RETURNS JSONB AS $$
DECLARE
    v_updated BOOLEAN;
BEGIN
    UPDATE public.services
    SET 
        booking_workflow = p_booking_workflow,
        auto_confirm = p_auto_confirm,
        confirmation_deadline_hours = p_confirmation_deadline_hours,
        updated_at = NOW()
    WHERE 
        id = p_service_id
    RETURNING true INTO v_updated;
    
    IF v_updated THEN
        RETURN jsonb_build_object(
            'success', true,
            'service_id', p_service_id,
            'message', 'Service booking settings updated successfully'
        );
    ELSE
        RETURN jsonb_build_object(
            'success', false,
            'service_id', p_service_id,
            'message', 'Service not found'
        );
    END IF;
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'service_id', p_service_id,
        'message', 'Error updating service: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant appropriate permissions
GRANT EXECUTE ON FUNCTION public.create_service_content_with_details TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_service_content_with_details TO authenticated;
GRANT EXECUTE ON FUNCTION update_service_booking_settings TO authenticated;

-- Update the specific service that had the issue
UPDATE public.services
SET 
    booking_workflow = 'pre-approval',
    auto_confirm = false
WHERE 
    id = 'a0a772ac-9e7e-4dbd-a4d0-5d1d8a2c1791';

-- Update any existing services that are using direct workflow with auto_confirm
-- This ensures all services follow a consistent approval pattern by default
UPDATE public.services
SET 
    booking_workflow = 'pre-approval',
    auto_confirm = false
WHERE 
    booking_workflow = 'direct' AND auto_confirm = true;

COMMENT ON FUNCTION public.create_service_content_with_details IS 'Creates a service with booking workflow configuration';
COMMENT ON FUNCTION public.update_service_content_with_details IS 'Updates a service including booking workflow settings';
COMMENT ON FUNCTION update_service_booking_settings IS 'Updates just the booking workflow settings for a service'; 