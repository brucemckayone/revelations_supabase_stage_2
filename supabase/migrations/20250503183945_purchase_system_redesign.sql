-- PURCHASE SYSTEM REDESIGN
-- Implements a centralized purchase system with Stripe integration

-- Drop existing purchase tables that will be replaced
DROP TABLE IF EXISTS public.article_purchases CASCADE;
DROP TABLE IF EXISTS public.ticket_purchases CASCADE;
DROP TABLE IF EXISTS public.ticket_purchases_event_date_user CASCADE;
DROP TABLE IF EXISTS public.service_purchases CASCADE;
DROP TABLE IF EXISTS public.media_access_control CASCADE;
DROP TABLE IF EXISTS public.subscriptions CASCADE;
DROP TABLE IF EXISTS public.purchases CASCADE;

-- Drop existing related tables that will be replaced
DROP TABLE IF EXISTS public.event_bookings CASCADE;
DROP TABLE IF EXISTS public.content_purchases CASCADE;
DROP TABLE IF EXISTS public.appointment_purchases CASCADE;
DROP TABLE IF EXISTS public.stripe_webhook_events CASCADE;

-- Drop related functions
DROP FUNCTION IF EXISTS get_user_article_purchases CASCADE;
DROP FUNCTION IF EXISTS get_user_ticket_purchases CASCADE;
DROP FUNCTION IF EXISTS get_user_service_purchases CASCADE;
DROP FUNCTION IF EXISTS get_user_media_access CASCADE;
DROP FUNCTION IF EXISTS check_subscription_status CASCADE;
DROP FUNCTION IF EXISTS get_all_sales CASCADE;
DROP FUNCTION IF EXISTS get_appointment_sales CASCADE;
DROP FUNCTION IF EXISTS get_content_sales CASCADE;
DROP FUNCTION IF EXISTS get_event_bookings CASCADE;
DROP FUNCTION IF EXISTS get_subscriptions CASCADE;

-- 1. Create the unified purchases table
CREATE TABLE IF NOT EXISTS public.purchases (
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

COMMENT ON TABLE public.purchases IS 'Central table for all purchase transactions with Stripe integration';

-- Create indexes for faster queries
DROP INDEX IF EXISTS idx_purchases_user_id;
DROP INDEX IF EXISTS idx_purchases_owner_id;
DROP INDEX IF EXISTS idx_purchases_post_id;
DROP INDEX IF EXISTS idx_purchases_content_id;
DROP INDEX IF EXISTS idx_purchases_service_id;
DROP INDEX IF EXISTS idx_purchases_event_id;
DROP INDEX IF EXISTS idx_purchases_stripe_payment_intent_id;
DROP INDEX IF EXISTS idx_purchases_stripe_invoice_id;
DROP INDEX IF EXISTS idx_purchases_stripe_subscription_id;
DROP INDEX IF EXISTS idx_purchases_purchase_date;
DROP INDEX IF EXISTS idx_purchases_payment_status;

CREATE INDEX idx_purchases_user_id ON public.purchases(user_id);
CREATE INDEX idx_purchases_owner_id ON public.purchases(owner_id);
CREATE INDEX idx_purchases_post_id ON public.purchases(post_id);
CREATE INDEX idx_purchases_content_id ON public.purchases(content_id);
CREATE INDEX idx_purchases_service_id ON public.purchases(service_id);
CREATE INDEX idx_purchases_event_id ON public.purchases(event_id);
CREATE INDEX idx_purchases_stripe_payment_intent_id ON public.purchases(stripe_payment_intent_id);
CREATE INDEX idx_purchases_stripe_invoice_id ON public.purchases(stripe_invoice_id);
CREATE INDEX idx_purchases_stripe_subscription_id ON public.purchases(stripe_subscription_id);
CREATE INDEX idx_purchases_purchase_date ON public.purchases(purchase_date);
CREATE INDEX idx_purchases_payment_status ON public.purchases(payment_status);

-- 2. Create subscription table
CREATE TABLE IF NOT EXISTS public.subscriptions (
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

COMMENT ON TABLE public.subscriptions IS 'Detailed subscription information for recurring payments';

-- Create indexes
DROP INDEX IF EXISTS idx_subscriptions_purchase_id;
DROP INDEX IF EXISTS idx_subscriptions_stripe_subscription_id;
DROP INDEX IF EXISTS idx_subscriptions_status;
DROP INDEX IF EXISTS idx_subscriptions_next_billing_date;

CREATE INDEX idx_subscriptions_purchase_id ON public.subscriptions(purchase_id);
CREATE INDEX idx_subscriptions_stripe_subscription_id ON public.subscriptions(stripe_subscription_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX idx_subscriptions_next_billing_date ON public.subscriptions(next_billing_date);

-- 3. Create event bookings table
CREATE TABLE IF NOT EXISTS public.event_bookings (
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

COMMENT ON TABLE public.event_bookings IS 'Tracks event ticket purchases and attendance';

-- Create indexes
DROP INDEX IF EXISTS idx_event_bookings_purchase_id;
DROP INDEX IF EXISTS idx_event_bookings_event_id;
DROP INDEX IF EXISTS idx_event_bookings_date_id;
DROP INDEX IF EXISTS idx_event_bookings_ticket_id;
DROP INDEX IF EXISTS idx_event_bookings_status;

CREATE INDEX idx_event_bookings_purchase_id ON public.event_bookings(purchase_id);
CREATE INDEX idx_event_bookings_event_id ON public.event_bookings(event_id);
CREATE INDEX idx_event_bookings_date_id ON public.event_bookings(date_id);
CREATE INDEX idx_event_bookings_ticket_id ON public.event_bookings(ticket_id);
CREATE INDEX idx_event_bookings_status ON public.event_bookings(status);

-- 4. Create content purchases table
CREATE TABLE IF NOT EXISTS public.content_purchases (
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

COMMENT ON TABLE public.content_purchases IS 'Tracks digital content purchases and access';

-- Create indexes
DROP INDEX IF EXISTS idx_content_purchases_purchase_id;
DROP INDEX IF EXISTS idx_content_purchases_content_id;
DROP INDEX IF EXISTS idx_content_purchases_access_expires_at;

CREATE INDEX idx_content_purchases_purchase_id ON public.content_purchases(purchase_id);
CREATE INDEX idx_content_purchases_content_id ON public.content_purchases(content_id);
CREATE INDEX idx_content_purchases_access_expires_at ON public.content_purchases(access_expires_at);

-- 5. Create appointment purchases table
CREATE TABLE IF NOT EXISTS public.appointment_purchases (
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

COMMENT ON TABLE public.appointment_purchases IS 'Tracks service appointments and bookings';

-- Create indexes
DROP INDEX IF EXISTS idx_appointment_purchases_purchase_id;
DROP INDEX IF EXISTS idx_appointment_purchases_service_id;
DROP INDEX IF EXISTS idx_appointment_purchases_appointment_date;
DROP INDEX IF EXISTS idx_appointment_purchases_status;

CREATE INDEX idx_appointment_purchases_purchase_id ON public.appointment_purchases(purchase_id);
CREATE INDEX idx_appointment_purchases_service_id ON public.appointment_purchases(service_id);
CREATE INDEX idx_appointment_purchases_appointment_date ON public.appointment_purchases(appointment_date);
CREATE INDEX idx_appointment_purchases_status ON public.appointment_purchases(status);

-- 6. Create stripe webhook events table
CREATE TABLE IF NOT EXISTS public.stripe_webhook_events (
    id TEXT PRIMARY KEY, -- Stripe event ID
    type TEXT NOT NULL,
    object_id TEXT NOT NULL,
    object_type TEXT NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    processing_error TEXT
);

COMMENT ON TABLE public.stripe_webhook_events IS 'Logs and tracks Stripe webhook events for payment processing';

-- Create indexes
DROP INDEX IF EXISTS idx_stripe_webhook_events_type;
DROP INDEX IF EXISTS idx_stripe_webhook_events_object_id;
DROP INDEX IF EXISTS idx_stripe_webhook_events_processed;

CREATE INDEX idx_stripe_webhook_events_type ON public.stripe_webhook_events(type);
CREATE INDEX idx_stripe_webhook_events_object_id ON public.stripe_webhook_events(object_id);
CREATE INDEX idx_stripe_webhook_events_processed ON public.stripe_webhook_events(processed);

-- 7. Add Triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers
DROP TRIGGER IF EXISTS purchases_updated_at ON public.purchases;
DROP TRIGGER IF EXISTS subscriptions_updated_at ON public.subscriptions;
DROP TRIGGER IF EXISTS event_bookings_updated_at ON public.event_bookings;
DROP TRIGGER IF EXISTS content_purchases_updated_at ON public.content_purchases;
DROP TRIGGER IF EXISTS appointment_purchases_updated_at ON public.appointment_purchases;

-- Create triggers for all tables
CREATE TRIGGER purchases_updated_at BEFORE UPDATE ON public.purchases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER subscriptions_updated_at BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER event_bookings_updated_at BEFORE UPDATE ON public.event_bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER content_purchases_updated_at BEFORE UPDATE ON public.content_purchases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER appointment_purchases_updated_at BEFORE UPDATE ON public.appointment_purchases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. Row Level Security (RLS) for Multi-Tenant Data Protection
-- Enable RLS on the purchases table
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS purchase_select_as_purchaser ON public.purchases;
DROP POLICY IF EXISTS purchase_select_as_owner ON public.purchases;
DROP POLICY IF EXISTS purchase_insert_as_purchaser ON public.purchases;
DROP POLICY IF EXISTS purchase_update_as_purchaser ON public.purchases;
DROP POLICY IF EXISTS purchase_admin ON public.purchases;

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

-- Policy for updating purchases (restricted to purchasers only)
CREATE POLICY purchase_update_as_purchaser ON public.purchases
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy for admins
CREATE POLICY purchase_admin ON public.purchases
    USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Enable RLS on the subscriptions table
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Drop existing policy
DROP POLICY IF EXISTS subscriptions_select ON public.subscriptions;

-- Policy for viewing subscriptions
CREATE POLICY subscriptions_select ON public.subscriptions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM purchases
            WHERE purchases.id = purchase_id
            AND (purchases.user_id = auth.uid() OR purchases.owner_id = auth.uid())
        ) OR
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Similar policies for other tables
ALTER TABLE public.event_bookings ENABLE ROW LEVEL SECURITY;

-- Drop existing policy
DROP POLICY IF EXISTS event_bookings_select ON public.event_bookings;

CREATE POLICY event_bookings_select ON public.event_bookings
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM purchases
            WHERE purchases.id = purchase_id
            AND (purchases.user_id = auth.uid() OR purchases.owner_id = auth.uid())
        ) OR
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

ALTER TABLE public.content_purchases ENABLE ROW LEVEL SECURITY;

-- Drop existing policy
DROP POLICY IF EXISTS content_purchases_select ON public.content_purchases;

CREATE POLICY content_purchases_select ON public.content_purchases
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM purchases
            WHERE purchases.id = purchase_id
            AND (purchases.user_id = auth.uid() OR purchases.owner_id = auth.uid())
        ) OR
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

ALTER TABLE public.appointment_purchases ENABLE ROW LEVEL SECURITY;

-- Drop existing policy
DROP POLICY IF EXISTS appointment_purchases_select ON public.appointment_purchases;

CREATE POLICY appointment_purchases_select ON public.appointment_purchases
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM purchases
            WHERE purchases.id = purchase_id
            AND (purchases.user_id = auth.uid() OR purchases.owner_id = auth.uid())
        ) OR
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- 9. Database Functions for Frontend Components

-- Function for all-sales-data
CREATE OR REPLACE FUNCTION get_all_sales(
    filters JSONB
)
RETURNS TABLE (
    id TEXT,
    customerName TEXT,
    customerEmail character varying(255),
    amount NUMERIC(10, 2),
    status TEXT,
    type TEXT,
    date TIMESTAMP WITH TIME ZONE,
    productName TEXT
) 
SECURITY DEFINER
SET search_path = public
AS $$
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
        (
            filters->>'search' IS NULL OR 
            filters->>'search' = '' OR 
            prof.full_name ILIKE '%' || COALESCE(filters->>'search', '') || '%' OR
            u.email ILIKE '%' || COALESCE(filters->>'search', '') || '%' OR
            p.id::TEXT ILIKE '%' || COALESCE(filters->>'search', '') || '%' OR
            (post.title IS NOT NULL AND post.title ILIKE '%' || COALESCE(filters->>'search', '') || '%')
        )
    ORDER BY
        p.purchase_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$ LANGUAGE plpgsql;

-- Function for appointment-sales-data
CREATE OR REPLACE FUNCTION get_appointment_sales(
    filters JSONB
)
RETURNS TABLE (
    id TEXT,
    customerName TEXT,
    customerEmail character varying(255),
    amount NUMERIC(10, 2),
    status TEXT,
    bookingDate TIMESTAMP WITH TIME ZONE,
    appointmentDate TIMESTAMP WITH TIME ZONE,
    duration INTEGER,
    serviceName TEXT,
    serviceType TEXT,
    method TEXT,
    notes TEXT
) 
SECURITY DEFINER
SET search_path = public
AS $$
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
            (filters->>'search' <> '' AND (
                prof.full_name ILIKE '%' || (filters->>'search') || '%' OR
                u.email ILIKE '%' || (filters->>'search') || '%' OR
                p.id::TEXT ILIKE '%' || (filters->>'search') || '%' OR
                (post.title IS NOT NULL AND post.title ILIKE '%' || (filters->>'search') || '%')
            ))
        )
    ORDER BY
        ap.appointment_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$ LANGUAGE plpgsql;

-- Function for content-sales-data
CREATE OR REPLACE FUNCTION get_content_sales(
    filters JSONB
)
RETURNS TABLE (
    id TEXT,
    customerName TEXT,
    customerEmail character varying(255),
    amount NUMERIC(10, 2),
    status TEXT,
    date TIMESTAMP WITH TIME ZONE,
    contentTitle TEXT,
    contentType TEXT,
    downloadCount INTEGER,
    isSubscription BOOLEAN
) 
SECURITY DEFINER
SET search_path = public
AS $$
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
            (filters->>'search' <> '' AND (
                prof.full_name ILIKE '%' || (filters->>'search') || '%' OR
                u.email ILIKE '%' || (filters->>'search') || '%' OR
                p.id::TEXT ILIKE '%' || (filters->>'search') || '%' OR
                (post.title IS NOT NULL AND post.title ILIKE '%' || (filters->>'search') || '%')
            ))
        )
    ORDER BY
        p.purchase_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$ LANGUAGE plpgsql;

-- Function for event-bookings-data
CREATE OR REPLACE FUNCTION get_event_bookings(
    filters JSONB
)
RETURNS TABLE (
    id TEXT,
    customerName TEXT,
    customerEmail character varying(255),
    amount NUMERIC(10, 2),
    status TEXT,
    bookingDate TIMESTAMP WITH TIME ZONE,
    eventTitle TEXT,
    eventDate TIMESTAMP WITH TIME ZONE,
    attendees INTEGER,
    location TEXT,
    isVirtual BOOLEAN
) 
SECURITY DEFINER
SET search_path = public
AS $$
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
            (filters->>'search' <> '' AND (
                prof.full_name ILIKE '%' || (filters->>'search') || '%' OR
                u.email ILIKE '%' || (filters->>'search') || '%' OR
                p.id::TEXT ILIKE '%' || (filters->>'search') || '%' OR
                (post.title IS NOT NULL AND post.title ILIKE '%' || (filters->>'search') || '%')
            ))
        )
    ORDER BY
        ed.start_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$ LANGUAGE plpgsql;

-- Function for subscription-data
CREATE OR REPLACE FUNCTION get_subscriptions(
    filters JSONB
)
RETURNS TABLE (
    id TEXT,
    customerName TEXT,
    customerEmail character varying(255),
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
) 
SECURITY DEFINER
SET search_path = public
AS $$
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
            (filters->>'search' <> '' AND (
                prof.full_name ILIKE '%' || (filters->>'search') || '%' OR
                u.email ILIKE '%' || (filters->>'search') || '%' OR
                s.id::TEXT ILIKE '%' || (filters->>'search') || '%' OR
                s.plan_name ILIKE '%' || (filters->>'search') || '%'
            ))
        )
    ORDER BY
        s.next_billing_date ASC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$ LANGUAGE plpgsql;

-- 10. Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.purchases TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.subscriptions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.event_bookings TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.content_purchases TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.appointment_purchases TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.stripe_webhook_events TO authenticated;

-- Grant permissions to access auth tables (needed for functions)
GRANT SELECT ON auth.users TO authenticated;
GRANT SELECT ON public.user_roles TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_all_sales TO authenticated;
GRANT EXECUTE ON FUNCTION get_appointment_sales TO authenticated;
GRANT EXECUTE ON FUNCTION get_content_sales TO authenticated;
GRANT EXECUTE ON FUNCTION get_event_bookings TO authenticated;
GRANT EXECUTE ON FUNCTION get_subscriptions TO authenticated;