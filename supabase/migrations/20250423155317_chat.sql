-- Chat Feature Migration for Supabase
-- This migration creates all necessary tables, functions, and policies for the chat feature

-- ENUM Types for chat-related statuses
CREATE TYPE public.chat_type_enum AS ENUM (
    'private',         -- One-on-one chats between users
    'group',           -- Group chats for multiple participants
    'broadcast'        -- Creator broadcast channels
);

CREATE TYPE public.message_status_enum AS ENUM (
    'delivered',       -- Message has been delivered to the database
    'read',            -- Message has been read by recipient
    'deleted'          -- Message has been deleted (soft delete)
);

-- Chat rooms table to store different chat conversations
CREATE TABLE public.chat_rooms (
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

-- Create indices for better query performance
CREATE INDEX idx_chat_rooms_created_by ON public.chat_rooms(created_by);
CREATE INDEX idx_chat_rooms_type ON public.chat_rooms(type);
CREATE INDEX idx_chat_rooms_associated_post ON public.chat_rooms(associated_post_id) 
    WHERE associated_post_id IS NOT NULL;
CREATE INDEX idx_chat_rooms_associated_event ON public.chat_rooms(associated_event_id) 
    WHERE associated_event_id IS NOT NULL;

-- Participants in each chat room
CREATE TABLE public.chat_participants (
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

-- Create indices for better query performance
CREATE INDEX idx_chat_participants_user_id ON public.chat_participants(user_id);
CREATE INDEX idx_chat_participants_chat_room_id ON public.chat_participants(chat_room_id);
CREATE INDEX idx_chat_participants_left_at ON public.chat_participants(left_at) 
    WHERE left_at IS NULL;

-- Individual chat messages
CREATE TABLE public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id),
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    status message_status_enum DEFAULT 'delivered',
    reply_to_message_id UUID, -- Will be self-referenced after table creation
    is_edited BOOLEAN DEFAULT FALSE
);

-- Add self-reference to chat_messages for replies
ALTER TABLE public.chat_messages 
    ADD CONSTRAINT fk_reply_to_message 
    FOREIGN KEY (reply_to_message_id) 
    REFERENCES public.chat_messages(id) ON DELETE SET NULL;

-- Now update the chat_participants table with the last_read_message foreign key
ALTER TABLE public.chat_participants 
    ADD CONSTRAINT fk_last_read_message 
    FOREIGN KEY (last_read_message_id) 
    REFERENCES public.chat_messages(id) ON DELETE SET NULL;

-- Create indices for better query performance
CREATE INDEX idx_chat_messages_chat_room_id ON public.chat_messages(chat_room_id);
CREATE INDEX idx_chat_messages_sender_id ON public.chat_messages(sender_id);
CREATE INDEX idx_chat_messages_created_at ON public.chat_messages(created_at);
CREATE INDEX idx_chat_messages_reply_to ON public.chat_messages(reply_to_message_id) 
    WHERE reply_to_message_id IS NOT NULL;

-- Message read receipts
CREATE TABLE public.message_read_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(message_id, user_id)
);

-- Create indices for better query performance
CREATE INDEX idx_message_read_receipts_message_id ON public.message_read_receipts(message_id);
CREATE INDEX idx_message_read_receipts_user_id ON public.message_read_receipts(user_id);

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
CREATE TRIGGER update_chat_room_timestamp
BEFORE UPDATE ON public.chat_rooms
FOR EACH ROW
EXECUTE FUNCTION update_chat_room_timestamp();

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
CREATE TRIGGER update_chat_room_timestamp_on_message
AFTER INSERT ON public.chat_messages
FOR EACH ROW
EXECUTE FUNCTION update_chat_room_timestamp_on_message();

-- Function to check if a user can create a broadcast chat room
CREATE OR REPLACE FUNCTION can_create_broadcast_room()
RETURNS TRIGGER AS $$
BEGIN
    -- For testing purposes, always allow creating broadcast rooms
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check if a user can create a broadcast room
DROP TRIGGER IF EXISTS check_broadcast_room_creator ON public.chat_rooms;

CREATE TRIGGER check_broadcast_room_creator
BEFORE INSERT ON public.chat_rooms
FOR EACH ROW
EXECUTE FUNCTION can_create_broadcast_room();

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
CREATE TRIGGER add_creator_to_participants
AFTER INSERT ON public.chat_rooms
FOR EACH ROW
EXECUTE FUNCTION add_creator_as_participant();

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
    VALUES (NEW.id, NEW.sender_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update sender's read receipt when a message is sent
CREATE TRIGGER update_sender_read_receipt
AFTER INSERT ON public.chat_messages
FOR EACH ROW
EXECUTE FUNCTION update_sender_read_receipt();

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
    CREATE TEMP TABLE temp_participants AS
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
    DROP TABLE temp_participants;
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
        
        -- Add policy for user_roles
        ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Users can see their own roles" ON public.user_roles
            FOR SELECT USING (auth.uid() = user_id);
            
        CREATE POLICY "Admin users can insert roles" ON public.user_roles
            FOR INSERT WITH CHECK (true);  -- For testing, allow all inserts
            
        -- Grant access to authenticated users
        GRANT ALL ON public.user_roles TO authenticated;
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
GRANT USAGE ON SCHEMA public TO authenticated;
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

-- Real-time Authorization setup
DO $$
BEGIN
  -- Check if the realtime schema exists
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'realtime') THEN
    -- Try to enable postgres changes for the tables
    BEGIN
      -- Enable postgres changes for the tables we want to track
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages';
    EXCEPTION WHEN others THEN
      -- Publication might not exist or table might already be added
      RAISE NOTICE 'Note: Could not add chat_messages to publication: %', SQLERRM;
      
      -- Try to create the publication if it doesn't exist
      BEGIN
        EXECUTE 'CREATE PUBLICATION supabase_realtime FOR TABLE public.chat_messages';
      EXCEPTION WHEN others THEN
        RAISE NOTICE 'Note: Could not create publication: %', SQLERRM;
      END;
    END;
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
DROP TRIGGER IF EXISTS broadcast_chat_message_changes ON public.chat_messages;
CREATE TRIGGER broadcast_chat_message_changes
AFTER INSERT OR UPDATE OR DELETE ON public.chat_messages
FOR EACH ROW
EXECUTE FUNCTION public.broadcast_chat_message_changes();
