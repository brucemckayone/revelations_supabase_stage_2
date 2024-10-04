-- Create the base view with post_details joined with on_demand_media and Spotify playlists
CREATE VIEW on_demand_base AS
SELECT
    pd.*,
    odm.id AS on_demand_media_id,
    odm.media_type,
    odm.duration,
    odm.price,
    odm.created_at AS on_demand_created_at,
    odm.updated_at AS on_demand_updated_at,
    COALESCE(sp.playlist_iframes, ARRAY[]::TEXT[]) AS spotify_playlist_iframes,
    COALESCE(sp.playlist_ids, ARRAY[]::UUID[]) AS spotify_playlist_ids
FROM 
    post_details pd
JOIN 
    public.on_demand_media odm ON pd.id = odm.post_id
LEFT JOIN
    (
        SELECT
            spj.content_id,
            ARRAY_AGG(sp.iframe) AS playlist_iframes,
            ARRAY_AGG(sp.id) AS playlist_ids
        FROM
            public.spotify_playlist_join spj
        JOIN
            public.spotify_playlists sp ON spj.playlist_id = sp.id
        GROUP BY
            spj.content_id
    ) sp ON odm.id = sp.content_id;
