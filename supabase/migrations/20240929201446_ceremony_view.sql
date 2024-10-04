
-- Create the ceremony_details view
CREATE VIEW ceremony_details AS
SELECT
    odb.*,
    c.ceremony_type,
    c.ceremony_theme,
    c.ceremony_focus,
    c.what_to_bring,
    c.space_holder_names
FROM 
    on_demand_base odb
JOIN 
    public.ceremony c ON odb.on_demand_media_id = c.content_id;
