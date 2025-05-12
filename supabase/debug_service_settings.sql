-- Debug function to check service settings
CREATE OR REPLACE FUNCTION debug_service_settings(p_service_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'service_id', s.id,
        'booking_workflow', s.booking_workflow,
        'auto_confirm', s.auto_confirm,
        'post_id', s.post_id,
        'owner_id', p.user_id,
        'title', p.title,
        'price', s.price
    ) INTO v_result
    FROM 
        public.services s
    JOIN 
        public.posts p ON s.post_id = p.id
    WHERE 
        s.id = p_service_id;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution permission
GRANT EXECUTE ON FUNCTION debug_service_settings TO authenticated;

-- Usage: 
-- SELECT debug_service_settings('a0a772ac-9e7e-4dbd-a4d0-5d1d8a2c1791'); 