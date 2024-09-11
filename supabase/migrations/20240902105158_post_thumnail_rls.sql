
-- Update SELECT policy

CREATE POLICY "Give users select access to own folder" ON storage.objects
FOR SELECT TO authenticated
USING (
    bucket_id = 'post_thumbnails' and
    true
);

-- Update DELETE policy
CREATE POLICY "Give users DELETE access to own folder" ON storage.objects
FOR DELETE TO authenticated
USING (
    bucket_id = 'post_thumbnails'
    AND public.isOwnedFolder(name)
    AND public.authorizedAs(ARRAY['creator'::public.user_role])
    OR public.authorizedAs(ARRAY['admin'::public.user_role])
);

-- Update INSERT policy
CREATE POLICY "Give users insert access to own folder" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'post_thumbnails'
    AND public.isOwnedFolder(name)
    AND public.authorizedAs(ARRAY['creator'::public.user_role])
    OR public.authorizedAs(ARRAY['admin'::public.user_role])
);



CREATE POLICY "Give users UPDATE access to own folder" ON storage.objects
FOR UPDATE
TO authenticated
WITH CHECK
(
    bucket_id = 'post_thumbnails'
    AND public.isOwnedFolder(name)
    AND public.authorizedAs(ARRAY['creator'::public.user_role])
    OR public.authorizedAs(ARRAY['admin'::public.user_role])
);