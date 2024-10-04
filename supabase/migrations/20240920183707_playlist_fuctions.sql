

create or replace function insert_playlist(iframe text)
returns void as $$
begin
    insert into public.spotify_playlist_join (user_id, iframe) values (auth.uid(), in_iframe);
end;
$$ language plpgsql;

create or replace function delete_playlist(user_id uuid, iframe text)
returns void as $$
begin
    delete from public.spotify_playlist_join where user_id = user_id and iframe = iframe;
end;
$$ language plpgsql;

