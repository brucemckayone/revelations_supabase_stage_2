-- Generated with srtd from template: supabase/migrations-templates/20250107000008_universal_packages_helpers.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Universal Package Helpers
-- Additional functions for user-defined packages, templates, and advanced features

-- ====================================
-- USER-DEFINED PACKAGE BUILDER
-- ====================================

-- Function for users to create their own custom packages from templates
drop function if exists public.create_user_defined_package;
create or replace function public.create_user_defined_package(
    p_template_package_id uuid,
    p_custom_name text,
    p_appointment_credits integer default null,
    p_content_credits integer default null,
    p_event_credits integer default null,
    p_duration_weeks integer default null,
    p_is_recurring boolean default false
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_template public.universal_packages;
    v_package_id uuid;
    v_custom_price numeric(10,2);
    v_base_price numeric(10,2);
begin
    v_user_id := auth.uid();
    
    if v_user_id is null then
        raise exception 'Authentication required';
    end if;
    
    -- Get template package
    select * into v_template
    from public.universal_packages
    where id = p_template_package_id 
    and is_active = true
    and package_type = 'custom_bundle';
    
    if not found then
        raise exception 'Template package not found or not customizable';
    end if;
    
    -- Calculate custom pricing based on credits requested vs template
    v_base_price := v_template.price;
    
    -- Simple pricing formula: base price + additional credits cost
    v_custom_price := v_base_price;
    
    if p_appointment_credits > v_template.total_appointment_credits then
        v_custom_price := v_custom_price + 
            ((p_appointment_credits - v_template.total_appointment_credits) * 
             (v_template.configuration->>'appointment_credit_price')::numeric);
    end if;
    
    if p_content_credits > v_template.total_content_credits then
        v_custom_price := v_custom_price + 
            ((p_content_credits - v_template.total_content_credits) * 
             (v_template.configuration->>'content_credit_price')::numeric);
    end if;
    
    if p_event_credits > v_template.total_event_credits then
        v_custom_price := v_custom_price + 
            ((p_event_credits - v_template.total_event_credits) * 
             (v_template.configuration->>'event_credit_price')::numeric);
    end if;
    
    -- Create user-defined package
    insert into public.universal_packages (
        creator_id, name, description, package_type, price,
        duration_weeks, is_recurring,
        total_appointment_credits, total_content_credits, total_event_credits,
        is_user_defined, template_package_id,
        appointment_access_pattern, content_access_pattern, event_access_pattern,
        configuration
    ) values (
        v_template.creator_id, -- Package still belongs to original creator
        p_custom_name,
        'Custom package based on ' || v_template.name,
        'custom_bundle',
        v_custom_price,
        coalesce(p_duration_weeks, v_template.duration_weeks),
        p_is_recurring,
        coalesce(p_appointment_credits, v_template.total_appointment_credits),
        coalesce(p_content_credits, v_template.total_content_credits),
        coalesce(p_event_credits, v_template.total_event_credits),
        true, -- is_user_defined
        p_template_package_id,
        v_template.appointment_access_pattern,
        v_template.content_access_pattern,
        v_template.event_access_pattern,
        jsonb_build_object(
            'customized_by', v_user_id,
            'customization_date', current_timestamp,
            'original_price', v_base_price,
            'custom_price', v_custom_price
        )
    ) returning id into v_package_id;
    
    -- Copy access rules from template
    insert into public.package_access_rules (
        package_id, service_id, content_id, post_id, post_type, event_id,
        access_type, credits_required, priority
    )
    select 
        v_package_id, service_id, content_id, post_id, post_type, event_id,
        access_type, credits_required, priority
    from public.package_access_rules
    where package_id = p_template_package_id;
    
    return jsonb_build_object(
        'success', true,
        'package_id', v_package_id,
        'custom_price', v_custom_price,
        'appointment_credits', coalesce(p_appointment_credits, v_template.total_appointment_credits),
        'content_credits', coalesce(p_content_credits, v_template.total_content_credits),
        'event_credits', coalesce(p_event_credits, v_template.total_event_credits)
    );
end;
$$;

-- ====================================
-- PACKAGE DASHBOARD FUNCTIONS
-- ====================================

-- Type for user packages dashboard return
drop type if exists public.user_packages_dashboard_type;
create type public.user_packages_dashboard_type as (
    active_packages jsonb,
    total_appointment_credits integer,
    total_content_credits integer,
    total_event_credits integer,
    expiring_soon jsonb,
    usage_this_month jsonb
);


-- Get user's active packages dashboard
drop function if exists public.get_user_packages_dashboard;
create or replace function public.get_user_packages_dashboard(
    p_user_id uuid default null
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_result jsonb;
begin
    v_user_id := coalesce(p_user_id, auth.uid());
    
    if v_user_id is null then
        raise exception 'Authentication required';
    end if;
    
    select jsonb_build_object(
        'active_packages', coalesce(active_packages.packages, '[]'::jsonb),
        'total_appointment_credits', coalesce(totals.appointment_credits, 0),
        'total_content_credits', coalesce(totals.content_credits, 0),
        'total_event_credits', coalesce(totals.event_credits, 0),
        'expiring_soon', coalesce(expiring.packages, '[]'::jsonb),
        'usage_this_month', coalesce(usage.monthly_usage, '{}'::jsonb)
    ) into v_result
    from (
        -- Active packages
        select jsonb_agg(
            jsonb_build_object(
                'id', upp.id,
                'package_name', up.name,
                'package_type', up.package_type,
                'appointment_credits_remaining', upp.appointment_credits_remaining,
                'content_credits_remaining', upp.content_credits_remaining,
                'event_credits_remaining', upp.event_credits_remaining,
                'expires_at', upp.expires_at,
                'is_recurring', upp.is_recurring,
                'next_billing_date', upp.next_billing_date,
                'progress', jsonb_build_object(
                    'appointments_used', upp.total_appointments_used,
                    'content_accessed', upp.total_content_accessed,
                    'events_attended', upp.total_events_attended
                )
            )
        ) as packages
        from public.universal_package_purchases upp
        join public.purchases p on upp.purchase_id = p.id
        join public.universal_packages up on upp.package_id = up.id
        where p.user_id = v_user_id
        and upp.status = 'active'
        and (upp.expires_at is null or upp.expires_at > current_timestamp)
    ) active_packages,
    (
        -- Credit totals
        select 
            sum(upp.appointment_credits_remaining) as appointment_credits,
            sum(upp.content_credits_remaining) as content_credits,
            sum(upp.event_credits_remaining) as event_credits
        from public.universal_package_purchases upp
        join public.purchases p on upp.purchase_id = p.id
        where p.user_id = v_user_id
        and upp.status = 'active'
        and (upp.expires_at is null or upp.expires_at > current_timestamp)
    ) totals,
    (
        -- Expiring soon (within 7 days)
        select jsonb_agg(
            jsonb_build_object(
                'id', upp.id,
                'package_name', up.name,
                'expires_at', upp.expires_at,
                'days_remaining', extract(days from upp.expires_at - current_timestamp)
            )
        ) as packages
        from public.universal_package_purchases upp
        join public.purchases p on upp.purchase_id = p.id
        join public.universal_packages up on upp.package_id = up.id
        where p.user_id = v_user_id
        and upp.status = 'active'
        and upp.expires_at is not null
        and upp.expires_at > current_timestamp
        and upp.expires_at <= current_timestamp + interval '7 days'
    ) expiring,
    (
        -- This month's usage
        select jsonb_build_object(
            'appointments_used', coalesce(sum(case when pul.access_type = 'appointment' then pul.credits_used end), 0),
            'content_accessed', coalesce(sum(case when pul.access_type in ('content', 'post') then pul.credits_used end), 0),
            'events_attended', coalesce(sum(case when pul.access_type = 'event' then pul.credits_used end), 0),
            'total_credits_used', coalesce(sum(pul.credits_used), 0)
        ) as monthly_usage
        from public.package_usage_log pul
        join public.universal_package_purchases upp on pul.package_purchase_id = upp.id
        join public.purchases p on upp.purchase_id = p.id
        where p.user_id = v_user_id
        and pul.access_date >= date_trunc('month', current_timestamp)
    ) usage;
    
    return v_result;
end;
$$;

-- Get creator's package analytics
drop function if exists public.get_creator_package_analytics;
create or replace function public.get_creator_package_analytics(
    p_creator_id uuid default null,
    p_date_range_days integer default 30
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_creator_id uuid;
    v_result jsonb;
begin
    v_creator_id := coalesce(p_creator_id, auth.uid());
    
    if v_creator_id is null then
        raise exception 'Authentication required';
    end if;
    
    select jsonb_build_object(
        'package_performance', coalesce(performance.data, '[]'::jsonb),
        'revenue_summary', coalesce(revenue.data, '{}'::jsonb),
        'customer_insights', coalesce(customers.data, '{}'::jsonb),
        'usage_patterns', coalesce(usage.data, '[]'::jsonb)
    ) into v_result
    from (
        -- Package performance
        select jsonb_agg(
            jsonb_build_object(
                'package_id', up.id,
                'package_name', up.name,
                'package_type', up.package_type,
                'total_purchases', count(upp.id),
                'active_subscriptions', count(case when upp.status = 'active' then 1 end),
                'total_revenue', coalesce(sum(p.amount), 0),
                'avg_purchase_amount', coalesce(avg(p.amount), 0),
                'conversion_rate', 
                    case when count(upp.id) > 0 then
                        round((count(case when upp.status = 'active' then 1 end)::numeric / count(upp.id)) * 100, 2)
                    else 0 
                    end
            )
        ) as data
        from public.universal_packages up
        left join public.universal_package_purchases upp on up.id = upp.package_id
        left join public.purchases p on upp.purchase_id = p.id
        where up.creator_id = v_creator_id
        and (p.purchase_date >= current_timestamp - (p_date_range_days || ' days')::interval or p.purchase_date is null)
        group by up.id, up.name, up.package_type
    ) performance,
    (
        -- Revenue summary
        select jsonb_build_object(
            'total_revenue', coalesce(sum(p.amount), 0),
            'recurring_revenue', coalesce(sum(case when up.is_recurring then p.amount end), 0),
            'one_time_revenue', coalesce(sum(case when not up.is_recurring then p.amount end), 0),
            'avg_package_value', coalesce(avg(p.amount), 0),
            'revenue_by_type', revenue_by_type.types
        ) as data
        from public.purchases p
        join public.universal_package_purchases upp on p.id = upp.purchase_id
        join public.universal_packages up on upp.package_id = up.id
        cross join (
            select jsonb_object_agg(up2.package_type, revenue_data.revenue) as types
            from (
                select up2.package_type, coalesce(sum(p2.amount), 0) as revenue
                from public.universal_packages up2
                left join public.universal_package_purchases upp2 on up2.id = upp2.package_id
                left join public.purchases p2 on upp2.purchase_id = p2.id
                where up2.creator_id = v_creator_id
                and (p2.purchase_date >= current_timestamp - (p_date_range_days || ' days')::interval or p2.purchase_date is null)
                group by up2.package_type
            ) revenue_data
        ) revenue_by_type
        where up.creator_id = v_creator_id
        and p.purchase_date >= current_timestamp - (p_date_range_days || ' days')::interval
    ) revenue,
    (
        -- Customer insights
        select jsonb_build_object(
            'total_customers', count(distinct p.user_id),
            'active_customers', count(distinct case when upp.status = 'active' then p.user_id end),
            'retention_rate', 
                case when count(distinct p.user_id) > 0 then
                    round((count(distinct case when upp.status = 'active' then p.user_id end)::numeric / count(distinct p.user_id)) * 100, 2)
                else 0 
                end,
            'avg_customer_lifetime_value', coalesce(avg(customer_value.total_spent), 0)
        ) as data
        from public.purchases p
        join public.universal_package_purchases upp on p.id = upp.purchase_id
        join public.universal_packages up on upp.package_id = up.id
        cross join (
            select p3.user_id, sum(p3.amount) as total_spent
            from public.purchases p3
            join public.universal_package_purchases upp3 on p3.id = upp3.purchase_id
            join public.universal_packages up3 on upp3.package_id = up3.id
            where up3.creator_id = v_creator_id
            group by p3.user_id
        ) customer_value
        where up.creator_id = v_creator_id
        and p.purchase_date >= current_timestamp - (p_date_range_days || ' days')::interval
    ) customers,
    (
        -- Usage patterns
        select jsonb_agg(
            jsonb_build_object(
                'date', usage_date,
                'total_usage', total_usage,
                'appointment_usage', appointment_usage,
                'content_usage', content_usage,
                'event_usage', event_usage
            )
        ) as data
        from (
            select 
                date_trunc('day', pul.access_date) as usage_date,
                count(*) as total_usage,
                count(case when pul.access_type = 'appointment' then 1 end) as appointment_usage,
                count(case when pul.access_type in ('content', 'post') then 1 end) as content_usage,
                count(case when pul.access_type = 'event' then 1 end) as event_usage
            from public.package_usage_log pul
            join public.universal_package_purchases upp on pul.package_purchase_id = upp.id
            join public.universal_packages up on upp.package_id = up.id
            where up.creator_id = v_creator_id
            and pul.access_date >= current_timestamp - (p_date_range_days || ' days')::interval
            group by date_trunc('day', pul.access_date)
            order by usage_date desc
            limit 30
        ) daily_usage
    ) usage;
    
    return v_result;
end;
$$;

-- ====================================
-- SUBSCRIPTION MANAGEMENT FUNCTIONS
-- ====================================

-- Refresh package credits (for monthly/weekly allowances)
drop function if exists public.refresh_package_credits;
create or replace function public.refresh_package_credits()
returns void
language plpgsql
security definer
as $$
declare
    v_package_purchase record;
begin
    -- Loop through packages that need credit refresh
    for v_package_purchase in
        select upp.*, up.total_appointment_credits, up.total_content_credits, up.total_event_credits,
               up.appointment_access_pattern, up.content_access_pattern, up.event_access_pattern
        from public.universal_package_purchases upp
        join public.universal_packages up on upp.package_id = up.id
        where upp.status = 'active'
        and upp.next_credit_refresh_at <= current_timestamp
        and (
            up.appointment_access_pattern in ('monthly_allowance', 'weekly_allowance') or
            up.content_access_pattern in ('monthly_allowance', 'weekly_allowance') or
            up.event_access_pattern in ('monthly_allowance', 'weekly_allowance')
        )
    loop
        -- Calculate next refresh date
        declare
            v_next_refresh timestamp with time zone;
        begin
            -- Determine refresh interval (use the shortest interval if mixed)
            if v_package_purchase.appointment_access_pattern = 'weekly_allowance' or
               v_package_purchase.content_access_pattern = 'weekly_allowance' or
               v_package_purchase.event_access_pattern = 'weekly_allowance' then
                v_next_refresh := current_timestamp + interval '1 week';
            else
                v_next_refresh := current_timestamp + interval '1 month';
            end if;
            
            -- Reset credits based on access pattern
            update public.universal_package_purchases
            set 
                appointment_credits_remaining = case 
                    when v_package_purchase.appointment_access_pattern in ('monthly_allowance', 'weekly_allowance')
                    then v_package_purchase.total_appointment_credits
                    else appointment_credits_remaining
                end,
                content_credits_remaining = case 
                    when v_package_purchase.content_access_pattern in ('monthly_allowance', 'weekly_allowance')
                    then v_package_purchase.total_content_credits
                    else content_credits_remaining
                end,
                event_credits_remaining = case 
                    when v_package_purchase.event_access_pattern in ('monthly_allowance', 'weekly_allowance')
                    then v_package_purchase.total_event_credits
                    else event_credits_remaining
                end,
                last_credit_refresh_at = current_timestamp,
                next_credit_refresh_at = v_next_refresh,
                updated_at = current_timestamp
            where id = v_package_purchase.id;
        end;
    end loop;
end;
$$;

-- Function to cancel package subscription
drop function if exists public.cancel_package_subscription;
create or replace function public.cancel_package_subscription(
    p_package_purchase_id uuid,
    p_immediate boolean default false
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_package_purchase record;
    v_cancellation_date timestamp with time zone;
begin
    v_user_id := auth.uid();
    
    if v_user_id is null then
        raise exception 'Authentication required';
    end if;
    
    -- Get package purchase
    select upp.*, p.user_id into v_package_purchase
    from public.universal_package_purchases upp
    join public.purchases p on upp.purchase_id = p.id
    where upp.id = p_package_purchase_id
    and p.user_id = v_user_id;
    
    if not found then
        raise exception 'Package subscription not found';
    end if;
    
    if not v_package_purchase.is_recurring then
        raise exception 'Package is not a subscription';
    end if;
    
    -- Determine cancellation date
    if p_immediate then
        v_cancellation_date := current_timestamp;
    else
        v_cancellation_date := coalesce(v_package_purchase.current_period_end, current_timestamp);
    end if;
    
    -- Update package status
    update public.universal_package_purchases
    set 
        status = case when p_immediate then 'canceled' else status end,
        expires_at = v_cancellation_date,
        next_billing_date = null,
        updated_at = current_timestamp
    where id = p_package_purchase_id;
    
    return jsonb_build_object(
        'success', true,
        'package_purchase_id', p_package_purchase_id,
        'cancellation_date', v_cancellation_date,
        'immediate', p_immediate
    );
end;
$$;

-- ====================================
-- INTEGRATION WITH EXISTING CONTENT ACCESS
-- ====================================

-- Enhanced content access function that includes package checks
drop function if exists public.can_access_content_enhanced;
create or replace function public.can_access_content_enhanced(
    p_content_id uuid
) returns boolean
language plpgsql
security definer
as $$
declare
    v_has_direct_access boolean;
    v_has_subscription_access boolean;
    v_has_package_access boolean;
    v_package_check jsonb;
begin
    -- Check existing access methods first
    v_has_direct_access := can_access_content_v2(p_content_id);
    
    if v_has_direct_access then
        return true;
    end if;
    
    -- Check package access
    v_package_check := can_access_with_package('content', p_content_id);
    v_has_package_access := (v_package_check->>'can_access')::boolean;
    
    return v_has_package_access;
end;
$$;

-- ====================================
-- GRANTS & PERMISSIONS
-- ====================================

grant execute on function public.create_user_defined_package to authenticated, service_role;
grant execute on function public.get_user_packages_dashboard to authenticated, service_role;
grant execute on function public.get_creator_package_analytics to authenticated, service_role;
grant execute on function public.refresh_package_credits to service_role;
grant execute on function public.cancel_package_subscription to authenticated, service_role;
grant execute on function public.can_access_content_enhanced to authenticated, service_role;

-- ====================================
-- COMMENTS
-- ====================================

comment on function public.create_user_defined_package is 'Allows users to customize packages from templates with their own credit amounts';
comment on function public.get_user_packages_dashboard is 'Returns comprehensive dashboard data for user package purchases';
comment on function public.get_creator_package_analytics is 'Provides detailed analytics for creators about their package performance';
comment on function public.refresh_package_credits is 'Scheduled function to refresh credits for monthly/weekly allowance packages';
comment on function public.cancel_package_subscription is 'Cancels a recurring package subscription';
comment on function public.can_access_content_enhanced is 'Enhanced content access that includes package-based access checks'; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
