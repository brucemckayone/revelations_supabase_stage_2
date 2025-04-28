# Chat Feature Technical Requirements

## Overview

This document provides detailed technical specifications for implementing the chat feature within our platform. It serves as a guide for both frontend and backend developers to ensure consistent implementation.

## Database Schema

### chat_rooms

| Field               | Type           | Description                              |
| ------------------- | -------------- | ---------------------------------------- |
| id                  | UUID           | Primary key                              |
| name                | TEXT           | Optional name for group chats            |
| type                | chat_type_enum | 'private', 'group', or 'broadcast'       |
| created_by          | UUID           | Reference to auth.users(id)              |
| created_at          | TIMESTAMPTZ    | Creation timestamp                       |
| updated_at          | TIMESTAMPTZ    | Last activity timestamp                  |
| associated_post_id  | UUID           | Optional reference to posts(id)          |
| associated_event_id | UUID           | Optional reference to events(id)         |
| is_broadcast        | BOOLEAN        | Indicates if room is a broadcast channel |
| description         | TEXT           | Optional description of the chat purpose |

### chat_participants

| Field                | Type        | Description                              |
| -------------------- | ----------- | ---------------------------------------- |
| id                   | UUID        | Primary key                              |
| chat_room_id         | UUID        | Reference to chat_rooms(id)              |
| user_id              | UUID        | Reference to auth.users(id)              |
| joined_at            | TIMESTAMPTZ | When user joined the chat                |
| left_at              | TIMESTAMPTZ | When user left the chat (NULL if active) |
| role                 | TEXT        | 'admin' or 'member'                      |
| is_muted             | BOOLEAN     | Indicates if notifications are muted     |
| last_read_message_id | UUID        | Reference to last message read           |

### chat_messages

| Field               | Type                | Description                               |
| ------------------- | ------------------- | ----------------------------------------- |
| id                  | UUID                | Primary key                               |
| chat_room_id        | UUID                | Reference to chat_rooms(id)               |
| sender_id           | UUID                | Reference to auth.users(id)               |
| message             | TEXT                | Message content                           |
| created_at          | TIMESTAMPTZ         | When message was sent                     |
| status              | message_status_enum | 'delivered', 'read', or 'deleted'         |
| reply_to_message_id | UUID                | Reference to parent message (for threads) |
| is_edited           | BOOLEAN             | Indicates if message was edited           |

### message_read_receipts

| Field      | Type        | Description                    |
| ---------- | ----------- | ------------------------------ |
| id         | UUID        | Primary key                    |
| message_id | UUID        | Reference to chat_messages(id) |
| user_id    | UUID        | Reference to auth.users(id)    |
| read_at    | TIMESTAMPTZ | When message was read          |

## API Endpoints

### Chat Rooms

#### GET /chat/rooms

- Returns all chat rooms the authenticated user is a participant of
- Query params:
  - `limit`: Number of rooms to return (default: 20)
  - `offset`: Pagination offset
  - `type`: Filter by chat type
- Response: Array of chat room objects with latest message

#### POST /chat/rooms

- Creates a new chat room
- Request body:
  ```json
  {
    "name": "string?",
    "type": "private|group|broadcast",
    "participants": ["user_id1", "user_id2"],
    "associated_post_id": "uuid?",
    "associated_event_id": "uuid?",
    "is_broadcast": "boolean?",
    "description": "string?"
  }
  ```
- Response: Created chat room object

#### GET /chat/rooms/:id

- Returns details of a specific chat room
- Response: Chat room object with participants

#### PATCH /chat/rooms/:id

- Updates chat room details
- Request body: Chat room fields to update
- Response: Updated chat room object

#### DELETE /chat/rooms/:id

- Deletes a chat room (only creator can delete)
- Response: Success message

### Participants

#### GET /chat/rooms/:id/participants

- Returns all participants in a chat room
- Response: Array of participant objects

#### POST /chat/rooms/:id/participants

- Adds participants to a chat room
- Request body:
  ```json
  {
    "user_ids": ["user_id1", "user_id2"]
  }
  ```
- Response: Updated participants list

#### DELETE /chat/rooms/:id/participants/:user_id

- Removes a participant from a chat room
- Response: Success message

### Messages

#### GET /chat/rooms/:id/messages

- Returns messages from a chat room
- Query params:
  - `limit`: Number of messages (default: 50)
  - `before`: Get messages before this timestamp
  - `after`: Get messages after this timestamp
  - `around_message_id`: Get messages around this ID
- Response: Array of message objects

#### POST /chat/rooms/:id/messages

- Sends a new message
- Request body:
  ```json
  {
    "message": "string",
    "reply_to_message_id": "uuid?"
  }
  ```
- Response: Created message object

#### PATCH /chat/rooms/:id/messages/:message_id

- Edits a message (only sender can edit)
- Request body:
  ```json
  {
    "message": "string"
  }
  ```
- Response: Updated message object

#### DELETE /chat/rooms/:id/messages/:message_id

- Deletes a message (soft delete)
- Response: Success message

#### POST /chat/rooms/:id/messages/:message_id/read

- Marks a message as read
- Response: Success message

## Realtime Subscriptions

### Channels

#### chat:rooms

- Notifies when user is added to a new chat room
- Payload: Chat room object

#### chat:rooms:{room_id}

- Notifies about room updates (name, description changes)
- Payload: Updated room fields

#### chat:messages:{room_id}

- Notifies about new messages, edits, and deletions
- Payload: Message object with action type ('new', 'edit', 'delete')

#### chat:typing:{room_id}

- Notifies when users are typing
- Payload:
  ```json
  {
    "user_id": "uuid",
    "is_typing": true|false
  }
  ```

#### chat:presence:{room_id}

- Notifies about user presence changes
- Payload:
  ```json
  {
    "user_id": "uuid",
    "status": "online|offline",
    "last_active": "timestamp"
  }
  ```

## Frontend Component Specifications

### ChatList Component

- Displays a list of all chat rooms the user is part of
- Each room displays:
  - Room name or participants' names
  - Last message preview (30 chars max)
  - Timestamp of last message
  - Unread message count
- Sorting: Most recent message first
- Filtering: By chat type
- Actions: Create new chat, enter existing chat

### ChatRoom Component

- Displays messages in a conversation view
- Features:
  - Infinite scroll for message history
  - Message grouping by sender and time proximity
  - Timestamps for message groups
  - Visual indicators for read/delivered messages
  - Thread view for replies
  - Message status indicators

### MessageComposer Component

- Provides interface for composing and sending messages
- Features:
  - Plain text input
  - Send button
  - Reply interface
  - Typing indicator
  - Character counter (if limit applies)

### ChatParticipants Component

- Shows list of participants in current chat
- Features:
  - Online status indicators
  - Admin indicators
  - Actions for admins (remove user, change role)
  - User profile preview on click/hover

## UI/UX Requirements

### Chat List Screen

- Responsive design (mobile-first)
- Sticky header with search and filter options
- Visual distinction between read and unread conversations
- Pull-to-refresh functionality
- Loading states and empty states

### Chat Room Screen

- Message bubbles with different colors for sent/received
- Avatars for group chats
- Date separators between days
- New message indicator when scrolled up
- Smooth scrolling and loading animations
- Context menu for message actions

### Accessibility Requirements

- Keyboard navigation support
- Screen reader compatibility
- Sufficient color contrast
- Focus indicators
- Alternative text for UI elements

## State Management

### Chat Room State

- Active chat rooms list
- Current room details
- Participants in current room
- Message history (paginated)
- Unread message counts
- Typing indicators
- Online presence data

### User Preferences

- Notification settings
- Chat display preferences
- Message history retention
- Auto-load media preference

## Error Handling

### Network Issues

- Offline message queue
- Automatic retry logic
- Visual indicators for message send status
- Reconnection handling

### Edge Cases

- Empty chat rooms
- Long messages
- High message volume
- Permission denied scenarios
- Rate limiting feedback

## Performance Considerations

### Message Loading

- Initial load: 50 most recent messages
- Pagination: 50 messages per request
- Prefetch when approaching end of loaded messages
- Cache loaded messages in memory
- Debounce typing indicator events (300ms)

### Optimizations

- Virtual scrolling for long chat histories
- Lazy loading of older messages
- Batched updates for read receipts
- Throttled presence updates

## Analytics Integration

- Track conversation metrics:
  - Message counts
  - Response times
  - Active participants
  - Session duration
- Event tracking for:
  - Room creation
  - Message sending
  - Feature usage (threads, reactions)
