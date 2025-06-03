-- Generated with srtd from template: supabase/migrations-templates/20250603000000_implement_specialized_chat_channels.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;


-- ========================================
-- Specialized Chat Channels Implementation
-- ========================================
-- This migration implements specialized chat room types for different
-- notification and interaction channels, with focus on appointment management


-- Drop existing type and recreate with new values (PostgreSQL safe approach)
DO $$
BEGIN
  -- Create new enum type with all values
  CREATE TYPE public.chat_type_enum_new AS ENUM (
    'private',
    'group', 
    'broadcast',
    'appointment_booking',
    'event_notification',
    'service_updates',
    'booking_support',
    'transaction_channel'
  );
  
  -- Update table to use new enum (safe conversion)
  ALTER TABLE public.chat_rooms 
    ALTER COLUMN type TYPE public.chat_type_enum_new 
    USING type::text::public.chat_type_enum_new;
  
  -- Drop old enum and rename new one
  DROP TYPE IF EXISTS public.chat_type_enum CASCADE;
  ALTER TYPE public.chat_type_enum_new RENAME TO chat_type_enum;
  
EXCEPTION
  WHEN duplicate_object THEN
    -- Type already exists with these values, continue
    NULL;
END $$;

-- ========================================
-- Enhanced Chat Rooms Table Structure
-- ========================================

-- Add new columns for specialized chat functionality
DO $$
BEGIN
  -- Add appointment association
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_rooms' 
    AND column_name = 'associated_appointment_id'
  ) THEN
    ALTER TABLE public.chat_rooms 
    ADD COLUMN associated_appointment_id UUID REFERENCES public.appointment_purchases(id) ON DELETE CASCADE;
  END IF;

  -- Add metadata for specialized chat configurations
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_rooms' 
    AND column_name = 'metadata'
  ) THEN
    ALTER TABLE public.chat_rooms 
    ADD COLUMN metadata JSONB DEFAULT '{}';
  END IF;

  -- Add auto-notification settings
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_rooms' 
    AND column_name = 'auto_notifications'
  ) THEN
    ALTER TABLE public.chat_rooms 
    ADD COLUMN auto_notifications BOOLEAN DEFAULT false;
  END IF;

  -- Add pinned message for current status
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_rooms' 
    AND column_name = 'pinned_message_id'
  ) THEN
    ALTER TABLE public.chat_rooms 
    ADD COLUMN pinned_message_id UUID REFERENCES public.chat_messages(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ========================================
-- Enhanced Chat Messages for Action Buttons
-- ========================================

-- Add action buttons support to chat messages
DO $$
BEGIN
  -- Add action buttons as JSONB
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_messages' 
    AND column_name = 'action_buttons'
  ) THEN
    ALTER TABLE public.chat_messages 
    ADD COLUMN action_buttons JSONB DEFAULT NULL;
  END IF;

  -- Add message type for specialized messages
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_messages' 
    AND column_name = 'message_type'
  ) THEN
    ALTER TABLE public.chat_messages 
    ADD COLUMN message_type TEXT DEFAULT 'regular';
  END IF;

  -- Add superseded_by for message replacement tracking
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_messages' 
    AND column_name = 'superseded_by'
  ) THEN
    ALTER TABLE public.chat_messages 
    ADD COLUMN superseded_by UUID REFERENCES public.chat_messages(id) ON DELETE SET NULL;
  END IF;

  -- Add appointment context
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_messages' 
    AND column_name = 'appointment_context'
  ) THEN
    ALTER TABLE public.chat_messages 
    ADD COLUMN appointment_context JSONB DEFAULT NULL;
  END IF;
END $$;

-- ========================================
-- Chat Room Management Functions
-- ========================================

drop function if exists public.create_appointment_chat_room;
-- Function to create specialized appointment chat rooms
CREATE OR REPLACE FUNCTION public.create_appointment_chat_room(
  p_appointment_id UUID,
  p_client_id UUID,
  p_owner_id UUID,
  p_service_name TEXT DEFAULT NULL,
  p_appointment_date TIMESTAMPTZ DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_chat_room_id UUID;
  v_room_name TEXT;
  v_metadata JSONB;
BEGIN
  -- Generate descriptive room name
  v_room_name := COALESCE(p_service_name, 'Service') || ' - ' || 
    COALESCE(to_char(p_appointment_date, 'DD/MM/YYYY HH24:MI'), 'Appointment') ||
    ' (ID: ' || p_appointment_id || ')';

  -- Prepare metadata
  v_metadata := jsonb_build_object(
    'appointment_id', p_appointment_id,
    'service_name', p_service_name,
    'appointment_date', p_appointment_date,
    'created_for', 'appointment_booking'
  );

  -- Create specialized appointment chat room
  INSERT INTO public.chat_rooms (
    name,
    type,
    created_by,
    associated_appointment_id,
    metadata,
    auto_notifications
  ) VALUES (
    v_room_name,
    'appointment_booking',
    p_owner_id,
    p_appointment_id,
    v_metadata,
    true
  ) RETURNING id INTO v_chat_room_id;

  -- Add participants
  INSERT INTO public.chat_participants (chat_room_id, user_id, role)
  VALUES 
    (v_chat_room_id, p_client_id, 'member'),
    (v_chat_room_id, p_owner_id, 'admin')
  ON CONFLICT (chat_room_id, user_id) DO NOTHING;

  RETURN v_chat_room_id;
END $$;

drop function if exists public.get_or_create_appointment_chat;
-- Function to get or create appointment chat room
CREATE OR REPLACE FUNCTION public.get_or_create_appointment_chat(
  p_appointment_id UUID,
  p_client_id UUID,
  p_owner_id UUID,
  p_service_name TEXT DEFAULT NULL,
  p_appointment_date TIMESTAMPTZ DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_chat_room_id UUID;
BEGIN
  -- Check for existing appointment chat room
  SELECT id INTO v_chat_room_id
  FROM public.chat_rooms
  WHERE associated_appointment_id = p_appointment_id
    AND type = 'appointment_booking';

  -- Create new room if none exists
  IF v_chat_room_id IS NULL THEN
    v_chat_room_id := public.create_appointment_chat_room(
      p_appointment_id,
      p_client_id,
      p_owner_id,
      p_service_name,
      p_appointment_date
    );
  END IF;

  RETURN v_chat_room_id;
END $$;

-- ========================================
-- Living Message System
-- ========================================

drop function if exists public.create_or_update_appointment_message;

-- Function to create/update living appointment message
CREATE OR REPLACE FUNCTION public.create_or_update_appointment_message(
  p_chat_room_id UUID,
  p_sender_id UUID,
  p_appointment_id UUID,
  p_status TEXT,
  p_message_content TEXT,
  p_action_buttons JSONB DEFAULT NULL,
  p_appointment_context JSONB DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_existing_message_id UUID;
  v_new_message_id UUID;
BEGIN
  -- Find existing active appointment message in this chat room
  SELECT id INTO v_existing_message_id
  FROM public.chat_messages
  WHERE chat_room_id = p_chat_room_id
    AND message_type = 'appointment_status'
    AND superseded_by IS NULL
    AND (appointment_context->>'appointment_id')::UUID = p_appointment_id;

  -- Create new message
  INSERT INTO public.chat_messages (
    chat_room_id,
    sender_id,
    message,
    message_type,
    action_buttons,
    appointment_context,
    status
  ) VALUES (
    p_chat_room_id,
    p_sender_id,
    p_message_content,
    'appointment_status',
    p_action_buttons,
    COALESCE(p_appointment_context, jsonb_build_object(
      'appointment_id', p_appointment_id,
      'status', p_status,
      'timestamp', extract(epoch from now())
    )),
    'delivered'
  ) RETURNING id INTO v_new_message_id;

  -- Mark existing message as superseded if it exists
  IF v_existing_message_id IS NOT NULL THEN
    UPDATE public.chat_messages
    SET superseded_by = v_new_message_id
    WHERE id = v_existing_message_id;
  END IF;

  -- Update pinned message for the chat room
  UPDATE public.chat_rooms
  SET pinned_message_id = v_new_message_id
  WHERE id = p_chat_room_id;

  RETURN v_new_message_id;
END $$;

-- ========================================
-- Enhanced Chat Query Functions
-- ========================================

-- Function to get chat messages with superseded filtering
drop function if exists public.get_active_chat_messages;
CREATE OR REPLACE FUNCTION public.get_active_chat_messages(
  p_chat_room_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_before TIMESTAMPTZ DEFAULT NULL
) RETURNS TABLE(
  message_id UUID,
  sender_id UUID,
  sender_name TEXT,
  message TEXT,
  message_type TEXT,
  action_buttons JSONB,
  appointment_context JSONB,
  created_at TIMESTAMPTZ,
  status TEXT,
  is_superseded BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cm.id,
    cm.sender_id,
    COALESCE(p.first_name || ' ' || p.last_name, p.first_name, 'Unknown') as sender_name,
    cm.message,
    COALESCE(cm.message_type, 'regular'),
    cm.action_buttons,
    cm.appointment_context,
    cm.created_at,
    cm.status,
    (cm.superseded_by IS NOT NULL) as is_superseded
  FROM public.chat_messages cm
  LEFT JOIN public.profiles p ON cm.sender_id = p.id
  WHERE cm.chat_room_id = p_chat_room_id
    AND (p_before IS NULL OR cm.created_at < p_before)
  ORDER BY cm.created_at DESC
  LIMIT p_limit;
END $$;

-- Function to get current appointment status message
drop function if exists public.get_current_appointment_message;
CREATE OR REPLACE FUNCTION public.get_current_appointment_message(
  p_appointment_id UUID
) RETURNS TABLE(
  message_id UUID,
  chat_room_id UUID,
  message_content TEXT,
  action_buttons JSONB,
  appointment_context JSONB,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cm.id,
    cm.chat_room_id,
    cm.message,
    cm.action_buttons,
    cm.appointment_context,
    cm.created_at
  FROM public.chat_messages cm
  JOIN public.chat_rooms cr ON cm.chat_room_id = cr.id
  WHERE cr.associated_appointment_id = p_appointment_id
    AND cr.type = 'appointment_booking'
    AND cm.message_type = 'appointment_status'
    AND cm.superseded_by IS NULL;
END $$;

-- Enhanced get_chat_messages_with_reactions function with action buttons support
drop function if exists public.get_chat_messages_with_reactions;
CREATE OR REPLACE FUNCTION public.get_chat_messages_with_reactions(
  p_chat_room_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_before TIMESTAMPTZ DEFAULT NULL,
  p_after TIMESTAMPTZ DEFAULT NULL,
  p_around_message_id UUID DEFAULT NULL
) RETURNS TABLE(
  message_id UUID,
  sender_id UUID,
  sender_name TEXT,
  message TEXT,
  message_type TEXT,
  action_buttons JSONB,
  appointment_context JSONB,
  created_at TIMESTAMPTZ,
  status message_status_enum,
  reply_to_message_id UUID,
  reply_to_message_text TEXT,
  is_edited BOOLEAN,
  read_by_count INTEGER,
  reactions JSON,
  superseded_by UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cm.id,
    cm.sender_id,
    COALESCE(p.full_name, 'Unknown') as sender_name,
    cm.message,
    COALESCE(cm.message_type, 'regular'),
    cm.action_buttons,
    cm.appointment_context,
    cm.created_at,
    cm.status,
    cm.reply_to_message_id,
    reply_msg.message as reply_to_message_text,
    cm.is_edited,
    0 as read_by_count, -- Simplified for now
    '[]'::json as reactions, -- Simplified for now
    cm.superseded_by
  FROM public.chat_messages cm
  LEFT JOIN public.profiles p ON cm.sender_id = p.id
  LEFT JOIN public.chat_messages reply_msg ON cm.reply_to_message_id = reply_msg.id
  WHERE cm.chat_room_id = p_chat_room_id
    AND (p_before IS NULL OR cm.created_at < p_before)
    AND (p_after IS NULL OR cm.created_at > p_after)
    AND (
      p_around_message_id IS NULL OR 
      cm.id = p_around_message_id OR
      cm.created_at >= (
        SELECT msg.created_at - INTERVAL '1 hour'
        FROM public.chat_messages msg
        WHERE msg.id = p_around_message_id
      ) AND cm.created_at <= (
        SELECT msg.created_at + INTERVAL '1 hour'
        FROM public.chat_messages msg
        WHERE msg.id = p_around_message_id
      )
    )
  ORDER BY cm.created_at DESC
  LIMIT p_limit;
END $$;

-- ========================================
-- Flexible Chat Room Filtering Function
-- ========================================

-- Function to get user chat rooms with flexible filtering options
drop function if exists public.get_user_chat_rooms_filtered;
CREATE OR REPLACE FUNCTION public.get_user_chat_rooms_filtered(
  p_user_id UUID DEFAULT NULL,
  p_chat_types TEXT[] DEFAULT NULL, -- Filter by chat types: 'private', 'appointment_booking', etc.
  p_has_appointment BOOLEAN DEFAULT NULL, -- Filter by whether room has associated appointment
  p_appointment_status TEXT DEFAULT NULL, -- Filter by appointment status
  p_has_unread BOOLEAN DEFAULT NULL, -- Filter by unread messages
  p_search_text TEXT DEFAULT NULL, -- Search in room names
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
) RETURNS TABLE(
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
  -- Specialized chat fields
  associated_appointment_id UUID,
  metadata JSONB,
  auto_notifications BOOLEAN,
  pinned_message_id UUID,
  -- Additional filter context
  appointment_status TEXT,
  appointment_date TIMESTAMPTZ,
  service_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Use provided user_id or get from auth
  v_user_id := COALESCE(p_user_id, auth.uid());
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID required';
  END IF;

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
    LEFT JOIN public.message_read_receipts mrr ON cm.id = mrr.message_id AND mrr.user_id = v_user_id
    WHERE 
      cp.user_id = v_user_id
      AND cp.left_at IS NULL
      AND cm.status != 'deleted'
      AND cm.sender_id != v_user_id
      AND mrr.id IS NULL
    GROUP BY cp.chat_room_id
  ),
  appointment_info AS (
    SELECT 
      cr.id as chat_room_id,
      ap.status::TEXT as appointment_status,
      ap.appointment_date,
      p.title as service_name
    FROM public.chat_rooms cr
    LEFT JOIN public.appointment_purchases ap ON cr.associated_appointment_id = ap.id
    LEFT JOIN public.services s ON ap.service_id = s.id
    LEFT JOIN public.posts p ON s.post_id = p.id
    WHERE cr.associated_appointment_id IS NOT NULL
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
    -- Specialized chat fields
    cr.associated_appointment_id,
    cr.metadata,
    cr.auto_notifications,
    cr.pinned_message_id,
    -- Additional context
    ai.appointment_status,
    ai.appointment_date,
    ai.service_name
  FROM public.chat_rooms cr
  JOIN public.chat_participants cp ON cr.id = cp.chat_room_id
  LEFT JOIN latest_messages lm ON cr.id = lm.chat_room_id
  LEFT JOIN unread_counts uc ON cr.id = uc.chat_room_id
  LEFT JOIN appointment_info ai ON cr.id = ai.chat_room_id
  WHERE 
    cp.user_id = v_user_id
    AND cp.left_at IS NULL
    -- Filter by chat types
    AND (p_chat_types IS NULL OR cr.type::TEXT = ANY(p_chat_types))
    -- Filter by appointment association
    AND (p_has_appointment IS NULL OR 
         (p_has_appointment = true AND cr.associated_appointment_id IS NOT NULL) OR
         (p_has_appointment = false AND cr.associated_appointment_id IS NULL))
    -- Filter by appointment status
    AND (p_appointment_status IS NULL OR ai.appointment_status = p_appointment_status)
    -- Filter by unread messages
    AND (p_has_unread IS NULL OR 
         (p_has_unread = true AND COALESCE(uc.count, 0) > 0) OR
         (p_has_unread = false AND COALESCE(uc.count, 0) = 0))
    -- Search in room names
    AND (p_search_text IS NULL OR 
         cr.name ILIKE '%' || p_search_text || '%' OR
         ai.service_name ILIKE '%' || p_search_text || '%')
  ORDER BY COALESCE(lm.created_at, cr.created_at) DESC
  LIMIT p_limit OFFSET p_offset;
END $$;

-- ========================================
-- Indexes for Performance
-- ========================================

-- Indexes for specialized chat rooms
CREATE INDEX IF NOT EXISTS idx_chat_rooms_appointment_id 
  ON public.chat_rooms (associated_appointment_id) 
  WHERE associated_appointment_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_chat_rooms_type_auto_notifications 
  ON public.chat_rooms (type, auto_notifications) 
  WHERE auto_notifications = true;

-- Indexes for enhanced chat messages
CREATE INDEX IF NOT EXISTS idx_chat_messages_type_superseded 
  ON public.chat_messages (chat_room_id, message_type, superseded_by)
  WHERE message_type = 'appointment_status';

CREATE INDEX IF NOT EXISTS idx_chat_messages_appointment_context 
  ON public.chat_messages USING gin (appointment_context)
  WHERE appointment_context IS NOT NULL;




-- ========================================
-- Comments for Documentation
-- ========================================

-- Grant permissions for the new filtering function
GRANT EXECUTE ON FUNCTION public.get_user_chat_rooms_filtered(UUID, TEXT[], BOOLEAN, TEXT, BOOLEAN, TEXT, INTEGER, INTEGER) TO authenticated, anon, service_role;

COMMENT ON FUNCTION public.create_appointment_chat_room(UUID, UUID, UUID, TEXT, TIMESTAMPTZ) IS 
'Creates a specialized appointment booking chat room with metadata and auto-notifications enabled.';

COMMENT ON FUNCTION public.get_or_create_appointment_chat(UUID, UUID, UUID, TEXT, TIMESTAMPTZ) IS 
'Gets existing appointment chat room or creates new one. Safe for repeated calls.';

COMMENT ON FUNCTION public.create_or_update_appointment_message(UUID, UUID, UUID, TEXT, TEXT, JSONB, JSONB) IS 
'Creates new appointment status message and marks previous one as superseded. Implements living message system.';

COMMENT ON FUNCTION public.get_active_chat_messages(UUID, INTEGER, TIMESTAMPTZ) IS 
'Enhanced chat message retrieval that properly handles superseded messages and new message types.';

COMMENT ON FUNCTION public.get_current_appointment_message(UUID) IS 
'Gets the current active appointment status message for a specific appointment.';

COMMENT ON FUNCTION public.get_chat_messages_with_reactions(UUID, INTEGER, TIMESTAMPTZ, TIMESTAMPTZ, UUID) IS 
'Enhanced chat message retrieval with reactions, action buttons, message types, and appointment context support.';

COMMENT ON FUNCTION public.get_user_chat_rooms_filtered(UUID, TEXT[], BOOLEAN, TEXT, BOOLEAN, TEXT, INTEGER, INTEGER) IS 
'Flexible chat room filtering function that can filter by chat type, appointment status, unread messages, and search text. Includes appointment context and specialized chat fields.'; 


COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
