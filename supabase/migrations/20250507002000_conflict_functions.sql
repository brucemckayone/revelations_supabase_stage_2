-- SERVICE APPOINTMENT SYSTEM IMPROVEMENTS - PHASE 1 (CONFLICT CHECKING)
-- Implements the check_schedule_conflicts function needed by triggers
-- Reference: /service_improvements.md

-- Function to check for conflicts
CREATE OR REPLACE FUNCTION check_schedule_conflicts(
    p_provider_id UUID,
    p_start_time TIMESTAMP WITH TIME ZONE,
    p_end_time TIMESTAMP WITH TIME ZONE,
    p_exclude_appointment_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_has_conflicts BOOLEAN;
BEGIN
    -- Lock the provider's schedule for consistent checking
    -- In a real transaction, this would use lock_provider_schedule
    
    -- Check for conflicts
    SELECT EXISTS (
        -- Check appointment_purchases conflicts
        SELECT 1
        FROM public.appointment_purchases ap
        JOIN public.purchases p ON ap.purchase_id = p.id
        WHERE p.owner_id = p_provider_id
        AND ap.status IN ('confirmed', 'pending_approval', 'pending_payment')
        AND (ap.id != p_exclude_appointment_id OR p_exclude_appointment_id IS NULL)
        AND (ap.appointment_date, ap.appointment_date + (ap.duration || ' minutes')::INTERVAL)
            OVERLAPS (p_start_time, p_end_time)

        UNION ALL

        -- Check legacy appointments conflicts
        SELECT 1
        FROM public.appointments a
        WHERE a.facilitator_id = p_provider_id
        AND a.status IN ('confirmed', 'pending')
        AND (a.start_time, a.end_time) OVERLAPS (p_start_time, p_end_time)

        UNION ALL

        -- Check event conflicts
        SELECT 1
        FROM public.event_dates ed
        JOIN public.event_bookings eb ON ed.id = eb.date_id
        JOIN public.purchases p ON eb.purchase_id = p.id
        WHERE p.owner_id = p_provider_id
        AND eb.status IN ('confirmed', 'pending')
        AND (ed.start_date, ed.end_date) OVERLAPS (p_start_time, p_end_time)
    ) INTO v_has_conflicts;

    RETURN v_has_conflicts;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION check_schedule_conflicts IS 'Checks for scheduling conflicts across appointment systems';

-- Grant appropriate permissions
GRANT EXECUTE ON FUNCTION check_schedule_conflicts TO authenticated; 