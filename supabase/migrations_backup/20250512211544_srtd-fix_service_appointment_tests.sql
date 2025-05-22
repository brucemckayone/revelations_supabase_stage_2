-- Generated with srtd from template: supabase/migrations-templates/fix_service_appointment_tests.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- FIX FOR SERVICE APPOINTMENT TESTS
-- This template improves the service appointment tests stability by using fixed dates instead of relative ones

-- Drop and recreate the get_provider_availability function to properly handle the available_slots_count
DROP FUNCTION IF EXISTS public.get_provider_availability;

CREATE OR REPLACE FUNCTION public.get_provider_availability(
    provider_id UUID,
    start_date DATE,
    end_date DATE
) RETURNS TABLE (
    date DATE,
    available_slots JSONB  -- Return as JSONB, not JSONB[]
) AS $$
DECLARE
    current_loop_date DATE := start_date;
    provider_timezone TEXT;
    buffer_minutes INTEGER;
BEGIN
    -- Get provider preferences
    SELECT
        COALESCE(p.timezone, 'UTC'),
        COALESCE(p.appointment_buffer_minutes, 0)
    INTO
        provider_timezone,
        buffer_minutes
    FROM
        public.provider_preferences p
    WHERE
        p.user_id = $1;

    -- Default to UTC and no buffer if no preferences found
    IF NOT FOUND THEN
        provider_timezone := 'UTC';
        buffer_minutes := 0;
    END IF;

    -- Loop through each date in the range
    WHILE current_loop_date <= $3 LOOP
        -- Assign the output column 'date' using the current loop date
        "date" := current_loop_date;

        -- Build a JSONB array of slots directly
        SELECT jsonb_agg(
            jsonb_build_object(
                'start_time', slot_time,
                'end_time', slot_time + INTERVAL '1 hour',
                'available', TRUE,
                'slot_id', md5($1::TEXT || slot_time::TEXT)
            )
            ORDER BY slot_time
        )
        INTO available_slots
        FROM (
            -- Generate potential hourly slots based on provider's availability for this day of week
            SELECT
                (current_loop_date + avail.start_time + (h * INTERVAL '1 hour'))::TIMESTAMP AS slot_time
            FROM
                public.availability avail,
                generate_series(0, 8) h
            WHERE
                avail.user_id = $1 AND
                avail.is_active = true AND
                -- Compare lowercase day names for robustness
                LOWER(avail.day) = LOWER(TRIM(TO_CHAR(current_loop_date, 'day'))) AND
                -- Check if the slot is within the provider's time range
                (avail.start_time + (h * INTERVAL '1 hour')) < avail.end_time AND
                (avail.start_time + (h * INTERVAL '1 hour') + INTERVAL '1 hour') <= avail.end_time AND
                -- Make sure this date isn't marked as unavailable in exceptions
                NOT EXISTS (
                    SELECT 1
                    FROM public.availability_exceptions ae
                    WHERE ae.user_id = $1 AND
                          ae.exception_date = current_loop_date AND
                          ae.is_available = false
                )
        ) slots;

        -- Return empty JSONB array instead of NULL for dates with no slots
        IF available_slots IS NULL THEN
            available_slots := '[]'::JSONB;
        END IF;
        
        -- Increment the loop date before RETURN NEXT
        current_loop_date := current_loop_date + INTERVAL '1 day';
        
        -- Return the calculated row
        RETURN NEXT;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
