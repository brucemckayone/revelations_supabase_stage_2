# Enhanced Events Ticketing System

## Overview

This document outlines a **clever, comprehensive events ticketing system** that leverages your existing purchase system, universal packages, and subscription architecture to create powerful new revenue streams and user experiences.

## Strategic Opportunities

### 1. **Multi-Revenue Stream Architecture**

- **Individual Tickets** (current)
- **Event Packages** (bundle multiple events)
- **Event Subscriptions** (monthly access to creator's events)
- **Universal Credits** (credits-based event access)
- **Dynamic Pricing** (early bird, group rates, demand-based)
- **Transfer Marketplace** (resale system)

### 2. **Leveraging Existing Systems**

- Use existing `universal_packages` for event credits
- Extend subscription system for event access
- Leverage waitlist system for high-demand events
- Use package system for event bundles

## Core Components

### A. Event Package System (Bundle Events)

**Concept**: Allow creators to bundle multiple events at a discount, similar to service packages.

```sql
-- New table for event packages
CREATE TABLE event_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES auth.users(id),
    name TEXT NOT NULL,
    description TEXT,
    package_type event_package_type_enum NOT NULL,

    -- Pricing
    regular_price NUMERIC(10,2) NOT NULL,
    discounted_price NUMERIC(10,2) NOT NULL,
    discount_percentage INTEGER GENERATED ALWAYS AS (
        ROUND(((regular_price - discounted_price) / regular_price * 100)::numeric)
    ) STORED,

    -- Validity
    valid_for_weeks INTEGER,
    max_events_included INTEGER,

    -- Settings
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    auto_include_new_events BOOLEAN DEFAULT false,

    -- Metadata
    tags TEXT[],
    metadata JSONB DEFAULT '{}',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TYPE event_package_type_enum AS ENUM (
    'fixed_events',        -- Specific events included
    'event_credits',       -- X credits for any events
    'monthly_access',      -- All events in a month
    'creator_pass'         -- All creator events for period
);

-- Junction table for specific events in fixed packages
CREATE TABLE event_package_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_id UUID NOT NULL REFERENCES event_packages(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    included_ticket_types TEXT[] DEFAULT '{}', -- Empty means all ticket types
    max_quantity_per_event INTEGER DEFAULT 1,

    UNIQUE(package_id, event_id)
);

-- Package purchases
CREATE TABLE event_package_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
    package_id UUID NOT NULL REFERENCES event_packages(id),

    -- Usage tracking
    events_used INTEGER DEFAULT 0,
    events_remaining INTEGER NOT NULL,
    credits_used INTEGER DEFAULT 0,
    credits_remaining INTEGER DEFAULT 0,

    -- Validity
    expires_at TIMESTAMP WITH TIME ZONE,

    -- Status
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

### B. Event Subscription System

**Concept**: Monthly/yearly subscriptions for unlimited access to a creator's events.

```sql
-- Event subscription tiers (extends existing subscription system)
CREATE TABLE event_subscription_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES auth.users(id),
    tier_name TEXT NOT NULL,
    tier_key TEXT NOT NULL,

    -- Pricing (monthly/yearly)
    monthly_price NUMERIC(10,2),
    yearly_price NUMERIC(10,2),
    stripe_price_id_monthly TEXT,
    stripe_price_id_yearly TEXT,

    -- Benefits
    includes_all_events BOOLEAN DEFAULT true,
    max_events_per_month INTEGER, -- NULL for unlimited
    includes_premium_events BOOLEAN DEFAULT true,
    early_access_hours INTEGER DEFAULT 0,
    priority_booking BOOLEAN DEFAULT false,
    exclusive_content_access BOOLEAN DEFAULT false,

    -- Settings
    is_active BOOLEAN DEFAULT true,
    tier_order INTEGER DEFAULT 0,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

    UNIQUE(creator_id, tier_key)
);

-- Track subscription event usage
CREATE TABLE subscription_event_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID NOT NULL, -- References existing subscriptions table
    event_booking_id UUID NOT NULL REFERENCES event_bookings(id),
    usage_month DATE NOT NULL, -- First day of the month

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

    UNIQUE(subscription_id, event_booking_id)
);
```

### C. Universal Credits for Events (Enhance Existing System)

**Concept**: Extend the existing universal_packages system to include event credits.

```sql
-- Add event-specific configuration to universal packages
ALTER TABLE universal_packages
ADD COLUMN IF NOT EXISTS event_access_config JSONB DEFAULT '{}';

-- Example event_access_config structure:
-- {
--   "access_type": "credits" | "unlimited" | "tier_based",
--   "credits_per_event": 1,
--   "included_event_types": ["workshop", "seminar"],
--   "excluded_creators": ["uuid1", "uuid2"],
--   "max_events_per_month": 5,
--   "premium_events_included": true,
--   "early_access_hours": 24
-- }

-- Track event credit usage (extends existing system)
CREATE TABLE universal_package_event_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_purchase_id UUID NOT NULL REFERENCES universal_package_purchases(id),
    event_booking_id UUID NOT NULL REFERENCES event_bookings(id),
    credits_used INTEGER NOT NULL DEFAULT 1,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

    UNIQUE(package_purchase_id, event_booking_id)
);
```

### D. Dynamic Pricing System

**Concept**: Flexible pricing based on timing, demand, and group sizes.

```sql
-- Dynamic pricing rules for tickets
CREATE TABLE ticket_pricing_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,

    -- Rule type
    rule_type pricing_rule_type_enum NOT NULL,

    -- Timing rules
    starts_at TIMESTAMP WITH TIME ZONE,
    ends_at TIMESTAMP WITH TIME ZONE,
    days_before_event INTEGER,

    -- Quantity rules
    min_quantity INTEGER DEFAULT 1,
    max_quantity INTEGER,

    -- Pricing
    price_modifier_type price_modifier_type_enum NOT NULL,
    price_modifier_value NUMERIC(10,2) NOT NULL,

    -- Conditions
    conditions JSONB DEFAULT '{}',

    -- Settings
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0, -- Higher priority applied first

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

    CHECK (
        (rule_type = 'early_bird' AND days_before_event IS NOT NULL) OR
        (rule_type = 'group_discount' AND min_quantity > 1) OR
        (rule_type = 'last_minute' AND days_before_event IS NOT NULL) OR
        (rule_type = 'demand_surge' AND conditions IS NOT NULL) OR
        (rule_type = 'loyalty_discount' AND conditions IS NOT NULL)
    )
);

CREATE TYPE pricing_rule_type_enum AS ENUM (
    'early_bird',       -- Early booking discount
    'group_discount',   -- Volume discount
    'last_minute',      -- Last-minute deals
    'demand_surge',     -- Price increase based on demand
    'loyalty_discount', -- Repeat customer discount
    'promo_code'        -- Promotional codes
);

CREATE TYPE price_modifier_type_enum AS ENUM (
    'percentage_off',   -- -20%
    'fixed_amount_off', -- -$10
    'percentage_markup', -- +20%
    'fixed_price'       -- Set to $50
);
```

### E. Ticket Transfer and Resale System

**Concept**: Allow ticket holders to transfer or resell their tickets.

```sql
-- Ticket transfers
CREATE TABLE ticket_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES event_bookings(id),

    -- Transfer details
    from_user_id UUID NOT NULL REFERENCES auth.users(id),
    to_user_id UUID REFERENCES auth.users(id), -- NULL until claimed
    to_email TEXT, -- For unclaimed transfers

    -- Transfer terms
    transfer_type transfer_type_enum NOT NULL,
    asking_price NUMERIC(10,2), -- For sales
    original_price NUMERIC(10,2) NOT NULL,

    -- Status
    status transfer_status_enum DEFAULT 'pending',
    expires_at TIMESTAMP WITH TIME ZONE,
    claimed_at TIMESTAMP WITH TIME ZONE,

    -- Security
    transfer_code TEXT NOT NULL UNIQUE,

    -- Metadata
    notes TEXT,
    metadata JSONB DEFAULT '{}',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TYPE transfer_type_enum AS ENUM (
    'gift',       -- Free transfer
    'sale',       -- Paid transfer
    'exchange'    -- Swap for different event
);

CREATE TYPE transfer_status_enum AS ENUM (
    'pending',    -- Awaiting recipient
    'claimed',    -- Successfully transferred
    'expired',    -- Transfer expired
    'cancelled'   -- Cancelled by sender
);

-- Resale marketplace listings
CREATE TABLE ticket_marketplace_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_id UUID NOT NULL REFERENCES ticket_transfers(id),

    -- Listing details
    title TEXT NOT NULL,
    description TEXT,
    asking_price NUMERIC(10,2) NOT NULL,
    is_negotiable BOOLEAN DEFAULT false,

    -- Visibility
    is_public BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,

    -- Status
    status listing_status_enum DEFAULT 'active',
    views_count INTEGER DEFAULT 0,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TYPE listing_status_enum AS ENUM (
    'active',
    'sold',
    'expired',
    'removed'
);
```

## Smart Functions

### 1. Intelligent Event Booking with Multiple Options

```sql
CREATE OR REPLACE FUNCTION book_event_with_options(
    p_event_id UUID,
    p_date_id UUID,
    p_ticket_id UUID,
    p_quantity INTEGER DEFAULT 1,
    p_payment_method payment_method_enum DEFAULT 'stripe',
    p_package_purchase_id UUID DEFAULT NULL,
    p_subscription_id UUID DEFAULT NULL,
    p_use_credits BOOLEAN DEFAULT false,
    p_promo_code TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_final_price NUMERIC(10,2);
    v_booking_method TEXT;
    v_result JSONB;
BEGIN
    v_user_id := auth.uid();

    -- Determine booking method and calculate price
    IF p_package_purchase_id IS NOT NULL THEN
        -- Use event package
        v_result := process_package_event_booking(p_event_id, p_date_id, p_ticket_id, p_quantity, p_package_purchase_id);
        v_booking_method := 'package';
    ELSIF p_subscription_id IS NOT NULL THEN
        -- Use subscription
        v_result := process_subscription_event_booking(p_event_id, p_date_id, p_ticket_id, p_quantity, p_subscription_id);
        v_booking_method := 'subscription';
    ELSIF p_use_credits THEN
        -- Use universal package credits
        v_result := process_credits_event_booking(p_event_id, p_date_id, p_ticket_id, p_quantity);
        v_booking_method := 'credits';
    ELSE
        -- Regular purchase with dynamic pricing
        v_final_price := calculate_dynamic_ticket_price(p_ticket_id, p_quantity, p_promo_code);
        v_result := process_regular_event_booking(p_event_id, p_date_id, p_ticket_id, p_quantity, v_final_price);
        v_booking_method := 'purchase';
    END IF;

    -- Add booking method to result
    v_result := v_result || jsonb_build_object('booking_method', v_booking_method);

    RETURN v_result;
END;
$$;
```

### 2. Dynamic Pricing Calculator

```sql
CREATE OR REPLACE FUNCTION calculate_dynamic_ticket_price(
    p_ticket_id UUID,
    p_quantity INTEGER,
    p_promo_code TEXT DEFAULT NULL
) RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_base_price NUMERIC(10,2);
    v_final_price NUMERIC(10,2);
    v_rule RECORD;
    v_modifier NUMERIC(10,2);
    v_event_date TIMESTAMP WITH TIME ZONE;
    v_days_before INTEGER;
    v_current_bookings INTEGER;
    v_total_capacity INTEGER;
    v_demand_ratio NUMERIC(5,2);
BEGIN
    -- Get base price and event details
    SELECT t.price, ed.start_date
    INTO v_base_price, v_event_date
    FROM tickets t
    JOIN events e ON t.event_id = e.id
    JOIN event_dates ed ON e.id = ed.event_id
    WHERE t.id = p_ticket_id;

    v_final_price := v_base_price * p_quantity;
    v_days_before := EXTRACT(DAY FROM (v_event_date - NOW()));

    -- Apply pricing rules in priority order
    FOR v_rule IN
        SELECT * FROM ticket_pricing_rules
        WHERE ticket_id = p_ticket_id
        AND is_active = true
        AND (starts_at IS NULL OR starts_at <= NOW())
        AND (ends_at IS NULL OR ends_at >= NOW())
        ORDER BY priority DESC
    LOOP
        -- Check if rule applies
        IF applies_pricing_rule(v_rule, p_quantity, v_days_before) THEN
            v_modifier := calculate_price_modifier(v_rule, v_base_price, p_quantity);
            v_final_price := v_final_price + v_modifier;
        END IF;
    END LOOP;

    -- Apply promo code if provided
    IF p_promo_code IS NOT NULL THEN
        v_final_price := apply_promo_code(v_final_price, p_promo_code);
    END IF;

    -- Ensure price doesn't go negative
    v_final_price := GREATEST(v_final_price, 0);

    RETURN v_final_price;
END;
$$;
```

### 3. Event Package Purchase Function

```sql
CREATE OR REPLACE FUNCTION purchase_event_package(
    p_package_id UUID,
    p_payment_intent_id TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_package event_packages;
    v_purchase_id UUID;
    v_package_purchase_id UUID;
    v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    v_user_id := auth.uid();

    -- Get package details
    SELECT * INTO v_package
    FROM event_packages
    WHERE id = p_package_id AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Event package not found or inactive';
    END IF;

    -- Calculate expiration
    IF v_package.valid_for_weeks IS NOT NULL THEN
        v_expires_at := NOW() + (v_package.valid_for_weeks || ' weeks')::INTERVAL;
    END IF;

    -- Create purchase record
    INSERT INTO purchases (
        user_id, owner_id, stripe_payment_intent_id,
        amount, currency, payment_status,
        purchase_type, purchase_date
    ) VALUES (
        v_user_id, v_package.creator_id, p_payment_intent_id,
        v_package.discounted_price, 'USD', 'completed',
        'event_package', NOW()
    ) RETURNING id INTO v_purchase_id;

    -- Create package purchase tracking
    INSERT INTO event_package_purchases (
        purchase_id, package_id,
        events_remaining, credits_remaining,
        expires_at
    ) VALUES (
        v_purchase_id, p_package_id,
        COALESCE(v_package.max_events_included, 999),
        CASE WHEN v_package.package_type = 'event_credits'
             THEN v_package.max_events_included
             ELSE 0 END,
        v_expires_at
    ) RETURNING id INTO v_package_purchase_id;

    RETURN jsonb_build_object(
        'success', true,
        'purchase_id', v_purchase_id,
        'package_purchase_id', v_package_purchase_id,
        'expires_at', v_expires_at
    );
END;
$$;
```

## Integration with Existing Systems

### A. Universal Packages Enhancement

Extend the existing universal packages to include event credits:

```sql
-- Add event credits support to universal packages
UPDATE universal_packages
SET event_credits = 5,
    event_access_config = jsonb_build_object(
        'access_type', 'credits',
        'credits_per_event', 1,
        'premium_events_included', true,
        'early_access_hours', 24
    )
WHERE package_type = 'premium';
```

### B. Subscription System Enhancement

Extend existing subscriptions to include event access:

```sql
-- Add event access to existing subscription tiers
INSERT INTO event_subscription_tiers (
    creator_id, tier_name, tier_key,
    monthly_price, yearly_price,
    includes_all_events, max_events_per_month,
    early_access_hours, priority_booking
)
SELECT
    creator_id, 'Event Access - ' || tier_name, tier_key || '_events',
    monthly_price + 20, yearly_price + 200,
    true, NULL, 24, true
FROM creator_subscription_tiers
WHERE is_active = true;
```

### C. Waitlist Integration

Enhance the existing waitlist system for premium users:

```sql
-- Priority waitlist for subscribers and package holders
CREATE OR REPLACE FUNCTION join_priority_waitlist(
    p_user_id UUID,
    p_event_id UUID,
    p_date_id UUID
) RETURNS waitlist_entries
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_priority INTEGER := 100; -- Default priority
    v_entry waitlist_entries;
BEGIN
    -- Check for subscription (higher priority)
    IF EXISTS (
        SELECT 1 FROM subscriptions s
        JOIN event_subscription_tiers est ON s.tier = est.tier_key
        WHERE s.user_id = p_user_id
        AND s.status = 'active'
        AND est.priority_booking = true
    ) THEN
        v_priority := 10; -- High priority for subscribers
    END IF;

    -- Check for universal package with event credits
    IF EXISTS (
        SELECT 1 FROM universal_package_purchases upp
        JOIN universal_packages up ON upp.package_id = up.id
        WHERE upp.user_id = p_user_id
        AND upp.event_credits_remaining > 0
        AND upp.is_active = true
    ) THEN
        v_priority := LEAST(v_priority, 20); -- High priority for package holders
    END IF;

    -- Join waitlist with calculated priority
    INSERT INTO waitlist_entries (
        user_id, event_id, event_date_id, position, priority
    ) VALUES (
        p_user_id, p_event_id, p_date_id,
        get_next_waitlist_position(p_event_id, p_date_id),
        v_priority
    ) RETURNING * INTO v_entry;

    RETURN v_entry;
END;
$$;
```

## Revenue Optimization Features

### 1. **Smart Upselling**

- Suggest event packages when user books multiple events
- Recommend subscriptions for frequent attendees
- Cross-sell related events

### 2. **Loyalty Program**

- Track user's event attendance history
- Offer discounts based on loyalty tier
- Exclusive early access to popular events

### 3. **Group Booking Incentives**

- Automatic discounts for bulk purchases
- Group coordinator rewards
- Corporate package options

### 4. **Seasonal Strategies**

- Holiday event bundles
- Summer workshop series
- New Year resolution packages

## Key Benefits

### For Creators:

1. **Multiple Revenue Streams**: Individual sales, packages, subscriptions, credits
2. **Predictable Income**: Subscription and package pre-sales
3. **Higher Customer Value**: Package and subscription models increase LTV
4. **Reduced No-Shows**: Pre-paid packages encourage attendance
5. **Market Insights**: Dynamic pricing provides demand data

### For Users:

1. **Cost Savings**: Packages and subscriptions offer discounts
2. **Convenience**: Credits and subscriptions simplify booking
3. **Priority Access**: Subscribers get early booking and waitlist priority
4. **Flexibility**: Transfer system allows for schedule changes
5. **Discovery**: Package deals expose users to new events

### For Platform:

1. **Increased Transaction Volume**: Multiple purchase types
2. **Higher Average Order Value**: Packages and bundles
3. **Improved Retention**: Subscription and package holders are stickier
4. **Marketplace Revenue**: Commission on transfers and resales
5. **Data Insights**: Rich analytics on pricing and demand

This system transforms your events from simple ticket sales into a comprehensive, profitable ecosystem that benefits all stakeholders while providing maximum flexibility and value.
