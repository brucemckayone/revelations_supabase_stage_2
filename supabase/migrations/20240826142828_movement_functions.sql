

CREATE OR REPLACE FUNCTION get_filtered_movement_content(
    input_post_ids UUID[] DEFAULT NULL,
    post_type_array post_type_enum[] DEFAULT NULL,
    search_title TEXT DEFAULT NULL,
    min_duration INT DEFAULT NULL,
    max_duration INT DEFAULT NULL,
    min_energy_level INT DEFAULT NULL,
    max_energy_level INT DEFAULT NULL,
    min_price NUMERIC DEFAULT NULL,
    max_price NUMERIC DEFAULT NULL,
    tag_array TEXT[] DEFAULT NULL,
    p_limit INT DEFAULT 10,
    p_offset INT DEFAULT 0
) RETURNS TABLE (
    post_id UUID,
    post_type post_type_enum,
    title TEXT,
    slug TEXT,
    description TEXT,
    thumbnail_url TEXT,
    media_type media_type_enum,
    duration INTERVAL,
    price NUMERIC,
    instructor_name VARCHAR(100),
    session_theme VARCHAR(255),
    energy_level INT,
    spiritual_elements TEXT,
    emotional_focus TEXT,
    recommended_environment TEXT,
    body_focus TEXT,
    tags TEXT,
    total_count BIGINT
) AS $$
DECLARE
    min_duration_interval INTERVAL;
    max_duration_interval INTERVAL;
BEGIN
    -- Convert percentage to actual duration intervals
    min_duration_interval := CASE
        WHEN min_duration IS NOT NULL THEN
            INTERVAL '15 minutes' + (INTERVAL '75 minutes' * min_duration / 100)
        ELSE NULL
    END;

    max_duration_interval := CASE
        WHEN max_duration IS NOT NULL THEN
            INTERVAL '15 minutes' + (INTERVAL '75 minutes' * max_duration / 100)
        ELSE NULL
    END;

    RETURN QUERY
    WITH filtered_posts AS (
        SELECT DISTINCT p.id
        FROM posts p
        LEFT JOIN post_tags pt ON p.id = pt.post_id
        LEFT JOIN tags t ON pt.tag_id = t.id
        WHERE (input_post_ids IS NULL OR p.id = ANY(input_post_ids))
        AND (post_type_array IS NULL OR p.post_type = ANY(post_type_array))
        AND (search_title IS NULL OR p.title ILIKE '%' || search_title || '%')
        AND (tag_array IS NULL OR t.name = ANY(tag_array))
    ),
    counted_results AS (
        SELECT 
            p.id AS post_id,
            p.post_type,
            p.title,
            p.slug,
            p.description,
            p.thumbnail_url,
            odm.media_type,
            odm.duration,
            odm.price,
            m.instructor_name,
            m.session_theme,
            m.energy_level,
            m.spiritual_elements,
            m.emotional_focus,
            m.recommended_environment,
            m.body_focus,
            string_agg(t.name, ', ') AS tags,
            COUNT(*) OVER() AS total_count
        FROM 
            filtered_posts fp
        JOIN
            posts p ON fp.id = p.id
        JOIN
            on_demand_media odm ON p.id = odm.post_id
        JOIN
            movements m ON odm.id = m.content_id
        LEFT JOIN
            post_tags pt ON p.id = pt.post_id
        LEFT JOIN
            tags t ON pt.tag_id = t.id
        WHERE 
            (min_duration_interval IS NULL OR odm.duration >= min_duration_interval)
            AND (max_duration_interval IS NULL OR odm.duration <= max_duration_interval)
            AND (min_energy_level IS NULL OR m.energy_level >= min_energy_level)
            AND (max_energy_level IS NULL OR m.energy_level <= max_energy_level)
            AND (min_price IS NULL OR odm.price >= min_price)
            AND (max_price IS NULL OR odm.price <= max_price)
        GROUP BY 
            p.id, odm.id, m.id
        ORDER BY 
            p.created_at DESC
    )
    SELECT 
        cr.post_id,
        cr.post_type,
        cr.title,
        cr.slug,
        cr.description,
        cr.thumbnail_url,
        cr.media_type,
        cr.duration,
        cr.price,
        cr.instructor_name,
        cr.session_theme,
        cr.energy_level,
        cr.spiritual_elements,
        cr.emotional_focus,
        cr.recommended_environment,
        cr.body_focus,
        cr.tags,
        cr.total_count
    FROM counted_results cr
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;