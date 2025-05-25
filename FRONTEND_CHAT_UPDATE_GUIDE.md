# Frontend Chat System Update Guide

## 🚨 **What's Currently Out of Date**

Based on the current frontend implementation in `utils.ts` and the new specialized chat channels system, here are the **critical updates needed**:

### 1. **Missing Database Schema Fields**

The current `ChatMessage` and `ChatRoom` interfaces are missing all the new specialized fields:

**ChatMessage Interface Missing:**

- `action_buttons: JSONB` - Interactive buttons for payments, meetings, etc.
- `message_type: TEXT` - 'appointment_status', 'regular', etc.
- `superseded_by: UUID` - Tracks message replacements
- `appointment_context: JSONB` - Appointment metadata

**ChatRoom Interface Missing:**

- `associated_appointment_id: UUID` - Links to appointments
- `metadata: JSONB` - Specialized chat configuration
- `auto_notifications: BOOLEAN` - Auto-messaging settings
- `pinned_message_id: UUID` - Current status message

**Chat Type Enum Missing:**

- `'appointment_booking'` - NEW specialized type
- `'event_notification'` - NEW specialized type
- `'service_updates'` - NEW specialized type
- `'booking_support'` - NEW specialized type
- `'transaction_channel'` - NEW specialized type

### 2. **Missing Functions**

Current `utils.ts` doesn't have functions for:

- **Living Message System** - Getting active/superseded messages
- **Appointment Chat Integration** - Specialized appointment chat functions
- **Action Button Handling** - Processing button clicks
- **Enhanced Message Queries** - New `get_active_chat_messages()` function

### 3. **Missing UI Components**

No components exist for:

- **Action Buttons** - Payment, meeting, reschedule buttons
- **Appointment Status Messages** - Specialized message display
- **Living Message Updates** - Handling message supersession
- **Specialized Chat Room Types** - Different UI for appointment chats

---

## 🛠️ **Step-by-Step Update Implementation**

### **Phase 1: Update Type Definitions**

#### 1.1 Update `ChatRoom` Interface

```typescript
// Update in utils.ts or types file
export interface ChatRoom {
  id: string;
  name: string;
  type:
    | "private"
    | "group"
    | "broadcast"
    | "appointment_booking"
    | "event_notification"
    | "service_updates"
    | "booking_support"
    | "transaction_channel";
  is_broadcast: boolean;
  description?: string;

  // NEW FIELDS
  associated_appointment_id?: string;
  metadata?: Record<string, any>;
  auto_notifications?: boolean;
  pinned_message_id?: string;

  last_message?: {
    message: string;
    created_at: string;
    sender_id: string;
  };
  unread_count: number;
  created_at: string;
  updated_at: string;
  participants: {
    user_id: string;
    display_name: string;
    role: "member" | "admin" | "creator";
  }[];
}
```

#### 1.2 Update `ChatMessage` Interface

```typescript
// Update in utils.ts or types file
export interface ActionButton {
  type: "payment" | "meeting" | "reschedule" | "cancel" | "rebook";
  label: string;
  url?: string; // For external links (payment, meeting)
  action?: string; // For internal actions
  style: "primary" | "secondary" | "success" | "danger";
  confirm?: string; // Confirmation message
}

export interface AppointmentContext {
  appointment_id: string;
  status: string;
  service_name?: string;
  appointment_date?: string;
  payment_url?: string;
  meeting_url?: string;
  timestamp: number;
}

export interface ChatMessage {
  id: string;
  chat_room_id: string;
  sender_id: string;
  message: string;
  created_at: string;
  updated_at?: string;
  is_edited: boolean;
  status: "delivered" | "read" | "deleted";
  reply_to_message_id?: string;

  // NEW FIELDS
  message_type?: string;
  action_buttons?: ActionButton[];
  superseded_by?: string;
  appointment_context?: AppointmentContext;
  is_superseded?: boolean;
}
```

### **Phase 2: Update API Functions**

#### 2.1 Replace Message Fetching Function

```typescript
// Replace fetchChatMessages in utils.ts
export const fetchChatMessages = async (
  roomId: string,
  options?: {
    limit?: number;
    before?: string;
    after?: string;
    around_message_id?: string;
    includeSuperseded?: boolean;
  }
): Promise<ChatMessage[]> => {
  // Use new enhanced function that handles superseded messages
  const { data, error } = await supabase.rpc("get_active_chat_messages", {
    p_chat_room_id: roomId,
    p_limit: options?.limit || 50,
    p_before: options?.before || null,
  });

  if (error) {
    console.error("Error fetching messages:", error);
    throw new Error(error.message);
  }

  return data.map((msg: any) => ({
    id: msg.message_id,
    chat_room_id: roomId,
    sender_id: msg.sender_id,
    message: msg.message,
    created_at: msg.created_at,
    is_edited: false, // Updated function should include this
    status: msg.status,
    reply_to_message_id: msg.reply_to_message_id,
    message_type: msg.message_type,
    action_buttons: msg.action_buttons,
    appointment_context: msg.appointment_context,
    is_superseded: msg.is_superseded,
  }));
};
```

#### 2.2 Add Appointment Chat Functions

```typescript
// Add to utils.ts
export const getAppointmentChat = async (
  appointmentId: string
): Promise<string | null> => {
  const { data, error } = await supabase
    .from("chat_rooms")
    .select("id")
    .eq("associated_appointment_id", appointmentId)
    .eq("type", "appointment_booking")
    .single();

  if (error) {
    console.error("Error fetching appointment chat:", error);
    return null;
  }

  return data?.id || null;
};

export const getCurrentAppointmentMessage = async (
  appointmentId: string
): Promise<ChatMessage | null> => {
  const { data, error } = await supabase.rpc(
    "get_current_appointment_message",
    {
      p_appointment_id: appointmentId,
    }
  );

  if (error || !data || data.length === 0) {
    console.error("Error fetching current appointment message:", error);
    return null;
  }

  const msg = data[0];
  return {
    id: msg.message_id,
    chat_room_id: msg.chat_room_id,
    sender_id: "", // Not needed for display
    message: msg.message_content,
    created_at: msg.created_at,
    is_edited: false,
    status: "delivered",
    message_type: "appointment_status",
    action_buttons: msg.action_buttons,
    appointment_context: msg.appointment_context,
  };
};
```

#### 2.3 Add Action Button Handler

```typescript
// Add to utils.ts
export const handleActionButton = async (
  button: ActionButton,
  appointmentId: string
): Promise<void> => {
  switch (button.type) {
    case "payment":
      if (button.url) {
        window.open(button.url, "_blank");
      }
      break;

    case "meeting":
      if (button.url) {
        window.open(button.url, "_blank");
      }
      break;

    case "cancel":
      if (button.confirm && !confirm(button.confirm)) {
        return;
      }
      // Call appointment cancellation API
      await cancelAppointment(appointmentId);
      break;

    case "reschedule":
      // Open reschedule modal/page
      // Implementation depends on your reschedule UI
      break;

    case "rebook":
      // Navigate to booking page
      // Implementation depends on your booking flow
      break;

    default:
      console.warn("Unknown action button type:", button.type);
  }
};

const cancelAppointment = async (appointmentId: string): Promise<void> => {
  const { error } = await supabase.rpc("respond_to_appointment_request", {
    p_appointment_id: appointmentId,
    p_action: "reject",
    p_notes: "Cancelled by client",
  });

  if (error) {
    throw new Error(error.message);
  }
};
```

### **Phase 3: Create New UI Components**

#### 3.1 AppointmentMessage Component

```typescript
// Create AppointmentMessage.tsx
import React from "react";
import { ChatMessage, ActionButton } from "./types";
import { handleActionButton } from "./utils";

interface AppointmentMessageProps {
  message: ChatMessage;
  appointmentId: string;
}

export const AppointmentMessage: React.FC<AppointmentMessageProps> = ({
  message,
  appointmentId,
}) => {
  const handleButtonClick = async (button: ActionButton) => {
    try {
      await handleActionButton(button, appointmentId);
    } catch (error) {
      console.error("Error handling button click:", error);
      // Show error toast/notification
    }
  };

  const getButtonStyle = (style: string) => {
    const baseClasses = "px-4 py-2 rounded-lg font-medium transition-colors";
    switch (style) {
      case "primary":
        return `${baseClasses} bg-blue-600 text-white hover:bg-blue-700`;
      case "success":
        return `${baseClasses} bg-green-600 text-white hover:bg-green-700`;
      case "danger":
        return `${baseClasses} bg-red-600 text-white hover:bg-red-700`;
      case "secondary":
      default:
        return `${baseClasses} bg-gray-200 text-gray-800 hover:bg-gray-300`;
    }
  };

  return (
    <div className="appointment-message bg-blue-50 border border-blue-200 rounded-lg p-4 my-2">
      <div className="prose max-w-none">
        <div
          dangerouslySetInnerHTML={{
            __html: message.message.replace(
              /\*\*(.*?)\*\*/g,
              "<strong>$1</strong>"
            ),
          }}
        />
      </div>

      {message.action_buttons && message.action_buttons.length > 0 && (
        <div className="flex flex-wrap gap-2 mt-4">
          {message.action_buttons.map((button, index) => (
            <button
              key={index}
              onClick={() => handleButtonClick(button)}
              className={getButtonStyle(button.style)}
            >
              {button.label}
            </button>
          ))}
        </div>
      )}

      <div className="text-xs text-gray-500 mt-2">
        {new Date(message.created_at).toLocaleString()}
      </div>
    </div>
  );
};
```

#### 3.2 Enhanced ChatMessage Component

```typescript
// Update existing ChatMessage component
import React from "react";
import { ChatMessage } from "./types";
import { AppointmentMessage } from "./AppointmentMessage";

interface ChatMessageComponentProps {
  message: ChatMessage;
  isOwnMessage: boolean;
}

export const ChatMessageComponent: React.FC<ChatMessageComponentProps> = ({
  message,
  isOwnMessage,
}) => {
  // Don't render superseded messages
  if (message.is_superseded) {
    return null;
  }

  // Special rendering for appointment status messages
  if (
    message.message_type === "appointment_status" &&
    message.appointment_context
  ) {
    return (
      <AppointmentMessage
        message={message}
        appointmentId={message.appointment_context.appointment_id}
      />
    );
  }

  // Regular message rendering
  return (
    <div
      className={`message ${isOwnMessage ? "own-message" : "other-message"}`}
    >
      <div className="message-content">{message.message}</div>
      <div className="message-time">
        {new Date(message.created_at).toLocaleString()}
      </div>
    </div>
  );
};
```

### **Phase 4: Update Chat Room List**

#### 4.1 Enhanced Chat Room Display

```typescript
// Update ChatList component
export const ChatRoomItem: React.FC<{ room: ChatRoom }> = ({ room }) => {
  const getRoomIcon = () => {
    switch (room.type) {
      case "appointment_booking":
        return "📅";
      case "event_notification":
        return "🎉";
      case "service_updates":
        return "🔔";
      case "booking_support":
        return "💬";
      case "transaction_channel":
        return "💳";
      default:
        return "💬";
    }
  };

  const getRoomDisplayName = () => {
    if (room.type === "appointment_booking" && room.metadata) {
      const metadata = room.metadata as any;
      return `${metadata.service_name || "Appointment"} - ${
        metadata.appointment_date
          ? new Date(metadata.appointment_date).toLocaleDateString()
          : "TBD"
      }`;
    }
    return room.name || "Unnamed Chat";
  };

  return (
    <div className="chat-room-item">
      <div className="room-icon">{getRoomIcon()}</div>
      <div className="room-info">
        <div className="room-name">{getRoomDisplayName()}</div>
        <div className="last-message">
          {room.last_message?.message || "No messages yet"}
        </div>
      </div>
      {room.unread_count > 0 && (
        <div className="unread-badge">{room.unread_count}</div>
      )}
    </div>
  );
};
```

### **Phase 5: Update Real-time Subscriptions**

#### 5.1 Enhanced Message Subscription

```typescript
// Update in utils.ts
export const subscribeToRoomMessages = (
  roomId: string,
  onNewMessage: (message: ChatMessage) => void,
  onMessageUpdate: (message: ChatMessage) => void
) => {
  return supabase
    .channel(`room-${roomId}`)
    .on(
      "postgres_changes",
      {
        event: "INSERT",
        schema: "public",
        table: "chat_messages",
        filter: `chat_room_id=eq.${roomId}`,
      },
      (payload) => {
        const newMessage: ChatMessage = {
          id: payload.new.id,
          chat_room_id: payload.new.chat_room_id,
          sender_id: payload.new.sender_id,
          message: payload.new.message,
          created_at: payload.new.created_at,
          is_edited: payload.new.is_edited,
          status: payload.new.status,
          reply_to_message_id: payload.new.reply_to_message_id,
          message_type: payload.new.message_type,
          action_buttons: payload.new.action_buttons,
          appointment_context: payload.new.appointment_context,
          superseded_by: payload.new.superseded_by,
          is_superseded: false,
        };
        onNewMessage(newMessage);
      }
    )
    .on(
      "postgres_changes",
      {
        event: "UPDATE",
        schema: "public",
        table: "chat_messages",
        filter: `chat_room_id=eq.${roomId}`,
      },
      (payload) => {
        // Handle message supersession
        if (payload.new.superseded_by && !payload.old.superseded_by) {
          const updatedMessage: ChatMessage = {
            id: payload.new.id,
            chat_room_id: payload.new.chat_room_id,
            sender_id: payload.new.sender_id,
            message: payload.new.message,
            created_at: payload.new.created_at,
            is_edited: payload.new.is_edited,
            status: payload.new.status,
            reply_to_message_id: payload.new.reply_to_message_id,
            message_type: payload.new.message_type,
            action_buttons: payload.new.action_buttons,
            appointment_context: payload.new.appointment_context,
            superseded_by: payload.new.superseded_by,
            is_superseded: true,
          };
          onMessageUpdate(updatedMessage);
        }
      }
    )
    .subscribe();
};
```

### **Phase 6: Integration with Appointment System**

#### 6.1 Appointment Chat Integration Hook

```typescript
// Create useAppointmentChat.ts hook
import { useState, useEffect } from "react";
import { ChatMessage } from "./types";
import {
  getAppointmentChat,
  getCurrentAppointmentMessage,
  subscribeToRoomMessages,
} from "./utils";

export const useAppointmentChat = (appointmentId: string) => {
  const [chatRoomId, setChatRoomId] = useState<string | null>(null);
  const [currentMessage, setCurrentMessage] = useState<ChatMessage | null>(
    null
  );
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadAppointmentChat = async () => {
      try {
        const roomId = await getAppointmentChat(appointmentId);
        setChatRoomId(roomId);

        if (roomId) {
          const message = await getCurrentAppointmentMessage(appointmentId);
          setCurrentMessage(message);
        }
      } catch (error) {
        console.error("Error loading appointment chat:", error);
      } finally {
        setLoading(false);
      }
    };

    loadAppointmentChat();
  }, [appointmentId]);

  useEffect(() => {
    if (!chatRoomId) return;

    const subscription = subscribeToRoomMessages(
      chatRoomId,
      (newMessage) => {
        // Update current message if it's an appointment status message
        if (
          newMessage.message_type === "appointment_status" &&
          newMessage.appointment_context?.appointment_id === appointmentId
        ) {
          setCurrentMessage(newMessage);
        }
      },
      (updatedMessage) => {
        // Handle message supersession
        if (
          updatedMessage.is_superseded &&
          currentMessage?.id === updatedMessage.id
        ) {
          // Fetch the new current message
          getCurrentAppointmentMessage(appointmentId).then(setCurrentMessage);
        }
      }
    );

    return () => {
      subscription.unsubscribe();
    };
  }, [chatRoomId, appointmentId, currentMessage?.id]);

  return {
    chatRoomId,
    currentMessage,
    loading,
  };
};
```

#### 6.2 Appointment Status Widget

```typescript
// Create AppointmentStatusWidget.tsx
import React from "react";
import { useAppointmentChat } from "./useAppointmentChat";
import { AppointmentMessage } from "./AppointmentMessage";

interface AppointmentStatusWidgetProps {
  appointmentId: string;
}

export const AppointmentStatusWidget: React.FC<
  AppointmentStatusWidgetProps
> = ({ appointmentId }) => {
  const { currentMessage, loading } = useAppointmentChat(appointmentId);

  if (loading) {
    return <div className="animate-pulse bg-gray-200 h-32 rounded-lg"></div>;
  }

  if (!currentMessage) {
    return (
      <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
        <p className="text-gray-600">No status updates available</p>
      </div>
    );
  }

  return (
    <AppointmentMessage
      message={currentMessage}
      appointmentId={appointmentId}
    />
  );
};
```

---

## 🎯 **Implementation Priority**

### **Phase 1 (Critical - Do First):**

1. Update type definitions (`ChatRoom`, `ChatMessage`, `ActionButton`)
2. Replace `fetchChatMessages()` with enhanced version
3. Add basic appointment chat functions

### **Phase 2 (High Priority):**

4. Create `AppointmentMessage` component
5. Update existing `ChatMessage` component to handle superseded messages
6. Add action button handling

### **Phase 3 (Medium Priority):**

7. Update chat room list to show specialized room types
8. Enhance real-time subscriptions
9. Create appointment chat integration hook

### **Phase 4 (Enhancement):**

10. Create appointment status widget
11. Add comprehensive error handling
12. Add loading states and animations

---

## 🔍 **Testing Checklist**

### **Frontend Integration Tests:**

- [ ] **Message Display**: Superseded messages are hidden
- [ ] **Action Buttons**: All button types work correctly
- [ ] **Real-time Updates**: Living messages update automatically
- [ ] **Appointment Context**: Appointment details display correctly
- [ ] **Room Types**: Different chat types show appropriate icons/styling
- [ ] **Error Handling**: Graceful handling of API errors
- [ ] **Loading States**: Proper loading indicators

### **Appointment Flow Tests:**

- [ ] **Booking Request**: Creates appointment chat room
- [ ] **Approval**: Updates message with payment button
- [ ] **Payment**: Updates message with confirmation + new buttons
- [ ] **Meeting Link**: Adds join meeting button
- [ ] **Cancellation**: Shows cancelled status with rebook option

---

## 📋 **Summary of Required Changes**

### **Files to Update:**

1. `utils.ts` - Add new interfaces, functions, enhanced API calls
2. `ChatMessage.tsx` - Handle new message types and supersession
3. `ChatList.tsx` - Show specialized room types
4. `database.types.ts` - Update type definitions to match new schema

### **New Files to Create:**

1. `AppointmentMessage.tsx` - Specialized appointment message component
2. `useAppointmentChat.ts` - Hook for appointment chat integration
3. `AppointmentStatusWidget.tsx` - Widget for appointment pages

### **Integration Points:**

1. **Appointment Pages**: Add `AppointmentStatusWidget`
2. **Payment Flow**: Integrate with action button handlers
3. **Booking System**: Use appointment chat functions
4. **Notification System**: Subscribe to appointment chat updates

This guide provides a complete roadmap for updating your frontend chat system to support the new specialized chat channels with living messages and interactive action buttons.
