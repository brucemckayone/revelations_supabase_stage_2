
-- Create the dance_details view
CREATE VIEW dance_details AS
SELECT
    md.*,
    d.freeform_movement
FROM 
    movement_details md
JOIN 
    public.dance d ON md.movement_id = d.movement_id;
