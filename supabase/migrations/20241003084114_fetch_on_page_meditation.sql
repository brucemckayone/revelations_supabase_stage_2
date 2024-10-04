CREATE OR REPLACE FUNCTION get_on_page_meditation(current_user_id UUID)
RETURNS TABLE (
    
    id UUID,
    title TEXT,
    description TEXT,
    
    protected_media_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        med_det.*,
        pmd.url AS protected_media_url
    FROM
        meditation_details med_det
    LEFT JOIN 
        public.media_access_control mac 
        ON mac.content_id = med_det.on_demand_media_id 
        AND mac.user_id = current_user_id
    LEFT JOIN
        public.protected_media_data pmd 
        ON pmd.content_id = mac.content_id;
END;
$$ LANGUAGE plpgsql;
