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
-- Appointment Status Message Builder
-- ========================================

-- Function to build action buttons based on appointment status
CREATE OR REPLACE FUNCTION public.build_appointment_action_buttons(
  p_status TEXT,
  p_appointment_id UUID,
  p_payment_url TEXT DEFAULT NULL,
  p_meeting_url TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_buttons JSONB := '[]';
BEGIN
  CASE p_status
    WHEN 'pending_approval' THEN
      -- No actions for client during pending approval
      v_buttons := '[]';
      
    WHEN 'pending_payment' THEN
      IF p_payment_url IS NOT NULL THEN
        v_buttons := jsonb_build_array(
          jsonb_build_object(
            'type', 'payment',
            'label', 'Complete Payment',
            'url', p_payment_url,
            'style', 'primary'
          ),
          jsonb_build_object(
            'type', 'cancel',
            'label', 'Cancel Appointment',
            'action', 'cancel_appointment',
            'style', 'danger',
            'confirm', 'Are you sure you want to cancel this appointment?'
          )
        );
      END IF;
      
    WHEN 'confirmed' THEN
      v_buttons := jsonb_build_array(
        jsonb_build_object(
          'type', 'reschedule',
          'label', 'Reschedule',
          'action', 'reschedule_appointment',
          'style', 'secondary'
        ),
        jsonb_build_object(
          'type', 'cancel',
          'label', 'Cancel',
          'action', 'cancel_appointment',
          'style', 'danger',
          'confirm', 'Are you sure you want to cancel this appointment?'
        )
      );
      
      -- Add meeting link if available
      IF p_meeting_url IS NOT NULL THEN
        v_buttons := v_buttons || jsonb_build_array(
          jsonb_build_object(
            'type', 'meeting',
            'label', 'Join Meeting',
            'url', p_meeting_url,
            'style', 'success'
          )
        );
      END IF;
      
    WHEN 'cancelled' THEN
      v_buttons := jsonb_build_array(
        jsonb_build_object(
          'type', 'rebook',
          'label', 'Book Again',
          'action', 'rebook_appointment',
          'style', 'primary'
        )
      );
      
    ELSE
      v_buttons := '[]';
  END CASE;

  RETURN v_buttons;
END $$;

-- Function to build appointment status message content
CREATE OR REPLACE FUNCTION public.build_appointment_message_content(
  p_status TEXT,
  p_service_name TEXT,
  p_appointment_date TIMESTAMPTZ,
  p_client_name TEXT,
  p_owner_name TEXT,
  p_payment_amount NUMERIC DEFAULT NULL
) RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_content TEXT;
  v_date_formatted TEXT := to_char(p_appointment_date, 'Day, DD Month YYYY at HH24:MI');
BEGIN
  CASE p_status
    WHEN 'pending_approval' THEN
      v_content := format(
        '📅 **Appointment Request Submitted**

**Service:** %s
**Date & Time:** %s
**Client:** %s

Your appointment request has been submitted and is awaiting approval from %s. You''ll receive a notification once it''s reviewed.',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        COALESCE(p_client_name, 'Unknown Client'),
        COALESCE(p_owner_name, 'Service Provider')
      );
      
    WHEN 'pending_payment' THEN
      v_content := format(
        '✅ **Appointment Approved - Payment Required**

**Service:** %s
**Date & Time:** %s
**Amount:** %s

Your appointment has been approved! Please complete the payment to confirm your booking.',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        CASE WHEN p_payment_amount IS NOT NULL 
             THEN '$' || p_payment_amount::TEXT 
             ELSE 'TBD' END
      );
      
    WHEN 'confirmed' THEN
      v_content := format(
        '🎉 **Appointment Confirmed**

**Service:** %s
**Date & Time:** %s
**Provider:** %s

Your appointment is confirmed! You''ll receive a reminder before the session.',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        COALESCE(p_owner_name, 'Service Provider')
      );
      
    WHEN 'cancelled' THEN
      v_content := format(
        '❌ **Appointment Cancelled**

**Service:** %s
**Date & Time:** %s

This appointment has been cancelled. You can book a new appointment anytime.',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted
      );
      
    WHEN 'completed' THEN
      v_content := format(
        '✨ **Appointment Completed**

**Service:** %s
**Date & Time:** %s

Thank you for your session! We hope it was valuable for you.',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted
      );
      
    WHEN 'rescheduled' THEN
      v_content := format(
        '🔄 **Appointment Rescheduled**

**Service:** %s
**New Date & Time:** %s

Your appointment has been rescheduled. Please note the new time.',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted
      );
      
    ELSE
      v_content := format(
        '📋 **Appointment Update**

**Service:** %s
**Date & Time:** %s
**Status:** %s',
        COALESCE(p_service_name, 'Unknown Service'),
        v_date_formatted,
        p_status
      );
  END CASE;

  RETURN v_content;
END $$;

-- ========================================
-- Integration Functions
-- ========================================

-- Function to handle appointment status changes and update chat
CREATE OR REPLACE FUNCTION public.update_appointment_chat_message(
  p_appointment_id UUID,
  p_new_status TEXT,
  p_payment_url TEXT DEFAULT NULL,
  p_meeting_url TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_chat_room_id UUID;
  v_service_name TEXT;
  v_appointment_date TIMESTAMPTZ;
  v_client_name TEXT;
  v_owner_name TEXT;
  v_owner_id UUID;
  v_payment_amount NUMERIC;
  v_message_content TEXT;
  v_action_buttons JSONB;
  v_appointment_context JSONB;
  v_message_id UUID;
BEGIN
  -- Get chat room for this appointment
  SELECT cr.id, cr.created_by INTO v_chat_room_id, v_owner_id
  FROM public.chat_rooms cr
  WHERE cr.associated_appointment_id = p_appointment_id
    AND cr.type = 'appointment_booking';

  -- Exit if no chat room exists
  IF v_chat_room_id IS NULL THEN
    RETURN NULL;
  END IF;

  -- Get appointment details
  SELECT 
    s.name,
    ap.requested_date,
    uc.first_name || ' ' || COALESCE(uc.last_name, ''),
    uo.first_name || ' ' || COALESCE(uo.last_name, ''),
    ap.quoted_price
  INTO 
    v_service_name,
    v_appointment_date,
    v_client_name,
    v_owner_name,
    v_payment_amount
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.profiles uc ON ap.client_id = uc.id
  JOIN public.profiles uo ON ap.owner_id = uo.id
  WHERE ap.id = p_appointment_id;

  -- Build message content
  v_message_content := public.build_appointment_message_content(
    p_new_status,
    v_service_name,
    v_appointment_date,
    v_client_name,
    v_owner_name,
    v_payment_amount
  );

  -- Build action buttons
  v_action_buttons := public.build_appointment_action_buttons(
    p_new_status,
    p_appointment_id,
    p_payment_url,
    p_meeting_url
  );

  -- Build appointment context
  v_appointment_context := jsonb_build_object(
    'appointment_id', p_appointment_id,
    'status', p_new_status,
    'service_name', v_service_name,
    'appointment_date', v_appointment_date,
    'payment_url', p_payment_url,
    'meeting_url', p_meeting_url,
    'timestamp', extract(epoch from now())
  );

  -- Create/update living message
  v_message_id := public.create_or_update_appointment_message(
    v_chat_room_id,
    v_owner_id,
    p_appointment_id,
    p_new_status,
    v_message_content,
    v_action_buttons,
    v_appointment_context
  );

  RETURN v_message_id;
END $$;

-- ========================================
-- Enhanced Chat Query Functions
-- ========================================

-- Function to get chat messages with superseded filtering
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

COMMENT ON FUNCTION public.create_appointment_chat_room(UUID, UUID, UUID, TEXT, TIMESTAMPTZ) IS 
'Creates a specialized appointment booking chat room with metadata and auto-notifications enabled.';

COMMENT ON FUNCTION public.get_or_create_appointment_chat(UUID, UUID, UUID, TEXT, TIMESTAMPTZ) IS 
'Gets existing appointment chat room or creates new one. Safe for repeated calls.';

COMMENT ON FUNCTION public.create_or_update_appointment_message(UUID, UUID, UUID, TEXT, TEXT, JSONB, JSONB) IS 
'Creates new appointment status message and marks previous one as superseded. Implements living message system.';

COMMENT ON FUNCTION public.update_appointment_chat_message(UUID, TEXT, TEXT, TEXT) IS 
'Main integration function that updates appointment status in specialized chat room with appropriate actions and content.';

COMMENT ON FUNCTION public.build_appointment_action_buttons(TEXT, UUID, TEXT, TEXT) IS 
'Builds contextual action buttons based on appointment status and available URLs.';

COMMENT ON FUNCTION public.build_appointment_message_content(TEXT, TEXT, TIMESTAMPTZ, TEXT, TEXT, NUMERIC) IS 
'Generates formatted message content for appointment status updates.';

COMMENT ON FUNCTION public.get_active_chat_messages(UUID, INTEGER, TIMESTAMPTZ) IS 
'Enhanced chat message retrieval that properly handles superseded messages and new message types.';

COMMENT ON FUNCTION public.get_current_appointment_message(UUID) IS 
'Gets the current active appointment status message for a specific appointment.'; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
