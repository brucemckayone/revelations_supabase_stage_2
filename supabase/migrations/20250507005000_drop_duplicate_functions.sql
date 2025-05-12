-- SERVICE APPOINTMENT SYSTEM IMPROVEMENTS - PHASE 1 (PREP)
-- Drops duplicate functions to prevent conflicts during migration
-- Reference: /service_improvements.md

-- Drop the existing get_user_appointments function if it exists
DROP FUNCTION IF EXISTS public.get_user_appointments;
