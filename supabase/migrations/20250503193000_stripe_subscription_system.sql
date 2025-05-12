-- STRIPE SUBSCRIPTION SYSTEM
-- Implements subscription tiers, content access rules, and webhook processing

-- 1. Creator Subscription Tiers (with custom naming)
CREATE TABLE IF NOT EXISTS public.creator_subscription_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tier_key TEXT NOT NULL, -- Internal reference key (used in code)
    tier_name TEXT NOT NULL, -- Display name for the tier (customizable)
    description TEXT,
    price_monthly NUMERIC(10, 2) NOT NULL,
    price_quarterly NUMERIC(10, 2),
    price_annual NUMERIC(10, 2),
    stripe_price_id_monthly TEXT,
    stripe_price_id_quarterly TEXT, 
    stripe_price_id_annual TEXT,
    stripe_product_id TEXT,
    benefits JSONB,
    priority INTEGER NOT NULL DEFAULT 0, -- For ordering tiers (higher = better)
    is_active BOOLEAN DEFAULT true,
    trial_days INTEGER DEFAULT 0, -- 0 means no trial
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (creator_id, tier_key)
);

COMMENT ON TABLE public.creator_subscription_tiers IS 'Defines subscription tiers that creators offer, with pricing and benefits';

-- 2. Subscription Content Access Rules
CREATE TABLE IF NOT EXISTS public.subscription_content_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content_id UUID REFERENCES public.on_demand_media(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    post_type TEXT, -- Type of content this applies to (all, article, video, etc.) - NULL means specific content
    tier_key TEXT NOT NULL, -- References creator_subscription_tiers.tier_key
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_content_or_type CHECK (
        (content_id IS NOT NULL AND post_id IS NULL AND post_type IS NULL) OR
        (content_id IS NULL AND post_id IS NOT NULL AND post_type IS NULL) OR
        (content_id IS NULL AND post_id IS NULL AND post_type IS NOT NULL)
    ),
    UNIQUE (creator_id, content_id, tier_key),
    UNIQUE (creator_id, post_id, tier_key),
    UNIQUE (creator_id, post_type, tier_key)
);

COMMENT ON TABLE public.subscription_content_access IS 'Maps content to subscription tiers for access control';

-- 3. Add updated_at trigger
CREATE OR REPLACE FUNCTION update_subscription_tier_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_creator_subscription_tiers_updated_at
BEFORE UPDATE ON public.creator_subscription_tiers
FOR EACH ROW EXECUTE FUNCTION update_subscription_tier_updated_at();

-- 4. Add an active flag to subscriptions table
ALTER TABLE public.subscriptions 
ADD COLUMN IF NOT EXISTS is_trial BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS cancels_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS canceled_at TIMESTAMP WITH TIME ZONE;

-- 5. Functions for verifying subscription access

-- Check if user has an active subscription to a creator with at least the specified tier level
CREATE OR REPLACE FUNCTION has_active_subscription(
    subscription_creator_id UUID, 
    required_tier_key TEXT DEFAULT NULL
) 
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF required_tier_key IS NULL THEN
        -- Just check for any active subscription
        RETURN EXISTS (
            SELECT 1 
            FROM subscriptions s
            JOIN purchases p ON s.purchase_id = p.id
            WHERE p.owner_id = subscription_creator_id
            AND p.user_id = auth.uid()
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
        );
    ELSE
        -- Check subscription against required tier by comparing priorities
        RETURN EXISTS (
            SELECT 1 
            FROM subscriptions s
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst_user ON cst_user.tier_key = s.tier
                AND cst_user.creator_id = subscription_creator_id
            JOIN creator_subscription_tiers cst_required ON cst_required.tier_key = required_tier_key
                AND cst_required.creator_id = subscription_creator_id
            WHERE p.owner_id = subscription_creator_id
            AND p.user_id = auth.uid()
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND cst_user.priority >= cst_required.priority
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Check if the current user can access a specific content item
CREATE OR REPLACE FUNCTION can_access_content(content_id UUID)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_post_id UUID;
    v_creator_id UUID;
    v_post_type TEXT;
BEGIN
    -- Get post info for this content
    SELECT odm.post_id, p.user_id, p.post_type INTO v_post_id, v_creator_id, v_post_type
    FROM on_demand_media odm
    JOIN posts p ON odm.post_id = p.id
    WHERE odm.id = content_id;

    -- Free content is always accessible
    IF EXISTS (
        SELECT 1
        FROM on_demand_media
        WHERE id = content_id AND price = 0
    ) THEN
        RETURN TRUE;
    END IF;

    -- Check direct purchase first
    IF EXISTS (
        SELECT 1 
        FROM content_purchases cp
        JOIN purchases p ON cp.purchase_id = p.id
        WHERE cp.content_id = content_id
        AND p.user_id = auth.uid()
        AND p.payment_status = 'completed'
        AND (cp.access_expires_at IS NULL OR cp.access_expires_at > NOW())
    ) THEN
        RETURN TRUE;
    END IF;

    -- Check subscription access - look for any rule that matches
    IF v_creator_id IS NOT NULL THEN
        -- Check if content is specifically included in subscription
        IF EXISTS (
            SELECT 1
            FROM subscription_content_access sca
            JOIN subscriptions s ON TRUE
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst ON cst.creator_id = v_creator_id 
                AND cst.tier_key = s.tier
            WHERE sca.content_id = content_id
            AND p.user_id = auth.uid()
            AND p.owner_id = v_creator_id
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND sca.tier_key = s.tier
        ) THEN
            RETURN TRUE;
        END IF;

        -- Check if specific post is included in subscription
        IF EXISTS (
            SELECT 1
            FROM subscription_content_access sca
            JOIN subscriptions s ON TRUE
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst ON cst.creator_id = v_creator_id 
                AND cst.tier_key = s.tier
            WHERE sca.post_id = v_post_id
            AND p.user_id = auth.uid()
            AND p.owner_id = v_creator_id
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND sca.tier_key = s.tier
        ) THEN
            RETURN TRUE;
        END IF;

        -- Check if post type is included in subscription
        IF EXISTS (
            SELECT 1
            FROM subscription_content_access sca
            JOIN subscriptions s ON TRUE
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst ON cst.creator_id = v_creator_id 
                AND cst.tier_key = s.tier
            WHERE sca.post_type = v_post_type
            AND p.user_id = auth.uid()
            AND p.owner_id = v_creator_id
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND sca.tier_key = s.tier
        ) THEN
            RETURN TRUE;
        END IF;
    END IF;

    -- No access
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Check if the current user can access a specific event
CREATE OR REPLACE FUNCTION can_access_event(event_id UUID, date_id UUID)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check direct booking
    RETURN EXISTS (
        SELECT 1 
        FROM event_bookings eb
        JOIN purchases p ON eb.purchase_id = p.id
        WHERE eb.event_id = event_id
        AND eb.date_id = date_id
        AND p.user_id = auth.uid()
        AND p.payment_status = 'completed'
        AND eb.status IN ('confirmed', 'pending', 'attended')
    );
    -- Note: Subscriptions typically don't grant access to events
END;
$$ LANGUAGE plpgsql;

-- Check if the current user can access a specific appointment
CREATE OR REPLACE FUNCTION can_access_appointment(service_id UUID, appointment_date TIMESTAMP WITH TIME ZONE)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM appointment_purchases ap
        JOIN purchases p ON ap.purchase_id = p.id
        WHERE ap.service_id = service_id
        AND ap.appointment_date = appointment_date
        AND p.user_id = auth.uid()
        AND p.payment_status = 'completed'
        AND ap.status IN ('confirmed', 'pending', 'completed')
    );
    -- Note: Subscriptions typically don't grant access to appointments
END;
$$ LANGUAGE plpgsql;

-- 6. Functions for webhook processing

-- Process a Stripe payment intent success event (one-time purchases)
CREATE OR REPLACE FUNCTION process_payment_intent_succeeded(payment_intent_id TEXT, event_data JSONB)
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    metadata JSONB;
    purchase_type TEXT;
    purchase_id UUID;
    v_user_id UUID;
    v_owner_id UUID;
    v_amount NUMERIC(10, 2);
    v_currency TEXT;
    v_content_id UUID;
    v_event_id UUID;
    v_date_id UUID;
    v_ticket_id UUID;
    v_service_id UUID;
    v_appointment_date TIMESTAMP WITH TIME ZONE;
    v_duration INTEGER;
    v_attendees INTEGER;
BEGIN
    -- Extract metadata from the event
    metadata := event_data->'metadata';
    purchase_type := metadata->>'purchase_type';
    v_user_id := (metadata->>'user_id')::UUID;
    v_owner_id := (metadata->>'owner_id')::UUID;
    v_amount := (event_data->'amount_received')::NUMERIC / 100; -- Convert cents to dollars
    v_currency := lower(event_data->>'currency');
    
    -- Check if this payment intent has already been processed
    IF EXISTS (
        SELECT 1 FROM purchases WHERE stripe_payment_intent_id = payment_intent_id
    ) THEN
        RETURN 'Payment already processed';
    END IF;
    
    -- Process based on purchase type
    IF purchase_type = 'content' THEN
        v_content_id := (metadata->>'content_id')::UUID;
        
        -- Insert purchase record
        INSERT INTO purchases (
            user_id, owner_id, stripe_payment_intent_id, 
            amount, currency, payment_status, 
            content_id, purchase_type, purchase_date
        ) VALUES (
            v_user_id, v_owner_id, payment_intent_id,
            v_amount, v_currency, 'completed',
            v_content_id, purchase_type, NOW()
        ) RETURNING id INTO purchase_id;
        
        -- Insert content purchase details
        INSERT INTO content_purchases (
            purchase_id, content_id, download_count, 
            last_accessed, is_subscription, access_expires_at
        ) VALUES (
            purchase_id, v_content_id, 0,
            NULL, FALSE, NULL -- Permanent access
        );
        
        RETURN 'Content purchase processed';
        
    ELSIF purchase_type = 'event' THEN
        v_event_id := (metadata->>'event_id')::UUID;
        v_date_id := (metadata->>'date_id')::UUID;
        v_ticket_id := (metadata->>'ticket_id')::UUID;
        v_attendees := COALESCE((metadata->>'attendees')::INTEGER, 1);
        
        -- Insert purchase record
        INSERT INTO purchases (
            user_id, owner_id, stripe_payment_intent_id, 
            amount, currency, payment_status, 
            event_id, purchase_type, purchase_date,
            quantity
        ) VALUES (
            v_user_id, v_owner_id, payment_intent_id,
            v_amount, v_currency, 'completed',
            v_event_id, purchase_type, NOW(),
            v_attendees
        ) RETURNING id INTO purchase_id;
        
        -- Insert event booking details
        INSERT INTO event_bookings (
            purchase_id, event_id, ticket_id, date_id,
            attendees, is_virtual, status
        ) VALUES (
            purchase_id, v_event_id, v_ticket_id, v_date_id,
            v_attendees, COALESCE((metadata->>'is_virtual')::BOOLEAN, FALSE),
            'confirmed'
        );
        
        RETURN 'Event booking processed';
        
    ELSIF purchase_type = 'appointment' THEN
        v_service_id := (metadata->>'service_id')::UUID;
        v_appointment_date := (metadata->>'appointment_date')::TIMESTAMP WITH TIME ZONE;
        v_duration := COALESCE((metadata->>'duration')::INTEGER, 60);
        
        -- Insert purchase record
        INSERT INTO purchases (
            user_id, owner_id, stripe_payment_intent_id, 
            amount, currency, payment_status, 
            service_id, purchase_type, purchase_date,
            start_date, end_date
        ) VALUES (
            v_user_id, v_owner_id, payment_intent_id,
            v_amount, v_currency, 'completed',
            v_service_id, purchase_type, NOW(),
            v_appointment_date, v_appointment_date + (v_duration || ' minutes')::INTERVAL
        ) RETURNING id INTO purchase_id;
        
        -- Insert appointment details
        INSERT INTO appointment_purchases (
            purchase_id, service_id, appointment_date,
            duration, method, service_type, status
        ) VALUES (
            purchase_id, v_service_id, v_appointment_date,
            v_duration, 
            COALESCE(metadata->>'method', 'video'),
            COALESCE(metadata->>'service_type', 'consultation'),
            'confirmed'
        );
        
        RETURN 'Appointment booking processed';
        
    ELSE
        RETURN 'Unknown purchase type: ' || purchase_type;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Process a Stripe invoice paid event (subscriptions)
CREATE OR REPLACE FUNCTION process_invoice_paid(invoice_id TEXT, event_data JSONB)
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    subscription_id TEXT;
    customer_id TEXT;
    metadata JSONB;
    v_user_id UUID;
    v_owner_id UUID;
    v_amount NUMERIC(10, 2);
    v_currency TEXT;
    v_tier_key TEXT;
    v_purchase_id UUID;
    v_is_new BOOLEAN;
    v_billing_cycle TEXT;
    v_trial_ends_at TIMESTAMP WITH TIME ZONE;
    v_plan_name TEXT;
    v_tier_data RECORD;
    v_stripe_price_id TEXT;
BEGIN
    -- Extract basic data from event
    subscription_id := event_data->'subscription'->>'id';
    customer_id := event_data->>'customer';
    v_stripe_price_id := event_data->'lines'->'data'->0->>'price'->'id';
    v_amount := (event_data->>'amount_paid')::NUMERIC / 100; -- Convert cents to dollars
    v_currency := lower(event_data->>'currency');
    
    -- Check for existing purchase with this subscription ID
    SELECT id INTO v_purchase_id
    FROM purchases
    WHERE stripe_subscription_id = subscription_id;
    
    v_is_new := v_purchase_id IS NULL;
    
    -- Extract metadata for new subscriptions
    IF v_is_new THEN
        -- Get metadata from subscription
        -- Note: In practice, you'd need to make an API call to Stripe to get this data
        -- This is a placeholder - your webhook handler would need to include this data
        metadata := event_data->'subscription'->'metadata';
        
        -- Extract required data
        v_user_id := (metadata->>'user_id')::UUID;
        v_owner_id := (metadata->>'owner_id')::UUID;
        v_tier_key := metadata->>'tier';
        v_plan_name := metadata->>'plan_name';
        
        -- Determine billing cycle from price ID
        SELECT * INTO v_tier_data
        FROM creator_subscription_tiers
        WHERE creator_id = v_owner_id
        AND tier_key = v_tier_key;
        
        IF v_stripe_price_id = v_tier_data.stripe_price_id_monthly THEN
            v_billing_cycle := 'monthly';
        ELSIF v_stripe_price_id = v_tier_data.stripe_price_id_quarterly THEN
            v_billing_cycle := 'quarterly';
        ELSIF v_stripe_price_id = v_tier_data.stripe_price_id_annual THEN
            v_billing_cycle := 'annual';
        ELSE
            v_billing_cycle := 'monthly'; -- Default
        END IF;
        
        -- Check for trial
        IF (event_data->'subscription'->>'trial_end') IS NOT NULL THEN
            v_trial_ends_at := (event_data->'subscription'->>'trial_end')::TIMESTAMP WITH TIME ZONE;
        END IF;
        
        -- Insert purchase record
        INSERT INTO purchases (
            user_id, owner_id, stripe_subscription_id, stripe_customer_id,
            amount, currency, payment_status, 
            purchase_type, purchase_date, start_date
        ) VALUES (
            v_user_id, v_owner_id, subscription_id, customer_id,
            v_amount, v_currency, 'completed',
            'subscription', NOW(), NOW()
        ) RETURNING id INTO v_purchase_id;
        
        -- Insert subscription details
        INSERT INTO subscriptions (
            purchase_id, stripe_subscription_id, stripe_price_id, stripe_product_id,
            plan_name, tier, billing_cycle, status,
            next_billing_date, payments_count, total_paid,
            last_payment_status, last_payment_date,
            is_trial, trial_ends_at
        ) VALUES (
            v_purchase_id, subscription_id, v_stripe_price_id, v_tier_data.stripe_product_id,
            v_plan_name, v_tier_key, v_billing_cycle, 
            CASE WHEN v_trial_ends_at IS NOT NULL AND v_trial_ends_at > NOW() THEN 'trial' ELSE 'active' END,
            -- Next billing defaults to 30 days ahead, but would come from Stripe
            NOW() + CASE
                WHEN v_billing_cycle = 'monthly' THEN '1 month'::INTERVAL
                WHEN v_billing_cycle = 'quarterly' THEN '3 months'::INTERVAL
                WHEN v_billing_cycle = 'annual' THEN '1 year'::INTERVAL
                ELSE '1 month'::INTERVAL
            END,
            1, -- payments_count
            v_amount, -- total_paid
            'completed', -- last_payment_status
            NOW(), -- last_payment_date
            v_trial_ends_at IS NOT NULL, -- is_trial
            v_trial_ends_at -- trial_ends_at
        );
        
        RETURN 'New subscription created: ' || subscription_id;
    ELSE
        -- Update existing subscription
        
        -- Get subscription record
        DECLARE
            v_subscription_id UUID;
            v_next_billing_date TIMESTAMP WITH TIME ZONE;
            v_payments_count INTEGER;
            v_total_paid NUMERIC(10, 2);
        BEGIN
            SELECT s.id, s.next_billing_date, s.payments_count, s.total_paid
            INTO v_subscription_id, v_next_billing_date, v_payments_count, v_total_paid
            FROM subscriptions s
            WHERE s.purchase_id = v_purchase_id;
            
            -- Calculate next billing date based on current one
            SELECT s.next_billing_date + CASE
                WHEN s.billing_cycle = 'monthly' THEN '1 month'::INTERVAL
                WHEN s.billing_cycle = 'quarterly' THEN '3 months'::INTERVAL
                WHEN s.billing_cycle = 'annual' THEN '1 year'::INTERVAL
                ELSE '1 month'::INTERVAL
            END
            INTO v_next_billing_date
            FROM subscriptions s
            WHERE s.purchase_id = v_purchase_id;
            
            -- Update subscription
            UPDATE subscriptions
            SET 
                status = 'active',
                next_billing_date = v_next_billing_date,
                payments_count = v_payments_count + 1,
                total_paid = v_total_paid + v_amount,
                last_payment_status = 'completed',
                last_payment_date = NOW(),
                is_trial = FALSE, -- No longer in trial after a payment
                updated_at = NOW()
            WHERE purchase_id = v_purchase_id;
            
            -- Update purchase record
            UPDATE purchases
            SET 
                stripe_invoice_id = invoice_id,
                payment_status = 'completed',
                amount = v_amount, -- Update to latest amount
                updated_at = NOW()
            WHERE id = v_purchase_id;
        END;
        
        RETURN 'Subscription payment processed: ' || subscription_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Process a subscription created/updated event
CREATE OR REPLACE FUNCTION process_subscription_updated(subscription_id TEXT, event_data JSONB)
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_status TEXT;
    v_cancels_at TIMESTAMP WITH TIME ZONE;
    v_purchase_id UUID;
    v_canceled_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Extract data from event
    v_status := event_data->>'status';
    v_cancels_at := (event_data->>'cancel_at')::TIMESTAMP WITH TIME ZONE;
    v_canceled_at := (event_data->>'canceled_at')::TIMESTAMP WITH TIME ZONE;
    
    -- Find purchase id for this subscription
    SELECT id INTO v_purchase_id
    FROM purchases
    WHERE stripe_subscription_id = subscription_id;
    
    IF v_purchase_id IS NULL THEN
        RETURN 'Subscription not found: ' || subscription_id;
    END IF;
    
    -- Update subscription status
    UPDATE subscriptions
    SET 
        status = CASE 
            WHEN v_status = 'active' THEN 'active'
            WHEN v_status = 'trialing' THEN 'trial'
            WHEN v_status = 'past_due' THEN 'past_due'
            WHEN v_status = 'canceled' THEN 'cancelled'
            WHEN v_status = 'unpaid' THEN 'past_due'
            WHEN v_status = 'incomplete' THEN 'past_due'
            WHEN v_status = 'incomplete_expired' THEN 'cancelled'
            ELSE 'cancelled'
        END,
        cancels_at = v_cancels_at,
        canceled_at = v_canceled_at,
        updated_at = NOW()
    WHERE purchase_id = v_purchase_id;
    
    -- Update purchase status if subscription is cancelled
    IF v_status IN ('canceled', 'incomplete_expired') THEN
        UPDATE purchases
        SET payment_status = 'completed',
            end_date = NOW()
        WHERE id = v_purchase_id;
    END IF;
    
    RETURN 'Subscription updated: ' || subscription_id;
END;
$$ LANGUAGE plpgsql;

-- 7. Row Level Security
-- Add RLS policies for subscription tables

ALTER TABLE public.creator_subscription_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_content_access ENABLE ROW LEVEL SECURITY;

-- Creators can manage their own tiers
CREATE POLICY creator_manage_tiers ON public.creator_subscription_tiers
    FOR ALL
    USING (creator_id = auth.uid());

-- Everyone can view active tiers
CREATE POLICY view_active_tiers ON public.creator_subscription_tiers
    FOR SELECT
    USING (is_active = true);

-- Creators can manage their content access rules
CREATE POLICY creator_manage_access ON public.subscription_content_access
    FOR ALL
    USING (creator_id = auth.uid());

-- 8. Grant Permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.creator_subscription_tiers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.subscription_content_access TO authenticated;
GRANT EXECUTE ON FUNCTION has_active_subscription TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_content TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_event TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_appointment TO authenticated; 