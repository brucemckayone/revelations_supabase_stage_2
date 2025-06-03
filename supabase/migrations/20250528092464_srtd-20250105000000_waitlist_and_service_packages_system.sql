-- Generated with srtd from template: supabase/migrations-templates/20250105000000_waitlist_and_service_packages_system.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Waitlist and Service Packages System
-- This migration implements:
-- 1. Unified waitlist system for both services and events
-- 2. Service packages (multi-session pricing)
-- 3. Capacity management with automatic notification every hour
-- 4. Claim windows for waitlist spots

-- Drop existing constraints and tables that need restructuring
alter table if exists public.services drop constraint if exists check_booking_workflow;

-- Add capacity fields to services
alter table public.services 
add column if not exists capacity integer,
add column if not exists current_bookings integer default 0,
add column if not exists waitlist_enabled boolean default false;

-- Add capacity fields to events (via event_dates since each date can have different capacity)
alter table public.event_dates
add column if not exists capacity integer,
add column if not exists current_bookings integer default 0,
add column if not exists waitlist_enabled boolean default false;

-- Create service packages table for multi-session pricing
create table if not exists public.service_packages (
    id uuid default gen_random_uuid() primary key,
    service_id uuid not null references public.services(id) on delete cascade,
    name text not null, -- e.g., "2 Week Package", "4 Week Package"
    description text,
    sessions_count integer not null, -- number of sessions included
    price numeric(10, 2) not null,
    duration_weeks integer, -- how long the package is valid for
    booking_window_days integer default 7, -- how far in advance sessions can be booked
    is_active boolean default true, -- whether this package is currently available
    created_at timestamp with time zone default current_timestamp,
    updated_at timestamp with time zone default current_timestamp,
    
    constraint sessions_count_positive check (sessions_count > 0),
    constraint price_positive check (price > 0)
);

comment on table public.service_packages is 'Multi-session packages for services (e.g., 2 weeks, 4 weeks, 10 weeks)';

-- Create unified waitlist entries table (replacing the old one)
drop table if exists public.waitlist_entries cascade;

create table public.waitlist_entries (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users(id) on delete cascade,
    email varchar(255) not null,
    
    -- Reference to either service, event, or service package
    service_id uuid references public.services(id) on delete cascade,
    event_id uuid references public.events(id) on delete cascade,
    event_date_id uuid references public.event_dates(id) on delete cascade,
    package_id uuid references public.service_packages(id) on delete cascade,
    
    -- Waitlist management
    position integer not null, -- position in queue (1 = first in line)
    status text not null default 'waiting' check (status in ('waiting', 'notified', 'claimed', 'expired', 'declined')),
    
    -- Notification tracking
    last_notified_at timestamp with time zone,
    notification_count integer default 0,
    claim_expires_at timestamp with time zone, -- when the claim window expires
    
    -- Metadata
    metadata jsonb default '{}',
    created_at timestamp with time zone default current_timestamp,
    updated_at timestamp with time zone default current_timestamp,
    
    constraint only_one_reference check (
        (service_id is not null)::integer + 
        (event_id is not null)::integer + 
        (package_id is not null)::integer = 1
    )
);

comment on table public.waitlist_entries is 'Unified waitlist system for services, events, and service packages';

-- Create indexes for performance
create index if not exists idx_waitlist_entries_service_id on public.waitlist_entries(service_id);
create index if not exists idx_waitlist_entries_event_id on public.waitlist_entries(event_id);
create index if not exists idx_waitlist_entries_event_date_id on public.waitlist_entries(event_date_id);
create index if not exists idx_waitlist_entries_package_id on public.waitlist_entries(package_id);
create index if not exists idx_waitlist_entries_status on public.waitlist_entries(status);
create index if not exists idx_waitlist_entries_position on public.waitlist_entries(position);
create index if not exists idx_waitlist_entries_user_id on public.waitlist_entries(user_id);

-- Create service package purchases table
create table if not exists public.service_package_purchases (
    id uuid default gen_random_uuid() primary key,
    purchase_id uuid not null references public.purchases(id) on delete cascade,
    package_id uuid not null references public.service_packages(id) on delete cascade,
    sessions_remaining integer not null,
    expires_at timestamp with time zone,
    created_at timestamp with time zone default current_timestamp,
    updated_at timestamp with time zone default current_timestamp
);

comment on table public.service_package_purchases is 'Tracks purchased service packages and remaining sessions';

-- Add package_purchase_id to appointments table
alter table public.appointments 
add column if not exists package_purchase_id uuid references public.service_package_purchases(id) on delete set null;

-- Create index for better performance
create index if not exists idx_appointments_package_purchase_id on public.appointments(package_purchase_id);

-- Update services constraint to include packages
alter table public.services 
drop constraint if exists check_booking_workflow;

alter table public.services 
add constraint check_booking_workflow 
check (booking_workflow = any (array['direct'::text, 'pre-approval'::text, 'waitlist'::text, 'package'::text]));

-- Create function to join waitlist
create or replace function public.join_waitlist(
    p_user_id uuid,
    p_email text,
    p_service_id uuid default null,
    p_event_id uuid default null,
    p_event_date_id uuid default null,
    p_package_id uuid default null
) returns public.waitlist_entries
language plpgsql
security definer
as $$
declare
    v_position integer;
    v_entry public.waitlist_entries;
begin
    -- Validate that exactly one reference is provided
    if (p_service_id is not null)::integer + 
       (p_event_id is not null)::integer + 
       (p_package_id is not null)::integer != 1 then
        raise exception 'Exactly one of service_id, event_id, or package_id must be provided';
    end if;
    
    -- Check if user is already on this waitlist
    if exists (
        select 1 from public.waitlist_entries 
        where user_id = p_user_id 
        and (
            (service_id = p_service_id and p_service_id is not null) or
            (event_id = p_event_id and event_date_id = p_event_date_id and p_event_id is not null) or
            (package_id = p_package_id and p_package_id is not null)
        )
        and status = 'waiting'
    ) then
        raise exception 'User is already on this waitlist';
    end if;
    
    -- Get next position in queue
    select coalesce(max(position), 0) + 1 into v_position
    from public.waitlist_entries
    where (
        (service_id = p_service_id and p_service_id is not null) or
        (event_id = p_event_id and event_date_id = p_event_date_id and p_event_id is not null) or
        (package_id = p_package_id and p_package_id is not null)
    )
    and status = 'waiting';
    
    -- Insert waitlist entry
    insert into public.waitlist_entries (
        user_id, email, service_id, event_id, event_date_id, package_id, position
    ) values (
        p_user_id, p_email, p_service_id, p_event_id, p_event_date_id, p_package_id, v_position
    ) returning * into v_entry;
    
    return v_entry;
end;
$$;

-- Create function to check availability and process waitlist
create or replace function public.check_capacity_and_notify_waitlist()
returns void
language plpgsql
security definer
as $$
declare
    v_entry record;
    v_capacity integer;
    v_current_bookings integer;
    v_available_spots integer;
    v_claim_window_hours integer := 24; -- Default 24 hour claim window
begin
    -- Process service waitlists
    for v_entry in (
        select we.*, s.capacity, s.current_bookings, p.title as service_title
        from public.waitlist_entries we
        join public.services s on we.service_id = s.id
        join public.posts p on s.post_id = p.id
        where we.status = 'waiting'
        and we.service_id is not null
        and s.capacity is not null
        and s.waitlist_enabled = true
        order by we.service_id, we.position
    ) loop
        v_available_spots := v_entry.capacity - v_entry.current_bookings;
        
        if v_available_spots > 0 then
            -- Update waitlist entry to notified status
            update public.waitlist_entries
            set 
                status = 'notified',
                last_notified_at = current_timestamp,
                notification_count = notification_count + 1,
                claim_expires_at = current_timestamp + (v_claim_window_hours || ' hours')::interval,
                updated_at = current_timestamp
            where id = v_entry.id;
            
            -- Create notification
            perform public.create_notification(
                v_entry.user_id,
                null, -- system notification
                'Spot Available: ' || v_entry.service_title,
                'A spot has opened up for ' || v_entry.service_title || '. You have ' || v_claim_window_hours || ' hours to claim your spot before it goes to the next person in line.',
                'waitlist',
                1, -- high priority
                v_entry.service_id,
                '/services/' || v_entry.service_id || '?claim=' || v_entry.id,
                jsonb_build_object(
                    'waitlist_entry_id', v_entry.id,
                    'service_id', v_entry.service_id,
                    'claim_expires_at', current_timestamp + (v_claim_window_hours || ' hours')::interval,
                    'notification_type', 'waitlist_spot_available'
                )
            );
            
            -- Only notify one person at a time per service
            exit;
        end if;
    end loop;
    
    -- Process event waitlists (similar logic for events)
    for v_entry in (
        select we.*, ed.capacity, ed.current_bookings, p.title as event_title, ed.start_date
        from public.waitlist_entries we
        join public.event_dates ed on we.event_date_id = ed.id
        join public.events e on ed.event_id = e.id
        join public.posts p on e.post_id = p.id
        where we.status = 'waiting'
        and we.event_date_id is not null
        and ed.capacity is not null
        and ed.waitlist_enabled = true
        order by we.event_date_id, we.position
    ) loop
        v_available_spots := v_entry.capacity - v_entry.current_bookings;
        
        if v_available_spots > 0 then
            -- Update waitlist entry to notified status
            update public.waitlist_entries
            set 
                status = 'notified',
                last_notified_at = current_timestamp,
                notification_count = notification_count + 1,
                claim_expires_at = current_timestamp + (v_claim_window_hours || ' hours')::interval,
                updated_at = current_timestamp
            where id = v_entry.id;
            
            -- Create notification
            perform public.create_notification(
                v_entry.user_id,
                null, -- system notification
                'Event Spot Available: ' || v_entry.event_title,
                'A spot has opened up for ' || v_entry.event_title || ' on ' || to_char(v_entry.start_date, 'Mon DD at HH24:MI') || '. You have ' || v_claim_window_hours || ' hours to claim your spot.',
                'waitlist',
                1, -- high priority
                v_entry.event_id,
                '/events/' || v_entry.event_id || '?claim=' || v_entry.id,
                jsonb_build_object(
                    'waitlist_entry_id', v_entry.id,
                    'event_id', v_entry.event_id,
                    'event_date_id', v_entry.event_date_id,
                    'claim_expires_at', current_timestamp + (v_claim_window_hours || ' hours')::interval,
                    'notification_type', 'waitlist_spot_available'
                )
            );
            
            -- Only notify one person at a time per event date
            exit;
        end if;
    end loop;
    
    -- Process package waitlists
    for v_entry in (
        select we.*, sp.name as package_name, p.title as service_title
        from public.waitlist_entries we
        join public.service_packages sp on we.package_id = sp.id
        join public.services s on sp.service_id = s.id
        join public.posts p on s.post_id = p.id
        where we.status = 'waiting'
        and we.package_id is not null
        and sp.is_active = true
        order by we.package_id, we.position
    ) loop
        -- For packages, we assume they're always available unless specifically limited
        -- Update waitlist entry to notified status
        update public.waitlist_entries
        set 
            status = 'notified',
            last_notified_at = current_timestamp,
            notification_count = notification_count + 1,
            claim_expires_at = current_timestamp + (v_claim_window_hours || ' hours')::interval,
            updated_at = current_timestamp
        where id = v_entry.id;
        
        -- Create notification
        perform public.create_notification(
            v_entry.user_id,
            null, -- system notification
            'Package Available: ' || v_entry.package_name,
            'The ' || v_entry.package_name || ' for ' || v_entry.service_title || ' is now available. You have ' || v_claim_window_hours || ' hours to claim your package.',
            'waitlist',
            1, -- high priority
            null, -- no specific reference id for packages
            '/services/' || (select service_id from public.service_packages where id = v_entry.package_id) || '/packages/' || v_entry.package_id || '?claim=' || v_entry.id,
            jsonb_build_object(
                'waitlist_entry_id', v_entry.id,
                'package_id', v_entry.package_id,
                'claim_expires_at', current_timestamp + (v_claim_window_hours || ' hours')::interval,
                'notification_type', 'waitlist_package_available'
            )
        );
        
        -- Only notify one person at a time per package
        exit;
    end loop;
end;
$$;

-- Create function to claim waitlist spot
create or replace function public.claim_waitlist_spot(
    p_waitlist_entry_id uuid,
    p_user_id uuid default null
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_entry public.waitlist_entries;
    v_user_id uuid;
    v_result jsonb;
begin
    -- Use provided user_id or get from auth
    v_user_id := coalesce(p_user_id, auth.uid());
    
    -- Get waitlist entry
    select * into v_entry
    from public.waitlist_entries
    where id = p_waitlist_entry_id
    and user_id = v_user_id;
    
    if not found then
        raise exception 'Waitlist entry not found or access denied';
    end if;
    
    -- Check if still in claim window
    if v_entry.status != 'notified' then
        raise exception 'Waitlist entry is not in notified status';
    end if;
    
    if v_entry.claim_expires_at < current_timestamp then
        -- Expired, move to next person
        update public.waitlist_entries
        set status = 'expired', updated_at = current_timestamp
        where id = p_waitlist_entry_id;
        
        -- Trigger notification for next person
        perform public.check_capacity_and_notify_waitlist();
        
        raise exception 'Claim window has expired';
    end if;
    
    -- Mark as claimed
    update public.waitlist_entries
    set 
        status = 'claimed',
        updated_at = current_timestamp
    where id = p_waitlist_entry_id;
    
    -- Return booking information based on type
    if v_entry.service_id is not null then
        v_result := jsonb_build_object(
            'type', 'service',
            'service_id', v_entry.service_id,
            'action', 'book_appointment'
        );
    elsif v_entry.event_date_id is not null then
        v_result := jsonb_build_object(
            'type', 'event',
            'event_id', v_entry.event_id,
            'event_date_id', v_entry.event_date_id,
            'action', 'book_event'
        );
    elsif v_entry.package_id is not null then
        v_result := jsonb_build_object(
            'type', 'package',
            'package_id', v_entry.package_id,
            'action', 'purchase_package'
        );
    end if;
    
    return v_result;
end;
$$;

-- Create function to expire old claims and notify next in line
create or replace function public.process_expired_waitlist_claims()
returns void
language plpgsql
security definer
as $$
begin
    -- Mark expired claims
    update public.waitlist_entries
    set 
        status = 'expired',
        updated_at = current_timestamp
    where status = 'notified'
    and claim_expires_at < current_timestamp;
    
    -- Reorder positions for each waitlist after expired claims
    with position_updates as (
        select 
            id,
            row_number() over (
                partition by coalesce(service_id::text, event_date_id::text, package_id::text)
                order by created_at
            ) as new_position
        from public.waitlist_entries
        where status = 'waiting'
    )
    update public.waitlist_entries
    set 
        position = position_updates.new_position,
        updated_at = current_timestamp
    from position_updates
    where public.waitlist_entries.id = position_updates.id;
    
    -- Trigger notification check for next people in line
    perform public.check_capacity_and_notify_waitlist();
end;
$$;

-- Create function to update capacity counters
create or replace function public.update_capacity_counters()
returns void
language plpgsql
security definer
as $$
begin
    -- Update service current bookings
    update public.services
    set current_bookings = (
        select count(*)
        from public.appointments a
        where a.service_id = services.id
        and a.status in ('confirmed', 'pending_approval', 'pending_payment', 'pending_auto_payment')
        and a.appointment_date > current_timestamp
    );
    
    -- Update event date current bookings
    update public.event_dates
    set current_bookings = (
        select coalesce(sum(eb.attendees), 0)
        from public.event_bookings eb
        join public.purchases p on eb.purchase_id = p.id
        where eb.date_id = event_dates.id
        and p.payment_status in ('completed', 'pending')
        and eb.status != 'cancelled'
    );
end;
$$;

-- Create function for providers to manually notify waitlist
create or replace function public.notify_waitlist_manually(
    p_service_id uuid default null,
    p_event_date_id uuid default null,
    p_package_id uuid default null,
    p_message text default null
) returns integer
language plpgsql
security definer
as $$
declare
    v_provider_id uuid;
    v_count integer := 0;
    v_entry record;
    v_title text;
    v_default_message text;
begin
    v_provider_id := auth.uid();
    
    -- Verify provider ownership
    if p_service_id is not null then
        if not exists (
            select 1 from public.services s
            join public.posts p on s.post_id = p.id
            where s.id = p_service_id and p.user_id = v_provider_id
        ) then
            raise exception 'Access denied: Not your service';
        end if;
        
        select p.title into v_title
        from public.services s
        join public.posts p on s.post_id = p.id
        where s.id = p_service_id;
        
        v_default_message := 'Good news! A spot may be opening up soon for ' || v_title || '. Stay tuned for updates.';
    end if;
    
    if p_event_date_id is not null then
        if not exists (
            select 1 from public.event_dates ed
            join public.events e on ed.event_id = e.id
            join public.posts p on e.post_id = p.id
            where ed.id = p_event_date_id and p.user_id = v_provider_id
        ) then
            raise exception 'Access denied: Not your event';
        end if;
        
        select p.title into v_title
        from public.event_dates ed
        join public.events e on ed.event_id = e.id
        join public.posts p on e.post_id = p.id
        where ed.id = p_event_date_id;
        
        v_default_message := 'Good news! A spot may be opening up soon for ' || v_title || '. Stay tuned for updates.';
    end if;
    
    if p_package_id is not null then
        if not exists (
            select 1 from public.service_packages sp
            join public.services s on sp.service_id = s.id
            join public.posts p on s.post_id = p.id
            where sp.id = p_package_id and p.user_id = v_provider_id
        ) then
            raise exception 'Access denied: Not your package';
        end if;
        
        select sp.name || ' for ' || p.title into v_title
        from public.service_packages sp
        join public.services s on sp.service_id = s.id
        join public.posts p on s.post_id = p.id
        where sp.id = p_package_id;
        
        v_default_message := 'Good news! The ' || v_title || ' may be available soon. Stay tuned for updates.';
    end if;
    
    -- Send notifications to waitlist
    for v_entry in (
        select *
        from public.waitlist_entries
        where (
            (service_id = p_service_id and p_service_id is not null) or
            (event_date_id = p_event_date_id and p_event_date_id is not null) or
            (package_id = p_package_id and p_package_id is not null)
        )
        and status = 'waiting'
        order by position
    ) loop
        perform public.create_notification(
            v_entry.user_id,
            v_provider_id,
            'Update from Provider: ' || v_title,
            coalesce(p_message, v_default_message),
            'message',
            2, -- medium priority
            coalesce(p_service_id, v_entry.event_id),
            case 
                when p_service_id is not null then '/services/' || p_service_id
                when p_event_date_id is not null then '/events/' || v_entry.event_id
                when p_package_id is not null then '/services/' || (
                    select s.id from public.service_packages sp 
                    join public.services s on sp.service_id = s.id 
                    where sp.id = p_package_id
                ) || '/packages'
            end,
            jsonb_build_object(
                'waitlist_entry_id', v_entry.id,
                'notification_type', 'provider_message',
                'provider_id', v_provider_id,
                'manual_notification', true
            )
        );
        
        v_count := v_count + 1;
    end loop;
    
    return v_count;
end;
$$;

-- Create cron job function to run every hour
create or replace function public.hourly_waitlist_processor()
returns void
language plpgsql
security definer
as $$
begin
    -- Update capacity counters
    perform public.update_capacity_counters();
    
    -- Process expired claims
    perform public.process_expired_waitlist_claims();
    
    -- Check for available spots and notify
    perform public.check_capacity_and_notify_waitlist();
end;
$$;

-- Add triggers to automatically update capacity when bookings change
create or replace function public.update_service_capacity_on_appointment_change()
returns trigger
language plpgsql
as $$
begin
    -- Update capacity counter for the affected service
    if tg_op = 'DELETE' then
        update public.services
        set current_bookings = (
            select count(*)
            from public.appointments a
            where a.service_id = old.service_id
            and a.status in ('confirmed', 'pending_approval', 'pending_payment', 'pending_auto_payment')
            and a.appointment_date > current_timestamp
        )
        where id = old.service_id;
        
        return old;
    else
        update public.services
        set current_bookings = (
            select count(*)
            from public.appointments a
            where a.service_id = new.service_id
            and a.status in ('confirmed', 'pending_approval', 'pending_payment', 'pending_auto_payment')
            and a.appointment_date > current_timestamp
        )
        where id = new.service_id;
        
        return new;
    end if;
end;
$$;

-- Create trigger for appointment changes
drop trigger if exists update_service_capacity_trigger on public.appointments;
create trigger update_service_capacity_trigger
    after insert or update or delete on public.appointments
    for each row
    execute function public.update_service_capacity_on_appointment_change();

-- Create trigger for event booking changes
create or replace function public.update_event_capacity_on_booking_change()
returns trigger
language plpgsql
as $$
begin
    -- Update capacity counter for the affected event date
    if tg_op = 'DELETE' then
        update public.event_dates
        set current_bookings = (
            select coalesce(sum(eb.attendees), 0)
            from public.event_bookings eb
            join public.purchases p on eb.purchase_id = p.id
            where eb.date_id = old.date_id
            and p.payment_status in ('completed', 'pending')
            and eb.status != 'cancelled'
        )
        where id = old.date_id;
        
        return old;
    else
        update public.event_dates
        set current_bookings = (
            select coalesce(sum(eb.attendees), 0)
            from public.event_bookings eb
            join public.purchases p on eb.purchase_id = p.id
            where eb.date_id = new.date_id
            and p.payment_status in ('completed', 'pending')
            and eb.status != 'cancelled'
        )
        where id = new.date_id;
        
        return new;
    end if;
end;
$$;

-- Create trigger for event booking changes
drop trigger if exists update_event_capacity_trigger on public.event_bookings;
create trigger update_event_capacity_trigger
    after insert or update or delete on public.event_bookings
    for each row
    execute function public.update_event_capacity_on_booking_change();

-- Grant necessary permissions
grant all on table public.service_packages to authenticated, anon, service_role;
grant all on table public.waitlist_entries to authenticated, anon, service_role;
grant all on table public.service_package_purchases to authenticated, anon, service_role;

grant execute on function public.join_waitlist(uuid, text, uuid, uuid, uuid, uuid) to authenticated, anon, service_role;
grant execute on function public.claim_waitlist_spot(uuid, uuid) to authenticated, anon, service_role;
grant execute on function public.notify_waitlist_manually(uuid, uuid, uuid, text) to authenticated, anon, service_role;
grant execute on function public.check_capacity_and_notify_waitlist() to authenticated, anon, service_role;
grant execute on function public.process_expired_waitlist_claims() to authenticated, anon, service_role;
grant execute on function public.hourly_waitlist_processor() to authenticated, anon, service_role;
grant execute on function public.update_capacity_counters() to authenticated, anon, service_role;

-- Update RLS policies
alter table public.service_packages enable row level security;
alter table public.waitlist_entries enable row level security;
alter table public.service_package_purchases enable row level security;

-- Service packages policies
create policy "Public can view service packages"
    on public.service_packages
    for select
    to public
    using (true);

create policy "Service owners can manage packages"
    on public.service_packages
    for all
    to authenticated
    using (
        exists (
            select 1 from public.services s
            join public.posts p on s.post_id = p.id
            where s.id = service_packages.service_id
            and p.user_id = auth.uid()
        )
    );

-- Waitlist entries policies
create policy "Users can view their own waitlist entries"
    on public.waitlist_entries
    for select
    to authenticated
    using (user_id = auth.uid());

create policy "Users can create waitlist entries"
    on public.waitlist_entries
    for insert
    to authenticated
    with check (user_id = auth.uid());

create policy "Users can update their own waitlist entries"
    on public.waitlist_entries
    for update
    to authenticated
    using (user_id = auth.uid());

create policy "Service/Event owners can view their waitlists"
    on public.waitlist_entries
    for select
    to authenticated
    using (
        exists (
            select 1 from public.services s
            join public.posts p on s.post_id = p.id
            where s.id = waitlist_entries.service_id
            and p.user_id = auth.uid()
        ) or
        exists (
            select 1 from public.events e
            join public.posts p on e.post_id = p.id
            where e.id = waitlist_entries.event_id
            and p.user_id = auth.uid()
        ) or
        exists (
            select 1 from public.service_packages sp
            join public.services s on sp.service_id = s.id
            join public.posts p on s.post_id = p.id
            where sp.id = waitlist_entries.package_id
            and p.user_id = auth.uid()
        )
    );

-- Service package purchases policies
create policy "Users can view their own package purchases"
    on public.service_package_purchases
    for select
    to authenticated
    using (
        exists (
            select 1 from public.purchases p
            where p.id = service_package_purchases.purchase_id
            and p.user_id = auth.uid()
        )
    );

create policy "Service owners can view their package purchases"
    on public.service_package_purchases
    for select
    to authenticated
    using (
        exists (
            select 1 from public.purchases p
            where p.id = service_package_purchases.purchase_id
            and p.owner_id = auth.uid()
        )
    );

-- Add comments for documentation
comment on function public.join_waitlist(uuid, text, uuid, uuid, uuid, uuid) is 'Join a waitlist for a service, event, or package';
comment on function public.claim_waitlist_spot(uuid, uuid) is 'Claim a waitlist spot within the claim window';
comment on function public.notify_waitlist_manually(uuid, uuid, uuid, text) is 'Allow providers to manually notify their waitlists';
comment on function public.check_capacity_and_notify_waitlist() is 'Check for available capacity and notify next person in waitlist';
comment on function public.process_expired_waitlist_claims() is 'Process expired claim windows and reorder positions';
comment on function public.hourly_waitlist_processor() is 'Main function to run every hour for waitlist management';

-- Create view for comprehensive waitlist information
create or replace view public.waitlist_details_view as
select 
    we.id,
    we.user_id,
    we.email,
    we.position,
    we.status,
    we.last_notified_at,
    we.notification_count,
    we.claim_expires_at,
    we.created_at,
    we.updated_at,
    
    -- Service information
    case when we.service_id is not null then
        jsonb_build_object(
            'id', s.id,
            'title', sp.title,
            'price', s.price,
            'duration', extract(epoch from s.duration) / 60,
            'capacity', s.capacity,
            'current_bookings', s.current_bookings,
            'available_spots', coalesce(s.capacity - s.current_bookings, 0)
        )
    end as service_info,
    
    -- Event information
    case when we.event_id is not null then
        jsonb_build_object(
            'id', e.id,
            'title', ep.title,
            'date_id', ed.id,
            'start_date', ed.start_date,
            'end_date', ed.end_date,
            'capacity', ed.capacity,
            'current_bookings', ed.current_bookings,
            'available_spots', coalesce(ed.capacity - ed.current_bookings, 0)
        )
    end as event_info,
    
    -- Package information
    case when we.package_id is not null then
        jsonb_build_object(
            'id', pkg.id,
            'name', pkg.name,
            'description', pkg.description,
            'sessions_count', pkg.sessions_count,
            'price', pkg.price,
            'duration_weeks', pkg.duration_weeks,
            'service_title', pkgp.title
        )
    end as package_info,
    
    -- User information
    jsonb_build_object(
        'id', prof.id,
        'full_name', prof.full_name,
        'avatar_url', prof.avatar_url
    ) as user_info
    
from public.waitlist_entries we
left join public.services s on we.service_id = s.id
left join public.posts sp on s.post_id = sp.id
left join public.events e on we.event_id = e.id
left join public.posts ep on e.post_id = ep.id
left join public.event_dates ed on we.event_date_id = ed.id
left join public.service_packages pkg on we.package_id = pkg.id
left join public.services pkgs on pkg.service_id = pkgs.id
left join public.posts pkgp on pkgs.post_id = pkgp.id
left join public.profiles prof on we.user_id = prof.id;

comment on view public.waitlist_details_view is 'Comprehensive view of waitlist entries with related information';

grant select on public.waitlist_details_view to authenticated, anon, service_role; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
