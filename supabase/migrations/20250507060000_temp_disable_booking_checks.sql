-- Temporary override of prevent_double_booking for seeding
-- This makes the function a no-op that always allows appointments
-- IMPORTANT: This is only for development/seeding purposes

-- Save the original function for later restoration if needed
CREATE OR REPLACE FUNCTION original_prevent_double_booking()
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

-- Replace the current function with a no-op version
CREATE OR REPLACE FUNCTION prevent_double_booking()
RETURNS TRIGGER AS $$
BEGIN
    -- Always allow the booking during seeding
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 