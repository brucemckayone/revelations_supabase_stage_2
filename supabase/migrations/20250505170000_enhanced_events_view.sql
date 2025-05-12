-- ENHANCED EVENTS VIEW
-- Provides comprehensive information about events with the new purchase system

-- First, let's create a view to get event information with availability and tickets
CREATE OR REPLACE VIEW public.event_details_view AS
SELECT 
    -- Event base info
    e.id AS event_id,
    p.id AS post_id,
    p.slug,
    p.title,
    p.description,
    e.content,
    p.thumbnail_url,
    e.type AS event_type,
    p.featured,
    p.created_at,
    p.updated_at,
    p.user_id AS creator_id,
    
    -- Location info (for in-person and hybrid events)
    CASE 
        WHEN e.type = 'online' THEN 
            jsonb_build_object('name', 'Online Event')
        ELSE 
            jsonb_build_object(
                'id', l.id,
                'name', l.name,
                'description', l.description,
                'image_url', l.image_url,
                'address', jsonb_build_object(
                    'line_1', l.line_1,
                    'line_2', l.line_2,
                    'city', l.city,
                    'country', l.country,
                    'postcode', l.postcode,
                    'maps_link', l.maps_link
                ),
                'coordinates', CASE 
                    WHEN l.coordinates IS NOT NULL THEN jsonb_build_object(
                        'latitude', ST_Y(l.coordinates::geometry),
                        'longitude', ST_X(l.coordinates::geometry)
                    )
                    ELSE NULL
                END
            )
    END AS location,
    
    -- Room info (for online and hybrid events)
    CASE 
        WHEN e.type IN ('online', 'hybrid') THEN 
            jsonb_build_object(
                'id', lr.id,
                'name', lr.name,
                'password_protected', (lr.password IS NOT NULL)
            )
        ELSE NULL
    END AS room,
    
    -- Creator profile
    jsonb_build_object(
        'id', pr.id,
        'full_name', pr.full_name,
        'avatar_url', pr.avatar_url
    ) AS creator
FROM 
    public.events e
JOIN 
    public.posts p ON e.post_id = p.id
LEFT JOIN 
    public.post_locations pl ON p.id = pl.post_id
LEFT JOIN 
    public.locations l ON pl.location_id = l.id
LEFT JOIN 
    public.live_rooms lr ON p.id = lr.post_id
LEFT JOIN 
    public.profiles pr ON p.user_id = pr.id
WHERE 
    p.post_type = 'event';

-- Create a view for event dates with availability information
CREATE OR REPLACE VIEW public.event_dates_view AS
SELECT 
    ed.id AS date_id,
    ed.event_id,
    ed.start_date,
    ed.end_date,
    (ed.start_date > CURRENT_TIMESTAMP) AS is_future,
    -- Check if the date is fully booked
    CASE 
        WHEN (
            SELECT SUM(eb.attendees)
            FROM public.event_bookings eb
            JOIN public.purchases p ON eb.purchase_id = p.id
            WHERE eb.date_id = ed.id
            AND p.payment_status IN ('completed', 'pending')
            AND eb.status != 'cancelled'
        ) >= COALESCE(
            (
                SELECT SUM(t.quantity)
                FROM public.tickets t
                WHERE t.event_id = ed.event_id
                AND t.quantity IS NOT NULL
            ),
            NULL
        ) 
        AND EXISTS (
            SELECT 1
            FROM public.tickets t
            WHERE t.event_id = ed.event_id
            AND t.quantity IS NOT NULL
        )
        THEN TRUE
        ELSE FALSE
    END AS is_fully_booked,
    -- Number of attendees
    COALESCE(
        (
            SELECT SUM(eb.attendees)
            FROM public.event_bookings eb
            JOIN public.purchases p ON eb.purchase_id = p.id
            WHERE eb.date_id = ed.id
            AND p.payment_status IN ('completed', 'pending')
            AND eb.status != 'cancelled'
        ),
        0
    ) AS current_attendees
FROM 
    public.event_dates ed;

-- Create a view for tickets with availability information
CREATE OR REPLACE VIEW public.event_tickets_view AS
SELECT 
    t.id AS ticket_id,
    t.event_id,
    t.title,
    t.description,
    t.price,
    t.quantity,
    t.days_before_unavailable,
    -- Calculate available quantity
    CASE 
        WHEN t.quantity IS NULL THEN NULL -- Unlimited tickets
        ELSE t.quantity - COALESCE(
            (
                SELECT SUM(eb.attendees)
                FROM public.event_bookings eb
                JOIN public.purchases p ON eb.purchase_id = p.id
                WHERE eb.ticket_id = t.id
                AND p.payment_status IN ('completed', 'pending')
                AND eb.status != 'cancelled'
            ),
            0
        )
    END AS available_quantity,
    -- Check if the ticket type is sold out
    CASE 
        WHEN t.quantity IS NULL THEN FALSE -- Unlimited tickets can't be sold out
        WHEN (
            SELECT SUM(eb.attendees)
            FROM public.event_bookings eb
            JOIN public.purchases p ON eb.purchase_id = p.id
            WHERE eb.ticket_id = t.id
            AND p.payment_status IN ('completed', 'pending')
            AND eb.status != 'cancelled'
        ) >= t.quantity THEN TRUE
        ELSE FALSE
    END AS is_sold_out
FROM 
    public.tickets t;

-- Create a view combining the main event info with dates and tickets
CREATE OR REPLACE VIEW public.comprehensive_events_view AS
SELECT 
    e.*,
    -- Add event dates as a JSONB array
    COALESCE(
        (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'id', edv.date_id,
                    'start_date', edv.start_date,
                    'end_date', edv.end_date,
                    'is_future', edv.is_future,
                    'is_fully_booked', edv.is_fully_booked,
                    'current_attendees', edv.current_attendees
                ) 
                ORDER BY edv.start_date
            )
            FROM public.event_dates_view edv
            WHERE edv.event_id = e.event_id
        ),
        '[]'::jsonb
    ) AS dates,
    
    -- Add future dates as a filtered JSONB array
    COALESCE(
        (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'id', edv.date_id,
                    'start_date', edv.start_date,
                    'end_date', edv.end_date,
                    'is_fully_booked', edv.is_fully_booked,
                    'current_attendees', edv.current_attendees
                ) 
                ORDER BY edv.start_date
            )
            FROM public.event_dates_view edv
            WHERE edv.event_id = e.event_id
            AND edv.is_future = TRUE
        ),
        '[]'::jsonb
    ) AS future_dates,
    
    -- Add tickets as a JSONB array
    COALESCE(
        (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'id', etv.ticket_id,
                    'title', etv.title,
                    'description', etv.description,
                    'price', etv.price,
                    'quantity', etv.quantity,
                    'available_quantity', etv.available_quantity,
                    'is_sold_out', etv.is_sold_out,
                    'days_before_unavailable', etv.days_before_unavailable
                )
                ORDER BY etv.price
            )
            FROM public.event_tickets_view etv
            WHERE etv.event_id = e.event_id
        ),
        '[]'::jsonb
    ) AS tickets,
    
    -- Add tags
    COALESCE(
        (
            SELECT jsonb_agg(t.name)
            FROM public.post_tags pt
            JOIN public.tags t ON pt.tag_id = t.id
            WHERE pt.post_id = e.post_id
        ),
        '[]'::jsonb
    ) AS tags,
    
    -- Next available date
    (
        SELECT MIN(edv.start_date)
        FROM public.event_dates_view edv
        WHERE edv.event_id = e.event_id
        AND edv.is_future = TRUE
        AND edv.is_fully_booked = FALSE
    ) AS next_available_date,
    
    -- Lowest ticket price
    (
        SELECT MIN(etv.price)
        FROM public.event_tickets_view etv
        WHERE etv.event_id = e.event_id
        AND (etv.is_sold_out = FALSE OR etv.quantity IS NULL)
    ) AS min_price
FROM 
    public.event_details_view e;

COMMENT ON VIEW public.comprehensive_events_view IS 'Provides complete event information including location, dates, tickets, and availability for the events page';

-- Grant permissions
GRANT SELECT ON public.event_details_view TO authenticated, anon;
GRANT SELECT ON public.event_dates_view TO authenticated, anon;
GRANT SELECT ON public.event_tickets_view TO authenticated, anon;
GRANT SELECT ON public.comprehensive_events_view TO authenticated, anon;

-- Function to get upcoming events for the events page (with various filters)
CREATE OR REPLACE FUNCTION get_upcoming_events(
    user_lat DOUBLE PRECISION DEFAULT NULL,
    user_lon DOUBLE PRECISION DEFAULT NULL,
    event_types event_type_enum[] DEFAULT NULL,
    distance_limit DOUBLE PRECISION DEFAULT NULL,
    page_size INTEGER DEFAULT 10,
    page_number INTEGER DEFAULT 0,
    only_featured BOOLEAN DEFAULT FALSE,
    creator_ids UUID[] DEFAULT NULL,
    tag_filter TEXT[] DEFAULT NULL
)
RETURNS TABLE (
    event_id UUID,
    post_id UUID,
    slug TEXT,
    title TEXT,
    description TEXT,
    thumbnail_url TEXT,
    event_type event_type_enum,
    location_name TEXT,
    next_date TIMESTAMP WITH TIME ZONE,
    available_tickets BOOLEAN,
    min_price NUMERIC(10,2),
    distance DOUBLE PRECISION,
    total_count BIGINT,
    creator JSONB,
    featured BOOLEAN,
    tags JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH event_with_distance AS (
        SELECT 
            e.event_id,
            e.post_id,
            e.slug,
            e.title,
            e.description,
            e.thumbnail_url,
            e.event_type,
            CASE 
                WHEN e.event_type = 'online' THEN 'Online Event'
                ELSE COALESCE((e.location->>'name')::TEXT, 'Location TBA')
            END AS location_name,
            e.next_available_date as next_date,
            (e.future_dates != '[]'::jsonb AND EXISTS (
                SELECT 1 FROM jsonb_array_elements(e.tickets) t
                WHERE (t->>'is_sold_out')::BOOLEAN = FALSE
            )) AS available_tickets,
            e.min_price,
            -- Calculate distance if location coordinates and user coordinates provided
            CASE 
                WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL 
                AND e.location ? 'coordinates' 
                AND e.location->'coordinates' ? 'latitude'
                AND e.event_type IN ('in-person', 'hybrid') 
                THEN 
                    ST_Distance(
                        ST_SetSRID(ST_MakePoint(
                            (e.location->'coordinates'->>'longitude')::FLOAT,
                            (e.location->'coordinates'->>'latitude')::FLOAT
                        ), 4326)::geography,
                        ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography
                    ) / 1000  -- Convert meters to kilometers
                ELSE NULL
            END AS distance,
            e.creator,
            e.featured,
            e.tags,
            COUNT(*) OVER()::BIGINT as total_count
        FROM 
            public.comprehensive_events_view e
        WHERE 
            e.next_available_date IS NOT NULL
            AND (event_types IS NULL OR e.event_type = ANY(event_types))
            AND (only_featured = FALSE OR e.featured = TRUE)
            AND (creator_ids IS NULL OR e.creator_id = ANY(creator_ids))
            AND (tag_filter IS NULL OR EXISTS (
                SELECT 1 FROM jsonb_array_elements_text(e.tags) tag_name
                WHERE tag_name::TEXT = ANY(tag_filter)
            ))
            AND CASE
                WHEN distance_limit IS NOT NULL 
                    AND user_lat IS NOT NULL 
                    AND user_lon IS NOT NULL 
                    AND e.location ? 'coordinates' 
                    AND e.location->'coordinates' ? 'latitude'
                THEN 
                    ST_Distance(
                        ST_SetSRID(ST_MakePoint(
                            (e.location->'coordinates'->>'longitude')::FLOAT,
                            (e.location->'coordinates'->>'latitude')::FLOAT
                        ), 4326)::geography,
                        ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography
                    ) / 1000 <= distance_limit
                ELSE TRUE
            END
    )
    SELECT 
        ewd.event_id,
        ewd.post_id,
        ewd.slug,
        ewd.title,
        ewd.description,
        ewd.thumbnail_url,
        ewd.event_type,
        ewd.location_name,
        ewd.next_date,
        ewd.available_tickets,
        ewd.min_price,
        ewd.distance,
        ewd.total_count,
        ewd.creator,
        ewd.featured,
        ewd.tags
    FROM 
        event_with_distance ewd
    ORDER BY 
        -- Sort by distance if location-based search, otherwise by date
        CASE 
            WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL THEN ewd.distance
            ELSE NULL
        END NULLS LAST,
        ewd.next_date ASC
    LIMIT page_size
    OFFSET page_number * page_size;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_upcoming_events TO authenticated, anon;

-- Function to get event details by slug
CREATE OR REPLACE FUNCTION get_enhanced_event_details(event_slug TEXT)
RETURNS TABLE (
    event_details JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        jsonb_build_object(
            'event_id', e.event_id,
            'post_id', e.post_id,
            'slug', e.slug,
            'title', e.title,
            'description', e.description,
            'content', e.content,
            'thumbnail_url', e.thumbnail_url,
            'event_type', e.event_type,
            'featured', e.featured,
            'created_at', e.created_at,
            'updated_at', e.updated_at,
            'location', e.location,
            'room', e.room,
            'creator', e.creator,
            'dates', e.dates,
            'future_dates', e.future_dates,
            'tickets', e.tickets,
            'tags', e.tags,
            'next_available_date', e.next_available_date,
            'min_price', e.min_price
        ) AS event_details
    FROM 
        public.comprehensive_events_view e
    WHERE 
        e.slug = event_slug
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_enhanced_event_details TO authenticated, anon;

-- Function to purchase an event ticket (following the purchase system pattern)
CREATE OR REPLACE FUNCTION create_event_purchase(
    p_event_id UUID,
    p_ticket_id UUID,
    p_date_id UUID,
    p_quantity INTEGER,
    p_is_virtual BOOLEAN DEFAULT FALSE,
    p_payment_intent_id TEXT DEFAULT NULL,
    p_payment_status TEXT DEFAULT 'pending'
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_owner_id UUID;
    v_post_id UUID;
    v_ticket_price NUMERIC(10, 2);
    v_currency TEXT;
    v_purchase_id UUID;
    v_booking_id UUID;
    v_is_sold_out BOOLEAN;
    v_is_date_fully_booked BOOLEAN;
    v_ticket_title TEXT;
    v_result JSONB;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    -- Check if the user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to purchase tickets';
    END IF;
    
    -- Get event owner and post details
    SELECT p.user_id, e.post_id 
    INTO v_owner_id, v_post_id
    FROM public.events e
    JOIN public.posts p ON e.post_id = p.id
    WHERE e.id = p_event_id;
    
    -- Check if event exists
    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Event not found';
    END IF;
    
    -- Get ticket price and check availability
    SELECT 
        t.price, 
        t.title,
        etv.is_sold_out
    INTO 
        v_ticket_price, 
        v_ticket_title,
        v_is_sold_out
    FROM public.tickets t
    JOIN public.event_tickets_view etv ON t.id = etv.ticket_id
    WHERE t.id = p_ticket_id;
    
    -- Check if ticket exists
    IF v_ticket_price IS NULL THEN
        RAISE EXCEPTION 'Ticket not found';
    END IF;
    
    -- Check if ticket is sold out
    IF v_is_sold_out THEN
        RAISE EXCEPTION 'This ticket type is sold out';
    END IF;
    
    -- Check if date is fully booked
    SELECT edv.is_fully_booked
    INTO v_is_date_fully_booked
    FROM public.event_dates_view edv
    WHERE edv.date_id = p_date_id;
    
    -- Check if date exists
    IF v_is_date_fully_booked IS NULL THEN
        RAISE EXCEPTION 'Event date not found';
    END IF;
    
    -- Check if date is fully booked
    IF v_is_date_fully_booked THEN
        RAISE EXCEPTION 'This event date is fully booked';
    END IF;
    
    -- Default currency
    v_currency := 'GBP';
    
    -- Create purchase record
    INSERT INTO public.purchases (
        user_id,
        owner_id,
        stripe_payment_intent_id,
        amount,
        currency,
        payment_status,
        post_id,
        event_id,
        purchase_type,
        quantity,
        start_date,
        metadata
    ) VALUES (
        v_user_id,
        v_owner_id,
        p_payment_intent_id,
        v_ticket_price * p_quantity,
        v_currency,
        p_payment_status,
        v_post_id,
        p_event_id,
        'event',
        p_quantity,
        (SELECT start_date FROM public.event_dates WHERE id = p_date_id),
        jsonb_build_object(
            'ticket_name', v_ticket_title,
            'ticket_id', p_ticket_id,
            'date_id', p_date_id,
            'is_virtual', p_is_virtual
        )
    ) RETURNING id INTO v_purchase_id;
    
    -- Create event booking record
    INSERT INTO public.event_bookings (
        purchase_id,
        event_id,
        ticket_id,
        date_id,
        attendees,
        is_virtual,
        status,
        ticket_code
    ) VALUES (
        v_purchase_id,
        p_event_id,
        p_ticket_id,
        p_date_id,
        p_quantity,
        p_is_virtual,
        CASE WHEN p_payment_status = 'completed' THEN 'confirmed' ELSE 'pending' END,
        UPPER(SUBSTRING(MD5(gen_random_uuid()::TEXT) FROM 1 FOR 8))
    ) RETURNING id INTO v_booking_id;
    
    -- Prepare result object to match other purchase function patterns
    v_result := jsonb_build_object(
        'purchase_id', v_purchase_id,
        'booking_id', v_booking_id,
        'event_id', p_event_id,
        'ticket_id', p_ticket_id,
        'date_id', p_date_id,
        'amount', v_ticket_price * p_quantity,
        'payment_status', p_payment_status,
        'attendees', p_quantity
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user event purchases (aligns with get_content_sales, etc.)
CREATE OR REPLACE FUNCTION get_user_event_purchases(
    p_status TEXT DEFAULT NULL
)
RETURNS TABLE (
    purchase_id UUID,
    event_id UUID,
    post_id UUID, 
    title TEXT,
    slug TEXT,
    thumbnail_url TEXT,
    ticket_id UUID,
    ticket_name TEXT,
    ticket_price NUMERIC(10, 2),
    date_id UUID,
    event_date TIMESTAMP WITH TIME ZONE,
    event_end_date TIMESTAMP WITH TIME ZONE,
    purchase_date TIMESTAMP WITH TIME ZONE,
    attendees INTEGER,
    amount NUMERIC(10, 2),
    payment_status TEXT,
    booking_status TEXT,
    ticket_code TEXT,
    is_virtual BOOLEAN,
    event_type event_type_enum,
    location JSONB,
    room JSONB
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id AS purchase_id,
        p.event_id,
        ev.post_id,
        ev.title,
        ev.slug,
        ev.thumbnail_url,
        eb.ticket_id,
        t.title AS ticket_name,
        t.price AS ticket_price,
        eb.date_id,
        ed.start_date AS event_date,
        ed.end_date AS event_end_date,
        p.purchase_date,
        eb.attendees,
        p.amount,
        p.payment_status,
        eb.status AS booking_status,
        eb.ticket_code,
        eb.is_virtual,
        ev.event_type,
        ev.location,
        ev.room
    FROM
        public.purchases p
    JOIN
        public.event_bookings eb ON p.id = eb.purchase_id
    JOIN
        public.event_details_view ev ON p.event_id = ev.event_id
    JOIN
        public.tickets t ON eb.ticket_id = t.id
    JOIN
        public.event_dates ed ON eb.date_id = ed.id
    WHERE
        p.user_id = auth.uid()
        AND p.purchase_type = 'event'
        AND (
            p_status IS NULL 
            OR (
                CASE 
                    WHEN p_status = 'upcoming' THEN 
                        ed.start_date > CURRENT_TIMESTAMP AND p.payment_status != 'refunded'
                    WHEN p_status = 'past' THEN 
                        ed.start_date <= CURRENT_TIMESTAMP AND p.payment_status != 'refunded'
                    WHEN p_status = 'cancelled' THEN 
                        p.payment_status = 'refunded' OR p.payment_status = 'failed'
                    ELSE 
                        p.payment_status = p_status
                END
            )
        )
    ORDER BY
        ed.start_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update event purchase status (aligns with other purchase update functions)
CREATE OR REPLACE FUNCTION update_event_purchase_status(
    p_purchase_id UUID,
    p_payment_status TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
    v_owner_id UUID;
    v_booking_status TEXT;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    -- Validate payment status
    IF p_payment_status NOT IN ('completed', 'pending', 'refunded', 'failed') THEN
        RAISE EXCEPTION 'Invalid payment status';
    END IF;
    
    -- Get purchase owner for permission check
    SELECT owner_id INTO v_owner_id
    FROM public.purchases
    WHERE id = p_purchase_id;
    
    -- Check permissions (must be owner or admin)
    IF v_owner_id != v_user_id AND NOT EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = v_user_id AND role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    -- Determine booking status based on payment status
    CASE 
        WHEN p_payment_status = 'completed' THEN v_booking_status := 'confirmed';
        WHEN p_payment_status = 'pending' THEN v_booking_status := 'pending';
        WHEN p_payment_status = 'refunded' OR p_payment_status = 'failed' THEN v_booking_status := 'cancelled';
        ELSE v_booking_status := 'pending';
    END CASE;
    
    -- Update purchase status
    UPDATE public.purchases
    SET 
        payment_status = p_payment_status,
        completed_at = CASE WHEN p_payment_status = 'completed' THEN CURRENT_TIMESTAMP ELSE completed_at END,
        refunded_at = CASE WHEN p_payment_status = 'refunded' THEN CURRENT_TIMESTAMP ELSE refunded_at END
    WHERE id = p_purchase_id AND purchase_type = 'event';
    
    -- Update booking status
    UPDATE public.event_bookings
    SET status = v_booking_status
    WHERE purchase_id = p_purchase_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if a user has access to an event (similar to can_access_content)
CREATE OR REPLACE FUNCTION can_attend_event(
    p_event_id UUID,
    p_date_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
    v_has_access BOOLEAN;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    -- Check if the user is authenticated
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if the user is the event creator
    SELECT EXISTS (
        SELECT 1
        FROM public.events e
        JOIN public.posts p ON e.post_id = p.id
        WHERE e.id = p_event_id
        AND p.user_id = v_user_id
    ) INTO v_has_access;
    
    -- If user is creator, they have access
    IF v_has_access THEN
        RETURN TRUE;
    END IF;
    
    -- Check if the user has purchased a ticket for this event date
    SELECT EXISTS (
        SELECT 1
        FROM public.purchases p
        JOIN public.event_bookings eb ON p.id = eb.purchase_id
        WHERE p.event_id = p_event_id
        AND eb.date_id = p_date_id
        AND p.user_id = v_user_id
        AND p.payment_status = 'completed'
    ) INTO v_has_access;
    
    RETURN v_has_access;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_event_purchase TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_event_purchases TO authenticated;
GRANT EXECUTE ON FUNCTION update_event_purchase_status TO authenticated;
GRANT EXECUTE ON FUNCTION can_attend_event TO authenticated, anon; 