drop function if exists public.get_provider_availability;
CREATE OR REPLACE FUNCTION public.get_provider_availability(
    p_provider_id UUID,
    p_start_date DATE,
    p_end_date DATE,
    p_slot_length_minutes INTEGER
) RETURNS TABLE (
    date DATE,
    available_slots JSONB
) AS $$
DECLARE
    v_timezone TEXT;
    v_buffer INTEGER;
    v_notice INTEGER;
    v_window_days INTEGER;
    v_now TIMESTAMP WITH TIME ZONE := NOW();
    v_booking_window_end DATE;
    current_loop_date DATE := p_start_date;
BEGIN
    -- Get provider preferences
    SELECT
        COALESCE(pp.timezone, 'UTC'),
        COALESCE(pp.appointment_buffer_minutes, 0),
        COALESCE(pp.advance_notice_hours, 24),
        COALESCE(pp.booking_window_days, 30)
    INTO
        v_timezone,
        v_buffer,
        v_notice,
        v_window_days
    FROM
        public.provider_preferences pp
    WHERE
        pp.user_id = p_provider_id;

    -- Default to UTC and no buffer if no preferences found
    IF NOT FOUND THEN
        v_timezone := 'UTC';
        v_buffer := 0;
        v_notice := 24;
        v_window_days := 30;
    END IF;

    -- Calculate booking window end date in provider timezone
    v_booking_window_end := DATE((v_now + (v_window_days || ' days')::interval) AT TIME ZONE v_timezone);
    -- Ensure we do not loop past provider booking window or requested end date
    IF p_end_date > v_booking_window_end THEN
        p_end_date := v_booking_window_end;
    END IF;

    -- Loop through each date in the range
    WHILE current_loop_date <= p_end_date LOOP
        -- Assign the output column 'date' using the current loop date
        date := current_loop_date;
        
        -- Generate and check slots with conflicts
        WITH 
        -- Get appointment conflicts for this provider
        appointment_conflicts AS (
            SELECT
                ap.appointment_date AS start_time,
                (ap.appointment_date + (ap.duration || ' hours')::INTERVAL) AS end_time
            FROM
                public.appointment_purchases ap
            JOIN
                public.purchases p ON ap.purchase_id = p.id
            WHERE
                p.owner_id = p_provider_id AND
                ap.status IN ('confirmed', 'pending_approval', 'pending_payment', 'pending_auto_payment', 'pending_reschedule') AND
                DATE(ap.appointment_date AT TIME ZONE v_timezone) = current_loop_date
        ),
        -- Get event conflicts for this provider
        event_conflicts AS (
            SELECT ed.start_date AS start_time,
                   ed.end_date   AS end_time
            FROM   public.event_dates ed
            JOIN   public.events      e ON e.id = ed.event_id
            JOIN   public.posts       p ON p.id = e.post_id
            WHERE  p.user_id = p_provider_id
              -- Only consider events that actually begin on this date (provider timezone)
              AND  DATE(ed.start_date AT TIME ZONE v_timezone) = current_loop_date
        ),
        -- Generate base time slots from availability schedule
        base_slots AS (
            SELECT
              ((current_loop_date + avail.start_time) + h * make_interval(mins => p_slot_length_minutes)) AT TIME ZONE v_timezone AS slot_time,
              ((current_loop_date + avail.start_time) + (h + 1) * make_interval(mins => p_slot_length_minutes)) AT TIME ZONE v_timezone AS slot_end_time
            FROM public.availability avail
            CROSS JOIN LATERAL generate_series(
                0,
                GREATEST(floor(extract(epoch from (avail.end_time-avail.start_time)) / (60 * p_slot_length_minutes))::int - 1, 0)
            ) AS h
            WHERE avail.user_id = p_provider_id
              AND avail.is_active = true
              AND lower(avail.day) = lower(trim(to_char(current_loop_date,'day')))
              AND NOT EXISTS (
                    SELECT 1
                    FROM public.availability_exceptions ae
                    WHERE ae.user_id = p_provider_id
                      AND ae.exception_date = current_loop_date
                      AND ae.is_available = false)
        ),
        -- Check each slot for conflicts
        checked_slots AS (
            SELECT
                bs.slot_time,
                bs.slot_end_time,
                -- Check if the slot is past the advance-notice cutoff
                ((bs.slot_time AT TIME ZONE v_timezone) < ((v_now + (v_notice || ' hours')::interval) AT TIME ZONE v_timezone)) AS is_past,
                -- Check for appointment conflicts
                EXISTS (
                    SELECT 1 FROM appointment_conflicts ac
                    WHERE 
                        -- Add buffer time to appointment times for overlap check
                        (
                            bs.slot_time < (ac.end_time + (v_buffer || ' minutes')::INTERVAL) AND
                            bs.slot_end_time > (ac.start_time - (v_buffer || ' minutes')::INTERVAL)
                        )
                ) AS has_appointment_conflict,
                -- Check for event conflicts
                EXISTS (
                    SELECT 1 FROM event_conflicts ec
                    WHERE 
                        (bs.slot_time <= ec.end_time AND bs.slot_end_time >= ec.start_time)
                ) AS has_event_conflict
            FROM base_slots bs
        )
        
        -- Build the final JSONB array of available slots
        SELECT jsonb_agg(
            jsonb_build_object(
                'start_time', cs.slot_time,
                'end_time', cs.slot_end_time,
                'available', NOT (cs.is_past OR cs.has_appointment_conflict OR cs.has_event_conflict),
                'slot_id', md5(p_provider_id::TEXT || cs.slot_time::TEXT)
            )
            ORDER BY cs.slot_time
        )
        INTO available_slots
        FROM checked_slots cs;

        -- Return empty JSONB array instead of NULL for dates with no slots
        IF available_slots IS NULL THEN
            available_slots := '[]'::JSONB;
        END IF;
        
        -- Return the current date's data before moving to the next date
        RETURN NEXT;
        
        -- Move to the next date
        current_loop_date := current_loop_date + INTERVAL '1 day';
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


