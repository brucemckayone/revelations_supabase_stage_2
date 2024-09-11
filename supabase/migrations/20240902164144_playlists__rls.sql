CREATE POLICY "Users can read any spotify_playlist_join" ON spotify_playlist_join
    FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "Access control for spotify_playlist_join update creator and onder" ON spotify_playlist_join
as PERMISSIVE
for update
to authenticated
using (
    EXISTS (
            SELECT 1 FROM on_demand_media
            JOIN posts ON posts.id = on_demand_media.post_id
            WHERE on_demand_media.id = spotify_playlist_join.content_id
            AND (
                (public.authorizedAs(ARRAY['creator']::public.user_role[]) AND posts.user_id = auth.uid())
            )
        )
);

CREATE POLICY "Access control for spotify_playlist_join delete creator and onder" ON spotify_playlist_join
as PERMISSIVE
for delete
to authenticated
using (
    EXISTS (
            SELECT 1 FROM on_demand_media
            JOIN posts ON posts.id = on_demand_media.post_id
            WHERE on_demand_media.id = spotify_playlist_join.content_id
            AND (
                (public.authorizedAs(ARRAY['creator']::public.user_role[]) AND posts.user_id = auth.uid())
            )
        )
);

CREATE POLICY "Access control for spotify_playlist_join insert creator and onder" ON spotify_playlist_join
as PERMISSIVE
for insert
to authenticated
with check (
    EXISTS (
            SELECT 1 FROM on_demand_media
            JOIN posts ON posts.id = on_demand_media.post_id
            WHERE on_demand_media.id = spotify_playlist_join.content_id
            AND (
                (public.authorizedAs(ARRAY['creator']::public.user_role[]) AND posts.user_id = auth.uid())
            )
        )
);

CREATE POLICY "enable admin update" ON spotify_playlist_join
as PERMISSIVE
for update 
to authenticated
using (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

CREATE POLICY "enable admin delete" ON spotify_playlist_join
as PERMISSIVE
for delete
to authenticated
using (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

CREATE POLICY "enable admin insert" ON spotify_playlist_join
as PERMISSIVE
for insert
to authenticated
with check (
    public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);


CREATE POLICY "Users can read any spotify_playlists" ON spotify_playlists
    FOR SELECT
    TO anon, authenticated
    USING (true);

create policy "Enable delete creator and owner"
on "public"."spotify_playlists"
as PERMISSIVE
for DELETE
to authenticated
using (
  (public.authorizedAs(ARRAY['creator'::public.user_role]) and (select auth.uid()) = user_id)
);


create policy "Enable delete for admin"
on "public"."spotify_playlists"
as PERMISSIVE
for DELETE
to authenticated
using (
  public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);

create policy "Enable insert for creator and oner"
on "public"."spotify_playlists"
as PERMISSIVE
for insert
to authenticated
with check (
  (public.authorizedAs(ARRAY['creator'::public.user_role]) and (select auth.uid()) = user_id)
);


create policy "Enable insert admin"
on "public"."spotify_playlists"
as PERMISSIVE
for insert
to authenticated
with check (
  public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);


create policy "Enable update creator that owns row"
on "public"."spotify_playlists"
as PERMISSIVE
for UPDATE
to authenticated
using (
  (public.authorizedAs(ARRAY['creator'::public.user_role]) and (select auth.uid()) = user_id)
);

create policy "Enable update for admin"
on "public"."spotify_playlists"
as PERMISSIVE
for UPDATE
to authenticated
using (
  public.authorizedAs(ARRAY['admin'::public.user_role, 'moderator'::public.user_role])
);
