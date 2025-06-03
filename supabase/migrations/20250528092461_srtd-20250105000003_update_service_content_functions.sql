-- Generated with srtd from template: supabase/migrations-templates/20250105000003_update_service_content_functions.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Update Service Content Functions for Waitlist and Package Support
-- This migration updates the service content creation and update functions
-- to handle the new capacity, waitlist, and package-related fields

-- Drop and recreate create_service_content_with_details with new parameters
drop function if exists public.create_service_content_with_details;

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

    -- Create the service record with actual existing fields only
    insert into public.services (
        post_id,
        location_id,
        content,
        price,
        duration,
        type,
        booking_workflow,
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

-- Drop and recreate update_service_content_with_details with new parameters
drop function if exists public.update_service_content_with_details;

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
        waitlist_enabled
    into 
        v_current_workflow, 
        v_current_auto_confirm, 
        v_current_deadline,
        v_current_capacity,
        v_current_waitlist_enabled
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

-- Grant permissions for the updated functions
grant execute on function public.create_service_content_with_details(
    text, text, text, text, text, text[], 
    public.publish_status_enum, uuid, numeric, interval, 
    public.event_type_enum, text, boolean, integer, 
    integer, boolean, uuid
) to authenticated, anon, service_role;

grant execute on function public.update_service_content_with_details(
    uuid, text, text, text, text, text, text[], 
    public.publish_status_enum, uuid, numeric, interval, 
    public.event_type_enum, text, boolean, integer, 
    integer, boolean
) to authenticated, anon, service_role;

-- Add comments for documentation
comment on function public.create_service_content_with_details(
    text, text, text, text, text, text[], 
    public.publish_status_enum, uuid, numeric, interval, 
    public.event_type_enum, text, boolean, integer, 
    integer, boolean, uuid
) is 'Create service content with full details including capacity and waitlist support';

comment on function public.update_service_content_with_details(
    uuid, text, text, text, text, text, text[], 
    public.publish_status_enum, uuid, numeric, interval, 
    public.event_type_enum, text, boolean, integer, 
    integer, boolean
) is 'Update service content with full details including capacity and waitlist support'; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
