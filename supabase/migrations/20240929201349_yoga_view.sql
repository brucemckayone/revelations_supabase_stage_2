
-- Create the yoga_details view
CREATE VIEW yoga_details AS
SELECT
    md.*,
    y.yoga_style,
    y.chakras
FROM 
    movement_details md
JOIN 
    public.yoga y ON md.movement_id = y.movement_id;
