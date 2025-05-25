# Specialized Chat Channels Architecture

## Overview

Instead of cluttering general chat rooms with appointment notifications, we create **specialized chat room types** for different categories of interactions. Each type has its own purpose, UI/UX, and behavior patterns.

## Enhanced Chat Room Type System

### 1. Extended Chat Type Enum

```sql
-- Extend the existing chat_type_enum
ALTER TYPE public.chat_type_enum ADD VALUE 'appointment_booking';
ALTER TYPE public.chat_type_enum ADD VALUE 'event_notification';
ALTER TYPE public.chat_type_enum ADD VALUE 'service_updates';
ALTER TYPE public.chat_type_enum ADD VALUE 'booking_support';
ALTER TYPE public.chat_type_enum ADD VALUE 'transaction_channel';
-- Note: PostgreSQL doesn't allow direct modification, so we'll need a migration approach
```

**Better Migration Approach:**

```sql
-- Create new enum with all values
CREATE TYPE public.chat_type_enum_new AS ENUM (
    'private',           -- General 1:1 conversations
    'group',            -- Multi-user conversations
    'broadcast',        -- One-to-many announcements
    'appointment_booking', -- Dedicated appointment communications
    'event_notification', -- Event-related updates and discussions
    'service_updates',     -- Ongoing service communications
    'booking_support',     -- Help and support for specific bookings
    'transaction_channel'  -- Payment and transaction-related communications
);

-- Migration script to update existing data and replace enum
-- (Full migration strategy detailed below)
```

### 2. Specialized Channel Purposes

#### A. `appointment_booking` Channels

**Purpose**: Dedicated space for all appointment-related communications

- Appointment requests and approvals
- Payment processing and confirmations
- Rescheduling and cancellations
- Pre-appointment reminders
- Meeting links and instructions

**Benefits**:

- Clean separation from general chat
- Purpose-built UI for appointment actions
- Easy filtering and management
- Automated lifecycle management

#### B. `event_notification` Channels

**Purpose**: Event-specific communication hub

- Event announcements and updates
- Registration confirmations
- Event reminders (24h, 1h before)
- Live event links and access
- Post-event follow-ups

#### C. `service_updates` Channels

**Purpose**: Ongoing service relationship management

- Service updates and improvements
- Usage statistics and insights
- Renewal reminders
- Feedback requests
- Service-specific announcements

#### D. `booking_support` Channels

**Purpose**: Help and assistance for specific bookings

- Technical support for bookings
- Troubleshooting assistance
- Booking modifications
- Cancellation support
- Refund processes

#### E. `transaction_channel` Channels

**Purpose**: Financial transaction communications

- Payment confirmations
- Invoice delivery
- Refund notifications
- Payment method updates
- Billing support

### 3. Enhanced Database Schema

```sql
-- Add channel-specific metadata to chat_rooms
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS channel_config JSONB DEFAULT '{}'::JSONB;
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS auto_archive_after INTERVAL;
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS is_system_managed BOOLEAN DEFAULT FALSE;

-- Index for efficient filtering by type
CREATE INDEX IF NOT EXISTS idx_chat_rooms_type_active ON chat_rooms(type) WHERE archived_at IS NULL;

-- Enhanced appointment chat messages tracking
CREATE TABLE IF NOT EXISTS specialized_chat_channels (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  channel_type TEXT NOT NULL, -- maps to chat_type_enum values
  reference_id UUID NOT NULL, -- appointment_id, event_id, service_id, etc.
  reference_type TEXT NOT NULL, -- 'appointment', 'event', 'service', etc.
  auto_managed BOOLEAN DEFAULT TRUE,
  lifecycle_config JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(channel_type, reference_id, reference_type)
);

CREATE INDEX idx_specialized_channels_reference ON specialized_chat_channels(reference_type, reference_id);
CREATE INDEX idx_specialized_channels_type ON specialized_chat_channels(channel_type);
```

### 4. Channel Management Functions

#### A. Specialized Channel Creator

```sql
CREATE OR REPLACE FUNCTION create_specialized_chat_channel(
  p_channel_type TEXT,
  p_reference_id UUID,
  p_reference_type TEXT,
  p_participant_ids UUID[],
  p_channel_name TEXT,
  p_created_by UUID,
  p_config JSONB DEFAULT '{}'::JSONB
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_chat_room_id UUID;
  v_participant_id UUID;
  v_auto_archive_interval INTERVAL;
BEGIN
  -- Validate channel type
  IF p_channel_type NOT IN ('appointment_booking', 'event_notification', 'service_updates', 'booking_support', 'transaction_channel') THEN
    RAISE EXCEPTION 'Invalid specialized channel type: %', p_channel_type;
  END IF;

  -- Set auto-archive based on channel type
  v_auto_archive_interval := CASE p_channel_type
    WHEN 'appointment_booking' THEN INTERVAL '30 days'
    WHEN 'event_notification' THEN INTERVAL '7 days'
    WHEN 'transaction_channel' THEN INTERVAL '90 days'
    WHEN 'booking_support' THEN INTERVAL '60 days'
    ELSE INTERVAL '30 days'
  END;

  -- Create the specialized chat room
  INSERT INTO chat_rooms (
    name,
    type,
    created_by,
    channel_config,
    auto_archive_after,
    is_system_managed
  ) VALUES (
    p_channel_name,
    p_channel_type::chat_type_enum,
    p_created_by,
    p_config,
    v_auto_archive_interval,
    TRUE
  ) RETURNING id INTO v_chat_room_id;

  -- Add participants
  FOREACH v_participant_id IN ARRAY p_participant_ids
  LOOP
    INSERT INTO chat_participants (chat_room_id, user_id)
    VALUES (v_chat_room_id, v_participant_id)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
  END LOOP;

  -- Register the specialized channel
  INSERT INTO specialized_chat_channels (
    chat_room_id,
    channel_type,
    reference_id,
    reference_type,
    lifecycle_config
  ) VALUES (
    v_chat_room_id,
    p_channel_type,
    p_reference_id,
    p_reference_type,
    p_config
  );

  RETURN v_chat_room_id;
END;
$$;
```

#### B. Appointment Booking Channel Manager

```sql
CREATE OR REPLACE FUNCTION get_or_create_appointment_channel(
  p_appointment_id UUID
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_chat_room_id UUID;
  v_appointment_record RECORD;
  v_channel_name TEXT;
  v_participants UUID[];
  v_config JSONB;
BEGIN
  -- Check if channel already exists
  SELECT scc.chat_room_id INTO v_chat_room_id
  FROM specialized_chat_channels scc
  WHERE scc.reference_id = p_appointment_id
    AND scc.reference_type = 'appointment'
    AND scc.channel_type = 'appointment_booking';

  IF v_chat_room_id IS NOT NULL THEN
    RETURN v_chat_room_id;
  END IF;

  -- Get appointment details
  SELECT
    ap.*,
    p.user_id as client_id,
    p.owner_id as provider_id,
    COALESCE(posts.title, 'Service') as service_name,
    COALESCE(pr_client.full_name, 'Client') as client_name,
    COALESCE(pr_provider.full_name, 'Provider') as provider_name
  INTO v_appointment_record
  FROM appointment_purchases ap
  JOIN purchases p ON ap.purchase_id = p.id
  JOIN services s ON ap.service_id = s.id
  LEFT JOIN posts ON s.post_id = posts.id
  LEFT JOIN profiles pr_client ON p.user_id = pr_client.id
  LEFT JOIN profiles pr_provider ON p.owner_id = pr_provider.id
  WHERE ap.id = p_appointment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Appointment not found: %', p_appointment_id;
  END IF;

  -- Build channel name and config
  v_channel_name := '📅 ' || v_appointment_record.service_name || ' - ' ||
                    to_char(v_appointment_record.appointment_date, 'DD Mon YYYY HH12:MI AM');

  v_participants := ARRAY[v_appointment_record.client_id, v_appointment_record.provider_id];

  v_config := jsonb_build_object(
    'appointment_date', v_appointment_record.appointment_date,
    'service_name', v_appointment_record.service_name,
    'appointment_method', v_appointment_record.method,
    'auto_reminders', TRUE,
    'reminder_schedule', jsonb_build_array('24 hours', '1 hour', '15 minutes')
  );

  -- Create the specialized channel
  v_chat_room_id := create_specialized_chat_channel(
    'appointment_booking',
    p_appointment_id,
    'appointment',
    v_participants,
    v_channel_name,
    v_appointment_record.provider_id,
    v_config
  );

  RETURN v_chat_room_id;
END;
$$;
```

### 5. Enhanced Message Management

#### A. Channel-Aware Message Creation

```sql
CREATE OR REPLACE FUNCTION create_specialized_channel_message(
  p_channel_type TEXT,
  p_reference_id UUID,
  p_sender_id UUID,
  p_content TEXT,
  p_actions JSONB DEFAULT '[]'::JSONB,
  p_message_subtype TEXT DEFAULT 'update',
  p_metadata JSONB DEFAULT '{}'::JSONB
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_chat_room_id UUID;
  v_message_id UUID;
  v_formatted_content TEXT;
  v_action JSONB;
  v_action_buttons TEXT := '';
BEGIN
  -- Get the channel for this reference
  SELECT scc.chat_room_id INTO v_chat_room_id
  FROM specialized_chat_channels scc
  WHERE scc.channel_type = p_channel_type
    AND scc.reference_id = p_reference_id;

  IF v_chat_room_id IS NULL THEN
    RAISE EXCEPTION 'No % channel found for reference %', p_channel_type, p_reference_id;
  END IF;

  -- Format action buttons
  FOR v_action IN SELECT * FROM jsonb_array_elements(p_actions)
  LOOP
    IF v_action->>'url' IS NOT NULL THEN
      v_action_buttons := v_action_buttons || E'\n[' || (v_action->>'label') || '](' || (v_action->>'url') || '){button}';
    ELSE
      v_action_buttons := v_action_buttons || E'\n[' || (v_action->>'label') || '](#action:' || (v_action->>'type') || '){button}';
    END IF;
  END LOOP;

  v_formatted_content := p_content || v_action_buttons;

  -- Create the message
  INSERT INTO chat_messages (
    chat_room_id,
    sender_id,
    message,
    status,
    message_type,
    metadata
  ) VALUES (
    v_chat_room_id,
    p_sender_id,
    v_formatted_content,
    'delivered',
    p_channel_type || '_' || p_message_subtype,
    p_metadata || jsonb_build_object(
      'channel_type', p_channel_type,
      'reference_id', p_reference_id,
      'actions', p_actions
    )
  ) RETURNING id INTO v_message_id;

  RETURN v_message_id;
END;
$$;
```

### 6. Lifecycle Management

#### A. Channel Auto-Management

```sql
CREATE OR REPLACE FUNCTION manage_specialized_channel_lifecycle()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_channel_record RECORD;
  v_should_archive BOOLEAN := FALSE;
  v_archive_reason TEXT;
BEGIN
  -- Only process appointment channels for now
  IF TG_TABLE_NAME != 'appointment_purchases' THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Get channel info
  SELECT scc.*, cr.name as channel_name
  INTO v_channel_record
  FROM specialized_chat_channels scc
  JOIN chat_rooms cr ON scc.chat_room_id = cr.id
  WHERE scc.reference_id = COALESCE(NEW.id, OLD.id)
    AND scc.reference_type = 'appointment'
    AND scc.channel_type = 'appointment_booking';

  IF NOT FOUND THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Determine if channel should be archived based on appointment status
  IF TG_OP = 'UPDATE' AND NEW.status != OLD.status THEN
    CASE NEW.status
      WHEN 'cancelled' THEN
        v_should_archive := TRUE;
        v_archive_reason := 'Appointment cancelled';
      WHEN 'completed' THEN
        -- Archive after 7 days for completed appointments
        UPDATE chat_rooms
        SET auto_archive_after = INTERVAL '7 days',
            channel_config = channel_config || jsonb_build_object('auto_archive_reason', 'Appointment completed')
        WHERE id = v_channel_record.chat_room_id;
      WHEN 'no_show' THEN
        v_should_archive := TRUE;
        v_archive_reason := 'Appointment no-show';
    END CASE;
  END IF;

  -- Archive channel if needed
  IF v_should_archive THEN
    UPDATE chat_rooms
    SET
      archived_at = NOW(),
      channel_config = channel_config || jsonb_build_object('archive_reason', v_archive_reason)
    WHERE id = v_channel_record.chat_room_id;

    -- Send final message
    INSERT INTO chat_messages (
      chat_room_id,
      sender_id,
      message,
      status,
      message_type
    ) VALUES (
      v_channel_record.chat_room_id,
      NULL, -- System message
      '📋 This appointment channel has been archived: ' || v_archive_reason,
      'delivered',
      'system_archive'
    );
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Create trigger for appointment lifecycle management
CREATE TRIGGER specialized_channel_lifecycle_trigger
  AFTER UPDATE ON appointment_purchases
  FOR EACH ROW
  EXECUTE FUNCTION manage_specialized_channel_lifecycle();
```

### 7. Frontend Integration Benefits

#### A. Type-Based UI Rendering

```typescript
// Frontend can render different UIs based on channel type
interface ChatChannelProps {
  channelType: "appointment_booking" | "event_notification" | "service_updates";
  channelData: any;
}

// Appointment booking channels get specialized UI:
// - Calendar integration
// - Payment buttons
// - Meeting join buttons
// - Rescheduling interface

// Event channels get:
// - Event countdown
// - Attendance tracking
// - Live stream integration

// Service channels get:
// - Usage metrics
// - Renewal reminders
// - Feedback collection
```

#### B. Smart Notifications

```typescript
// Different notification strategies per channel type
const notificationConfig = {
  appointment_booking: {
    priority: "high",
    channels: ["push", "email", "sms"],
    schedule: ["24h", "1h", "15min"],
  },
  event_notification: {
    priority: "medium",
    channels: ["push", "email"],
    schedule: ["24h", "1h"],
  },
  service_updates: {
    priority: "low",
    channels: ["in_app"],
    batching: true,
  },
};
```

### 8. Migration Strategy

#### Phase 1: Extend Type System

1. Create new enum with additional values
2. Add new columns to chat_rooms table
3. Create specialized_chat_channels table

#### Phase 2: Gradual Migration

1. New appointments use specialized channels
2. Existing appointments continue with current system
3. Optional migration tool for existing data

#### Phase 3: Enhanced Features

1. Lifecycle management triggers
2. Auto-archiving system
3. Channel-specific UI components

### 9. Benefits of This Approach

#### User Experience

- **Clean Organization**: Different types of communications are separated
- **Purpose-Built UI**: Each channel type gets optimized interface
- **Reduced Noise**: No mixing of appointment actions with general chat
- **Contextual Actions**: Channel-appropriate buttons and features

#### Technical Benefits

- **Scalability**: Easy to add new channel types
- **Maintainability**: Clear separation of concerns
- **Performance**: Efficient filtering and querying by type
- **Flexibility**: Each channel can have different rules and behavior

#### Business Benefits

- **Analytics**: Better tracking of different interaction types
- **Automation**: Channel-specific automation and workflows
- **Support**: Easier to provide targeted support for different channels
- **Compliance**: Different retention and archiving rules per channel type

This approach transforms your chat system into a **multi-purpose communication platform** where each type of interaction gets its own optimized space and behavior!
