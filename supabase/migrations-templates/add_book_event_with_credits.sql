-- Function to book an event using universal credits
CREATE OR REPLACE FUNCTION public.book_event_with_credits(
    p_package_purchase_id UUID,
    p_event_id UUID,
    p_date_id UUID,
    p_ticket_id UUID,
    p_quantity INTEGER DEFAULT 1
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_package_purchase RECORD;
    v_ticket RECORD;
    v_credits_required INTEGER := 1;
    v_booking_result JSONB;
    v_booking_id UUID;
    v_purchase_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    -- Get package purchase details
    SELECT 
        upp.*,
        up.name as package_name
    INTO v_package_purchase
    FROM public.universal_package_purchases upp
    JOIN public.universal_packages up ON upp.package_id = up.id
    WHERE upp.id = p_package_purchase_id 
    AND upp.user_id = v_user_id
    AND upp.is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Package purchase not found or expired';
    END IF;
    
    -- Check if package is still valid
    IF v_package_purchase.expires_at IS NOT NULL AND v_package_purchase.expires_at < NOW() THEN
        RAISE EXCEPTION 'Package has expired';
    END IF;
    
    -- Check sufficient credits
    IF v_package_purchase.event_credits_remaining < v_credits_required * p_quantity THEN
        RAISE EXCEPTION 'Insufficient credits remaining. Required: %, Available: %', 
            v_credits_required * p_quantity, v_package_purchase.event_credits_remaining;
    END IF;
    
    -- Get ticket details for context
    SELECT * INTO v_ticket
    FROM public.tickets
    WHERE id = p_ticket_id;
    
    -- Create the event booking using existing function (but mark as completed/free)
    v_booking_result := public.create_event_purchase(
        p_event_id, p_ticket_id, p_date_id, p_quantity, 
        false, NULL, 'completed'
    );
    
    v_booking_id := (v_booking_result->>'booking_id')::UUID;
    v_purchase_id := (v_booking_result->>'purchase_id')::UUID;
    
    -- Update the purchase to reflect it was paid with credits
    UPDATE public.purchases
    SET 
        amount = 0, -- No charge since paid with credits
        metadata = COALESCE(metadata, '{}') || jsonb_build_object(
            'paid_with_credits', true,
            'package_purchase_id', p_package_purchase_id,
            'credits_used', v_credits_required * p_quantity,
            'original_ticket_price', v_ticket.price
        )
    WHERE id = v_purchase_id;
    
    -- Deduct credits from the package
    UPDATE public.universal_package_purchases
    SET 
        event_credits_remaining = event_credits_remaining - (v_credits_required * p_quantity),
        updated_at = NOW()
    WHERE id = p_package_purchase_id;
    
    -- Track the credit usage
    INSERT INTO public.universal_package_event_usage (
        package_purchase_id, event_booking_id, event_id, ticket_id,
        credits_used, original_ticket_price, ticket_quantity,
        usage_context
    ) VALUES (
        p_package_purchase_id, v_booking_id, p_event_id, p_ticket_id,
        v_credits_required * p_quantity, v_ticket.price, p_quantity,
        jsonb_build_object(
            'booking_method', 'universal_credits',
            'package_name', v_package_purchase.package_name
        )
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'booking_id', v_booking_id,
        'purchase_id', v_purchase_id,
        'credits_used', v_credits_required * p_quantity,
        'credits_remaining', v_package_purchase.event_credits_remaining - (v_credits_required * p_quantity),
        'original_ticket_price', v_ticket.price,
        'total_saved', v_ticket.price * p_quantity
    );
END;
$$; 