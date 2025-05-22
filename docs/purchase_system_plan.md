# Purchase System Reorganization Plan

## Current Understanding

### Core Structure

- Multi-tenant application where creators (users) can sell various types of content and services
- Each saleable item is linked to a `user_id` (owner) from the `auth.users` table
- Posts table serves as a central entity for most content types with `post_type_enum` differentiating between them
- Multiple purchase-related tables with varying structures and relationships

### Existing Purchase Tables

1. **purchases**: General purchase table with links to various content types

   - Connects to `post_id`, `content_id`, `booking_id`
   - Has `invoice_id` and `payment_intent_id` for payment tracking
   - Includes `amount_received` for financial data

2. **subscriptions**: Links to purchases for recurring payments

   - References `purchase_id`
   - Contains `subscription_date` and `end_date`

3. **ticket_purchases_event_date_user**: Event ticket purchases

   - References `purchase_id`, `event_id`, `ticket_id`
   - Tracks user attendance to specific event dates

4. **article_purchases**: Article purchases

   - Not integrated with main purchases table
   - Separate tracking for article access

5. **service_purchases**: Service/appointment purchases

   - Not integrated with main purchases table
   - Tracks service date access

6. **media_access_control**: Content access control

   - Links users to content they've purchased
   - References both `purchase_id` and `content_id`

7. **invoices**: Financial records
   - Contains `amount`, `currency`, `status`
   - Linked to Stripe via `stripe_invoice_id`

### Saleables Item Types

1. **events**: Time-based gatherings with tickets

   - Has event_dates for scheduling
   - Uses tickets for sales

2. **services**: Bookable services (appointments)

   - Has service_dates for availability
   - Linked to bookings

3. **on_demand_media**: Digital content (video/audio)

   - Has price, duration, media_type

4. **articles**: Written content
   - Has content, potential for purchases

### Frontend Requirements

The frontend components need consolidated data for:

- General sales across all types
- Appointment-specific sales
- Content (media) purchase information
- Event booking information
- Subscription management

## Issues with Current Structure

1. **Inconsistent Status Tracking**: No standardized status field across all purchase types (completed, pending, refunded, failed)

2. **Fragmented Purchase Records**: Purchase data is spread across multiple tables without a unified approach

3. **Missing Fields for Frontend**: Several frontend-required fields aren't present in the current schema:

   - Download tracking for content
   - Detailed subscription information (billing cycle, tier)
   - Consistent customer data structure

4. **Lack of Integration**: Some purchase types (article_purchases, service_purchases) aren't integrated with the main purchases table

5. **Inconsistent Schemas**: Different purchase tables have different field names and structures

## New Structure with Stripe Integration

### 1. Unified Purchase Table

Create a more comprehensive central `purchases` table with Stripe integration:

```sql
CREATE TABLE public.purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- purchaser
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- seller/creator

    -- Stripe payment info
    stripe_payment_intent_id TEXT,
    stripe_invoice_id TEXT,
    stripe_subscription_id TEXT,
    stripe_customer_id TEXT,
    amount NUMERIC(10, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    payment_status TEXT NOT NULL CHECK (payment_status IN ('completed', 'pending', 'refunded', 'failed')),

    -- Item references (only one should be non-null)
    post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL,
    content_id UUID REFERENCES public.on_demand_media(id) ON DELETE SET NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
    event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,

    -- Purchase type
    purchase_type TEXT NOT NULL CHECK (purchase_type IN ('content', 'event', 'appointment', 'subscription', 'article')),

    -- Dates
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    start_date TIMESTAMP WITH TIME ZONE, -- for subscriptions, services, events
    end_date TIMESTAMP WITH TIME ZONE,   -- for subscriptions, services, events

    -- Additional fields
    quantity INTEGER NOT NULL DEFAULT 1,
    metadata JSONB, -- For type-specific additional data

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT check_only_one_item_type CHECK (
        (post_id IS NOT NULL)::integer +
        (content_id IS NOT NULL)::integer +
        (service_id IS NOT NULL)::integer +
        (event_id IS NOT NULL)::integer <= 1
    )
);

-- Create indexes for faster queries
CREATE INDEX idx_purchases_user_id ON public.purchases(user_id);
CREATE INDEX idx_purchases_owner_id ON public.purchases(owner_id);
CREATE INDEX idx_purchases_post_id ON public.purchases(post_id);
CREATE INDEX idx_purchases_stripe_payment_intent_id ON public.purchases(stripe_payment_intent_id);
CREATE INDEX idx_purchases_stripe_invoice_id ON public.purchases(stripe_invoice_id);
CREATE INDEX idx_purchases_stripe_subscription_id ON public.purchases(stripe_subscription_id);
```

### 2. Subscription Table with Stripe Integration

```sql
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,

    -- Stripe details
    stripe_subscription_id TEXT NOT NULL,
    stripe_price_id TEXT NOT NULL,
    stripe_product_id TEXT NOT NULL,

    -- Subscription details
    plan_name TEXT NOT NULL,
    tier TEXT NOT NULL CHECK (tier IN ('basic', 'premium', 'unlimited')),
    billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('monthly', 'quarterly', 'annual')),

    -- Status tracking
    status TEXT NOT NULL CHECK (status IN ('active', 'cancelled', 'paused', 'trial', 'past_due')),

    -- Payment tracking
    next_billing_date TIMESTAMP WITH TIME ZONE NOT NULL,
    payments_count INTEGER NOT NULL DEFAULT 1,
    total_paid NUMERIC(10, 2) NOT NULL,
    last_payment_status TEXT NOT NULL CHECK (last_payment_status IN ('completed', 'failed', 'refunded')),
    last_payment_date TIMESTAMP WITH TIME ZONE NOT NULL,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_subscriptions_purchase_id ON public.subscriptions(purchase_id);
CREATE INDEX idx_subscriptions_stripe_subscription_id ON public.subscriptions(stripe_subscription_id);
```

### 3. Event Booking Improvements

```sql
CREATE TABLE public.event_bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
    date_id UUID NOT NULL REFERENCES public.event_dates(id) ON DELETE CASCADE,

    -- Booking details
    attendees INTEGER NOT NULL DEFAULT 1,
    is_virtual BOOLEAN NOT NULL DEFAULT FALSE,

    status TEXT NOT NULL CHECK (status IN ('confirmed', 'pending', 'cancelled', 'attended')),

    -- Ticket info
    ticket_code TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_event_bookings_purchase_id ON public.event_bookings(purchase_id);
CREATE INDEX idx_event_bookings_event_id ON public.event_bookings(event_id);
CREATE INDEX idx_event_bookings_date_id ON public.event_bookings(date_id);
```

### 4. Content Purchase Improvements

```sql
CREATE TABLE public.content_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,
    content_id UUID NOT NULL REFERENCES public.on_demand_media(id) ON DELETE CASCADE,

    -- Content access tracking
    download_count INTEGER NOT NULL DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE,
    is_subscription BOOLEAN NOT NULL DEFAULT FALSE,

    -- Access details
    access_expires_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_content_purchases_purchase_id ON public.content_purchases(purchase_id);
CREATE INDEX idx_content_purchases_content_id ON public.content_purchases(content_id);
```

### 5. Appointment Purchase Improvements

```sql
CREATE TABLE public.appointment_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,

    -- Appointment details
    appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL, -- in minutes
    method TEXT NOT NULL CHECK (method IN ('video', 'phone', 'in-person')),
    service_type TEXT NOT NULL CHECK (service_type IN ('reading', 'healing', 'coaching', 'consultation')),

    status TEXT NOT NULL CHECK (status IN ('confirmed', 'pending', 'cancelled', 'completed')),
    notes TEXT,

    -- Meeting details
    meeting_url TEXT,
    meeting_id TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_appointment_purchases_purchase_id ON public.appointment_purchases(purchase_id);
CREATE INDEX idx_appointment_purchases_service_id ON public.appointment_purchases(service_id);
CREATE INDEX idx_appointment_purchases_appointment_date ON public.appointment_purchases(appointment_date);
```

### 6. Stripe Webhook Events Table

```sql
CREATE TABLE public.stripe_webhook_events (
    id TEXT PRIMARY KEY, -- Stripe event ID
    type TEXT NOT NULL,
    object_id TEXT NOT NULL,
    object_type TEXT NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    processing_error TEXT
);

-- Create indexes
CREATE INDEX idx_stripe_webhook_events_type ON public.stripe_webhook_events(type);
CREATE INDEX idx_stripe_webhook_events_object_id ON public.stripe_webhook_events(object_id);
CREATE INDEX idx_stripe_webhook_events_processed ON public.stripe_webhook_events(processed);
```

### 7. Row Level Security (RLS) for Multi-Tenant Data Protection

```sql
-- Enable RLS on the purchases table
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;

-- Policy for purchasers to view their own purchases
CREATE POLICY purchase_select_as_purchaser ON public.purchases
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for sellers to view purchases of their content
CREATE POLICY purchase_select_as_owner ON public.purchases
    FOR SELECT
    USING (auth.uid() = owner_id);

-- Policy for purchasers to insert their own purchases
CREATE POLICY purchase_insert_as_purchaser ON public.purchases
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy for updating purchases (restricted to specific fields for purchasers)
CREATE POLICY purchase_update_as_purchaser ON public.purchases
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (
        -- Only allow updating specific fields
        user_id = OLD.user_id AND
        owner_id = OLD.owner_id
    );

-- Policy for admins
CREATE POLICY purchase_admin ON public.purchases
    USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Similar policies for other tables
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_purchases ENABLE ROW LEVEL SECURITY;
```

## Database Functions for Frontend Components

### 1. All Sales Table Function

```sql
CREATE OR REPLACE FUNCTION get_all_sales(
    filters JSONB
)
RETURNS TABLE (
    id TEXT,
    customerName TEXT,
    customerEmail TEXT,
    amount NUMERIC(10, 2),
    status TEXT,
    type TEXT,
    date TIMESTAMP WITH TIME ZONE,
    productName TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id::TEXT,
        prof.full_name AS customerName,
        u.email AS customerEmail,
        p.amount,
        p.payment_status AS status,
        p.purchase_type AS type,
        p.purchase_date AS date,
        CASE
            WHEN p.post_id IS NOT NULL THEN post.title
            ELSE 'Unnamed Product'
        END AS productName
    FROM
        purchases p
    JOIN
        auth.users u ON p.user_id = u.id
    JOIN
        profiles prof ON prof.id = p.user_id
    LEFT JOIN
        posts post ON p.post_id = post.id
    WHERE
        (p.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
        )) AND
        (filters->>'status' IS NULL OR filters->>'status' = 'all' OR p.payment_status = filters->>'status') AND
        (filters->>'search' IS NULL OR
            prof.full_name ILIKE '%' || filters->>'search' || '%' OR
            u.email ILIKE '%' || filters->>'search' || '%' OR
            p.id::TEXT ILIKE '%' || filters->>'search' || '%' OR
            post.title ILIKE '%' || filters->>'search' || '%'
        )
    ORDER BY
        p.purchase_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$ LANGUAGE plpgsql;
```

### 2. Appointment Sales Function

```sql
CREATE OR REPLACE FUNCTION get_appointment_sales(
    filters JSONB
)
RETURNS TABLE (
    id TEXT,
    customerName TEXT,
    customerEmail TEXT,
    amount NUMERIC(10, 2),
    status TEXT,
    bookingDate TIMESTAMP WITH TIME ZONE,
    appointmentDate TIMESTAMP WITH TIME ZONE,
    duration INTEGER,
    serviceName TEXT,
    serviceType TEXT,
    method TEXT,
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id::TEXT,
        prof.full_name AS customerName,
        u.email AS customerEmail,
        p.amount,
        p.payment_status AS status,
        p.purchase_date AS bookingDate,
        ap.appointment_date,
        ap.duration,
        post.title AS serviceName,
        ap.service_type,
        ap.method,
        ap.notes
    FROM
        purchases p
    JOIN
        appointment_purchases ap ON p.id = ap.purchase_id
    JOIN
        auth.users u ON p.user_id = u.id
    JOIN
        profiles prof ON prof.id = p.user_id
    LEFT JOIN
        services s ON p.service_id = s.id
    LEFT JOIN
        posts post ON s.post_id = post.id
    WHERE
        p.purchase_type = 'appointment' AND
        (p.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
        )) AND
        (filters->>'status' IS NULL OR filters->>'status' = 'all' OR p.payment_status = filters->>'status') AND
        (filters->>'search' IS NULL OR
            prof.full_name ILIKE '%' || filters->>'search' || '%' OR
            u.email ILIKE '%' || filters->>'search' || '%' OR
            p.id::TEXT ILIKE '%' || filters->>'search' || '%' OR
            post.title ILIKE '%' || filters->>'search' || '%'
        )
    ORDER BY
        ap.appointment_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$ LANGUAGE plpgsql;
```

### 3. Content Sales Function

```sql
CREATE OR REPLACE FUNCTION get_content_sales(
    filters JSONB
)
RETURNS TABLE (
    id TEXT,
    customerName TEXT,
    customerEmail TEXT,
    amount NUMERIC(10, 2),
    status TEXT,
    date TIMESTAMP WITH TIME ZONE,
    contentTitle TEXT,
    contentType TEXT,
    downloadCount INTEGER,
    isSubscription BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id::TEXT,
        prof.full_name AS customerName,
        u.email AS customerEmail,
        p.amount,
        p.payment_status AS status,
        p.purchase_date AS date,
        post.title AS contentTitle,
        odm.media_type::TEXT AS contentType,
        cp.download_count,
        cp.is_subscription
    FROM
        purchases p
    JOIN
        content_purchases cp ON p.id = cp.purchase_id
    JOIN
        auth.users u ON p.user_id = u.id
    JOIN
        profiles prof ON prof.id = p.user_id
    JOIN
        on_demand_media odm ON p.content_id = odm.id
    JOIN
        posts post ON odm.post_id = post.id
    WHERE
        p.purchase_type = 'content' AND
        (p.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
        )) AND
        (filters->>'status' IS NULL OR filters->>'status' = 'all' OR p.payment_status = filters->>'status') AND
        (filters->>'search' IS NULL OR
            prof.full_name ILIKE '%' || filters->>'search' || '%' OR
            u.email ILIKE '%' || filters->>'search' || '%' OR
            p.id::TEXT ILIKE '%' || filters->>'search' || '%' OR
            post.title ILIKE '%' || filters->>'search' || '%'
        )
    ORDER BY
        p.purchase_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$ LANGUAGE plpgsql;
```

### 4. Event Bookings Function

```sql
CREATE OR REPLACE FUNCTION get_event_bookings(
    filters JSONB
)
RETURNS TABLE (
    id TEXT,
    customerName TEXT,
    customerEmail TEXT,
    amount NUMERIC(10, 2),
    status TEXT,
    bookingDate TIMESTAMP WITH TIME ZONE,
    eventTitle TEXT,
    eventDate TIMESTAMP WITH TIME ZONE,
    attendees INTEGER,
    location TEXT,
    isVirtual BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id::TEXT,
        prof.full_name AS customerName,
        u.email AS customerEmail,
        p.amount,
        p.payment_status AS status,
        p.purchase_date AS bookingDate,
        post.title AS eventTitle,
        ed.start_date AS eventDate,
        eb.attendees,
        COALESCE(loc.name,
            CASE WHEN e.type = 'online' THEN 'Online Event'
            ELSE 'Location TBA' END) AS location,
        (e.type = 'online' OR e.type = 'hybrid') AS isVirtual
    FROM
        purchases p
    JOIN
        event_bookings eb ON p.id = eb.purchase_id
    JOIN
        auth.users u ON p.user_id = u.id
    JOIN
        profiles prof ON prof.id = p.user_id
    JOIN
        events e ON p.event_id = e.id
    JOIN
        posts post ON e.post_id = post.id
    JOIN
        event_dates ed ON eb.date_id = ed.id
    LEFT JOIN
        post_locations pl ON post.id = pl.post_id
    LEFT JOIN
        locations loc ON pl.location_id = loc.id
    WHERE
        p.purchase_type = 'event' AND
        (p.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
        )) AND
        (filters->>'status' IS NULL OR filters->>'status' = 'all' OR p.payment_status = filters->>'status') AND
        (filters->>'search' IS NULL OR
            prof.full_name ILIKE '%' || filters->>'search' || '%' OR
            u.email ILIKE '%' || filters->>'search' || '%' OR
            p.id::TEXT ILIKE '%' || filters->>'search' || '%' OR
            post.title ILIKE '%' || filters->>'search' || '%' OR
            loc.name ILIKE '%' || filters->>'search' || '%'
        )
    ORDER BY
        ed.start_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$ LANGUAGE plpgsql;
```

### 5. Subscriptions Function

```sql
CREATE OR REPLACE FUNCTION get_subscriptions(
    filters JSONB
)
RETURNS TABLE (
    id TEXT,
    customerName TEXT,
    customerEmail TEXT,
    plan TEXT,
    tier TEXT,
    billingCycle TEXT,
    amount NUMERIC(10, 2),
    status TEXT,
    startDate TIMESTAMP WITH TIME ZONE,
    nextBillingDate TIMESTAMP WITH TIME ZONE,
    totalPaid NUMERIC(10, 2),
    paymentsCount INTEGER,
    lastPaymentStatus TEXT,
    lastPaymentDate TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id::TEXT,
        prof.full_name AS customerName,
        u.email AS customerEmail,
        s.plan_name AS plan,
        s.tier,
        s.billing_cycle AS billingCycle,
        p.amount,
        s.status,
        p.start_date AS startDate,
        s.next_billing_date AS nextBillingDate,
        s.total_paid AS totalPaid,
        s.payments_count AS paymentsCount,
        s.last_payment_status AS lastPaymentStatus,
        s.last_payment_date AS lastPaymentDate
    FROM
        subscriptions s
    JOIN
        purchases p ON s.purchase_id = p.id
    JOIN
        auth.users u ON p.user_id = u.id
    JOIN
        profiles prof ON prof.id = p.user_id
    WHERE
        p.purchase_type = 'subscription' AND
        (p.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
        )) AND
        (
            filters->>'status' IS NULL OR
            filters->>'status' = 'all' OR
            CASE
                WHEN filters->>'status' = 'completed' THEN s.status IN ('active', 'trial')
                WHEN filters->>'status' = 'pending' THEN s.status IN ('active', 'trial', 'past_due')
                WHEN filters->>'status' = 'failed' THEN s.status = 'past_due'
                WHEN filters->>'status' = 'refunded' THEN s.status IN ('cancelled', 'paused')
                ELSE FALSE
            END
        ) AND
        (filters->>'search' IS NULL OR
            prof.full_name ILIKE '%' || filters->>'search' || '%' OR
            u.email ILIKE '%' || filters->>'search' || '%' OR
            s.id::TEXT ILIKE '%' || filters->>'search' || '%' OR
            s.plan_name ILIKE '%' || filters->>'search' || '%'
        )
    ORDER BY
        s.next_billing_date ASC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$ LANGUAGE plpgsql;
```

## Stripe Integration Details

The payment system will use Stripe for processing payments. Here's how the integration will work:

1. **Stripe Customers**: Each user will have a corresponding Stripe customer ID stored in their profile or user_stripe_data record.

2. **Payment Intents**: For one-time payments, we'll use Stripe Payment Intents. The ID will be stored in `stripe_payment_intent_id`.

3. **Subscriptions**: For recurring payments, we'll use Stripe Subscriptions. The subscription ID will be stored in `stripe_subscription_id`.

4. **Webhooks**:

   - We'll set up Stripe webhooks to track payment status changes
   - Events will be logged in `stripe_webhook_events` table
   - Supabase Edge Functions will process webhooks and update database records

5. **Status Synchronization**:
   - Purchase status will be synchronized with Stripe payment status
   - Subscription status will be synchronized with Stripe subscription status

## Implementation Steps

1. **Schema Creation** (1-2 days)

   - Create new table schemas with proper Stripe integration fields
   - Set up proper indexes and constraints
   - Create RLS policies for multi-tenant security

2. **Frontend API Functions** (2-3 days)

   - Create DB functions for each frontend component
   - Ensure output matches exactly what frontend expects
   - Add pagination, filtering, and sorting support

3. **Stripe Integration** (2-3 days)

   - Set up Stripe webhook endpoint
   - Create Supabase Edge Function for webhook processing
   - Create utility functions for creating and managing Stripe resources

4. **Testing** (1-2 days)

   - Test all functionality with mock data
   - Test Stripe integration with test mode
   - Verify multi-tenant isolation
   - Performance testing for large datasets

5. **Cleanup & Deployment** (1 day)
   - Delete deprecated tables
   - Update API references
   - Document new system
