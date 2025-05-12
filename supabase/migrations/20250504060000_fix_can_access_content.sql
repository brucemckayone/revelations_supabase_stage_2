-- Fix ambiguous column references in can_access_content function
-- This function is called by various views and other functions

CREATE OR REPLACE FUNCTION can_access_content(content_id UUID)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_post_id UUID;
    v_creator_id UUID;
    v_post_type TEXT;
    v_content_id ALIAS FOR content_id; -- Use an alias for internal references
BEGIN
    -- Get post info for this content
    SELECT odm.post_id, p.user_id, p.post_type INTO v_post_id, v_creator_id, v_post_type
    FROM on_demand_media odm
    JOIN posts p ON odm.post_id = p.id
    WHERE odm.id = v_content_id;

    -- Free content is always accessible
    IF EXISTS (
        SELECT 1
        FROM on_demand_media odm
        WHERE odm.id = v_content_id AND odm.price = 0
    ) THEN
        RETURN TRUE;
    END IF;

    -- Check direct purchase first
    IF EXISTS (
        SELECT 1 
        FROM content_purchases cp
        JOIN purchases p ON cp.purchase_id = p.id
        WHERE cp.content_id = v_content_id
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
            WHERE sca.content_id = v_content_id
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION can_access_content TO authenticated; 