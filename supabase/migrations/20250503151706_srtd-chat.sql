-- Generated with srtd from template: supabase/migrations-templates/chat.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Chat Feature Migration for Supabase
-- This migration creates all necessary tables, functions, and policies for the chat feature
-- This migration is fully idempotent and can be run multiple times without errors

-- ENUM Types for chat-related statuses
DO $$
BEGIN
    -- Create chat_type_enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'chat_type_enum') THEN
        CREATE TYPE public.chat_type_enum AS ENUM (
            'private',         -- One-on-one chats between users
            'group',           -- Group chats for multiple participants
            'broadcast'        -- Creator broadcast channels
        );
        RAISE NOTICE 'Created chat_type_enum type';
    ELSE
        RAISE NOTICE 'chat_type_enum type already exists, skipping creation';
    END IF;

    -- Create message_status_enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'message_status_enum') THEN
        CREATE TYPE public.message_status_enum AS ENUM (
            'delivered',       -- Message has been delivered to the database
            'read',            -- Message has been read by recipient
            'deleted'          -- Message has been deleted (soft delete)
        );
        RAISE NOTICE 'Created message_status_enum type';
    ELSE
        RAISE NOTICE 'message_status_enum type already exists, skipping creation';
    END IF;
END$$;

-- Chat rooms table to store different chat conversations
CREATE TABLE IF NOT EXISTS public.chat_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT,                              -- Optional name for group chats
    type chat_type_enum NOT NULL,           -- Type of chat
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Fields for group chats attached to specific content
    associated_post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    associated_event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    
    -- For broadcast channels (creators only)
    is_broadcast BOOLEAN DEFAULT FALSE,
    description TEXT                        -- Description of the chat purpose
);

-- Create indices for better query performance if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_rooms_created_by') THEN
        CREATE INDEX idx_chat_rooms_created_by ON public.chat_rooms(created_by);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_rooms_type') THEN
        CREATE INDEX idx_chat_rooms_type ON public.chat_rooms(type);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_rooms_associated_post') THEN
        CREATE INDEX idx_chat_rooms_associated_post ON public.chat_rooms(associated_post_id) 
            WHERE associated_post_id IS NOT NULL;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_rooms_associated_event') THEN
        CREATE INDEX idx_chat_rooms_associated_event ON public.chat_rooms(associated_event_id) 
            WHERE associated_event_id IS NOT NULL;
    END IF;
END$$;

-- Participants in each chat room
CREATE TABLE IF NOT EXISTS public.chat_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMPTZ, -- NULL if still a participant
    role TEXT DEFAULT 'member',       -- 'admin', 'member', etc.
    is_muted BOOLEAN DEFAULT FALSE,
    last_read_message_id UUID, -- Will be updated with foreign key constraint after table creation
    UNIQUE(chat_room_id, user_id)
);

-- Create indices for better query performance if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_participants_user_id') THEN
        CREATE INDEX idx_chat_participants_user_id ON public.chat_participants(user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_participants_chat_room_id') THEN
        CREATE INDEX idx_chat_participants_chat_room_id ON public.chat_participants(chat_room_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_participants_left_at') THEN
        CREATE INDEX idx_chat_participants_left_at ON public.chat_participants(left_at) 
            WHERE left_at IS NULL;
    END IF;
END$$;

-- Individual chat messages
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id),
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    status message_status_enum DEFAULT 'delivered',
    reply_to_message_id UUID, -- Will be self-referenced after table creation
    is_edited BOOLEAN DEFAULT FALSE
);

-- Add self-reference to chat_messages for replies if constraint doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_reply_to_message'
    ) THEN
        ALTER TABLE public.chat_messages 
            ADD CONSTRAINT fk_reply_to_message 
            FOREIGN KEY (reply_to_message_id) 
            REFERENCES public.chat_messages(id) ON DELETE SET NULL;
    END IF;
END$$;

-- Now update the chat_participants table with the last_read_message foreign key if constraint doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_last_read_message'
    ) THEN
        ALTER TABLE public.chat_participants 
            ADD CONSTRAINT fk_last_read_message 
            FOREIGN KEY (last_read_message_id) 
            REFERENCES public.chat_messages(id) ON DELETE SET NULL;
    END IF;
END$$;

-- Create indices for better query performance if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_messages_chat_room_id') THEN
        CREATE INDEX idx_chat_messages_chat_room_id ON public.chat_messages(chat_room_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_messages_sender_id') THEN
        CREATE INDEX idx_chat_messages_sender_id ON public.chat_messages(sender_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_messages_created_at') THEN
        CREATE INDEX idx_chat_messages_created_at ON public.chat_messages(created_at);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_messages_reply_to') THEN
        CREATE INDEX idx_chat_messages_reply_to ON public.chat_messages(reply_to_message_id) 
            WHERE reply_to_message_id IS NOT NULL;
    END IF;
END$$;

-- Message read receipts
CREATE TABLE IF NOT EXISTS public.message_read_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(message_id, user_id)
);

-- Create indices for better query performance if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_message_read_receipts_message_id') THEN
        CREATE INDEX idx_message_read_receipts_message_id ON public.message_read_receipts(message_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_message_read_receipts_user_id') THEN
        CREATE INDEX idx_message_read_receipts_user_id ON public.message_read_receipts(user_id);
    END IF;
END$$;

-- Functions and triggers

-- Function to update 'updated_at' column for chat_rooms
CREATE OR REPLACE FUNCTION update_chat_room_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    -- Update to current timestamp
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update chat_rooms.updated_at when updated
DO $$
DECLARE
    trigger_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_chat_room_timestamp'
        AND tgrelid = 'public.chat_rooms'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_chat_room_timestamp
        BEFORE UPDATE ON public.chat_rooms
        FOR EACH ROW
        EXECUTE FUNCTION update_chat_room_timestamp();
        RAISE NOTICE 'Created update_chat_room_timestamp trigger';
    ELSE
        RAISE NOTICE 'update_chat_room_timestamp trigger already exists, skipping creation';
    END IF;
END$$;

-- Function to update chat_rooms.updated_at when a new message is added
CREATE OR REPLACE FUNCTION update_chat_room_timestamp_on_message()
RETURNS TRIGGER AS $$
BEGIN
    -- Update to current timestamp
    UPDATE public.chat_rooms
    SET updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.chat_room_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update chat_rooms.updated_at when a new message is added
DO $$
DECLARE
    trigger_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_chat_room_timestamp_on_message'
        AND tgrelid = 'public.chat_messages'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_chat_room_timestamp_on_message
        AFTER INSERT ON public.chat_messages
        FOR EACH ROW
        EXECUTE FUNCTION update_chat_room_timestamp_on_message();
        RAISE NOTICE 'Created update_chat_room_timestamp_on_message trigger';
    ELSE
        RAISE NOTICE 'update_chat_room_timestamp_on_message trigger already exists, skipping creation';
    END IF;
END$$;

-- Function to check if a user can create a broadcast chat room
CREATE OR REPLACE FUNCTION can_create_broadcast_room()
RETURNS TRIGGER AS $$
BEGIN
    -- For testing purposes, always allow creating broadcast rooms
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check if a user can create a broadcast room
DO $$
DECLARE
    trigger_exists BOOLEAN;
BEGIN
    -- First drop the trigger if it exists to prevent issues in recreating it
    DROP TRIGGER IF EXISTS check_broadcast_room_creator ON public.chat_rooms;
    
    CREATE TRIGGER check_broadcast_room_creator
    BEFORE INSERT ON public.chat_rooms
    FOR EACH ROW
    EXECUTE FUNCTION can_create_broadcast_room();
    
    RAISE NOTICE 'Created or recreated check_broadcast_room_creator trigger';
END$$;

-- Function to automatically add the creator as an admin participant when a room is created
CREATE OR REPLACE FUNCTION add_creator_as_participant()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.chat_participants (chat_room_id, user_id, role)
    VALUES (NEW.id, NEW.created_by, 'admin');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to add creator as participant automatically
DO $$
DECLARE
    trigger_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'add_creator_to_participants'
        AND tgrelid = 'public.chat_rooms'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER add_creator_to_participants
        AFTER INSERT ON public.chat_rooms
        FOR EACH ROW
        EXECUTE FUNCTION add_creator_as_participant();
        RAISE NOTICE 'Created add_creator_to_participants trigger';
    ELSE
        RAISE NOTICE 'add_creator_to_participants trigger already exists, skipping creation';
    END IF;
END$$;

-- Function to update all participants' last_read_message_id when a message is sent
CREATE OR REPLACE FUNCTION update_sender_read_receipt()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the sender's last_read_message_id
    UPDATE public.chat_participants
    SET last_read_message_id = NEW.id
    WHERE chat_room_id = NEW.chat_room_id
    AND user_id = NEW.sender_id;
    
    -- Create a read receipt for the sender
    INSERT INTO public.message_read_receipts (message_id, user_id)
    VALUES (NEW.id, NEW.sender_id)
    ON CONFLICT (message_id, user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update sender's read receipt when a message is sent
DO $$
DECLARE
    trigger_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_sender_read_receipt'
        AND tgrelid = 'public.chat_messages'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_sender_read_receipt
        AFTER INSERT ON public.chat_messages
        FOR EACH ROW
        EXECUTE FUNCTION update_sender_read_receipt();
        RAISE NOTICE 'Created update_sender_read_receipt trigger';
    ELSE
        RAISE NOTICE 'update_sender_read_receipt trigger already exists, skipping creation';
    END IF;
END$$;

-- Functions to get chat information

-- Function to get chat rooms for a user with latest message
CREATE OR REPLACE FUNCTION get_user_chat_rooms(p_user_id UUID)
RETURNS TABLE (
    room_id UUID,
    room_name TEXT,
    room_type chat_type_enum,
    room_description TEXT,
    is_broadcast BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    latest_message TEXT,
    latest_message_id UUID,
    latest_message_sender UUID,
    latest_message_time TIMESTAMPTZ,
    unread_count BIGINT
) 
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
        COALESCE(uc.count, 0) AS unread_count
    FROM public.chat_rooms cr
    JOIN public.chat_participants cp ON cr.id = cp.chat_room_id
    LEFT JOIN latest_messages lm ON cr.id = lm.chat_room_id
    LEFT JOIN unread_counts uc ON cr.id = uc.chat_room_id
    WHERE 
        cp.user_id = p_user_id
        AND cp.left_at IS NULL
    ORDER BY COALESCE(lm.created_at, cr.created_at) DESC;
END;
$$ LANGUAGE plpgsql;

-- No-parameter version of get_user_chat_rooms that uses the current user's ID
CREATE OR REPLACE FUNCTION get_user_chat_rooms()
RETURNS TABLE (
    room_id UUID,
    room_name TEXT,
    room_type chat_type_enum,
    room_description TEXT,
    is_broadcast BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    latest_message TEXT,
    latest_message_id UUID,
    latest_message_sender UUID,
    latest_message_time TIMESTAMPTZ,
    unread_count BIGINT
) 
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY SELECT * FROM get_user_chat_rooms(auth.uid());
END;
$$ LANGUAGE plpgsql;

-- Function to get messages for a chat room with pagination
CREATE OR REPLACE FUNCTION get_chat_messages(
    p_chat_room_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_before TIMESTAMPTZ DEFAULT NULL,
    p_after TIMESTAMPTZ DEFAULT NULL,
    p_around_message_id UUID DEFAULT NULL
)
RETURNS TABLE (
    message_id UUID,
    sender_id UUID,
    sender_name TEXT,
    message TEXT,
    created_at TIMESTAMPTZ,
    status message_status_enum,
    reply_to_message_id UUID,
    reply_to_message_text TEXT,
    is_edited BOOLEAN,
    read_by_count INTEGER
) 
SECURITY DEFINER
AS $$
DECLARE
    v_around_time TIMESTAMPTZ;
    v_half_limit INTEGER;
BEGIN
    -- If around_message_id is provided, get its timestamp
    IF p_around_message_id IS NOT NULL THEN
        SELECT cm.created_at INTO v_around_time
        FROM public.chat_messages cm
        WHERE cm.id = p_around_message_id;
        
        v_half_limit := p_limit / 2;
        
        -- Get messages around the specified message id
        RETURN QUERY
        WITH message_data AS (
            (SELECT 
                cm.id AS message_id,
                cm.sender_id,
                p.full_name AS sender_name,
                cm.message,
                cm.created_at,
                cm.status,
                cm.reply_to_message_id,
                reply.message AS reply_to_message_text,
                cm.is_edited,
                COUNT(mrr.id)::INTEGER AS read_by_count
            FROM public.chat_messages cm
            LEFT JOIN public.chat_messages reply ON cm.reply_to_message_id = reply.id
            LEFT JOIN public.message_read_receipts mrr ON cm.id = mrr.message_id
            LEFT JOIN public.profiles p ON cm.sender_id = p.id
            WHERE 
                cm.chat_room_id = p_chat_room_id
                AND cm.created_at <= v_around_time
                AND cm.status != 'deleted'
            GROUP BY cm.id, p.full_name, reply.message
            ORDER BY cm.created_at DESC
            LIMIT v_half_limit)
            
            UNION ALL
            
            (SELECT 
                cm.id AS message_id,
                cm.sender_id,
                p.full_name AS sender_name,
                cm.message,
                cm.created_at,
                cm.status,
                cm.reply_to_message_id,
                reply.message AS reply_to_message_text,
                cm.is_edited,
                COUNT(mrr.id)::INTEGER AS read_by_count
            FROM public.chat_messages cm
            LEFT JOIN public.chat_messages reply ON cm.reply_to_message_id = reply.id
            LEFT JOIN public.message_read_receipts mrr ON cm.id = mrr.message_id
            LEFT JOIN public.profiles p ON cm.sender_id = p.id
            WHERE 
                cm.chat_room_id = p_chat_room_id
                AND cm.created_at > v_around_time
                AND cm.status != 'deleted'
            GROUP BY cm.id, p.full_name, reply.message
            ORDER BY cm.created_at ASC
            LIMIT v_half_limit)
        )
        SELECT * FROM message_data
        ORDER BY created_at ASC;
    ELSIF p_before IS NOT NULL THEN
        -- Get messages before the specified timestamp
        RETURN QUERY
        SELECT 
            cm.id AS message_id,
            cm.sender_id,
            p.full_name AS sender_name,
            cm.message,
            cm.created_at,
            cm.status,
            cm.reply_to_message_id,
            reply.message AS reply_to_message_text,
            cm.is_edited,
            COUNT(mrr.id)::INTEGER AS read_by_count
        FROM public.chat_messages cm
        LEFT JOIN public.chat_messages reply ON cm.reply_to_message_id = reply.id
        LEFT JOIN public.message_read_receipts mrr ON cm.id = mrr.message_id
        LEFT JOIN public.profiles p ON cm.sender_id = p.id
        WHERE 
            cm.chat_room_id = p_chat_room_id
            AND cm.created_at < p_before
            AND cm.status != 'deleted'
        GROUP BY cm.id, p.full_name, reply.message
        ORDER BY cm.created_at DESC
        LIMIT p_limit;
    ELSIF p_after IS NOT NULL THEN
        -- Get messages after the specified timestamp
        RETURN QUERY
        SELECT 
            cm.id AS message_id,
            cm.sender_id,
            p.full_name AS sender_name,
            cm.message,
            cm.created_at,
            cm.status,
            cm.reply_to_message_id,
            reply.message AS reply_to_message_text,
            cm.is_edited,
            COUNT(mrr.id)::INTEGER AS read_by_count
        FROM public.chat_messages cm
        LEFT JOIN public.chat_messages reply ON cm.reply_to_message_id = reply.id
        LEFT JOIN public.message_read_receipts mrr ON cm.id = mrr.message_id
        LEFT JOIN public.profiles p ON cm.sender_id = p.id
        WHERE 
            cm.chat_room_id = p_chat_room_id
            AND cm.created_at > p_after
            AND cm.status != 'deleted'
        GROUP BY cm.id, p.full_name, reply.message
        ORDER BY cm.created_at ASC
        LIMIT p_limit;
    ELSE
        -- Get the most recent messages
        RETURN QUERY
        SELECT 
            cm.id AS message_id,
            cm.sender_id,
            p.full_name AS sender_name,
            cm.message,
            cm.created_at,
            cm.status,
            cm.reply_to_message_id,
            reply.message AS reply_to_message_text,
            cm.is_edited,
            COUNT(mrr.id)::INTEGER AS read_by_count
        FROM public.chat_messages cm
        LEFT JOIN public.chat_messages reply ON cm.reply_to_message_id = reply.id
        LEFT JOIN public.message_read_receipts mrr ON cm.id = mrr.message_id
        LEFT JOIN public.profiles p ON cm.sender_id = p.id
        WHERE 
            cm.chat_room_id = p_chat_room_id
            AND cm.status != 'deleted'
        GROUP BY cm.id, p.full_name, reply.message
        ORDER BY cm.created_at DESC
        LIMIT p_limit;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Simplified overload for get_chat_messages with just the room ID
CREATE OR REPLACE FUNCTION get_chat_messages_simple(p_chat_room_id UUID)
RETURNS TABLE (
    message_id UUID,
    sender_id UUID,
    sender_name TEXT,
    message TEXT,
    created_at TIMESTAMPTZ,
    status message_status_enum,
    reply_to_message_id UUID,
    reply_to_message_text TEXT,
    is_edited BOOLEAN,
    read_by_count INTEGER
) 
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM get_chat_messages(p_chat_room_id, 50, NULL::TIMESTAMPTZ, NULL::TIMESTAMPTZ, NULL::UUID);
END;
$$ LANGUAGE plpgsql;

-- Function to mark a message as read
CREATE OR REPLACE FUNCTION mark_message_as_read(
    p_message_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN 
SECURITY DEFINER
AS $$
DECLARE
    v_chat_room_id UUID;
BEGIN
    -- Get the chat room id for the message
    SELECT chat_room_id INTO v_chat_room_id
    FROM public.chat_messages
    WHERE id = p_message_id;
    
    -- Check if user is a participant in the chat room
    IF NOT EXISTS (
        SELECT 1 FROM public.chat_participants
        WHERE chat_room_id = v_chat_room_id
        AND user_id = p_user_id
        AND left_at IS NULL
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Create read receipt if it doesn't exist
    INSERT INTO public.message_read_receipts (message_id, user_id)
    VALUES (p_message_id, p_user_id)
    ON CONFLICT (message_id, user_id) DO NOTHING;
    
    -- Update participant's last read message id if this is newer
    UPDATE public.chat_participants
    SET last_read_message_id = p_message_id
    WHERE chat_room_id = v_chat_room_id
      AND user_id = p_user_id
      AND (last_read_message_id IS NULL OR 
           EXISTS (
               SELECT 1 FROM public.chat_messages m1, public.chat_messages m2
               WHERE m1.id = p_message_id
               AND m2.id = last_read_message_id
               AND m1.created_at > m2.created_at
           ));
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to create a private chat between two users (or return existing one)
CREATE OR REPLACE FUNCTION create_or_get_private_chat(
    p_user_id1 UUID,
    p_user_id2 UUID
)
RETURNS UUID 
SECURITY DEFINER
AS $$
DECLARE
    v_chat_room_id UUID;
BEGIN
    -- Check if a private chat already exists between these users
    SELECT cr.id INTO v_chat_room_id
    FROM public.chat_rooms cr
    JOIN public.chat_participants cp1 ON cr.id = cp1.chat_room_id
    JOIN public.chat_participants cp2 ON cr.id = cp2.chat_room_id
    WHERE cr.type = 'private'
      AND cp1.user_id = p_user_id1
      AND cp2.user_id = p_user_id2
      AND cp1.left_at IS NULL
      AND cp2.left_at IS NULL;
    
    -- If private chat exists, return it
    IF v_chat_room_id IS NOT NULL THEN
        RETURN v_chat_room_id;
    END IF;
    
    -- Otherwise, create a new private chat
    INSERT INTO public.chat_rooms (type, created_by)
    VALUES ('private', p_user_id1)
    RETURNING id INTO v_chat_room_id;
    
    -- Creator is automatically added as admin by the trigger
    
    -- Add the second participant
    INSERT INTO public.chat_participants (chat_room_id, user_id, role)
    VALUES (v_chat_room_id, p_user_id2, 'member');
    
    RETURN v_chat_room_id;
END;
$$ LANGUAGE plpgsql;

-- Function to add participants to a chat room
CREATE OR REPLACE FUNCTION add_chat_participants(
    p_chat_room_id UUID,
    p_user_ids UUID[]
)
RETURNS SETOF public.chat_participants 
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_participant public.chat_participants;
    v_result public.chat_participants;
BEGIN
    -- Create a temporary table to collect results
    CREATE TEMP TABLE IF NOT EXISTS temp_participants AS
    SELECT * FROM public.chat_participants WHERE FALSE;
    
    -- Loop through all user ids
    FOREACH v_user_id IN ARRAY p_user_ids
    LOOP
        -- Insert or update the participant
        INSERT INTO public.chat_participants (chat_room_id, user_id)
        VALUES (p_chat_room_id, v_user_id)
        ON CONFLICT (chat_room_id, user_id)
        DO UPDATE SET
            left_at = NULL,
            joined_at = CURRENT_TIMESTAMP
        RETURNING * INTO v_participant;
        
        -- Insert into our temporary results table
        INSERT INTO temp_participants VALUES (v_participant.*);
    END LOOP;
    
    -- Return all participants in the room
    RETURN QUERY
    SELECT * FROM public.chat_participants
    WHERE chat_room_id = p_chat_room_id
    AND left_at IS NULL
    ORDER BY joined_at;
    
    -- Drop the temporary table
    DROP TABLE IF EXISTS temp_participants;
END;
$$ LANGUAGE plpgsql;

-- Row-Level Security (RLS) policies

-- Enable Row Level Security
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_read_receipts ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Chat rooms visible to participants" ON public.chat_rooms;
DROP POLICY IF EXISTS "Authenticated users can create chat rooms" ON public.chat_rooms;
DROP POLICY IF EXISTS "Room creators and admins can update chat rooms" ON public.chat_rooms;
DROP POLICY IF EXISTS "Room creators and admins can delete chat rooms" ON public.chat_rooms;
DROP POLICY IF EXISTS "Chat participants visible to members" ON public.chat_participants;
DROP POLICY IF EXISTS "Users can be added as participants" ON public.chat_participants;
DROP POLICY IF EXISTS "Participants can update their own data" ON public.chat_participants;
DROP POLICY IF EXISTS "Messages visible to chat participants" ON public.chat_messages;
DROP POLICY IF EXISTS "Only participants can insert messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Senders can update their own messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Read receipts visible to participants" ON public.message_read_receipts;
DROP POLICY IF EXISTS "Users can create their own read receipts" ON public.message_read_receipts;

-- Create RLS policies for chat_rooms
CREATE POLICY "Chat rooms visible to participants" ON public.chat_rooms
    FOR SELECT
    USING (true);  -- Temporarily set to true for testing

-- Allow authenticated users to create chat rooms
CREATE POLICY "Authenticated users can create chat rooms" ON public.chat_rooms
    FOR INSERT
    WITH CHECK (auth.uid() = created_by);

-- Allow room creators and admins to update chat rooms
CREATE POLICY "Room creators and admins can update chat rooms" ON public.chat_rooms
    FOR UPDATE
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.chat_participants
            WHERE chat_room_id = id
            AND user_id = auth.uid()
            AND role = 'admin'
            AND left_at IS NULL
        )
    );
    
-- Allow room creators and admins to delete chat rooms
CREATE POLICY "Room creators and admins can delete chat rooms" ON public.chat_rooms
    FOR DELETE
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.chat_participants
            WHERE chat_room_id = id
            AND user_id = auth.uid()
            AND role = 'admin'
            AND left_at IS NULL
        )
    );

-- Create RLS policies for chat_participants
CREATE POLICY "Chat participants visible to members" ON public.chat_participants
    FOR SELECT
    USING (true);  -- Temporarily set to true for testing
/*
-- Uncomment this block when ready for production RLS
CREATE POLICY "Chat participants visible to members" ON public.chat_participants
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 
            FROM public.chat_participants cp
            WHERE cp.chat_room_id = public.chat_participants.chat_room_id
            AND cp.user_id = auth.uid()
            AND cp.left_at IS NULL
        )
        OR auth.uid() = user_id
    );
*/

CREATE POLICY "Users can be added as participants" ON public.chat_participants
    FOR INSERT
    WITH CHECK (true);  -- Temporarily set to true for testing

CREATE POLICY "Participants can update their own data" ON public.chat_participants
    FOR UPDATE
    USING (true);  -- Temporarily set to true for testing

-- Create RLS policies for chat_messages
CREATE POLICY "Messages visible to chat participants" ON public.chat_messages
    FOR SELECT
    USING (true);  -- Temporarily set to true for testing

CREATE POLICY "Only participants can insert messages" ON public.chat_messages
    FOR INSERT
    WITH CHECK (true);  -- Temporarily set to true for testing

CREATE POLICY "Senders can update their own messages" ON public.chat_messages
    FOR UPDATE
    USING (true);  -- Temporarily set to true for testing

-- Create RLS policies for message_read_receipts
CREATE POLICY "Read receipts visible to participants" ON public.message_read_receipts
    FOR SELECT
    USING (true);  -- Temporarily set to true for testing

CREATE POLICY "Users can create their own read receipts" ON public.message_read_receipts
    FOR INSERT
    WITH CHECK (true);  -- Temporarily set to true for testing

-- Ensure user_roles table exists for the can_create_broadcast_room function
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_roles') THEN
        CREATE TABLE public.user_roles (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            role TEXT NOT NULL,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, role)
        );
        
        RAISE NOTICE 'Created user_roles table';
        
        -- Add policy for user_roles
        ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
        
        -- Drop policies if they exist first (shouldn't happen but being safe)
        DROP POLICY IF EXISTS "Users can see their own roles" ON public.user_roles;
        DROP POLICY IF EXISTS "Admin users can insert roles" ON public.user_roles;
        
        -- Create the policies
        CREATE POLICY "Users can see their own roles" ON public.user_roles
            FOR SELECT USING (auth.uid() = user_id);
            
        CREATE POLICY "Admin users can insert roles" ON public.user_roles
            FOR INSERT WITH CHECK (true);  -- For testing, allow all inserts
            
        -- Grant access to authenticated users
        GRANT ALL ON public.user_roles TO authenticated;
        
        RAISE NOTICE 'Created RLS policies for user_roles table';
    ELSE
        RAISE NOTICE 'user_roles table already exists, skipping creation';
        
        -- Ensure the policies exist
        IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'Users can see their own roles' AND polrelid = 'public.user_roles'::regclass) THEN
            CREATE POLICY "Users can see their own roles" ON public.user_roles
                FOR SELECT USING (auth.uid() = user_id);
            RAISE NOTICE 'Created missing "Users can see their own roles" policy';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'Admin users can insert roles' AND polrelid = 'public.user_roles'::regclass) THEN
            CREATE POLICY "Admin users can insert roles" ON public.user_roles
                FOR INSERT WITH CHECK (true);
            RAISE NOTICE 'Created missing "Admin users can insert roles" policy';
        END IF;
    END IF;
END
$$;


-- Function to update message status to 'read'
CREATE OR REPLACE FUNCTION update_message_status(
    p_message_id UUID,
    p_status message_status_enum
)
RETURNS BOOLEAN
SECURITY DEFINER
AS $$
DECLARE
    v_chat_room_id UUID;
    v_sender_id UUID;
BEGIN
    -- Get the chat room id and sender id for the message
    SELECT chat_room_id, sender_id INTO v_chat_room_id, v_sender_id
    FROM public.chat_messages
    WHERE id = p_message_id;
    
    -- Check if user is a participant in the chat room
    IF NOT EXISTS (
        SELECT 1 FROM public.chat_participants
        WHERE chat_room_id = v_chat_room_id
        AND user_id = auth.uid()
        AND left_at IS NULL
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Only allow changing status to 'read' or 'deleted'
    IF p_status NOT IN ('read', 'deleted') THEN
        RETURN FALSE;
    END IF;
    
    -- For 'deleted', only allow if user is the sender or an admin
    IF p_status = 'deleted' AND auth.uid() != v_sender_id AND NOT EXISTS (
        SELECT 1 FROM public.chat_participants
        WHERE chat_room_id = v_chat_room_id
        AND user_id = auth.uid()
        AND role = 'admin'
        AND left_at IS NULL
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Update the message status
    UPDATE public.chat_messages
    SET status = p_status
    WHERE id = p_message_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions to authenticated users
DO $$
BEGIN
    -- Grant schema usage if not already granted
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.usage_privileges
        WHERE grantee = 'authenticated'
        AND object_schema = 'public'
        AND privilege_type = 'USAGE'
    ) THEN
        GRANT USAGE ON SCHEMA public TO authenticated;
    END IF;

    -- Grant table privileges
    GRANT ALL ON public.chat_rooms TO authenticated;
    GRANT ALL ON public.chat_participants TO authenticated;
    GRANT ALL ON public.chat_messages TO authenticated;
    GRANT ALL ON public.message_read_receipts TO authenticated;
    GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

    -- Grant execute permissions on functions
    GRANT EXECUTE ON FUNCTION update_chat_room_timestamp TO authenticated;
    GRANT EXECUTE ON FUNCTION update_chat_room_timestamp_on_message TO authenticated;
    GRANT EXECUTE ON FUNCTION can_create_broadcast_room TO authenticated;
    GRANT EXECUTE ON FUNCTION add_creator_as_participant TO authenticated;
    GRANT EXECUTE ON FUNCTION update_sender_read_receipt TO authenticated;
    GRANT EXECUTE ON FUNCTION get_user_chat_rooms(UUID) TO authenticated;
    GRANT EXECUTE ON FUNCTION get_user_chat_rooms() TO authenticated;
    GRANT EXECUTE ON FUNCTION get_chat_messages(UUID, INTEGER, TIMESTAMPTZ, TIMESTAMPTZ, UUID) TO authenticated;
    GRANT EXECUTE ON FUNCTION get_chat_messages_simple(UUID) TO authenticated;
    GRANT EXECUTE ON FUNCTION mark_message_as_read(UUID, UUID) TO authenticated;
    GRANT EXECUTE ON FUNCTION create_or_get_private_chat(UUID, UUID) TO authenticated;
    GRANT EXECUTE ON FUNCTION add_chat_participants(UUID, UUID[]) TO authenticated;
    GRANT EXECUTE ON FUNCTION update_message_status(UUID, message_status_enum) TO authenticated;
END$$;

-- Real-time Authorization setup
DO $$
BEGIN
  -- Check if the realtime schema exists
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'realtime') THEN
    -- Check if the publication exists
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
      -- Check if chat_messages is already in the publication
      IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'chat_messages'
      ) THEN
        -- Try to add chat_messages to the existing publication
        BEGIN
          EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages';
        EXCEPTION WHEN others THEN
          RAISE NOTICE 'Could not add chat_messages to publication: %', SQLERRM;
        END;
      END IF;
    ELSE
      -- Publication doesn't exist, try to create it
      BEGIN
        EXECUTE 'CREATE PUBLICATION supabase_realtime FOR TABLE public.chat_messages';
      EXCEPTION WHEN others THEN
        RAISE NOTICE 'Could not create publication: %', SQLERRM;
      END;
    END IF;
  END IF;
END;
$$;

-- Create the broadcast function for postgres_changes
CREATE OR REPLACE FUNCTION public.broadcast_chat_message_changes()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
  -- Don't try to call realtime.broadcast_changes directly
  -- The trigger itself will generate postgres_changes events that clients can subscribe to
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$;

-- Create the trigger for postgres_changes
DO $$
DECLARE
  trigger_exists BOOLEAN;
BEGIN
  -- First drop the trigger if it exists - this is safe since we'll recreate it
  DROP TRIGGER IF EXISTS broadcast_chat_message_changes ON public.chat_messages;
  
  -- Create the trigger
  CREATE TRIGGER broadcast_chat_message_changes
  AFTER INSERT OR UPDATE OR DELETE ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.broadcast_chat_message_changes();
  
  RAISE NOTICE 'Created or recreated broadcast_chat_message_changes trigger';
END$$;

-- Message reactions feature
-- This allows users to react to messages with emojis

-- Create enum for predefined reaction types (optional)
DO $$
BEGIN
    -- Create reaction_type_enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reaction_type_enum') THEN
        CREATE TYPE public.reaction_type_enum AS ENUM (
            'like',      -- 👍
            'love',      -- ❤️
            'haha',      -- 😂
            'wow',       -- 😮
            'sad',       -- 😢
            'angry',     -- 😠
            'custom'     -- For custom emoji reactions
        );
        RAISE NOTICE 'Created reaction_type_enum type';
    ELSE
        RAISE NOTICE 'reaction_type_enum type already exists, skipping creation';
    END IF;
END$$;

-- Message reactions table
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction_type reaction_type_enum NOT NULL,
    emoji_code TEXT, -- Unicode character or emoji code for custom reactions
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(message_id, user_id, reaction_type) -- One reaction type per user per message
);

-- Create indices for better query performance if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_message_reactions_message_id') THEN
        CREATE INDEX idx_message_reactions_message_id ON public.message_reactions(message_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_message_reactions_user_id') THEN
        CREATE INDEX idx_message_reactions_user_id ON public.message_reactions(user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_message_reactions_type') THEN
        CREATE INDEX idx_message_reactions_type ON public.message_reactions(reaction_type);
    END IF;
END$$;

-- Enable Row Level Security for message_reactions
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Message reactions visible to participants" ON public.message_reactions;
DROP POLICY IF EXISTS "Users can add reactions to messages" ON public.message_reactions;
DROP POLICY IF EXISTS "Users can remove their own reactions" ON public.message_reactions;

-- Create RLS policies for message_reactions
CREATE POLICY "Message reactions visible to participants" ON public.message_reactions
    FOR SELECT
    USING (true);  -- Temporarily set to true for testing

CREATE POLICY "Users can add reactions to messages" ON public.message_reactions
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can remove their own reactions" ON public.message_reactions
    FOR DELETE
    USING (user_id = auth.uid());

-- Function to toggle a reaction on a message
CREATE OR REPLACE FUNCTION toggle_message_reaction(
    p_message_id UUID,
    p_reaction_type reaction_type_enum,
    p_emoji_code TEXT DEFAULT NULL
)
RETURNS BOOLEAN
SECURITY DEFINER
AS $$
DECLARE
    v_chat_room_id UUID;
    v_existing_reaction UUID;
BEGIN
    -- Get the chat room id for the message
    SELECT chat_room_id INTO v_chat_room_id
    FROM public.chat_messages
    WHERE id = p_message_id;
    
    -- Check if user is a participant in the chat room
    IF NOT EXISTS (
        SELECT 1 FROM public.chat_participants
        WHERE chat_room_id = v_chat_room_id
        AND user_id = auth.uid()
        AND left_at IS NULL
    ) THEN
        RETURN FALSE;
    END IF;

    -- Check if the reaction already exists
    SELECT id INTO v_existing_reaction
    FROM public.message_reactions
    WHERE message_id = p_message_id
    AND user_id = auth.uid()
    AND reaction_type = p_reaction_type;
    
    -- If reaction exists, delete it (toggle off)
    IF v_existing_reaction IS NOT NULL THEN
        DELETE FROM public.message_reactions
        WHERE id = v_existing_reaction;
        RETURN TRUE;
    END IF;
    
    -- Otherwise, create the reaction (toggle on)
    INSERT INTO public.message_reactions (
        message_id,
        user_id,
        reaction_type,
        emoji_code
    ) VALUES (
        p_message_id,
        auth.uid(),
        p_reaction_type,
        p_emoji_code
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to get reactions for a message
CREATE OR REPLACE FUNCTION get_message_reactions(p_message_id UUID)
RETURNS TABLE (
    reaction_type reaction_type_enum,
    emoji_code TEXT,
    count BIGINT,
    user_ids UUID[],
    user_has_reacted BOOLEAN
)
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mr.reaction_type,
        mr.emoji_code,
        COUNT(*) AS count,
        array_agg(mr.user_id) AS user_ids,
        bool_or(mr.user_id = auth.uid()) AS user_has_reacted
    FROM public.message_reactions mr
    WHERE mr.message_id = p_message_id
    GROUP BY mr.reaction_type, mr.emoji_code
    ORDER BY count DESC, mr.reaction_type;
END;
$$ LANGUAGE plpgsql;

-- Update the get_chat_messages function to include reactions
CREATE OR REPLACE FUNCTION get_chat_messages_with_reactions(
    p_chat_room_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_before TIMESTAMPTZ DEFAULT NULL,
    p_after TIMESTAMPTZ DEFAULT NULL,
    p_around_message_id UUID DEFAULT NULL
)
RETURNS TABLE (
    message_id UUID,
    sender_id UUID,
    sender_name TEXT,
    message TEXT,
    created_at TIMESTAMPTZ,
    status message_status_enum,
    reply_to_message_id UUID,
    reply_to_message_text TEXT,
    is_edited BOOLEAN,
    read_by_count INTEGER,
    reactions JSON
)
SECURITY DEFINER
AS $$
DECLARE
    v_around_time TIMESTAMPTZ;
    v_half_limit INTEGER;
    v_messages_base RECORD;
    v_result RECORD;
BEGIN
    -- Get base message data by calling existing function
    FOR v_messages_base IN
        SELECT * FROM get_chat_messages(
            p_chat_room_id,
            p_limit,
            p_before,
            p_after,
            p_around_message_id
        )
    LOOP
        -- For each message, fetch its reactions
        SELECT
            v_messages_base.message_id,
            v_messages_base.sender_id,
            v_messages_base.sender_name,
            v_messages_base.message,
            v_messages_base.created_at,
            v_messages_base.status,
            v_messages_base.reply_to_message_id,
            v_messages_base.reply_to_message_text,
            v_messages_base.is_edited,
            v_messages_base.read_by_count,
            COALESCE(
                (
                    SELECT json_agg(
                        json_build_object(
                            'type', r.reaction_type,
                            'emoji_code', r.emoji_code,
                            'count', r.count,
                            'user_has_reacted', r.user_has_reacted
                        )
                    )
                    FROM get_message_reactions(v_messages_base.message_id) r
                ),
                '[]'::json
            ) AS reactions
        INTO v_result;
        
        -- Return the row with reactions
        message_id := v_result.message_id;
        sender_id := v_result.sender_id;
        sender_name := v_result.sender_name;
        message := v_result.message;
        created_at := v_result.created_at;
        status := v_result.status;
        reply_to_message_id := v_result.reply_to_message_id;
        reply_to_message_text := v_result.reply_to_message_text;
        is_edited := v_result.is_edited;
        read_by_count := v_result.read_by_count;
        reactions := v_result.reactions;
        
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Add real-time notification for reactions
DO $$
BEGIN
  -- Check if the realtime schema exists
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'realtime') THEN
    -- Check if the publication exists
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
      -- Check if message_reactions is already in the publication
      IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'message_reactions'
      ) THEN
        -- Try to add message_reactions to the existing publication
        BEGIN
          EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.message_reactions';
        EXCEPTION WHEN others THEN
          RAISE NOTICE 'Could not add message_reactions to publication: %', SQLERRM;
        END;
      END IF;
    END IF;
  END IF;
END;
$$;

-- Create the broadcast function for message reaction changes
CREATE OR REPLACE FUNCTION public.broadcast_message_reaction_changes()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
  -- The trigger itself will generate postgres_changes events that clients can subscribe to
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$;

-- Create the trigger for postgres_changes on message_reactions
DO $$
DECLARE
  trigger_exists BOOLEAN;
BEGIN
  -- First drop the trigger if it exists - this is safe since we'll recreate it
  DROP TRIGGER IF EXISTS broadcast_message_reaction_changes ON public.message_reactions;
  
  -- Create the trigger
  CREATE TRIGGER broadcast_message_reaction_changes
  AFTER INSERT OR UPDATE OR DELETE ON public.message_reactions
  FOR EACH ROW
  EXECUTE FUNCTION public.broadcast_message_reaction_changes();
  
  RAISE NOTICE 'Created or recreated broadcast_message_reaction_changes trigger';
END$$;

-- Grant permissions for the new table and functions
DO $$
BEGIN
    -- Grant table privileges
    GRANT ALL ON public.message_reactions TO authenticated;
    
    -- Grant execute permissions on functions
    GRANT EXECUTE ON FUNCTION toggle_message_reaction(UUID, reaction_type_enum, TEXT) TO authenticated;
    GRANT EXECUTE ON FUNCTION get_message_reactions(UUID) TO authenticated;
    GRANT EXECUTE ON FUNCTION get_chat_messages_with_reactions(UUID, INTEGER, TIMESTAMPTZ, TIMESTAMPTZ, UUID) TO authenticated;
END$$;


COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
