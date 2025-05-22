-- Generated with srtd from template: supabase/migrations-templates/create-storage-buckets.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

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
-- Create all buckets
-----------------------
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('post_thumbnails', 'post_thumbnails', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('location_thumbnails', 'location_thumbnails', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('creator_avatars', 'creator_avatars', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('creator_coverImages', 'creator_coverImages', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('avatars', 'avatars', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('public', 'public', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-----------------------
-- Create all policies with existence check
-----------------------
DO $$
DECLARE
  policy_exists BOOLEAN;
BEGIN
  ------------------------------
  -- 1. post_thumbnails policies
  ------------------------------
  -- Check if the post_thumbnails SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Give users select access to post_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Give users select access to post_thumbnails" ON storage.objects
      FOR SELECT 
      USING (bucket_id = 'post_thumbnails')
    $policy$;
  END IF;
  
  -- Check if the DELETE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Give users DELETE access to post_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Give users DELETE access to post_thumbnails" ON storage.objects
      FOR DELETE TO authenticated
      USING (
        bucket_id = 'post_thumbnails'
        AND (
            public.isOwnedFolder(name)
            AND public.authorizedAs(ARRAY['creator'::public.user_role])
        )
        OR public.authorizedAs(ARRAY['admin'::public.user_role])
      )
    $policy$;
  END IF;
  
  -- Check if the INSERT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Give users insert access to post_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Give users insert access to post_thumbnails" ON storage.objects
      FOR INSERT TO authenticated
      WITH CHECK (
        bucket_id = 'post_thumbnails'
        AND (
            public.isOwnedFolder(name)
            AND public.authorizedAs(ARRAY['creator'::public.user_role])
        )
        OR public.authorizedAs(ARRAY['admin'::public.user_role])
      )
    $policy$;
  END IF;
  
  -- Check if the UPDATE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Give users UPDATE access to post_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Give users UPDATE access to post_thumbnails" ON storage.objects
      FOR UPDATE TO authenticated
      WITH CHECK (
        bucket_id = 'post_thumbnails'
        AND (
            public.isOwnedFolder(name)
            AND public.authorizedAs(ARRAY['creator'::public.user_role])
        )
        OR public.authorizedAs(ARRAY['admin'::public.user_role])
      )
    $policy$;
  END IF;

  ------------------------------
  -- 2. location_thumbnails policies
  ------------------------------
  -- Check if the SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Give public access to location_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Give public access to location_thumbnails" ON storage.objects
      FOR SELECT
      USING (bucket_id = 'location_thumbnails')
    $policy$;
  END IF;
  
  -- Check if the INSERT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow authenticated uploads to location_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow authenticated uploads to location_thumbnails" ON storage.objects
      FOR INSERT
      TO authenticated
      WITH CHECK (bucket_id = 'location_thumbnails')
    $policy$;
  END IF;
  
  -- Check if the UPDATE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow authenticated updates to location_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow authenticated updates to location_thumbnails" ON storage.objects
      FOR UPDATE
      TO authenticated
      USING (bucket_id = 'location_thumbnails' AND auth.uid() = owner)
    $policy$;
  END IF;
  
  -- Check if the DELETE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow authenticated deletes from location_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow authenticated deletes from location_thumbnails" ON storage.objects
      FOR DELETE
      TO authenticated
      USING (bucket_id = 'location_thumbnails' AND auth.uid() = owner)
    $policy$;
  END IF;
  
  ------------------------------
  -- 3. creator_avatars policies
  ------------------------------
  -- Check if the SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow public access to creator_avatars'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow public access to creator_avatars" ON storage.objects
      FOR SELECT 
      USING (bucket_id = 'creator_avatars')
    $policy$;
  END IF;
  
  -- Check if the ALL policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow creators to manage their avatars'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow creators to manage their avatars" ON storage.objects
      FOR ALL TO authenticated
      USING (
        bucket_id = 'creator_avatars' 
        AND (
            (auth.uid() = owner AND public.authorizedAs(ARRAY['creator'::public.user_role]))
            OR public.authorizedAs(ARRAY['admin'::public.user_role])
        )
      )
    $policy$;
  END IF;
  
  ------------------------------
  -- 4. creator_coverImages policies
  ------------------------------
  -- Check if the SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow public access to creator_coverImages'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow public access to creator_coverImages" ON storage.objects
      FOR SELECT 
      USING (bucket_id = 'creator_coverImages')
    $policy$;
  END IF;
  
  -- Check if the ALL policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow creators to manage their cover images'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow creators to manage their cover images" ON storage.objects
      FOR ALL TO authenticated
      USING (
        bucket_id = 'creator_coverImages' 
        AND (
            (auth.uid() = owner AND public.authorizedAs(ARRAY['creator'::public.user_role]))
            OR public.authorizedAs(ARRAY['admin'::public.user_role])
        )
      )
    $policy$;
  END IF;
  
  ------------------------------
  -- 5. avatars policies
  ------------------------------
  -- Check if the SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Avatar images are publicly accessible'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
      FOR SELECT 
      USING (bucket_id = 'avatars')
    $policy$;
  END IF;
  
  -- Check if the INSERT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Anyone can upload an avatar'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Anyone can upload an avatar" ON storage.objects
      FOR INSERT TO authenticated
      WITH CHECK (bucket_id = 'avatars')
    $policy$;
  END IF;
  
  -- Check if the UPDATE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can manage their own avatars'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Users can manage their own avatars" ON storage.objects
      FOR UPDATE TO authenticated
      USING (bucket_id = 'avatars' AND auth.uid() = owner)
    $policy$;
  END IF;
  
  -- Check if the DELETE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can delete their own avatars'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Users can delete their own avatars" ON storage.objects
      FOR DELETE TO authenticated
      USING (bucket_id = 'avatars' AND auth.uid() = owner)
    $policy$;
  END IF;
  
  ------------------------------
  -- 6. public bucket policies
  ------------------------------
  -- Check if the SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Public bucket is accessible to everyone'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Public bucket is accessible to everyone" ON storage.objects
      FOR SELECT 
      USING (bucket_id = 'public')
    $policy$;
  END IF;
  
  -- Check if the INSERT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Authenticated users can upload to public'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Authenticated users can upload to public" ON storage.objects
      FOR INSERT TO authenticated
      WITH CHECK (bucket_id = 'public')
    $policy$;
  END IF;
  
  -- Check if the UPDATE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can update their own files in public'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Users can update their own files in public" ON storage.objects
      FOR UPDATE TO authenticated
      USING (bucket_id = 'public' AND auth.uid() = owner)
    $policy$;
  END IF;
  
  -- Check if the DELETE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can delete their own files in public'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Users can delete their own files in public" ON storage.objects
      FOR DELETE TO authenticated
      USING (bucket_id = 'public' AND auth.uid() = owner)
    $policy$;
  END IF;
END $$;

COMMIT; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
