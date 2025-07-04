-- Template: 20250702000002_fix_get_provider_availability_conflicts.sql
-- Purpose: Fix edge-case where busy slots were still marked available (e.g. 12:00 on 2025-07-17).
-- Strategy:
--   1. Convert appointment/event times to provider timezone for accurate same-day matching.
--   2. Use tstzrange overlap logic with buffer minutes for robust conflict checking.
--   3. Keep return signature the same (slots array with available boolean) but logic more accurate.

BEGIN;

-- Drop old version first
DROP FUNCTION IF EXISTS public.get_provider_availability(UUID, DATE, DATE, INTEGER);

CREATE OR REPLACE FUNCTION public.get_provider_availability(
    p_provider_id UUID,
    p_start_date  DATE,
    p_end_date    DATE,
    p_slot_length_minutes INTEGER
) RETURNS TABLE (
    date DATE,
    available_slots JSONB
) AS $$
DECLARE
    v_timezone   TEXT;
    v_buffer     INTEGER;
    v_notice     INTEGER;
    v_window_days INTEGER;
    v_now        TIMESTAMPTZ := NOW();
    v_booking_window_end DATE;
    current_loop_date DATE := p_start_date;
BEGIN
    -- Provider preferences ---------------------------------------------------
    SELECT
        COALESCE(pp.timezone, 'UTC'),
        COALESCE(pp.appointment_buffer_minutes, 0),
        COALESCE(pp.advance_notice_hours, 24),
        COALESCE(pp.booking_window_days, 30)
    INTO v_timezone, v_buffer, v_notice, v_window_days
    FROM public.provider_preferences pp
    WHERE pp.user_id = p_provider_id;

    IF NOT FOUND THEN
        v_timezone   := 'UTC';
        v_buffer     := 0;
        v_notice     := 24;
        v_window_days := 30;
    END IF;

    v_booking_window_end := DATE((v_now + (v_window_days || ' days')::interval) AT TIME ZONE v_timezone);
    IF p_end_date > v_booking_window_end THEN
        p_end_date := v_booking_window_end;
    END IF;

    -- Iterate through each date ---------------------------------------------
    WHILE current_loop_date <= p_end_date LOOP
        date := current_loop_date;

        WITH
        -- Appointments -------------------------------------------------------
        appointment_conflicts AS (
            SELECT  
                (ap.appointment_date AT TIME ZONE v_timezone)                       AS start_local,
                ((ap.appointment_date + (ap.duration || ' hours')::interval)
                        AT TIME ZONE v_timezone)                                   AS end_local
            FROM   public.appointment_purchases ap
            JOIN   public.purchases p ON p.id = ap.purchase_id
            WHERE  p.owner_id = p_provider_id
              AND  ap.status IN ('confirmed', 'pending_approval', 'pending_payment',
                                 'pending_auto_payment', 'pending_reschedule')
              AND  DATE((ap.appointment_date AT TIME ZONE v_timezone)) = current_loop_date
        ),
        -- Events -------------------------------------------------------------
        event_conflicts AS (
            SELECT (ed.start_date AT TIME ZONE v_timezone) AS start_local,
                   (ed.end_date   AT TIME ZONE v_timezone) AS end_local
            FROM   public.event_dates ed
            JOIN   public.events      e ON e.id = ed.event_id
            JOIN   public.posts       po ON po.id = e.post_id
            WHERE  po.user_id = p_provider_id
              AND  DATE((ed.start_date AT TIME ZONE v_timezone)) = current_loop_date
        ),
        -- Base slots ---------------------------------------------------------
        base_slots AS (
            SELECT 
                ((current_loop_date + avail.start_time) + h * make_interval(mins=>p_slot_length_minutes))            AS slot_local,
                ((current_loop_date + avail.start_time) + (h+1) * make_interval(mins=>p_slot_length_minutes))        AS slot_end_local
            FROM public.availability avail
            CROSS JOIN LATERAL generate_series(
                0,
                GREATEST( floor(extract(epoch FROM (avail.end_time - avail.start_time)) / (60 * p_slot_length_minutes))::INT - 1, 0)
            ) AS h
            WHERE avail.user_id = p_provider_id
              AND avail.is_active = TRUE
              AND lower(avail.day) = lower(trim(to_char(current_loop_date,'day')))
              AND NOT EXISTS (
                    SELECT 1 FROM public.availability_exceptions ae
                    WHERE ae.user_id = p_provider_id
                      AND ae.exception_date = current_loop_date
                      AND ae.is_available = FALSE)
        ),
        -- Check conflicts using tstzrange overlap with buffer ----------------
        checked_slots AS (
            SELECT 
                bs.slot_local,
                bs.slot_end_local,
                -- Past check -------------------------------------------------
                ((bs.slot_local AT TIME ZONE v_timezone) < ((v_now + (v_notice || ' hours')::interval) AT TIME ZONE v_timezone))      AS is_past,

                -- Appointment conflict -------------------------------------
                EXISTS (
                    SELECT 1 FROM appointment_conflicts ac
                    WHERE tstzrange( (ac.start_local  - make_interval(mins=>v_buffer)),
                                     (ac.end_local    + make_interval(mins=>v_buffer)),
                                     '[]') &&
                          tstzrange( bs.slot_local, bs.slot_end_local, '[]')
                ) AS has_appointment_conflict,

                -- Event conflict -------------------------------------------
                EXISTS (
                    SELECT 1 FROM event_conflicts ec
                    WHERE tstzrange(ec.start_local, ec.end_local, '[]') &&
                          tstzrange(bs.slot_local, bs.slot_end_local, '[]')
                ) AS has_event_conflict
            FROM base_slots bs
        )
        SELECT jsonb_agg(
                   jsonb_build_object(
                       'start_time', cs.slot_local AT TIME ZONE v_timezone,  -- return as timestamptz in provider tz
                       'end_time',   cs.slot_end_local AT TIME ZONE v_timezone,
                       'available',  NOT (cs.is_past OR cs.has_appointment_conflict OR cs.has_event_conflict),
                       'slot_id',    md5(p_provider_id::TEXT || cs.slot_local::TEXT)
                   ) ORDER BY cs.slot_local
               )
        INTO available_slots
        FROM checked_slots cs;

        IF available_slots IS NULL THEN
            available_slots := '[]'::JSONB;
        END IF;

        RETURN NEXT;
        current_loop_date := current_loop_date + INTERVAL '1 day';
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION public.get_provider_availability(uuid, date, date, integer) IS
'Computes provider availability with accurate conflict detection (buffer & timezone-aware). Fixes earlier bug where busy slots could show as available.';

COMMIT; 