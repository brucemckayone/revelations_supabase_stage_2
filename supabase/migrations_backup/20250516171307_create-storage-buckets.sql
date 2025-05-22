-- Migration to create storage buckets and set up policies
BEGIN;

-- Enable row-level security on storage.objects and storage.buckets
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- Create function to check if user is creator or admin
CREATE OR REPLACE FUNCTION public.is_creator_or_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_user_role(auth.uid()) IN ('creator', 'admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant usage on necessary schemas
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_creator_or_admin TO authenticated;

-----------------------
-- 1. post_thumbnails bucket
-----------------------
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('post_thumbnails', 'post_thumbnails', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Post thumbnails SELECT policy (anyone can view)
CREATE POLICY "Give users select access to post_thumbnails" ON storage.objects
FOR SELECT 
USING (bucket_id = 'post_thumbnails');

-- Post thumbnails DELETE policy
CREATE POLICY "Give users DELETE access to post_thumbnails" ON storage.objects
FOR DELETE TO authenticated
USING (
    bucket_id = 'post_thumbnails'
    AND (
        public.isOwnedFolder(name)
        AND public.authorizedAs(ARRAY['creator'::public.user_role])
    )
    OR public.authorizedAs(ARRAY['admin'::public.user_role])
);

-- Post thumbnails INSERT policy
CREATE POLICY "Give users insert access to post_thumbnails" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'post_thumbnails'
    AND (
        public.isOwnedFolder(name)
        AND public.authorizedAs(ARRAY['creator'::public.user_role])
    )
    OR public.authorizedAs(ARRAY['admin'::public.user_role])
);

-- Post thumbnails UPDATE policy
CREATE POLICY "Give users UPDATE access to post_thumbnails" ON storage.objects
FOR UPDATE TO authenticated
WITH CHECK (
    bucket_id = 'post_thumbnails'
    AND (
        public.isOwnedFolder(name)
        AND public.authorizedAs(ARRAY['creator'::public.user_role])
    )
    OR public.authorizedAs(ARRAY['admin'::public.user_role])
);

-----------------------
-- 2. location_thumbnails bucket
-----------------------
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('location_thumbnails', 'location_thumbnails', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Create storage policy to allow public access to read files
CREATE POLICY "Give public access to location_thumbnails" ON storage.objects
FOR SELECT
USING (bucket_id = 'location_thumbnails');

-- Create storage policy to allow authenticated users to upload files
CREATE POLICY "Allow authenticated uploads to location_thumbnails" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'location_thumbnails');

-- Create storage policy to allow authenticated users to update their own files
CREATE POLICY "Allow authenticated updates to location_thumbnails" ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'location_thumbnails' AND auth.uid() = owner);

-- Create storage policy to allow authenticated users to delete their own files
CREATE POLICY "Allow authenticated deletes from location_thumbnails" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'location_thumbnails' AND auth.uid() = owner);

-----------------------
-- 3. creator_avatars bucket
-----------------------
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('creator_avatars', 'creator_avatars', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Creator avatars SELECT policy (anyone can view)
CREATE POLICY "Allow public access to creator_avatars" ON storage.objects
FOR SELECT 
USING (bucket_id = 'creator_avatars');

-- Creator avatars INSERT/UPDATE/DELETE (creators only)
CREATE POLICY "Allow creators to manage their avatars" ON storage.objects
FOR ALL TO authenticated
USING (
    bucket_id = 'creator_avatars' 
    AND (
        (auth.uid() = owner AND public.authorizedAs(ARRAY['creator'::public.user_role]))
        OR public.authorizedAs(ARRAY['admin'::public.user_role])
    )
);

-----------------------
-- 4. creator_coverImages bucket
-----------------------
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('creator_coverImages', 'creator_coverImages', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Cover images SELECT policy (anyone can view)
CREATE POLICY "Allow public access to creator_coverImages" ON storage.objects
FOR SELECT 
USING (bucket_id = 'creator_coverImages');

-- Cover images INSERT/UPDATE/DELETE (creators only)
CREATE POLICY "Allow creators to manage their cover images" ON storage.objects
FOR ALL TO authenticated
USING (
    bucket_id = 'creator_coverImages' 
    AND (
        (auth.uid() = owner AND public.authorizedAs(ARRAY['creator'::public.user_role]))
        OR public.authorizedAs(ARRAY['admin'::public.user_role])
    )
);

-----------------------
-- 5. avatars bucket (for users)
-----------------------
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('avatars', 'avatars', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Avatar images are publicly accessible
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
FOR SELECT 
USING (bucket_id = 'avatars');

-- Anyone can upload an avatar
CREATE POLICY "Anyone can upload an avatar" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- Users can only update/delete their own avatars
CREATE POLICY "Users can manage their own avatars" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'avatars' AND auth.uid() = owner);

CREATE POLICY "Users can delete their own avatars" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'avatars' AND auth.uid() = owner);

-----------------------
-- 6. public bucket
-----------------------
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('public', 'public', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Public bucket is accessible to everyone
CREATE POLICY "Public bucket is accessible to everyone" ON storage.objects
FOR SELECT 
USING (bucket_id = 'public');

-- Only authenticated users can upload to public
CREATE POLICY "Authenticated users can upload to public" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'public');

-- Users can only manage their own files in public bucket
CREATE POLICY "Users can update their own files in public" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'public' AND auth.uid() = owner);

CREATE POLICY "Users can delete their own files in public" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'public' AND auth.uid() = owner);

COMMIT; 