# Appointment Notification System Redesign

## Overview

This document outlines a comprehensive redesign of the appointment notification and chat message system to address the core issues of message accumulation, outdated actions, and duplicate notifications.

## Core Problems Solved

1. **Message Accumulation**: Replace multiple messages with single evolving message
2. **Outdated Actions**: Remove obsolete payment links and actions automatically
3. **Duplicate Notifications**: Unified system prevents notification/chat conflicts
4. **Maintainability**: Clean separation of concerns with reusable components
5. **User Experience**: Clean, current, actionable communications

## Solution Architecture

### 1. Living Appointment Messages

**Concept**: Each appointment has exactly ONE active message in chat that evolves with appointment status.

**Benefits**:

- Clean chat interface
- Always current actions
- Clear communication flow
- No confusion about which action to take

### 2. Database Schema Additions

```sql
-- New table to track active appointment messages
CREATE TABLE appointment_chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID NOT NULL REFERENCES appointment_purchases(id) ON DELETE CASCADE,
  chat_room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  current_message_id UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(appointment_id, chat_room_id)
);

-- Add metadata to chat_messages for better tracking
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS appointment_id UUID REFERENCES appointment_purchases(id) ON DELETE CASCADE;
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'general';
```

### 3. Reusable Functions Library

#### A. Message Template Generator

```sql
CREATE OR REPLACE FUNCTION generate_appointment_message_content(
  p_appointment_id UUID,
  p_recipient_type TEXT -- 'client' or 'provider'
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_message_content TEXT;
  v_actions JSONB := '[]'::JSONB;
  v_metadata JSONB;
BEGIN
  -- Get comprehensive appointment details
  SELECT
    ap.*,
    p.user_id as client_id,
    p.owner_id as provider_id,
    s.type as service_type,
    COALESCE(posts.title, 'Service') as service_name,
    COALESCE(pr_client.full_name, 'Client') as client_name,
    COALESCE(pr_provider.full_name, 'Provider') as provider_name,
    p.amount,
    p.payment_status
  INTO v_appointment
  FROM appointment_purchases ap
  JOIN purchases p ON ap.purchase_id = p.id
  JOIN services s ON ap.service_id = s.id
  LEFT JOIN posts ON s.post_id = posts.id
  LEFT JOIN profiles pr_client ON p.user_id = pr_client.id
  LEFT JOIN profiles pr_provider ON p.owner_id = pr_provider.id
  WHERE ap.id = p_appointment_id;

  -- Generate status-specific content and actions
  CASE v_appointment.status
    WHEN 'pending_approval' THEN
      IF p_recipient_type = 'provider' THEN
        v_message_content := '🗓️ **New Appointment Request**' || E'\n\n' ||
                           v_appointment.client_name || ' has requested a ' || v_appointment.service_name ||
                           ' appointment for ' || to_char(v_appointment.appointment_date, 'FMDay, DD Mon YYYY at HH12:MI AM') ||
                           CASE WHEN v_appointment.notes IS NOT NULL THEN E'\n\n**Notes**: ' || v_appointment.notes ELSE '' END;

        v_actions := jsonb_build_array(
          jsonb_build_object('type', 'approve', 'label', 'Approve & Set Price', 'style', 'primary'),
          jsonb_build_object('type', 'reject', 'label', 'Decline', 'style', 'secondary'),
          jsonb_build_object('type', 'suggest', 'label', 'Suggest Different Time', 'style', 'secondary')
        );
      ELSE
        v_message_content := '⏳ **Appointment Request Submitted**' || E'\n\n' ||
                           'Your request for ' || v_appointment.service_name ||
                           ' on ' || to_char(v_appointment.appointment_date, 'FMDay, DD Mon YYYY at HH12:MI AM') ||
                           ' has been sent to ' || v_appointment.provider_name || E'\n\n' ||
                           '⏱️ Waiting for approval...';
        v_actions := '[]'::JSONB; -- No actions for client at this stage
      END IF;

    WHEN 'pending_payment', 'pending_auto_payment' THEN
      IF p_recipient_type = 'client' THEN
        v_message_content := '✅ **Appointment Approved**' || E'\n\n' ||
                           'Your appointment with ' || v_appointment.provider_name ||
                           ' for ' || to_char(v_appointment.appointment_date, 'FMDay, DD Mon YYYY at HH12:MI AM') ||
                           ' has been approved!' || E'\n\n' ||
                           '💳 **Price**: £' || v_appointment.amount || E'\n\n' ||
                           'Complete payment to confirm your booking.';

        v_actions := jsonb_build_array(
          jsonb_build_object(
            'type', 'payment',
            'label', 'Complete Payment (£' || v_appointment.amount || ')',
            'url', COALESCE(v_appointment.payment_link, '/checkout/appointment/' || v_appointment.id),
            'style', 'primary'
          ),
          jsonb_build_object('type', 'cancel', 'label', 'Cancel Request', 'style', 'danger')
        );
      ELSE
        v_message_content := '💰 **Appointment Approved**' || E'\n\n' ||
                           'You approved the appointment with ' || v_appointment.client_name ||
                           ' for ' || to_char(v_appointment.appointment_date, 'FMDay, DD Mon YYYY at HH12:MI AM') ||
                           E'\n\n' || '⏳ Waiting for payment...';
        v_actions := '[]'::JSONB;
      END IF;

    WHEN 'confirmed' THEN
      v_message_content := '🎉 **Appointment Confirmed**' || E'\n\n' ||
                         'Appointment between ' || v_appointment.client_name || ' and ' || v_appointment.provider_name || E'\n' ||
                         '📅 ' || to_char(v_appointment.appointment_date, 'FMDay, DD Mon YYYY at HH12:MI AM') || E'\n' ||
                         '💰 £' || v_appointment.amount || ' - Paid';

      -- Add method-specific actions
      IF v_appointment.method = 'video' THEN
        v_actions := jsonb_build_array(
          jsonb_build_object('type', 'join', 'label', 'Join Video Call', 'url', '/meeting/' || v_appointment.id, 'style', 'primary'),
          jsonb_build_object('type', 'reschedule', 'label', 'Request Reschedule', 'style', 'secondary')
        );
      ELSE
        v_actions := jsonb_build_array(
          jsonb_build_object('type', 'details', 'label', 'View Details', 'url', '/appointments/' || v_appointment.id, 'style', 'primary'),
          jsonb_build_object('type', 'reschedule', 'label', 'Request Reschedule', 'style', 'secondary')
        );
      END IF;

    WHEN 'cancelled' THEN
      v_message_content := '❌ **Appointment Cancelled**' || E'\n\n' ||
                         'The appointment for ' || to_char(v_appointment.appointment_date, 'FMDay, DD Mon YYYY at HH12:MI AM') ||
                         ' has been cancelled.' ||
                         CASE WHEN v_appointment.provider_notes IS NOT NULL THEN E'\n\n**Reason**: ' || v_appointment.provider_notes ELSE '' END;
      v_actions := '[]'::JSONB;

    WHEN 'completed' THEN
      v_message_content := '✅ **Appointment Completed**' || E'\n\n' ||
                         'The appointment on ' || to_char(v_appointment.appointment_date, 'FMDay, DD Mon YYYY at HH12:MI AM') ||
                         ' has been completed.' || E'\n\n' ||
                         'Thank you!';

      v_actions := jsonb_build_array(
        jsonb_build_object('type', 'feedback', 'label', 'Leave Feedback', 'url', '/feedback/' || v_appointment.id, 'style', 'secondary'),
        jsonb_build_object('type', 'book_again', 'label', 'Book Again', 'url', '/book/' || v_appointment.service_id, 'style', 'primary')
      );

    ELSE
      v_message_content := 'Appointment status: ' || v_appointment.status;
      v_actions := '[]'::JSONB;
  END CASE;

  -- Build metadata
  v_metadata := jsonb_build_object(
    'appointment_id', v_appointment.id,
    'status', v_appointment.status,
    'appointment_date', v_appointment.appointment_date,
    'service_name', v_appointment.service_name,
    'amount', v_appointment.amount,
    'recipient_type', p_recipient_type
  );

  RETURN jsonb_build_object(
    'content', v_message_content,
    'actions', v_actions,
    'metadata', v_metadata
  );
END;
$$;
```

#### B. Message Replacement Manager

```sql
CREATE OR REPLACE FUNCTION update_appointment_chat_message(
  p_appointment_id UUID,
  p_chat_room_id UUID,
  p_sender_id UUID,
  p_recipient_type TEXT
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_message_data JSONB;
  v_formatted_message TEXT;
  v_new_message_id UUID;
  v_current_message_id UUID;
  v_action_buttons TEXT := '';
  v_action JSONB;
BEGIN
  -- Generate message content
  v_message_data := generate_appointment_message_content(p_appointment_id, p_recipient_type);

  -- Format actions as buttons
  FOR v_action IN SELECT * FROM jsonb_array_elements(v_message_data->'actions')
  LOOP
    IF v_action->>'url' IS NOT NULL THEN
      v_action_buttons := v_action_buttons || E'\n[' || (v_action->>'label') || '](' || (v_action->>'url') || '){button}';
    ELSE
      v_action_buttons := v_action_buttons || E'\n[' || (v_action->>'label') || '](#action:' || (v_action->>'type') || '){button}';
    END IF;
  END LOOP;

  v_formatted_message := (v_message_data->>'content') || v_action_buttons;

  -- Check if there's an existing message to replace
  SELECT current_message_id INTO v_current_message_id
  FROM appointment_chat_messages
  WHERE appointment_id = p_appointment_id AND chat_room_id = p_chat_room_id;

  IF v_current_message_id IS NOT NULL THEN
    -- Replace existing message
    UPDATE chat_messages
    SET
      message = v_formatted_message,
      updated_at = NOW(),
      metadata = v_message_data->'metadata'
    WHERE id = v_current_message_id
    RETURNING id INTO v_new_message_id;

    v_new_message_id := v_current_message_id;
  ELSE
    -- Create new message
    INSERT INTO chat_messages (
      chat_room_id,
      sender_id,
      message,
      status,
      appointment_id,
      message_type,
      metadata
    ) VALUES (
      p_chat_room_id,
      p_sender_id,
      v_formatted_message,
      'delivered',
      p_appointment_id,
      'appointment_status',
      v_message_data->'metadata'
    ) RETURNING id INTO v_new_message_id;

    -- Track this as the active appointment message
    INSERT INTO appointment_chat_messages (
      appointment_id,
      chat_room_id,
      current_message_id
    ) VALUES (
      p_appointment_id,
      p_chat_room_id,
      v_new_message_id
    ) ON CONFLICT (appointment_id, chat_room_id)
    DO UPDATE SET
      current_message_id = v_new_message_id,
      updated_at = NOW();
  END IF;

  RETURN v_new_message_id;
END;
$$;
```

#### C. Notification Cleanup Manager

```sql
CREATE OR REPLACE FUNCTION cleanup_obsolete_appointment_notifications(
  p_appointment_id UUID,
  p_user_id UUID,
  p_new_status TEXT
) RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_obsolete_types TEXT[];
  v_deleted_count INTEGER := 0;
BEGIN
  -- Define which notification types become obsolete for each status
  CASE p_new_status
    WHEN 'confirmed' THEN
      v_obsolete_types := ARRAY['payment']; -- Remove payment notifications when confirmed
    WHEN 'cancelled' THEN
      v_obsolete_types := ARRAY['payment', 'reminder']; -- Remove payment and reminder notifications
    WHEN 'completed' THEN
      v_obsolete_types := ARRAY['payment', 'reminder', 'appointment']; -- Clean up most notifications
    ELSE
      v_obsolete_types := ARRAY[]::TEXT[];
  END CASE;

  -- Mark obsolete notifications as read and delete if configured
  UPDATE notifications
  SET
    is_read = TRUE,
    metadata = metadata || jsonb_build_object('obsoleted_by_status', p_new_status, 'obsoleted_at', NOW())
  WHERE
    user_id = p_user_id
    AND reference_id = p_appointment_id
    AND reference_type = 'appointment'
    AND type = ANY(v_obsolete_types)
    AND is_read = FALSE;

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  RETURN v_deleted_count;
END;
$$;
```

### 4. Enhanced Trigger System

```sql
CREATE OR REPLACE FUNCTION handle_appointment_notifications_v2()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_purchase_record RECORD;
  v_chat_room_id UUID;
  v_client_message_id UUID;
  v_provider_message_id UUID;
  v_cleanup_count INTEGER;
BEGIN
  -- Get appointment context
  SELECT
    p.*,
    COALESCE(pr_client.full_name, 'Unknown Client') as client_name,
    COALESCE(pr_provider.full_name, 'Unknown Provider') as provider_name
  INTO v_purchase_record
  FROM purchases p
  LEFT JOIN profiles pr_client ON p.user_id = pr_client.id
  LEFT JOIN profiles pr_provider ON p.owner_id = pr_provider.id
  WHERE p.id = NEW.purchase_id;

  -- Find or create chat room
  v_chat_room_id := get_or_create_appointment_chat_room(NEW.id, v_purchase_record.user_id, v_purchase_record.owner_id);

  -- Update chat messages for both participants
  v_client_message_id := update_appointment_chat_message(
    NEW.id,
    v_chat_room_id,
    v_purchase_record.owner_id, -- Provider sends to client
    'client'
  );

  v_provider_message_id := update_appointment_chat_message(
    NEW.id,
    v_chat_room_id,
    v_purchase_record.user_id, -- Client context for provider
    'provider'
  );

  -- Clean up obsolete notifications
  v_cleanup_count := cleanup_obsolete_appointment_notifications(
    NEW.id,
    v_purchase_record.user_id,
    NEW.status::TEXT
  );

  v_cleanup_count := v_cleanup_count + cleanup_obsolete_appointment_notifications(
    NEW.id,
    v_purchase_record.owner_id,
    NEW.status::TEXT
  );

  -- Send standard notifications based on user preferences (outside chat)
  PERFORM send_appointment_notification_channels(NEW.id, TG_OP, OLD.status, NEW.status);

  -- Log the update
  PERFORM pg_notify('appointment_chat_updated',
    jsonb_build_object(
      'appointment_id', NEW.id,
      'chat_room_id', v_chat_room_id,
      'status', NEW.status,
      'client_message_id', v_client_message_id,
      'provider_message_id', v_provider_message_id,
      'cleanup_count', v_cleanup_count
    )::text
  );

  RETURN NEW;
END;
$$;
```

### 5. Chat Room Management

```sql
CREATE OR REPLACE FUNCTION get_or_create_appointment_chat_room(
  p_appointment_id UUID,
  p_client_id UUID,
  p_provider_id UUID
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_chat_room_id UUID;
  v_room_name TEXT;
  v_appointment_date TIMESTAMPTZ;
  v_service_name TEXT;
BEGIN
  -- Get appointment details for room naming
  SELECT
    ap.appointment_date,
    COALESCE(posts.title, 'Service')
  INTO v_appointment_date, v_service_name
  FROM appointment_purchases ap
  JOIN services s ON ap.service_id = s.id
  LEFT JOIN posts ON s.post_id = posts.id
  WHERE ap.id = p_appointment_id;

  -- Look for existing private room between these users
  WITH room_participants AS (
    SELECT
      cr.id as room_id,
      COUNT(*) as participant_count,
      SUM(CASE WHEN cp.user_id IN (p_client_id, p_provider_id) THEN 1 ELSE 0 END) as target_users_count
    FROM
      chat_rooms cr
      JOIN chat_participants cp ON cr.id = cp.chat_room_id
    WHERE
      cr.type = 'private'
    GROUP BY
      cr.id
  )
  SELECT room_id INTO v_chat_room_id
  FROM room_participants
  WHERE
    participant_count = 2 AND
    target_users_count = 2;

  -- Create room if it doesn't exist
  IF v_chat_room_id IS NULL THEN
    v_room_name := v_service_name || ' - ' || to_char(v_appointment_date, 'DD Mon YYYY HH12:MI AM');

    INSERT INTO chat_rooms (name, type, created_by)
    VALUES (v_room_name, 'private', p_provider_id)
    RETURNING id INTO v_chat_room_id;

    INSERT INTO chat_participants (chat_room_id, user_id)
    VALUES
      (v_chat_room_id, p_client_id),
      (v_chat_room_id, p_provider_id)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
  END IF;

  RETURN v_chat_room_id;
END;
$$;
```

### 6. Implementation Benefits

#### Maintainability

- **Single Responsibility**: Each function has one clear purpose
- **Reusable Components**: Message generation, cleanup, room management all modular
- **Clear Separation**: Business logic separate from notification logic
- **Easy Testing**: Functions can be tested independently

#### User Experience

- **Clean Interface**: One current message per appointment
- **Always Accurate**: Actions are always relevant to current status
- **No Confusion**: Clear understanding of what needs to be done
- **Progressive Enhancement**: Message evolves with appointment

#### Technical Benefits

- **Performance**: Fewer database operations (updates vs inserts)
- **Consistency**: Single source of truth for appointment state
- **Scalability**: Efficient message management as system grows
- **Extensibility**: Easy to add new statuses or message types

### 7. Migration Strategy

1. **Phase 1**: Deploy new functions and schema additions
2. **Phase 2**: Update trigger to use new system for new appointments
3. **Phase 3**: Migrate existing appointments (optional cleanup)
4. **Phase 4**: Remove old notification creation code from business functions

### 8. Extensibility

The system is designed to easily support:

- New appointment statuses
- Additional message types (reminders, follow-ups)
- Custom message templates per service
- Multi-language support
- Rich media in messages (images, attachments)
- Custom action handlers

This architecture transforms the current "accumulation" model into a "living document" model where each appointment maintains its current state clearly and actionably.
