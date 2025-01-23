
CREATE OR REPLACE FUNCTION get_event_cards(
    user_lat DOUBLE PRECISION DEFAULT NULL,
    user_lon DOUBLE PRECISION DEFAULT NULL,
    event_types event_type_enum[] DEFAULT NULL,
    time_filter TEXT DEFAULT 'upcoming',
    distance_limit DOUBLE PRECISION DEFAULT NULL,
    page_size INTEGER DEFAULT 10,
    page_number INTEGER DEFAULT 0,
    only_featured BOOLEAN DEFAULT FALSE,
    user_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    slug TEXT,
    title TEXT,
    description TEXT,
    thumbnail_url TEXT,
    event_type event_type_enum,
    location_name TEXT,
    next_date TIMESTAMPTZ,
    available_tickets BIGINT,
    min_price NUMERIC(10,2),
    distance DOUBLE PRECISION,
    total_count BIGINT,
    author JSONB,
    featured BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH next_available_date AS (
        SELECT 
            event_id,
            MIN(start_date) as next_date
        FROM public.event_dates
        WHERE CASE 
            WHEN time_filter = 'upcoming' THEN start_date > CURRENT_TIMESTAMP
            WHEN time_filter = 'past' THEN start_date <= CURRENT_TIMESTAMP
            ELSE TRUE
        END
        GROUP BY event_id
    ),
    ticket_summary AS (
        SELECT 
            t.event_id,
            MIN(t.price) as min_price,
            SUM(
                CASE 
                    WHEN t.quantity IS NULL THEN NULL
                    ELSE t.quantity - COALESCE(
                        (SELECT SUM(tp.quantity) 
                         FROM public.ticket_purchases tp 
                         WHERE tp.ticket_id = t.id),
                        0
                    )
                END
            )::BIGINT as total_available
        FROM public.tickets t
        GROUP BY t.event_id
    ),
    filtered_events AS (
        SELECT 
            p.id as post_id,
            p.slug,
            p.title,
            p.description,
            p.thumbnail_url,
            e.type as event_type,
            CASE 
                WHEN e.type = 'online' THEN 'Online Event'
                ELSE COALESCE(l.name, 'Location TBA')
            END as location_name,
            nad.next_date,
            COALESCE(ts.total_available, 0)::BIGINT as available_tickets,
            ts.min_price,
            CASE 
                WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL 
                    AND l.coordinates IS NOT NULL 
                    AND e.type IN ('in-person', 'hybrid') 
                THEN ST_Distance(
                    l.coordinates::geography,
                    ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography
                ) / 1000  -- Convert meters to kilometers
                ELSE NULL
            END AS event_distance,
            COUNT(*) OVER()::BIGINT as total_count,
            pr.id as author_id,
            pr.full_name as author_full_name,
            pr.avatar_url as author_avatar_url,
            p.featured
        FROM 
            public.posts p
        INNER JOIN 
            public.events e ON p.id = e.post_id
        LEFT JOIN 
            public.post_locations pl ON p.id = pl.post_id
        LEFT JOIN 
            public.locations l ON pl.location_id = l.id
        LEFT JOIN 
            next_available_date nad ON e.id = nad.event_id
        LEFT JOIN 
            ticket_summary ts ON e.id = ts.event_id
        LEFT JOIN 
            public.profiles pr ON p.user_id = pr.id
        WHERE 
            p.post_type = 'event'
            AND (event_types IS NULL OR e.type = ANY(event_types))
            AND (only_featured = FALSE OR p.featured = TRUE)
            AND (user_ids IS NULL OR p.user_id = ANY(user_ids))
            AND CASE 
                WHEN time_filter = 'upcoming' THEN 
                    nad.next_date > CURRENT_TIMESTAMP
                WHEN time_filter = 'past' THEN 
                    nad.next_date <= CURRENT_TIMESTAMP
                ELSE 
                    TRUE
                END
            AND CASE
                WHEN distance_limit IS NOT NULL 
                    AND user_lat IS NOT NULL 
                    AND user_lon IS NOT NULL 
                    AND l.coordinates IS NOT NULL 
                THEN ST_DWithin(
                    l.coordinates::geography,
                    ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography,
                    distance_limit * 1000  -- Convert km to meters
                )
                ELSE 
                    TRUE
                END
    )
    SELECT 
        fe.post_id as id,
        fe.slug,
        fe.title,
        fe.description,
        fe.thumbnail_url,
        fe.event_type,
        fe.location_name,
        fe.next_date,
        fe.available_tickets,
        fe.min_price,
        fe.event_distance AS distance,
        fe.total_count,
        jsonb_build_object(
            'id', fe.author_id,
            'full_name', fe.author_full_name,
            'avatar_url', fe.author_avatar_url
        ) as author,
        fe.featured
    FROM 
        filtered_events fe
    ORDER BY 
        CASE 
            WHEN time_filter = 'upcoming' THEN
                CASE 
                    WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL THEN fe.event_distance
                    ELSE NULL
                END
        END NULLS LAST,
        CASE 
            WHEN time_filter = 'upcoming' THEN fe.next_date
            WHEN time_filter = 'past' THEN fe.next_date
            ELSE fe.next_date
        END DESC
    LIMIT page_size
    OFFSET page_number * page_size;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_event_cards TO authenticated, anon;

CREATE OR REPLACE FUNCTION get_event_details(event_slug TEXT)
RETURNS TABLE (
    id UUID,
    slug TEXT,
    title TEXT,
    description TEXT,
    content TEXT,
    thumbnail_url TEXT,
    event_type event_type_enum,
    featured BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    location JSONB,
    future_dates JSONB[],
    tickets JSONB[],
    author JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.slug,
        p.title,
        p.description,
        e.content,
        p.thumbnail_url,
        e.type as event_type,
        p.featured,
        p.created_at,
        p.updated_at,
        CASE 
            WHEN e.type = 'online' THEN 
                jsonb_build_object('name', 'Online Event')
            ELSE 
                jsonb_build_object(
                    'id', l.id,
                    'name', l.name,
                    'address', generate_coordinates_text(
                        l.line_1, l.line_2, l.city, l.postcode, l.country
                    ),
                    'coordinates', jsonb_build_object(
                        'latitude', ST_Y(l.coordinates::geometry),
                        'longitude', ST_X(l.coordinates::geometry)
                    )
                )
        END as location,
        ARRAY(
            SELECT jsonb_build_object(
                'id', ed.id,
                'start_date', ed.start_date,
                'end_date', ed.end_date
            )
            FROM event_dates ed
            WHERE ed.event_id = e.id
            AND ed.start_date > CURRENT_TIMESTAMP
            ORDER BY ed.start_date
        ) as future_dates,
        ARRAY(
            SELECT jsonb_build_object(
                'id', t.id,
                'name', t.title,
                'description', t.description,
                'price', t.price,
                'quantity', t.quantity,
                'available_quantity', 
                    CASE 
                        WHEN t.quantity IS NULL THEN NULL
                        ELSE t.quantity - COALESCE(
                            (SELECT SUM(tp.quantity) 
                             FROM ticket_purchases tp 
                             WHERE tp.ticket_id = t.id),
                            0
                        )
                    END
            )
            FROM tickets t
            WHERE t.event_id = e.id
            ORDER BY t.price
        ) as tickets,
        jsonb_build_object(
            'id', pr.id,
            'full_name', pr.full_name,
            'avatar_url', pr.avatar_url
        ) as author
    FROM 
        posts p
        INNER JOIN events e ON p.id = e.post_id
        LEFT JOIN post_locations pl ON p.id = pl.post_id
        LEFT JOIN locations l ON pl.location_id = l.id
        LEFT JOIN profiles pr ON p.user_id = pr.id
    WHERE 
        p.slug = event_slug
        AND p.post_type = 'event'
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_event_details TO authenticated, anon;