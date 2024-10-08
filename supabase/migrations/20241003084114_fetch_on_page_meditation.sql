CREATE OR REPLACE FUNCTION get_on_page_meditation(p_slug text)
RETURNS TABLE (
    meditation_details JSONB,
    protected_media_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(med_det) AS meditation_details,  -- Convert the row to JSONB
        pmd.url AS protected_media_url
    FROM 
        meditation_details med_det
    LEFT JOIN 
        public.media_access_control mac
        ON mac.content_id = med_det.on_demand_media_id
        AND mac.user_id = auth.uid()
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = mac.content_id
    WHERE med_det.slug = p_slug;
END;
$$ LANGUAGE plpgsql;
