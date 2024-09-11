-- Policy for selecting protected_media_data
CREATE POLICY "Access control for protected_media_data select purchased" ON protected_media_data
AS PERMISSIVE FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM media_access_control
        WHERE media_access_control.content_id = protected_media_data.content_id
        AND media_access_control.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for protected_media_data select admin" ON protected_media_data
AS PERMISSIVE FOR SELECT
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin', 'moderator']::public.user_role[])
);

CREATE POLICY "Access control for protected_media_data select creator" ON protected_media_data
AS PERMISSIVE FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM on_demand_media
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE on_demand_media.id = protected_media_data.content_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

-- Policies for deleting protected_media_data
CREATE POLICY "Access control for protected_media_data delete admin" ON protected_media_data
AS PERMISSIVE FOR DELETE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin', 'moderator']::public.user_role[])
);

CREATE POLICY "Access control for protected_media_data delete creator" ON protected_media_data
AS PERMISSIVE FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM on_demand_media
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE on_demand_media.id = protected_media_data.content_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

-- Policies for inserting protected_media_data
CREATE POLICY "Access control for protected_media_data insert admin" ON protected_media_data
AS PERMISSIVE FOR INSERT
TO authenticated
WITH CHECK (
    public.authorizedAs(ARRAY['admin', 'moderator']::public.user_role[])
);

CREATE POLICY "Access control for protected_media_data insert creator" ON protected_media_data
AS PERMISSIVE FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM on_demand_media
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE on_demand_media.id = content_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

-- Policies for updating protected_media_data
CREATE POLICY "Access control for protected_media_data update admin" ON protected_media_data
AS PERMISSIVE FOR UPDATE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin', 'moderator']::public.user_role[])
);

CREATE POLICY "Access control for protected_media_data update creator" ON protected_media_data
AS PERMISSIVE FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM on_demand_media
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE on_demand_media.id = protected_media_data.content_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);