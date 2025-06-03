-- Generated with srtd from template: supabase/migrations-templates/20250107000011_dual_purchase_options_enhancement.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Enhancement: Dual Purchase Options for Universal Packages
-- Allows packages to be offered as both one-time purchases AND recurring subscriptions

-- ====================================
-- RETURN TYPES
-- ====================================

-- Enhanced package creation result
drop type if exists create_universal_package_result cascade;
create type create_universal_package_result as (
    package_id uuid
);


-- Drop and recreate with purchase option support
drop type if exists package_pricing_options_result cascade;

-- Return type for pricing options
create type package_pricing_options_result as (
    package_id uuid,
    pricing_options jsonb
);

-- ====================================
-- ALTER UNIVERSAL PACKAGES TABLE
-- ====================================

-- Add new columns for dual purchase support
alter table public.universal_packages 
add column if not exists supports_one_time_purchase boolean not null default true;

alter table public.universal_packages 
add column if not exists supports_recurring_purchase boolean not null default false;

alter table public.universal_packages 
add column if not exists one_time_price numeric(10,2) check (one_time_price >= 0);

alter table public.universal_packages 
add column if not exists recurring_price numeric(10,2) check (recurring_price >= 0);

alter table public.universal_packages 
add column if not exists one_time_duration_weeks integer check (one_time_duration_weeks > 0);

alter table public.universal_packages 
add column if not exists recurring_billing_interval interval not null default '1 month';
-- Add constraint to ensure at least one purchase type is supported
alter table public.universal_packages
drop constraint if exists check_purchase_type_support;

alter table public.universal_packages
add constraint check_purchase_type_support 
check (supports_one_time_purchase = true or supports_recurring_purchase = true);

alter table public.universal_packages
drop constraint if exists check_one_time_pricing;

-- Add constraint to ensure pricing is set for supported purchase types
alter table public.universal_packages
add constraint check_one_time_pricing 
check (
    (supports_one_time_purchase = false) or 
    (supports_one_time_purchase = true and one_time_price is not null and one_time_duration_weeks is not null)
);

alter table public.universal_packages
drop constraint if exists check_recurring_pricing;

alter table public.universal_packages 
add constraint check_recurring_pricing 
check (
    (supports_recurring_purchase = false) or 
    (supports_recurring_purchase = true and recurring_price is not null)
);


-- ====================================
-- UPDATE UNIVERSAL PACKAGE PURCHASES TABLE
-- ====================================



-- Add purchase type tracking to purchases
do $$ begin
    create type purchase_option_enum as enum (
        'one_time',
        'recurring'
    );
exception
    when duplicate_object then null;
end $$;

alter table public.universal_package_purchases 
add column if not exists purchase_option purchase_option_enum not null default 'one_time';

-- ====================================
-- ENHANCED CREATE PACKAGE FUNCTION
-- ====================================

drop function if exists public.create_universal_package;
create or replace function public.create_universal_package(
    p_name text,
    p_description text default null,
    p_package_type package_access_type_enum default 'custom_bundle',
    
    -- Dual pricing options
    p_supports_one_time_purchase boolean default true,
    p_supports_recurring_purchase boolean default false,
    p_one_time_price numeric default null,
    p_recurring_price numeric default null,
    p_one_time_duration_weeks integer default null,
    p_recurring_billing_interval interval default '1 month',
    
    p_currency text default 'usd',
    p_appointment_credits integer default 0,
    p_content_credits integer default 0,
    p_event_credits integer default 0,
    p_post_credits integer default 0,
    p_is_active boolean default true,
    p_requires_approval boolean default false,
    p_availability_start timestamp default null,
    p_availability_end timestamp default null,
    p_max_purchases integer default null,
    p_purchase_limit_per_user integer default null
) returns create_universal_package_result
language plpgsql
security definer
as $$
declare
    v_package_id uuid;
    v_user_id uuid;
    v_final_price numeric;
    v_final_duration integer;
    v_final_recurring boolean;
begin
    v_user_id := auth.uid();
    
    if v_user_id is null then
        raise exception 'Authentication required';
    end if;

    -- Validate at least one purchase type is supported
    if not p_supports_one_time_purchase and not p_supports_recurring_purchase then
        raise exception 'Package must support at least one purchase type';
    end if;

    -- Validate one-time purchase settings
    if p_supports_one_time_purchase then
        if p_one_time_price is null or p_one_time_duration_weeks is null then
            raise exception 'One-time purchase requires price and duration';
        end if;
    end if;

    -- Validate recurring purchase settings
    if p_supports_recurring_purchase then
        if p_recurring_price is null then
            raise exception 'Recurring purchase requires price';
        end if;
    end if;

    -- Set legacy fields for backward compatibility
    -- Default to one-time if both are supported, recurring if only recurring
    if p_supports_recurring_purchase and not p_supports_one_time_purchase then
        v_final_recurring := true;
        v_final_price := p_recurring_price;
        v_final_duration := 4; -- Default 4 weeks for recurring
    else
        v_final_recurring := false;
        v_final_price := coalesce(p_one_time_price, p_recurring_price);
        v_final_duration := coalesce(p_one_time_duration_weeks, 4);
    end if;

    insert into public.universal_packages (
        creator_id,
        name,
        description,
        package_type,
        
        -- Legacy fields (for backward compatibility)
        price,
        duration_weeks,
        is_recurring,
        
        -- New dual purchase fields
        supports_one_time_purchase,
        supports_recurring_purchase,
        one_time_price,
        recurring_price,
        one_time_duration_weeks,
        recurring_billing_interval,
        
        currency,
        appointment_credits,
        content_credits,
        event_credits,
        post_credits,
        is_active,
        requires_approval,
        availability_start,
        availability_end,
        max_purchases,
        purchase_limit_per_user
    ) values (
        v_user_id,
        p_name,
        p_description,
        p_package_type,
        
        -- Legacy fields
        v_final_price,
        v_final_duration,
        v_final_recurring,
        
        -- New dual purchase fields
        p_supports_one_time_purchase,
        p_supports_recurring_purchase,
        p_one_time_price,
        p_recurring_price,
        p_one_time_duration_weeks,
        p_recurring_billing_interval,
        
        p_currency,
        p_appointment_credits,
        p_content_credits,
        p_event_credits,
        p_post_credits,
        p_is_active,
        p_requires_approval,
        p_availability_start,
        p_availability_end,
        p_max_purchases,
        p_purchase_limit_per_user
    ) returning id into v_package_id;

    return (v_package_id);
exception
    when others then
        raise exception 'Error creating universal package: %', sqlerrm;
end;
$$;

-- ====================================
-- ENHANCED PURCHASE FUNCTION
-- ====================================

-- Drop and recreate with purchase option support
drop function if exists public.purchase_universal_package;


-- Create missing types for package purchases
drop type if exists purchase_universal_package_result cascade;
create type purchase_universal_package_result as (
    success boolean,
    purchase_id uuid,
    package_purchase_id uuid,
    package_id uuid,
    expires_at timestamp with time zone,
    appointment_credits integer,
    content_credits integer,
    event_credits integer
);

create or replace function public.purchase_universal_package(
    p_package_id uuid,
    p_purchase_option purchase_option_enum, -- NEW: Specify which purchase type
    p_purchase_id uuid default null,
    p_user_id uuid default null
) returns purchase_universal_package_result
language plpgsql
security definer
as $$
declare
    v_package record;
    v_user_id uuid;
    v_purchase_id uuid;
    v_package_purchase_id uuid;
    v_expires_at timestamptz;
    v_final_price numeric;
    v_next_billing_date timestamptz;
begin
    -- Get user ID
    if p_user_id is null then
        v_user_id := auth.uid();
    else
        v_user_id := p_user_id;
    end if;

    if v_user_id is null then
        raise exception 'Authentication required';
    end if;

    -- Get package details with dual purchase support
    select * into v_package
    from public.universal_packages
    where id = p_package_id and is_active = true;

    if not found then
        raise exception 'Package not found or inactive';
    end if;

    -- Validate purchase option is supported
    if p_purchase_option = 'one_time' and not v_package.supports_one_time_purchase then
        raise exception 'Package does not support one-time purchases';
    end if;

    if p_purchase_option = 'recurring' and not v_package.supports_recurring_purchase then
        raise exception 'Package does not support recurring purchases';
    end if;

    -- Set pricing and duration based on purchase option
    if p_purchase_option = 'one_time' then
        v_final_price := v_package.one_time_price;
        v_expires_at := now() + (v_package.one_time_duration_weeks || ' weeks')::interval;
        v_next_billing_date := null;
    else -- recurring
        v_final_price := v_package.recurring_price;
        v_expires_at := now() + v_package.recurring_billing_interval;
        v_next_billing_date := now() + v_package.recurring_billing_interval;
    end if;

    -- Create or get purchase record
    if p_purchase_id is null then
        insert into public.purchases (
            user_id,
            service_id,
            amount,
            currency,
            status,
            type,
            created_at
        ) values (
            v_user_id,
            null, -- No specific service for packages
            v_final_price,
            v_package.currency,
            'completed',
            'package',
            now()
        ) returning id into v_purchase_id;
    else
        v_purchase_id := p_purchase_id;
        
        -- Update existing purchase with correct amount
        update public.purchases
        set amount = v_final_price,
            type = 'package',
            status = 'completed'
        where id = v_purchase_id;
    end if;

    -- Create package purchase record with purchase option
    insert into public.universal_package_purchases (
        purchase_id,
        package_id,
        user_id,
        purchase_option, -- NEW: Track which purchase type was chosen
        appointment_credits_remaining,
        content_credits_remaining,
        event_credits_remaining,
        post_credits_remaining,
        expires_at,
        next_billing_date,
        is_active
    ) values (
        v_purchase_id,
        p_package_id,
        v_user_id,
        p_purchase_option,
        v_package.appointment_credits,
        v_package.content_credits,
        v_package.event_credits,
        v_package.post_credits,
        v_expires_at,
        v_next_billing_date,
        true
    ) returning id into v_package_purchase_id;

    return (
        true, -- success
        v_purchase_id,
        v_package_purchase_id,
        p_package_id,
        v_expires_at,
        v_package.appointment_credits,
        v_package.content_credits,
        v_package.event_credits
    );
exception
    when others then
        raise exception 'Error purchasing universal package: %', sqlerrm;
end;
$$;

-- ====================================
-- CONVENIENCE FUNCTIONS
-- ====================================

-- Get package pricing options for display
create or replace function public.get_package_pricing_options(
    p_package_id uuid
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_package record;
    v_result jsonb := '{}';
begin
    select 
        supports_one_time_purchase,
        supports_recurring_purchase,
        one_time_price,
        recurring_price,
        one_time_duration_weeks,
        recurring_billing_interval,
        currency
    into v_package
    from public.universal_packages
    where id = p_package_id and is_active = true;

    if not found then
        return '{"error": "Package not found"}';
    end if;

    -- Build pricing options
    if v_package.supports_one_time_purchase then
        v_result := jsonb_set(v_result, '{one_time}', jsonb_build_object(
            'available', true,
            'price', v_package.one_time_price,
            'duration_weeks', v_package.one_time_duration_weeks,
            'currency', v_package.currency
        ));
    else
        v_result := jsonb_set(v_result, '{one_time}', '{"available": false}');
    end if;

    if v_package.supports_recurring_purchase then
        v_result := jsonb_set(v_result, '{recurring}', jsonb_build_object(
            'available', true,
            'price', v_package.recurring_price,
            'billing_interval', extract(epoch from v_package.recurring_billing_interval),
            'currency', v_package.currency
        ));
    else
        v_result := jsonb_set(v_result, '{recurring}', '{"available": false}');
    end if;

    return v_result;
end;
$$;

-- ====================================
-- GRANTS & PERMISSIONS
-- ====================================

grant execute on function public.create_universal_package
 to authenticated, service_role;

grant execute on function public.purchase_universal_package(uuid, purchase_option_enum, uuid, uuid) to authenticated, service_role;
grant execute on function public.get_package_pricing_options(uuid) to authenticated, service_role;

grant usage on type purchase_option_enum to authenticated, service_role;
grant usage on type package_pricing_options_result to authenticated, service_role;
grant usage on type create_universal_package_result to authenticated, service_role;

-- ====================================
-- COMMENTS
-- ====================================

comment on function public.create_universal_package is 'Create universal package with dual purchase options (one-time and/or recurring)';

comment on function public.purchase_universal_package(uuid, purchase_option_enum, uuid, uuid) 
is 'Purchase universal package with specified purchase option (one-time or recurring)';

comment on function public.get_package_pricing_options(uuid) 
is 'Get available pricing options for a package (one-time and/or recurring)';

comment on column public.universal_packages.supports_one_time_purchase 
is 'Whether this package can be purchased as a one-time payment';

comment on column public.universal_packages.supports_recurring_purchase 
is 'Whether this package can be purchased as a recurring subscription';

comment on column public.universal_package_purchases.purchase_option 
is 'Which purchase option was chosen (one_time or recurring)'; 



COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
