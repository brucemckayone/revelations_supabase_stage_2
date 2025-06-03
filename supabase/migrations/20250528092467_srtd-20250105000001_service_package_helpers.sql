-- Generated with srtd from template: supabase/migrations-templates/20250105000001_service_package_helpers.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Service Package Helper Functions
-- This migration adds helper functions for managing service packages

drop function if exists public.manage_service_package;

-- Function to create/update service packages
create or replace function public.manage_service_package(
    p_service_id uuid,
    p_name text,
    p_sessions_count integer,
    p_price numeric(10,2),
    p_booking_window_days integer default 7,
    p_package_id uuid default null,
    p_description text default null,
    p_duration_weeks integer default null,
    p_is_active boolean default true
) returns public.service_packages
language plpgsql
security definer
as $$
declare
    v_package public.service_packages;
    v_provider_id uuid;
begin
    v_provider_id := auth.uid();
    
    -- Verify the user owns this service
    if not exists (
        select 1 from public.services s
        join public.posts p on s.post_id = p.id
        where s.id = p_service_id and p.user_id = v_provider_id
    ) then
        raise exception 'Access denied: Not your service';
    end if;
    
    -- Validate inputs
    if p_sessions_count <= 0 then
        raise exception 'Sessions count must be positive';
    end if;
    
    if p_price <= 0 then
        raise exception 'Price must be positive';
    end if;
    
    if p_package_id is null then
        -- Create new package
        insert into public.service_packages (
            service_id, name, description, sessions_count, price,
            duration_weeks, booking_window_days, is_active
        ) values (
            p_service_id, p_name, p_description, p_sessions_count, p_price,
            p_duration_weeks, p_booking_window_days, p_is_active
        ) returning * into v_package;
    else
        -- Update existing package
        update public.service_packages
        set 
            name = p_name,
            description = p_description,
            sessions_count = p_sessions_count,
            price = p_price,
            duration_weeks = p_duration_weeks,
            booking_window_days = p_booking_window_days,
            is_active = p_is_active,
            updated_at = current_timestamp
        where id = p_package_id
        and service_id = p_service_id
        returning * into v_package;
        
        if not found then
            raise exception 'Package not found or access denied';
        end if;
    end if;
    
    return v_package;
end;
$$;

drop function if exists public.purchase_service_package;
-- Function to purchase a service package
create or replace function public.purchase_service_package(
    p_package_id uuid,
    p_amount numeric(10,2),
    p_stripe_payment_intent_id text default null,
    p_user_id uuid default null,
    p_currency text default 'usd'
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_package public.service_packages;
    v_purchase_id uuid;
    v_package_purchase_id uuid;
    v_expires_at timestamp with time zone;
begin
    v_user_id := coalesce(p_user_id, auth.uid());
    
    -- Get package details
    select * into v_package
    from public.service_packages
    where id = p_package_id and is_active = true;
    
    if not found then
        raise exception 'Package not found or not available';
    end if;
    
    -- Calculate expiration date
    if v_package.duration_weeks is not null then
        v_expires_at := current_timestamp + (v_package.duration_weeks || ' weeks')::interval;
    end if;
    
    -- Get service owner
    declare
        v_owner_id uuid;
    begin
        select p.user_id into v_owner_id
        from public.services s
        join public.posts p on s.post_id = p.id
        where s.id = v_package.service_id;
    end;
    
    -- Create purchase record
    insert into public.purchases (
        user_id, owner_id, stripe_payment_intent_id,
        amount, currency, payment_status,
        purchase_type, service_id,
        purchase_date, start_date, end_date
    ) values (
        v_user_id, v_owner_id, p_stripe_payment_intent_id,
        p_amount, p_currency, 'completed',
        'package', v_package.service_id,
        current_timestamp, current_timestamp, v_expires_at
    ) returning id into v_purchase_id;
    
    -- Create package purchase tracking
    insert into public.service_package_purchases (
        purchase_id, package_id, sessions_remaining, expires_at
    ) values (
        v_purchase_id, p_package_id, v_package.sessions_count, v_expires_at
    ) returning id into v_package_purchase_id;
    
    return jsonb_build_object(
        'purchase_id', v_purchase_id,
        'package_purchase_id', v_package_purchase_id,
        'sessions_remaining', v_package.sessions_count,
        'expires_at', v_expires_at
    );
end;
$$;

drop function if exists public.book_appointment_with_package;
-- Function to book appointment using package session
create or replace function public.book_appointment_with_package(
    p_service_id uuid,
    p_package_purchase_id uuid,
    p_appointment_date timestamp with time zone,
    p_duration interval default null,
    p_notes text default null,
    p_booking_workflow text default 'direct'
) returns public.appointments
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_appointment public.appointments;
    v_package_purchase public.service_package_purchases;
    v_service public.services;
begin
    v_user_id := auth.uid();
    
    -- Get package purchase details
    select spp.*, p.user_id
    into v_package_purchase
    from public.service_package_purchases spp
    join public.purchases p on spp.purchase_id = p.id
    where spp.id = p_package_purchase_id
    and p.user_id = v_user_id;
    
    if not found then
        raise exception 'Package purchase not found or access denied';
    end if;
    
    -- Check if package is expired
    if v_package_purchase.expires_at is not null and v_package_purchase.expires_at < current_timestamp then
        raise exception 'Package has expired';
    end if;
    
    -- Check if sessions remaining
    if v_package_purchase.sessions_remaining <= 0 then
        raise exception 'No sessions remaining in package';
    end if;
    
    -- Get service details
    select * into v_service
    from public.services
    where id = p_service_id;
    
    if not found then
        raise exception 'Service not found';
    end if;
    
    -- Use service duration if not specified
    if p_duration is null then
        p_duration := v_service.duration;
    end if;
    
    -- Create appointment
    insert into public.appointments (
        user_id, service_id, appointment_date, duration,
        status, booking_workflow, notes,
        package_purchase_id
    ) values (
        v_user_id, p_service_id, p_appointment_date, p_duration,
        case 
            when p_booking_workflow = 'direct' then 'confirmed'
            when p_booking_workflow = 'pre-approval' then 'pending_approval'
            else 'pending_approval'
        end,
        p_booking_workflow, p_notes,
        p_package_purchase_id
    ) returning * into v_appointment;
    
    -- Deduct session from package
    update public.service_package_purchases
    set 
        sessions_remaining = sessions_remaining - 1,
        updated_at = current_timestamp
    where id = p_package_purchase_id;
    
    return v_appointment;
end;
$$;

drop function if exists public.get_user_service_packages;
-- Function to get user's active packages for a service
create or replace function public.get_user_service_packages(
    p_service_id uuid,
    p_user_id uuid default null
) returns table (
    package_purchase_id uuid,
    package_name text,
    sessions_remaining integer,
    total_sessions integer,
    expires_at timestamp with time zone,
    purchase_date timestamp with time zone
)
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
begin
    v_user_id := coalesce(p_user_id, auth.uid());
    
    return query
    select 
        spp.id as package_purchase_id,
        sp.name as package_name,
        spp.sessions_remaining,
        sp.sessions_count as total_sessions,
        spp.expires_at,
        p.purchase_date
    from public.service_package_purchases spp
    join public.purchases p on spp.purchase_id = p.id
    join public.service_packages sp on spp.package_id = sp.id
    where sp.service_id = p_service_id
    and p.user_id = v_user_id
    and p.payment_status = 'completed'
    and spp.sessions_remaining > 0
    and (spp.expires_at is null or spp.expires_at > current_timestamp)
    order by spp.expires_at asc nulls last, p.purchase_date asc;
end;
$$;

drop function if exists public.get_package_usage_stats;
-- Function to get package usage statistics for providers
create or replace function public.get_package_usage_stats(
    p_service_id uuid,
    p_package_id uuid default null
) returns table (
    package_id uuid,
    package_name text,
    total_purchases integer,
    total_sessions_sold integer,
    sessions_used integer,
    sessions_remaining integer,
    revenue numeric(10,2),
    active_customers integer
)
language plpgsql
security definer
as $$
declare
    v_provider_id uuid;
begin
    v_provider_id := auth.uid();
    
    -- Verify ownership
    if not exists (
        select 1 from public.services s
        join public.posts p on s.post_id = p.id
        where s.id = p_service_id and p.user_id = v_provider_id
    ) then
        raise exception 'Access denied: Not your service';
    end if;
    
    return query
    select 
        sp.id as package_id,
        sp.name as package_name,
        count(distinct spp.id)::integer as total_purchases,
        sum(sp.sessions_count)::integer as total_sessions_sold,
        sum(sp.sessions_count - spp.sessions_remaining)::integer as sessions_used,
        sum(spp.sessions_remaining)::integer as sessions_remaining,
        sum(p.amount) as revenue,
        count(distinct case 
            when spp.sessions_remaining > 0 
            and (spp.expires_at is null or spp.expires_at > current_timestamp)
            then p.user_id 
        end)::integer as active_customers
    from public.service_packages sp
    left join public.service_package_purchases spp on sp.id = spp.package_id
    left join public.purchases p on spp.purchase_id = p.id and p.payment_status = 'completed'
    where sp.service_id = p_service_id
    and (p_package_id is null or sp.id = p_package_id)
    group by sp.id, sp.name
    order by sp.created_at;
end;
$$;

-- Add package_purchase_id to appointments table
alter table public.appointments 
add column if not exists package_purchase_id uuid references public.service_package_purchases(id) on delete set null;

-- Create index for better performance
create index if not exists idx_appointments_package_purchase_id on public.appointments(package_purchase_id);

-- Update the appointment booking function to handle package sessions
drop function if exists public.create_appointment_request;
create or replace function public.create_appointment_request(
    p_service_id uuid,
    p_appointment_date timestamp with time zone,
    p_duration interval default null,
    p_notes text default null,
    p_package_purchase_id uuid default null
) returns public.appointments
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_service public.services;
    v_appointment public.appointments;
    v_booking_workflow text;
    v_auto_confirm boolean;
    v_package_purchase public.service_package_purchases;
begin
    v_user_id := auth.uid();
    
    -- Get service details
    select s.*, p.user_id as owner_id
    into v_service
    from public.services s
    join public.posts p on s.post_id = p.id
    where s.id = p_service_id;
    
    if not found then
        raise exception 'Service not found';
    end if;
    
    -- If using package session, validate it
    if p_package_purchase_id is not null then
        select spp.*, p.user_id
        into v_package_purchase
        from public.service_package_purchases spp
        join public.purchases p on spp.purchase_id = p.id
        where spp.id = p_package_purchase_id
        and p.user_id = v_user_id;
        
        if not found then
            raise exception 'Package purchase not found or access denied';
        end if;
        
        if v_package_purchase.expires_at is not null and v_package_purchase.expires_at < current_timestamp then
            raise exception 'Package has expired';
        end if;
        
        if v_package_purchase.sessions_remaining <= 0 then
            raise exception 'No sessions remaining in package';
        end if;
    end if;
    
    -- Use service duration if not specified
    if p_duration is null then
        p_duration := v_service.duration;
    end if;
    
    -- Determine booking workflow and status
    v_booking_workflow := v_service.booking_workflow;
    v_auto_confirm := v_service.auto_confirm;
    
    -- Create appointment with appropriate status
    insert into public.appointments (
        user_id, service_id, appointment_date, duration,
        status, booking_workflow, notes, package_purchase_id
    ) values (
        v_user_id, p_service_id, p_appointment_date, p_duration,
        case 
            when v_booking_workflow = 'direct' and v_auto_confirm then 'confirmed'
            when v_booking_workflow = 'direct' then 'pending_payment'
            when v_booking_workflow = 'pre-approval' then 'pending_approval'
            when v_booking_workflow = 'waitlist' then 'pending_approval'
            else 'pending_approval'
        end,
        v_booking_workflow, p_notes, p_package_purchase_id
    ) returning * into v_appointment;
    
    -- If using package session and confirmed, deduct session
    if p_package_purchase_id is not null and v_appointment.status = 'confirmed' then
        update public.service_package_purchases
        set 
            sessions_remaining = sessions_remaining - 1,
            updated_at = current_timestamp
        where id = p_package_purchase_id;
    end if;
    
    return v_appointment;
end;
$$;

-- Grant permissions
grant execute on function public.manage_service_package(uuid, text, integer, numeric, integer, uuid, text, integer, boolean) to authenticated, service_role;
grant execute on function public.purchase_service_package(uuid, numeric, text, uuid, text) to authenticated, service_role;
grant execute on function public.book_appointment_with_package(uuid, uuid, timestamp with time zone, interval, text, text) to authenticated, service_role;
grant execute on function public.get_user_service_packages(uuid, uuid) to authenticated, service_role;
grant execute on function public.get_package_usage_stats(uuid, uuid) to authenticated, service_role;
grant execute on function public.create_appointment_request(uuid, timestamp with time zone, interval, text, uuid) to authenticated, service_role;

-- Add comments
comment on function public.manage_service_package(uuid, text, integer, numeric, integer, uuid, text, integer, boolean) is 'Create or update service packages';
comment on function public.purchase_service_package(uuid, numeric, text, uuid, text) is 'Purchase a service package';
comment on function public.book_appointment_with_package(uuid, uuid, timestamp with time zone, interval, text, text) is 'Book appointment using package session';
comment on function public.get_user_service_packages(uuid, uuid) is 'Get user active packages for a service';
comment on function public.get_package_usage_stats(uuid, uuid) is 'Get package usage statistics for providers';
comment on function public.create_appointment_request(uuid, timestamp with time zone, interval, text, uuid) is 'Create appointment request with optional package session'; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
