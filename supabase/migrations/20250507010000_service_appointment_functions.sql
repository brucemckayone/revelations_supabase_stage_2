-- SERVICE APPOINTMENT SYSTEM IMPROVEMENTS - PHASE 1 (PART 2)
-- Implements core booking and management functions
-- Reference: /service_improvements.md

-- 1. Unified appointment request function with workflow handling
CREATE OR REPLACE FUNCTION request_service_appointment(
    p_service_id UUID,
    p_requested_date TIMESTAMP WITH TIME ZONE,
    p_duration INTEGER DEFAULT NULL,
    p_method TEXT DEFAULT 'video',
    p_service_type TEXT DEFAULT 'consultation',
    p_notes TEXT DEFAULT NULL,
    p_client_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_client_id UUID;
    v_service_owner_id UUID;
    v_booking_workflow TEXT;
    v_auto_confirm BOOLEAN;
    v_service_price NUMERIC;
    v_service_duration INTEGER;
    v_purchase_id UUID;
    v_appointment_id UUID;
    v_initial_status TEXT;
    v_result JSONB;
    v_timezone TEXT;
    v_slot_available BOOLEAN;
BEGIN
    -- Set client ID (default to current user)
    v_client_id := COALESCE(p_client_id, auth.uid());
    
    -- Check if client is logged in
    IF v_client_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Authentication required'
        );
    END IF;
    
    -- Get service details and owner preferences
    SELECT 
        p.user_id, 
        s.booking_workflow,
        s.auto_confirm,
        s.price,
        EXTRACT(EPOCH FROM s.duration)::INTEGER / 60 AS duration_minutes,
        pp.timezone
    INTO 
        v_service_owner_id,
        v_booking_workflow,
        v_auto_confirm,
        v_service_price,
        v_service_duration,
        v_timezone
    FROM 
        public.services s
    JOIN 
        public.posts p ON s.post_id = p.id
    LEFT JOIN
        public.provider_preferences pp ON p.user_id = pp.user_id
    WHERE 
        s.id = p_service_id;
    
    -- Check if the service exists
    IF v_service_owner_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Service not found'
        );
    END IF;
    
    -- Set duration (use service default if not provided)
    v_service_duration := COALESCE(p_duration, v_service_duration);
    IF v_service_duration IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Service duration not specified'
        );
    END IF;
    
    -- Verify the time slot is available
    IF check_schedule_conflicts(
        v_service_owner_id, 
        p_requested_date, 
        p_requested_date + (v_service_duration || ' minutes')::INTERVAL
    ) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'The requested time slot is not available'
        );
    END IF;
    
    -- Determine initial status based on workflow
    CASE 
        WHEN v_booking_workflow = 'direct' AND v_auto_confirm THEN
            v_initial_status := 'confirmed';
        WHEN v_booking_workflow = 'direct' AND NOT v_auto_confirm THEN
            v_initial_status := 'pending_payment';
        WHEN v_booking_workflow = 'pre-approval' THEN
            v_initial_status := 'pending_approval';
        WHEN v_booking_workflow = 'waitlist' THEN
            v_initial_status := 'pending_approval';
        ELSE
            v_initial_status := 'pending_approval';
    END CASE;
    
    -- Create purchase record first
    INSERT INTO public.purchases (
        user_id,
        owner_id,
        amount,
        currency,
        payment_status,
        service_id,
        purchase_type,
        start_date,
        end_date,
        metadata
    ) VALUES (
        v_client_id,
        v_service_owner_id,
        v_service_price,
        'GBP',
        CASE WHEN v_initial_status = 'confirmed' THEN 'completed' ELSE 'pending' END,
        p_service_id,
        'appointment',
        p_requested_date,
        p_requested_date + (v_service_duration || ' minutes')::INTERVAL,
        jsonb_build_object(
            'appointment_type', p_service_type,
            'appointment_method', p_method,
            'client_notes', p_notes
        )
    ) RETURNING id INTO v_purchase_id;
    
    -- Create appointment record
    INSERT INTO public.appointment_purchases (
        purchase_id,
        service_id,
        appointment_date,
        duration,
        method,
        service_type,
        status,
        notes
    ) VALUES (
        v_purchase_id,
        p_service_id,
        p_requested_date,
        v_service_duration,
        p_method,
        p_service_type,
        v_initial_status,
        p_notes
    ) RETURNING id INTO v_appointment_id;
    
    -- Return result with appropriate next steps
    v_result := jsonb_build_object(
        'success', TRUE,
        'appointment_id', v_appointment_id,
        'purchase_id', v_purchase_id,
        'service_id', p_service_id,
        'status', v_initial_status,
        'requires_payment', (v_initial_status = 'pending_payment'),
        'requires_approval', (v_initial_status = 'pending_approval'),
        'appointment_date', p_requested_date,
        'duration', v_service_duration,
        'price', v_service_price,
        'provider_id', v_service_owner_id,
        'client_id', v_client_id,
        'workflow', v_booking_workflow,
        'next_steps', CASE
            WHEN v_initial_status = 'pending_payment' THEN 'Payment required to confirm booking'
            WHEN v_initial_status = 'pending_approval' THEN 'Waiting for provider approval'
            WHEN v_initial_status = 'confirmed' THEN 'Appointment confirmed'
            ELSE 'Review appointment details'
        END
    );
    
    RETURN v_result;
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', FALSE,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION request_service_appointment IS 'Creates a service appointment request with appropriate workflow based on service settings';

-- 2. Function for providers to respond to appointment requests
CREATE OR REPLACE FUNCTION respond_to_appointment_request(
    p_appointment_id UUID,
    p_action TEXT, -- 'confirm', 'reject', 'suggest_alternative'
    p_alternative_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_provider_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_appointment_record RECORD;
    v_provider_id UUID;
    v_current_status TEXT;
    v_source TEXT;
    v_purchase_id UUID;
    v_result JSONB;
BEGIN
    -- Determine which system the appointment is in
    
    -- First check appointment_purchases
    SELECT 
        ap.id, 
        ap.status, 
        p.owner_id AS provider_id,
        'appointment_purchase' AS source,
        p.id AS purchase_id
    INTO v_appointment_record
    FROM 
        public.appointment_purchases ap
    JOIN 
        public.purchases p ON ap.purchase_id = p.id
    WHERE 
        ap.id = p_appointment_id;
    
    -- If not found, check legacy appointments
    IF v_appointment_record.id IS NULL THEN
        SELECT 
            a.id, 
            a.status, 
            a.facilitator_id AS provider_id,
            'legacy_appointment' AS source,
            NULL AS purchase_id
        INTO v_appointment_record
        FROM 
            public.appointments a
        WHERE 
            a.id = p_appointment_id;
    END IF;
    
    -- If still not found, appointment doesn't exist
    IF v_appointment_record.id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Appointment not found'
        );
    END IF;
    
    -- Store found values
    v_provider_id := v_appointment_record.provider_id;
    v_current_status := v_appointment_record.status;
    v_source := v_appointment_record.source;
    v_purchase_id := v_appointment_record.purchase_id;
    
    -- Check permissions
    IF v_provider_id != auth.uid() AND NOT EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Permission denied'
        );
    END IF;
    
    -- Process the response based on source system
    IF v_source = 'appointment_purchase' THEN
        -- Handle appointment_purchases
        IF p_action = 'confirm' THEN
            IF v_current_status NOT IN ('pending_approval', 'pending_payment') THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Appointment cannot be confirmed in its current status: ' || v_current_status
                );
            END IF;
            
            -- Update to confirmed
            UPDATE public.appointment_purchases
            SET 
                status = 'confirmed',
                notes = CASE 
                    WHEN p_provider_notes IS NOT NULL THEN 
                        COALESCE(notes, '') || E'\nProvider notes: ' || p_provider_notes
                    ELSE notes
                END
            WHERE id = p_appointment_id;
            
            -- Also update purchase if needed
            IF v_current_status = 'pending_approval' THEN
                UPDATE public.purchases
                SET payment_status = 'completed'
                WHERE id = v_purchase_id;
            END IF;
            
            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'confirm',
                'appointment_id', p_appointment_id,
                'status', 'confirmed'
            );
            
        ELSIF p_action = 'reject' THEN
            IF v_current_status NOT IN ('pending_approval', 'pending_payment', 'confirmed') THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Appointment cannot be rejected in its current status: ' || v_current_status
                );
            END IF;
            
            -- Update to cancelled
            UPDATE public.appointment_purchases
            SET 
                status = 'cancelled',
                notes = CASE 
                    WHEN p_provider_notes IS NOT NULL THEN 
                        COALESCE(notes, '') || E'\nRejection reason: ' || p_provider_notes
                    ELSE notes
                END
            WHERE id = p_appointment_id;
            
            -- If payment was already made, set to refunded
            IF v_current_status IN ('confirmed', 'pending_payment') THEN
                UPDATE public.purchases
                SET payment_status = 'refunded'
                WHERE id = v_purchase_id;
            END IF;
            
            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'reject',
                'appointment_id', p_appointment_id,
                'status', 'cancelled'
            );
            
        ELSIF p_action = 'suggest_alternative' THEN
            IF v_current_status NOT IN ('pending_approval', 'pending_payment') OR p_alternative_time IS NULL THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Cannot suggest alternative time'
                );
            END IF;
            
            -- Create a record of the suggestion in metadata
            UPDATE public.appointment_purchases
            SET 
                notes = COALESCE(notes, '') || E'\nAlternative time suggested: ' || 
                    TO_CHAR(p_alternative_time, 'YYYY-MM-DD HH24:MI:SS'),
                metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
                    'alternative_time', p_alternative_time,
                    'suggestion_notes', p_provider_notes
                )
            WHERE id = p_appointment_id;
            
            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'suggest_alternative',
                'appointment_id', p_appointment_id,
                'suggested_time', p_alternative_time
            );
        ELSE
            RETURN jsonb_build_object(
                'success', FALSE,
                'error', 'Invalid action: ' || p_action
            );
        END IF;
        
    ELSE
        -- Handle legacy appointments
        IF p_action = 'confirm' THEN
            UPDATE public.appointments
            SET status = 'confirmed'
            WHERE id = p_appointment_id AND status = 'pending';
            
        ELSIF p_action = 'reject' THEN
            UPDATE public.appointments
            SET status = 'rejected'
            WHERE id = p_appointment_id AND status = 'pending';
            
        ELSIF p_action = 'suggest_alternative' AND p_alternative_time IS NOT NULL THEN
            UPDATE public.appointments
            SET 
                status = 'suggested',
                start_time = p_alternative_time,
                end_time = p_alternative_time + interval '1 hour'
            WHERE id = p_appointment_id AND status = 'pending';
        ELSE
            RETURN jsonb_build_object(
                'success', FALSE,
                'error', 'Invalid action for legacy appointment'
            );
        END IF;
        
        v_result := jsonb_build_object(
            'success', TRUE,
            'action', p_action,
            'appointment_id', p_appointment_id
        );
    END IF;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION respond_to_appointment_request IS 'Allows providers to confirm, reject, or suggest alternatives for appointment requests';

-- 3. Basic service calendar availability function
CREATE OR REPLACE FUNCTION get_service_calendar_availability(
    p_service_id UUID,
    p_days_ahead INTEGER DEFAULT 30,
    p_timezone TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_start_date DATE := CURRENT_DATE;
    v_end_date DATE := CURRENT_DATE + (p_days_ahead || ' days')::INTERVAL;
    v_service_owner_id UUID;
    v_timezone TEXT;
    v_result JSONB;
BEGIN
    -- Get service provider
    SELECT p.user_id, COALESCE(p_timezone, pp.timezone, 'UTC')
    INTO v_service_owner_id, v_timezone
    FROM public.services s
    JOIN public.posts p ON s.post_id = p.id
    LEFT JOIN public.provider_preferences pp ON p.user_id = pp.user_id
    WHERE s.id = p_service_id;
    
    IF v_service_owner_id IS NULL THEN
        RETURN jsonb_build_object('error', 'Service not found');
    END IF;
    
    -- Get availability data
    WITH availability_data AS (
        SELECT 
            date,
            available_slots
        FROM 
            get_provider_availability(v_service_owner_id, v_start_date, v_end_date)
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_service_calendar_availability IS 'Returns calendar-friendly availability data for a specific service';

-- 4. Client appointment management view function
CREATE OR REPLACE FUNCTION get_user_appointments(
    p_user_id UUID DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_result JSONB;
BEGIN
    -- Default to current user
    v_user_id := COALESCE(p_user_id, auth.uid());
    
    -- Check permissions if trying to view another user's appointments
    IF v_user_id != auth.uid() AND NOT EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN jsonb_build_object('error', 'Permission denied');
    END IF;
    
    -- Get appointments
    WITH user_appointments AS (
        SELECT
            ap.id AS appointment_id,
            p.id AS purchase_id,
            s.id AS service_id,
            pp.id AS post_id,
            pp.title AS service_title,
            pr.full_name AS provider_name,
            pr.avatar_url AS provider_avatar,
            p.owner_id AS provider_id,
            ap.appointment_date,
            ap.duration,
            ap.method,
            ap.service_type,
            ap.status,
            p.payment_status,
            p.amount,
            ap.appointment_date > CURRENT_TIMESTAMP AS is_future,
            ROW_NUMBER() OVER (
                ORDER BY 
                    CASE WHEN ap.appointment_date > CURRENT_TIMESTAMP THEN 0 ELSE 1 END,
                    ap.appointment_date
            ) AS row_num
        FROM
            public.appointment_purchases ap
        JOIN
            public.purchases p ON ap.purchase_id = p.id
        JOIN
            public.services s ON ap.service_id = s.id
        JOIN
            public.posts pp ON s.post_id = pp.id
        LEFT JOIN
            public.profiles pr ON p.owner_id = pr.id
        WHERE
            p.user_id = v_user_id
            AND (p_status IS NULL OR ap.status = p_status)
    )
    SELECT jsonb_build_object(
        'appointments', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'appointment_id', appointment_id,
                    'purchase_id', purchase_id,
                    'service_id', service_id,
                    'service_title', service_title,
                    'provider_name', provider_name,
                    'provider_avatar', provider_avatar,
                    'provider_id', provider_id,
                    'appointment_date', appointment_date,
                    'duration', duration,
                    'method', method,
                    'service_type', service_type,
                    'status', status,
                    'payment_status', payment_status,
                    'amount', amount,
                    'is_future', is_future
                )
            )
            FROM user_appointments
            WHERE row_num > p_offset AND row_num <= (p_offset + p_limit)
        ),
        'count', (
            SELECT COUNT(*) FROM user_appointments
        ),
        'summary', (
            SELECT jsonb_build_object(
                'upcoming', COUNT(*) FILTER (WHERE is_future AND status = 'confirmed'),
                'pending', COUNT(*) FILTER (WHERE status IN ('pending_approval', 'pending_payment')),
                'past', COUNT(*) FILTER (WHERE NOT is_future AND status = 'confirmed'),
                'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled')
            )
            FROM user_appointments
        )
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_user_appointments IS 'Returns a user''s appointment bookings with pagination and filtering';

-- Grant appropriate permissions
GRANT EXECUTE ON FUNCTION request_service_appointment TO authenticated;
GRANT EXECUTE ON FUNCTION respond_to_appointment_request TO authenticated;
GRANT EXECUTE ON FUNCTION get_service_calendar_availability TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_appointments TO authenticated;

-- Create the services_with_availability view for easy querying
CREATE OR REPLACE VIEW public.services_with_availability AS
SELECT
    s.*,
    s.title as service_title,
    s.thumbnail_url as service_thumbnail,
    jsonb_build_object(
        'has_availability', EXISTS (
            SELECT 1
            FROM get_provider_availability(p.user_id, CURRENT_DATE, CURRENT_DATE + 30)
            CROSS JOIN jsonb_array_elements(available_slots) AS slot
            WHERE (slot->>'available')::BOOLEAN = true
            LIMIT 1
        )
    ) AS availability_status
FROM 
    public.service_details_view s
JOIN 
    public.posts p ON s.post_id = p.id;

COMMENT ON VIEW public.services_with_availability IS 'Service details with basic availability status for filtering';

-- Function to get provider availability
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
                     (ts.slot_time + '30 minutes'::interval) <= ex.end_time THEN true
                -- Handle regular availability
                WHEN ex.exception_date IS NULL AND
                     da.is_active AND
                     ts.slot_time >= da.start_time AND
                     (ts.slot_time + '30 minutes'::interval) <= da.end_time THEN true
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