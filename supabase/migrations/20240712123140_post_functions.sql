CREATE OR REPLACE FUNCTION public.create_post(
    p_title TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_content TEXT,
    p_post_type post_type_enum,
    p_status publish_status_enum,
    p_thumbnail_url TEXT,
    p_user_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_post_id UUID;
    v_user_id UUID;
BEGIN
    v_user_id := COALESCE(p_user_id, auth.uid());

    INSERT INTO public.posts (
        user_id, title, slug, description, content, post_type, status, thumbnail_url
    ) VALUES (
        v_user_id, p_title, p_slug, p_description, p_content, p_post_type, p_status, p_thumbnail_url
    ) RETURNING id INTO v_post_id;

    RETURN v_post_id;
END;
$$ LANGUAGE plpgsql SECURITY invoker;

-- Function to add tags to a post
CREATE OR REPLACE FUNCTION public.add_tags_to_post(
    p_post_id UUID,
    p_tags TEXT[]
) RETURNS VOID AS $$
BEGIN
     -- Remove existing tag associations not in the input list
    DELETE FROM public.post_tags
    WHERE post_id = p_post_id
    AND tag_id NOT IN (
        SELECT id FROM public.tags
        WHERE name = ANY(p_tags)
    );

    -- Add new tag associations for tags that don't exist for this post
    INSERT INTO public.post_tags (post_id, tag_id)
    SELECT p_post_id, t.id
    FROM unnest(p_tags) AS tag_name
    JOIN public.tags t ON t.name = tag_name
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.post_tags pt
        WHERE pt.post_id = p_post_id AND pt.tag_id = t.id
    )
    ON CONFLICT (post_id, tag_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;