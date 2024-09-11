ALTER TABLE neuroflow ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_neuroflow_movement_id ON neuroflow(movement_id);


-- Policy for reading neuroflow records
CREATE POLICY "Users can read any neuroflow" ON neuroflow
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Policies for deleting neuroflow records
CREATE POLICY "Access control for neuroflow delete creator" ON neuroflow
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM movements
        JOIN on_demand_media ON on_demand_media.id = movements.content_id
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE movements.id = neuroflow.movement_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for neuroflow delete admin" ON neuroflow
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

-- Policies for inserting neuroflow records
CREATE POLICY "Access control for neuroflow insert creator" ON neuroflow
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

CREATE POLICY "Access control for neuroflow insert admin" ON neuroflow
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

-- Policies for updating neuroflow records
CREATE POLICY "Access control for neuroflow update creator" ON neuroflow
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM movements
        JOIN on_demand_media ON on_demand_media.id = movements.content_id
        JOIN posts ON posts.id = on_demand_media.post_id
        WHERE movements.id = neuroflow.movement_id
        AND public.authorizedAs(ARRAY['creator']::public.user_role[])
        AND posts.user_id = auth.uid()
    )
);

CREATE POLICY "Access control for neuroflow update admin" ON neuroflow
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);