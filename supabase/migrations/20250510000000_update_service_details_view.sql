-- Update service views to include booking workflow fields
-- This is needed for the frontend to properly handle different booking workflows

-- First, update the service_details_view to include booking workflow fields
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
    
    -- Booking workflow fields
    s.booking_workflow,
    s.auto_confirm,
    s.confirmation_deadline_hours,
    
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
    pr.avatar_url,
    s.booking_workflow,
    s.auto_confirm,
    s.confirmation_deadline_hours;

-- Now update the get_service_details function to include the booking workflow fields
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
            'booking_workflow', sv.booking_workflow,
            'auto_confirm', sv.auto_confirm,
            'confirmation_deadline_hours', sv.confirmation_deadline_hours,
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

-- Update the comprehensive_services_view to include booking workflow fields
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

-- Grant permissions
GRANT SELECT ON public.service_details_view TO authenticated;
GRANT SELECT ON public.comprehensive_services_view TO authenticated;
GRANT EXECUTE ON FUNCTION get_service_details TO authenticated;

-- Add comment to explain the change
COMMENT ON VIEW public.service_details_view IS 'Service details view with booking workflow fields';
COMMENT ON FUNCTION get_service_details IS 'Get detailed service information including booking workflow configuration'; 