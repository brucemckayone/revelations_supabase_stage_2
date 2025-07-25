-- Step 3: Add core credit booking functions

-- Function to check if a user can book an event with credits
CREATE OR REPLACE FUNCTION public.can_book_event_with_credits(
    p_user_id UUID,
    p_event_id UUID,
    p_ticket_id UUID,
    p_quantity INTEGER DEFAULT 1
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_package_purchase RECORD;
    v_event RECORD;
    v_ticket RECORD;
    v_credits_required INTEGER := 1;
    v_can_book BOOLEAN := false;
    v_result JSONB := '{}';
    v_available_packages JSONB := '[]';
    v_package_info JSONB;
BEGIN
    -- Get event and ticket details
    SELECT 
        e.*,
        p.user_id as creator_id,
        p.title as event_title
    INTO v_event
    FROM public.events e
    JOIN public.posts p ON e.post_id = p.id
    WHERE e.id = p_event_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('can_book', false, 'error', 'Event not found');
    END IF;
    
    SELECT * INTO v_ticket
    FROM public.tickets
    WHERE id = p_ticket_id AND event_id = p_event_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('can_book', false, 'error', 'Ticket not found');
    END IF;
    
    -- Check each active universal package purchase
    FOR v_package_purchase IN
        SELECT 
            upp.*,
            up.name as package_name
        FROM public.universal_package_purchases upp
        JOIN public.universal_packages up ON upp.package_id = up.id
        WHERE upp.user_id = p_user_id
        AND upp.is_active = true
        AND upp.event_credits_remaining > 0
        AND (upp.expires_at IS NULL OR upp.expires_at > NOW())
        ORDER BY upp.created_at ASC
    LOOP
        -- Default credits access
        IF v_package_purchase.event_credits_remaining >= v_credits_required * p_quantity THEN
            v_can_book := true;
        END IF;
        
        -- Add package to available options
        v_package_info := jsonb_build_object(
            'package_purchase_id', v_package_purchase.id,
            'package_name', v_package_purchase.package_name,
            'credits_remaining', v_package_purchase.event_credits_remaining,
            'credits_required', v_credits_required,
            'can_book', v_can_book
        );
        
        v_available_packages := v_available_packages || v_package_info;
        
        IF v_can_book THEN
            v_result := v_result || jsonb_build_object('can_book', true);
        END IF;
    END LOOP;
    
    -- Build final result
    v_result := v_result || jsonb_build_object(
        'available_packages', v_available_packages,
        'event_id', p_event_id,
        'ticket_id', p_ticket_id,
        'quantity', p_quantity
    );
    
    IF NOT (v_result ? 'can_book') THEN
        v_result := v_result || jsonb_build_object('can_book', false);
    END IF;
    
    RETURN v_result;
END;
$$; 