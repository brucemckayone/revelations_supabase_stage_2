-- ENHANCED SERVICE VIEWS FOR FRONTEND INTEGRATION
-- Creates views specifically designed to work with the provided TypeScript interfaces

-- First, let's make sure we have the right structure for the service_details_view
-- This view closely matches the ServiceDetails interface
DROP VIEW IF EXISTS public.service_details_view CASCADE;
CREATE OR REPLACE VIEW public.service_details_view AS
SELECT 
    -- Service base info
    s.id AS service_id,
    p.id AS post_id,
    p.slug,
    p.title,
    p.description,
    s.content,
    p.thumbnail_url,
    s.type AS service_type,
    s.price,
    s.duration::text, -- Convert interval to string for frontend
    p.featured,
    p.created_at,
    p.updated_at,
    p.user_id AS creator_id,
    
    -- Location info (for in-person services)
    CASE 
        WHEN s.type = 'online' THEN 
            jsonb_build_object('name', 'Online Service')
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
    
    -- Creator profile
    jsonb_build_object(
        'id', pr.id,
        'full_name', pr.full_name,
        'avatar_url', pr.avatar_url
    ) AS creator,
    
    -- Tags as an array
    COALESCE(
        array_agg(t.name) FILTER (WHERE t.id IS NOT NULL),
        '{}'::text[]
    ) AS tags
FROM 
    public.services s
JOIN 
    public.posts p ON s.post_id = p.id
LEFT JOIN 
    public.locations l ON s.location_id = l.id
LEFT JOIN 
    public.profiles pr ON p.user_id = pr.id
LEFT JOIN 
    public.post_tags pt ON p.id = pt.post_id
LEFT JOIN 
    public.tags t ON pt.tag_id = t.id
WHERE 
    p.post_type = 'service'
GROUP BY
    s.id,
    p.id,
    p.slug,
    p.title,
    p.description,
    s.content,
    p.thumbnail_url,
    s.type,
    s.price,
    s.duration,
    p.featured,
    p.created_at,
    p.updated_at,
    p.user_id,
    l.id,
    l.name,
    l.description,
    l.image_url,
    l.line_1,
    l.line_2,
    l.city,
    l.country,
    l.postcode,
    l.maps_link,
    l.coordinates,
    pr.id,
    pr.full_name,
    pr.avatar_url;

-- Service appointments view that matches the ServiceAppointment interface
DROP VIEW IF EXISTS public.service_appointments_view CASCADE;
CREATE OR REPLACE VIEW public.service_appointments_view AS
SELECT 
    ap.id AS appointment_id,
    ap.purchase_id,
    ap.service_id,
    ap.appointment_date,
    ap.duration,
    ap.method,
    ap.service_type,
    ap.status,
    ap.notes,
    ap.meeting_url,
    ap.meeting_id,
    p.user_id AS client_id,
    p.owner_id AS provider_id,
    p.payment_status,
    p.amount AS price_paid,
    -- Client details
    jsonb_build_object(
        'id', cl.id,
        'full_name', cl.full_name,
        'avatar_url', cl.avatar_url
    ) AS client,
    -- Check if the appointment is in the future
    (ap.appointment_date > CURRENT_TIMESTAMP) AS is_future,
    -- Check if the appointment is confirmed
    (ap.status = 'confirmed') AS is_confirmed,
    -- Check if the appointment is completed
    (ap.status = 'completed') AS is_completed,
    -- Check if the appointment is cancelled
    (ap.status = 'cancelled') AS is_cancelled
FROM 
    public.appointment_purchases ap
JOIN 
    public.purchases p ON ap.purchase_id = p.id
LEFT JOIN 
    public.profiles cl ON p.user_id = cl.id;

-- User appointments view that matches the UserAppointment interface
DROP VIEW IF EXISTS public.user_appointments_view CASCADE;
CREATE OR REPLACE VIEW public.user_appointments_view AS
SELECT 
    ap.id AS appointment_id,
    ap.purchase_id,
    ap.service_id,
    p.title AS service_title,
    pr.full_name AS provider_name,
    pr.avatar_url AS provider_avatar,
    ap.appointment_date,
    ap.duration,
    ap.method,
    ap.service_type,
    ap.status,
    pur.payment_status,
    pur.amount,
    (ap.appointment_date > CURRENT_TIMESTAMP) AS is_future,
    pur.user_id  -- Added for filtering
FROM 
    public.appointment_purchases ap
JOIN 
    public.purchases pur ON ap.purchase_id = pur.id
JOIN 
    public.services s ON ap.service_id = s.id
JOIN 
    public.posts p ON s.post_id = p.id
JOIN 
    public.profiles pr ON pur.owner_id = pr.id;

-- Comprehensive service view with the appointments added as JSON arrays
DROP VIEW IF EXISTS public.comprehensive_services_view CASCADE;
CREATE OR REPLACE VIEW public.comprehensive_services_view AS
SELECT 
    sv.*,
    -- Add appointments as a JSONB array (only show confirmed and pending ones)
    COALESCE(
        (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'id', sav.appointment_id,
                    'appointment_date', sav.appointment_date,
                    'duration', sav.duration,
                    'method', sav.method,
                    'service_type', sav.service_type,
                    'status', sav.status,
                    'client', sav.client,
                    'is_future', sav.is_future
                ) 
                ORDER BY sav.appointment_date
            )
            FROM public.service_appointments_view sav
            WHERE sav.service_id = sv.service_id
            AND sav.status IN ('confirmed', 'pending')
            AND sav.provider_id = auth.uid()
        ),
        '[]'::jsonb
    ) AS appointments,
    
    -- Add future appointments as a filtered JSONB array
    COALESCE(
        (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'id', sav.appointment_id,
                    'appointment_date', sav.appointment_date,
                    'duration', sav.duration,
                    'method', sav.method,
                    'service_type', sav.service_type,
                    'status', sav.status
                ) 
                ORDER BY sav.appointment_date
            )
            FROM public.service_appointments_view sav
            WHERE sav.service_id = sv.service_id
            AND sav.is_future = TRUE
            AND sav.status IN ('confirmed', 'pending')
            AND sav.provider_id = auth.uid()
        ),
        '[]'::jsonb
    ) AS future_appointments,
    
    -- Add past appointments as a filtered JSONB array
    COALESCE(
        (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'id', sav.appointment_id,
                    'appointment_date', sav.appointment_date,
                    'duration', sav.duration,
                    'method', sav.method,
                    'service_type', sav.service_type,
                    'status', sav.status,
                    'client', sav.client
                ) 
                ORDER BY sav.appointment_date DESC
            )
            FROM public.service_appointments_view sav
            WHERE sav.service_id = sv.service_id
            AND sav.is_future = FALSE
            AND sav.status IN ('confirmed', 'completed')
            AND sav.provider_id = auth.uid()
        ),
        '[]'::jsonb
    ) AS past_appointments,
    
    -- Add availability info
    jsonb_build_object(
        'has_appointments', 
        EXISTS (
            SELECT 1 
            FROM public.service_appointments_view sav
            WHERE sav.service_id = sv.service_id
            AND sav.status IN ('confirmed', 'pending')
            AND sav.is_future = TRUE
        ),
        'upcoming_count',
        (
            SELECT COUNT(*)
            FROM public.service_appointments_view sav
            WHERE sav.service_id = sv.service_id
            AND sav.status IN ('confirmed', 'pending')
            AND sav.is_future = TRUE
        ),
        'total_completed',
        (
            SELECT COUNT(*)
            FROM public.service_appointments_view sav
            WHERE sav.service_id = sv.service_id
            AND sav.status = 'completed'
        )
    ) AS availability_stats
FROM 
    public.service_details_view sv;

-- For backwards compatibility, maintain a similar view called service_details
DROP VIEW IF EXISTS public.service_details CASCADE;
CREATE OR REPLACE VIEW public.service_details AS
SELECT
    s.id,
    p.id AS post_id,
    p.user_id,
    p.title,
    p.slug,
    p.description,
    p.content,
    p.post_type,
    p.status,
    p.thumbnail_url,
    p.created_at,
    p.updated_at,
    p.featured,
    -- Tags as JSONB array (like in event views)
    COALESCE(
        (
            SELECT jsonb_agg(t.name)
            FROM public.post_tags pt
            JOIN public.tags t ON pt.tag_id = t.id
            WHERE pt.post_id = p.id
        ),
        '[]'::jsonb
    ) AS tags,
    -- To maintain individual tag fields for backward compatibility
    -- These will be NULL and won't affect grouping
    NULL::text AS tag_name,
    NULL::uuid AS tag_id,
    pr.id AS profile_id,
    pr.full_name AS profile_full_name,
    pr.avatar_url AS profile_avatar_url,
    s.duration,
    s.price,
    s.type AS service_type,
    l.name AS location_name
FROM
    public.services s
JOIN
    public.posts p ON s.post_id = p.id
LEFT JOIN
    public.profiles pr ON p.user_id = pr.id
LEFT JOIN
    public.locations l ON s.location_id = l.id;

-- Grant permissions
GRANT SELECT ON public.service_details_view TO authenticated;
GRANT SELECT ON public.service_appointments_view TO authenticated;
GRANT SELECT ON public.user_appointments_view TO authenticated;
GRANT SELECT ON public.comprehensive_services_view TO authenticated;
GRANT SELECT ON public.service_details TO authenticated;

-- Update RPC functions to use the new views

-- Function to get detailed service information
CREATE OR REPLACE FUNCTION get_service_details(service_slug TEXT)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT 
        jsonb_build_object(
            'service_id', sv.service_id,
            'post_id', sv.post_id,
            'slug', sv.slug,
            'title', sv.title,
            'description', sv.description,
            'content', sv.content,
            'thumbnail_url', sv.thumbnail_url,
            'service_type', sv.service_type,
            'price', sv.price,
            'duration', sv.duration,
            'featured', sv.featured,
            'created_at', sv.created_at,
            'updated_at', sv.updated_at,
            'creator_id', sv.creator_id,
            'location', sv.location,
            'creator', sv.creator,
            'tags', sv.tags
        )
    INTO result
    FROM 
        public.service_details_view sv
    WHERE 
        sv.slug = service_slug;
        
    -- Add appointments if the user is the service provider
    IF result IS NOT NULL AND result->>'creator_id' = auth.uid()::TEXT THEN
        SELECT 
            result || jsonb_build_object(
                'appointments', csv.appointments,
                'future_appointments', csv.future_appointments,
                'past_appointments', csv.past_appointments,
                'availability_stats', csv.availability_stats
            )
        INTO result
        FROM 
            public.comprehensive_services_view csv
        WHERE 
            csv.service_id = (result->>'service_id')::UUID;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to get upcoming service appointments for a provider
CREATE OR REPLACE FUNCTION get_upcoming_service_appointments(
    provider_id UUID DEFAULT auth.uid(),
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    appointment_id UUID,
    service_id UUID,
    post_id UUID,
    service_title TEXT,
    appointment_date TIMESTAMP WITH TIME ZONE,
    duration INTERVAL,
    method TEXT,
    service_type TEXT,
    status TEXT,
    client_name TEXT,
    client_avatar TEXT,
    price NUMERIC
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
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
        sav.client->>'full_name' AS client_name,
        sav.client->>'avatar_url' AS client_avatar,
        sav.price_paid AS price
    FROM 
        public.service_appointments_view sav
    JOIN 
        public.service_details_view sv ON sav.service_id = sv.service_id
    WHERE 
        sav.provider_id = get_upcoming_service_appointments.provider_id
        AND sav.is_future = TRUE
        AND sav.status IN ('confirmed', 'pending')
    ORDER BY 
        sav.appointment_date ASC
    LIMIT 
        get_upcoming_service_appointments.limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get user's service appointments
CREATE OR REPLACE FUNCTION get_user_service_appointments(
    user_id UUID DEFAULT auth.uid()
)
RETURNS TABLE (
    appointment_id UUID,
    purchase_id UUID,
    service_id UUID,
    service_title TEXT,
    provider_name TEXT,
    provider_avatar TEXT,
    appointment_date TIMESTAMP WITH TIME ZONE,
    duration INTEGER,
    method TEXT,
    service_type TEXT,
    status TEXT,
    payment_status TEXT,
    amount NUMERIC,
    is_future BOOLEAN
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uav.appointment_id,
        uav.purchase_id,
        uav.service_id,
        uav.service_title,
        uav.provider_name,
        uav.provider_avatar,
        uav.appointment_date,
        uav.duration,
        uav.method,
        uav.service_type,
        uav.status,
        uav.payment_status,
        uav.amount,
        uav.is_future
    FROM 
        public.user_appointments_view uav
    WHERE 
        uav.user_id = get_user_service_appointments.user_id
    ORDER BY 
        uav.appointment_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_service_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_upcoming_service_appointments TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_service_appointments TO authenticated; 