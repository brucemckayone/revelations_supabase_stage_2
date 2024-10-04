
-- Create the movement_details view
CREATE VIEW movement_details AS
SELECT
    odb.*,
    m.id AS movement_id,
    m.instructor_name,
    m.session_theme,
    m.energy_level,
    m.spiritual_elements,
    m.emotional_focus,
    m.recommended_environment,
    m.body_focus,
    m.created_at AS movement_created_at,
    m.updated_at AS movement_updated_at
FROM 
    on_demand_base odb
JOIN 
    public.movements m ON odb.on_demand_media_id = m.content_id;
