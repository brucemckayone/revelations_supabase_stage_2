-- Generated with srtd from template: supabase/migrations-templates/20250702000004_scope_conflicts_to_day.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Template: 20250702000004_scope_conflicts_to_day.sql
-- Purpose: Adjust conflict CTEs so we only consider appointments/events whose start OR end occurs on the current date in provider's timezone.

BEGIN;

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
    SELECT COALESCE(pp.timezone, 'UTC'),
           COALESCE(pp.appointment_buffer_minutes, 0),
           COALESCE(pp.advance_notice_hours, 24),
           COALESCE(pp.booking_window_days, 30)
    INTO   v_timezone, v_buffer, v_notice, v_window_days
    FROM   public.provider_preferences pp
    WHERE  pp.user_id = p_provider_id;

    IF NOT FOUND THEN
        v_timezone   := 'UTC';
        v_buffer     := 0;
        v_notice     := 24;
        v_window_days := 30;
    END IF;

    v_booking_window_end := DATE((v_now + (v_window_days || ' days')::interval) AT TIME ZONE v_timezone);
    IF p_end_date > v_booking_window_end THEN p_end_date := v_booking_window_end; END IF;

    WHILE current_loop_date <= p_end_date LOOP
        date := current_loop_date;

        WITH
        appts AS (
            SELECT (ap.appointment_date AT TIME ZONE v_timezone)                                        AS start_local,
                   ((ap.appointment_date + (ap.duration || ' hours')::interval) AT TIME ZONE v_timezone) AS end_local
            FROM   public.appointment_purchases ap
            JOIN   public.purchases p ON p.id = ap.purchase_id
            WHERE  p.owner_id = p_provider_id
              AND  ap.status IN ('confirmed','pending_approval','pending_payment','pending_auto_payment','pending_reschedule')
              AND  (DATE((ap.appointment_date AT TIME ZONE v_timezone)) = current_loop_date) -- scope to current day
        ),
        evts AS (
            SELECT (ed.start_date AT TIME ZONE v_timezone) AS start_local,
                   (ed.end_date   AT TIME ZONE v_timezone) AS end_local
            FROM   public.event_dates ed
            JOIN   public.events      e  ON e.id = ed.event_id
            JOIN   public.posts       po ON po.id = e.post_id
            WHERE  po.user_id = p_provider_id
              AND  (DATE((ed.start_date AT TIME ZONE v_timezone)) = current_loop_date) -- scope to current day
        ),
        raw_slots AS (
            SELECT ((current_loop_date + avail.start_time) + h * make_interval(mins=>p_slot_length_minutes))  AS slot_naive,
                   ((current_loop_date + avail.start_time) + (h+1)* make_interval(mins=>p_slot_length_minutes)) AS slot_end_naive
            FROM   public.availability avail
            CROSS JOIN LATERAL generate_series(
                0,
                GREATEST(floor(extract(epoch FROM (avail.end_time-avail.start_time))/(60*p_slot_length_minutes))::int - 1,0)
            ) AS h
            WHERE  avail.user_id = p_provider_id
              AND  avail.is_active = true
              AND  lower(avail.day) = lower(trim(to_char(current_loop_date,'day')))
              AND  NOT EXISTS (
                     SELECT 1 FROM public.availability_exceptions ae
                     WHERE ae.user_id = p_provider_id
                       AND ae.exception_date = current_loop_date
                       AND ae.is_available = false)
        ),
        slots AS (
            SELECT (slot_naive     AT TIME ZONE v_timezone) AS slot_start,
                   (slot_end_naive AT TIME ZONE v_timezone) AS slot_end
            FROM   raw_slots
        ),
        checked AS (
            SELECT s.slot_start, s.slot_end,
                   (s.slot_start < (v_now + (v_notice || ' hours')::interval))                               AS is_past,
                   EXISTS (
                        SELECT 1 FROM appts ac
                        WHERE tstzrange((ac.start_local - make_interval(mins=>v_buffer)),
                                         (ac.end_local   + make_interval(mins=>v_buffer)), '[]') &&
                              tstzrange(s.slot_start, s.slot_end, '[]'))                                     AS has_appt,
                   EXISTS (
                        SELECT 1 FROM evts ec
                        WHERE tstzrange(ec.start_local, ec.end_local, '[]') &&
                              tstzrange(s.slot_start, s.slot_end, '[]'))                                     AS has_evt
            FROM slots s
        )
        SELECT jsonb_agg(
                   jsonb_build_object(
                       'start_time', checked.slot_start,
                       'end_time',   checked.slot_end,
                       'available',  NOT (checked.is_past OR checked.has_appt OR checked.has_evt),
                       'slot_id',    md5(p_provider_id::text || checked.slot_start::text)
                   ) ORDER BY checked.slot_start)
          INTO available_slots
        FROM checked;

        IF available_slots IS NULL THEN available_slots := '[]'::jsonb; END IF;

        RETURN NEXT;
        current_loop_date := current_loop_date + interval '1 day';
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION public.get_provider_availability(uuid,date,date,integer) IS 'Scopes appointment/event conflicts to day-level to prevent multi-day ranges from blocking whole calendar.';

COMMIT;

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
