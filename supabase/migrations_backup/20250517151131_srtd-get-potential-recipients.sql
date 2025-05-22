-- Generated with srtd from template: supabase/migrations-templates/get-potential-recipients.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

drop type if exists get_potential_recipients_params;
CREATE TYPE get_potential_recipients_params AS (
    "type" TEXT,
    postId UUID,
    serviceId UUID,
    eventId UUID,
    appointmentId UUID,
    bookingId UUID,
    eventDate TIMESTAMPTZ,
    "limit" INTEGER
);

drop function if exists get_potential_recipients;
CREATE OR REPLACE FUNCTION get_potential_recipients(
    p_params JSONB
)
RETURNS TABLE (
    recipient_id UUID,
    name TEXT,
    email TEXT,
    group_type TEXT,
    avatar_url TEXT,
    appointment_id UUID,
    booking_id UUID,
    appointment_date TIMESTAMPTZ,
    post_title TEXT,
    tickets_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_type TEXT;
    v_post_id UUID;
    v_service_id UUID;
    v_event_id UUID;
    v_appointment_id UUID;
    v_booking_id UUID;
    v_event_date TIMESTAMPTZ;
    v_limit INTEGER;
    params JSONB;
BEGIN
    -- Check if we have a nested params object and use the appropriate structure
    IF p_params ? 'params' THEN
        params := p_params->'params';
    ELSE
        params := p_params;
    END IF;

    -- Extract parameters - handle both camelCase and lowercase parameter names
    v_type := params->>'type';
    
    -- Convert string UUIDs to UUID type, handling possible null/invalid values
    BEGIN
        -- Try postId (camelCase) first, then postid (lowercase)
        v_post_id := (params->>'postId')::UUID;
        IF v_post_id IS NULL THEN
            v_post_id := (params->>'postid')::UUID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_post_id := NULL;
    END;
    
    BEGIN
        v_service_id := (params->>'serviceId')::UUID;
        IF v_service_id IS NULL THEN
            v_service_id := (params->>'serviceid')::UUID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_service_id := NULL;
    END;
    
    BEGIN
        v_event_id := (params->>'eventId')::UUID;
        IF v_event_id IS NULL THEN
            v_event_id := (params->>'eventid')::UUID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_event_id := NULL;
    END;
    
    BEGIN
        v_appointment_id := (params->>'appointmentId')::UUID;
        IF v_appointment_id IS NULL THEN
            v_appointment_id := (params->>'appointmentid')::UUID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_appointment_id := NULL;
    END;
    
    BEGIN
        v_booking_id := (params->>'bookingId')::UUID;
        IF v_booking_id IS NULL THEN
            v_booking_id := (params->>'bookingid')::UUID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_booking_id := NULL;
    END;
    
    BEGIN
        v_event_date := (params->>'eventDate')::TIMESTAMPTZ;
        IF v_event_date IS NULL THEN
            v_event_date := (params->>'eventdate')::TIMESTAMPTZ;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_event_date := NULL;
    END;
    
    v_limit := COALESCE((params->>'limit')::INTEGER, 100);
    
    -- Validate required parameters
    IF v_type IS NULL THEN
        RAISE EXCEPTION 'Type parameter is required';
    END IF;
    
    -- Handle different recipient types
    CASE v_type
        -- Service appointments recipients
        WHEN 'service' THEN
            IF v_service_id IS NULL AND v_appointment_id IS NULL THEN
                RAISE EXCEPTION 'Either Service ID or Appointment ID is required for service recipients';
            END IF;
            
            RETURN QUERY
            WITH service_appointments AS (
                SELECT 
                    sav.client_id,
                    sav.client->>'full_name' AS client_name,
                    sav.client->>'avatar_url' AS client_avatar,
                    sav.appointment_id,
                    sav.appointment_date,
                    sav.service_id,
                    sv.title AS service_title
                FROM 
                    public.service_appointments_view sav
                JOIN
                    public.service_details_view sv ON sav.service_id = sv.service_id
                WHERE 
                    (v_service_id IS NULL OR sav.service_id = v_service_id)
                    AND (v_appointment_id IS NULL OR sav.appointment_id = v_appointment_id)
            )
            SELECT
                sa.client_id AS recipient_id,
                sa.client_name AS name,
                au.email::TEXT,
                'Service Client'::TEXT AS group_type,
                sa.client_avatar AS avatar_url,
                sa.appointment_id,
                NULL::UUID AS booking_id,
                sa.appointment_date,
                sa.service_title AS post_title,
                1 AS tickets_count -- Services typically have 1 appointment per client
            FROM
                service_appointments sa
            LEFT JOIN
                auth.users au ON sa.client_id = au.id
            LIMIT v_limit;
        
        -- Event attendees recipients
        WHEN 'event' THEN
            -- First, determine which date_ids we're looking for based on event_id and/or eventDate
            RETURN QUERY
            WITH relevant_dates AS (
                -- Find date_ids that match our criteria
                SELECT 
                    ed.id AS date_id,
                    ed.event_id,
                    ed.start_date,
                    edv.title AS event_title
                FROM 
                    public.event_dates ed
                JOIN 
                    public.event_details_view edv ON ed.event_id = edv.event_id
                WHERE 
                    -- If event_id is provided, filter by it
                    (v_event_id IS NULL OR ed.event_id = v_event_id)
                    -- If eventDate is provided, filter by date (ignoring time)
                    AND (v_event_date IS NULL OR DATE(ed.start_date) = DATE(v_event_date))
            ),
            -- Get attendees who booked these specific dates
            attendees AS (
                SELECT
                    p.user_id,
                    pr.full_name,
                    pr.avatar_url,
                    eb.id AS booking_id,
                    rd.date_id,
                    rd.event_id,
                    rd.start_date,
                    rd.event_title,
                    eb.attendees AS tickets_count
                FROM
                    relevant_dates rd
                JOIN
                    public.event_bookings eb ON rd.date_id = eb.date_id
                JOIN
                    public.purchases p ON eb.purchase_id = p.id
                LEFT JOIN
                    public.profiles pr ON p.user_id = pr.id
                WHERE
                    -- If booking_id is provided, filter by it
                    (v_booking_id IS NULL OR eb.id = v_booking_id)
                    AND eb.status != 'cancelled'
            )
            -- Select distinct attendees with their most recent booking
            SELECT DISTINCT ON (a.user_id)
                a.user_id AS recipient_id,
                a.full_name AS name,
                au.email::TEXT,
                'Event Attendee'::TEXT AS group_type,
                a.avatar_url,
                NULL::UUID AS appointment_id,
                a.booking_id,
                a.start_date AS appointment_date,
                a.event_title AS post_title,
                a.tickets_count
            FROM
                attendees a
            LEFT JOIN
                auth.users au ON a.user_id = au.id
            ORDER BY 
                a.user_id, a.start_date DESC
            LIMIT v_limit;
        
        -- Waitlist recipients
        WHEN 'waitlist' THEN
            IF v_post_id IS NULL THEN
                RAISE EXCEPTION 'Post ID is required for waitlist recipients';
            END IF;
            
            RETURN QUERY
            SELECT
                we.user_id AS recipient_id,
                pr.full_name AS name,
                au.email::TEXT,
                'Waitlist'::TEXT AS group_type,
                pr.avatar_url,
                NULL::UUID AS appointment_id,
                NULL::UUID AS booking_id,
                NULL::TIMESTAMPTZ AS appointment_date,
                p.title AS post_title,
                1 AS tickets_count -- Waitlist entries typically count as 1
            FROM
                public.waitlist_entries we
            LEFT JOIN
                public.profiles pr ON we.user_id = pr.id
            LEFT JOIN
                auth.users au ON we.user_id = au.id
            LEFT JOIN
                public.posts p ON we.post_id = p.id
            WHERE
                we.post_id = v_post_id
            LIMIT v_limit;
        
        -- All users (announcements/broadcasts)
        WHEN 'announcement', 'broadcast' THEN
            RETURN QUERY
            SELECT
                pr.id AS recipient_id,
                pr.full_name AS name,
                au.email::TEXT,
                'All Users'::TEXT AS group_type,
                pr.avatar_url,
                NULL::UUID AS appointment_id,
                NULL::UUID AS booking_id,
                NULL::TIMESTAMPTZ AS appointment_date,
                NULL::TEXT AS post_title,
                1 AS tickets_count -- Each user counts as 1 for announcements
            FROM
                public.profiles pr
            LEFT JOIN
                auth.users au ON pr.id = au.id
            LIMIT v_limit;
        
        -- Default case
        ELSE
            RAISE EXCEPTION 'Unknown recipient type: %', v_type;
    END CASE;
END;
$$; 




COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
