-- drop_obsolete_appointments_table.sql
-- Removes legacy public.appointments table which has been superseded by appointment_purchases.
-- Idempotent and safe via cascade.

begin;

-- Drop triggers that may reference appointments (if they still exist)
DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN SELECT trigger_name
             FROM information_schema.triggers
             WHERE event_object_table = 'appointments'
               AND trigger_schema = 'public'
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.appointments;', rec.trigger_name);
  END LOOP;
END $$;

-- Finally drop the table (cascade to remove dependent views/constraints)
drop table if exists public.appointments cascade;

commit;

-- Built with srtd hot-reload 