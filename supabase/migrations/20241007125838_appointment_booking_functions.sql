-- 1. update_updated_at_column function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. set_availability function
CREATE OR REPLACE FUNCTION public.set_availability(
    p_user_id UUID,
    p_day VARCHAR(20),
    p_is_active BOOLEAN,
    p_start_time TIME,
    p_end_time TIME
) RETURNS VOID AS $$
BEGIN
    INSERT INTO public.availability (user_id, day, is_active, start_time, end_time)
    VALUES (p_user_id, LOWER(p_day), p_is_active, p_start_time, p_end_time)
    ON CONFLICT (user_id, day)
    DO UPDATE SET
        is_active = EXCLUDED.is_active,
        start_time = EXCLUDED.start_time,
        end_time = EXCLUDED.end_time,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. get_availability function
CREATE OR REPLACE FUNCTION public.get_availability(
    p_user_id UUID
) RETURNS TABLE (
    day VARCHAR(20),
    is_active BOOLEAN,
    start_time TIME,
    end_time TIME
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.day,
        a.is_active,
        a.start_time,
        a.end_time
    FROM 
        public.availability a
    WHERE 
        a.user_id = p_user_id
    ORDER BY 
        CASE 
            WHEN a.day = 'monday' THEN 1
            WHEN a.day = 'tuesday' THEN 2
            WHEN a.day = 'wednesday' THEN 3
            WHEN a.day = 'thursday' THEN 4
            WHEN a.day = 'friday' THEN 5
            WHEN a.day = 'saturday' THEN 6
            WHEN a.day = 'sunday' THEN 7
        END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. get_available_slots function
CREATE OR REPLACE FUNCTION public.get_available_slots(
    p_facilitator_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS TABLE (
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_current_date DATE;
    v_day VARCHAR(20);
    v_start_time TIME;
    v_end_time TIME;
    v_slot_start TIMESTAMP WITH TIME ZONE;
    v_slot_end TIMESTAMP WITH TIME ZONE;
BEGIN
    FOR v_current_date IN SELECT generate_series(p_start_date, p_end_date, '1 day'::interval)::date
    LOOP
        v_day := LOWER(TO_CHAR(v_current_date, 'day'));
        
        -- Get availability for the current day
        SELECT a.start_time, a.end_time 
        INTO v_start_time, v_end_time
        FROM public.availability a
        WHERE a.user_id = p_facilitator_id AND a.day = v_day AND a.is_active = TRUE;
        
        IF v_start_time IS NOT NULL THEN
            -- Generate hourly slots
            FOR v_slot_start IN 
                SELECT generate_series(
                    v_current_date + v_start_time,
                    v_current_date + v_end_time - interval '1 hour',
                    '1 hour'::interval
                )
            LOOP
                v_slot_end := v_slot_start + interval '1 hour';
                
                -- Check if the slot is not already booked
                IF NOT EXISTS (
                    SELECT 1
                    FROM public.appointments
                    WHERE facilitator_id = p_facilitator_id
                    AND status IN ('confirmed', 'pending')
                    AND (appointments.start_time, appointments.end_time) OVERLAPS (v_slot_start, v_slot_end)
                ) THEN
                    start_time := v_slot_start;
                    end_time := v_slot_end;
                    RETURN NEXT;
                END IF;
            END LOOP;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. book_appointment function
CREATE OR REPLACE FUNCTION public.book_appointment(
    p_facilitator_id UUID,
    p_client_id UUID,
    p_start_time TIMESTAMP WITH TIME ZONE,
    p_end_time TIMESTAMP WITH TIME ZONE
) RETURNS UUID AS $$
DECLARE
    v_appointment_id UUID;
    v_day VARCHAR(20);
    v_start_time TIME;
    v_end_time TIME;
BEGIN
    -- Get the day of the week for the start time
    v_day := LOWER(TO_CHAR(p_start_time AT TIME ZONE 'UTC', 'day'));
    v_start_time := p_start_time::time;
    v_end_time := p_end_time::time;
    
    -- Check if the time slot is within the facilitator's availability
    IF NOT EXISTS (
        SELECT 1
        FROM public.availability
        WHERE user_id = p_facilitator_id
        AND day = v_day
        AND is_active = TRUE
        AND start_time <= v_start_time
        AND end_time >= v_end_time
    ) THEN
        RAISE EXCEPTION 'The selected time slot is not within the facilitator''s availability';
    END IF;

    -- Check for overlapping appointments
    IF EXISTS (
        SELECT 1
        FROM public.appointments
        WHERE facilitator_id = p_facilitator_id
        AND status IN ('confirmed', 'pending')
        AND (start_time, end_time) OVERLAPS (p_start_time, p_end_time)
    ) THEN
        RAISE EXCEPTION 'The selected time slot overlaps with an existing appointment';
    END IF;

    -- Book the appointment with pending status
    INSERT INTO public.appointments (facilitator_id, client_id, start_time, end_time, status)
    VALUES (p_facilitator_id, p_client_id, p_start_time, p_end_time, 'pending')
    RETURNING id INTO v_appointment_id;

    RETURN v_appointment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. get_pending_appointments function
CREATE OR REPLACE FUNCTION public.get_pending_appointments(
    p_facilitator_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS TABLE (
    appointment_id UUID,
    client_id UUID,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id AS appointment_id,
        a.client_id,
        a.start_time,
        a.end_time
    FROM public.appointments a
    WHERE a.facilitator_id = p_facilitator_id
    AND a.status = 'pending'
    AND DATE(a.start_time) BETWEEN p_start_date AND p_end_date
    ORDER BY a.start_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. respond_to_appointment function
CREATE OR REPLACE FUNCTION public.respond_to_appointment(
    p_appointment_id UUID,
    p_action VARCHAR(20),
    p_new_start_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_new_end_time TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    IF p_action NOT IN ('confirm', 'reject', 'suggest') THEN
        RAISE EXCEPTION 'Invalid action. Must be confirm, reject, or suggest.';
    END IF;

    IF p_action = 'confirm' THEN
        UPDATE public.appointments
        SET status = 'confirmed'
        WHERE id = p_appointment_id AND status = 'pending';
    ELSIF p_action = 'reject' THEN
        UPDATE public.appointments
        SET status = 'rejected'
        WHERE id = p_appointment_id AND status = 'pending';
    ELSIF p_action = 'suggest' THEN
        IF p_new_start_time IS NULL OR p_new_end_time IS NULL THEN
            RAISE EXCEPTION 'New start and end times must be provided for suggestions.';
        END IF;
        
        UPDATE public.appointments
        SET status = 'suggested',
            start_time = p_new_start_time,
            end_time = p_new_end_time
        WHERE id = p_appointment_id AND status = 'pending';
    END IF;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment not found or not in pending status.';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. get_user_appointments function
CREATE OR REPLACE FUNCTION public.get_user_appointments(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS TABLE (
    appointment_id UUID,
    facilitator_id UUID,
    client_id UUID,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id AS appointment_id,
        a.facilitator_id,
        a.client_id,
        a.start_time,
        a.end_time,
        a.status
    FROM public.appointments a
    WHERE (a.facilitator_id = p_user_id OR a.client_id = p_user_id)
    AND DATE(a.start_time) BETWEEN p_start_date AND p_end_date
    ORDER BY a.start_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. get_suggested_appointments function
CREATE OR REPLACE FUNCTION public.get_suggested_appointments(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS TABLE (
    appointment_id UUID,
    facilitator_id UUID,
    client_id UUID,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id AS appointment_id,
        a.facilitator_id,
        a.client_id,
        a.start_time,
        a.end_time
    FROM public.appointments a
    WHERE a.client_id = p_user_id
    AND a.status = 'suggested'
    AND DATE(a.start_time) BETWEEN p_start_date AND p_end_date
    ORDER BY a.start_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers

-- 1. Trigger for updating updated_at in availability table
CREATE TRIGGER update_availability_updated_at
BEFORE UPDATE ON public.availability
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 2. Trigger for updating updated_at in appointments table
CREATE TRIGGER update_appointments_updated_at
BEFORE UPDATE ON public.appointments
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Indexes

CREATE INDEX idx_availability_user_id ON public.availability(user_id);
CREATE INDEX idx_appointments_facilitator_id ON public.appointments(facilitator_id);
CREATE INDEX idx_appointments_client_id ON public.appointments(client_id);
CREATE INDEX idx_appointments_start_time ON public.appointments(start_time);