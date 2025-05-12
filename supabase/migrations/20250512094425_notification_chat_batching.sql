-- filename: supabase/migrations/20250512094425_notification_chat_batching.sql

-- Function to create or update batched chat notifications
CREATE OR REPLACE FUNCTION create_or_update_batched_chat_notification(
  p_chat_room_id UUID,
  p_sender_id UUID,
  p_recipient_id UUID,
  p_message TEXT,
  p_chat_name TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
  v_existing_notification UUID;
  v_batch_window INTERVAL = INTERVAL '15 minutes';
  v_message_batch JSONB;
  v_sender_name TEXT;
  v_chat_room_name TEXT;
  v_title TEXT;
  v_content TEXT;
  v_action_url TEXT;
BEGIN
  -- Skip self-notifications (don't notify sender about their own messages)
  IF p_sender_id = p_recipient_id THEN
    RETURN NULL;
  END IF;
  
  -- Get sender's name
  SELECT full_name INTO v_sender_name
  FROM profiles
  WHERE id = p_sender_id;
  
  -- Default sender name if not found
  v_sender_name := COALESCE(v_sender_name, 'Someone');
  
  -- Get or use provided chat room name
  IF p_chat_name IS NULL THEN
    SELECT name INTO v_chat_room_name
    FROM chat_rooms
    WHERE id = p_chat_room_id;
  ELSE
    v_chat_room_name := p_chat_name;
  END IF;
  
  -- Default chat name if not found
  v_chat_room_name := COALESCE(v_chat_room_name, 'Chat');
  
  -- Check for existing notification to batch with
  SELECT n.id, n.metadata->'messages' INTO v_existing_notification, v_message_batch
  FROM notifications n
  WHERE n.user_id = p_recipient_id
    AND n.type = 'message'
    AND n.reference_id = p_chat_room_id
    AND n.reference_type = 'chat_room'
    AND n.created_at > (NOW() - v_batch_window)
    AND n.is_read = FALSE
  ORDER BY n.created_at DESC
  LIMIT 1;
  
  -- Set action URL to the chat
  v_action_url := '/chat/' || p_chat_room_id;
  
  -- If we found an existing notification to batch with
  IF v_existing_notification IS NOT NULL THEN
    -- Add the new message to the batch
    IF v_message_batch IS NULL THEN
      v_message_batch := jsonb_build_array(
        jsonb_build_object(
          'sender_id', p_sender_id,
          'sender_name', v_sender_name,
          'message', p_message,
          'timestamp', NOW()
        )
      );
    ELSE
      v_message_batch := v_message_batch || jsonb_build_object(
        'sender_id', p_sender_id,
        'sender_name', v_sender_name,
        'message', p_message,
        'timestamp', NOW()
      );
    END IF;
    
    -- Count total messages
    v_title := v_chat_room_name;
    
    -- Create summary content based on message count
    IF jsonb_array_length(v_message_batch) = 1 THEN
      v_content := v_sender_name || ': ' || p_message;
    ELSE
      v_content := jsonb_array_length(v_message_batch)::TEXT || ' new messages in ' || v_chat_room_name;
    END IF;
    
    -- Update the existing notification
    UPDATE notifications
    SET 
      title = v_title,
      content = v_content,
      metadata = jsonb_set(
        metadata, 
        '{messages}', 
        v_message_batch
      ),
      updated_at = NOW()
    WHERE id = v_existing_notification;
    
    v_notification_id := v_existing_notification;
  ELSE
    -- Create a new notification
    v_title := v_chat_room_name;
    v_content := v_sender_name || ': ' || p_message;
    
    -- Initial message batch
    v_message_batch := jsonb_build_array(
      jsonb_build_object(
        'sender_id', p_sender_id,
        'sender_name', v_sender_name,
        'message', p_message,
        'timestamp', NOW()
      )
    );
    
    -- Create the notification
    v_notification_id := create_notification(
      p_recipient_id,
      v_title,
      v_content,
      'message',
      v_action_url,
      p_chat_room_id,
      'chat_room',
      jsonb_build_object(
        'chat_room_id', p_chat_room_id,
        'chat_name', v_chat_room_name,
        'messages', v_message_batch,
        'message_count', 1
      )
    );
  END IF;
  
  RETURN v_notification_id;
END;
$$;

COMMENT ON FUNCTION create_or_update_batched_chat_notification IS 'Creates or updates batched notifications for chat messages';

-- Trigger function for chat message notifications
CREATE OR REPLACE FUNCTION process_chat_message_notification()
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
      -- Create or update batched notification
      PERFORM create_or_update_batched_chat_notification(
        NEW.chat_room_id,
        NEW.sender_id,
        v_participant.user_id,
        NEW.message
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
      -- Create or update batched notification with chat name
      PERFORM create_or_update_batched_chat_notification(
        NEW.chat_room_id,
        NEW.sender_id,
        v_participant.user_id,
        NEW.message,
        v_chat_room.name
      );
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION process_chat_message_notification IS 'Generates batched notifications for new chat messages';

-- Create chat message trigger
DROP TRIGGER IF EXISTS chat_message_notification_trigger ON chat_messages;
CREATE TRIGGER chat_message_notification_trigger
AFTER INSERT ON chat_messages
FOR EACH ROW
EXECUTE FUNCTION process_chat_message_notification();

-- Function to notify when a user is added to a chat
CREATE OR REPLACE FUNCTION notify_chat_participant_added()
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
  
  -- Create notification for being added to a chat
  IF v_chat_room.type = 'private' THEN
    -- Private chat notification
    PERFORM create_notification(
      NEW.user_id,
      'New Chat',
      v_added_by || ' started a chat with you',
      'message',
      '/chat/' || NEW.chat_room_id,
      NEW.chat_room_id,
      'chat_added',
      jsonb_build_object(
        'chat_room_id', NEW.chat_room_id,
        'chat_type', v_chat_room.type,
        'added_by', v_added_by_id
      )
    );
  ELSE
    -- Group chat notification
    PERFORM create_notification(
      NEW.user_id,
      'Added to ' || v_chat_room.name,
      v_added_by || ' added you to ' || v_chat_room.name,
      'message',
      '/chat/' || NEW.chat_room_id,
      NEW.chat_room_id,
      'chat_added',
      jsonb_build_object(
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

COMMENT ON FUNCTION notify_chat_participant_added IS 'Creates a notification when a user is added to a chat';

-- Create trigger for new chat participants
DROP TRIGGER IF EXISTS chat_participant_added_trigger ON chat_participants;
CREATE TRIGGER chat_participant_added_trigger
AFTER INSERT ON chat_participants
FOR EACH ROW
EXECUTE FUNCTION notify_chat_participant_added();