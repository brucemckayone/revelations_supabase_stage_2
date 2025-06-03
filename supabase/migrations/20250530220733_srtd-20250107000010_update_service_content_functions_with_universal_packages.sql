-- Generated with srtd from template: supabase/migrations-templates/20250107000010_update_service_content_functions_with_universal_packages.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Update Service Content Functions for Universal Package Integration
-- This migration updates the service content creation and update functions
-- to handle universal packages as inputs and automatically create access rules

-- ====================================
-- RETURN TYPES
-- ====================================



-- ====================================
-- UPDATED CREATE FUNCTION
-- ====================================

-- Drop and recreate create_service_content_with_details with universal package support
drop function if exists public.create_service_content_with_details;
drop function if exists public.update_service_content_with_details;
-- Enhanced result type that includes package access rule information
drop type if exists service_content_with_packages_result;
create type service_content_with_packages_result as (
    post_id uuid,
    service_id uuid,
    slug text,
    package_rules_created integer,
    package_ids uuid[]
);

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
    user_id uuid default null,
    -- NEW: Universal package integration parameters
    p_universal_package_ids uuid[] default '{}', -- Array of universal package IDs to add access rules for
    p_package_credits_required integer default 1, -- Credits required per booking (default 1)
    p_package_access_type access_pattern_enum default 'pay_per_use', -- Access pattern
    p_package_priority integer default 0 -- Rule priority
) returns public.service_content_with_packages_result
language plpgsql
security definer
as $$
declare
    v_post_id uuid;
    v_service_id uuid;
    v_result service_content_with_packages_result;
    v_user_id uuid;
    v_package_id uuid;
    v_rules_created integer := 0;
    v_valid_package_ids uuid[] := '{}';
begin
    -- If user_id is not provided, use the authenticated user's ID
    if user_id is null then
       v_user_id := auth.uid();
    else
       v_user_id := user_id;
    end if;

    if v_user_id is null then
        raise exception 'Authentication required';
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

    -- Create the service record
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

    -- Handle universal package access rules if provided
    if array_length(p_universal_package_ids, 1) > 0 then
        -- Validate that all packages exist and belong to this creator
        for v_package_id in select unnest(p_universal_package_ids)
        loop
            -- Check if package exists and belongs to creator
            if exists (
                select 1 from public.universal_packages 
                where id = v_package_id 
                and creator_id = v_user_id 
                and is_active = true
            ) then
                -- Add access rule for this service to the package
                insert into public.package_access_rules (
                    package_id,
                    service_id,
                    access_type,
                    credits_required,
                    priority
                ) values (
                    v_package_id,
                    v_service_id,
                    p_package_access_type,
                    p_package_credits_required,
                    p_package_priority
                );
                
                v_rules_created := v_rules_created + 1;
                v_valid_package_ids := array_append(v_valid_package_ids, v_package_id);
            else
                -- Log warning but don't fail - package might not exist or not belong to creator
                raise warning 'Package % not found or not owned by creator %', v_package_id, v_user_id;
            end if;
        end loop;
    end if;

    -- Prepare the enhanced result
    v_result := (v_post_id, v_service_id, p_slug, v_rules_created, v_valid_package_ids);

    return v_result;
exception
    when others then
        raise exception 'Error creating service content with packages: %', sqlerrm;
end;
$$;

-- ====================================
-- UPDATED UPDATE FUNCTION
-- ====================================

-- Drop and recreate update_service_content_with_details with universal package support
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
    p_waitlist_enabled boolean default null,
    -- NEW: Universal package integration parameters
    p_universal_package_ids uuid[] default null, -- Array of universal package IDs to update access rules for
    p_package_credits_required integer default null, -- Credits required per booking
    p_package_access_type access_pattern_enum default null, -- Access pattern
    p_package_priority integer default null, -- Rule priority
    p_replace_package_rules boolean default false -- Whether to replace existing rules or add to them
) returns public.service_content_with_packages_result
language plpgsql
security definer
as $$
declare
    v_service_id uuid;
    v_result public.service_content_with_packages_result;
    v_current_workflow text;
    v_current_auto_confirm boolean;
    v_current_deadline integer;
    v_current_capacity integer;
    v_current_waitlist_enabled boolean;
    v_user_id uuid;
    v_package_id uuid;
    v_rules_created integer := 0;
    v_valid_package_ids uuid[] := '{}';
begin
    v_user_id := auth.uid();
    
    if v_user_id is null then
        raise exception 'Authentication required';
    end if;

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
        id,
        booking_workflow, 
        auto_confirm, 
        confirmation_deadline_hours,
        capacity,
        waitlist_enabled
    into 
        v_service_id,
        v_current_workflow, 
        v_current_auto_confirm, 
        v_current_deadline,
        v_current_capacity,
        v_current_waitlist_enabled
    from public.services
    where post_id = p_post_id;

    if v_service_id is null then
        raise exception 'Service not found for post_id %', p_post_id;
    end if;

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
    where id = v_service_id;

    -- Handle the tags separately using the add_tags_to_post function
    delete from public.post_tags where post_id = p_post_id;
    perform public.add_tags_to_post(p_post_id, p_tags);

    -- Handle universal package access rules if provided
    if p_universal_package_ids is not null and array_length(p_universal_package_ids, 1) > 0 then
        
        -- If replacing rules, remove existing ones for this service
        if p_replace_package_rules then
            delete from public.package_access_rules 
            where service_id = v_service_id 
            and package_id in (
                select id from public.universal_packages 
                where creator_id = v_user_id
            );
        end if;

        -- Add/update access rules for specified packages
        for v_package_id in select unnest(p_universal_package_ids)
        loop
            -- Check if package exists and belongs to creator
            if exists (
                select 1 from public.universal_packages 
                where id = v_package_id 
                and creator_id = v_user_id 
                and is_active = true
            ) then
                -- Insert or update access rule
                insert into public.package_access_rules (
                    package_id,
                    service_id,
                    access_type,
                    credits_required,
                    priority
                ) values (
                    v_package_id,
                    v_service_id,
                    coalesce(p_package_access_type, 'pay_per_use'),
                    coalesce(p_package_credits_required, 1),
                    coalesce(p_package_priority, 0)
                )
                on conflict (package_id, service_id) 
                do update set
                    access_type = coalesce(excluded.access_type, package_access_rules.access_type),
                    credits_required = coalesce(excluded.credits_required, package_access_rules.credits_required),
                    priority = coalesce(excluded.priority, package_access_rules.priority);
                
                v_rules_created := v_rules_created + 1;
                v_valid_package_ids := array_append(v_valid_package_ids, v_package_id);
            else
                -- Log warning but don't fail
                raise warning 'Package % not found or not owned by creator %', v_package_id, v_user_id;
            end if;
        end loop;
    end if;

    -- Prepare the enhanced result
    v_result := (p_post_id, v_service_id, p_slug, v_rules_created, v_valid_package_ids);

    return v_result;
exception
    when others then
        raise exception 'Error updating service content with packages: %', sqlerrm;
end;
$$;

-- ====================================
-- CONVENIENCE HELPER FUNCTIONS
-- ====================================

-- Function to add a service to existing universal packages
create or replace function public.add_service_to_universal_packages(
    p_service_id uuid,
    p_package_ids uuid[],
    p_credits_required integer default 1,
    p_access_type access_pattern_enum default 'pay_per_use',
    p_priority integer default 0
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_package_id uuid;
    v_rules_created integer := 0;
    v_valid_package_ids uuid[] := '{}';
begin
    v_user_id := auth.uid();
    
    if v_user_id is null then
        raise exception 'Authentication required';
    end if;

    -- Verify service ownership
    if not exists (
        select 1 from public.services s
        join public.posts p on s.post_id = p.id
        where s.id = p_service_id and p.user_id = v_user_id
    ) then
        raise exception 'Service not found or not owned by user';
    end if;

    -- Add access rules for each valid package
    for v_package_id in select unnest(p_package_ids)
    loop
        if exists (
            select 1 from public.universal_packages 
            where id = v_package_id 
            and creator_id = v_user_id 
            and is_active = true
        ) then
            insert into public.package_access_rules (
                package_id,
                service_id,
                access_type,
                credits_required,
                priority
            ) values (
                v_package_id,
                p_service_id,
                p_access_type,
                p_credits_required,
                p_priority
            )
            on conflict (package_id, service_id) 
            do update set
                access_type = excluded.access_type,
                credits_required = excluded.credits_required,
                priority = excluded.priority;
            
            v_rules_created := v_rules_created + 1;
            v_valid_package_ids := array_append(v_valid_package_ids, v_package_id);
        end if;
    end loop;

    return jsonb_build_object(
        'success', true,
        'service_id', p_service_id,
        'rules_created', v_rules_created,
        'package_ids', v_valid_package_ids
    );
end;
$$;

-- Function to remove a service from universal packages
create or replace function public.remove_service_from_universal_packages(
    p_service_id uuid,
    p_package_ids uuid[] default null -- If null, removes from all packages
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_rules_removed integer := 0;
begin
    v_user_id := auth.uid();
    
    if v_user_id is null then
        raise exception 'Authentication required';
    end if;

    -- Verify service ownership
    if not exists (
        select 1 from public.services s
        join public.posts p on s.post_id = p.id
        where s.id = p_service_id and p.user_id = v_user_id
    ) then
        raise exception 'Service not found or not owned by user';
    end if;

    -- Remove access rules
    if p_package_ids is null then
        -- Remove from all packages owned by this creator
        delete from public.package_access_rules 
        where service_id = p_service_id 
        and package_id in (
            select id from public.universal_packages 
            where creator_id = v_user_id
        );
    else
        -- Remove from specific packages
        delete from public.package_access_rules 
        where service_id = p_service_id 
        and package_id = any(p_package_ids)
        and package_id in (
            select id from public.universal_packages 
            where creator_id = v_user_id
        );
    end if;

    get diagnostics v_rules_removed = row_count;

    return jsonb_build_object(
        'success', true,
        'service_id', p_service_id,
        'rules_removed', v_rules_removed
    );
end;
$$;

-- ====================================
-- GRANTS & PERMISSIONS
-- ====================================

grant execute on function public.create_service_content_with_details(
    text, text, text, text, text, text[], 
    public.publish_status_enum, uuid, numeric, interval, 
    public.event_type_enum, text, boolean, integer, 
    integer, boolean, uuid, uuid[], integer, access_pattern_enum, integer
) to authenticated, service_role;

grant execute on function public.update_service_content_with_details(
    uuid, text, text, text, text, text, text[], 
    public.publish_status_enum, uuid, numeric, interval, 
    public.event_type_enum, text, boolean, integer, 
    integer, boolean, uuid[], integer, access_pattern_enum, integer, boolean
) to authenticated, service_role;

grant execute on function public.add_service_to_universal_packages(uuid, uuid[], integer, access_pattern_enum, integer) to authenticated, service_role;
grant execute on function public.remove_service_from_universal_packages(uuid, uuid[]) to authenticated, service_role;

-- Grant usage on the new type
grant usage on type service_content_with_packages_result to authenticated, service_role;

-- ====================================
-- COMMENTS
-- ====================================


comment on function public.create_service_content_with_details(
    text, text, text, text, text, text[], 
    public.publish_status_enum, uuid, numeric, interval, 
    public.event_type_enum, text, boolean, integer, 
    integer, boolean, uuid, uuid[], integer, access_pattern_enum, integer
) is 'Create service content with universal package integration - automatically creates access rules';

comment on function public.update_service_content_with_details(
    uuid, text, text, text, text, text, text[], 
    public.publish_status_enum, uuid, numeric, interval, 
    public.event_type_enum, text, boolean, integer, 
    integer, boolean, uuid[], integer, access_pattern_enum, integer, boolean
) is 'Update service content with universal package integration - manages access rules';

comment on function public.add_service_to_universal_packages(uuid, uuid[], integer, access_pattern_enum, integer) 
is 'Add an existing service to universal packages by creating access rules';

comment on function public.remove_service_from_universal_packages(uuid, uuid[]) 
is 'Remove a service from universal packages by deleting access rules';

comment on type service_content_with_packages_result 
is 'Enhanced result type that includes package access rule information'; 


COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
