-- Generated with srtd from template: supabase/migrations-templates/filter-service-appointments.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;



drop  function if exists filter_service_appointments;


CREATE OR REPLACE FUNCTION filter_service_appointments(
    filters JSONB
)

RETURNS TABLE (
    appointment_id UUID,
    service_id UUID,
    post_id UUID,
    service_title TEXT,
    appointment_date TIMESTAMPTZ,
    duration INTERVAL,
    method TEXT,
    service_type TEXT,
    status TEXT,
    client_id UUID,
    client_name TEXT,
    client_avatar TEXT,
    price NUMERIC,
    is_future BOOLEAN,
    total_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_provider_id UUID;
    v_time_filter TEXT;
    v_status_filter TEXT[];
    v_limit INTEGER;
    v_offset INTEGER;
BEGIN
    -- Set defaults and extract filter values
    v_provider_id := COALESCE(filters->>'providerId', auth.uid()::TEXT)::UUID;
    v_time_filter := COALESCE(filters->>'timeFilter', 'all');
    v_status_filter := CASE
        WHEN filters->>'status' IS NULL THEN ARRAY['confirmed', 'pending', 'cancelled', 'completed']::TEXT[]
        WHEN filters->>'status' = 'all' THEN ARRAY['confirmed', 'pending', 'cancelled', 'completed']::TEXT[]
        ELSE ARRAY[filters->>'status']::TEXT[]
    END;
    v_limit := COALESCE((filters->>'limit')::INTEGER, 10);
    v_offset := COALESCE((filters->>'offset')::INTEGER, 0);
    
    RETURN QUERY
    WITH filtered_appointments AS (
        SELECT 
            sav.appointment_id,
            sav.service_id,
            sv.post_id,
            sv.title AS service_title,
            sav.appointment_date,
            (sav.duration || ' minutes')::INTERVAL AS duration,
            sav.method,
            sav.service_type,
            sav.status,
            sav.client_id,
            sav.client->>'full_name' AS client_name,
            sav.client->>'avatar_url' AS client_avatar,
            sav.price_paid AS price,
            sav.is_future,
            COUNT(*) OVER() AS total_count
        FROM 
            public.service_appointments_view sav
        JOIN 
            public.service_details_view sv ON sav.service_id = sv.service_id
        WHERE 
            sav.provider_id = v_provider_id
            AND (
                (v_time_filter = 'upcoming' AND sav.is_future = TRUE) OR
                (v_time_filter = 'past' AND sav.is_future = FALSE) OR
                (v_time_filter = 'all')
            )
            AND sav.status = ANY(v_status_filter)
    )
    SELECT * FROM filtered_appointments fa
    ORDER BY 
        CASE WHEN v_time_filter = 'past' THEN fa.appointment_date END DESC,
        CASE WHEN v_time_filter IN ('all', 'upcoming') THEN fa.appointment_date END ASC
    LIMIT v_limit
    OFFSET v_offset;
END;
$$; 


COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
