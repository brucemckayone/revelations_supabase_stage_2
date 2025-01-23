-- Updated get_comments function
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
    score INTEGER,
    is_edited BOOLEAN,
    depth INTEGER,
    reactions JSON,
    attachments JSON,
    mentions JSON,
    author_name TEXT,
    author_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH comment_data AS (
        SELECT 
            c.*,
            u.username as author_name,
            u.avatar_url as author_avatar,
            (
                SELECT COALESCE(json_agg(
                    json_build_object(
                        'type', cr.reaction_type,
                        'count', COUNT(*),
                        'userReacted', EXISTS(
                            SELECT 1 
                            FROM public.comment_reactions cr2 
                            WHERE cr2.comment_id = c.id 
                            AND cr2.user_id = auth.uid()
                            AND cr2.reaction_type = cr.reaction_type
                        )
                    )
                ), '[]'::json)
                FROM public.comment_reactions cr
                WHERE cr.comment_id = c.id
                GROUP BY cr.reaction_type
            ) as reactions,
            (
                SELECT COALESCE(json_agg(
                    json_build_object(
                        'id', ca.id,
                        'type', ca.type,
                        'url', ca.url,
                        'name', ca.name,
                        'size', ca.size
                    )
                ), '[]'::json)
                FROM public.comment_attachments ca
                WHERE ca.comment_id = c.id
            ) as attachments,
            (
                SELECT COALESCE(json_agg(u2.username), '[]'::json)
                FROM public.comment_mentions cm
                JOIN auth.users u2 ON u2.id = cm.user_id
                WHERE cm.comment_id = c.id
            ) as mentions
        FROM public.comments c
        JOIN auth.users u ON u.id = c.user_id
        WHERE c.post_id = in_post_id 
        AND c.deleted_at IS NULL
    )
    SELECT *
    FROM comment_data
    ORDER BY created_at DESC
    LIMIT in_limit
    OFFSET in_offset;
END;
$$ LANGUAGE plpgsql;

-- Updated leave_comment function
CREATE OR REPLACE FUNCTION leave_comment(
    in_post_id UUID,
    in_comment TEXT,
    in_parent_id BIGINT DEFAULT NULL,
    in_attachments JSON DEFAULT NULL,
    in_mentions JSON DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    new_comment_id BIGINT;
    new_depth INTEGER;
BEGIN
    -- Calculate depth
    IF in_parent_id IS NOT NULL THEN
        SELECT depth + 1 INTO new_depth
        FROM public.comments
        WHERE id = in_parent_id;
    ELSE
        new_depth := 0;
    END IF;

    -- Insert comment
    INSERT INTO public.comments (
        user_id, 
        post_id, 
        comment, 
        parent_id,
        depth
    )
    VALUES (
        auth.uid(), 
        in_post_id, 
        in_comment, 
        in_parent_id,
        new_depth
    )
    RETURNING id INTO new_comment_id;

    -- Insert attachments
    IF in_attachments IS NOT NULL THEN
        INSERT INTO public.comment_attachments (
            comment_id,
            type,
            url,
            name,
            size
        )
        SELECT 
            new_comment_id,
            (value->>'type')::TEXT,
            (value->>'url')::TEXT,
            (value->>'name')::TEXT,
            (value->>'size')::INTEGER
        FROM json_array_elements(in_attachments);
    END IF;

    -- Insert mentions
    IF in_mentions IS NOT NULL THEN
        INSERT INTO public.comment_mentions (
            comment_id,
            user_id
        )
        SELECT 
            new_comment_id,
            (value->>'userId')::UUID
        FROM json_array_elements(in_mentions);
    END IF;

    RETURN new_comment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to toggle reaction
CREATE OR REPLACE FUNCTION toggle_comment_reaction(
    in_comment_id BIGINT,
    in_reaction_type TEXT
) RETURNS VOID AS $$
DECLARE
    existing_reaction_id BIGINT;
BEGIN
    SELECT id INTO existing_reaction_id
    FROM public.comment_reactions
    WHERE comment_id = in_comment_id 
    AND user_id = auth.uid()
    AND reaction_type = in_reaction_type;

    IF existing_reaction_id IS NULL THEN
        INSERT INTO public.comment_reactions (
            comment_id,
            user_id,
            reaction_type
        ) VALUES (
            in_comment_id,
            auth.uid(),
            in_reaction_type
        );
    ELSE
        DELETE FROM public.comment_reactions
        WHERE id = existing_reaction_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to get comment tree
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
    is_edited BOOLEAN,
    depth INTEGER,
    reactions JSON,
    attachments JSON,
    mentions JSON,
    author_name TEXT,
    author_avatar TEXT,
    path BIGINT[]
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE comment_tree AS (
        -- Base case: top-level comments
        SELECT 
            c.*,
            ARRAY[c.id] AS path,
            u.username as author_name,
            u.avatar_url as author_avatar,
            cr.reactions,
            ca.attachments,
            cm.mentions
        FROM public.comments c
        JOIN auth.users u ON u.id = c.user_id
        LEFT JOIN LATERAL (
            SELECT json_agg(
                json_build_object(
                    'type', r.reaction_type,
                    'count', COUNT(*),
                    'userReacted', EXISTS(
                        SELECT 1 FROM public.comment_reactions 
                        WHERE comment_id = c.id 
                        AND user_id = auth.uid()
                        AND reaction_type = r.reaction_type
                    )
                )
            ) as reactions
            FROM public.comment_reactions r
            WHERE r.comment_id = c.id
            GROUP BY r.reaction_type
        ) cr ON true
        LEFT JOIN LATERAL (
            SELECT json_agg(
                json_build_object(
                    'id', a.id,
                    'type', a.type,
                    'url', a.url,
                    'name', a.name,
                    'size', a.size
                )
            ) as attachments
            FROM public.comment_attachments a
            WHERE a.comment_id = c.id
        ) ca ON true
        LEFT JOIN LATERAL (
            SELECT json_agg(u2.username) as mentions
            FROM public.comment_mentions m
            JOIN auth.users u2 ON u2.id = m.user_id
            WHERE m.comment_id = c.id
        ) cm ON true
        WHERE c.post_id = in_post_id 
        AND c.parent_id IS NULL
        AND c.deleted_at IS NULL

        UNION ALL

        -- Recursive case: replies
        SELECT 
            c.*,
            ct.path || c.id,
            u.username,
            u.avatar_url,
            cr.reactions,
            ca.attachments,
            cm.mentions
        FROM public.comments c
        JOIN comment_tree ct ON c.parent_id = ct.id
        JOIN auth.users u ON u.id = c.user_id
        LEFT JOIN LATERAL (
            SELECT json_agg(
                json_build_object(
                    'type', r.reaction_type,
                    'count', COUNT(*),
                    'userReacted', EXISTS(
                        SELECT 1 FROM public.comment_reactions 
                        WHERE comment_id = c.id 
                        AND user_id = auth.uid()
                        AND reaction_type = r.reaction_type
                    )
                )
            ) as reactions
            FROM public.comment_reactions r
            WHERE r.comment_id = c.id
            GROUP BY r.reaction_type
        ) cr ON true
        LEFT JOIN LATERAL (
            SELECT json_agg(
                json_build_object(
                    'id', a.id,
                    'type', a.type,
                    'url', a.url,
                    'name', a.name,
                    'size', a.size
                )
            ) as attachments
            FROM public.comment_attachments a
            WHERE a.comment_id = c.id
        ) ca ON true
        LEFT JOIN LATERAL (
            SELECT json_agg(u2.username) as mentions
            FROM public.comment_mentions m
            JOIN auth.users u2 ON u2.id = m.user_id
            WHERE m.comment_id = c.id
        ) cm ON true
        WHERE c.deleted_at IS NULL
    )
    SELECT *
    FROM comment_tree
    ORDER BY path;
END;
$$ LANGUAGE plpgsql;



-- Simplified random comment generator
CREATE OR REPLACE FUNCTION generate_random_comment()
RETURNS TEXT AS $$
DECLARE
    comments TEXT[] := ARRAY[
        'This was incredibly insightful! Looking forward to more content like this.',
        'Great points made here. I particularly enjoyed the section about %s.',
        'Thanks for sharing this. It really helped me understand %s better.',
        'The explanation of %s was very clear and helpful.',
        'I love how you approached %s. Very unique perspective!',
        'This resonated with me deeply, especially the part about %s.',
        'Fantastic content! The insights about %s were eye-opening.',
        'Really appreciate the detailed breakdown of %s.',
        'This is exactly what I needed to learn more about %s.',
        'Excellent presentation of %s. Well structured and informative.'
    ];
    themes TEXT[] := ARRAY[
        'mindfulness', 'wellness', 'personal growth', 
        'meditation techniques', 'stress management',
        'mental clarity', 'emotional balance', 
        'spiritual development', 'inner peace',
        'holistic health', 'self-discovery', 'mindful living'
    ];
BEGIN
    RETURN format(
        comments[1 + floor(random() * array_length(comments, 1))],
        themes[1 + floor(random() * array_length(themes, 1))]
    );
END;
$$ LANGUAGE plpgsql;


-- Simplified seed comments function
CREATE OR REPLACE FUNCTION seed_comments()
RETURNS void AS $$
DECLARE
    post_record RECORD;
    comment_record RECORD;
    num_comments INTEGER;
    parent_comment_id BIGINT;
    user_ids UUID[];
    max_depth INTEGER := 3;
    current_depth INTEGER;
BEGIN
    -- Get array of user IDs
    SELECT ARRAY_AGG(id) INTO user_ids
    FROM auth.users;

    -- Get all posts
    FOR post_record IN (
        SELECT id AS post_id
        FROM public.posts
    ) LOOP
        -- Generate 3-8 root comments per post
        num_comments := 3 + floor(random() * 6);
        
        -- Create root comments
        FOR i IN 1..num_comments LOOP
            -- Insert root comment
            INSERT INTO public.comments (
                user_id,
                post_id,
                comment,
                created_at,
                depth,
                hasReplies
            ) VALUES (
                user_ids[1 + floor(random() * array_length(user_ids, 1))],
                post_record.post_id,
                generate_random_comment(),
                NOW() - (random() * interval '30 days'),
                0, null
            ) RETURNING id INTO parent_comment_id;

            -- Generate nested replies
            current_depth := 1;
            WHILE current_depth <= max_depth AND random() < 0.7 LOOP
                FOR j IN 1..1 + floor(random() * 3) LOOP
                    INSERT INTO public.comments (
                        user_id,
                        post_id,
                        comment,
                        parent_id,
                        created_at,
                        depth
                    ) VALUES (
                        user_ids[1 + floor(random() * array_length(user_ids, 1))],
                        post_record.post_id,
                        generate_random_comment(),
                        parent_comment_id,
                        NOW() - (random() * interval '30 days'),
                        current_depth
                    );
                END LOOP;
                current_depth := current_depth + 1;
            END LOOP;

            -- Add reactions to this comment thread
            FOR comment_record IN (
                SELECT id FROM comments 
                WHERE post_id = post_record.post_id 
                AND (parent_id = parent_comment_id OR id = parent_comment_id)
            ) LOOP
                -- Add 0-5 reactions per comment
                FOR i IN 1..floor(random() * 6) LOOP
                    INSERT INTO public.comment_reactions (
                        comment_id,
                        user_id,
                        reaction_type
                    ) VALUES (
                        comment_record.id,
                        user_ids[1 + floor(random() * array_length(user_ids, 1))],
                        CASE floor(random() * 5)
                            WHEN 0 THEN 'like'
                            WHEN 1 THEN 'heart'
                            WHEN 2 THEN 'laugh'
                            WHEN 3 THEN 'sad'
                            ELSE 'angry'
                        END
                    ) ON CONFLICT (comment_id, user_id, reaction_type) DO NOTHING;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Update random_timestamp function as well
CREATE OR REPLACE FUNCTION random_timestamp(start_date timestamp, end_date timestamp)
RETURNS timestamp
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    -- Modified permission check
    IF NOT (
        has_function_privilege(current_user, 'random_timestamp(timestamp, timestamp)', 'EXECUTE') OR
        current_user = 'authenticated' OR
        current_user = 'postgres' OR
        current_setting('role') = 'service_role'
    ) THEN
        RAISE EXCEPTION 'Insufficient permissions to generate random timestamp';
    END IF;

    RETURN start_date + random() * (end_date - start_date);
END;
$$ LANGUAGE plpgsql;


-- Entry point function that returns void
CREATE OR REPLACE FUNCTION run_seed_comments()
RETURNS void AS $$
BEGIN
    PERFORM seed_comments();
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
REVOKE ALL ON FUNCTION generate_random_comment() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION generate_random_comment() TO PUBLIC;

REVOKE ALL ON FUNCTION seed_comments() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION seed_comments() TO PUBLIC;

REVOKE ALL ON FUNCTION run_seed_comments() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION run_seed_comments() TO PUBLIC;

-- Enhanced get_comments function aligned with Comment type interface
CREATE OR REPLACE FUNCTION get_smart_comments(
    in_post_id UUID,
    in_limit INTEGER DEFAULT 10,
    in_offset INTEGER DEFAULT 0,
    in_sort_by TEXT DEFAULT 'best',
    in_show_replies BOOLEAN DEFAULT true,
    in_min_score INTEGER DEFAULT -5
) RETURNS TABLE (
    id BIGINT,
    content TEXT,
    author_id UUID,
    author_name TEXT,
    author_avatar TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    parent_id BIGINT,
    reactions JSON,
    is_edited BOOLEAN,
    depth INTEGER,
    deleted_at TIMESTAMP WITH TIME ZONE,
    has_replies BOOLEAN
) AS $$
DECLARE
    reaction_weights JSON := '{"like": 1, "heart": 2, "laugh": 1, "sad": -1, "angry": -2}'::JSON;
BEGIN
    RETURN QUERY
    WITH RECURSIVE comment_base AS (
        -- Base comments query with explicit column references
        SELECT 
            c.id as comment_id,
            c.comment as comment_text,
            c.user_id,
            c.post_id,
            c.parent_id,
            c.created_at as comment_created_at,
            c.updated_at as comment_updated_at,
            c.deleted_at as comment_deleted_at,
            c.is_edited as comment_is_edited,
            c.depth as comment_depth,
            c.hasReplies as comment_has_replies,
            p.full_name as author_name,
            p.avatar_url as author_avatar
        FROM public.comments c
        LEFT JOIN public.profiles p ON c.user_id = p.id
        WHERE 
            c.post_id = in_post_id
            AND (c.deleted_at IS NULL OR c.hasReplies = true)
            AND (in_show_replies OR c.parent_id IS NULL)
            AND (c.parent_id IS NULL OR c.depth <= 3)
    ),
    reaction_counts AS (
        -- Pre-calculate reaction counts and user reactions
        SELECT 
            cr.comment_id,
            cr.reaction_type,
            COUNT(*) as reaction_count,
            bool_or(cr.user_id = auth.uid()) as user_reacted
        FROM public.comment_reactions cr
        WHERE cr.comment_id IN (SELECT cb.comment_id FROM comment_base cb)
        GROUP BY cr.comment_id, cr.reaction_type
    ),
    reaction_scores AS (
        -- Calculate total reaction score
        SELECT 
            rc.comment_id,
            SUM((reaction_weights->>rc.reaction_type)::INTEGER * rc.reaction_count) as reaction_score,
            json_agg(
                json_build_object(
                    'type', rc.reaction_type,
                    'count', rc.reaction_count,
                    'userReacted', rc.user_reacted
                )
            ) as reactions_json
        FROM reaction_counts rc
        GROUP BY rc.comment_id
    ),
    ranked_comments AS (
        -- Combine everything with ranking
        SELECT 
            cb.comment_id,
            CASE 
                WHEN cb.comment_deleted_at IS NOT NULL THEN '[deleted]'
                ELSE cb.comment_text
            END as comment_content,
            cb.user_id as comment_author_id,
            cb.author_name as comment_author_name,
            cb.author_avatar as comment_author_avatar,
            cb.comment_created_at,
            cb.comment_updated_at,
            cb.parent_id as comment_parent_id,
            COALESCE(rs.reactions_json, '[]'::json) as comment_reactions,
            cb.comment_is_edited,
            cb.comment_depth,
            cb.comment_deleted_at,
            cb.comment_has_replies,
            (CASE 
                WHEN cb.comment_deleted_at IS NOT NULL THEN -1000
                ELSE COALESCE(rs.reaction_score, 0)
            END) + 
            (CASE 
                WHEN cb.comment_has_replies THEN 2
                ELSE 0
            END) +
            (CASE 
                WHEN in_sort_by = 'best' THEN 
                    EXTRACT(EPOCH FROM cb.comment_created_at) / 45000
                ELSE 0
            END)::INTEGER as hotness_score
        FROM comment_base cb
        LEFT JOIN reaction_scores rs ON cb.comment_id = rs.comment_id
    )
    SELECT 
        rc.comment_id as id,
        rc.comment_content as content,
        rc.comment_author_id as author_id,
        COALESCE(rc.comment_author_name, 'Anonymous') as author_name,
        rc.comment_author_avatar as author_avatar,
        rc.comment_created_at as created_at,
        rc.comment_updated_at as updated_at,
        rc.comment_parent_id as parent_id,
        rc.comment_reactions as reactions,
        rc.comment_is_edited as is_edited,
        rc.comment_depth as depth,
        rc.comment_deleted_at as deleted_at,
        rc.comment_has_replies as has_replies
    FROM ranked_comments rc
    ORDER BY
        CASE WHEN in_sort_by = 'best' THEN rc.hotness_score END DESC,
        CASE WHEN in_sort_by = 'newest' THEN rc.comment_created_at END DESC,
        CASE WHEN in_sort_by = 'oldest' THEN rc.comment_created_at END ASC
    LIMIT in_limit
    OFFSET in_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;