-- Generated with srtd from template: supabase/migrations-templates/20250105000005_enhanced_package_booking_system.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Enhanced Package Booking System
-- This migration adds comprehensive multi-date booking capabilities for service packages

-- Add package session scheduling preferences
alter table public.service_packages 
add column if not exists scheduling_preferences jsonb default '{}';

comment on column public.service_packages.scheduling_preferences is 'Preferences for scheduling sessions (frequency, preferred days, etc.)';

-- Create package session templates for recurring bookings
create table if not exists public.package_session_templates (
    id uuid default gen_random_uuid() primary key,
    package_id uuid not null references public.service_packages(id) on delete cascade,
    name text not null, -- e.g., "Weekly Sessions", "Bi-weekly Check-ins"
    description text,
    frequency_type text not null check (frequency_type in ('weekly', 'biweekly', 'monthly', 'custom')),
    frequency_interval integer default 1, -- every X weeks/months
    preferred_days integer[] default '{}', -- 0=Sunday, 1=Monday, etc.
    preferred_times time[] default '{}', -- preferred start times
    session_duration interval,
    auto_schedule boolean default false, -- whether to auto-schedule all sessions
    is_active boolean default true,
    created_at timestamp with time zone default current_timestamp,
    updated_at timestamp with time zone default current_timestamp
);

comment on table public.package_session_templates is 'Templates for scheduling recurring package sessions';

-- Function to bulk book multiple sessions from a package
create or replace function public.bulk_book_package_sessions(
    p_package_purchase_id uuid,
    p_session_dates timestamp with time zone[],
    p_notes text default null
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_package_purchase public.service_package_purchases;
    v_service public.services;
    v_appointment_ids uuid[] := '{}';
    v_appointment public.appointments;
    v_sessions_to_book integer;
    v_date timestamp with time zone;
    v_success_count integer := 0;
    v_failed_bookings jsonb := '[]';
    v_result jsonb;
begin
    v_user_id := auth.uid();
    
    -- Get package purchase details
    select spp.*
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
    
    -- Get service details
    select s.*
    into v_service
    from public.service_packages sp
    join public.services s on sp.service_id = s.id
    where sp.id = v_package_purchase.package_id;
    
    if not found then
        raise exception 'Service not found';
    end if;
    
    -- Validate session count
    v_sessions_to_book := array_length(p_session_dates, 1);
    if v_sessions_to_book > v_package_purchase.sessions_remaining then
        raise exception 'Not enough sessions remaining. Requested: %, Available: %', 
            v_sessions_to_book, v_package_purchase.sessions_remaining;
    end if;
    
    -- Book each session
    foreach v_date in array p_session_dates loop
        begin
            -- Create appointment using existing function
            select * into v_appointment
            from public.create_appointment_request(
                v_service.id,
                v_date,
                v_service.duration,
                p_notes,
                p_package_purchase_id
            );
            
            v_appointment_ids := v_appointment_ids || v_appointment.id;
            v_success_count := v_success_count + 1;
            
        exception when others then
            -- Log failed booking
            v_failed_bookings := v_failed_bookings || jsonb_build_object(
                'date', v_date,
                'error', sqlerrm
            );
        end;
    end loop;
    
    -- Build result
    v_result := jsonb_build_object(
        'success', true,
        'package_purchase_id', p_package_purchase_id,
        'sessions_booked', v_success_count,
        'sessions_requested', v_sessions_to_book,
        'appointment_ids', v_appointment_ids,
        'failed_bookings', v_failed_bookings,
        'sessions_remaining', v_package_purchase.sessions_remaining - v_success_count
    );
    
    return v_result;
end;
$$;

-- Function to suggest optimal session dates based on package preferences
create or replace function public.suggest_package_session_dates(
    p_package_purchase_id uuid,
    p_sessions_count integer default null,
    p_start_date date default null,
    p_template_id uuid default null
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_package_purchase public.service_package_purchases;
    v_package public.service_packages;
    v_service public.services;
    v_template public.package_session_templates;
    v_provider_id uuid;
    v_start_date date;
    v_sessions_needed integer;
    v_suggested_dates timestamp with time zone[] := '{}';
    v_current_date date;
    v_days_to_check integer := 90; -- Look ahead 3 months
    v_frequency_days integer;
    v_preferred_times time[];
    v_preferred_days integer[];
    v_session_time time;
    v_suggested_datetime timestamp with time zone;
    v_day_of_week integer;
    v_result jsonb;
begin
    v_user_id := auth.uid();
    
    -- Get package purchase details
    select spp.*
    into v_package_purchase
    from public.service_package_purchases spp
    join public.purchases p on spp.purchase_id = p.id
    where spp.id = p_package_purchase_id
    and p.user_id = v_user_id;
    
    if not found then
        raise exception 'Package purchase not found or access denied';
    end if;
    
    -- Get package details
    select sp.*
    into v_package
    from public.service_packages sp
    where sp.id = v_package_purchase.package_id;
    
    -- Get service details
    select s.*
    into v_service
    from public.services s
    where s.id = v_package.service_id;
    
    -- Get provider ID
    select posts.user_id
    into v_provider_id
    from public.posts posts
    where posts.id = v_service.post_id;
    
    -- Get template if specified
    if p_template_id is not null then
        select * into v_template
        from public.package_session_templates
        where id = p_template_id and package_id = v_package.id;
    end if;
    
    -- Set defaults
    v_start_date := coalesce(p_start_date, current_date + 1);
    v_sessions_needed := coalesce(p_sessions_count, v_package_purchase.sessions_remaining);
    
    -- Set scheduling preferences from template or package
    if v_template.id is not null then
        v_preferred_days := v_template.preferred_days;
        v_preferred_times := v_template.preferred_times;
        v_frequency_days := case v_template.frequency_type
            when 'weekly' then 7 * v_template.frequency_interval
            when 'biweekly' then 14 * v_template.frequency_interval
            when 'monthly' then 30 * v_template.frequency_interval
            else 7
        end;
    else
        -- Use package preferences or defaults
        v_preferred_days := coalesce(
            (v_package.scheduling_preferences->>'preferred_days')::integer[],
            array[1,2,3,4,5] -- Default to weekdays
        );
        v_preferred_times := coalesce(
            (select array_agg(time_val::time) 
             from jsonb_array_elements_text(v_package.scheduling_preferences->'preferred_times') as time_val),
            array['09:00'::time, '14:00'::time] -- Default times
        );
        v_frequency_days := coalesce(
            (v_package.scheduling_preferences->>'frequency_days')::integer,
            7 -- Default weekly
        );
    end if;
    
    -- Generate suggested dates
    v_current_date := v_start_date;
    
    while array_length(v_suggested_dates, 1) < v_sessions_needed and 
          v_current_date <= v_start_date + v_days_to_check loop
        
        v_day_of_week := extract(dow from v_current_date);
        
        -- Check if this day is preferred
        if v_day_of_week = any(v_preferred_days) then
            -- Try each preferred time
            foreach v_session_time in array v_preferred_times loop
                v_suggested_datetime := v_current_date + v_session_time;
                
                -- Check if this time slot is available (simplified check)
                if not exists (
                    select 1 from public.appointments a
                    where a.service_id = v_service.id
                    and a.appointment_date = v_suggested_datetime
                    and a.status in ('confirmed', 'pending_approval', 'pending_payment', 'pending_auto_payment')
                ) then
                    v_suggested_dates := v_suggested_dates || v_suggested_datetime;
                    exit; -- Found a good time for this day, move to next
                end if;
            end loop;
        end if;
        
        -- Move to next potential date based on frequency
        if array_length(v_suggested_dates, 1) > 0 and 
           array_length(v_suggested_dates, 1) % 1 = 0 then -- After each successful booking
            v_current_date := v_current_date + v_frequency_days;
        else
            v_current_date := v_current_date + 1; -- Try next day if no slot found
        end if;
    end loop;
    
    -- Build result
    v_result := jsonb_build_object(
        'package_purchase_id', p_package_purchase_id,
        'sessions_remaining', v_package_purchase.sessions_remaining,
        'sessions_requested', v_sessions_needed,
        'suggested_dates', to_jsonb(v_suggested_dates),
        'scheduling_preferences', jsonb_build_object(
            'frequency_days', v_frequency_days,
            'preferred_days', v_preferred_days,
            'preferred_times', v_preferred_times
        ),
        'template_used', v_template.id,
        'provider_id', v_provider_id
    );
    
    return v_result;
end;
$$;

-- Function to create a session template for a package
create or replace function public.create_package_session_template(
    p_package_id uuid,
    p_name text,
    p_frequency_type text,
    p_frequency_interval integer default 1,
    p_preferred_days integer[] default array[1,2,3,4,5],
    p_preferred_times time[] default array['09:00'::time],
    p_description text default null,
    p_auto_schedule boolean default false
) returns public.package_session_templates
language plpgsql
security definer
as $$
declare
    v_provider_id uuid;
    v_template public.package_session_templates;
begin
    v_provider_id := auth.uid();
    
    -- Verify the user owns this package's service
    if not exists (
        select 1 from public.service_packages sp
        join public.services s on sp.service_id = s.id
        join public.posts p on s.post_id = p.id
        where sp.id = p_package_id and p.user_id = v_provider_id
    ) then
        raise exception 'Access denied: Not your package';
    end if;
    
    -- Create template
    insert into public.package_session_templates (
        package_id, name, description, frequency_type, frequency_interval,
        preferred_days, preferred_times, auto_schedule
    ) values (
        p_package_id, p_name, p_description, p_frequency_type, p_frequency_interval,
        p_preferred_days, p_preferred_times, p_auto_schedule
    ) returning * into v_template;
    
    return v_template;
end;
$$;

-- Function to get package booking dashboard data
create or replace function public.get_package_booking_dashboard(
    p_package_purchase_id uuid
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_package_purchase public.service_package_purchases;
    v_package public.service_packages;
    v_service public.services;
    v_service_title text;
    v_upcoming_appointments jsonb;
    v_completed_appointments jsonb;
    v_available_templates jsonb;
    v_result jsonb;
begin
    v_user_id := auth.uid();
    
    -- Get package purchase details
    select spp.*
    into v_package_purchase
    from public.service_package_purchases spp
    join public.purchases pu on spp.purchase_id = pu.id
    where spp.id = p_package_purchase_id
    and pu.user_id = v_user_id;
    
    if not found then
        raise exception 'Package purchase not found or access denied';
    end if;
    
    -- Get package details
    select sp.*
    into v_package
    from public.service_packages sp
    where sp.id = v_package_purchase.package_id;
    
    -- Get service details
    select s.*
    into v_service
    from public.services s
    where s.id = v_package.service_id;
    
    -- Get service title
    select p.title
    into v_service_title
    from public.posts p
    where p.id = v_service.post_id;
    
    -- Get upcoming appointments
    select jsonb_agg(
        jsonb_build_object(
            'id', a.id,
            'appointment_date', a.appointment_date,
            'duration', a.duration,
            'status', a.status,
            'notes', a.notes
        ) order by a.appointment_date
    ) into v_upcoming_appointments
    from public.appointments a
    where a.package_purchase_id = p_package_purchase_id
    and a.appointment_date > current_timestamp
    and a.status not in ('cancelled', 'completed');
    
    -- Get completed appointments
    select jsonb_agg(
        jsonb_build_object(
            'id', a.id,
            'appointment_date', a.appointment_date,
            'duration', a.duration,
            'status', a.status,
            'notes', a.notes
        ) order by a.appointment_date desc
    ) into v_completed_appointments
    from public.appointments a
    where a.package_purchase_id = p_package_purchase_id
    and (a.appointment_date <= current_timestamp or a.status in ('cancelled', 'completed'));
    
    -- Get available templates
    select jsonb_agg(
        jsonb_build_object(
            'id', pst.id,
            'name', pst.name,
            'description', pst.description,
            'frequency_type', pst.frequency_type,
            'frequency_interval', pst.frequency_interval,
            'preferred_days', pst.preferred_days,
            'preferred_times', pst.preferred_times
        )
    ) into v_available_templates
    from public.package_session_templates pst
    where pst.package_id = v_package.id
    and pst.is_active = true;
    
    -- Build comprehensive result
    v_result := jsonb_build_object(
        'package_purchase', jsonb_build_object(
            'id', v_package_purchase.id,
            'sessions_remaining', v_package_purchase.sessions_remaining,
            'expires_at', v_package_purchase.expires_at,
            'created_at', v_package_purchase.created_at
        ),
        'package', jsonb_build_object(
            'id', v_package.id,
            'name', v_package.name,
            'description', v_package.description,
            'sessions_count', v_package.sessions_count,
            'duration_weeks', v_package.duration_weeks,
            'booking_window_days', v_package.booking_window_days
        ),
        'service', jsonb_build_object(
            'id', v_service.id,
            'title', v_service_title,
            'duration', v_service.duration,
            'booking_workflow', v_service.booking_workflow
        ),
        'upcoming_appointments', coalesce(v_upcoming_appointments, '[]'::jsonb),
        'completed_appointments', coalesce(v_completed_appointments, '[]'::jsonb),
        'available_templates', coalesce(v_available_templates, '[]'::jsonb),
        'sessions_used', v_package.sessions_count - v_package_purchase.sessions_remaining,
        'progress_percentage', round(
            ((v_package.sessions_count - v_package_purchase.sessions_remaining)::numeric / v_package.sessions_count::numeric) * 100, 
            1
        )
    );
    
    return v_result;
end;
$$;

-- Function to reschedule a package session
create or replace function public.reschedule_package_session(
    p_appointment_id uuid,
    p_new_date timestamp with time zone,
    p_reason text default null
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_appointment public.appointments;
    v_package_purchase public.service_package_purchases;
    v_old_date timestamp with time zone;
    v_result jsonb;
begin
    v_user_id := auth.uid();
    
    -- Get appointment and verify ownership
    select a.*
    into v_appointment
    from public.appointments a
    join public.service_package_purchases spp on a.package_purchase_id = spp.id
    join public.purchases p on spp.purchase_id = p.id
    where a.id = p_appointment_id
    and p.user_id = v_user_id
    and a.package_purchase_id is not null;
    
    if not found then
        raise exception 'Package appointment not found or access denied';
    end if;
    
    -- Get package purchase details
    select spp.*
    into v_package_purchase
    from public.service_package_purchases spp
    where spp.id = v_appointment.package_purchase_id;
    
    -- Check if appointment can be rescheduled
    if v_appointment.status in ('cancelled', 'completed') then
        raise exception 'Cannot reschedule cancelled or completed appointment';
    end if;
    
    v_old_date := v_appointment.appointment_date;
    
    -- Update appointment
    update public.appointments
    set 
        appointment_date = p_new_date,
        notes = coalesce(notes, '') || 
            case when notes is not null and notes != '' then E'\n\n' else '' end ||
            'Rescheduled from ' || v_old_date::text || 
            case when p_reason is not null then '. Reason: ' || p_reason else '' end,
        updated_at = current_timestamp
    where id = p_appointment_id;
    
    -- Build result
    v_result := jsonb_build_object(
        'success', true,
        'appointment_id', p_appointment_id,
        'old_date', v_old_date,
        'new_date', p_new_date,
        'reason', p_reason,
        'package_purchase_id', v_package_purchase.id
    );
    
    return v_result;
end;
$$;

-- Grant permissions
grant execute on function public.bulk_book_package_sessions(uuid, timestamp with time zone[], text) to authenticated, service_role;
grant execute on function public.suggest_package_session_dates(uuid, integer, date, uuid) to authenticated, service_role;
grant execute on function public.create_package_session_template(uuid, text, text, integer, integer[], time[], text, boolean) to authenticated, service_role;
grant execute on function public.get_package_booking_dashboard(uuid) to authenticated, service_role;
grant execute on function public.reschedule_package_session(uuid, timestamp with time zone, text) to authenticated, service_role;

-- Add comments
comment on function public.bulk_book_package_sessions(uuid, timestamp with time zone[], text) is 'Book multiple sessions from a package at once';
comment on function public.suggest_package_session_dates(uuid, integer, date, uuid) is 'Suggest optimal dates for package sessions based on preferences';
comment on function public.create_package_session_template(uuid, text, text, integer, integer[], time[], text, boolean) is 'Create scheduling template for package sessions';
comment on function public.get_package_booking_dashboard(uuid) is 'Get comprehensive package booking dashboard data';
comment on function public.reschedule_package_session(uuid, timestamp with time zone, text) is 'Reschedule a single package session';

-- Create indexes for performance
create index if not exists idx_package_session_templates_package_id on public.package_session_templates(package_id);
-- create index if not exists idx_appointments_package_purchase_date on public.appointments(package_purchase_id, appointment_date);
-- create index if not exists idx_appointments_service_date_status on public.appointments(service_id, appointment_date, status); 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
