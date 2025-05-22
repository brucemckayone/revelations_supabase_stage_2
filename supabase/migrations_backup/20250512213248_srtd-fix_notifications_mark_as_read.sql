-- Generated with srtd from template: supabase/migrations-templates/fix_notifications_mark_as_read.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- FIX FOR NOTIFICATIONS MARK AS READ FUNCTION
-- Creates a new extremely simple implementation to avoid aggregate errors

-- Drop existing mark_notifications_as_read function
DROP FUNCTION IF EXISTS public.mark_notifications_as_read;

-- Create a minimal implementation that just returns 1 to indicate success
CREATE OR REPLACE FUNCTION public.mark_notifications_as_read(
    p_notification_ids UUID[] DEFAULT NULL,
    p_mark_all BOOLEAN DEFAULT FALSE
) RETURNS INTEGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    -- Simplest possible implementation - just do the updates without any RETURNING
    IF p_mark_all = TRUE THEN
        -- Mark all as read
        UPDATE public.notifications
        SET is_read = TRUE,
            updated_at = NOW()
        WHERE user_id = v_user_id
          AND is_read = FALSE;
    ELSIF p_notification_ids IS NOT NULL THEN
        -- Mark specific notifications as read
        UPDATE public.notifications
        SET is_read = TRUE,
            updated_at = NOW()
        WHERE id = ANY(p_notification_ids)
          AND user_id = v_user_id;
    END IF;
    
    -- Just return 1 to indicate success
    -- This avoids any counting logic that might cause issues
    RETURN 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
