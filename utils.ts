import createClient from "@/lib/supabase/client";

// Create Supabase client
export const supabase = createClient();

// Types
export interface ChatRoom {
  id: string;
  name: string;
  type: "private" | "group" | "broadcast";
  is_broadcast: boolean;
  description?: string;
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
}

export interface Participant {
  id: string;
  user_id: string;
  chat_room_id: string;
  role: "member" | "admin" | "creator";
  joined_at: string;
  last_read_message_id: string | null;
  display_name: string;
  avatar_url: string | null;
  is_online?: boolean;
  last_seen?: string;
}

// Helper functions
export const fetchChatRooms = async (userId: string): Promise<ChatRoom[]> => {
  console.log("🔍 fetchChatRooms called with userId:", userId);

  // Use the parameterized version for certainty
  const { data, error } = await supabase.rpc("get_user_chat_rooms", {
    p_user_id: userId,
  });

  if (error) {
    console.error("📊 RPC Response - Error:", error);
    console.warn(error);
    throw new Error(error.message);
  }

  console.log("📊 RPC Response - Error:", error);
  console.log("📊 RPC Response - Data:", data);

  if (!data) {
    console.warn("⚠️ No data returned from get_user_chat_rooms");
    return [];
  }

  console.log("✅ RPC call successful");
  console.log("📈 Processing", data.length, "chat rooms");

  // Convert the returned data structure to match the ChatRoom interface
  const transformedRooms = data.map((room: any, index: number) => {
    console.log(`🏠 Processing room ${index + 1}:`, room);

    const transformedRoom = {
      id: room.room_id,
      name: room.room_name,
      type: room.room_type,
      is_broadcast: room.is_broadcast,
      description: room.room_description,
      last_message: room.latest_message
        ? {
            message: room.latest_message,
            created_at: room.latest_message_time,
            sender_id: room.latest_message_sender,
          }
        : undefined,
      unread_count: room.unread_count,
      created_at: room.created_at,
      updated_at: room.updated_at,
      participants: [], // This will be populated separately if needed
    };

    console.log(`✅ Transformed room ${index + 1}:`, transformedRoom);
    return transformedRoom;
  });

  console.log("🎉 All rooms transformed successfully:");
  console.log("📊 Final rooms array:", transformedRooms);
  console.log("📈 Returning", transformedRooms.length, "rooms");

  return transformedRooms;
};

export const fetchChatMessages = async (
  roomId: string,
  options?: {
    limit?: number;
    before?: string;
    after?: string;
    around_message_id?: string;
  }
): Promise<ChatMessage[]> => {
  // Add null check for roomId
  if (!roomId || roomId === "undefined") {
    console.error("fetchChatMessages called with invalid roomId:", roomId);
    return [];
  }

  console.log("🔍 fetchChatMessages called with roomId:", roomId);
  console.log("📋 Options:", options);

  try {
    // Use the correct RPC function name
    const { data, error } = await supabase.rpc(
      "get_chat_messages_with_reactions",
      {
        p_chat_room_id: roomId,
        p_limit: options?.limit || 50,
        p_before: options?.before || undefined,
        p_after: options?.after || undefined,
        p_around_message_id: options?.around_message_id || undefined,
      }
    );

    if (error) {
      console.error("Error fetching messages:", error);
      throw new Error(error.message);
    }

    console.log("✅ Messages fetched successfully:", data?.length || 0);
    return formatChatMessages(data || [], roomId);
  } catch (error) {
    console.error("Exception in fetchChatMessages:", error);
    throw error;
  }
};

// Helper to format chat messages
const formatChatMessages = (data: any[], roomId: string): ChatMessage[] => {
  return data.map((msg: any) => ({
    id: msg.message_id,
    chat_room_id: roomId,
    sender_id: msg.sender_id,
    message: msg.message,
    created_at: msg.created_at,
    is_edited: msg.is_edited,
    status: msg.status,
    reply_to_message_id: msg.reply_to_message_id,
  }));
};

export const fetchParticipants = async (
  roomId: string
): Promise<Participant[]> => {
  const { data, error } = await supabase
    .from("chat_participants")
    .select(
      `
      id,
      user_id,
      chat_room_id,
      role,
      joined_at,
      last_read_message_id,
      profiles:user_id (
        full_name,
        avatar_url
      )
    `
    )
    .eq("chat_room_id", roomId);

  if (error) {
    throw new Error(error.message);
  }

  return data.map((p) => {
    const profile = p.profiles as unknown as {
      full_name: string;
      avatar_url: string | null;
    };

    return {
      id: p.id,
      user_id: p.user_id,
      chat_room_id: p.chat_room_id,
      role: p.role as "member" | "admin" | "creator",
      joined_at: p.joined_at,
      last_read_message_id: p.last_read_message_id,
      display_name: profile?.full_name || "Anonymous", // Changed from display_name to full_name
      avatar_url: profile?.avatar_url || null,
      is_online: false,
    } as Participant;
  });
};

export const createPrivateChat = async (
  userId: string,
  otherUserId: string
): Promise<string> => {
  try {
    const { data, error } = await supabase.rpc("create_or_get_private_chat", {
      p_user_id1: userId,
      p_user_id2: otherUserId,
    });

    if (error) {
      console.error("Error creating private chat:", error);
      throw new Error(`Error creating private chat: ${error.message}`);
    }

    return data as string; // Returns the chat room ID
  } catch (error: any) {
    console.error("Error in createPrivateChat:", error);
    throw new Error(`Error creating private chat: ${error.message}`);
  }
};

export const createGroupChat = async (
  name: string,
  userIds: string[]
): Promise<string> => {
  // First create the chat room
  const { data: roomData, error: roomError } = await supabase
    .from("chat_rooms")
    .insert({
      name,
      type: "group",
      is_broadcast: false,
      created_by: userIds[0], // Assuming the first user is the creator
    })
    .select("id")
    .single();

  if (roomError) {
    throw new Error(roomError.message);
  }

  // Then add participants
  const { error: participantsError } = await supabase.rpc(
    "add_chat_participants",
    {
      p_chat_room_id: roomData.id,
      p_user_ids: userIds,
    }
  );

  if (participantsError) {
    throw new Error(participantsError.message);
  }

  return roomData.id;
};

export const sendMessage = async (
  roomId: string,
  message: string,
  replyToMessageId?: string
): Promise<string> => {
  const user = await supabase.auth.getUser();
  const userId = user.data.user?.id;

  if (!userId) {
    throw new Error("User not authenticated");
  }

  const { data, error } = await supabase
    .from("chat_messages")
    .insert({
      chat_room_id: roomId,
      sender_id: userId,
      message,
      reply_to_message_id: replyToMessageId,
    })
    .select("id")
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return data.id;
};

export const markMessageAsRead = async (messageId: string): Promise<void> => {
  const user = await supabase.auth.getUser();
  const userId = user.data.user?.id;

  if (!userId) {
    throw new Error("User not authenticated");
  }

  const { error } = await supabase.rpc("mark_message_as_read", {
    p_message_id: messageId,
    p_user_id: userId,
  });

  if (error) {
    throw new Error(error.message);
  }
};

export const removeParticipant = async (
  participantId: string
): Promise<void> => {
  // Use direct database access instead of rpc
  const { error } = await supabase
    .from("chat_participants")
    .update({ left_at: new Date().toISOString() })
    .eq("id", participantId);

  if (error) {
    throw new Error(error.message);
  }
};

export const changeParticipantRole = async (
  participantId: string,
  newRole: "member" | "admin"
): Promise<void> => {
  const { error } = await supabase
    .from("chat_participants")
    .update({ role: newRole })
    .eq("id", participantId);

  if (error) {
    throw new Error(error.message);
  }
};

export const deleteMessage = async (messageId: string): Promise<void> => {
  const user = await supabase.auth.getUser();
  const userId = user.data.user?.id;

  if (!userId) {
    throw new Error("User not authenticated");
  }

  // Update message status to 'deleted' rather than actually deleting
  const { error } = await supabase
    .from("chat_messages")
    .update({ status: "deleted" })
    .match({ id: messageId, sender_id: userId });

  if (error) {
    throw new Error(error.message);
  }
};

export const editMessage = async (
  messageId: string,
  newContent: string
): Promise<void> => {
  const user = await supabase.auth.getUser();
  const userId = user.data.user?.id;

  if (!userId) {
    throw new Error("User not authenticated");
  }

  const { error } = await supabase
    .from("chat_messages")
    .update({
      message: newContent,
      is_edited: true,
    })
    .match({ id: messageId, sender_id: userId });

  if (error) {
    throw new Error(error.message);
  }
};

// Setup real-time subscriptions
export const subscribeToRoomMessages = (
  roomId: string,
  onNewMessage: (message: ChatMessage) => void
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
        // Format the incoming message
        const newMessage = {
          id: payload.new.id,
          chat_room_id: payload.new.chat_room_id,
          sender_id: payload.new.sender_id,
          message: payload.new.message,
          created_at: payload.new.created_at,
          is_edited: payload.new.is_edited,
          status: payload.new.status,
          reply_to_message_id: payload.new.reply_to_message_id,
        };
        onNewMessage(newMessage);
      }
    )
    .subscribe();
};
