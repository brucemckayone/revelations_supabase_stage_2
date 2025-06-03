-- Generated with srtd from template: supabase/migrations-templates/2025060600006_package_purchase_webhook_function.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Function to process package purchase payment (for webhook processing)
-- This function is called after a purchase record already exists and payment is confirmed
drop function if exists public.process_package_purchase_payment;
create or replace function public.process_package_purchase_payment(
    p_purchase_id uuid,
    p_payment_intent_id text,
    p_package_id uuid,
    p_service_id uuid
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_purchase public.purchases;
    v_package public.service_packages;
    v_package_purchase_id uuid;
    v_expires_at timestamp with time zone;
    v_result jsonb;
begin
    -- Get and validate purchase record
    select * into v_purchase
    from public.purchases
    where id = p_purchase_id
    and stripe_payment_intent_id = p_payment_intent_id
    and payment_status = 'completed';
    
    if not found then
        raise exception 'Purchase not found or not completed: purchase_id=%, payment_intent=%', 
            p_purchase_id, p_payment_intent_id;
    end if;
    
    -- Get package details
    select * into v_package
    from public.service_packages
    where id = p_package_id 
    and service_id = p_service_id
    and is_active = true;
    
    if not found then
        raise exception 'Package not found or not active: package_id=%, service_id=%', 
            p_package_id, p_service_id;
    end if;
    
    -- Validate that this purchase is for the correct service
    if v_purchase.service_id != p_service_id then
        raise exception 'Purchase service_id mismatch: expected=%, actual=%', 
            p_service_id, v_purchase.service_id;
    end if;
    
    -- Calculate expiration date
    if v_package.duration_weeks is not null then
        v_expires_at := current_timestamp + (v_package.duration_weeks || ' weeks')::interval;
    end if;
    
    -- Update purchase record with package-specific details
    update public.purchases
    set 
        purchase_type = 'package',
        end_date = v_expires_at,
        updated_at = current_timestamp
    where id = p_purchase_id;
    
    -- Create package purchase tracking record
    insert into public.service_package_purchases (
        purchase_id, 
        package_id, 
        sessions_remaining, 
        expires_at
    ) values (
        p_purchase_id, 
        p_package_id, 
        v_package.sessions_count, 
        v_expires_at
    ) returning id into v_package_purchase_id;
    
    -- Build result
    v_result := jsonb_build_object(
        'success', true,
        'purchase_id', p_purchase_id,
        'package_purchase_id', v_package_purchase_id,
        'package_id', p_package_id,
        'service_id', p_service_id,
        'sessions_remaining', v_package.sessions_count,
        'sessions_total', v_package.sessions_count,
        'expires_at', v_expires_at,
        'package_name', v_package.name,
        'package_description', v_package.description,
        'user_id', v_purchase.user_id,
        'owner_id', v_purchase.owner_id,
        'amount', v_purchase.amount,
        'currency', v_purchase.currency
    );
    
    return v_result;
end;
$$;




drop type if exists package_purchase_payment_result;
-- Create return type for process_package_purchase_payment function
create  type package_purchase_payment_result as (
    success boolean,
    purchase_id text,
    package_purchase_id text,
    package_id text,
    service_id text,
    sessions_remaining integer,
    sessions_total integer,
    expires_at timestamptz,
    package_name text,
    package_description text,
    user_id text,
    owner_id text,
    amount integer,
    currency text
);

-- Grant permissions
grant execute on function public.process_package_purchase_payment(uuid, text, uuid, uuid) to authenticated, service_role;

-- Add comment
comment on function public.process_package_purchase_payment(uuid, text, uuid, uuid) is 'Process package purchase after payment confirmation (webhook handler)'; 


COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
