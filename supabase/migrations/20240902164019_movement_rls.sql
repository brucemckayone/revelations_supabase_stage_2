ALTER TABLE movements ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_movements_content_id ON movements(content_id);
-- Policy for reading movements
CREATE POLICY "Users can read any movements" ON movements
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Policies for deleting movements
CREATE POLICY "Access control for movements delete creator" ON movements
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM on_demand_media
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE on_demand_media.id = movements.content_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for movements delete admin" ON movements
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

-- Policies for inserting movements
CREATE POLICY "Access control for movements insert creator" ON movements
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM on_demand_media
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE on_demand_media.id = content_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for movements insert admin" ON movements
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

-- Policies for updating movements
CREATE POLICY "Access control for movements update creator" ON movements
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM on_demand_media
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE on_demand_media.id = movements.content_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for movements update admin" ON movements
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);