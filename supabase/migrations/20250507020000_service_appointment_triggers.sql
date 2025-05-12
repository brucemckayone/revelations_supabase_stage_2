-- SERVICE APPOINTMENT SYSTEM IMPROVEMENTS - PHASE 1 (PART 3)
-- Implements trigger functions to prevent double-booking
-- Reference: /service_improvements.md

-- 1. Trigger function to prevent double-booking
CREATE OR REPLACE FUNCTION prevent_double_booking() 
RETURNS TRIGGER AS $$
DECLARE
    v_provider_id UUID;
    v_start_time TIMESTAMP WITH TIME ZONE;
    v_end_time TIMESTAMP WITH TIME ZONE;
    v_has_conflicts BOOLEAN;
BEGIN
    -- Get the provider ID and time range
    IF TG_TABLE_NAME = 'appointment_purchases' THEN
        SELECT p.owner_id INTO v_provider_id
        FROM public.purchases p
        WHERE p.id = NEW.purchase_id;
        
        v_start_time := NEW.appointment_date;
        v_end_time := NEW.appointment_date + (NEW.duration || ' minutes')::INTERVAL;
    ELSIF TG_TABLE_NAME = 'appointments' THEN
        v_provider_id := NEW.facilitator_id;
        v_start_time := NEW.start_time;
        v_end_time := NEW.end_time;
    END IF;
    
    -- Don't check conflicts for cancelled/completed appointments
    IF NEW.status IN ('cancelled', 'completed', 'no_show') THEN
        RETURN NEW;
    END IF;
    
    -- Check for conflicts
    v_has_conflicts := check_schedule_conflicts(
        v_provider_id, 
        v_start_time, 
        v_end_time,
        CASE WHEN TG_TABLE_NAME = 'appointment_purchases' THEN NEW.id ELSE NULL END
    );
    
    IF v_has_conflicts THEN
        RAISE EXCEPTION 'This time slot conflicts with an existing commitment';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION prevent_double_booking IS 'Trigger function to prevent double-booking appointments';

-- 2. Create triggers on both appointment tables
DROP TRIGGER IF EXISTS check_appointment_purchase_conflicts ON public.appointment_purchases;
CREATE TRIGGER check_appointment_purchase_conflicts
BEFORE INSERT OR UPDATE ON public.appointment_purchases
FOR EACH ROW EXECUTE FUNCTION prevent_double_booking();

DROP TRIGGER IF EXISTS check_legacy_appointment_conflicts ON public.appointments;
CREATE TRIGGER check_legacy_appointment_conflicts
BEFORE INSERT OR UPDATE ON public.appointments
FOR EACH ROW EXECUTE FUNCTION prevent_double_booking();

-- 3. Add lock-based transaction safety for concurrent operations
CREATE OR REPLACE FUNCTION lock_provider_schedule(
    p_provider_id UUID
) RETURNS BIGINT AS $$
DECLARE
    v_lock_key BIGINT;
BEGIN
    -- Create a stable lock key from the UUID
    SELECT ('x' || substring(p_provider_id::TEXT, 1, 8))::BIT(32)::BIGINT INTO v_lock_key;
    
    -- Acquire advisory lock with 5 second timeout
    IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
        -- Wait up to 5 seconds
        PERFORM pg_sleep(0.1)
        FROM generate_series(1, 50)
        WHERE NOT pg_try_advisory_xact_lock(v_lock_key);
        
        IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
            RAISE EXCEPTION 'Could not acquire schedule lock, try again later';
        END IF;
    END IF;
    
    RETURN v_lock_key;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION lock_provider_schedule IS 'Acquires an advisory lock for a provider schedule to prevent race conditions';

-- 4. Update the request_service_appointment function to use the lock
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
    v_lock_key BIGINT;
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
    
    -- Acquire lock for provider schedule to prevent race conditions
    v_lock_key := lock_provider_schedule(v_service_owner_id);
    
    -- Verify the time slot is available with the lock held
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

-- Grant appropriate permissions
GRANT EXECUTE ON FUNCTION lock_provider_schedule TO authenticated; 