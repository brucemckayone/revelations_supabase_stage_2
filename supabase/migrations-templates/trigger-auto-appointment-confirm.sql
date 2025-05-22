
-- Trigger function to automatically confirm appointments when status is pending_auto_payment
CREATE OR REPLACE FUNCTION public.auto_confirm_appointment()
RETURNS TRIGGER AS $$
DECLARE
    v_price NUMERIC;
    v_purchase_id UUID;
BEGIN
    -- If the new status is 'pending_auto_payment', automatically approve it
    IF NEW.status = 'pending_auto_payment'::appointment_status_enum THEN
        -- Get the price from the purchase record
        SELECT p.amount, p.id INTO v_price, v_purchase_id
        FROM public.purchases p
        JOIN public.appointment_purchases ap ON ap.purchase_id = p.id
        WHERE ap.id = NEW.id;
        
        -- Call the approve_appointment_request function
        -- This handles approval, payment link generation, and all related operations
        PERFORM public.approve_appointment_request(
            p_appointment_id := NEW.id,
            p_price := v_price,
            p_message := 'Automatically approved by system'
        );
        
        -- Return NULL since the actual update was done in the function
        RETURN NULL;
    END IF;
    
    -- For other status changes, just proceed normally
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on appointment_purchases table
DROP TRIGGER IF EXISTS trg_auto_confirm_appointment ON public.appointment_purchases;

CREATE TRIGGER trg_auto_confirm_appointment
BEFORE UPDATE OF status ON public.appointment_purchases
FOR EACH ROW
WHEN (NEW.status = 'pending_auto_payment'::appointment_status_enum)
EXECUTE FUNCTION public.auto_confirm_appointment();

COMMENT ON FUNCTION public.auto_confirm_appointment() IS 'Trigger function to automatically approve appointments when their status is set to pending_auto_payment by calling the approve_appointment_request function';
