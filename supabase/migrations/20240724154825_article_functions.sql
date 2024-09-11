-- First, create a composite type for the article content creation result
CREATE TYPE public.article_content_creation_result AS (
    post_id UUID,
    article_id UUID,
    slug TEXT
);

-- Main function to create article content
CREATE OR REPLACE FUNCTION public.create_article_content_with_details(
    p_title TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_content TEXT,
    p_thumbnail_url TEXT,
    p_tags TEXT[],
    p_status publish_status_enum,
    user_id UUID default null
) RETURNS article_content_creation_result AS $$
DECLARE
    v_post_id UUID;
    v_article_id UUID;
    v_result article_content_creation_result;
    v_user_id UUID;
BEGIN
    -- If user_id is not provided, use the authenticated user's ID
    IF user_id IS NULL THEN
        v_user_id := auth.uid();
    ELSE
        v_user_id := user_id;
    END IF;

    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'article'::post_type_enum,
        p_status,
        p_thumbnail_url,
        v_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the article record
    INSERT INTO public.articles (
        post_id,
        content
    ) VALUES (
        v_post_id,
        p_content
    ) RETURNING id INTO v_article_id;

    -- Prepare the result
    v_result := (v_post_id, v_article_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating article content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Function to update article content
CREATE OR REPLACE FUNCTION public.update_article_content_with_details(
    p_post_id UUID,
    p_title TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_content TEXT,
    p_thumbnail_url TEXT,
    p_tags TEXT[],
    p_status publish_status_enum
) RETURNS public.article_content_creation_result AS $$
DECLARE
    v_article_id UUID;
    v_result public.article_content_creation_result;
BEGIN
    -- Update the post
    UPDATE public.posts
    SET title = p_title,
        slug = p_slug,
        description = p_description,
        content = p_content,
        thumbnail_url = p_thumbnail_url,
        status = p_status,
        updated_at = NOW()
    WHERE id = p_post_id;

    -- Update tags
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Update article
    UPDATE public.articles
    SET content = p_content,
        updated_at = NOW()
    WHERE post_id = p_post_id
    RETURNING id INTO v_article_id;

    -- Prepare the result
    v_result := (p_post_id, v_article_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating article content: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;