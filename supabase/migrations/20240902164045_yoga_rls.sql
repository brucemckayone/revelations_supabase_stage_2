
ALTER TABLE yoga ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_dance_movement_id ON dance(movement_id);

-- Policy for reading yoga records
CREATE POLICY "Users can read any yoga" ON yoga
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Policies for deleting yoga records
CREATE POLICY "Access control for yoga delete creator" ON yoga
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM movements
        JOIN on_demand_media ON on_demand_media.id = movements.content_id
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE movements.id = yoga.movement_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for yoga delete admin" ON yoga
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

-- Policies for inserting yoga records
CREATE POLICY "Access control for yoga insert creator" ON yoga
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM movements
        JOIN on_demand_media ON on_demand_media.id = movements.content_id
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE movements.id = movement_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for yoga insert admin" ON yoga
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

-- Policies for updating yoga records
CREATE POLICY "Access control for yoga update creator" ON yoga
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM movements
        JOIN on_demand_media ON on_demand_media.id = movements.content_id
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE movements.id = yoga.movement_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for yoga update admin" ON yoga
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);