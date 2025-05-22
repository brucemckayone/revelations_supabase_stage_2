
-- First drop all existing appointment functions to prevent conflicts
-- Drop all possible signatures of these functions

-- Drop approve_appointment_request with all possible signatures
DROP FUNCTION IF EXISTS public.approve_appointment_request(UUID, NUMERIC);
DROP FUNCTION IF EXISTS public.approve_appointment_request(UUID, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.approve_appointment_request(UUID, NUMERIC, TEXT, TEXT);

-- Drop process_appointment_payment_confirmation with all possible signatures
DROP FUNCTION IF EXISTS public.process_appointment_payment_confirmation(UUID);
DROP FUNCTION IF EXISTS public.process_appointment_payment_confirmation(UUID, TEXT);


-- Drop reschedule_appointment_request with all possible signatures
DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER);
DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER, TEXT);
DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER, TEXT, TEXT, TIMESTAMP WITH TIME ZONE[]);


-- Drop respond_to_appointment_request with all possible signatures
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(UUID, TEXT);
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(UUID, TEXT, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(UUID, TEXT, TIMESTAMP WITH TIME ZONE, TEXT);
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(UUID, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, TEXT);

-- Drop suggest_appointment_dates with all possible signatures
DROP FUNCTION IF EXISTS public.suggest_appointment_dates(UUID, TIMESTAMP WITH TIME ZONE[]);
DROP FUNCTION IF EXISTS public.suggest_appointment_dates(UUID, TIMESTAMP WITH TIME ZONE[], TEXT);
DROP FUNCTION IF EXISTS public.suggest_appointment_dates(UUID, TIMESTAMP WITH TIME ZONE[], TEXT, TEXT);

-- Also drop any related views
DROP VIEW IF EXISTS public.pending_payment_appointments; 