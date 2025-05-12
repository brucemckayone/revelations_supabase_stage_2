-- Fix ambiguous column references in get_on_page functions
-- Fully qualify all content_id references

-- 1. Fix get_on_page_meditation
DROP FUNCTION IF EXISTS get_on_page_meditation;
CREATE OR REPLACE FUNCTION get_on_page_meditation(p_slug text)
RETURNS TABLE (
    meditation_details JSONB,
    protected_media_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(med_det) AS meditation_details,
        CASE
            -- Creator always has access
            WHEN EXISTS (
                SELECT 1 FROM posts p
                WHERE p.id = med_det.id AND p.user_id = auth.uid()
            ) THEN pmd.url
            -- Otherwise use can_access_content_v2 function
            WHEN public.can_access_content_v2(med_det.on_demand_media_id) THEN pmd.url
            ELSE NULL
        END AS protected_media_url
    FROM 
        meditation_details med_det
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = med_det.on_demand_media_id
    WHERE med_det.slug = p_slug;
END;
$$ LANGUAGE plpgsql;

-- 2. Fix get_on_page_yoga
DROP FUNCTION IF EXISTS get_on_page_yoga;
CREATE OR REPLACE FUNCTION get_on_page_yoga(p_slug text)
RETURNS TABLE (
    yoga_details JSONB,
    protected_media_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(yoga_det) AS yoga_details,
        CASE
            -- Creator always has access
            WHEN EXISTS (
                SELECT 1 FROM posts p
                WHERE p.id = yoga_det.id AND p.user_id = auth.uid()
            ) THEN pmd.url
            -- Otherwise use can_access_content_v2 function
            WHEN public.can_access_content_v2(yoga_det.on_demand_media_id) THEN pmd.url
            ELSE NULL
        END AS protected_media_url
    FROM
        yoga_details yoga_det
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = yoga_det.on_demand_media_id
    WHERE yoga_det.slug = p_slug;
END;
$$ LANGUAGE plpgsql;

-- 3. Fix get_on_page_dance
DROP FUNCTION IF EXISTS get_on_page_dance;
CREATE OR REPLACE FUNCTION get_on_page_dance(p_slug text)
RETURNS TABLE (
    dance_details JSONB,
    protected_media_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(dance_det) AS dance_details,
        CASE
            -- Creator always has access
            WHEN EXISTS (
                SELECT 1 FROM posts p
                WHERE p.id = dance_det.id AND p.user_id = auth.uid()
            ) THEN pmd.url
            -- Otherwise use can_access_content_v2 function
            WHEN public.can_access_content_v2(dance_det.on_demand_media_id) THEN pmd.url
            ELSE NULL
        END AS protected_media_url
    FROM
        dance_details dance_det
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = dance_det.on_demand_media_id
    WHERE dance_det.slug = p_slug;
END;
$$ LANGUAGE plpgsql;

-- 4. Fix get_on_page_neuro_flow
DROP FUNCTION IF EXISTS get_on_page_neuro_flow;
CREATE OR REPLACE FUNCTION get_on_page_neuro_flow(p_slug text)
RETURNS TABLE (
    neuroflow_details JSONB,
    protected_media_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(neuro_det) AS neuroflow_details,
        CASE
            -- Creator always has access
            WHEN EXISTS (
                SELECT 1 FROM posts p
                WHERE p.id = neuro_det.id AND p.user_id = auth.uid()
            ) THEN pmd.url
            -- Otherwise use can_access_content_v2 function
            WHEN public.can_access_content_v2(neuro_det.on_demand_media_id) THEN pmd.url
            ELSE NULL
        END AS protected_media_url
    FROM 
        neuroflow_details neuro_det
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = neuro_det.on_demand_media_id
    WHERE neuro_det.slug = p_slug;
END;
$$ LANGUAGE plpgsql;

-- 5. Fix get_on_page_ceremony
DROP FUNCTION IF EXISTS get_on_page_ceremony;
CREATE OR REPLACE FUNCTION get_on_page_ceremony(p_slug text)
RETURNS TABLE (
    ceremony_details JSONB,
    protected_media_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(cer_det) AS ceremony_details,
        CASE
            -- Creator always has access
            WHEN EXISTS (
                SELECT 1 FROM posts p
                WHERE p.id = cer_det.id AND p.user_id = auth.uid()
            ) THEN pmd.url
            -- Otherwise use can_access_content_v2 function
            WHEN public.can_access_content_v2(cer_det.on_demand_media_id) THEN pmd.url
            ELSE NULL
        END AS protected_media_url
    FROM 
        ceremony_details cer_det
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = cer_det.on_demand_media_id
    WHERE cer_det.slug = p_slug;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions on the updated functions
GRANT EXECUTE ON FUNCTION get_on_page_meditation TO authenticated;
GRANT EXECUTE ON FUNCTION get_on_page_yoga TO authenticated;
GRANT EXECUTE ON FUNCTION get_on_page_dance TO authenticated;
GRANT EXECUTE ON FUNCTION get_on_page_neuro_flow TO authenticated;
GRANT EXECUTE ON FUNCTION get_on_page_ceremony TO authenticated; 