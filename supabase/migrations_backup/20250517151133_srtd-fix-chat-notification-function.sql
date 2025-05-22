-- Generated with srtd from template: supabase/migrations-templates/fix-chat-notification-function.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Migration template to fix the chat message notification function
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

COMMIT; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
