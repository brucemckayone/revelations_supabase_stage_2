-- Generated with srtd from template: supabase/migrations-templates/profile_cards_view.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Create a view that joins profiles, creator_profiles, and user_roles tables
-- to provide all necessary information for profile cards
CREATE OR REPLACE VIEW public.profile_cards_view AS
SELECT 
    p.id AS user_id,
    p.username,
    p.full_name,
    p.avatar_url,
    p.website,
    
    -- Creator profile information (may be null if not a creator)
    cp.id AS creator_profile_id,
    cp.title AS creator_title,
    cp.short_bio,
    cp.cover_image_url,
    cp.background_video_url,
    
    -- User role information
    ur.role AS user_role,
    
    -- Branding information for styling
    cb.hue,
    cb.dark,
    cb.saturation,
    cb.lightness,
    cb.contrast,
    
    -- Additional useful fields
    COALESCE(cp.updated_at, p.updated_at) AS last_updated
FROM 
    public.profiles p
LEFT JOIN 
    public.creator_profiles cp ON cp.profile_id = p.id
LEFT JOIN 
    public.user_roles ur ON ur.user_id = p.id
LEFT JOIN 
    public.creator_branding cb ON cb.user_id = p.id
ORDER BY 
    COALESCE(cp.updated_at, p.updated_at) DESC NULLS LAST;

-- Add a comment to the view
COMMENT ON VIEW public.profile_cards_view IS 'Combined view of user profiles and creator profiles for displaying profile cards'; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
