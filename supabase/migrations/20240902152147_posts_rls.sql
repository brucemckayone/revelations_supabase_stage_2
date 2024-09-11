ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_tags ENABLE ROW LEVEL SECURITY;


-- Policies for posts table
CREATE POLICY "Users can read any post" ON posts
AS PERMISSIVE FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Users can insert their own posts" ON posts
AS PERMISSIVE FOR INSERT
TO authenticated
WITH CHECK (
    public.authorizedAs(ARRAY['creator']::public.user_role[])
    AND user_id = auth.uid()
);

CREATE POLICY "Admins and moderators can insert any post" ON posts
AS PERMISSIVE FOR INSERT
TO authenticated
WITH CHECK (
    public.authorizedAs(ARRAY['admin', 'moderator']::public.user_role[])
);

CREATE POLICY "Users can update their own posts" ON posts
AS PERMISSIVE FOR UPDATE
TO authenticated
USING (
    public.authorizedAs(ARRAY['creator']::public.user_role[])
    AND user_id = auth.uid()
);

CREATE POLICY "Admins and moderators can update any post" ON posts
AS PERMISSIVE FOR UPDATE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin', 'moderator']::public.user_role[])
);

CREATE POLICY "Users can delete their own posts" ON posts
AS PERMISSIVE FOR DELETE
TO authenticated
USING (
    public.authorizedAs(ARRAY['creator']::public.user_role[])
    AND user_id = auth.uid()
);

CREATE POLICY "Admins and moderators can delete any post" ON posts
AS PERMISSIVE FOR DELETE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin', 'moderator']::public.user_role[])
);

-- Policies for tags table
CREATE POLICY "Public read access for tags" ON tags
AS PERMISSIVE FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Authorized users can delete tags" ON tags
AS PERMISSIVE FOR DELETE
TO authenticated
USING (public.authorizedAs(ARRAY['admin', 'moderator','creator']::public.user_role[]));

CREATE POLICY "Authorized users can insert tags" ON tags
AS PERMISSIVE FOR INSERT
TO authenticated
WITH CHECK (public.authorizedAs(ARRAY['admin', 'moderator','creator']::public.user_role[]));

CREATE POLICY "Authorized users can update tags" ON tags
AS PERMISSIVE FOR UPDATE
TO authenticated
USING (public.authorizedAs(ARRAY['admin', 'moderator','creator']::public.user_role[]));

-- Policies for post_tags table
CREATE POLICY "Public read access for post_tags" ON post_tags
AS PERMISSIVE FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Creators can delete their own post_tags" ON post_tags
AS PERMISSIVE FOR DELETE
TO authenticated
USING (
    public.authorizedAs(ARRAY['creator']::public.user_role[])
    AND EXISTS (
        SELECT 1 FROM posts
        WHERE posts.id = post_tags.post_id
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Admins and moderators can delete any post_tags" ON post_tags
AS PERMISSIVE FOR DELETE
TO authenticated
USING (public.authorizedAs(ARRAY['admin', 'moderator']::public.user_role[]));

CREATE POLICY "Creators can insert their own post_tags" ON post_tags
AS PERMISSIVE FOR INSERT
TO authenticated
WITH CHECK (
    public.authorizedAs(ARRAY['creator']::public.user_role[])
    AND EXISTS (
        SELECT 1 FROM posts
        WHERE posts.id = post_tags.post_id
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Admins and moderators can insert any post_tags" ON post_tags
AS PERMISSIVE FOR INSERT
TO authenticated
WITH CHECK (public.authorizedAs(ARRAY['admin', 'moderator']::public.user_role[]));

CREATE POLICY "Creators can update their own post_tags" ON post_tags
AS PERMISSIVE FOR UPDATE
TO authenticated
USING (
    public.authorizedAs(ARRAY['creator']::public.user_role[])
    AND EXISTS (
        SELECT 1 FROM posts
        WHERE posts.id = post_tags.post_id
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Admins and moderators can update any post_tags" ON post_tags
AS PERMISSIVE FOR UPDATE
TO authenticated
USING (public.authorizedAs(ARRAY['admin', 'moderator']::public.user_role[]));