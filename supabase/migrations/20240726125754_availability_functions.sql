CREATE OR REPLACE FUNCTION add_event_buffer(
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_buffer_minutes INT DEFAULT 15
)
RETURNS TABLE (
    buffered_start TIMESTAMP WITH TIME ZONE,
    buffered_end TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p_start_date - (p_buffer_minutes || ' minutes')::INTERVAL AS buffered_start,
        p_end_date + (p_buffer_minutes || ' minutes')::INTERVAL AS buffered_end;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION public.get_user_availability(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    availability_day VARCHAR(20),
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    debug_info TEXT
) AS $$
DECLARE
    v_current_date DATE;
    v_day_start TIMESTAMP WITH TIME ZONE;
    v_day_end TIMESTAMP WITH TIME ZONE;
    v_event_start TIMESTAMP WITH TIME ZONE;
    v_event_end TIMESTAMP WITH TIME ZONE;
    v_event_info TEXT;
BEGIN
    CREATE TEMPORARY TABLE temp_availability (
        availability_day VARCHAR(20),
        start_time TIMESTAMP WITH TIME ZONE,
        end_time TIMESTAMP WITH TIME ZONE,
        debug_info TEXT
    ) ON COMMIT DROP;

    -- Fetch all relevant event dates for the user
    CREATE TEMPORARY TABLE user_events AS
    SELECT 
        e.start_date,
        e.end_date,
        e.id AS event_id
    FROM public.event_dates e
    JOIN public.events ev ON e.event_id = ev.id
    JOIN public.posts p ON ev.post_id = p.id
    WHERE p.user_id = p_user_id
      AND e.start_date <= p_end_date::timestamp
      AND e.end_date >= p_start_date::timestamp;

    FOR v_current_date IN SELECT generate_series(p_start_date, p_end_date, '1 day'::interval)::date LOOP
        -- Get the user's availability for the current day
        SELECT 
            v_current_date + a.start_time,
            v_current_date + a.end_time
        INTO v_day_start, v_day_end
        FROM public.availability a
        WHERE a.user_id = p_user_id
          AND a.day = LOWER(TRIM(to_char(v_current_date, 'day')))
          AND a.is_active = true;

        IF v_day_start IS NOT NULL THEN
            -- Check for events on this day
            FOR v_event_start, v_event_end, v_event_info IN
                SELECT 
                    GREATEST(ue.start_date, v_day_start) - INTERVAL '15 minutes',
                    LEAST(ue.end_date, v_day_end) + INTERVAL '15 minutes',
                    format('Event ID: %s, Original Start: %s, Original End: %s', 
                           ue.event_id, ue.start_date, ue.end_date)
                FROM user_events ue
                WHERE v_current_date BETWEEN ue.start_date::date AND ue.end_date::date
                ORDER BY ue.start_date
            LOOP
                -- If event covers the whole day or more
                IF v_event_start <= v_day_start AND v_event_end >= v_day_end THEN
                
                    INSERT INTO temp_availability (availability_day, start_time, end_time, debug_info)
                    VALUES (
                        LOWER(TRIM(to_char(v_current_date, 'day'))),
                        NULL,
                        NULL,
                        format('Date: %s, Day: %s, Fully booked: %s', 
                               v_current_date, LOWER(TRIM(to_char(v_current_date, 'day'))), v_event_info)
                    );
                    v_day_start = NULL; -- Mark the day as fully booked
                    EXIT; -- No need to check other events for this day
                ELSE
                    -- Insert availability before the event if exists
                    IF v_day_start < v_event_start THEN
                        INSERT INTO temp_availability (availability_day, start_time, end_time, debug_info)
                        VALUES (
                            LOWER(TRIM(to_char(v_current_date, 'day'))),
                            v_day_start,
                            v_event_start,
                            format('Date: %s, Day: %s, Available slot before event: %s', 
                                   v_current_date, LOWER(TRIM(to_char(v_current_date, 'day'))), v_event_info)
                        );
                    END IF;
                    -- Update day_start for the next iteration
                    v_day_start = GREATEST(v_day_start, v_event_end);
                END IF;
            END LOOP;

            -- Insert remaining availability after all events if any
            IF v_day_start IS NOT NULL AND v_day_start < v_day_end THEN
                INSERT INTO temp_availability (availability_day, start_time, end_time, debug_info)
                VALUES (
                    LOWER(TRIM(to_char(v_current_date, 'day'))),
                    v_day_start,
                    v_day_end,
                    format('Date: %s, Day: %s, Available slot after events', 
                           v_current_date, LOWER(TRIM(to_char(v_current_date, 'day'))))
                );
            END IF;

            -- If no events affected this day, insert the full availability
            IF NOT EXISTS (SELECT 1 FROM temp_availability ta WHERE ta.start_time::date = v_current_date) THEN
                INSERT INTO temp_availability (availability_day, start_time, end_time, debug_info)
                VALUES (
                    LOWER(TRIM(to_char(v_current_date, 'day'))),
                    v_day_start,
                    v_day_end,
                    format('Date: %s, Day: %s, Regular availability', v_current_date, LOWER(TRIM(to_char(v_current_date, 'day'))))
                );
            END IF;
        ELSE
            -- If no availability set for this day
            INSERT INTO temp_availability(availability_day, start_time, end_time, debug_info)
            VALUES (
                LOWER(TRIM(to_char(v_current_date, 'day'))),
                NULL,
                NULL,
                format('Date: %s, Day: %s, No availability set', v_current_date, LOWER(TRIM(to_char(v_current_date, 'day'))))
            );
        END IF;
    END LOOP;

    RETURN QUERY SELECT * FROM temp_availability ORDER BY start_time NULLS LAST;
END;
$$ LANGUAGE plpgsql;

