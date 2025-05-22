-- Add the new events_view that supports filtering by various criteria
CREATE OR REPLACE VIEW "public"."events_view" AS
 WITH event_dates_summary AS (
    SELECT
        ed.event_id,
        MIN(CASE WHEN ed.start_date > CURRENT_TIMESTAMP THEN ed.start_date ELSE NULL END) AS next_date,
        MIN(CASE WHEN ed.start_date <= CURRENT_TIMESTAMP THEN ed.start_date ELSE NULL END) AS latest_past_date,
        ARRAY_AGG(ed.id ORDER BY ed.start_date) AS date_ids,
        COUNT(DISTINCT ed.id) FILTER (WHERE ed.start_date > CURRENT_TIMESTAMP) AS future_dates_count,
        COUNT(DISTINCT ed.id) FILTER (WHERE ed.start_date <= CURRENT_TIMESTAMP) AS past_dates_count,
        EXISTS (
            SELECT 1 FROM public.event_dates ed2
            WHERE ed2.event_id = ed.event_id
            AND ed2.start_date > CURRENT_TIMESTAMP
            AND NOT EXISTS (
                SELECT 1 FROM public.event_dates_view edv
                WHERE edv.date_id = ed2.id AND edv.is_fully_booked = true
            )
        ) AS has_available_future_dates
    FROM 
        public.event_dates ed
    GROUP BY 
        ed.event_id
  ),
  ticket_summary AS (
    SELECT
        t.event_id,
        MIN(t.price) AS min_price,
        MAX(t.price) AS max_price,
        COUNT(*) AS ticket_types_count,
        SUM(CASE WHEN etv.is_sold_out = false THEN 1 ELSE 0 END) AS available_ticket_types_count
    FROM
        public.tickets t
    JOIN
        public.event_tickets_view etv ON t.id = etv.ticket_id
    GROUP BY
        t.event_id
  )
  SELECT
    e.event_id,
    e.post_id,
    e.slug,
    e.title,
    e.description,
    e.content,
    e.thumbnail_url,
    e.event_type,
    CASE 
        WHEN e.event_type = 'online' THEN 'Online Event'
        ELSE COALESCE((e.location->>'name')::TEXT, 'Location TBA')
    END AS location_name,
    e.location,
    e.room,
    e.creator_id,
    e.creator,
    e.featured,
    e.created_at,
    e.updated_at,
    e.dates,
    e.future_dates,
    e.tickets,
    eds.next_date,
    eds.latest_past_date,
    eds.date_ids,
    eds.future_dates_count,
    eds.past_dates_count,
    eds.has_available_future_dates,
    CASE
        WHEN eds.next_date IS NOT NULL THEN 'upcoming'
        WHEN eds.latest_past_date IS NOT NULL THEN 'past'
        ELSE 'draft'
    END AS event_status,
    ts.min_price,
    ts.max_price,
    ts.ticket_types_count,
    ts.available_ticket_types_count,
    COALESCE(e.tags, '[]'::jsonb) AS tags
  FROM
    public.comprehensive_events_view e
  LEFT JOIN
    event_dates_summary eds ON e.event_id = eds.event_id
  LEFT JOIN
    ticket_summary ts ON e.event_id = ts.event_id;

ALTER TABLE "public"."events_view" OWNER TO "postgres";

COMMENT ON VIEW "public"."events_view" IS 'A comprehensive view of events with additional metadata for filtering by status (upcoming, past, all) and availability';


CREATE TYPE public.event_status_enum AS ENUM (
    'upcoming',
    'past',
    'all'
);

CREATE TYPE event_filters AS (
    status public.event_status_enum,
    event_types public.event_type_enum[],
    creator_ids uuid[],
    tags text[],
    user_lat double precision,
    user_lon double precision,
    distance_limit double precision
);

-- Create a filter-enabled function that uses our new view
CREATE OR REPLACE FUNCTION "public"."filter_events"(
    "filters" jsonb DEFAULT '{}'::jsonb
) RETURNS TABLE(
    "event_id" uuid,
    "post_id" uuid,
    "slug" text,
    "title" text,
    "description" text,
    "thumbnail_url" text,
    "event_type" public.event_type_enum,
    "location_name" text,
    "location" jsonb,
    "creator" jsonb,
    "featured" boolean,
    "next_date" timestamp with time zone,
    "latest_past_date" timestamp with time zone,
    "min_price" numeric,
    "tags" jsonb,
    "event_status" text,
    "has_available_tickets" boolean,
    "distance" double precision,
    "attendees_count" bigint,
    "date_attendees" jsonb,
    "total_count" bigint
) LANGUAGE plpgsql AS $$
DECLARE
    v_status text;
    v_event_types public.event_type_enum[];
    v_user_lat double precision;
    v_user_lon double precision;
    v_distance_limit double precision;
    v_only_featured boolean;
    v_creator_ids uuid[];
    v_tag_filter text[];
    v_page_size integer;
    v_page_number integer;
    v_search text;
BEGIN
    -- Extract filter parameters
    v_status := filters->>'status';
    v_only_featured := COALESCE((filters->>'featured')::boolean, false);
    v_page_size := COALESCE((filters->>'pageSize')::integer, 10);
    v_page_number := COALESCE((filters->>'page')::integer, 0);
    v_search := filters->>'search';
    
    -- Parse array parameters
    IF filters ? 'eventTypes' AND jsonb_typeof(filters->'eventTypes') = 'array' THEN
        SELECT array_agg(e::public.event_type_enum)
        INTO v_event_types
        FROM jsonb_array_elements_text(filters->'eventTypes') e;
    END IF;
    
    IF filters ? 'creatorIds' AND jsonb_typeof(filters->'creatorIds') = 'array' THEN
        SELECT array_agg(c::uuid)
        INTO v_creator_ids
        FROM jsonb_array_elements_text(filters->'creatorIds') c;
    END IF;
    
    IF filters ? 'tags' AND jsonb_typeof(filters->'tags') = 'array' THEN
        SELECT array_agg(t::text)
        INTO v_tag_filter
        FROM jsonb_array_elements_text(filters->'tags') t;
    END IF;
    
    -- Location-based filtering parameters
    v_user_lat := (filters->>'userLat')::double precision;
    v_user_lon := (filters->>'userLon')::double precision;
    v_distance_limit := (filters->>'distanceLimit')::double precision;
    
    RETURN QUERY
    WITH attendee_counts AS (
        SELECT 
            eb.event_id,
            eb.date_id,
            ed.start_date,
            SUM(eb.attendees) as total_attendees
        FROM 
            public.event_bookings eb
        JOIN
            public.purchases p ON eb.purchase_id = p.id
        JOIN
            public.event_dates ed ON eb.date_id = ed.id
        WHERE 
            eb.status != 'cancelled' AND
            p.payment_status = 'completed'
        GROUP BY 
            eb.event_id, eb.date_id, ed.start_date
    ),
    date_attendee_counts AS (
        SELECT
            ac.event_id,
            JSONB_AGG(
                jsonb_build_object(
                    'date_id', ac.date_id,
                    'date', ac.start_date,
                    'attendees', ac.total_attendees
                )
            ) AS date_attendees,
            SUM(ac.total_attendees) AS total_attendees
        FROM
            attendee_counts ac
        GROUP BY
            ac.event_id
    ),
    filtered_events AS (
        SELECT
            ev.*,
            CASE 
                WHEN v_user_lat IS NOT NULL AND v_user_lon IS NOT NULL 
                AND ev.location ? 'coordinates' 
                AND ev.location->'coordinates' ? 'latitude'
                AND ev.event_type IN ('in-person', 'hybrid') 
                THEN 
                    ST_Distance(
                        ST_SetSRID(ST_MakePoint(
                            (ev.location->'coordinates'->>'longitude')::FLOAT,
                            (ev.location->'coordinates'->>'latitude')::FLOAT
                        ), 4326)::geography,
                        ST_SetSRID(ST_MakePoint(v_user_lon, v_user_lat), 4326)::geography
                    ) / 1000  -- Convert meters to kilometers
                ELSE NULL
            END AS distance,
            COUNT(*) OVER()::BIGINT as total_count
        FROM public.events_view ev
        WHERE
            -- Status filtering
            (v_status IS NULL OR v_status = 'all' OR ev.event_status = v_status)
            
            -- Event type filtering
            AND (v_event_types IS NULL OR ev.event_type = ANY(v_event_types))
            
            -- Featured filtering
            AND (v_only_featured = FALSE OR ev.featured = TRUE)
            
            -- Creator filtering
            AND (v_creator_ids IS NULL OR ev.creator_id = ANY(v_creator_ids))
            
            -- Tag filtering
            AND (v_tag_filter IS NULL OR EXISTS (
                SELECT 1 FROM jsonb_array_elements_text(ev.tags) tag_name
                WHERE tag_name::TEXT = ANY(v_tag_filter)
            ))
            
            -- Search filtering
            AND (v_search IS NULL OR v_search = '' OR 
                 ev.title ILIKE '%' || v_search || '%' OR 
                 ev.description ILIKE '%' || v_search || '%')
            
            -- Distance filtering
            AND (v_distance_limit IS NULL OR v_user_lat IS NULL OR v_user_lon IS NULL OR
                NOT (ev.event_type IN ('in-person', 'hybrid')) OR
                NOT (ev.location ? 'coordinates') OR
                ST_Distance(
                    ST_SetSRID(ST_MakePoint(
                        (ev.location->'coordinates'->>'longitude')::FLOAT,
                        (ev.location->'coordinates'->>'latitude')::FLOAT
                    ), 4326)::geography,
                    ST_SetSRID(ST_MakePoint(v_user_lon, v_user_lat), 4326)::geography
                ) / 1000 <= v_distance_limit
            )
    )
    SELECT
        fe.event_id,
        fe.post_id,
        fe.slug,
        fe.title,
        fe.description, 
        fe.thumbnail_url,
        fe.event_type,
        fe.location_name,
        fe.location,
        fe.creator,
        fe.featured,
        fe.next_date,
        fe.latest_past_date,
        fe.min_price,
        fe.tags,
        fe.event_status,
        fe.has_available_future_dates AND fe.available_ticket_types_count > 0 AS has_available_tickets,
        fe.distance,
        COALESCE(dac.total_attendees, 0)::bigint AS attendees_count,
        dac.date_attendees,
        fe.total_count
    FROM filtered_events fe
    LEFT JOIN
        date_attendee_counts dac ON fe.event_id = dac.event_id
    ORDER BY
        -- For upcoming events, prioritize by distance if location-based, then date
        CASE WHEN v_status = 'upcoming' OR v_status IS NULL THEN
            CASE WHEN v_user_lat IS NOT NULL AND v_user_lon IS NOT NULL THEN
                fe.distance
            ELSE
                NULL
            END
        ELSE NULL
        END NULLS LAST,
        -- Sort by appropriate date based on status
        CASE
            WHEN v_status = 'upcoming' OR v_status IS NULL THEN fe.next_date
            WHEN v_status = 'past' THEN fe.latest_past_date
            ELSE fe.created_at
        END DESC
    LIMIT v_page_size
    OFFSET v_page_number * v_page_size;
END;
$$;

ALTER FUNCTION "public"."filter_events"("filters" jsonb) OWNER TO "postgres";

COMMENT ON FUNCTION "public"."filter_events"("filters" jsonb) IS 'Enhanced event filtering function that supports various filter criteria including status, location, tags, and more'; 