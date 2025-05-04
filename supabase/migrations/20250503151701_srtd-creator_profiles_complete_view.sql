-- Generated with srtd from template: supabase/migrations-templates/creator_profiles_complete_view.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Create a comprehensive view that joins profiles, creator_profiles, and user_roles tables
-- to provide all creator information in a single view
CREATE OR REPLACE VIEW public.creator_profiles_complete_view AS
SELECT 
    -- Basic profile information
    p.id AS user_id,
    p.username,
    p.full_name,
    p.avatar_url,
    p.website,
    p.updated_at AS profile_updated_at,
    
    -- All creator profile information
    cp.id AS creator_profile_id,
    cp.user_id AS creator_user_id,
    cp.profile_id,
    cp.title,
    cp.updated_at AS creator_updated_at,
    cp.cover_image_url,
    cp.bio,
    cp.short_bio,
    cp.certifications,
    cp.experience,
    cp.philosophy,
    cp.background_video_url,
    cp.featured_testimonials,
    
    -- User role information
    ur.role AS user_role,
    
    -- Branding information for styling
    cb.hue,
    cb.dark,
    cb.saturation,
    cb.lightness,
    cb.contrast
FROM 
    public.profiles p
JOIN 
    public.creator_profiles cp ON cp.profile_id = p.id
LEFT JOIN 
    public.user_roles ur ON ur.user_id = p.id
LEFT JOIN 
    public.creator_branding cb ON cb.user_id = p.id
ORDER BY 
    cp.updated_at DESC NULLS LAST;

-- Add a comment to the view
COMMENT ON VIEW public.creator_profiles_complete_view IS 'Comprehensive view of creator profiles with all information fields for detailed displays'; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
