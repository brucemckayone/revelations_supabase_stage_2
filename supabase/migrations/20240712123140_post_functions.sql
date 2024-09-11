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
DECLARE
    v_tag_id UUID;
    v_tag TEXT;
BEGIN
    FOREACH v_tag IN ARRAY p_tags
    LOOP
        -- Try to insert the tag, if it doesn't exist
        INSERT INTO public.tags (name)
        VALUES (v_tag)
        ON CONFLICT (name) DO NOTHING;

        -- Get the tag id
        SELECT id INTO v_tag_id FROM public.tags WHERE name = v_tag;

        -- Associate the tag with the post
        INSERT INTO public.post_tags (post_id, tag_id)
        VALUES (p_post_id, v_tag_id)
        ON CONFLICT (post_id, tag_id) DO NOTHING;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;