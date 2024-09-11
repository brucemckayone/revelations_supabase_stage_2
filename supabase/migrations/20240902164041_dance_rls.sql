ALTER TABLE dance ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_movements_content_id ON movements(content_id);

-- Policy for reading dance records
CREATE POLICY "Users can read any dance" ON dance
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Policies for deleting dance records
CREATE POLICY "Access control for dance delete creator" ON dance
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM movements
        JOIN on_demand_media ON on_demand_media.id = movements.content_id
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE movements.id = dance.movement_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for dance delete admin" ON dance
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

-- Policies for inserting dance records
CREATE POLICY "Access control for dance insert creator" ON dance
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

CREATE POLICY "Access control for dance insert admin" ON dance
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

-- Policies for updating dance records
CREATE POLICY "Access control for dance update creator" ON dance
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM movements
        JOIN on_demand_media ON on_demand_media.id = movements.content_id
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE movements.id = dance.movement_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for dance update admin" ON dance
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);