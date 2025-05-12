-- Fix for the time slot boundary issue in the get_provider_availability function
-- The issue: The 23:30-00:00 slot is incorrectly handled because the end time crosses midnight

CREATE OR REPLACE FUNCTION get_provider_availability(
    p_provider_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    date DATE,
    available_slots JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_timezone TEXT;
    v_buffer INTEGER;
    v_today DATE := CURRENT_DATE;
    v_now TIME := CURRENT_TIME;
BEGIN
    -- Get provider preferences
    SELECT timezone, appointment_buffer_minutes INTO v_timezone, v_buffer
    FROM provider_preferences
    WHERE user_id = p_provider_id;

    -- Default values if not set
    v_timezone := COALESCE(v_timezone, 'UTC');
    v_buffer := COALESCE(v_buffer, 0);

    RETURN QUERY
    WITH date_series AS (
        SELECT generate_series(p_start_date, p_end_date, '1 day'::interval)::date AS day_date
    ),
    day_availability AS (
        SELECT
            ds.day_date,
            TRIM(LOWER(TO_CHAR(ds.day_date, 'day'))) AS day_name,
            av.start_time,
            av.end_time,
            av.is_active
        FROM
            date_series ds
        LEFT JOIN
            public.availability av ON
                av.day = TRIM(LOWER(TO_CHAR(ds.day_date, 'day'))) AND
                av.user_id = p_provider_id
    ),
    exceptions AS (
        SELECT
            ex.exception_date,
            ex.is_available,
            ex.start_time,
            ex.end_time
        FROM
            public.availability_exceptions ex
        WHERE
            ex.user_id = p_provider_id AND
            ex.exception_date BETWEEN p_start_date AND p_end_date
    ),
    appointments AS (
        SELECT
            (ap.appointment_date AT TIME ZONE v_timezone)::date AS appt_date,
            ap.appointment_date AT TIME ZONE v_timezone AS start_time,
            (ap.appointment_date + (ap.duration || ' minutes')::interval) AT TIME ZONE v_timezone AS end_time
        FROM
            public.appointment_purchases ap
        JOIN
            public.purchases p ON ap.purchase_id = p.id
        WHERE
            p.owner_id = p_provider_id AND
            ap.status IN ('confirmed', 'pending_approval', 'pending_payment') AND
            (ap.appointment_date AT TIME ZONE v_timezone)::date BETWEEN p_start_date AND p_end_date

        UNION ALL

        SELECT
            (a.start_time AT TIME ZONE v_timezone)::date AS appt_date,
            a.start_time AT TIME ZONE v_timezone AS start_time,
            a.end_time AT TIME ZONE v_timezone AS end_time
        FROM
            public.appointments a
        WHERE
            a.facilitator_id = p_provider_id AND
            a.status IN ('confirmed', 'pending') AND
            (a.start_time AT TIME ZONE v_timezone)::date BETWEEN p_start_date AND p_end_date
    ),
    events AS (
        SELECT
            (ed.start_date AT TIME ZONE v_timezone)::date AS event_date,
            ed.start_date AT TIME ZONE v_timezone AS start_time,
            ed.end_date AT TIME ZONE v_timezone AS end_time
        FROM
            public.event_dates ed
        JOIN
            public.event_bookings eb ON ed.id = eb.date_id
        JOIN
            public.purchases p ON eb.purchase_id = p.id
        WHERE
            p.owner_id = p_provider_id AND
            eb.status IN ('confirmed', 'pending') AND
            (ed.start_date AT TIME ZONE v_timezone)::date BETWEEN p_start_date AND p_end_date
    ),
    -- Generate time slots using an integer series instead of time series
    time_slots AS (
        SELECT 
            (('00:00:00'::time + (n * interval '30 minutes'))::time) AS slot_time
        FROM 
            generate_series(0, 47) AS n -- 48 half-hour slots in a day
    ),
    available_slots AS (
        SELECT
            da.day_date,
            ts.slot_time AS slot_start_time,
            (ts.slot_time + '30 minutes'::interval) AS slot_end_time,
            -- Check if slot is within available hours
            CASE
                -- Handle date exceptions
                WHEN ex.exception_date IS NOT NULL AND NOT ex.is_available THEN false
                WHEN ex.exception_date IS NOT NULL AND ex.is_available AND
                     ts.slot_time >= ex.start_time AND
                     (
                        -- Special handling for end time crossing midnight
                        (ex.end_time > ex.start_time AND (ts.slot_time + '30 minutes'::interval) <= ex.end_time) OR
                        (ex.end_time < ex.start_time AND (ts.slot_time + '30 minutes'::interval) >= '00:00:00'::time)
                     ) THEN true
                -- Handle regular availability with special case for midnight crossing
                WHEN ex.exception_date IS NULL AND
                     da.is_active AND
                     ts.slot_time >= da.start_time AND
                     (
                        -- Handle normal case (start_time < end_time)
                        (da.end_time > da.start_time AND (ts.slot_time + '30 minutes'::interval) <= da.end_time) OR 
                        -- Handle case where end_time < start_time (crossing midnight)
                        (da.end_time < da.start_time AND 
                         (ts.slot_time < da.end_time OR ts.slot_time >= da.start_time))
                     ) THEN true
                ELSE false
            END AS is_within_availability,
            -- Check if slot overlaps with existing commitments
            EXISTS (
                SELECT 1 FROM appointments a
                WHERE a.appt_date = da.day_date AND
                (a.start_time, a.end_time) OVERLAPS
                (da.day_date + ts.slot_time, da.day_date + ts.slot_time + '30 minutes'::interval)
            ) AS has_appointment_conflict,
            EXISTS (
                SELECT 1 FROM events e
                WHERE e.event_date = da.day_date AND
                (e.start_time, e.end_time) OVERLAPS
                (da.day_date + ts.slot_time, da.day_date + ts.slot_time + '30 minutes'::interval)
            ) AS has_event_conflict,
            -- Handle past times
            (da.day_date < v_today OR
             (da.day_date = v_today AND ts.slot_time <= v_now)) AS is_past
        FROM
            day_availability da
        CROSS JOIN
            time_slots ts
        LEFT JOIN
            exceptions ex ON ex.exception_date = da.day_date
    )
    SELECT
        as_grp.day_date AS date,
        jsonb_agg(
            jsonb_build_object(
                'start_time', (as_grp.day_date + as_grp.slot_start_time)::timestamp,
                'end_time', (as_grp.day_date + as_grp.slot_end_time)::timestamp,
                'available', (
                    as_grp.is_within_availability AND
                    NOT as_grp.has_appointment_conflict AND
                    NOT as_grp.has_event_conflict AND
                    NOT as_grp.is_past
                )
            )
            ORDER BY as_grp.slot_start_time
        ) AS available_slots
    FROM
        available_slots as_grp
    GROUP BY
        as_grp.day_date
    ORDER BY
        as_grp.day_date;
END;
$$;

COMMENT ON FUNCTION get_provider_availability IS 'Returns detailed availability slots for a provider with special handling for time slots crossing midnight'; 