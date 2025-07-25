-- Generated with srtd from template: supabase/migrations-templates/get-calandar-availabilty.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;


CREATE OR REPLACE FUNCTION "public"."get_service_calendar_availability"(
    "p_service_id" "uuid",
    "p_days_ahead" integer DEFAULT 30,
    "p_timezone" "text" DEFAULT NULL::"text"
) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_start_date DATE := CURRENT_DATE;
    v_end_date DATE := CURRENT_DATE + (p_days_ahead || ' days')::INTERVAL;
    v_service_owner_id UUID;
    v_timezone TEXT;
    v_result JSONB;
    v_service_duration INTERVAL;
    v_service_duration_minutes INTEGER;
BEGIN
    -- Get service provider and duration
    SELECT p.user_id, COALESCE(p_timezone, pp.timezone, 'UTC'), s.duration
    INTO v_service_owner_id, v_timezone, v_service_duration
    FROM public.services s
    JOIN public.posts p ON s.post_id = p.id
    LEFT JOIN public.provider_preferences pp ON p.user_id = pp.user_id
    WHERE s.id = p_service_id;
    
    IF v_service_owner_id IS NULL THEN
        RETURN jsonb_build_object('error', 'Service not found');
    END IF;

    -- Convert interval duration to minutes
    v_service_duration_minutes := EXTRACT(EPOCH FROM v_service_duration) / 60;
    -- Guard: duration must be at least 1 minute
    IF v_service_duration_minutes < 1 THEN
        RAISE EXCEPTION 'Service duration must be at least 1 minute. Got: %', v_service_duration;
    END IF;
    
    -- Get availability data
    WITH availability_data AS (
        SELECT 
            date,
            available_slots
        FROM 
            get_provider_availability(v_service_owner_id, v_start_date, v_end_date, v_service_duration_minutes)
    ),
    calendar_days AS (
        SELECT 
            date,
            -- For each date, get the count of available slots
            (
                SELECT COUNT(*)
                FROM jsonb_array_elements(available_slots) AS slot
                WHERE (slot->>'available')::BOOLEAN = true
            ) AS available_slot_count,
            -- Get the first and last available times
            (
                SELECT MIN(
                    (elem->>'start_time')::TIMESTAMP WITH TIME ZONE AT TIME ZONE v_timezone
                )
                FROM jsonb_array_elements(available_slots) AS elem
                WHERE (elem->>'available')::BOOLEAN = true
            ) AS first_available,
            (
                SELECT MAX(
                    (elem->>'end_time')::TIMESTAMP WITH TIME ZONE AT TIME ZONE v_timezone
                )
                FROM jsonb_array_elements(available_slots) AS elem
                WHERE (elem->>'available')::BOOLEAN = true
            ) AS last_available,
            -- Format for a calendar view (day cells)
            CASE 
                WHEN (
                    SELECT COUNT(*)
                    FROM jsonb_array_elements(available_slots) AS slot
                    WHERE (slot->>'available')::BOOLEAN = true
                ) > 0 THEN 'available'
                WHEN (
                    SELECT COUNT(*)
                    FROM jsonb_array_elements(available_slots) AS slot
                ) = 0 THEN 'unavailable'
                ELSE 'booked'
            END AS day_status
        FROM 
            availability_data
    )
    SELECT 
        jsonb_build_object(
            'service_id', p_service_id,
            'timezone', v_timezone,
            'days', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'date', date,
                        'day_status', day_status,
                        'available_slots', available_slot_count,
                        'first_available', first_available,
                        'last_available', last_available
                    )
                    ORDER BY date
                )
                FROM calendar_days
            ),
            'hours', (
                SELECT jsonb_build_object(
                    'earliest', MIN(first_available::time),
                    'latest', MAX(last_available::time)
                )
                FROM calendar_days
                WHERE first_available IS NOT NULL
            )
        ) INTO v_result;
    
    RETURN v_result;
END;
$$;


COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
