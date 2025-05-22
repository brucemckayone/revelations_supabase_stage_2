-- Generated with srtd from template: supabase/migrations-templates/add_payment_link_to_appointments.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;


-- Add payment_link column to appointment_purchases table
ALTER TABLE public.appointment_purchases ADD COLUMN IF NOT EXISTS payment_link TEXT DEFAULT NULL;
COMMENT ON COLUMN public.appointment_purchases.payment_link IS 'Stores the checkout URL for pending payment appointments';

-- Add index for quicker lookup by payment_link
CREATE INDEX IF NOT EXISTS idx_appointment_purchases_payment_link ON public.appointment_purchases(payment_link);



COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
