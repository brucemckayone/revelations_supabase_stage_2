-- Generated with srtd from template: supabase/migrations-templates/20250107000009_universal_packages_webhook_functions.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Universal Packages Webhook Functions
-- Missing functions for Stripe integration and webhook processing

-- ====================================
-- WEBHOOK FUNCTION FOR UNIVERSAL PACKAGES
-- ====================================



-- Function to process universal package purchase payment (for webhook processing)
-- This function is called after a purchase record already exists and payment is confirmed
drop function if exists public.process_universal_package_purchase_payment;
create or replace function public.process_universal_package_purchase_payment(
    p_purchase_id uuid,
    p_payment_intent_id text,
    p_package_id uuid
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_purchase public.purchases;
    v_package public.universal_packages;
    v_package_purchase_id uuid;
    v_expires_at timestamp with time zone;
    v_next_billing timestamp with time zone;
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
    from public.universal_packages
    where id = p_package_id 
    and is_active = true;
    
    if not found then
        raise exception 'Package not found or not active: package_id=%', p_package_id;
    end if;
    
    -- Validate that this purchase is for the correct creator
    if v_purchase.owner_id != v_package.creator_id then
        raise exception 'Purchase owner_id mismatch: expected=%, actual=%', 
            v_package.creator_id, v_purchase.owner_id;
    end if;
    
    -- Calculate expiration date
    if v_package.duration_weeks is not null then
        v_expires_at := current_timestamp + (v_package.duration_weeks || ' weeks')::interval;
    end if;
    
    -- Calculate next billing date for recurring packages
    if v_package.is_recurring and v_package.recurring_interval_weeks is not null then
        v_next_billing := current_timestamp + (v_package.recurring_interval_weeks || ' weeks')::interval;
    end if;
    
    -- Update purchase record with package-specific details
    update public.purchases
    set 
        purchase_type = 'package',
        end_date = v_expires_at,
        updated_at = current_timestamp
    where id = p_purchase_id;
    
    -- Create universal package purchase tracking record
    insert into public.universal_package_purchases (
        purchase_id, 
        package_id, 
        appointment_credits_remaining,
        content_credits_remaining,
        event_credits_remaining,
        is_recurring,
        expires_at,
        next_billing_date,
        current_period_start,
        current_period_end
    ) values (
        p_purchase_id, 
        p_package_id, 
        v_package.total_appointment_credits,
        v_package.total_content_credits,
        v_package.total_event_credits,
        v_package.is_recurring,
        v_expires_at,
        v_next_billing,
        current_timestamp,
        v_expires_at
    ) returning id into v_package_purchase_id;
    
    -- Build result
    v_result := jsonb_build_object(
        'success', true,
        'purchase_id', p_purchase_id,
        'package_purchase_id', v_package_purchase_id,
        'package_id', p_package_id,
        'package_type', v_package.package_type,
        'appointment_credits_remaining', v_package.total_appointment_credits,
        'content_credits_remaining', v_package.total_content_credits,
        'event_credits_remaining', v_package.total_event_credits,
        'expires_at', v_expires_at,
        'next_billing_date', v_next_billing,
        'package_name', v_package.name,
        'package_description', v_package.description,
        'user_id', v_purchase.user_id,
        'owner_id', v_purchase.owner_id,
        'amount', v_purchase.amount,
        'currency', v_purchase.currency,
        'is_recurring', v_package.is_recurring
    );
    
    return v_result;
end;
$$;

-- ====================================
-- PACKAGE TEMPLATE MANAGEMENT
-- ====================================

-- Function to create default package templates for new creators
drop function if exists public.create_default_package_templates;
create or replace function public.create_default_package_templates(
    p_creator_id uuid default null
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_creator_id uuid;
    v_template_ids uuid[] := '{}';
    v_template_id uuid;
begin
    v_creator_id := coalesce(p_creator_id, auth.uid());
    
    if v_creator_id is null then
        raise exception 'Creator ID required';
    end if;
    
    -- Template 1: Content Creator Essentials
    insert into public.universal_packages (
        creator_id, name, description, package_type, price,
        duration_weeks, is_recurring,
        total_appointment_credits, total_content_credits, total_event_credits,
        appointment_access_pattern, content_access_pattern, event_access_pattern,
        is_active, is_featured,
        configuration
    ) values (
        v_creator_id, 
        'Content Creator Essentials', 
        'Perfect starter package with mix of content access and 1:1 sessions',
        'hybrid_credits',
        49.99,
        4, -- 4 weeks
        false,
        2, 20, 1, -- 2 appointments, 20 content pieces, 1 event
        'pay_per_use', 'pay_per_use', 'pay_per_use',
        true, false,
        jsonb_build_object(
            'template_type', 'essentials',
            'appointment_credit_price', 25.0,
            'content_credit_price', 2.5,
            'event_credit_price', 15.0,
            'customizable', true
        )
    ) returning id into v_template_id;
    v_template_ids := array_append(v_template_ids, v_template_id);
    
    -- Template 2: Premium All-Access
    insert into public.universal_packages (
        creator_id, name, description, package_type, price,
        duration_weeks, is_recurring, recurring_interval_weeks,
        total_appointment_credits, total_content_credits, total_event_credits,
        appointment_access_pattern, content_access_pattern, event_access_pattern,
        is_active, is_featured,
        configuration
    ) values (
        v_creator_id,
        'Premium All-Access',
        'Unlimited content access with monthly 1:1 sessions',
        'unlimited_content',
        99.99,
        4, -- 4 week billing cycle
        true, 4, -- recurring every 4 weeks
        2, 0, 0, -- 2 monthly appointments, unlimited content
        'monthly_allowance', 'unlimited', 'unlimited',
        true, true,
        jsonb_build_object(
            'template_type', 'premium',
            'unlimited_content_types', array['yoga', 'dance', 'meditation', 'article', 'video'],
            'customizable', false
        )
    ) returning id into v_template_id;
    v_template_ids := array_append(v_template_ids, v_template_id);
    
    -- Template 3: Beginner Friendly
    insert into public.universal_packages (
        creator_id, name, description, package_type, price,
        duration_weeks, is_recurring,
        total_appointment_credits, total_content_credits, total_event_credits,
        appointment_access_pattern, content_access_pattern, event_access_pattern,
        is_active, is_featured,
        configuration
    ) values (
        v_creator_id,
        'Beginner Friendly',
        'Perfect introduction with guided content and intro session',
        'content_credits',
        24.99,
        2, -- 2 weeks
        false,
        1, 10, 0, -- 1 intro session, 10 beginner pieces
        'pay_per_use', 'pay_per_use', 'pay_per_use',
        true, false,
        jsonb_build_object(
            'template_type', 'beginner',
            'difficulty_filter', 'beginner',
            'daily_content_limit', 2,
            'customizable', true
        )
    ) returning id into v_template_id;
    v_template_ids := array_append(v_template_ids, v_template_id);
    
    -- Template 4: Custom Builder
    insert into public.universal_packages (
        creator_id, name, description, package_type, price,
        duration_weeks, is_recurring,
        total_appointment_credits, total_content_credits, total_event_credits,
        appointment_access_pattern, content_access_pattern, event_access_pattern,
        is_active, is_featured,
        configuration
    ) values (
        v_creator_id,
        'Build Your Own',
        'Fully customizable package - users choose their own credits and duration',
        'custom_bundle',
        0, -- Price calculated dynamically
        null, -- User chooses duration
        false,
        0, 0, 0, -- User chooses credits
        'pay_per_use', 'pay_per_use', 'pay_per_use',
        true, false,
        jsonb_build_object(
            'template_type', 'custom',
            'base_price', 10.0,
            'appointment_credit_price', 30.0,
            'content_credit_price', 3.0,
            'event_credit_price', 20.0,
            'duration_week_price', 2.0,
            'min_total_credits', 5,
            'max_total_credits', 200,
            'min_duration_weeks', 1,
            'max_duration_weeks', 52,
            'customizable', true
        )
    ) returning id into v_template_id;
    v_template_ids := array_append(v_template_ids, v_template_id);
    
    return jsonb_build_object(
        'success', true,
        'creator_id', v_creator_id,
        'template_ids', v_template_ids,
        'templates_created', array_length(v_template_ids, 1)
    );
end;
$$;

-- ====================================
-- PACKAGE ACCESS RULE MANAGEMENT
-- ====================================

-- Function to add access rules to a package
drop function if exists public.add_package_access_rules;
create or replace function public.add_package_access_rules(
    p_package_id uuid,
    p_access_rules jsonb
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_creator_id uuid;
    v_rule jsonb;
    v_rule_ids uuid[] := '{}';
    v_rule_id uuid;
begin
    -- Verify package ownership
    select creator_id into v_creator_id
    from public.universal_packages
    where id = p_package_id and creator_id = auth.uid();
    
    if not found then
        raise exception 'Package not found or not owned by user';
    end if;
    
    -- Process each access rule
    for v_rule in select jsonb_array_elements(p_access_rules)
    loop
        insert into public.package_access_rules (
            package_id,
            service_id,
            content_id,
            post_id,
            post_type,
            event_id,
            access_type,
            credits_required,
            daily_limit,
            weekly_limit,
            monthly_limit,
            priority
        ) values (
            p_package_id,
            case when v_rule->>'service_id' != '' then (v_rule->>'service_id')::uuid else null end,
            case when v_rule->>'content_id' != '' then (v_rule->>'content_id')::uuid else null end,
            case when v_rule->>'post_id' != '' then (v_rule->>'post_id')::uuid else null end,
            case when v_rule->>'post_type' != '' then v_rule->>'post_type' else null end,
            case when v_rule->>'event_id' != '' then (v_rule->>'event_id')::uuid else null end,
            (v_rule->>'access_type')::access_pattern_enum,
            coalesce((v_rule->>'credits_required')::integer, 1),
            case when v_rule->>'daily_limit' != '' then (v_rule->>'daily_limit')::integer else null end,
            case when v_rule->>'weekly_limit' != '' then (v_rule->>'weekly_limit')::integer else null end,
            case when v_rule->>'monthly_limit' != '' then (v_rule->>'monthly_limit')::integer else null end,
            coalesce((v_rule->>'priority')::integer, 0)
        ) returning id into v_rule_id;
        
        v_rule_ids := array_append(v_rule_ids, v_rule_id);
    end loop;
    
    return jsonb_build_object(
        'success', true,
        'package_id', p_package_id,
        'rule_ids', v_rule_ids,
        'rules_created', array_length(v_rule_ids, 1)
    );
end;
$$;

-- ====================================
-- DEFAULT ACCESS RULES FOR TEMPLATES
-- ====================================

-- Function to create default access rules for template packages
drop function if exists public.create_default_access_rules_for_templates;
create or replace function public.create_default_access_rules_for_templates(
    p_creator_id uuid default null
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_creator_id uuid;
    v_template record;
    v_rules_created integer := 0;
begin
    v_creator_id := coalesce(p_creator_id, auth.uid());
    
    if v_creator_id is null then
        raise exception 'Creator ID required';
    end if;
    
    -- Add default rules for each template
    for v_template in 
        select id, name, configuration
        from public.universal_packages
        where creator_id = v_creator_id
        and configuration->>'template_type' is not null
    loop
        case v_template.configuration->>'template_type'
            when 'essentials' then
                -- Essentials: Mixed access to different content types
                insert into public.package_access_rules (package_id, post_type, access_type, credits_required, priority)
                values 
                    (v_template.id, 'article', 'unlimited', 0, 1),
                    (v_template.id, 'meditation', 'pay_per_use', 1, 2),
                    (v_template.id, 'yoga', 'pay_per_use', 1, 2),
                    (v_template.id, 'service', 'pay_per_use', 1, 3);
                v_rules_created := v_rules_created + 4;
                
            when 'premium' then
                -- Premium: Unlimited access to most content
                insert into public.package_access_rules (package_id, post_type, access_type, credits_required, priority)
                values 
                    (v_template.id, 'yoga', 'unlimited', 0, 1),
                    (v_template.id, 'dance', 'unlimited', 0, 1),
                    (v_template.id, 'meditation', 'unlimited', 0, 1),
                    (v_template.id, 'article', 'unlimited', 0, 1),
                    (v_template.id, 'video', 'unlimited', 0, 1),
                    (v_template.id, 'service', 'monthly_allowance', 1, 2),
                    (v_template.id, 'event', 'pay_per_use', 1, 2);
                v_rules_created := v_rules_created + 7;
                
            when 'beginner' then
                -- Beginner: Limited access with constraints
                insert into public.package_access_rules (package_id, post_type, access_type, credits_required, daily_limit, weekly_limit, priority)
                values 
                    (v_template.id, 'yoga', 'pay_per_use', 1, 2, null, 1),
                    (v_template.id, 'meditation', 'pay_per_use', 1, 3, 5, 1),
                    (v_template.id, 'article', 'unlimited', 0, null, null, 1),
                    (v_template.id, 'service', 'pay_per_use', 1, null, null, 2);
                v_rules_created := v_rules_created + 4;
                
            when 'custom' then
                -- Custom: No default rules - user will add their own
                null;
        end case;
    end loop;
    
    return jsonb_build_object(
        'success', true,
        'creator_id', v_creator_id,
        'rules_created', v_rules_created
    );
end;
$$;

-- ====================================
-- PACKAGE PURCHASE HELPERS
-- ====================================

-- Function to get package purchase with details
drop function if exists public.get_package_purchase_details;
create or replace function public.get_package_purchase_details(
    p_package_purchase_id uuid
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_result jsonb;
begin
    v_user_id := auth.uid();
    
    if v_user_id is null then
        raise exception 'Authentication required';
    end if;
    
    select jsonb_build_object(
        'package_purchase', jsonb_build_object(
            'id', upp.id,
            'appointment_credits_remaining', upp.appointment_credits_remaining,
            'content_credits_remaining', upp.content_credits_remaining,
            'event_credits_remaining', upp.event_credits_remaining,
            'is_recurring', upp.is_recurring,
            'expires_at', upp.expires_at,
            'next_billing_date', upp.next_billing_date,
            'status', upp.status,
            'total_appointments_used', upp.total_appointments_used,
            'total_content_accessed', upp.total_content_accessed,
            'total_events_attended', upp.total_events_attended,
            'created_at', upp.created_at
        ),
        'package', jsonb_build_object(
            'id', up.id,
            'name', up.name,
            'description', up.description,
            'package_type', up.package_type,
            'price', up.price,
            'currency', up.currency,
            'duration_weeks', up.duration_weeks,
            'total_appointment_credits', up.total_appointment_credits,
            'total_content_credits', up.total_content_credits,
            'total_event_credits', up.total_event_credits
        ),
        'creator', jsonb_build_object(
            'id', prof.id,
            'full_name', prof.full_name,
            'avatar_url', prof.avatar_url
        ),
        'access_rules', coalesce(rules.rules, '[]'::jsonb),
        'usage_stats', jsonb_build_object(
            'credits_used_percentage', jsonb_build_object(
                'appointments', case 
                    when up.total_appointment_credits > 0 then 
                        round((upp.total_appointments_used::numeric / up.total_appointment_credits) * 100, 2)
                    else 0 
                end,
                'content', case 
                    when up.total_content_credits > 0 then 
                        round((upp.total_content_accessed::numeric / up.total_content_credits) * 100, 2)
                    else 0 
                end,
                'events', case 
                    when up.total_event_credits > 0 then 
                        round((upp.total_events_attended::numeric / up.total_event_credits) * 100, 2)
                    else 0 
                end
            )
        )
    ) into v_result
    from public.universal_package_purchases upp
    join public.purchases p on upp.purchase_id = p.id
    join public.universal_packages up on upp.package_id = up.id
    join public.profiles prof on up.creator_id = prof.id
    left join (
        select 
            package_id,
            jsonb_agg(
                jsonb_build_object(
                    'id', par.id,
                    'service_id', par.service_id,
                    'content_id', par.content_id,
                    'post_id', par.post_id,
                    'post_type', par.post_type,
                    'event_id', par.event_id,
                    'access_type', par.access_type,
                    'credits_required', par.credits_required,
                    'daily_limit', par.daily_limit,
                    'weekly_limit', par.weekly_limit,
                    'monthly_limit', par.monthly_limit,
                    'priority', par.priority
                )
            ) as rules
        from public.package_access_rules par
        group by package_id
    ) rules on up.id = rules.package_id
    where upp.id = p_package_purchase_id
    and p.user_id = v_user_id;
    
    if v_result is null then
        raise exception 'Package purchase not found or not accessible';
    end if;
    
    return v_result;
end;
$$;

-- ====================================
-- STRIPE INTEGRATION HELPERS
-- ====================================

-- Function to prepare package for Stripe checkout
drop function if exists public.prepare_package_for_stripe;
create or replace function public.prepare_package_for_stripe(
    p_package_id uuid
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_package public.universal_packages;
    v_stripe_metadata jsonb;
begin
    -- Get package details
    select * into v_package
    from public.universal_packages
    where id = p_package_id and is_active = true;
    
    if not found then
        raise exception 'Package not found or not available';
    end if;
    
    -- Build Stripe metadata
    v_stripe_metadata := jsonb_build_object(
        'purchase_type', 'universal_package',
        'package_id', v_package.id,
        'package_type', v_package.package_type,
        'creator_id', v_package.creator_id,
        'appointment_credits', v_package.total_appointment_credits,
        'content_credits', v_package.total_content_credits,
        'event_credits', v_package.total_event_credits,
        'is_recurring', v_package.is_recurring,
        'duration_weeks', v_package.duration_weeks,
        'is_user_defined', v_package.is_user_defined,
        'template_package_id', v_package.template_package_id
    );
    
    return jsonb_build_object(
        'package_id', v_package.id,
        'name', v_package.name,
        'description', v_package.description,
        'price', v_package.price,
        'currency', v_package.currency,
        'stripe_metadata', v_stripe_metadata,
        'stripe_product_id', v_package.stripe_product_id,
        'stripe_price_id', v_package.stripe_price_id
    );
end;
$$;


-- ====================================
-- GRANTS & PERMISSIONS
-- ====================================

grant execute on function public.process_universal_package_purchase_payment to service_role;
grant execute on function public.create_default_package_templates to authenticated, service_role;
grant execute on function public.add_package_access_rules to authenticated, service_role;
grant execute on function public.create_default_access_rules_for_templates to authenticated, service_role;
grant execute on function public.get_package_purchase_details to authenticated, service_role;
grant execute on function public.prepare_package_for_stripe to authenticated, service_role;

-- ====================================
-- COMMENTS
-- ====================================


comment on function public.process_universal_package_purchase_payment is 'Process universal package purchase after payment confirmation (webhook handler)';
comment on function public.create_default_package_templates is 'Creates default package templates for new creators';
comment on function public.add_package_access_rules is 'Adds access rules to a package from JSON array';
comment on function public.create_default_access_rules_for_templates is 'Creates default access rules for template packages';
comment on function public.get_package_purchase_details is 'Gets complete package purchase details with creator info and access rules';
comment on function public.prepare_package_for_stripe is 'Prepares package data for Stripe checkout including metadata'; 


COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
