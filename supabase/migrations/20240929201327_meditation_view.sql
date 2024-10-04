CREATE VIEW meditation_details AS
SELECT
    odb.*,
    md.meditation_type,
    md.meditation_theme,
    md.meditation_focus,
    md.what_to_bring,
    md.space_holder_names
FROM 
    on_demand_base odb
JOIN 
    public.meditations md ON odb.on_demand_media_id = md.content_id;
