-- SERVICE APPOINTMENT SYSTEM IMPROVEMENTS - PHASE 1 (TABLES)
-- Implements core tables for the enhanced appointment system
-- Reference: /service_improvements.md

-- 1. Create the Provider Preferences Table
CREATE TABLE IF NOT EXISTS public.provider_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    appointment_buffer_minutes INTEGER NOT NULL DEFAULT 0,
    max_daily_appointments INTEGER,
    max_weekly_appointments INTEGER,
    advance_notice_hours INTEGER NOT NULL DEFAULT 24,
    booking_window_days INTEGER NOT NULL DEFAULT 30,
    auto_confirm BOOLEAN NOT NULL DEFAULT false,
    timezone TEXT NOT NULL DEFAULT 'UTC',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Create the Availability Exceptions Table
CREATE TABLE IF NOT EXISTS public.availability_exceptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    exception_date DATE NOT NULL,
    is_available BOOLEAN NOT NULL, -- true for extra availability, false for unavailable
    start_time TIME,
    end_time TIME,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_times CHECK ((is_available = false) OR (start_time IS NOT NULL AND end_time IS NOT NULL AND start_time < end_time))
);
CREATE INDEX IF NOT EXISTS idx_availability_exceptions_user_date 
ON public.availability_exceptions(user_id, exception_date);

-- 3. Add enhanced fields to services table
ALTER TABLE public.services
ADD COLUMN IF NOT EXISTS booking_workflow TEXT DEFAULT 'direct',
ADD COLUMN IF NOT EXISTS auto_confirm BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS confirmation_deadline_hours INTEGER DEFAULT 24;

-- Add constraint after column creation
ALTER TABLE public.services 
DROP CONSTRAINT IF EXISTS check_booking_workflow,
ADD CONSTRAINT check_booking_workflow 
CHECK (booking_workflow IN ('direct', 'pre-approval', 'waitlist'));

-- 4. Update appointment_purchases table status options
-- First, drop the existing constraint
ALTER TABLE public.appointment_purchases
DROP CONSTRAINT IF EXISTS appointment_purchases_status_check;

-- Then add the new expanded constraint with more status options
ALTER TABLE public.appointment_purchases
ADD CONSTRAINT appointment_purchases_status_check
CHECK (status IN ('pending_approval', 'pending_payment', 'confirmed',
                  'cancelled', 'completed', 'no_show', 'rescheduled'));

-- 5. Create or replace the unified provider availability function
CREATE OR REPLACE FUNCTION get_provider_availability(
    p_provider_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS TABLE (
    date DATE,
    available_slots JSONB
) AS $$
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
            LOWER(TO_CHAR(ds.day_date, 'day')) AS day_name,
            av.start_time,
            av.end_time,
            av.is_active
        FROM
            date_series ds
        LEFT JOIN
            public.availability av ON
                av.day = LOWER(TO_CHAR(ds.day_date, 'day')) AND
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_provider_availability IS 'Returns a provider''s availability with conflict checking';

-- 6. Security policies and permissions
ALTER TABLE public.provider_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.availability_exceptions ENABLE ROW LEVEL SECURITY;

-- RLS for provider preferences
CREATE POLICY provider_preferences_owner ON public.provider_preferences
    FOR ALL
    USING (user_id = auth.uid() OR
          EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'));

-- RLS for availability exceptions
CREATE POLICY availability_exceptions_owner ON public.availability_exceptions
    FOR ALL
    USING (user_id = auth.uid() OR
          EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'));

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.provider_preferences TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.availability_exceptions TO authenticated;
GRANT EXECUTE ON FUNCTION get_provider_availability TO authenticated; 