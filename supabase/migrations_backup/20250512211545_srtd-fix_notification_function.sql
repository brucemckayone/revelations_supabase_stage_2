-- Generated with srtd from template: supabase/migrations-templates/fix_notification_function.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- FIX FOR NOTIFICATION TYPE CASTING
-- Fixes the create_notification function by casting text values to notification_type enum

-- Drop existing notification functions to recreate them with proper types
DROP FUNCTION IF EXISTS public.create_notification;
DROP FUNCTION IF EXISTS public.create_notifications_batch;
DROP FUNCTION IF EXISTS public.create_or_update_batched_chat_notification;
DROP FUNCTION IF EXISTS public.update_notification_preferences;
DROP FUNCTION IF EXISTS public.mark_notifications_as_read;

-- Add sender_id column to notifications table
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS sender_id UUID REFERENCES auth.users(id);
COMMENT ON COLUMN public.notifications.sender_id IS 'The user who sent the notification';

-- Create index for faster querying of sent notifications
CREATE INDEX IF NOT EXISTS notifications_sender_id_idx ON public.notifications(sender_id);

-- Fix the create_notification function with proper type casting and sender_id
CREATE OR REPLACE FUNCTION public.create_notification(
    p_user_id UUID,
    p_sender_id UUID,
    p_title TEXT,
    p_content TEXT,
    p_type TEXT, -- Keep as TEXT for easier API use
    p_priority TEXT DEFAULT 'medium', -- Ignored (not in table schema)
    p_related_entity_id UUID DEFAULT NULL,
    p_action TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO public.notifications (
        user_id,
        sender_id,
        title,
        content,
        type,
        reference_id, -- use reference_id instead of related_entity_id
        action_url, -- use action_url instead of action
        metadata
    ) VALUES (
        p_user_id,
        p_sender_id,
        p_title,
        p_content,
        p_type::public.notification_type, -- Explicitly cast to enum type
        p_related_entity_id, -- renamed to reference_id
        p_action, -- renamed to action_url
        COALESCE(p_metadata, '{}'::jsonb)
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix the create_notifications_batch function with proper type casting and sender_id
CREATE OR REPLACE FUNCTION public.create_notifications_batch(
    p_user_ids UUID[],
    p_sender_id UUID,
    p_title TEXT,
    p_content TEXT,
    p_type TEXT, -- Keep as TEXT for easier API use
    p_priority TEXT DEFAULT 'medium', -- Ignored (not in table schema)
    p_related_entity_id UUID DEFAULT NULL,
    p_action TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
) RETURNS SETOF UUID AS $$
DECLARE
    user_id_in_loop UUID;
    notification_id UUID;
BEGIN
    FOREACH user_id_in_loop IN ARRAY p_user_ids LOOP
        -- Insert directly to avoid multiple auth.uid() calls and ensure consistent sender
        INSERT INTO public.notifications (
            user_id,
            sender_id,
            title,
            content,
            type,
            reference_id,
            action_url,
            metadata
        ) VALUES (
            user_id_in_loop,
            p_sender_id,
            p_title,
            p_content,
            p_type::public.notification_type,
            p_related_entity_id,
            p_action,
            COALESCE(p_metadata, '{}'::jsonb)
        ) RETURNING id INTO notification_id;
        
        RETURN NEXT notification_id;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add the create_or_update_batched_chat_notification function with sender_id
CREATE OR REPLACE FUNCTION public.create_or_update_batched_chat_notification(
    p_user_id UUID, -- recipient
    p_sender_id UUID, -- sender
    p_chat_id UUID, -- chat or conversation ID
    p_message_preview TEXT
) RETURNS UUID AS $$
DECLARE
    existing_notification_id UUID;
    notification_id UUID;
    message_count INTEGER;
    updated_metadata JSONB;
BEGIN
    -- Check for existing unread notification for this chat
    SELECT n.id
    INTO existing_notification_id
    FROM public.notifications n
    WHERE n.user_id = p_user_id
        AND n.reference_id = p_chat_id
        AND n.type = 'message'::public.notification_type
        AND n.is_read = FALSE;
    
    IF existing_notification_id IS NULL THEN
        -- Create new notification with sender tracking
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
            p_sender_id, -- Include sender ID
            'New message',
            p_message_preview,
            'message'::public.notification_type,
            p_chat_id,
            'chat',
            jsonb_build_object(
                'chat_id', p_chat_id,
                'message_count', 1,
                'sender_id', p_sender_id
            )
        ) RETURNING id INTO notification_id;
    ELSE
        -- Update existing notification
        SELECT (metadata->>'message_count')::int + 1
        INTO message_count
        FROM public.notifications
        WHERE id = existing_notification_id;
        
        -- Update metadata with new count
        updated_metadata := jsonb_build_object(
            'chat_id', p_chat_id,
            'message_count', message_count,
            'sender_id', p_sender_id
        );
        
        UPDATE public.notifications
        SET 
            content = CASE 
                WHEN message_count > 1 THEN message_count || ' new messages'
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

-- Add the update_notification_preferences function
CREATE OR REPLACE FUNCTION public.update_notification_preferences(
    p_type TEXT,
    p_in_app BOOLEAN DEFAULT NULL,
    p_email BOOLEAN DEFAULT NULL,
    p_push BOOLEAN DEFAULT NULL,
    p_sms BOOLEAN DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    -- Insert or update preferences
    INSERT INTO public.notification_preferences (
        user_id,
        type,
        in_app,
        email,
        push,
        sms
    ) VALUES (
        auth.uid(),
        p_type,
        COALESCE(p_in_app, TRUE),
        COALESCE(p_email, TRUE),
        COALESCE(p_push, TRUE),
        COALESCE(p_sms, FALSE)
    )
    ON CONFLICT (user_id, type) DO UPDATE SET
        in_app = COALESCE(p_in_app, notification_preferences.in_app),
        email = COALESCE(p_email, notification_preferences.email),
        push = COALESCE(p_push, notification_preferences.push),
        sms = COALESCE(p_sms, notification_preferences.sms),
        updated_at = NOW();
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add the mark_notifications_as_read function
CREATE OR REPLACE FUNCTION public.mark_notifications_as_read(
    p_notification_ids UUID[] DEFAULT NULL,
    p_mark_all BOOLEAN DEFAULT FALSE
) RETURNS BOOLEAN AS $$
BEGIN
    IF p_mark_all THEN
        -- Mark all notifications as read
        UPDATE public.notifications
        SET is_read = TRUE, updated_at = NOW()
        WHERE user_id = auth.uid() AND is_read = FALSE;
    ELSIF p_notification_ids IS NOT NULL THEN
        -- Mark specific notifications as read
        UPDATE public.notifications
        SET is_read = TRUE, updated_at = NOW()
        WHERE id = ANY(p_notification_ids) AND user_id = auth.uid();
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create view for sent notifications
CREATE OR REPLACE VIEW public.creator_sent_notifications AS
SELECT 
    n.id,
    n.sender_id,
    n.title,
    n.content,
    n.type,
    n.reference_id,
    n.reference_type,
    n.created_at,
    COUNT(DISTINCT n.user_id) AS total_recipients,
    SUM(CASE WHEN n.is_read THEN 1 ELSE 0 END) AS read_count,
    jsonb_agg(DISTINCT jsonb_build_object(
        'user_id', n.user_id,
        'is_read', n.is_read
    )) AS recipients
FROM 
    public.notifications n
WHERE 
    n.sender_id IS NOT NULL
GROUP BY 
    n.id, n.sender_id, n.title, n.content, n.type, n.reference_id, n.reference_type, n.created_at
ORDER BY 
    n.created_at DESC;

COMMENT ON VIEW public.creator_sent_notifications IS 'View for creators to see notifications they have sent';

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
