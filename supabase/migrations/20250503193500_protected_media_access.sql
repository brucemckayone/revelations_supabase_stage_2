-- PROTECTED MEDIA ACCESS CONTROL
-- Implements functions and policies for accessing protected media content

-- 1. Create RLS policy for protected_media_data
ALTER TABLE IF EXISTS public.protected_media_data ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (if any)
DROP POLICY IF EXISTS protected_media_access ON public.protected_media_data;
DROP POLICY IF EXISTS admin_full_access_protected_media ON public.protected_media_data;

-- 2. Functions for media access control

-- Get URL for protected media if user has access
CREATE OR REPLACE FUNCTION get_protected_media_url(content_id UUID)
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_url TEXT;
BEGIN
    -- Check if user has access to this content
    IF can_access_content(content_id) THEN
        -- Get the protected URL
        SELECT url INTO v_url
        FROM protected_media_data
        WHERE content_id = content_id;
        
        -- Record the access
        UPDATE content_purchases cp
        SET 
            last_accessed = NOW(),
            download_count = download_count + 1
        FROM purchases p
        WHERE cp.purchase_id = p.id
        AND cp.content_id = content_id
        AND p.user_id = auth.uid();
        
        RETURN v_url;
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create a view to simplify access to media content
CREATE OR REPLACE VIEW accessible_media AS
SELECT 
    odm.id AS content_id,
    p.id AS post_id,
    p.title,
    p.description,
    p.thumbnail_url,
    odm.duration,
    odm.media_type,
    CASE 
        WHEN p.user_id = auth.uid() THEN true -- Creator always has access
        WHEN odm.price = 0 THEN true -- Free content is accessible
        ELSE can_access_content(odm.id) -- Check purchase/subscription
    END AS has_access,
    pmd.url AS media_url,
    CASE 
        WHEN p.user_id = auth.uid() THEN 'creator'
        WHEN odm.price = 0 THEN 'free'
        WHEN EXISTS (
            SELECT 1 
            FROM content_purchases cp
            JOIN purchases pur ON cp.purchase_id = pur.id
            WHERE cp.content_id = odm.id
            AND pur.user_id = auth.uid()
        ) THEN 'purchased'
        WHEN EXISTS (
            SELECT 1
            FROM subscriptions s
            JOIN purchases pur ON s.purchase_id = pur.id
            WHERE pur.user_id = auth.uid()
            AND pur.owner_id = p.user_id
            AND s.status IN ('active', 'trial')
        ) THEN 'subscription'
        ELSE 'not_purchased'
    END AS access_type
FROM
    on_demand_media odm
JOIN
    posts p ON odm.post_id = p.id
LEFT JOIN
    protected_media_data pmd ON odm.id = pmd.content_id
WHERE
    p.status = 'public';

COMMENT ON VIEW accessible_media IS 'View that shows media content with access control information';

-- 3. RLS policies for protected_media_data

-- Media creators can access their own protected media
CREATE POLICY creator_protected_media_access ON public.protected_media_data
    FOR ALL
    USING (
        EXISTS (
            SELECT 1
            FROM on_demand_media odm
            JOIN posts p ON odm.post_id = p.id
            WHERE odm.id = content_id
            AND p.user_id = auth.uid()
        )
    );

-- Users can see content they've purchased or have subscription access to
CREATE POLICY user_protected_media_access ON public.protected_media_data
    FOR SELECT
    USING (
        can_access_content(content_id)
    );

-- Admin access
CREATE POLICY admin_full_access_protected_media ON public.protected_media_data
    FOR ALL
    USING (
        public.has_role('admin')
    );

-- 4. Grant permissions

GRANT SELECT ON public.protected_media_data TO authenticated;
GRANT EXECUTE ON FUNCTION get_protected_media_url TO authenticated;
GRANT SELECT ON public.accessible_media TO authenticated; 