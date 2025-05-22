-- Migration template for a comprehensive fix of all notification functions
BEGIN;

-- Fix the process_chat_message_notification function to use correct parameter order
CREATE OR REPLACE FUNCTION public.process_chat_message_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_chat_room RECORD;
  v_participant RECORD;
BEGIN
  -- Get chat room details
  SELECT * INTO v_chat_room
  FROM chat_rooms
  WHERE id = NEW.chat_room_id;
  
  -- Process differently based on chat type
  IF v_chat_room.type = 'private' THEN
    -- For private chats, notify the other participant
    FOR v_participant IN (
      SELECT user_id 
      FROM chat_participants 
      WHERE chat_room_id = NEW.chat_room_id 
      AND user_id <> NEW.sender_id
      AND left_at IS NULL
    ) LOOP
      -- Use the corrected function with the right parameter order
      PERFORM create_or_update_batched_chat_notification(
        v_participant.user_id,  -- recipient user_id
        NEW.sender_id,          -- sender_id
        NEW.chat_room_id,       -- chat_id
        NEW.message             -- message preview
      );
    END LOOP;
  ELSE
    -- For group chats, notify all participants except sender
    FOR v_participant IN (
      SELECT user_id 
      FROM chat_participants 
      WHERE chat_room_id = NEW.chat_room_id 
      AND user_id <> NEW.sender_id
      AND left_at IS NULL
    ) LOOP
      -- Use the corrected function with the right parameter order
      PERFORM create_or_update_batched_chat_notification(
        v_participant.user_id,  -- recipient user_id
        NEW.sender_id,          -- sender_id
        NEW.chat_room_id,       -- chat_id
        NEW.message             -- message preview
      );
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Fix the notify_chat_participant_added function to include sender_id parameter
CREATE OR REPLACE FUNCTION public.notify_chat_participant_added()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_chat_room RECORD;
  v_added_by TEXT;
  v_added_by_id UUID;
BEGIN
  -- Skip if user left (left_at is not null)
  IF NEW.left_at IS NOT NULL THEN
    RETURN NEW;
  END IF;
  
  -- Get chat room details
  SELECT * INTO v_chat_room
  FROM chat_rooms
  WHERE id = NEW.chat_room_id;
  
  -- Get who added the user (the creator of the chat or the admin)
  IF TG_OP = 'INSERT' THEN
    v_added_by_id := v_chat_room.created_by;
  ELSE
    -- For updates (e.g., rejoining a chat), use the current user
    v_added_by_id := auth.uid();
  END IF;
  
  -- Get the name of who added the user
  SELECT full_name INTO v_added_by
  FROM profiles
  WHERE id = v_added_by_id;
  
  v_added_by := COALESCE(v_added_by, 'Someone');
  
  -- Create notification for being added to a chat with the fixed function signature
  IF v_chat_room.type = 'private' THEN
    -- Private chat notification
    PERFORM create_notification(
      NEW.user_id,              -- user_id
      v_added_by_id,            -- sender_id
      'New Chat',               -- title
      v_added_by || ' started a chat with you', -- content
      'message',                -- type
      NULL,                     -- priority (ignored)
      NEW.chat_room_id,         -- related_entity_id/reference_id
      '/chat/' || NEW.chat_room_id, -- action/action_url
      jsonb_build_object(       -- metadata
        'chat_room_id', NEW.chat_room_id,
        'chat_type', v_chat_room.type,
        'added_by', v_added_by_id
      )
    );
  ELSE
    -- Group chat notification
    PERFORM create_notification(
      NEW.user_id,              -- user_id
      v_added_by_id,            -- sender_id
      'Added to ' || v_chat_room.name, -- title
      v_added_by || ' added you to ' || v_chat_room.name, -- content
      'message',                -- type
      NULL,                     -- priority (ignored)
      NEW.chat_room_id,         -- related_entity_id/reference_id
      '/chat/' || NEW.chat_room_id, -- action/action_url
      jsonb_build_object(       -- metadata
        'chat_room_id', NEW.chat_room_id,
        'chat_type', v_chat_room.type,
        'chat_name', v_chat_room.name,
        'added_by', v_added_by_id
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Fix notify_new_follower function to include sender_id
CREATE OR REPLACE FUNCTION public.notify_new_follower()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_follower_name TEXT;
BEGIN
  -- Get follower's name
  SELECT full_name INTO v_follower_name
  FROM profiles
  WHERE id = NEW.follower_id;
  
  -- Create a notification for the user being followed
  PERFORM create_notification(
    NEW.followed_id,           -- user_id
    NEW.follower_id,           -- sender_id
    'New Follower',            -- title
    v_follower_name || ' is now following you', -- content
    'social',                  -- type
    NULL,                      -- priority
    NEW.follower_id,           -- related_entity_id
    '/profile/' || NEW.follower_id, -- action_url
    jsonb_build_object(        -- metadata
      'follower_id', NEW.follower_id,
      'follower_name', v_follower_name
    )
  );
  
  RETURN NEW;
END;
$$;

-- Fix post_comment_notification function to include sender_id
CREATE OR REPLACE FUNCTION public.post_comment_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_post_author_id UUID;
  v_parent_comment_author_id UUID;
  v_commenter_name TEXT;
  v_post_title TEXT;
  v_notification_id UUID;
BEGIN
  -- Get commenter's name
  SELECT full_name INTO v_commenter_name
  FROM profiles
  WHERE id = NEW.user_id;
  
  v_commenter_name := COALESCE(v_commenter_name, 'Someone');
  
  -- If it's a reply to another comment
  IF NEW.parent_id IS NOT NULL THEN
    -- Get the parent comment author ID
    SELECT user_id INTO v_parent_comment_author_id
    FROM comments
    WHERE id = NEW.parent_id;
    
    -- Don't notify if replying to your own comment
    IF v_parent_comment_author_id != NEW.user_id THEN
      -- Notify the parent comment author about the reply
      PERFORM create_notification(
        v_parent_comment_author_id, -- user_id
        NEW.user_id,                -- sender_id
        'New Reply',                -- title
        v_commenter_name || ' replied to your comment', -- content
        'social',                   -- type
        NULL,                       -- priority
        NEW.post_id,                -- related_entity_id
        '/post/' || NEW.post_id || '#comment-' || NEW.id, -- action
        jsonb_build_object(         -- metadata
          'comment_id', NEW.id,
          'post_id', NEW.post_id,
          'parent_comment_id', NEW.parent_id,
          'commenter_id', NEW.user_id,
          'commenter_name', v_commenter_name
        )
      );
    END IF;
  END IF;
  
  -- Also notify the post author about the comment (if not their own post)
  SELECT user_id, title INTO v_post_author_id, v_post_title
  FROM posts
  WHERE id = NEW.post_id;
  
  -- Don't notify if commenting on your own post
  IF v_post_author_id != NEW.user_id THEN
    PERFORM create_notification(
      v_post_author_id,            -- user_id
      NEW.user_id,                 -- sender_id
      'New Comment',               -- title
      v_commenter_name || ' commented on your post: ' || v_post_title, -- content
      'social',                    -- type
      NULL,                        -- priority
      NEW.post_id,                 -- related_entity_id
      '/post/' || NEW.post_id || '#comment-' || NEW.id, -- action
      jsonb_build_object(          -- metadata
        'comment_id', NEW.id,
        'post_id', NEW.post_id,
        'commenter_id', NEW.user_id,
        'commenter_name', v_commenter_name,
        'post_title', v_post_title
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create a compatibility wrapper for the old function signature to avoid breaking existing code
CREATE OR REPLACE FUNCTION public.legacy_create_notification(
  p_user_id UUID,
  p_title TEXT,
  p_content TEXT,
  p_type TEXT,
  p_action_url TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_reference_type TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT NULL
) RETURNS UUID AS $$
BEGIN
  -- Call the new function with auth.uid() as the sender_id
  RETURN create_notification(
    p_user_id,
    auth.uid(),  -- Current user as sender
    p_title,
    p_content,
    p_type,
    NULL,       -- No priority needed
    p_reference_id,
    p_action_url,
    p_metadata
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.legacy_create_notification IS 'Backwards compatibility wrapper for the old create_notification function signature';

COMMIT; 