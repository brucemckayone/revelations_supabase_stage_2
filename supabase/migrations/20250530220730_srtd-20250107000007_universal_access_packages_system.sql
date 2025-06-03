-- Generated with srtd from template: supabase/migrations-templates/20250107000007_universal_access_packages_system.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Universal Access Packages System
-- Extends the existing package concept to handle all content types with flexible access controls

-- ====================================
-- ENHANCED PACKAGE TYPES & CATEGORIES 
-- ====================================

-- New enum for package types
do $$ begin
    create type package_access_type_enum as enum (
        'appointments_only',     -- Current appointment packages
        'content_credits',       -- Fixed number of content access credits
        'unlimited_content',     -- Unlimited access to specific content types
        'hybrid_credits',        -- Mix of appointments + content credits
        'full_access',          -- Everything unlimited for duration
        'custom_bundle'         -- User-defined mix of services
    );
exception
    when duplicate_object then null;
end $$;

-- New enum for content access patterns
do $$ begin
    create type access_pattern_enum as enum (
        'pay_per_use',          -- Each use deducts credits
        'unlimited',            -- Unlimited for package duration
        'monthly_allowance',    -- Refresh credits monthly
        'weekly_allowance'      -- Refresh credits weekly
    );
exception
    when duplicate_object then null;
end $$;

-- ====================================
-- UNIVERSAL PACKAGES TABLE
-- ====================================

create table if not exists public.universal_packages (
    id uuid primary key default gen_random_uuid(),
    creator_id uuid not null references auth.users(id) on delete cascade,
    
    -- Basic package info
    name text not null check (char_length(name) >= 2 and char_length(name) <= 100),
    description text,
    package_type package_access_type_enum not null default 'custom_bundle',
    
    -- Pricing
    price numeric(10,2) not null check (price >= 0),
    currency text not null default 'usd',
    
    -- Duration & availability
    duration_weeks integer check (duration_weeks > 0),  -- null = no expiration
    is_recurring boolean default false,                   -- subscription vs one-time
    recurring_interval_weeks integer check (recurring_interval_weeks > 0), -- for subscriptions
    
    -- Package configuration
    total_appointment_credits integer default 0 check (total_appointment_credits >= 0),
    total_content_credits integer default 0 check (total_content_credits >= 0),
    total_event_credits integer default 0 check (total_event_credits >= 0),
    
    -- Access patterns for different content types
    appointment_access_pattern access_pattern_enum default 'pay_per_use',
    content_access_pattern access_pattern_enum default 'pay_per_use',
    event_access_pattern access_pattern_enum default 'pay_per_use',
    
    -- Stripe integration
    stripe_product_id text,
    stripe_price_id text,
    
    -- Status
    is_active boolean default true,
    is_featured boolean default false,
    max_active_subscriptions integer, -- null = unlimited
    
    -- User-defined packages
    is_user_defined boolean default false,
    template_package_id uuid references public.universal_packages(id) on delete set null,
    
    -- Metadata for flexibility
    configuration jsonb default '{}',
    
    created_at timestamp with time zone default current_timestamp,
    updated_at timestamp with time zone default current_timestamp
);

-- Indexes for performance
create index if not exists idx_universal_packages_creator_id on public.universal_packages(creator_id);
create index if not exists idx_universal_packages_type on public.universal_packages(package_type);
create index if not exists idx_universal_packages_active on public.universal_packages(is_active) where is_active = true;
create index if not exists idx_universal_packages_featured on public.universal_packages(is_featured) where is_featured = true;

-- ====================================
-- PACKAGE ACCESS RULES TABLE
-- ====================================

create table if not exists public.package_access_rules (
    id uuid primary key default gen_random_uuid(),
    package_id uuid not null references public.universal_packages(id) on delete cascade,
    
    -- What this rule grants access to (only one should be set)
    service_id uuid references public.services(id) on delete cascade,
    content_id uuid references public.on_demand_media(id) on delete cascade,
    post_id uuid references public.posts(id) on delete cascade,
    post_type text, -- grants access to all posts of this type
    event_id uuid references public.events(id) on delete cascade,
    
    -- Access configuration
    access_type access_pattern_enum not null default 'pay_per_use',
    credits_required integer default 1 check (credits_required > 0),
    
    -- Constraints
    daily_limit integer check (daily_limit > 0),
    weekly_limit integer check (weekly_limit > 0), 
    monthly_limit integer check (monthly_limit > 0),
    
    -- Priority (higher number = higher priority when multiple rules match)
    priority integer default 0,
    
    created_at timestamp with time zone default current_timestamp,
    
    -- Ensure only one target type is specified
    constraint check_single_access_target check (
        (service_id is not null)::integer +
        (content_id is not null)::integer +
        (post_id is not null)::integer +
        (post_type is not null)::integer +
        (event_id is not null)::integer = 1
    )
);

-- Indexes
create index if not exists idx_package_access_rules_package_id on public.package_access_rules(package_id);
create index if not exists idx_package_access_rules_service_id on public.package_access_rules(service_id) where service_id is not null;
create index if not exists idx_package_access_rules_content_id on public.package_access_rules(content_id) where content_id is not null;
create index if not exists idx_package_access_rules_post_type on public.package_access_rules(post_type) where post_type is not null;

-- ====================================
-- UNIVERSAL PACKAGE PURCHASES TABLE
-- ====================================

create table if not exists public.universal_package_purchases (
    id uuid primary key default gen_random_uuid(),
    purchase_id uuid not null references public.purchases(id) on delete cascade,
    package_id uuid not null references public.universal_packages(id) on delete restrict,
    
    -- Current credit balances
    appointment_credits_remaining integer default 0 check (appointment_credits_remaining >= 0),
    content_credits_remaining integer default 0 check (content_credits_remaining >= 0),
    event_credits_remaining integer default 0 check (event_credits_remaining >= 0),
    
    -- Subscription info
    is_recurring boolean default false,
    current_period_start timestamp with time zone,
    current_period_end timestamp with time zone,
    next_billing_date timestamp with time zone,
    
    -- Package lifecycle
    activated_at timestamp with time zone default current_timestamp,
    expires_at timestamp with time zone,
    status text not null default 'active' check (status in ('active', 'expired', 'canceled', 'suspended')),
    
    -- Usage tracking
    total_appointments_used integer default 0 check (total_appointments_used >= 0),
    total_content_accessed integer default 0 check (total_content_accessed >= 0),
    total_events_attended integer default 0 check (total_events_attended >= 0),
    
    -- Credit refresh tracking (for monthly/weekly allowances)
    last_credit_refresh_at timestamp with time zone,
    next_credit_refresh_at timestamp with time zone,
    
    created_at timestamp with time zone default current_timestamp,
    updated_at timestamp with time zone default current_timestamp
);

-- Indexes
create index if not exists idx_universal_package_purchases_purchase_id on public.universal_package_purchases(purchase_id);
create index if not exists idx_universal_package_purchases_package_id on public.universal_package_purchases(package_id);
create index if not exists idx_universal_package_purchases_status on public.universal_package_purchases(status);
create index if not exists idx_universal_package_purchases_expires_at on public.universal_package_purchases(expires_at);

-- ====================================
-- PACKAGE USAGE LOG TABLE
-- ====================================

create table if not exists public.package_usage_log (
    id uuid primary key default gen_random_uuid(),
    package_purchase_id uuid not null references public.universal_package_purchases(id) on delete cascade,
    
    -- What was accessed
    access_type text not null check (access_type in ('appointment', 'content', 'event', 'post')),
    resource_id uuid not null, -- ID of the accessed resource
    
    -- Credits used
    credits_used integer not null default 1 check (credits_used > 0),
    
    -- Usage details
    access_date timestamp with time zone default current_timestamp,
    metadata jsonb default '{}',
    
    created_at timestamp with time zone default current_timestamp
);

-- Indexes
create index if not exists idx_package_usage_log_package_purchase_id on public.package_usage_log(package_purchase_id);
create index if not exists idx_package_usage_log_access_type on public.package_usage_log(access_type);
create index if not exists idx_package_usage_log_access_date on public.package_usage_log(access_date);

-- ====================================
-- FUNCTIONS FOR PACKAGE MANAGEMENT
-- ====================================

drop function if exists public.create_universal_package;
-- Function to create a universal package
create or replace function public.create_universal_package(
    p_name text,
    p_description text,
    p_package_type package_access_type_enum,
    p_price numeric(10,2),
    p_duration_weeks integer default null,
    p_is_recurring boolean default false,
    p_appointment_credits integer default 0,
    p_content_credits integer default 0,
    p_event_credits integer default 0,
    p_configuration jsonb default '{}'
) returns uuid
language plpgsql
security definer
as $$
declare
    v_package_id uuid;
    v_creator_id uuid;
begin
    v_creator_id := auth.uid();
    
    if v_creator_id is null then
        raise exception 'Authentication required';
    end if;
    
    insert into public.universal_packages (
        creator_id, name, description, package_type, price,
        duration_weeks, is_recurring,
        total_appointment_credits, total_content_credits, total_event_credits,
        configuration
    ) values (
        v_creator_id, p_name, p_description, p_package_type, p_price,
        p_duration_weeks, p_is_recurring,
        p_appointment_credits, p_content_credits, p_event_credits,
        p_configuration
    ) returning id into v_package_id;
    
    return v_package_id;
end;
$$;


drop function if exists public.purchase_universal_package;
-- Function to purchase a universal package
create or replace function public.purchase_universal_package(
    p_package_id uuid,
    p_stripe_payment_intent_id text default null
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_package public.universal_packages;
    v_purchase_id uuid;
    v_package_purchase_id uuid;
    v_expires_at timestamp with time zone;
    v_next_billing timestamp with time zone;
begin
    v_user_id := auth.uid();
    
    if v_user_id is null then
        raise exception 'Authentication required';
    end if;
    
    -- Get package details
    select * into v_package
    from public.universal_packages
    where id = p_package_id and is_active = true;
    
    if not found then
        raise exception 'Package not found or not available';
    end if;
    
    -- Calculate dates
    if v_package.duration_weeks is not null then
        v_expires_at := current_timestamp + (v_package.duration_weeks || ' weeks')::interval;
    end if;
    
    if v_package.is_recurring and v_package.recurring_interval_weeks is not null then
        v_next_billing := current_timestamp + (v_package.recurring_interval_weeks || ' weeks')::interval;
    end if;
    
    -- Create purchase record
    insert into public.purchases (
        user_id, owner_id, stripe_payment_intent_id,
        amount, currency, payment_status,
        purchase_type, purchase_date
    ) values (
        v_user_id, v_package.creator_id, p_stripe_payment_intent_id,
        v_package.price, v_package.currency, 'completed',
        'package', current_timestamp
    ) returning id into v_purchase_id;
    
    -- Create package purchase tracking
    insert into public.universal_package_purchases (
        purchase_id, package_id,
        appointment_credits_remaining, content_credits_remaining, event_credits_remaining,
        is_recurring, expires_at, next_billing_date,
        current_period_start, current_period_end
    ) values (
        v_purchase_id, p_package_id,
        v_package.total_appointment_credits, v_package.total_content_credits, v_package.total_event_credits,
        v_package.is_recurring, v_expires_at, v_next_billing,
        current_timestamp, v_expires_at
    ) returning id into v_package_purchase_id;
    
    return jsonb_build_object(
        'success', true,
        'purchase_id', v_purchase_id,
        'package_purchase_id', v_package_purchase_id,
        'package_id', p_package_id,
        'expires_at', v_expires_at,
        'appointment_credits', v_package.total_appointment_credits,
        'content_credits', v_package.total_content_credits,
        'event_credits', v_package.total_event_credits
    );
end;
$$;

-- Function to check if user can access content with package
create or replace function public.can_access_with_package(
    p_access_type text, -- 'appointment', 'content', 'event', 'post'
    p_resource_id uuid
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_package_purchase record;
    v_access_rule record;
    v_can_access boolean := false;
    v_credits_required integer := 1;
    v_package_purchase_id uuid;
begin
    v_user_id := auth.uid();
    
    if v_user_id is null then
        return jsonb_build_object('can_access', false, 'reason', 'Authentication required');
    end if;
    
    -- Find active package purchases for this user
    for v_package_purchase in 
        select upp.*, up.package_type
        from public.universal_package_purchases upp
        join public.purchases p on upp.purchase_id = p.id
        join public.universal_packages up on upp.package_id = up.id
        where p.user_id = v_user_id
        and upp.status = 'active'
        and (upp.expires_at is null or upp.expires_at > current_timestamp)
        order by upp.created_at desc
    loop
        -- Check if this package has rules that grant access to the resource
        for v_access_rule in
            select par.*, 
                   case 
                     when p_access_type = 'appointment' then par.service_id = p_resource_id
                     when p_access_type = 'content' then par.content_id = p_resource_id
                     when p_access_type = 'event' then par.event_id = p_resource_id
                     when p_access_type = 'post' then par.post_id = p_resource_id
                     else false
                   end as direct_match,
                   case 
                     when p_access_type = 'post' then 
                       exists(select 1 from public.posts where id = p_resource_id and post_type = par.post_type)
                     else false
                   end as type_match
            from public.package_access_rules par
            where par.package_id = v_package_purchase.package_id
            order by par.priority desc, par.created_at asc
        loop
            if v_access_rule.direct_match or v_access_rule.type_match then
                v_credits_required := v_access_rule.credits_required;
                v_package_purchase_id := v_package_purchase.id;
                
                -- Check if unlimited access
                if v_access_rule.access_type = 'unlimited' then
                    v_can_access := true;
                    exit;
                end if;
                
                -- Check credits based on access type
                case p_access_type
                    when 'appointment' then
                        if v_package_purchase.appointment_credits_remaining >= v_credits_required then
                            v_can_access := true;
                            exit;
                        end if;
                    when 'content', 'post' then
                        if v_package_purchase.content_credits_remaining >= v_credits_required then
                            v_can_access := true;
                            exit;
                        end if;
                    when 'event' then
                        if v_package_purchase.event_credits_remaining >= v_credits_required then
                            v_can_access := true;
                            exit;
                        end if;
                end case;
            end if;
        end loop;
        
        if v_can_access then
            exit;
        end if;
    end loop;
    
    return jsonb_build_object(
        'can_access', v_can_access,
        'package_purchase_id', v_package_purchase_id,
        'credits_required', v_credits_required,
        'access_type', p_access_type,
        'resource_id', p_resource_id
    );
end;
$$;

-- Function to use package credits
create or replace function public.use_package_credits(
    p_package_purchase_id uuid,
    p_access_type text,
    p_resource_id uuid,
    p_credits_used integer default 1
) returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_package_purchase record;
    v_updated_credits integer;
begin
    v_user_id := auth.uid();
    
    if v_user_id is null then
        raise exception 'Authentication required';
    end if;
    
    -- Get package purchase and verify ownership
    select upp.*, p.user_id into v_package_purchase
    from public.universal_package_purchases upp
    join public.purchases p on upp.purchase_id = p.id
    where upp.id = p_package_purchase_id
    and p.user_id = v_user_id
    and upp.status = 'active';
    
    if not found then
        raise exception 'Package purchase not found or not accessible';
    end if;
    
    -- Deduct credits based on access type
    case p_access_type
        when 'appointment' then
            if v_package_purchase.appointment_credits_remaining < p_credits_used then
                raise exception 'Insufficient appointment credits';
            end if;
            
            update public.universal_package_purchases
            set 
                appointment_credits_remaining = appointment_credits_remaining - p_credits_used,
                total_appointments_used = total_appointments_used + 1,
                updated_at = current_timestamp
            where id = p_package_purchase_id
            returning appointment_credits_remaining into v_updated_credits;
            
        when 'content', 'post' then
            if v_package_purchase.content_credits_remaining < p_credits_used then
                raise exception 'Insufficient content credits';
            end if;
            
            update public.universal_package_purchases
            set 
                content_credits_remaining = content_credits_remaining - p_credits_used,
                total_content_accessed = total_content_accessed + 1,
                updated_at = current_timestamp
            where id = p_package_purchase_id
            returning content_credits_remaining into v_updated_credits;
            
        when 'event' then
            if v_package_purchase.event_credits_remaining < p_credits_used then
                raise exception 'Insufficient event credits';
            end if;
            
            update public.universal_package_purchases
            set 
                event_credits_remaining = event_credits_remaining - p_credits_used,
                total_events_attended = total_events_attended + 1,
                updated_at = current_timestamp
            where id = p_package_purchase_id
            returning event_credits_remaining into v_updated_credits;
    end case;
    
    -- Log the usage
    insert into public.package_usage_log (
        package_purchase_id, access_type, resource_id, credits_used
    ) values (
        p_package_purchase_id, p_access_type, p_resource_id, p_credits_used
    );
    
    return jsonb_build_object(
        'success', true,
        'credits_used', p_credits_used,
        'remaining_credits', v_updated_credits,
        'access_type', p_access_type
    );
end;
$$;

-- ====================================
-- RLS POLICIES
-- ====================================

-- Universal packages
alter table public.universal_packages enable row level security;

drop policy if exists "creators_manage_packages" on public.universal_packages;
create policy "creators_manage_packages" on public.universal_packages
    for all using (creator_id = auth.uid());

drop policy if exists "public_view_active_packages" on public.universal_packages;
create policy "public_view_active_packages" on public.universal_packages
    for select using (is_active = true);

-- Package access rules
alter table public.package_access_rules enable row level security;

drop policy if exists "creators_manage_access_rules" on public.package_access_rules;
create policy "creators_manage_access_rules" on public.package_access_rules
    for all using (
        exists(
            select 1 from public.universal_packages up 
            where up.id = package_id and up.creator_id = auth.uid()
        )
    );

-- Package purchases
alter table public.universal_package_purchases enable row level security;

drop policy if exists "users_view_own_package_purchases" on public.universal_package_purchases;
create policy "users_view_own_package_purchases" on public.universal_package_purchases
    for select using (
        exists(
            select 1 from public.purchases p 
            where p.id = purchase_id and p.user_id = auth.uid()
        )
    );

drop policy if exists "creators_view_package_sales" on public.universal_package_purchases;
create policy "creators_view_package_sales" on public.universal_package_purchases
    for select using (
        exists(
            select 1 from public.purchases p 
            join public.universal_packages up on up.id = package_id
            where p.id = purchase_id and up.creator_id = auth.uid()
        )
    );

-- Usage log
alter table public.package_usage_log enable row level security;

drop policy if exists "users_view_own_usage" on public.package_usage_log;
create policy "users_view_own_usage" on public.package_usage_log
    for select using (
        exists(
            select 1 from public.universal_package_purchases upp
            join public.purchases p on upp.purchase_id = p.id
            where upp.id = package_purchase_id and p.user_id = auth.uid()
        )
    );

-- ====================================
-- GRANTS
-- ====================================

grant usage on type package_access_type_enum to authenticated, service_role;
grant usage on type access_pattern_enum to authenticated, service_role;

grant all on table public.universal_packages to authenticated, service_role;
grant all on table public.package_access_rules to authenticated, service_role;
grant all on table public.universal_package_purchases to authenticated, service_role;
grant all on table public.package_usage_log to authenticated, service_role;

grant execute on function public.create_universal_package to authenticated, service_role;
grant execute on function public.purchase_universal_package to authenticated, service_role;
grant execute on function public.can_access_with_package to authenticated, service_role;
grant execute on function public.use_package_credits to authenticated, service_role;

-- ====================================
-- COMMENTS
-- ====================================

comment on table public.universal_packages is 'Universal packages that can grant access to appointments, content, events, and more';
comment on table public.package_access_rules is 'Defines what each package grants access to and how';
comment on table public.universal_package_purchases is 'Tracks user purchases of universal packages and credit usage';
comment on table public.package_usage_log is 'Logs all package credit usage for analytics and verification';

comment on function public.create_universal_package is 'Creates a new universal package with specified access rules';
comment on function public.purchase_universal_package is 'Processes purchase of a universal package';
comment on function public.can_access_with_package is 'Checks if user can access resource with their active packages';
comment on function public.use_package_credits is 'Deducts credits when user accesses package content';

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
