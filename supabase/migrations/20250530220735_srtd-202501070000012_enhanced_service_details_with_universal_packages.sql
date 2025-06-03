-- Generated with srtd from template: supabase/migrations-templates/202501070000012_enhanced_service_details_with_universal_packages.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Enhanced Service Details with Universal Packages
-- This function returns complete service information including associated universal packages

-- ====================================
-- DROP EXISTING FUNCTIONS AND TYPES (IDEMPOTENT)
-- ====================================



-- Drop functions first
drop function if exists public.get_service_details_with_packages(text);
drop function if exists public.get_service_packages(text);
drop function if exists public.get_comprehensive_service_details(text, uuid);
drop function if exists public.build_package_detail(uuid, text, text, text, text, boolean, boolean, integer, text, integer, boolean, numeric, integer, boolean, numeric, bigint, integer, integer, integer, integer);

-- Drop types
drop type if exists service_details_with_packages_result cascade;
drop type if exists service_details_result cascade;
drop type if exists service_packages_result cascade;
drop type if exists comprehensive_service_details_result cascade;

-- Drop composite types for structured data
drop type if exists universal_package_detail cascade;
drop type if exists package_pricing_options cascade;
drop type if exists package_pricing_option cascade;
drop type if exists package_recurring_pricing_option cascade;
drop type if exists package_credits cascade;
drop type if exists package_service_access cascade;
drop type if exists user_appointment_detail cascade;
drop type if exists user_credits_summary cascade;
drop type if exists user_upcoming_appointment cascade;
drop type if exists user_package_purchase_detail cascade;
drop type if exists user_package_credits_remaining cascade;
drop type if exists user_package_service_access cascade;

-- ====================================
-- CREATE RETURN TYPES
-- ====================================

-- Package pricing option types
create type package_pricing_option as (
    available boolean,
    price numeric,
    duration_weeks integer,
    currency text
);

create type package_recurring_pricing_option as (
    available boolean,
    price numeric,
    billing_interval bigint,
    currency text
);

create type package_pricing_options as (
    one_time package_pricing_option,
    recurring package_recurring_pricing_option
);

create type package_credits as (
    appointments integer,
    content integer,
    events integer,
    posts integer
);

create type package_service_access as (
    access_type text,
    credits_required integer,
    priority integer
);

-- Main package type
create type universal_package_detail as (
    id uuid,
    name text,
    description text,
    package_type text,
    currency text,
    pricing_options package_pricing_options,
    credits package_credits,
    service_access package_service_access,
    is_featured boolean,
    is_active boolean,
    credits_required integer,
    access_type text,
    appointment_credits integer
);

-- User appointment type
create type user_appointment_detail as (
    id uuid,
    start_time timestamptz,
    end_time timestamptz,
    status text,
    booking_type text,
    package_purchase_id uuid,
    created_at timestamptz
);

-- User package purchase type
create type user_package_purchase_detail as (
    id uuid,
    package_id uuid,
    package_name text,
    purchase_option text,
    status text,
    expires_at timestamptz,
    is_recurring boolean,
    current_period_start timestamptz,
    current_period_end timestamptz,
    appointment_credits_remaining integer,
    content_credits_remaining integer,
    event_credits_remaining integer,
    access_type text,
    credits_required integer
);

-- User credits summary type
create type user_credits_summary as (
    total_appointment_credits integer,
    total_content_credits integer,
    total_event_credits integer,
    active_packages integer
);

-- User upcoming appointment type
create type user_upcoming_appointment as (
    id uuid,
    start_time timestamptz,
    end_time timestamptz,
    status text,
    package_purchase_id uuid
);

-- ====================================
-- COMPREHENSIVE SERVICE DETAILS FUNCTION
-- ====================================

create or replace function public.get_comprehensive_service_details(
    p_service_slug text,
    p_user_id uuid default null
) returns table (
    service_id uuid,
    service_slug text,
    service_title text,
    service_description text,
    service_content text,
    service_price numeric,
    service_duration interval,
    service_type event_type_enum,
    service_capacity integer,
    service_current_bookings integer,
    service_auto_confirm boolean,
    service_booking_workflow text,
    service_thumbnail_url text,
    service_tags text[],
    service_status text,
    creator_id uuid,
    creator_name text,
    creator_avatar_url text,
    creator_username text,
    location_id uuid,
    location_name text,
    location_address text,
    associated_packages universal_package_detail[],
    user_appointments user_appointment_detail[],
    user_package_purchases user_package_purchase_detail[],
    user_available_credits user_credits_summary,
    user_can_access_service boolean,
    user_upcoming_appointments user_upcoming_appointment[]
)
language plpgsql
security definer
as $$
declare
    v_service_id uuid;
    v_service_slug text;
    v_service_title text;
    v_service_description text;
    v_service_content text;
    v_service_price numeric;
    v_service_duration interval;
    v_service_type event_type_enum;
    v_service_capacity integer;
    v_service_current_bookings integer;
    v_service_auto_confirm boolean;
    v_service_booking_workflow text;
    v_service_thumbnail_url text;
    v_service_tags text[];
    v_service_status text;
    v_creator_id uuid;
    v_creator_name text;
    v_creator_avatar_url text;
    v_creator_username text;
    v_location_id uuid;
    v_location_name text;
    v_location_address text;
    v_packages universal_package_detail[] := array[]::universal_package_detail[];
    v_user_appointments user_appointment_detail[] := array[]::user_appointment_detail[];
    v_user_purchases user_package_purchase_detail[] := array[]::user_package_purchase_detail[];
    v_user_credits user_credits_summary;
    v_upcoming_appointments user_upcoming_appointment[] := array[]::user_upcoming_appointment[];
    v_can_access boolean := false;
    v_appointment_record record;
    v_purchase_record record;
    v_upcoming_record record;
    v_package_record record;
    v_appointment user_appointment_detail;
    v_purchase user_package_purchase_detail;
    v_upcoming user_upcoming_appointment;
    v_package universal_package_detail;
begin
    -- Get service details
    select 
        s.id,
        p.slug,
        p.title,
        p.description,
        s.content,
        s.price,
        s.duration,
        s.type,
        s.capacity,
        s.current_bookings,
        s.auto_confirm,
        s.booking_workflow,
        p.thumbnail_url,
        array_agg(distinct t.name) filter (where t.name is not null) as tags,
        p.status,
        
        -- Creator info (fixed to use profiles table)
        p.user_id,
        coalesce(prof.full_name, prof.username, split_part(au.email, '@', 1)) as creator_name,
        prof.avatar_url,
        prof.username,
        
        -- Location info (fixed address concatenation)
        s.location_id,
        l.name,
        concat_ws(', ', l.line_1, l.line_2, l.city, l.country, l.postcode) as full_address
    into 
        v_service_id,
        v_service_slug,
        v_service_title,
        v_service_description,
        v_service_content,
        v_service_price,
        v_service_duration,
        v_service_type,
        v_service_capacity,
        v_service_current_bookings,
        v_service_auto_confirm,
        v_service_booking_workflow,
        v_service_thumbnail_url,
        v_service_tags,
        v_service_status,
        v_creator_id,
        v_creator_name,
        v_creator_avatar_url,
        v_creator_username,
        v_location_id,
        v_location_name,
        v_location_address
    from services s
    join posts p on s.post_id = p.id
    join auth.users au on p.user_id = au.id
    left join public.profiles prof on p.user_id = prof.id
    left join locations l on s.location_id = l.id
    left join post_tags pt on p.id = pt.post_id
    left join tags t on pt.tag_id = t.id
    where p.slug = p_service_slug
      and p.status = 'public'
    group by 
        s.id, p.slug, p.title, p.description, s.content, s.price, s.duration,
        s.type, s.capacity, s.current_bookings, s.auto_confirm, s.booking_workflow,
        p.thumbnail_url, p.status, p.user_id, prof.full_name, prof.username, 
        prof.avatar_url, au.email, s.location_id, l.name, l.line_1, l.line_2, 
        l.city, l.country, l.postcode;

    -- Check if service was found
    if v_service_id is null then
        raise exception 'Service not found or not public: %', p_service_slug;
    end if;

    -- Get associated universal packages
    for v_package_record in
        select 
            up.id,
            up.name,
            up.description,
            up.package_type::text,
            up.currency,
            up.is_featured,
            up.is_active,
            par.credits_required,
            par.access_type::text,
            up.total_appointment_credits,
            up.total_content_credits,
            up.total_event_credits,
            up.supports_one_time_purchase,
            up.one_time_price,
            up.one_time_duration_weeks,
            up.supports_recurring_purchase,
            up.recurring_price,
            extract(epoch from up.recurring_billing_interval)::bigint as recurring_billing_interval_seconds,
            par.priority
        from universal_packages up
        join package_access_rules par on up.id = par.package_id
        where par.service_id = v_service_id
          and up.is_active = true
        order by par.priority desc, up.is_featured desc, up.created_at asc
    loop
        -- Build the composite type structure
        v_package.id := v_package_record.id;
        v_package.name := v_package_record.name;
        v_package.description := v_package_record.description;
        v_package.package_type := v_package_record.package_type;
        v_package.currency := v_package_record.currency;
        
        -- Build pricing options
        v_package.pricing_options.one_time.available := v_package_record.supports_one_time_purchase;
        v_package.pricing_options.one_time.price := v_package_record.one_time_price;
        v_package.pricing_options.one_time.duration_weeks := v_package_record.one_time_duration_weeks;
        v_package.pricing_options.one_time.currency := v_package_record.currency;
        
        v_package.pricing_options.recurring.available := v_package_record.supports_recurring_purchase;
        v_package.pricing_options.recurring.price := v_package_record.recurring_price;
        v_package.pricing_options.recurring.billing_interval := v_package_record.recurring_billing_interval_seconds;
        v_package.pricing_options.recurring.currency := v_package_record.currency;
        
        -- Build credits
        v_package.credits.appointments := v_package_record.total_appointment_credits;
        v_package.credits.content := v_package_record.total_content_credits;
        v_package.credits.events := v_package_record.total_event_credits;
        v_package.credits.posts := 0; -- Not available, default to 0
        
        -- Build service access
        v_package.service_access.access_type := v_package_record.access_type;
        v_package.service_access.credits_required := v_package_record.credits_required;
        v_package.service_access.priority := v_package_record.priority;
        
        -- Set display flags and backwards compatibility
        v_package.is_featured := v_package_record.is_featured;
        v_package.is_active := v_package_record.is_active;
        v_package.credits_required := v_package_record.credits_required;
        v_package.access_type := v_package_record.access_type;
        v_package.appointment_credits := v_package_record.total_appointment_credits;
        
        -- Add to array
        v_packages := v_packages || v_package;
    end loop;

    -- If user_id provided, get user-specific information
    if p_user_id is not null then
        -- Get user's past appointments for this service
        for v_appointment_record in
            select 
                a.id,
                a.start_time,
                a.end_time,
                a.status,
                a.created_at,
                a.package_purchase_id,
                case when a.package_purchase_id is not null then 'package' else 'individual' end as booking_type
            from appointments a
            join services s on a.facilitator_id = v_creator_id
            where a.client_id = p_user_id
              and s.id = v_service_id
            order by a.start_time desc
            limit 10
        loop
            -- Build appointment composite type
            v_appointment.id := v_appointment_record.id;
            v_appointment.start_time := v_appointment_record.start_time;
            v_appointment.end_time := v_appointment_record.end_time;
            v_appointment.status := v_appointment_record.status;
            v_appointment.booking_type := v_appointment_record.booking_type;
            v_appointment.package_purchase_id := v_appointment_record.package_purchase_id;
            v_appointment.created_at := v_appointment_record.created_at;
            
            v_user_appointments := v_user_appointments || v_appointment;
        end loop;

        -- Get user's upcoming appointments for this service
        for v_upcoming_record in
            select 
                a.id,
                a.start_time,
                a.end_time,
                a.status,
                a.package_purchase_id
            from appointments a
            join services s on a.facilitator_id = v_creator_id
            where a.client_id = p_user_id
              and s.id = v_service_id
              and a.start_time > now()
              and a.status in ('confirmed', 'pending')
            order by a.start_time asc
        loop
            -- Build upcoming appointment composite type
            v_upcoming.id := v_upcoming_record.id;
            v_upcoming.start_time := v_upcoming_record.start_time;
            v_upcoming.end_time := v_upcoming_record.end_time;
            v_upcoming.status := v_upcoming_record.status;
            v_upcoming.package_purchase_id := v_upcoming_record.package_purchase_id;
            
            v_upcoming_appointments := v_upcoming_appointments || v_upcoming;
        end loop;

        -- Get user's package purchases that can access this service
        for v_purchase_record in
            select 
                upp.id,
                upp.package_id,
                up.name as package_name,
                upp.purchase_option,
                upp.appointment_credits_remaining,
                upp.content_credits_remaining,
                upp.event_credits_remaining,
                upp.status,
                upp.expires_at,
                upp.current_period_start,
                upp.current_period_end,
                upp.is_recurring,
                par.access_type,
                par.credits_required
            from universal_package_purchases upp
            join universal_packages up on upp.package_id = up.id
            join package_access_rules par on up.id = par.package_id
            join purchases pur on upp.purchase_id = pur.id
            where pur.user_id = p_user_id
              and par.service_id = v_service_id
              and upp.status = 'active'
              and (upp.expires_at is null or upp.expires_at > now())
            order by upp.created_at desc
        loop
            -- Build purchase composite type  
            v_purchase.id := v_purchase_record.id;
            v_purchase.package_id := v_purchase_record.package_id;
            v_purchase.package_name := v_purchase_record.package_name;
            v_purchase.purchase_option := v_purchase_record.purchase_option;
            v_purchase.status := v_purchase_record.status;
            v_purchase.expires_at := v_purchase_record.expires_at;
            v_purchase.is_recurring := v_purchase_record.is_recurring;
            v_purchase.current_period_start := v_purchase_record.current_period_start;
            v_purchase.current_period_end := v_purchase_record.current_period_end;
            v_purchase.appointment_credits_remaining := v_purchase_record.appointment_credits_remaining;
            v_purchase.content_credits_remaining := v_purchase_record.content_credits_remaining;
            v_purchase.event_credits_remaining := v_purchase_record.event_credits_remaining;
            v_purchase.access_type := v_purchase_record.access_type;
            v_purchase.credits_required := v_purchase_record.credits_required;
            
            v_user_purchases := v_user_purchases || v_purchase;

            -- Check if user can access this service
            if v_purchase_record.access_type = 'unlimited' or 
               (v_purchase_record.access_type = 'pay_per_use' and 
                v_purchase_record.appointment_credits_remaining >= v_purchase_record.credits_required) then
                v_can_access := true;
            end if;
        end loop;

        -- Calculate total available credits
        select 
            coalesce(sum(appointment_credits_remaining), 0),
            coalesce(sum(content_credits_remaining), 0),
            coalesce(sum(event_credits_remaining), 0),
            count(*)
        into 
            v_user_credits.total_appointment_credits,
            v_user_credits.total_content_credits,
            v_user_credits.total_event_credits,
            v_user_credits.active_packages
        from universal_package_purchases upp
        join package_access_rules par on upp.package_id = par.package_id
        join purchases pur on upp.purchase_id = pur.id
        where pur.user_id = p_user_id
          and par.service_id = v_service_id
          and upp.status = 'active'
          and (upp.expires_at is null or upp.expires_at > now());
    end if;

    return query select
        v_service_id,
        v_service_slug,
        v_service_title,
        v_service_description,
        v_service_content,
        v_service_price,
        v_service_duration,
        v_service_type,
        v_service_capacity,
        v_service_current_bookings,
        v_service_auto_confirm,
        v_service_booking_workflow,
        v_service_thumbnail_url,
        v_service_tags,
        v_service_status,
        v_creator_id,
        v_creator_name,
        v_creator_avatar_url,
        v_creator_username,
        v_location_id,
        v_location_name,
        v_location_address,
        v_packages,
        v_user_appointments,
        v_user_purchases,
        v_user_credits,
        v_can_access,
        v_upcoming_appointments;
exception
    when others then
        raise exception 'Error fetching comprehensive service details: %', sqlerrm;
end;
$$;

-- ====================================
-- GRANTS & PERMISSIONS
-- ====================================

grant execute on function public.get_comprehensive_service_details(text, uuid) to authenticated, anon;

-- Grant access to composite types
grant usage on type universal_package_detail to authenticated, anon;
grant usage on type package_pricing_options to authenticated, anon;
grant usage on type package_pricing_option to authenticated, anon;
grant usage on type package_recurring_pricing_option to authenticated, anon;
grant usage on type package_credits to authenticated, anon;
grant usage on type package_service_access to authenticated, anon;
grant usage on type user_appointment_detail to authenticated, anon;
grant usage on type user_package_purchase_detail to authenticated, anon;
grant usage on type user_credits_summary to authenticated, anon;
grant usage on type user_upcoming_appointment to authenticated, anon;

-- ====================================
-- COMMENTS
-- ====================================

comment on function public.get_comprehensive_service_details(text, uuid) 
is 'Get complete service details including user-specific data like appointments, credits, and purchase history';

comment on type universal_package_detail 
is 'Complete universal package details including pricing options and credits';

comment on type package_pricing_options 
is 'Package pricing options for one-time and recurring purchases';

comment on type package_pricing_option 
is 'One-time package pricing option details';

comment on type package_recurring_pricing_option 
is 'Recurring package pricing option details';

comment on type package_credits 
is 'Package credit allocation across different service types';

comment on type package_service_access 
is 'Package service access rules and requirements';

comment on type user_appointment_detail 
is 'User appointment details including status and booking type';

comment on type user_package_purchase_detail 
is 'User package purchase details including credits and access information';

comment on type user_credits_summary 
is 'Summary of user available credits across all packages';

comment on type user_upcoming_appointment 
is 'User upcoming appointment details'; 


COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
