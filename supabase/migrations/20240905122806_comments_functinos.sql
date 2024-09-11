
-- Function to leave a comment
CREATE OR REPLACE FUNCTION leave_comment(
    in_post_id UUID,
    in_comment TEXT,
    in_parent_id BIGINT DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    new_comment_id BIGINT;
BEGIN
    INSERT INTO public.comments (user_id, post_id, comment, parent_id)
    VALUES (auth.uid(), in_post_id, in_comment, in_parent_id)
    RETURNING id INTO new_comment_id;

    RETURN new_comment_id;
END;
$$ LANGUAGE plpgsql;


-- Function to get comments for a post
CREATE OR REPLACE FUNCTION get_comments(
    in_post_id UUID,
    in_limit INTEGER DEFAULT 5,
    in_offset INTEGER DEFAULT 0
) RETURNS TABLE (
    id BIGINT,
    user_id UUID,
    post_id UUID,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    parent_id BIGINT,
    score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        comments.id,
        comments.user_id,
        comments.post_id,
        comments.comment,
        comments.created_at,
        comments.updated_at,
        comments.deleted_at,
        comments.parent_id,
        comments.score
    FROM public.comments
    WHERE comments.post_id = in_post_id AND comments.deleted_at IS NULL
    ORDER BY comments.created_at DESC
    LIMIT in_limit
    OFFSET in_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to upvote a comment
CREATE OR REPLACE FUNCTION upvote_comment(
    in_comment_id BIGINT
) RETURNS void AS $$
BEGIN
    UPDATE public.comments
    SET score = score + 1
    WHERE id = in_comment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to downvote a comment
CREATE OR REPLACE FUNCTION downvote_comment(
    in_comment_id BIGINT
) RETURNS void AS $$
BEGIN
    UPDATE public.comments
    SET score = score - 1
    WHERE id = in_comment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to soft delete a comment
CREATE OR REPLACE FUNCTION delete_comment(
    in_comment_id BIGINT
) RETURNS void AS $$
BEGIN
    UPDATE public.comments
    SET deleted_at = NOW()
    WHERE id = in_comment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get replies for a comment
CREATE OR REPLACE FUNCTION get_comment_replies(
    in_comment_id BIGINT
) RETURNS TABLE (
    id BIGINT,
    user_id UUID,
    post_id UUID,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    parent_id BIGINT,
    score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.comments
    WHERE parent_id = in_comment_id AND deleted_at IS NULL
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get the depth of a comment thread
CREATE OR REPLACE FUNCTION get_thread_depth(
    in_comment_id BIGINT
) RETURNS INTEGER AS $$
DECLARE
    depth INTEGER := 0;
    current_id BIGINT := in_comment_id;
BEGIN
    WHILE current_id IS NOT NULL LOOP
        depth := depth + 1;
        SELECT parent_id INTO current_id
        FROM public.comments
        WHERE id = current_id;
    END LOOP;

    RETURN depth;
END;
$$ LANGUAGE plpgsql;

-- New function to get the full comment tree for a post
CREATE OR REPLACE FUNCTION get_comment_tree(
    in_post_id UUID
) RETURNS TABLE (
    id BIGINT,
    user_id UUID,
    post_id UUID,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    parent_id BIGINT,
    score INTEGER,
    depth INTEGER,
    path BIGINT[]
) AS $$
WITH RECURSIVE comment_tree AS (
    -- Base case: top-level comments
    SELECT 
        c.*,
        0 AS depth,
        ARRAY[c.id] AS path
    FROM 
        public.comments c
    WHERE 
        c.post_id = in_post_id 
        AND c.parent_id IS NULL
        AND c.deleted_at IS NULL

    UNION ALL

    -- Recursive case: replies
    SELECT 
        c.*,
        ct.depth + 1,
        ct.path || c.id
    FROM 
        public.comments c
    JOIN 
        comment_tree ct ON c.parent_id = ct.id
    WHERE 
        c.deleted_at IS NULL
)
SELECT * FROM comment_tree
ORDER BY path;
$$ LANGUAGE SQL;

-- Function to get replies for a specific comment (including nested replies)
CREATE OR REPLACE FUNCTION get_comment_replies_tree(
    in_comment_id BIGINT
) RETURNS TABLE (
    id BIGINT,
    user_id UUID,
    post_id UUID,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    parent_id BIGINT,
    score INTEGER,
    depth INTEGER,
    path BIGINT[]
) AS $$
WITH RECURSIVE reply_tree AS (
    -- Base case: direct replies to the given comment
    SELECT 
        c.*,
        0 AS depth,
        ARRAY[c.id] AS path
    FROM 
        public.comments c
    WHERE 
        c.parent_id = in_comment_id
        AND c.deleted_at IS NULL

    UNION ALL

    -- Recursive case: replies to replies
    SELECT 
        c.*,
        rt.depth + 1,
        rt.path || c.id
    FROM 
        public.comments c
    JOIN 
        reply_tree rt ON c.parent_id = rt.id
    WHERE 
        c.deleted_at IS NULL
)
SELECT * FROM reply_tree
ORDER BY path;
$$ LANGUAGE SQL;



