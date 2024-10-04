-- Function to create an event
CREATE OR REPLACE FUNCTION public.create_event(
    p_post_id UUID,
    p_content TEXT,
    p_event_type event_type_enum
) RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
BEGIN
    INSERT INTO public.events (
        post_id, content, type
    ) VALUES (
        p_post_id, p_content, p_event_type
    ) RETURNING id INTO v_event_id;

    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;


-- First, ensure the custom type exists (if it doesn't already)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'event_date_input') THEN    
    CREATE TYPE public.event_date_input AS (
        id UUID,
        start_date TIMESTAMP WITH TIME ZONE,
        end_date TIMESTAMP WITH TIME ZONE
    );
  END IF;
END $$;

-- Now, update the function
CREATE OR REPLACE FUNCTION public.add_event_dates(
    p_event_id UUID,
    p_event_dates event_date_input[]
) RETURNS JSONB AS $$
DECLARE
    v_event_date event_date_input;
    v_result JSONB = '[]'::JSONB;
BEGIN
    -- Log the input for debugging
    RAISE NOTICE 'Received event_id: %, event_dates: %', p_event_id, p_event_dates;

    FOREACH v_event_date IN ARRAY p_event_dates
    LOOP
        BEGIN
            -- Log each date being processed
            RAISE NOTICE 'Processing date: start_date %, end_date %', v_event_date.start_date, v_event_date.end_date;

            INSERT INTO public.event_dates (
                event_id, start_date, end_date
            ) VALUES (
                p_event_id,
                v_event_date.start_date,
                v_event_date.end_date
            );
            
            v_result := v_result || jsonb_build_object(
                'success', true,
                'message', 'Date added successfully',
                'start_date', v_event_date.start_date,
                'end_date', v_event_date.end_date
            );

            -- Log successful insertion
            RAISE NOTICE 'Successfully inserted date: start_date %, end_date %', v_event_date.start_date, v_event_date.end_date;
        EXCEPTION
            WHEN exclusion_violation THEN
                v_result := v_result || jsonb_build_object(
                    'success', false,
                    'message', 'Overlapping date range detected',
                    'start_date', v_event_date.start_date,
                    'end_date', v_event_date.end_date
                );
                RAISE NOTICE 'Exclusion violation: start_date %, end_date %', v_event_date.start_date, v_event_date.end_date;
            WHEN OTHERS THEN
                v_result := v_result || jsonb_build_object(
                    'success', false,
                    'message', 'Error adding date: ' || SQLERRM,
                    'start_date', v_event_date.start_date,
                    'end_date', v_event_date.end_date
                );
                RAISE NOTICE 'Other error: %, start_date %, end_date %', SQLERRM, v_event_date.start_date, v_event_date.end_date;
        END;
    END LOOP;
    
    -- Log the final result
    RAISE NOTICE 'Final result: %', v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;


-- Modify the custom type to include an optional id field
CREATE TYPE public.ticket_input AS (
    id UUID,
    title TEXT,
    description TEXT,
    price NUMERIC(10,2),
    quantity INTEGER,
    days_before_unavailable INTEGER
);

-- Modify the function to handle updates and inserts
CREATE OR REPLACE FUNCTION public.add_tickets(
    p_event_id UUID,
    p_tickets ticket_input[]
) RETURNS VOID AS $$
DECLARE
    v_ticket ticket_input;
BEGIN
    FOREACH v_ticket IN ARRAY p_tickets
    LOOP
        -- Check if the ticket id exists
        IF v_ticket.id IS NOT NULL THEN
            -- Update existing ticket
            UPDATE public.tickets
            SET
                title = v_ticket.title,
                description = v_ticket.description,
                price = v_ticket.price,
                quantity = v_ticket.quantity,
                days_before_unavailable = v_ticket.days_before_unavailable
            WHERE id = v_ticket.id AND event_id = p_event_id;
            
            -- If no rows were updated, the ticket doesn't exist for this event, so insert it
            IF NOT FOUND THEN
                INSERT INTO public.tickets (
                    id, event_id, title, description, price, quantity, days_before_unavailable
                ) VALUES (
                    v_ticket.id, p_event_id, v_ticket.title, v_ticket.description,
                    v_ticket.price, v_ticket.quantity, v_ticket.days_before_unavailable
                );
            END IF;
        ELSE
            -- Insert new ticket
            INSERT INTO public.tickets (
                event_id, title, description, price, quantity, days_before_unavailable
            ) VALUES (
                p_event_id, v_ticket.title, v_ticket.description,
                v_ticket.price, v_ticket.quantity, v_ticket.days_before_unavailable
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Now, modify the function to use the custom type
CREATE OR REPLACE FUNCTION public.update_ticket(
    p_event_id UUID,
    p_tickets ticket_input[]
) RETURNS VOID AS $$
DECLARE
    v_ticket ticket_input;
BEGIN
    FOREACH v_ticket IN ARRAY p_tickets
    LOOP
        INSERT INTO public.tickets (
            event_id, title, description, price, quantity, days_before_unavailable
        ) VALUES (
            p_event_id,
            v_ticket.title,
            v_ticket.description,
            v_ticket.price,
            v_ticket.quantity,
            v_ticket.days_before_unavailable
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;


-- Function to create a live room
CREATE OR REPLACE FUNCTION public.create_live_room(
    p_post_id UUID,
    p_name TEXT,
    p_password TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_room_id UUID;
BEGIN
    INSERT INTO public.live_rooms (
        post_id, user_id, name, password
    ) VALUES (
        p_post_id, auth.uid(), p_name, p_password
    ) RETURNING id INTO v_room_id;

    RETURN v_room_id;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;


-- Function to create a location
CREATE OR REPLACE FUNCTION public.create_location(
    p_name TEXT,
    p_description TEXT,
    p_image_url TEXT,
    p_line_1 TEXT,
    p_line_2 TEXT,
    p_city TEXT,
    p_country TEXT,
    p_postcode TEXT,
    p_maps_link TEXT
) RETURNS UUID AS $$
DECLARE
    v_location_id UUID;
BEGIN
    INSERT INTO public.locations (
        name, description, image_url, line_1, line_2, city, country, postcode, maps_link, user_id
    ) VALUES (
        p_name, p_description, p_image_url, p_line_1, p_line_2, p_city, p_country, p_postcode, p_maps_link, auth.uid()
    ) RETURNING id INTO v_location_id;

    RETURN v_location_id;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Function to associate a location with a post
CREATE OR REPLACE FUNCTION public.associate_post_location(
    p_post_id UUID,
    p_location_id UUID
) RETURNS VOID AS $$
BEGIN
    INSERT INTO public.post_locations (post_id, location_id)
    VALUES (p_post_id, p_location_id)
    ON CONFLICT (post_id, location_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
-- First, create a composite type for the return value
CREATE TYPE event_creation_result AS (
    event_id UUID,
    post_id UUID,
    room_id UUID,
    slug TEXT
);




CREATE OR REPLACE FUNCTION public.create_event_with_details(
    p_title TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_content TEXT,
    p_thumbnail_url TEXT,
    p_tags TEXT[],
    p_status publish_status_enum,
    p_event_type event_type_enum,
    p_event_dates event_date_input[],
    p_tickets ticket_input[],
    p_room_name TEXT DEFAULT NULL,
    p_room_password TEXT DEFAULT NULL,
    p_location_id UUID DEFAULT NULL,
    user_id UUID default null
) RETURNS event_creation_result AS $$
DECLARE
    v_post_id UUID;
    v_event_id UUID;
    v_room_id UUID;
    v_date_results JSONB;
    v_result event_creation_result;
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
        'event'::post_type_enum,
        p_status,
        p_thumbnail_url,
        v_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the event
    v_event_id := public.create_event(v_post_id, p_content, p_event_type);

    -- Add event dates
    v_date_results := public.add_event_dates(v_event_id, p_event_dates);

    -- Add tickets
    PERFORM public.add_tickets(v_event_id, p_tickets);

    -- Handle room creation for online or hybrid events
    IF p_event_type IN ('online', 'hybrid') AND p_room_name IS NOT NULL THEN
        v_room_id := public.create_live_room(v_post_id, p_room_name, p_room_password);
    END IF;

    -- Associate location for in-person or hybrid events
    IF p_event_type IN ('in-person', 'hybrid') AND p_location_id IS NOT NULL THEN
        PERFORM public.associate_post_location(v_post_id, p_location_id);
    END IF;

    -- Prepare the result
    v_result := (v_event_id, v_post_id, v_room_id, p_slug);

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;


CREATE OR REPLACE FUNCTION public.update_event_with_details(
    p_event_id UUID,
    p_post_id UUID,
    p_title TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_content TEXT,
    p_thumbnail_url TEXT,
    p_status publish_status_enum,
    p_tags TEXT[],
    p_event_type event_type_enum,
    p_event_dates event_date_input[],
    p_tickets ticket_input[],
    p_room_name TEXT DEFAULT NULL,
    p_room_password TEXT DEFAULT NULL,
    p_location_id UUID DEFAULT NULL
) RETURNS event_creation_result AS $$
DECLARE
    v_room_id UUID;
    v_result event_creation_result;
    v_date event_date_input;
    v_existing_date_id UUID;
BEGIN
    -- Update the post
    UPDATE public.posts
    SET title = p_title,
        slug = p_slug,
        description = p_description,
        content = p_content,
        thumbnail_url = p_thumbnail_url,
        updated_at = NOW(),
        status = p_status
    WHERE id = p_post_id;

    -- Update tags
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Update the event
    UPDATE public.events
    SET content = p_content,
        type = p_event_type,
        updated_at = NOW()
    WHERE id = p_event_id;

    -- Update event dates
    -- First, delete dates that are not in the new set
    DELETE FROM public.event_dates
    WHERE event_id = p_event_id AND id NOT IN (
        SELECT (value->>'id')::UUID
        FROM jsonb_array_elements(to_jsonb(p_event_dates))
        WHERE value->>'id' IS NOT NULL
    );

    -- Then, update or insert new dates
    FOREACH v_date IN ARRAY p_event_dates
    LOOP
        -- Check if this date already exists
        SELECT id INTO v_existing_date_id
        FROM public.event_dates
        WHERE event_id = p_event_id AND id = (v_date.id::UUID);

        IF v_existing_date_id IS NOT NULL THEN
            -- Update existing date
            UPDATE public.event_dates
            SET start_date = v_date.start_date,
                end_date = v_date.end_date
            WHERE id = v_existing_date_id;
        ELSE
            -- Insert new date
            INSERT INTO public.event_dates (event_id, start_date, end_date)
            VALUES (p_event_id, v_date.start_date, v_date.end_date);
        END IF;
    END LOOP;

    -- Update tickets
    -- DELETE FROM public.tickets WHERE event_id = p_event_id;
    PERFORM public.add_tickets(p_event_id, p_tickets);

    -- Handle room update for online or hybrid events
    IF p_event_type IN ('online', 'hybrid') THEN
        SELECT id INTO v_room_id FROM public.live_rooms WHERE post_id = p_post_id;
        
        IF v_room_id IS NOT NULL THEN
            UPDATE public.live_rooms
            SET name = p_room_name,
                password = p_room_password,
                updated_at = NOW()
            WHERE id = v_room_id;
        ELSIF p_room_name IS NOT NULL THEN
            v_room_id := public.create_live_room(p_post_id, p_room_name, p_room_password);
        END IF;
    ELSE
        DELETE FROM public.live_rooms WHERE post_id = p_post_id;
        v_room_id := NULL;
    END IF;

    -- Handle location for in-person or hybrid events
    IF p_event_type IN ('in-person', 'hybrid') THEN
        DELETE FROM public.post_locations WHERE post_id = p_post_id;
        
        IF p_location_id IS NOT NULL THEN
            PERFORM public.associate_post_location(p_post_id, p_location_id);
        END IF;
    ELSE
        DELETE FROM public.post_locations WHERE post_id = p_post_id;
    END IF;

    -- Prepare the result
    v_result := (p_event_id, p_post_id, v_room_id, p_slug);

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;