
ALTER TABLE on_demand_media ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_on_demand_media_post_id ON on_demand_media(post_id);
-- Policy for reading on_demand_media records
CREATE POLICY "Users can read any on_demand_media" ON on_demand_media
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Policies for deleting on_demand_media records
CREATE POLICY "Access control for on_demand_media delete creator" ON on_demand_media
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM posts
        WHERE posts.id = on_demand_media.post_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for on_demand_media delete admin" ON on_demand_media
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

-- Policies for inserting on_demand_media records
CREATE POLICY "Access control for on_demand_media insert creator" ON on_demand_media
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.posts
        WHERE posts.id = post_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
         AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for on_demand_media insert admin" ON on_demand_media
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

-- Policies for updating on_demand_media records
CREATE POLICY "Access control for on_demand_media update creator" ON on_demand_media
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM posts
        WHERE posts.id = on_demand_media.post_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for on_demand_media update admin" ON on_demand_media
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);