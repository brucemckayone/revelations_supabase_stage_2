-- Generated with srtd from template: supabase/migrations-templates/update_get_user_chat_rooms.sql
-- You very likely **DO NOT** want to manually edit this generated file.



-- =============================================================================
-- UPDATE GET_USER_CHAT_ROOMS FUNCTION
-- =============================================================================
-- This migration updates the get_user_chat_rooms function to include the new
-- specialized chat channels fields that were added in the system.


drop function if exists public.get_user_chat_rooms(UUID);
-- Create updated function with new specialized chat fields
CREATE OR REPLACE FUNCTION public.get_user_chat_rooms(p_user_id UUID)
RETURNS TABLE(
    room_id UUID,
    room_name TEXT,
    room_type public.chat_type_enum,
    room_description TEXT,
    is_broadcast BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    latest_message TEXT,
    latest_message_id UUID,
    latest_message_sender UUID,
    latest_message_time TIMESTAMPTZ,
    unread_count BIGINT,
    -- NEW SPECIALIZED CHAT FIELDS
    associated_appointment_id UUID,
    metadata JSONB,
    auto_notifications BOOLEAN,
    pinned_message_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH latest_messages AS (
        SELECT DISTINCT ON (cm.chat_room_id)
            cm.chat_room_id,
            cm.id AS message_id,
            cm.message,
            cm.sender_id,
            cm.created_at,
            cm.status
        FROM public.chat_messages cm
        WHERE cm.status != 'deleted'
          AND cm.superseded_by IS NULL  -- Only show non-superseded messages
        ORDER BY cm.chat_room_id, cm.created_at DESC
    ),
    unread_counts AS (
        SELECT 
            cp.chat_room_id,
            COUNT(cm.id) AS count
        FROM public.chat_participants cp
        JOIN public.chat_messages cm ON cp.chat_room_id = cm.chat_room_id
        LEFT JOIN public.message_read_receipts mrr ON cm.id = mrr.message_id AND mrr.user_id = p_user_id
        WHERE 
            cp.user_id = p_user_id
            AND cp.left_at IS NULL
            AND cm.status != 'deleted'
            AND cm.sender_id != p_user_id
            AND mrr.id IS NULL
        GROUP BY cp.chat_room_id
    )
    SELECT 
        cr.id AS room_id,
        cr.name AS room_name,
        cr.type AS room_type,
        cr.description AS room_description,
        cr.is_broadcast,
        cr.created_at,
        cr.updated_at,
        lm.message AS latest_message,
        lm.message_id AS latest_message_id,
        lm.sender_id AS latest_message_sender,
        lm.created_at AS latest_message_time,
        COALESCE(uc.count, 0) AS unread_count,
        -- NEW SPECIALIZED CHAT FIELDS
        cr.associated_appointment_id,
        cr.metadata,
        cr.auto_notifications,
        cr.pinned_message_id
    FROM public.chat_rooms cr
    JOIN public.chat_participants cp ON cr.id = cp.chat_room_id
    LEFT JOIN latest_messages lm ON cr.id = lm.chat_room_id
    LEFT JOIN unread_counts uc ON cr.id = uc.chat_room_id
    WHERE 
        cp.user_id = p_user_id
        AND cp.left_at IS NULL
    ORDER BY COALESCE(lm.created_at, cr.created_at) DESC;
END;
$$;


drop function if exists public.get_user_chat_rooms();
-- Recreate the convenience function that uses auth.uid()
CREATE OR REPLACE FUNCTION public.get_user_chat_rooms()
RETURNS TABLE(
    room_id UUID,
    room_name TEXT,
    room_type public.chat_type_enum,
    room_description TEXT,
    is_broadcast BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    latest_message TEXT,
    latest_message_id UUID,
    latest_message_sender UUID,
    latest_message_time TIMESTAMPTZ,
    unread_count BIGINT,
    -- NEW SPECIALIZED CHAT FIELDS
    associated_appointment_id UUID,
    metadata JSONB,
    auto_notifications BOOLEAN,
    pinned_message_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY SELECT * FROM public.get_user_chat_rooms(auth.uid());
END;
$$;

-- -- Set ownership
-- ALTER FUNCTION public.get_user_chat_rooms(UUID) OWNER TO postgres;
-- ALTER FUNCTION public.get_user_chat_rooms() OWNER TO postgres;

-- Grant permissions
GRANT ALL ON FUNCTION public.get_user_chat_rooms(UUID) TO anon;
GRANT ALL ON FUNCTION public.get_user_chat_rooms(UUID) TO authenticated;
GRANT ALL ON FUNCTION public.get_user_chat_rooms(UUID) TO service_role;

GRANT ALL ON FUNCTION public.get_user_chat_rooms() TO anon;
GRANT ALL ON FUNCTION public.get_user_chat_rooms() TO authenticated;
GRANT ALL ON FUNCTION public.get_user_chat_rooms() TO service_role;

-- Add function comments
COMMENT ON FUNCTION public.get_user_chat_rooms(UUID) IS 
'Enhanced function to get user chat rooms with specialized chat channel fields including appointment associations, metadata, and auto-notifications.';

COMMENT ON FUNCTION public.get_user_chat_rooms() IS 
'Convenience function that gets chat rooms for the authenticated user with specialized chat channel support.';

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================
-- Summary of changes:
-- 1. Updated get_user_chat_rooms to include new specialized chat fields
-- 2. Added filtering for non-superseded messages in latest_messages CTE
-- 3. Maintained backward compatibility with existing function signature
-- 4. Added proper permissions and documentation 



-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
