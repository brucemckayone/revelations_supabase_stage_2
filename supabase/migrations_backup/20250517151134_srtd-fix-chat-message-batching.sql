-- Generated with srtd from template: supabase/migrations-templates/fix-chat-message-batching.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Migration template to fix chat notification batching
BEGIN;

-- Fix the create_or_update_batched_chat_notification function 
-- Current version has a logical error where updates to existing notifications never happen
CREATE OR REPLACE FUNCTION public.create_or_update_batched_chat_notification(
    p_user_id UUID,         -- recipient
    p_sender_id UUID,       -- sender
    p_chat_id UUID,         -- chat or conversation ID
    p_message_preview TEXT
) RETURNS UUID AS $$
DECLARE
    existing_notification_id UUID;
    notification_id UUID;
    message_count INTEGER;
    updated_metadata JSONB;
    sender_name TEXT;
BEGIN
    -- Get sender's name
    SELECT full_name INTO sender_name
    FROM profiles
    WHERE id = p_sender_id;
    
    -- Default sender name if not found
    sender_name := COALESCE(sender_name, 'Someone');
    
    -- Check for existing unread notification for this chat
    SELECT n.id
    INTO existing_notification_id
    FROM public.notifications n
    WHERE n.user_id = p_user_id
        AND n.reference_id = p_chat_id
        AND n.type = 'message'::public.notification_type
        AND n.is_read = FALSE;
    
    IF existing_notification_id IS NULL THEN
        -- No existing notification, create a new one
        INSERT INTO public.notifications (
            user_id,
            sender_id,
            title,
            content,
            type,
            reference_id,
            reference_type,
            metadata
        ) VALUES (
            p_user_id,
            p_sender_id,
            sender_name,  -- More descriptive title using sender name
            p_message_preview,
            'message'::public.notification_type,
            p_chat_id,
            'chat',
            jsonb_build_object(
                'chat_id', p_chat_id,
                'message_count', 1,
                'sender_id', p_sender_id,
                'sender_name', sender_name,
                'messages', jsonb_build_array(
                    jsonb_build_object(
                        'text', p_message_preview,
                        'timestamp', now()
                    )
                )
            )
        ) RETURNING id INTO notification_id;
    ELSE
        -- Update existing notification with new message count and content
        SELECT COALESCE((metadata->>'message_count')::int, 1) + 1
        INTO message_count
        FROM public.notifications
        WHERE id = existing_notification_id;
        
        -- Update metadata with new count and add message to array
        WITH notification_data AS (
            SELECT 
                metadata->'messages' as existing_messages,
                metadata
            FROM public.notifications
            WHERE id = existing_notification_id
        )
        SELECT 
            jsonb_set(
                jsonb_set(
                    metadata,
                    '{message_count}',
                    to_jsonb(message_count)
                ),
                '{messages}',
                COALESCE(
                    existing_messages || jsonb_build_array(
                        jsonb_build_object(
                            'text', p_message_preview,
                            'timestamp', now()
                        )
                    ),
                    jsonb_build_array(
                        jsonb_build_object(
                            'text', p_message_preview,
                            'timestamp', now()
                        )
                    )
                )
            )
        INTO updated_metadata
        FROM notification_data;
        
        -- Update the notification with new count and latest message
        UPDATE public.notifications
        SET 
            title = sender_name,
            content = CASE 
                WHEN message_count > 1 THEN message_count || ' new messages from ' || sender_name
                ELSE p_message_preview
            END,
            updated_at = NOW(),
            metadata = updated_metadata
        WHERE id = existing_notification_id;
        
        notification_id := existing_notification_id;
    END IF;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.create_or_update_batched_chat_notification IS 'Creates or updates batched notifications for chat messages to prevent notification spam';

COMMIT; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
