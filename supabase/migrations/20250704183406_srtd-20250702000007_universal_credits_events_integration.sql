-- Universal Credits Events Integration
-- Extends the existing universal packages system to support event bookings
-- Allows users to use credits from universal packages to book events

BEGIN;

-- ====================================
-- EXTEND EXISTING TABLES
-- ====================================

-- Add event-specific configuration to universal packages
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'universal_packages' 
        AND column_name = 'event_access_config'
    ) THEN
        ALTER TABLE public.universal_packages 
        ADD COLUMN event_access_config JSONB DEFAULT '{}';
    END IF;
END $$;

-- Add comment explaining the event_access_config structure
COMMENT ON COLUMN public.universal_packages.event_access_config IS 
'Configuration for event access. Example structure:
{
  "access_type": "credits" | "unlimited" | "tier_based",
  "credits_per_event": 1,
  "included_event_types": ["workshop", "seminar"],
  "excluded_creators": ["uuid1", "uuid2"],
  "max_events_per_month": 5,
  "premium_events_included": true,
  "early_access_hours": 24,
  "max_ticket_value": 50.00
}';

-- ====================================
-- NEW TABLES
-- ====================================

-- Track event credit usage from universal packages
CREATE TABLE IF NOT EXISTS public.universal_package_event_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_purchase_id UUID NOT NULL REFERENCES public.universal_package_purchases(id) ON DELETE CASCADE,
    event_booking_id UUID NOT NULL REFERENCES public.event_bookings(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
    
    -- Usage details
    credits_used INTEGER NOT NULL DEFAULT 1 CHECK (credits_used > 0),
    original_ticket_price NUMERIC(10,2),
    ticket_quantity INTEGER NOT NULL DEFAULT 1,
    
    -- Context
    usage_context JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Constraints
    UNIQUE(package_purchase_id, event_booking_id)
);

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_universal_package_event_usage_package_purchase_id 
    ON public.universal_package_event_usage(package_purchase_id);
CREATE INDEX IF NOT EXISTS idx_universal_package_event_usage_event_id 
    ON public.universal_package_event_usage(event_id);
CREATE INDEX IF NOT EXISTS idx_universal_package_event_usage_created_at 
    ON public.universal_package_event_usage(created_at);

-- Event credit access rules (defines which events can be accessed with which packages)
CREATE TABLE IF NOT EXISTS public.universal_package_event_access_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_id UUID NOT NULL REFERENCES public.universal_packages(id) ON DELETE CASCADE,
    
    -- Access scope
    creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL means all creators
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE, -- NULL means all events
    event_type TEXT, -- NULL means all types
    
    -- Access configuration
    credits_required INTEGER DEFAULT 1 CHECK (credits_required > 0),
    max_ticket_value NUMERIC(10,2), -- NULL means no limit
    access_level TEXT DEFAULT 'standard' CHECK (access_level IN ('standard', 'premium', 'vip')),
    
    -- Early access
    early_access_hours INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Constraints
    CONSTRAINT unique_package_event_rule UNIQUE(package_id, creator_id, event_id, event_type)
);

-- Index for rule lookups
CREATE INDEX IF NOT EXISTS idx_universal_package_event_access_rules_package_id 
    ON public.universal_package_event_access_rules(package_id);
CREATE INDEX IF NOT EXISTS idx_universal_package_event_access_rules_creator_id 
    ON public.universal_package_event_access_rules(creator_id);
CREATE INDEX IF NOT EXISTS idx_universal_package_event_access_rules_event_id 
    ON public.universal_package_event_access_rules(event_id);

-- ====================================
-- ROW LEVEL SECURITY
-- ====================================

-- Enable RLS
ALTER TABLE public.universal_package_event_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.universal_package_event_access_rules ENABLE ROW LEVEL SECURITY;

-- Usage tracking policies
CREATE POLICY "Users can view their own event credit usage" ON public.universal_package_event_usage
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.universal_package_purchases upp 
            WHERE upp.id = package_purchase_id AND upp.user_id = auth.uid()
        )
    );

CREATE POLICY "System can manage event credit usage" ON public.universal_package_event_usage
    FOR ALL USING (true);

-- Access rules policies
CREATE POLICY "Anyone can view active access rules" ON public.universal_package_event_access_rules
    FOR SELECT USING (is_active = true);

CREATE POLICY "Package creators can manage access rules" ON public.universal_package_event_access_rules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.universal_packages up 
            WHERE up.id = package_id AND up.creator_id = auth.uid()
        )
    );

-- ====================================
-- CORE FUNCTIONS
-- ====================================

-- Function to check if a user can book an event with credits
DROP FUNCTION IF EXISTS public.can_book_event_with_credits;
CREATE OR REPLACE FUNCTION public.can_book_event_with_credits(
    p_user_id UUID,
    p_event_id UUID,
    p_ticket_id UUID,
    p_quantity INTEGER DEFAULT 1
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_package_purchase RECORD;
    v_event RECORD;
    v_ticket RECORD;
    v_access_rule RECORD;
    v_credits_required INTEGER;
    v_can_book BOOLEAN := false;
    v_result JSONB := '{}';
    v_available_packages JSONB := '[]';
    v_package_info JSONB;
BEGIN
    -- Get event and ticket details
    SELECT 
        e.*,
        p.user_id as creator_id,
        p.title as event_title
    INTO v_event
    FROM public.events e
    JOIN public.posts p ON e.post_id = p.id
    WHERE e.id = p_event_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('can_book', false, 'error', 'Event not found');
    END IF;
    
    SELECT * INTO v_ticket
    FROM public.tickets
    WHERE id = p_ticket_id AND event_id = p_event_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('can_book', false, 'error', 'Ticket not found');
    END IF;
    
    -- Check each active universal package purchase
    FOR v_package_purchase IN
        SELECT 
            upp.*,
            up.name as package_name,
            up.event_access_config,
            up.event_credits as total_event_credits
        FROM public.universal_package_purchases upp
        JOIN public.universal_packages up ON upp.package_id = up.id
        WHERE upp.user_id = p_user_id
        AND upp.is_active = true
        AND upp.event_credits_remaining > 0
        AND (upp.expires_at IS NULL OR upp.expires_at > NOW())
        ORDER BY upp.created_at ASC -- Use oldest credits first
    LOOP
        v_credits_required := 1; -- Default
        v_can_book := false;
        
        -- Check package-level event access configuration
        IF v_package_purchase.event_access_config IS NOT NULL THEN
            -- Check access type
            CASE v_package_purchase.event_access_config->>'access_type'
                WHEN 'unlimited' THEN
                    v_can_book := true;
                    v_credits_required := 0;
                    
                WHEN 'credits' THEN
                    v_credits_required := COALESCE(
                        (v_package_purchase.event_access_config->>'credits_per_event')::INTEGER, 
                        1
                    );
                    
                    -- Check if user has enough credits
                    IF v_package_purchase.event_credits_remaining >= v_credits_required * p_quantity THEN
                        v_can_book := true;
                    END IF;
                    
                WHEN 'tier_based' THEN
                    -- Check specific access rules
                    SELECT * INTO v_access_rule
                    FROM public.universal_package_event_access_rules
                    WHERE package_id = v_package_purchase.package_id
                    AND is_active = true
                    AND (creator_id IS NULL OR creator_id = v_event.creator_id)
                    AND (event_id IS NULL OR event_id = p_event_id)
                    AND (event_type IS NULL OR event_type = v_event.type::TEXT)
                    ORDER BY 
                        CASE WHEN event_id IS NOT NULL THEN 1 ELSE 2 END,
                        CASE WHEN creator_id IS NOT NULL THEN 1 ELSE 2 END,
                        CASE WHEN event_type IS NOT NULL THEN 1 ELSE 2 END
                    LIMIT 1;
                    
                    IF FOUND THEN
                        v_credits_required := v_access_rule.credits_required;
                        
                        -- Check credits availability
                        IF v_package_purchase.event_credits_remaining >= v_credits_required * p_quantity THEN
                            -- Check max ticket value restriction
                            IF v_access_rule.max_ticket_value IS NULL OR 
                               v_ticket.price <= v_access_rule.max_ticket_value THEN
                                v_can_book := true;
                            END IF;
                        END IF;
                    END IF;
            END CASE;
            
            -- Additional package-level restrictions
            IF v_can_book THEN
                -- Check excluded creators
                IF v_package_purchase.event_access_config->'excluded_creators' IS NOT NULL THEN
                    IF jsonb_exists_any_text(
                        v_package_purchase.event_access_config->'excluded_creators',
                        ARRAY[v_event.creator_id::TEXT]
                    ) THEN
                        v_can_book := false;
                    END IF;
                END IF;
                
                -- Check included event types
                IF v_package_purchase.event_access_config->'included_event_types' IS NOT NULL THEN
                    IF NOT jsonb_exists_any_text(
                        v_package_purchase.event_access_config->'included_event_types',
                        ARRAY[v_event.type::TEXT]
                    ) THEN
                        v_can_book := false;
                    END IF;
                END IF;
                
                -- Check max ticket value
                IF v_package_purchase.event_access_config->>'max_ticket_value' IS NOT NULL THEN
                    IF v_ticket.price > (v_package_purchase.event_access_config->>'max_ticket_value')::NUMERIC THEN
                        v_can_book := false;
                    END IF;
                END IF;
                
                -- Check monthly event limit
                IF v_package_purchase.event_access_config->>'max_events_per_month' IS NOT NULL THEN
                    DECLARE
                        v_events_this_month INTEGER;
                        v_monthly_limit INTEGER;
                    BEGIN
                        v_monthly_limit := (v_package_purchase.event_access_config->>'max_events_per_month')::INTEGER;
                        
                        SELECT COUNT(*)
                        INTO v_events_this_month
                        FROM public.universal_package_event_usage upeu
                        WHERE upeu.package_purchase_id = v_package_purchase.id
                        AND DATE_TRUNC('month', upeu.created_at) = DATE_TRUNC('month', NOW());
                        
                        IF v_events_this_month >= v_monthly_limit THEN
                            v_can_book := false;
                        END IF;
                    END;
                END IF;
            END IF;
        END IF;
        
        -- Add package to available options
        v_package_info := jsonb_build_object(
            'package_purchase_id', v_package_purchase.id,
            'package_name', v_package_purchase.package_name,
            'credits_remaining', v_package_purchase.event_credits_remaining,
            'credits_required', v_credits_required,
            'total_cost', v_credits_required * p_quantity,
            'can_book', v_can_book,
            'expires_at', v_package_purchase.expires_at
        );
        
        v_available_packages := v_available_packages || v_package_info;
        
        -- If this package can fulfill the booking, mark as possible
        IF v_can_book THEN
            v_result := v_result || jsonb_build_object('can_book', true);
        END IF;
    END LOOP;
    
    -- Build final result
    v_result := v_result || jsonb_build_object(
        'available_packages', v_available_packages,
        'event_id', p_event_id,
        'ticket_id', p_ticket_id,
        'quantity', p_quantity,
        'ticket_price', v_ticket.price
    );
    
    -- Set can_book to false if not already set
    IF NOT (v_result ? 'can_book') THEN
        v_result := v_result || jsonb_build_object('can_book', false);
    END IF;
    
    RETURN v_result;
END;
$$;

-- Function to book an event using universal credits
DROP FUNCTION IF EXISTS public.book_event_with_credits;
CREATE OR REPLACE FUNCTION public.book_event_with_credits(
    p_package_purchase_id UUID,
    p_event_id UUID,
    p_date_id UUID,
    p_ticket_id UUID,
    p_quantity INTEGER DEFAULT 1
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_package_purchase RECORD;
    v_event RECORD;
    v_ticket RECORD;
    v_access_check JSONB;
    v_credits_required INTEGER;
    v_booking_result JSONB;
    v_booking_id UUID;
    v_purchase_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    -- Get package purchase details
    SELECT 
        upp.*,
        up.name as package_name,
        up.event_access_config
    INTO v_package_purchase
    FROM public.universal_package_purchases upp
    JOIN public.universal_packages up ON upp.package_id = up.id
    WHERE upp.id = p_package_purchase_id 
    AND upp.user_id = v_user_id
    AND upp.is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Package purchase not found or expired';
    END IF;
    
    -- Check if package is still valid
    IF v_package_purchase.expires_at IS NOT NULL AND v_package_purchase.expires_at < NOW() THEN
        RAISE EXCEPTION 'Package has expired';
    END IF;
    
    -- Check if event can be booked with this package
    v_access_check := public.can_book_event_with_credits(
        v_user_id, p_event_id, p_ticket_id, p_quantity
    );
    
    IF NOT (v_access_check->>'can_book')::BOOLEAN THEN
        RAISE EXCEPTION 'This event cannot be booked with the selected package: %', 
            COALESCE(v_access_check->>'error', 'Access denied');
    END IF;
    
    -- Find the specific package in the access check results
    DECLARE
        v_package_option JSONB;
    BEGIN
        SELECT jsonb_array_elements
        INTO v_package_option
        FROM jsonb_array_elements(v_access_check->'available_packages')
        WHERE (jsonb_array_elements->>'package_purchase_id')::UUID = p_package_purchase_id
        AND (jsonb_array_elements->>'can_book')::BOOLEAN = true
        LIMIT 1;
        
        IF v_package_option IS NULL THEN
            RAISE EXCEPTION 'Selected package cannot be used for this booking';
        END IF;
        
        v_credits_required := (v_package_option->>'credits_required')::INTEGER;
    END;
    
    -- Check sufficient credits
    IF v_package_purchase.event_credits_remaining < v_credits_required * p_quantity THEN
        RAISE EXCEPTION 'Insufficient credits remaining. Required: %, Available: %', 
            v_credits_required * p_quantity, v_package_purchase.event_credits_remaining;
    END IF;
    
    -- Get ticket details for context
    SELECT * INTO v_ticket
    FROM public.tickets
    WHERE id = p_ticket_id;
    
    -- Create the event booking using existing function (but mark as completed/free)
    v_booking_result := public.create_event_purchase(
        p_event_id, p_ticket_id, p_date_id, p_quantity, 
        false, NULL, 'completed'
    );
    
    v_booking_id := (v_booking_result->>'booking_id')::UUID;
    v_purchase_id := (v_booking_result->>'purchase_id')::UUID;
    
    -- Update the purchase to reflect it was paid with credits
    UPDATE public.purchases
    SET 
        amount = 0, -- No charge since paid with credits
        metadata = COALESCE(metadata, '{}') || jsonb_build_object(
            'paid_with_credits', true,
            'package_purchase_id', p_package_purchase_id,
            'credits_used', v_credits_required * p_quantity,
            'original_ticket_price', v_ticket.price
        )
    WHERE id = v_purchase_id;
    
    -- Deduct credits from the package
    UPDATE public.universal_package_purchases
    SET 
        event_credits_remaining = event_credits_remaining - (v_credits_required * p_quantity),
        updated_at = NOW()
    WHERE id = p_package_purchase_id;
    
    -- Track the credit usage
    INSERT INTO public.universal_package_event_usage (
        package_purchase_id, event_booking_id, event_id, ticket_id,
        credits_used, original_ticket_price, ticket_quantity,
        usage_context
    ) VALUES (
        p_package_purchase_id, v_booking_id, p_event_id, p_ticket_id,
        v_credits_required * p_quantity, v_ticket.price, p_quantity,
        jsonb_build_object(
            'booking_method', 'universal_credits',
            'package_name', v_package_purchase.package_name
        )
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'booking_id', v_booking_id,
        'purchase_id', v_purchase_id,
        'credits_used', v_credits_required * p_quantity,
        'credits_remaining', v_package_purchase.event_credits_remaining - (v_credits_required * p_quantity),
        'original_ticket_price', v_ticket.price,
        'total_saved', v_ticket.price * p_quantity
    );
END;
$$;

-- Function to get user's event credit packages
DROP FUNCTION IF EXISTS public.get_user_event_credit_packages;
CREATE OR REPLACE FUNCTION public.get_user_event_credit_packages(
    p_user_id UUID DEFAULT NULL
) RETURNS TABLE (
    package_purchase_id UUID,
    package_id UUID,
    package_name TEXT,
    event_credits_remaining INTEGER,
    total_event_credits INTEGER,
    expires_at TIMESTAMP WITH TIME ZONE,
    event_access_config JSONB,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := COALESCE(p_user_id, auth.uid());
    
    RETURN QUERY
    SELECT 
        upp.id as package_purchase_id,
        up.id as package_id,
        up.name as package_name,
        upp.event_credits_remaining,
        up.event_credits as total_event_credits,
        upp.expires_at,
        up.event_access_config,
        upp.created_at
    FROM public.universal_package_purchases upp
    JOIN public.universal_packages up ON upp.package_id = up.id
    WHERE upp.user_id = v_user_id
    AND upp.is_active = true
    AND upp.event_credits_remaining > 0
    AND (upp.expires_at IS NULL OR upp.expires_at > NOW())
    ORDER BY upp.created_at ASC; -- Show oldest packages first (FIFO usage)
END;
$$;

-- Function to create package access rules
DROP FUNCTION IF EXISTS public.create_package_event_access_rule;
CREATE OR REPLACE FUNCTION public.create_package_event_access_rule(
    p_package_id UUID,
    p_creator_id UUID DEFAULT NULL,
    p_event_id UUID DEFAULT NULL,
    p_event_type TEXT DEFAULT NULL,
    p_credits_required INTEGER DEFAULT 1,
    p_max_ticket_value NUMERIC(10,2) DEFAULT NULL,
    p_access_level TEXT DEFAULT 'standard'
) RETURNS public.universal_package_event_access_rules
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_package_creator_id UUID;
    v_rule public.universal_package_event_access_rules;
BEGIN
    -- Verify the user owns the package
    SELECT creator_id INTO v_package_creator_id
    FROM public.universal_packages
    WHERE id = p_package_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Package not found';
    END IF;
    
    IF v_package_creator_id != auth.uid() THEN
        RAISE EXCEPTION 'You can only create access rules for your own packages';
    END IF;
    
    -- Create the access rule
    INSERT INTO public.universal_package_event_access_rules (
        package_id, creator_id, event_id, event_type,
        credits_required, max_ticket_value, access_level
    ) VALUES (
        p_package_id, p_creator_id, p_event_id, p_event_type,
        p_credits_required, p_max_ticket_value, p_access_level
    ) RETURNING * INTO v_rule;
    
    RETURN v_rule;
END;
$$;

-- ====================================
-- HELPER FUNCTIONS
-- ====================================

-- Function to get event credit usage statistics
DROP FUNCTION IF EXISTS public.get_event_credit_usage_stats;
CREATE OR REPLACE FUNCTION public.get_event_credit_usage_stats(
    p_package_id UUID DEFAULT NULL,
    p_creator_id UUID DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_stats JSONB;
    v_creator_id UUID;
BEGIN
    v_creator_id := COALESCE(p_creator_id, auth.uid());
    
    SELECT jsonb_build_object(
        'total_credits_used', COALESCE(SUM(upeu.credits_used), 0),
        'total_events_booked', COUNT(DISTINCT upeu.event_booking_id),
        'total_value_saved', COALESCE(SUM(upeu.original_ticket_price * upeu.ticket_quantity), 0),
        'unique_users', COUNT(DISTINCT upp.user_id),
        'most_popular_events', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'event_id', e.id,
                    'event_title', p.title,
                    'bookings_count', COUNT(*)
                )
            )
            FROM (
                SELECT upeu.event_id, COUNT(*) as booking_count
                FROM public.universal_package_event_usage upeu
                JOIN public.universal_package_purchases upp ON upeu.package_purchase_id = upp.id
                JOIN public.universal_packages up ON upp.package_id = up.id
                WHERE (p_package_id IS NULL OR up.id = p_package_id)
                AND up.creator_id = v_creator_id
                GROUP BY upeu.event_id
                ORDER BY COUNT(*) DESC
                LIMIT 5
            ) top_events
            JOIN public.events e ON top_events.event_id = e.id
            JOIN public.posts p ON e.post_id = p.id
        )
    ) INTO v_stats
    FROM public.universal_package_event_usage upeu
    JOIN public.universal_package_purchases upp ON upeu.package_purchase_id = upp.id
    JOIN public.universal_packages up ON upp.package_id = up.id
    WHERE (p_package_id IS NULL OR up.id = p_package_id)
    AND up.creator_id = v_creator_id;
    
    RETURN COALESCE(v_stats, '{"total_credits_used": 0, "total_events_booked": 0, "total_value_saved": 0, "unique_users": 0}');
END;
$$;

-- ====================================
-- TRIGGERS
-- ====================================

-- Update timestamps for access rules
DROP TRIGGER IF EXISTS update_universal_package_event_access_rules_updated_at 
    ON public.universal_package_event_access_rules;
CREATE TRIGGER update_universal_package_event_access_rules_updated_at
    BEFORE UPDATE ON public.universal_package_event_access_rules
    FOR EACH ROW
    EXECUTE FUNCTION public.update_event_package_updated_at();

-- ====================================
-- GRANTS
-- ====================================

-- Grant table permissions
GRANT ALL ON TABLE public.universal_package_event_usage TO authenticated, service_role;
GRANT ALL ON TABLE public.universal_package_event_access_rules TO authenticated, service_role;

-- Grant function permissions
GRANT EXECUTE ON FUNCTION public.can_book_event_with_credits TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.book_event_with_credits TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_user_event_credit_packages TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.create_package_event_access_rule TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_event_credit_usage_stats TO authenticated, service_role;

COMMIT; 