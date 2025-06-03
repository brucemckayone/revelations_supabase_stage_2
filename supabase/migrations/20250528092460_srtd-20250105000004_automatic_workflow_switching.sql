-- Generated with srtd from template: supabase/migrations-templates/20250105000004_automatic_workflow_switching.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Automatic Booking Workflow Switching Based on Capacity
-- This migration implements automatic switching between booking workflows
-- when services reach or fall below capacity limits

-- Add original_booking_workflow column to track the intended workflow
alter table public.services 
add column if not exists original_booking_workflow text;

-- Update existing services to set original_booking_workflow
update public.services 
set original_booking_workflow = booking_workflow 
where original_booking_workflow is null;

-- Make original_booking_workflow not null with default
alter table public.services 
alter column original_booking_workflow set not null,
alter column original_booking_workflow set default 'pre-approval';

drop function if exists public.auto_switch_booking_workflow cascade;
-- Function to automatically switch booking workflow based on capacity
create or replace function public.auto_switch_booking_workflow()
returns trigger
language plpgsql
as $$
declare
    v_capacity integer;
    v_current_bookings integer;
    v_original_workflow text;
    v_waitlist_enabled boolean;
begin
    -- Get service details
    if tg_op = 'DELETE' then
        select capacity, current_bookings, original_booking_workflow, waitlist_enabled
        into v_capacity, v_current_bookings, v_original_workflow, v_waitlist_enabled
        from public.services
        where id = old.service_id;
    else
        select capacity, current_bookings, original_booking_workflow, waitlist_enabled
        into v_capacity, v_current_bookings, v_original_workflow, v_waitlist_enabled
        from public.services
        where id = new.service_id;
    end if;
    
    -- Only auto-switch if capacity is set and waitlist is enabled
    if v_capacity is not null and v_waitlist_enabled = true then
        if v_current_bookings >= v_capacity then
            -- At or over capacity - switch to waitlist workflow
            update public.services
            set booking_workflow = 'waitlist',
                updated_at = current_timestamp
            where id = coalesce(new.service_id, old.service_id)
            and booking_workflow != 'waitlist';
            
        elsif v_current_bookings < v_capacity then
            -- Under capacity - switch back to original workflow
            update public.services
            set booking_workflow = v_original_workflow,
                updated_at = current_timestamp
            where id = coalesce(new.service_id, old.service_id)
            and booking_workflow = 'waitlist'
            and v_original_workflow != 'waitlist'; -- Don't switch if originally waitlist
        end if;
    end if;
    
    return coalesce(new, old);
end;
$$;

drop function if exists public.auto_switch_service_workflow_on_update cascade;
-- Function to handle direct service capacity updates
create or replace function public.auto_switch_service_workflow_on_update()
returns trigger
language plpgsql
as $$
declare   
    v_capacity integer := new.capacity;
    v_current_bookings integer := new.current_bookings;
    v_original_workflow text := new.original_booking_workflow;
    v_waitlist_enabled boolean := new.waitlist_enabled;
begin
    -- Only auto-switch if capacity is set and waitlist is enabled
    if v_capacity is not null and v_waitlist_enabled = true then
        if v_current_bookings >= v_capacity then
            -- At or over capacity - switch to waitlist workflow
            if new.booking_workflow != 'waitlist' then
                new.booking_workflow := 'waitlist';
            end if;
            
        elsif v_current_bookings < v_capacity then
            -- Under capacity - switch back to original workflow if currently on waitlist
            if new.booking_workflow = 'waitlist' and v_original_workflow != 'waitlist' then
                new.booking_workflow := v_original_workflow;
            end if;
        end if;
    end if;
    
    return new;
end;
$$;

-- Create triggers for automatic workflow switching

-- Trigger on appointment changes (existing trigger updated)
drop trigger if exists update_service_capacity_trigger on public.appointments;

create or replace function public.update_service_capacity_and_workflow()
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

drop trigger if exists update_service_capacity_and_workflow_trigger on public.appointments;
create trigger update_service_capacity_and_workflow_trigger
    after insert or update or delete on public.appointments
    for each row
    execute function public.update_service_capacity_and_workflow();

drop trigger if exists auto_switch_service_workflow_trigger on public.services;
-- Trigger on direct service updates
create trigger auto_switch_service_workflow_trigger
    before update on public.services
    for each row
    execute function public.auto_switch_service_workflow_on_update();

drop function if exists public.set_service_original_workflow cascade;
-- Function to manually set original workflow (for providers who want to change it)
create or replace function public.set_service_original_workflow(
    p_service_id uuid,
    p_original_workflow text
) returns void
language plpgsql
security definer
as $$
declare
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
    
    -- Validate workflow
    if p_original_workflow not in ('direct', 'pre-approval', 'waitlist', 'package') then
        raise exception 'Invalid booking workflow: %', p_original_workflow;
    end if;
    
    -- Update original workflow
    update public.services
    set 
        original_booking_workflow = p_original_workflow,
        updated_at = current_timestamp
    where id = p_service_id;
    
    -- Trigger capacity check to potentially switch workflow immediately
    perform public.update_capacity_counters();
end;
$$;

drop function if exists public.get_service_workflow_status(uuid);

-- Function to get service workflow status
create or replace function public.get_service_workflow_status(
    p_service_id uuid
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_service record;
    v_available_spots integer;
    v_is_auto_switched boolean;
begin
    select 
        s.*,
        p.title
    into v_service
    from public.services s
    join public.posts p on s.post_id = p.id
    where s.id = p_service_id;
    
    if not found then
        raise exception 'Service not found';
    end if;
    
    -- Calculate available spots
    if v_service.capacity is not null then
        v_available_spots := greatest(0, v_service.capacity - v_service.current_bookings);
    end if;
    
    -- Determine if workflow was auto-switched
    v_is_auto_switched := (
        v_service.booking_workflow = 'waitlist' and 
        v_service.original_booking_workflow != 'waitlist' and
        v_service.waitlist_enabled = true and
        v_service.capacity is not null and
        v_service.current_bookings >= v_service.capacity
    );
    
    return jsonb_build_object(
        'service_id', v_service.id,
        'title', v_service.title,
        'current_workflow', v_service.booking_workflow,
        'original_workflow', v_service.original_booking_workflow,
        'capacity', v_service.capacity,
        'current_bookings', v_service.current_bookings,
        'available_spots', v_available_spots,
        'waitlist_enabled', v_service.waitlist_enabled,
        'is_auto_switched', v_is_auto_switched,
        'can_book_directly', (
            v_service.booking_workflow != 'waitlist' and 
            (v_service.capacity is null or v_service.current_bookings < v_service.capacity)
        ),
        'requires_waitlist', (
            v_service.booking_workflow = 'waitlist' or
            (v_service.capacity is not null and v_service.current_bookings >= v_service.capacity)
        )
    );
end;
$$;

drop function if exists public.create_service_content_with_details;
-- Update the create_service_content_with_details function to set original_booking_workflow
create or replace function public.create_service_content_with_details(
    p_title text,
    p_slug text,
    p_description text,
    p_content text,
    p_thumbnail_url text,
    p_tags text[],
    p_status public.publish_status_enum,
    p_location_id uuid,
    p_price numeric,
    p_duration interval,
    p_type public.event_type_enum,
    p_booking_workflow text default 'pre-approval',
    p_auto_confirm boolean default false,
    p_confirmation_deadline_hours integer default 24,
    p_capacity integer default null,
    p_waitlist_enabled boolean default false,
    user_id uuid default null
) returns public.service_content_creation_result
language plpgsql
as $$
declare
    v_post_id uuid;
    v_service_id uuid;
    v_result service_content_creation_result;
    v_user_id uuid;
begin
    -- If user_id is not provided, use the authenticated user's ID
    if user_id is null then
       v_user_id := auth.uid();
    else
       v_user_id := user_id;
    end if;

    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'service'::post_type_enum,
        p_status,
        p_thumbnail_url,
        v_user_id
    );

    -- Add tags to the post
    perform public.add_tags_to_post(v_post_id, p_tags);

    -- Create the service record with all parameters including new fields
    insert into public.services (
        post_id,
        location_id,
        content,
        price,
        duration,
        type,
        booking_workflow,
        original_booking_workflow,
        auto_confirm,
        confirmation_deadline_hours,
        capacity,
        current_bookings,
        waitlist_enabled
    ) values (
        v_post_id,
        p_location_id,
        p_content,
        p_price,
        p_duration,
        p_type,
        p_booking_workflow,
        p_booking_workflow, -- Set original to match initial
        p_auto_confirm,
        p_confirmation_deadline_hours,
        p_capacity,
        0, -- current_bookings starts at 0
        p_waitlist_enabled
    ) returning id into v_service_id;

    -- Prepare the result
    v_result := (v_post_id, v_service_id, p_slug);

    return v_result;
exception
    when others then
        raise exception 'Error creating service content: %', sqlerrm;
end;
$$;

drop function if exists public.update_service_content_with_details;

-- Update the update_service_content_with_details function to handle original_booking_workflow
create or replace function public.update_service_content_with_details(
    p_post_id uuid,
    p_title text,
    p_slug text,
    p_description text,
    p_content text,
    p_thumbnail_url text,
    p_tags text[],
    p_status public.publish_status_enum,
    p_location_id uuid,
    p_price numeric,
    p_duration interval,
    p_type public.event_type_enum,
    p_booking_workflow text default null,
    p_auto_confirm boolean default null,
    p_confirmation_deadline_hours integer default null,
    p_capacity integer default null,
    p_waitlist_enabled boolean default null
) returns public.service_content_creation_result
language plpgsql
as $$
declare
    v_service_id uuid;
    v_result public.service_content_creation_result;
    v_current_workflow text;
    v_current_auto_confirm boolean;
    v_current_deadline integer;
    v_current_capacity integer;
    v_current_waitlist_enabled boolean;
    v_current_original_workflow text;
begin
    -- Update the post
    update public.posts
    set title = p_title,
        slug = p_slug,
        description = p_description,
        content = p_content,
        thumbnail_url = p_thumbnail_url,
        status = p_status,
        updated_at = now()
    where id = p_post_id;

    -- Get current values for fields that might not be updated
    select 
        booking_workflow, 
        auto_confirm, 
        confirmation_deadline_hours,
        capacity,
        waitlist_enabled,
        original_booking_workflow
    into 
        v_current_workflow, 
        v_current_auto_confirm, 
        v_current_deadline,
        v_current_capacity,
        v_current_waitlist_enabled,
        v_current_original_workflow
    from public.services
    where post_id = p_post_id;

    -- Update the service with all fields, keeping existing values if null provided
    update public.services
    set location_id = p_location_id,
        content = p_content,
        price = p_price,
        duration = p_duration,
        type = p_type,
        booking_workflow = coalesce(p_booking_workflow, v_current_workflow),
        original_booking_workflow = case 
            when p_booking_workflow is not null then p_booking_workflow 
            else v_current_original_workflow 
        end,
        auto_confirm = coalesce(p_auto_confirm, v_current_auto_confirm),
        confirmation_deadline_hours = coalesce(p_confirmation_deadline_hours, v_current_deadline),
        capacity = case 
            when p_capacity is not null then p_capacity
            else v_current_capacity
        end,
        waitlist_enabled = coalesce(p_waitlist_enabled, v_current_waitlist_enabled),
        updated_at = now()
    where post_id = p_post_id
    returning id into v_service_id;

    -- Handle the tags separately using the add_tags_to_post function
    delete from public.post_tags where post_id = p_post_id;
    perform public.add_tags_to_post(p_post_id, p_tags);

    -- Prepare the result
    v_result := (p_post_id, v_service_id, p_slug);

    return v_result;
exception
    when others then
        raise exception 'Error updating service content: %', sqlerrm;
end;
$$;

-- Grant permissions
grant execute on function public.set_service_original_workflow to authenticated, service_role;
grant execute on function public.get_service_workflow_status(uuid) to authenticated, anon, service_role;

-- Add comments
comment on column public.services.original_booking_workflow is 'The intended booking workflow, used for auto-switching back from waitlist';
comment on function public.set_service_original_workflow is 'Set the original booking workflow for a service (provider only)';
comment on function public.get_service_workflow_status(uuid) is 'Get comprehensive workflow status including auto-switching state';
comment on function public.auto_switch_booking_workflow() is 'Automatically switch booking workflow based on capacity';
comment on function public.auto_switch_service_workflow_on_update() is 'Handle workflow switching on direct service updates'; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
