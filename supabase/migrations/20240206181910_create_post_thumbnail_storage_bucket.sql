-- Enable row-level security on storage.objects and storage.buckets
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- Create a function to check if the user is a creator or admin
CREATE OR REPLACE FUNCTION public.is_creator_or_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_user_role(auth.uid()) IN ('creator', 'admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Create post_thumbnails bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('post_thumbnails', 'post_thumbnails', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Create public bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('public', 'public', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Grant usage on necessary schemas
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA storage TO authenticated;

-- Grant execute on the is_creator_or_admin function
GRANT EXECUTE ON FUNCTION public.is_creator_or_admin TO authenticated;