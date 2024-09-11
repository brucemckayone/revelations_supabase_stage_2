CREATE OR REPLACE FUNCTION get_post_type_tags(post_type post_type_enum)
RETURNS TABLE (
    tag_id UUID,
    tag_name VARCHAR(50)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT t.id AS tag_id, t.name AS tag_name
    FROM public.tags t
    INNER JOIN public.post_tags pt ON t.id = pt.tag_id
    INNER JOIN public.posts p ON pt.post_id = p.id
    WHERE p.post_type = get_post_type_tags.post_type
    GROUP BY t.id, t.name;
END;
$$ LANGUAGE plpgsql;