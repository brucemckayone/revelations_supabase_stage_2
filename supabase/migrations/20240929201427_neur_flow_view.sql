
-- Create the neuroflow_details view
CREATE VIEW neuroflow_details AS
SELECT
    md.*,
    nf.techniques_used,
    nf.session_focus,
    nf.personal_growth_outcomes
FROM 
    movement_details md
JOIN 
    public.neuroflow nf ON md.movement_id = nf.movement_id;
