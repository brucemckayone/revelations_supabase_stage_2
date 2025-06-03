-- Generated with srtd from template: supabase/migrations-templates/trigger-auto-appointment-confirm.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;


-- =============================================================================
-- AUTO-APPOINTMENT CONFIRMATION TRIGGER
-- =============================================================================
-- This trigger automatically approves appointments with status 'pending_auto_payment'
-- Updated to work with specialized chat channels system



-- Drop existing function and triggers first for idempotency
DROP TRIGGER IF EXISTS trg_auto_confirm_appointment_update ON public.appointment_purchases;
DROP TRIGGER IF EXISTS trg_auto_confirm_appointment_insert ON public.appointment_purchases;
DROP TRIGGER IF EXISTS trg_auto_confirm_appointment ON public.appointment_purchases;
DROP FUNCTION IF EXISTS public.auto_confirm_appointment_trigger;

-- Create the auto-confirmation trigger function (renamed to avoid conflicts)
CREATE FUNCTION public.auto_confirm_appointment_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_result JSON;
BEGIN
    -- If the new status is 'pending_auto_payment', automatically approve it
    IF NEW.status = 'pending_auto_payment' THEN
        
        -- Call the new auto-confirmation function which handles:
        -- - Status update to confirmed
        -- - Specialized chat room creation
        -- - Living status message creation
        -- - Notifications via triggers
        SELECT public.auto_confirm_appointment_v2(NEW.id) INTO v_result;
        
        -- Log the result for debugging
        RAISE LOG 'Auto-confirmed appointment %: %', NEW.id, v_result;
        
    END IF;
    
    -- Always return NEW for AFTER triggers
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for both UPDATE and INSERT operations
-- Use AFTER triggers to avoid conflicts with the status update
CREATE TRIGGER trg_auto_confirm_appointment_update
  AFTER UPDATE OF status ON public.appointment_purchases
  FOR EACH ROW 
  WHEN (NEW.status = 'pending_auto_payment')
  EXECUTE FUNCTION public.auto_confirm_appointment_trigger();

CREATE TRIGGER trg_auto_confirm_appointment_insert
  AFTER INSERT ON public.appointment_purchases
  FOR EACH ROW
  WHEN (NEW.status = 'pending_auto_payment')
  EXECUTE FUNCTION public.auto_confirm_appointment_trigger();

COMMENT ON FUNCTION public.auto_confirm_appointment_trigger() IS 'Automatically approves appointments with pending_auto_payment status using specialized chat channels system. Calls auto_confirm_appointment_v2 function.';



COMMIT;

-- Last built: 20250522151945_srtd-trigger-auto-appointment-confirm.sql
-- Built with https://github.com/t1mmen/srtd
