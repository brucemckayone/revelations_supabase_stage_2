export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          operationName?: string
          query?: string
          variables?: Json
          extensions?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      appointment_purchases: {
        Row: {
          appointment_date: string
          created_at: string | null
          duration: number
          id: string
          meeting_id: string | null
          meeting_url: string | null
          metadata: Json | null
          method: Database["public"]["Enums"]["appointment_method_enum"]
          notes: string | null
          payment_failure_reason: string | null
          payment_link: string | null
          payment_method: string | null
          payment_reference: string | null
          provider_notes: string | null
          purchase_id: string
          service_id: string
          service_type: Database["public"]["Enums"]["appointment_type_enum"]
          status: Database["public"]["Enums"]["appointment_status_enum"]
          transaction_reference: string | null
          updated_at: string | null
        }
        Insert: {
          appointment_date: string
          created_at?: string | null
          duration: number
          id?: string
          meeting_id?: string | null
          meeting_url?: string | null
          metadata?: Json | null
          method: Database["public"]["Enums"]["appointment_method_enum"]
          notes?: string | null
          payment_failure_reason?: string | null
          payment_link?: string | null
          payment_method?: string | null
          payment_reference?: string | null
          provider_notes?: string | null
          purchase_id: string
          service_id: string
          service_type: Database["public"]["Enums"]["appointment_type_enum"]
          status: Database["public"]["Enums"]["appointment_status_enum"]
          transaction_reference?: string | null
          updated_at?: string | null
        }
        Update: {
          appointment_date?: string
          created_at?: string | null
          duration?: number
          id?: string
          meeting_id?: string | null
          meeting_url?: string | null
          metadata?: Json | null
          method?: Database["public"]["Enums"]["appointment_method_enum"]
          notes?: string | null
          payment_failure_reason?: string | null
          payment_link?: string | null
          payment_method?: string | null
          payment_reference?: string | null
          provider_notes?: string | null
          purchase_id?: string
          service_id?: string
          service_type?: Database["public"]["Enums"]["appointment_type_enum"]
          status?: Database["public"]["Enums"]["appointment_status_enum"]
          transaction_reference?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "appointment_purchases_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      appointments: {
        Row: {
          client_id: string | null
          created_at: string | null
          end_time: string
          facilitator_id: string | null
          id: string
          package_purchase_id: string | null
          start_time: string
          status: string | null
          updated_at: string | null
        }
        Insert: {
          client_id?: string | null
          created_at?: string | null
          end_time: string
          facilitator_id?: string | null
          id?: string
          package_purchase_id?: string | null
          start_time: string
          status?: string | null
          updated_at?: string | null
        }
        Update: {
          client_id?: string | null
          created_at?: string | null
          end_time?: string
          facilitator_id?: string | null
          id?: string
          package_purchase_id?: string | null
          start_time?: string
          status?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "appointments_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_facilitator_id_fkey"
            columns: ["facilitator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_package_purchase_id_fkey"
            columns: ["package_purchase_id"]
            isOneToOne: false
            referencedRelation: "service_package_purchases"
            referencedColumns: ["id"]
          },
        ]
      }
      articles: {
        Row: {
          content: string
          created_at: string | null
          id: string
          post_id: string
          updated_at: string | null
        }
        Insert: {
          content: string
          created_at?: string | null
          id?: string
          post_id: string
          updated_at?: string | null
        }
        Update: {
          content?: string
          created_at?: string | null
          id?: string
          post_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "articles_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
        ]
      }
      assets: {
        Row: {
          attempts: number | null
          created_at: string | null
          duration: number | null
          estimated_duration: number | null
          id: string
          job_data: Json | null
          job_id: string | null
          media_type: Database["public"]["Enums"]["media_type_enum"] | null
          metadata: Json | null
          metrics: Json | null
          output: Json | null
          priority: number | null
          processing_started_at: string | null
          progress: number | null
          queue_position: number | null
          stage: string | null
          status: string
          user_id: string
        }
        Insert: {
          attempts?: number | null
          created_at?: string | null
          duration?: number | null
          estimated_duration?: number | null
          id: string
          job_data?: Json | null
          job_id?: string | null
          media_type?: Database["public"]["Enums"]["media_type_enum"] | null
          metadata?: Json | null
          metrics?: Json | null
          output?: Json | null
          priority?: number | null
          processing_started_at?: string | null
          progress?: number | null
          queue_position?: number | null
          stage?: string | null
          status: string
          user_id: string
        }
        Update: {
          attempts?: number | null
          created_at?: string | null
          duration?: number | null
          estimated_duration?: number | null
          id?: string
          job_data?: Json | null
          job_id?: string | null
          media_type?: Database["public"]["Enums"]["media_type_enum"] | null
          metadata?: Json | null
          metrics?: Json | null
          output?: Json | null
          priority?: number | null
          processing_started_at?: string | null
          progress?: number | null
          queue_position?: number | null
          stage?: string | null
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "assets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      availability: {
        Row: {
          created_at: string | null
          day: string
          end_time: string
          is_active: boolean
          start_time: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          day: string
          end_time: string
          is_active: boolean
          start_time: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          day?: string
          end_time?: string
          is_active?: boolean
          start_time?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "availability_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      availability_exceptions: {
        Row: {
          created_at: string | null
          end_time: string | null
          exception_date: string
          id: string
          is_available: boolean
          reason: string | null
          start_time: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          end_time?: string | null
          exception_date: string
          id?: string
          is_available: boolean
          reason?: string | null
          start_time?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          end_time?: string | null
          exception_date?: string
          id?: string
          is_available?: boolean
          reason?: string | null
          start_time?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "availability_exceptions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      bookings: {
        Row: {
          client_email: string
          client_name: string
          created_at: string | null
          end_time: string | null
          id: string
          post_id: string | null
          start_time: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          client_email: string
          client_name: string
          created_at?: string | null
          end_time?: string | null
          id?: string
          post_id?: string | null
          start_time?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          client_email?: string
          client_name?: string
          created_at?: string | null
          end_time?: string | null
          id?: string
          post_id?: string | null
          start_time?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "bookings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      ceremony: {
        Row: {
          ceremony_focus: string
          ceremony_theme: string
          ceremony_type: string
          content_id: string
          id: string
          space_holder_names: string | null
          what_to_bring: string | null
        }
        Insert: {
          ceremony_focus: string
          ceremony_theme: string
          ceremony_type: string
          content_id: string
          id?: string
          space_holder_names?: string | null
          what_to_bring?: string | null
        }
        Update: {
          ceremony_focus?: string
          ceremony_theme?: string
          ceremony_type?: string
          content_id?: string
          id?: string
          space_holder_names?: string | null
          what_to_bring?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ceremony_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["content_id"]
          },
          {
            foreignKeyName: "ceremony_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "ceremony_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "ceremony_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "ceremony_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "ceremony_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "ceremony_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "ceremony_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ceremony_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["on_demand_media_id"]
          },
        ]
      }
      chat_messages: {
        Row: {
          action_buttons: Json | null
          appointment_context: Json | null
          chat_room_id: string
          created_at: string | null
          id: string
          is_edited: boolean | null
          message: string
          message_type: string | null
          reply_to_message_id: string | null
          sender_id: string
          status: Database["public"]["Enums"]["message_status_enum"] | null
          superseded_by: string | null
        }
        Insert: {
          action_buttons?: Json | null
          appointment_context?: Json | null
          chat_room_id: string
          created_at?: string | null
          id?: string
          is_edited?: boolean | null
          message: string
          message_type?: string | null
          reply_to_message_id?: string | null
          sender_id: string
          status?: Database["public"]["Enums"]["message_status_enum"] | null
          superseded_by?: string | null
        }
        Update: {
          action_buttons?: Json | null
          appointment_context?: Json | null
          chat_room_id?: string
          created_at?: string | null
          id?: string
          is_edited?: boolean | null
          message?: string
          message_type?: string | null
          reply_to_message_id?: string | null
          sender_id?: string
          status?: Database["public"]["Enums"]["message_status_enum"] | null
          superseded_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "chat_messages_chat_room_id_fkey"
            columns: ["chat_room_id"]
            isOneToOne: false
            referencedRelation: "chat_rooms"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_superseded_by_fkey"
            columns: ["superseded_by"]
            isOneToOne: false
            referencedRelation: "chat_messages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_reply_to_message"
            columns: ["reply_to_message_id"]
            isOneToOne: false
            referencedRelation: "chat_messages"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_participants: {
        Row: {
          chat_room_id: string
          id: string
          is_muted: boolean | null
          joined_at: string | null
          last_read_message_id: string | null
          left_at: string | null
          role: string | null
          user_id: string
        }
        Insert: {
          chat_room_id: string
          id?: string
          is_muted?: boolean | null
          joined_at?: string | null
          last_read_message_id?: string | null
          left_at?: string | null
          role?: string | null
          user_id: string
        }
        Update: {
          chat_room_id?: string
          id?: string
          is_muted?: boolean | null
          joined_at?: string | null
          last_read_message_id?: string | null
          left_at?: string | null
          role?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_participants_chat_room_id_fkey"
            columns: ["chat_room_id"]
            isOneToOne: false
            referencedRelation: "chat_rooms"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_last_read_message"
            columns: ["last_read_message_id"]
            isOneToOne: false
            referencedRelation: "chat_messages"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_rooms: {
        Row: {
          associated_appointment_id: string | null
          associated_event_id: string | null
          associated_post_id: string | null
          auto_notifications: boolean | null
          created_at: string | null
          created_by: string
          description: string | null
          id: string
          is_broadcast: boolean | null
          metadata: Json | null
          name: string | null
          pinned_message_id: string | null
          type: Database["public"]["Enums"]["chat_type_enum"]
          updated_at: string | null
        }
        Insert: {
          associated_appointment_id?: string | null
          associated_event_id?: string | null
          associated_post_id?: string | null
          auto_notifications?: boolean | null
          created_at?: string | null
          created_by: string
          description?: string | null
          id?: string
          is_broadcast?: boolean | null
          metadata?: Json | null
          name?: string | null
          pinned_message_id?: string | null
          type: Database["public"]["Enums"]["chat_type_enum"]
          updated_at?: string | null
        }
        Update: {
          associated_appointment_id?: string | null
          associated_event_id?: string | null
          associated_post_id?: string | null
          auto_notifications?: boolean | null
          created_at?: string | null
          created_by?: string
          description?: string | null
          id?: string
          is_broadcast?: boolean | null
          metadata?: Json | null
          name?: string | null
          pinned_message_id?: string | null
          type?: Database["public"]["Enums"]["chat_type_enum"]
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "chat_rooms_associated_appointment_id_fkey"
            columns: ["associated_appointment_id"]
            isOneToOne: false
            referencedRelation: "appointment_purchases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_appointment_id_fkey"
            columns: ["associated_appointment_id"]
            isOneToOne: false
            referencedRelation: "pending_payment_appointments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_appointment_id_fkey"
            columns: ["associated_appointment_id"]
            isOneToOne: false
            referencedRelation: "service_appointments_view"
            referencedColumns: ["appointment_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_appointment_id_fkey"
            columns: ["associated_appointment_id"]
            isOneToOne: false
            referencedRelation: "user_appointments_view"
            referencedColumns: ["appointment_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_event_id_fkey"
            columns: ["associated_event_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_event_id_fkey"
            columns: ["associated_event_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_event_id_fkey"
            columns: ["associated_event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_event_id_fkey"
            columns: ["associated_event_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "chat_rooms_associated_post_id_fkey"
            columns: ["associated_post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_rooms_pinned_message_id_fkey"
            columns: ["pinned_message_id"]
            isOneToOne: false
            referencedRelation: "chat_messages"
            referencedColumns: ["id"]
          },
        ]
      }
      comment_attachments: {
        Row: {
          comment_id: number | null
          created_at: string | null
          id: number
          name: string
          size: number
          type: string
          url: string
        }
        Insert: {
          comment_id?: number | null
          created_at?: string | null
          id?: number
          name: string
          size: number
          type: string
          url: string
        }
        Update: {
          comment_id?: number | null
          created_at?: string | null
          id?: number
          name?: string
          size?: number
          type?: string
          url?: string
        }
        Relationships: [
          {
            foreignKeyName: "comment_attachments_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
        ]
      }
      comment_mentions: {
        Row: {
          comment_id: number | null
          created_at: string | null
          id: number
          user_id: string | null
        }
        Insert: {
          comment_id?: number | null
          created_at?: string | null
          id?: number
          user_id?: string | null
        }
        Update: {
          comment_id?: number | null
          created_at?: string | null
          id?: number
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "comment_mentions_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comment_mentions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      comment_reactions: {
        Row: {
          comment_id: number | null
          created_at: string | null
          id: number
          reaction_type: string
          user_id: string | null
        }
        Insert: {
          comment_id?: number | null
          created_at?: string | null
          id?: number
          reaction_type: string
          user_id?: string | null
        }
        Update: {
          comment_id?: number | null
          created_at?: string | null
          id?: number
          reaction_type?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "comment_reactions_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comment_reactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      comments: {
        Row: {
          comment: string
          created_at: string
          deleted_at: string | null
          depth: number | null
          hasreplies: boolean | null
          id: number
          is_edited: boolean | null
          parent_id: number | null
          post_id: string
          score: number | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          comment: string
          created_at?: string
          deleted_at?: string | null
          depth?: number | null
          hasreplies?: boolean | null
          id?: number
          is_edited?: boolean | null
          parent_id?: number | null
          post_id: string
          score?: number | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          comment?: string
          created_at?: string
          deleted_at?: string | null
          depth?: number | null
          hasreplies?: boolean | null
          id?: number
          is_edited?: boolean | null
          parent_id?: number | null
          post_id?: string
          score?: number | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "comments_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "creator_profiles_complete_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_cards_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      content_purchases: {
        Row: {
          access_expires_at: string | null
          content_id: string
          created_at: string | null
          download_count: number
          id: string
          is_subscription: boolean
          last_accessed: string | null
          purchase_id: string
          updated_at: string | null
        }
        Insert: {
          access_expires_at?: string | null
          content_id: string
          created_at?: string | null
          download_count?: number
          id?: string
          is_subscription?: boolean
          last_accessed?: string | null
          purchase_id: string
          updated_at?: string | null
        }
        Update: {
          access_expires_at?: string | null
          content_id?: string
          created_at?: string | null
          download_count?: number
          id?: string
          is_subscription?: boolean
          last_accessed?: string | null
          purchase_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "content_purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["content_id"]
          },
          {
            foreignKeyName: "content_purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "content_purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "content_purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "content_purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "content_purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "content_purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "content_purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "content_purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "content_purchases_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
        ]
      }
      creator_branding: {
        Row: {
          contrast: number | null
          dark: boolean | null
          hue: number | null
          lightness: number | null
          saturation: number | null
          user_id: string
        }
        Insert: {
          contrast?: number | null
          dark?: boolean | null
          hue?: number | null
          lightness?: number | null
          saturation?: number | null
          user_id: string
        }
        Update: {
          contrast?: number | null
          dark?: boolean | null
          hue?: number | null
          lightness?: number | null
          saturation?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "creator_branding_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      creator_emails: {
        Row: {
          configuration: Json
          created_at: string | null
          id: string
          name: string
          subject: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          configuration: Json
          created_at?: string | null
          id?: string
          name: string
          subject: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          configuration?: Json
          created_at?: string | null
          id?: string
          name?: string
          subject?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "creator_emails_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      creator_profiles: {
        Row: {
          background_video_url: string | null
          bio: string | null
          certifications: string[] | null
          cover_image_url: string | null
          experience: string | null
          featured_testimonials: string[] | null
          id: string
          philosophy: string | null
          profile_id: string
          profile_name: string | null
          short_bio: string | null
          title: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          background_video_url?: string | null
          bio?: string | null
          certifications?: string[] | null
          cover_image_url?: string | null
          experience?: string | null
          featured_testimonials?: string[] | null
          id: string
          philosophy?: string | null
          profile_id: string
          profile_name?: string | null
          short_bio?: string | null
          title?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          background_video_url?: string | null
          bio?: string | null
          certifications?: string[] | null
          cover_image_url?: string | null
          experience?: string | null
          featured_testimonials?: string[] | null
          id?: string
          philosophy?: string | null
          profile_id?: string
          profile_name?: string | null
          short_bio?: string | null
          title?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "creator_profiles_complete_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profile_cards_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      creator_subscription_tiers: {
        Row: {
          benefits: Json | null
          created_at: string | null
          creator_id: string
          description: string | null
          id: string
          is_active: boolean | null
          price_annual: number | null
          price_monthly: number
          price_quarterly: number | null
          priority: number
          stripe_price_id_annual: string | null
          stripe_price_id_monthly: string | null
          stripe_price_id_quarterly: string | null
          stripe_product_id: string | null
          tier_key: string
          tier_name: string
          trial_days: number | null
          updated_at: string | null
        }
        Insert: {
          benefits?: Json | null
          created_at?: string | null
          creator_id: string
          description?: string | null
          id?: string
          is_active?: boolean | null
          price_annual?: number | null
          price_monthly: number
          price_quarterly?: number | null
          priority?: number
          stripe_price_id_annual?: string | null
          stripe_price_id_monthly?: string | null
          stripe_price_id_quarterly?: string | null
          stripe_product_id?: string | null
          tier_key: string
          tier_name: string
          trial_days?: number | null
          updated_at?: string | null
        }
        Update: {
          benefits?: Json | null
          created_at?: string | null
          creator_id?: string
          description?: string | null
          id?: string
          is_active?: boolean | null
          price_annual?: number | null
          price_monthly?: number
          price_quarterly?: number | null
          priority?: number
          stripe_price_id_annual?: string | null
          stripe_price_id_monthly?: string | null
          stripe_price_id_quarterly?: string | null
          stripe_product_id?: string | null
          tier_key?: string
          tier_name?: string
          trial_days?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "creator_subscription_tiers_creator_id_fkey"
            columns: ["creator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      dance: {
        Row: {
          freeform_movement: boolean
          id: string
          movement_id: string
        }
        Insert: {
          freeform_movement?: boolean
          id?: string
          movement_id: string
        }
        Update: {
          freeform_movement?: boolean
          id?: string
          movement_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "dance_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "dance_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "dance_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "movement_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "dance_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "movements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dance_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "neuroflow_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "dance_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "yoga_details"
            referencedColumns: ["movement_id"]
          },
        ]
      }
      email_templates: {
        Row: {
          created_at: string
          html_content: string
          id: string
          is_active: boolean
          name: string
          subject: string
          text_content: string
          updated_at: string
          variables: Json
        }
        Insert: {
          created_at?: string
          html_content: string
          id?: string
          is_active?: boolean
          name: string
          subject: string
          text_content: string
          updated_at?: string
          variables?: Json
        }
        Update: {
          created_at?: string
          html_content?: string
          id?: string
          is_active?: boolean
          name?: string
          subject?: string
          text_content?: string
          updated_at?: string
          variables?: Json
        }
        Relationships: []
      }
      embeddings: {
        Row: {
          embedding: string | null
          id: string
          post_id: string | null
        }
        Insert: {
          embedding?: string | null
          id?: string
          post_id?: string | null
        }
        Update: {
          embedding?: string | null
          id?: string
          post_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "embeddings_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
        ]
      }
      emotional_focuses: {
        Row: {
          created_at: string | null
          id: string
          updated_at: string | null
          value: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          updated_at?: string | null
          value: string
        }
        Update: {
          created_at?: string | null
          id?: string
          updated_at?: string | null
          value?: string
        }
        Relationships: []
      }
      error_logs: {
        Row: {
          additional_data: Json | null
          error_code: string | null
          error_level: string
          error_message: string
          function_name: string | null
          id: number
          ip_address: unknown | null
          line_number: number | null
          request_method: string | null
          request_path: string | null
          session_id: string | null
          source_file: string | null
          stack_trace: string | null
          timestamp: string
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          additional_data?: Json | null
          error_code?: string | null
          error_level: string
          error_message: string
          function_name?: string | null
          id?: number
          ip_address?: unknown | null
          line_number?: number | null
          request_method?: string | null
          request_path?: string | null
          session_id?: string | null
          source_file?: string | null
          stack_trace?: string | null
          timestamp?: string
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          additional_data?: Json | null
          error_code?: string | null
          error_level?: string
          error_message?: string
          function_name?: string | null
          id?: number
          ip_address?: unknown | null
          line_number?: number | null
          request_method?: string | null
          request_path?: string | null
          session_id?: string | null
          source_file?: string | null
          stack_trace?: string | null
          timestamp?: string
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      event_bookings: {
        Row: {
          attendees: number
          created_at: string | null
          date_id: string
          event_id: string
          id: string
          is_virtual: boolean
          purchase_id: string
          status: string
          ticket_code: string | null
          ticket_id: string
          updated_at: string | null
        }
        Insert: {
          attendees?: number
          created_at?: string | null
          date_id: string
          event_id: string
          id?: string
          is_virtual?: boolean
          purchase_id: string
          status: string
          ticket_code?: string | null
          ticket_id: string
          updated_at?: string | null
        }
        Update: {
          attendees?: number
          created_at?: string | null
          date_id?: string
          event_id?: string
          id?: string
          is_virtual?: boolean
          purchase_id?: string
          status?: string
          ticket_code?: string | null
          ticket_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "event_bookings_date_id_fkey"
            columns: ["date_id"]
            isOneToOne: false
            referencedRelation: "event_dates"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_bookings_date_id_fkey"
            columns: ["date_id"]
            isOneToOne: false
            referencedRelation: "event_dates_view"
            referencedColumns: ["date_id"]
          },
          {
            foreignKeyName: "event_bookings_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "event_bookings_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "event_bookings_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_bookings_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "event_bookings_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_bookings_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "event_tickets_view"
            referencedColumns: ["ticket_id"]
          },
          {
            foreignKeyName: "event_bookings_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "tickets"
            referencedColumns: ["id"]
          },
        ]
      }
      event_dates: {
        Row: {
          capacity: number | null
          current_bookings: number | null
          end_date: string
          event_id: string
          id: string
          start_date: string
          waitlist_enabled: boolean | null
        }
        Insert: {
          capacity?: number | null
          current_bookings?: number | null
          end_date: string
          event_id: string
          id?: string
          start_date: string
          waitlist_enabled?: boolean | null
        }
        Update: {
          capacity?: number | null
          current_bookings?: number | null
          end_date?: string
          event_id?: string
          id?: string
          start_date?: string
          waitlist_enabled?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "event_dates_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "event_dates_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "event_dates_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_dates_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["event_id"]
          },
        ]
      }
      events: {
        Row: {
          content: string | null
          created_at: string | null
          id: string
          post_id: string
          type: Database["public"]["Enums"]["event_type_enum"]
          updated_at: string | null
        }
        Insert: {
          content?: string | null
          created_at?: string | null
          id?: string
          post_id: string
          type: Database["public"]["Enums"]["event_type_enum"]
          updated_at?: string | null
        }
        Update: {
          content?: string | null
          created_at?: string | null
          id?: string
          post_id?: string
          type?: Database["public"]["Enums"]["event_type_enum"]
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "events_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
        ]
      }
      invoices: {
        Row: {
          amount: number
          created_at: string | null
          currency: string
          id: string
          status: string
          stripe_invoice_id: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          amount: number
          created_at?: string | null
          currency: string
          id?: string
          status?: string
          stripe_invoice_id?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          amount?: number
          created_at?: string | null
          currency?: string
          id?: string
          status?: string
          stripe_invoice_id?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "invoices_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      journal_content_links: {
        Row: {
          created_at: string
          id: number
          journal_entry_id: number
          post_id: string | null
        }
        Insert: {
          created_at?: string
          id?: never
          journal_entry_id: number
          post_id?: string | null
        }
        Update: {
          created_at?: string
          id?: never
          journal_entry_id?: number
          post_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "journal_content_links_journal_entry_id_fkey"
            columns: ["journal_entry_id"]
            isOneToOne: false
            referencedRelation: "journal_entries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_content_links_journal_entry_id_fkey"
            columns: ["journal_entry_id"]
            isOneToOne: false
            referencedRelation: "journal_entries_with_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "journal_content_links_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
        ]
      }
      journal_entries: {
        Row: {
          content: string
          created_at: string
          id: number
          mood: Database["public"]["Enums"]["mood_enum"] | null
          privacy: Database["public"]["Enums"]["journal_entry_privacy_enum"]
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          content: string
          created_at?: string
          id?: never
          mood?: Database["public"]["Enums"]["mood_enum"] | null
          privacy?: Database["public"]["Enums"]["journal_entry_privacy_enum"]
          title: string
          updated_at?: string
          user_id: string
        }
        Update: {
          content?: string
          created_at?: string
          id?: never
          mood?: Database["public"]["Enums"]["mood_enum"] | null
          privacy?: Database["public"]["Enums"]["journal_entry_privacy_enum"]
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "journal_entries_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      journal_entry_tags: {
        Row: {
          journal_entry_id: number
          tag_id: number
        }
        Insert: {
          journal_entry_id: number
          tag_id: number
        }
        Update: {
          journal_entry_id?: number
          tag_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "journal_entry_tags_journal_entry_id_fkey"
            columns: ["journal_entry_id"]
            isOneToOne: false
            referencedRelation: "journal_entries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_entry_tags_journal_entry_id_fkey"
            columns: ["journal_entry_id"]
            isOneToOne: false
            referencedRelation: "journal_entries_with_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_entry_tags_tag_id_fkey"
            columns: ["tag_id"]
            isOneToOne: false
            referencedRelation: "journal_tags"
            referencedColumns: ["id"]
          },
        ]
      }
      journal_media: {
        Row: {
          created_at: string
          id: number
          journal_entry_id: number
          media_type: string
          storage_path: string
        }
        Insert: {
          created_at?: string
          id?: never
          journal_entry_id: number
          media_type: string
          storage_path: string
        }
        Update: {
          created_at?: string
          id?: never
          journal_entry_id?: number
          media_type?: string
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "journal_media_journal_entry_id_fkey"
            columns: ["journal_entry_id"]
            isOneToOne: false
            referencedRelation: "journal_entries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_media_journal_entry_id_fkey"
            columns: ["journal_entry_id"]
            isOneToOne: false
            referencedRelation: "journal_entries_with_details"
            referencedColumns: ["id"]
          },
        ]
      }
      journal_tags: {
        Row: {
          created_at: string
          id: number
          name: string
        }
        Insert: {
          created_at?: string
          id?: never
          name: string
        }
        Update: {
          created_at?: string
          id?: never
          name?: string
        }
        Relationships: []
      }
      live_room_participants: {
        Row: {
          joined_at: string | null
          room_id: string
          user_id: string
        }
        Insert: {
          joined_at?: string | null
          room_id: string
          user_id: string
        }
        Update: {
          joined_at?: string | null
          room_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "live_room_participants_room_id_fkey"
            columns: ["room_id"]
            isOneToOne: false
            referencedRelation: "live_rooms"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_room_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      live_rooms: {
        Row: {
          created_at: string | null
          id: string
          name: string
          password: string | null
          post_id: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          name: string
          password?: string | null
          post_id?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          name?: string
          password?: string | null
          post_id?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "live_rooms_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_rooms_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      locations: {
        Row: {
          city: string | null
          coordinates: unknown | null
          coordinates_source: string | null
          coordinates_updated_at: string | null
          country: string | null
          created_at: string | null
          description: string | null
          id: string
          image_url: string | null
          line_1: string | null
          line_2: string | null
          maps_link: string | null
          name: string
          postcode: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          city?: string | null
          coordinates?: unknown | null
          coordinates_source?: string | null
          coordinates_updated_at?: string | null
          country?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          image_url?: string | null
          line_1?: string | null
          line_2?: string | null
          maps_link?: string | null
          name: string
          postcode?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          city?: string | null
          coordinates?: unknown | null
          coordinates_source?: string | null
          coordinates_updated_at?: string | null
          country?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          image_url?: string | null
          line_1?: string | null
          line_2?: string | null
          maps_link?: string | null
          name?: string
          postcode?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      meditations: {
        Row: {
          content_id: string
          id: string
          meditation_focus: string
          meditation_theme: string
          meditation_type: string
          space_holder_names: string | null
          what_to_bring: string | null
        }
        Insert: {
          content_id: string
          id?: string
          meditation_focus: string
          meditation_theme: string
          meditation_type: string
          space_holder_names?: string | null
          what_to_bring?: string | null
        }
        Update: {
          content_id?: string
          id?: string
          meditation_focus?: string
          meditation_theme?: string
          meditation_type?: string
          space_holder_names?: string | null
          what_to_bring?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "meditations_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["content_id"]
          },
          {
            foreignKeyName: "meditations_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "meditations_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "meditations_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "meditations_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "meditations_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "meditations_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "meditations_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meditations_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["on_demand_media_id"]
          },
        ]
      }
      message_reactions: {
        Row: {
          created_at: string | null
          emoji_code: string | null
          id: string
          message_id: string
          reaction_type: Database["public"]["Enums"]["reaction_type_enum"]
          user_id: string
        }
        Insert: {
          created_at?: string | null
          emoji_code?: string | null
          id?: string
          message_id: string
          reaction_type: Database["public"]["Enums"]["reaction_type_enum"]
          user_id: string
        }
        Update: {
          created_at?: string | null
          emoji_code?: string | null
          id?: string
          message_id?: string
          reaction_type?: Database["public"]["Enums"]["reaction_type_enum"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "message_reactions_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "chat_messages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "message_reactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      message_read_receipts: {
        Row: {
          id: string
          message_id: string
          read_at: string | null
          user_id: string
        }
        Insert: {
          id?: string
          message_id: string
          read_at?: string | null
          user_id: string
        }
        Update: {
          id?: string
          message_id?: string
          read_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "message_read_receipts_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "chat_messages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "message_read_receipts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      movement_props: {
        Row: {
          description: string | null
          id: string
          name: string
        }
        Insert: {
          description?: string | null
          id?: string
          name: string
        }
        Update: {
          description?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
      movement_props_join: {
        Row: {
          movement_id: string
          prop_id: string
        }
        Insert: {
          movement_id: string
          prop_id: string
        }
        Update: {
          movement_id?: string
          prop_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "movement_props_join_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "movement_props_join_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "movement_props_join_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: false
            referencedRelation: "movements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "movement_props_join_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "movement_props_join_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "movement_props_join_prop_id_fkey"
            columns: ["prop_id"]
            isOneToOne: false
            referencedRelation: "movement_props"
            referencedColumns: ["id"]
          },
        ]
      }
      movements: {
        Row: {
          body_focus: string | null
          content_id: string
          created_at: string | null
          emotional_focus: string | null
          energy_level: number
          id: string
          instructor_name: string
          recommended_environment: string | null
          session_theme: string
          spiritual_elements: string | null
          updated_at: string | null
        }
        Insert: {
          body_focus?: string | null
          content_id: string
          created_at?: string | null
          emotional_focus?: string | null
          energy_level: number
          id?: string
          instructor_name: string
          recommended_environment?: string | null
          session_theme: string
          spiritual_elements?: string | null
          updated_at?: string | null
        }
        Update: {
          body_focus?: string | null
          content_id?: string
          created_at?: string | null
          emotional_focus?: string | null
          energy_level?: number
          id?: string
          instructor_name?: string
          recommended_environment?: string | null
          session_theme?: string
          spiritual_elements?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "movements_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "accessible_media"
            referencedColumns: ["content_id"]
          },
          {
            foreignKeyName: "movements_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "ceremony_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "movements_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "dance_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "movements_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "meditation_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "movements_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "movement_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "movements_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "neuroflow_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "movements_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "on_demand_base"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "movements_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "on_demand_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "movements_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "yoga_details"
            referencedColumns: ["on_demand_media_id"]
          },
        ]
      }
      neuroflow: {
        Row: {
          id: string
          movement_id: string
          personal_growth_outcomes: string | null
          session_focus: string
          techniques_used: string
        }
        Insert: {
          id?: string
          movement_id: string
          personal_growth_outcomes?: string | null
          session_focus: string
          techniques_used: string
        }
        Update: {
          id?: string
          movement_id?: string
          personal_growth_outcomes?: string | null
          session_focus?: string
          techniques_used?: string
        }
        Relationships: [
          {
            foreignKeyName: "neuroflow_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "dance_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "neuroflow_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "movement_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "neuroflow_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "movements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "neuroflow_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "neuroflow_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "neuroflow_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "yoga_details"
            referencedColumns: ["movement_id"]
          },
        ]
      }
      notification_deliveries: {
        Row: {
          attempt_count: number
          channel: string
          created_at: string
          error_message: string | null
          external_id: string | null
          id: string
          next_attempt_at: string | null
          notification_id: string
          status: string
          updated_at: string
        }
        Insert: {
          attempt_count?: number
          channel: string
          created_at?: string
          error_message?: string | null
          external_id?: string | null
          id?: string
          next_attempt_at?: string | null
          notification_id: string
          status: string
          updated_at?: string
        }
        Update: {
          attempt_count?: number
          channel?: string
          created_at?: string
          error_message?: string | null
          external_id?: string | null
          id?: string
          next_attempt_at?: string | null
          notification_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_deliveries_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "creator_sent_notifications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_deliveries_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "notifications"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_preferences: {
        Row: {
          created_at: string
          email: boolean
          id: string
          in_app: boolean
          push: boolean
          sms: boolean
          type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          email?: boolean
          id?: string
          in_app?: boolean
          push?: boolean
          sms?: boolean
          type: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          email?: boolean
          id?: string
          in_app?: boolean
          push?: boolean
          sms?: boolean
          type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_preferences_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_read_receipts: {
        Row: {
          id: string
          notification_id: string
          read_at: string | null
          user_id: string
        }
        Insert: {
          id?: string
          notification_id: string
          read_at?: string | null
          user_id: string
        }
        Update: {
          id?: string
          notification_id?: string
          read_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_read_receipts_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "creator_sent_notifications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_read_receipts_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "notifications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_read_receipts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_recipients: {
        Row: {
          created_at: string | null
          id: string
          is_read: boolean | null
          notification_id: string
          read_at: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          is_read?: boolean | null
          notification_id: string
          read_at?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          is_read?: boolean | null
          notification_id?: string
          read_at?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_recipients_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "creator_sent_notifications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_recipients_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "notifications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_recipients_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_statistics: {
        Row: {
          channel_counts: Json
          created_at: string
          date: string
          id: string
          read_count: number
          total_count: number
          type_counts: Json
          updated_at: string
        }
        Insert: {
          channel_counts: Json
          created_at?: string
          date: string
          id?: string
          read_count: number
          total_count: number
          type_counts: Json
          updated_at?: string
        }
        Update: {
          channel_counts?: Json
          created_at?: string
          date?: string
          id?: string
          read_count?: number
          total_count?: number
          type_counts?: Json
          updated_at?: string
        }
        Relationships: []
      }
      notification_templates: {
        Row: {
          action_url: string | null
          content: string
          created_at: string | null
          creator_id: string
          id: string
          metadata: Json | null
          title: string
          type: Database["public"]["Enums"]["notification_type"]
          updated_at: string | null
        }
        Insert: {
          action_url?: string | null
          content: string
          created_at?: string | null
          creator_id: string
          id?: string
          metadata?: Json | null
          title: string
          type?: Database["public"]["Enums"]["notification_type"]
          updated_at?: string | null
        }
        Update: {
          action_url?: string | null
          content?: string
          created_at?: string | null
          creator_id?: string
          id?: string
          metadata?: Json | null
          title?: string
          type?: Database["public"]["Enums"]["notification_type"]
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "notification_templates_creator_id_fkey"
            columns: ["creator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          action_url: string | null
          audience_criteria: Json | null
          audience_type:
            | Database["public"]["Enums"]["notification_audience_type"]
            | null
          content: string
          created_at: string
          id: string
          is_read: boolean
          metadata: Json | null
          reference_id: string | null
          reference_type: string | null
          sender_id: string | null
          title: string
          type: Database["public"]["Enums"]["notification_type"]
          updated_at: string
          user_id: string
        }
        Insert: {
          action_url?: string | null
          audience_criteria?: Json | null
          audience_type?:
            | Database["public"]["Enums"]["notification_audience_type"]
            | null
          content: string
          created_at?: string
          id?: string
          is_read?: boolean
          metadata?: Json | null
          reference_id?: string | null
          reference_type?: string | null
          sender_id?: string | null
          title: string
          type: Database["public"]["Enums"]["notification_type"]
          updated_at?: string
          user_id: string
        }
        Update: {
          action_url?: string | null
          audience_criteria?: Json | null
          audience_type?:
            | Database["public"]["Enums"]["notification_audience_type"]
            | null
          content?: string
          created_at?: string
          id?: string
          is_read?: boolean
          metadata?: Json | null
          reference_id?: string | null
          reference_type?: string | null
          sender_id?: string | null
          title?: string
          type?: Database["public"]["Enums"]["notification_type"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      on_demand_media: {
        Row: {
          created_at: string | null
          duration: unknown
          id: string
          media_type: Database["public"]["Enums"]["media_type_enum"]
          post_id: string | null
          price: number
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          duration: unknown
          id?: string
          media_type: Database["public"]["Enums"]["media_type_enum"]
          post_id?: string | null
          price: number
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          duration?: unknown
          id?: string
          media_type?: Database["public"]["Enums"]["media_type_enum"]
          post_id?: string | null
          price?: number
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "on_demand_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "on_demand_media_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      onboarding_progress: {
        Row: {
          completed_at: string | null
          created_at: string
          id: string
          last_updated: string
          steps: Json
          user_id: string
        }
        Insert: {
          completed_at?: string | null
          created_at?: string
          id?: string
          last_updated?: string
          steps?: Json
          user_id: string
        }
        Update: {
          completed_at?: string | null
          created_at?: string
          id?: string
          last_updated?: string
          steps?: Json
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "onboarding_progress_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      package_access_rules: {
        Row: {
          access_type: Database["public"]["Enums"]["access_pattern_enum"]
          content_id: string | null
          created_at: string | null
          credits_required: number | null
          daily_limit: number | null
          event_id: string | null
          id: string
          monthly_limit: number | null
          package_id: string
          post_id: string | null
          post_type: string | null
          priority: number | null
          service_id: string | null
          weekly_limit: number | null
        }
        Insert: {
          access_type?: Database["public"]["Enums"]["access_pattern_enum"]
          content_id?: string | null
          created_at?: string | null
          credits_required?: number | null
          daily_limit?: number | null
          event_id?: string | null
          id?: string
          monthly_limit?: number | null
          package_id: string
          post_id?: string | null
          post_type?: string | null
          priority?: number | null
          service_id?: string | null
          weekly_limit?: number | null
        }
        Update: {
          access_type?: Database["public"]["Enums"]["access_pattern_enum"]
          content_id?: string | null
          created_at?: string | null
          credits_required?: number | null
          daily_limit?: number | null
          event_id?: string | null
          id?: string
          monthly_limit?: number | null
          package_id?: string
          post_id?: string | null
          post_type?: string | null
          priority?: number | null
          service_id?: string | null
          weekly_limit?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "package_access_rules_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["content_id"]
          },
          {
            foreignKeyName: "package_access_rules_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "package_access_rules_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "package_access_rules_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "package_access_rules_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "package_access_rules_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "package_access_rules_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "package_access_rules_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "package_access_rules_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "package_access_rules_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "package_access_rules_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "package_access_rules_package_id_fkey"
            columns: ["package_id"]
            isOneToOne: false
            referencedRelation: "universal_packages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "package_access_rules_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_access_rules_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "package_access_rules_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "package_access_rules_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      package_session_templates: {
        Row: {
          auto_schedule: boolean | null
          created_at: string | null
          description: string | null
          frequency_interval: number | null
          frequency_type: string
          id: string
          is_active: boolean | null
          name: string
          package_id: string
          preferred_days: number[] | null
          preferred_times: string[] | null
          session_duration: unknown | null
          updated_at: string | null
        }
        Insert: {
          auto_schedule?: boolean | null
          created_at?: string | null
          description?: string | null
          frequency_interval?: number | null
          frequency_type: string
          id?: string
          is_active?: boolean | null
          name: string
          package_id: string
          preferred_days?: number[] | null
          preferred_times?: string[] | null
          session_duration?: unknown | null
          updated_at?: string | null
        }
        Update: {
          auto_schedule?: boolean | null
          created_at?: string | null
          description?: string | null
          frequency_interval?: number | null
          frequency_type?: string
          id?: string
          is_active?: boolean | null
          name?: string
          package_id?: string
          preferred_days?: number[] | null
          preferred_times?: string[] | null
          session_duration?: unknown | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "package_session_templates_package_id_fkey"
            columns: ["package_id"]
            isOneToOne: false
            referencedRelation: "service_packages"
            referencedColumns: ["id"]
          },
        ]
      }
      package_usage_log: {
        Row: {
          access_date: string | null
          access_type: string
          created_at: string | null
          credits_used: number
          id: string
          metadata: Json | null
          package_purchase_id: string
          resource_id: string
        }
        Insert: {
          access_date?: string | null
          access_type: string
          created_at?: string | null
          credits_used?: number
          id?: string
          metadata?: Json | null
          package_purchase_id: string
          resource_id: string
        }
        Update: {
          access_date?: string | null
          access_type?: string
          created_at?: string | null
          credits_used?: number
          id?: string
          metadata?: Json | null
          package_purchase_id?: string
          resource_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "package_usage_log_package_purchase_id_fkey"
            columns: ["package_purchase_id"]
            isOneToOne: false
            referencedRelation: "universal_package_purchases"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_system_audits: {
        Row: {
          audit_date: string | null
          audit_results: string | null
          id: string
          system_status: string | null
        }
        Insert: {
          audit_date?: string | null
          audit_results?: string | null
          id?: string
          system_status?: string | null
        }
        Update: {
          audit_date?: string | null
          audit_results?: string | null
          id?: string
          system_status?: string | null
        }
        Relationships: []
      }
      payment_system_documentation: {
        Row: {
          created_at: string | null
          description: string
          id: string
          integration_notes: string | null
          payment_flow: string
          status: string | null
        }
        Insert: {
          created_at?: string | null
          description: string
          id?: string
          integration_notes?: string | null
          payment_flow: string
          status?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string
          id?: string
          integration_notes?: string | null
          payment_flow?: string
          status?: string | null
        }
        Relationships: []
      }
      post_emotional_focuses: {
        Row: {
          created_at: string | null
          emotional_focus_id: string
          post_id: string
        }
        Insert: {
          created_at?: string | null
          emotional_focus_id: string
          post_id: string
        }
        Update: {
          created_at?: string | null
          emotional_focus_id?: string
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_emotional_focuses_emotional_focus_id_fkey"
            columns: ["emotional_focus_id"]
            isOneToOne: false
            referencedRelation: "emotional_focuses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_emotional_focuses_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
        ]
      }
      post_locations: {
        Row: {
          created_at: string | null
          location_id: string
          post_id: string
        }
        Insert: {
          created_at?: string | null
          location_id: string
          post_id: string
        }
        Update: {
          created_at?: string | null
          location_id?: string
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_locations_location_id_fkey"
            columns: ["location_id"]
            isOneToOne: false
            referencedRelation: "locations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_locations_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
        ]
      }
      post_tags: {
        Row: {
          post_id: string
          tag_id: string
        }
        Insert: {
          post_id: string
          tag_id: string
        }
        Update: {
          post_id?: string
          tag_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_tags_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_tags_tag_id_fkey"
            columns: ["tag_id"]
            isOneToOne: false
            referencedRelation: "tags"
            referencedColumns: ["id"]
          },
        ]
      }
      posts: {
        Row: {
          content: string | null
          created_at: string | null
          description: string | null
          featured: boolean | null
          id: string
          post_type: Database["public"]["Enums"]["post_type_enum"]
          slug: string
          status: Database["public"]["Enums"]["publish_status_enum"]
          thumbnail_url: string | null
          title: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          content?: string | null
          created_at?: string | null
          description?: string | null
          featured?: boolean | null
          id?: string
          post_type: Database["public"]["Enums"]["post_type_enum"]
          slug: string
          status?: Database["public"]["Enums"]["publish_status_enum"]
          thumbnail_url?: string | null
          title: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          content?: string | null
          created_at?: string | null
          description?: string | null
          featured?: boolean | null
          id?: string
          post_type?: Database["public"]["Enums"]["post_type_enum"]
          slug?: string
          status?: Database["public"]["Enums"]["publish_status_enum"]
          thumbnail_url?: string | null
          title?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          full_name: string | null
          id: string
          updated_at: string | null
          username: string | null
          website: string | null
        }
        Insert: {
          avatar_url?: string | null
          full_name?: string | null
          id: string
          updated_at?: string | null
          username?: string | null
          website?: string | null
        }
        Update: {
          avatar_url?: string | null
          full_name?: string | null
          id?: string
          updated_at?: string | null
          username?: string | null
          website?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      protected_media_data: {
        Row: {
          content_id: string
          id: string
          status: Database["public"]["Enums"]["publish_status_enum"]
          updated_at: string | null
          url: string
        }
        Insert: {
          content_id: string
          id?: string
          status?: Database["public"]["Enums"]["publish_status_enum"]
          updated_at?: string | null
          url: string
        }
        Update: {
          content_id?: string
          id?: string
          status?: Database["public"]["Enums"]["publish_status_enum"]
          updated_at?: string | null
          url?: string
        }
        Relationships: [
          {
            foreignKeyName: "protected_media_data_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "accessible_media"
            referencedColumns: ["content_id"]
          },
          {
            foreignKeyName: "protected_media_data_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "ceremony_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "protected_media_data_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "dance_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "protected_media_data_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "meditation_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "protected_media_data_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "movement_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "protected_media_data_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "neuroflow_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "protected_media_data_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "on_demand_base"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "protected_media_data_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "on_demand_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "protected_media_data_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: true
            referencedRelation: "yoga_details"
            referencedColumns: ["on_demand_media_id"]
          },
        ]
      }
      provider_preferences: {
        Row: {
          advance_notice_hours: number
          appointment_buffer_minutes: number
          auto_confirm: boolean
          booking_window_days: number
          max_daily_appointments: number | null
          max_weekly_appointments: number | null
          timezone: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          advance_notice_hours?: number
          appointment_buffer_minutes?: number
          auto_confirm?: boolean
          booking_window_days?: number
          max_daily_appointments?: number | null
          max_weekly_appointments?: number | null
          timezone?: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          advance_notice_hours?: number
          appointment_buffer_minutes?: number
          auto_confirm?: boolean
          booking_window_days?: number
          max_daily_appointments?: number | null
          max_weekly_appointments?: number | null
          timezone?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "provider_preferences_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      purchases: {
        Row: {
          amount: number
          completed_at: string | null
          content_id: string | null
          created_at: string | null
          currency: string
          end_date: string | null
          ended_at: string | null
          event_id: string | null
          id: string
          metadata: Json | null
          owner_id: string
          payment_status: Database["public"]["Enums"]["purchase_payment_status_enum"]
          post_id: string | null
          purchase_date: string | null
          purchase_type: Database["public"]["Enums"]["purchase_type_enum"]
          quantity: number
          refunded_at: string | null
          service_id: string | null
          start_date: string | null
          stripe_customer_id: string | null
          stripe_invoice_id: string | null
          stripe_payment_intent_id: string | null
          stripe_subscription_id: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          amount: number
          completed_at?: string | null
          content_id?: string | null
          created_at?: string | null
          currency?: string
          end_date?: string | null
          ended_at?: string | null
          event_id?: string | null
          id?: string
          metadata?: Json | null
          owner_id: string
          payment_status: Database["public"]["Enums"]["purchase_payment_status_enum"]
          post_id?: string | null
          purchase_date?: string | null
          purchase_type: Database["public"]["Enums"]["purchase_type_enum"]
          quantity?: number
          refunded_at?: string | null
          service_id?: string | null
          start_date?: string | null
          stripe_customer_id?: string | null
          stripe_invoice_id?: string | null
          stripe_payment_intent_id?: string | null
          stripe_subscription_id?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          amount?: number
          completed_at?: string | null
          content_id?: string | null
          created_at?: string | null
          currency?: string
          end_date?: string | null
          ended_at?: string | null
          event_id?: string | null
          id?: string
          metadata?: Json | null
          owner_id?: string
          payment_status?: Database["public"]["Enums"]["purchase_payment_status_enum"]
          post_id?: string | null
          purchase_date?: string | null
          purchase_type?: Database["public"]["Enums"]["purchase_type_enum"]
          quantity?: number
          refunded_at?: string | null
          service_id?: string | null
          start_date?: string | null
          stripe_customer_id?: string | null
          stripe_invoice_id?: string | null
          stripe_payment_intent_id?: string | null
          stripe_subscription_id?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["content_id"]
          },
          {
            foreignKeyName: "purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "purchases_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "purchases_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "purchases_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "purchases_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      role_permissions: {
        Row: {
          id: number
          permission: Database["public"]["Enums"]["app_permission"]
          postgres_role: string
          role: Database["public"]["Enums"]["user_role"]
          schema_name: string
          scope: string
          table_name: string
        }
        Insert: {
          id?: number
          permission: Database["public"]["Enums"]["app_permission"]
          postgres_role: string
          role: Database["public"]["Enums"]["user_role"]
          schema_name: string
          scope: string
          table_name: string
        }
        Update: {
          id?: number
          permission?: Database["public"]["Enums"]["app_permission"]
          postgres_role?: string
          role?: Database["public"]["Enums"]["user_role"]
          schema_name?: string
          scope?: string
          table_name?: string
        }
        Relationships: []
      }
      room_posts: {
        Row: {
          created_at: string | null
          post_id: string
          room_id: string
        }
        Insert: {
          created_at?: string | null
          post_id: string
          room_id: string
        }
        Update: {
          created_at?: string | null
          post_id?: string
          room_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "room_posts_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "room_posts_room_id_fkey"
            columns: ["room_id"]
            isOneToOne: false
            referencedRelation: "live_rooms"
            referencedColumns: ["id"]
          },
        ]
      }
      service_bookings: {
        Row: {
          booking_id: string
          room_id: string | null
        }
        Insert: {
          booking_id: string
          room_id?: string | null
        }
        Update: {
          booking_id?: string
          room_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "service_bookings_booking_id_fkey"
            columns: ["booking_id"]
            isOneToOne: true
            referencedRelation: "bookings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_bookings_room_id_fkey"
            columns: ["room_id"]
            isOneToOne: false
            referencedRelation: "live_rooms"
            referencedColumns: ["id"]
          },
        ]
      }
      service_dates: {
        Row: {
          created_at: string | null
          end_time: string
          id: string
          service_id: string
          start_time: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          end_time: string
          id?: string
          service_id: string
          start_time: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          end_time?: string
          id?: string
          service_id?: string
          start_time?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "service_dates_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "service_dates_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "service_dates_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      service_package_purchases: {
        Row: {
          created_at: string | null
          expires_at: string | null
          id: string
          package_id: string
          purchase_id: string
          sessions_remaining: number
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          expires_at?: string | null
          id?: string
          package_id: string
          purchase_id: string
          sessions_remaining: number
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          expires_at?: string | null
          id?: string
          package_id?: string
          purchase_id?: string
          sessions_remaining?: number
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "service_package_purchases_package_id_fkey"
            columns: ["package_id"]
            isOneToOne: false
            referencedRelation: "service_packages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_package_purchases_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
        ]
      }
      service_packages: {
        Row: {
          booking_window_days: number | null
          created_at: string | null
          description: string | null
          duration_weeks: number | null
          id: string
          is_active: boolean | null
          name: string
          price: number
          scheduling_preferences: Json | null
          service_id: string
          sessions_count: number
          updated_at: string | null
        }
        Insert: {
          booking_window_days?: number | null
          created_at?: string | null
          description?: string | null
          duration_weeks?: number | null
          id?: string
          is_active?: boolean | null
          name: string
          price: number
          scheduling_preferences?: Json | null
          service_id: string
          sessions_count: number
          updated_at?: string | null
        }
        Update: {
          booking_window_days?: number | null
          created_at?: string | null
          description?: string | null
          duration_weeks?: number | null
          id?: string
          is_active?: boolean | null
          name?: string
          price?: number
          scheduling_preferences?: Json | null
          service_id?: string
          sessions_count?: number
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "service_packages_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "service_packages_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "service_packages_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      service_reservations: {
        Row: {
          created_at: string | null
          duration: unknown
          id: string
          service_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          duration: unknown
          id?: string
          service_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          duration?: unknown
          id?: string
          service_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "service_reservations_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "service_reservations_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "service_reservations_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_reservations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      services: {
        Row: {
          auto_confirm: boolean | null
          booking_workflow: string | null
          capacity: number | null
          confirmation_deadline_hours: number | null
          content: string | null
          created_at: string | null
          current_bookings: number | null
          duration: unknown
          id: string
          location_id: string | null
          original_booking_workflow: string
          post_id: string
          price: number
          type: Database["public"]["Enums"]["event_type_enum"]
          updated_at: string | null
          waitlist_enabled: boolean | null
        }
        Insert: {
          auto_confirm?: boolean | null
          booking_workflow?: string | null
          capacity?: number | null
          confirmation_deadline_hours?: number | null
          content?: string | null
          created_at?: string | null
          current_bookings?: number | null
          duration: unknown
          id?: string
          location_id?: string | null
          original_booking_workflow?: string
          post_id: string
          price: number
          type: Database["public"]["Enums"]["event_type_enum"]
          updated_at?: string | null
          waitlist_enabled?: boolean | null
        }
        Update: {
          auto_confirm?: boolean | null
          booking_workflow?: string | null
          capacity?: number | null
          confirmation_deadline_hours?: number | null
          content?: string | null
          created_at?: string | null
          current_bookings?: number | null
          duration?: unknown
          id?: string
          location_id?: string | null
          original_booking_workflow?: string
          post_id?: string
          price?: number
          type?: Database["public"]["Enums"]["event_type_enum"]
          updated_at?: string | null
          waitlist_enabled?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "services_location_id_fkey"
            columns: ["location_id"]
            isOneToOne: false
            referencedRelation: "locations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "services_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: true
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
        ]
      }
      spatial_ref_sys: {
        Row: {
          auth_name: string | null
          auth_srid: number | null
          proj4text: string | null
          srid: number
          srtext: string | null
        }
        Insert: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid: number
          srtext?: string | null
        }
        Update: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid?: number
          srtext?: string | null
        }
        Relationships: []
      }
      spotify_playlist_join: {
        Row: {
          content_id: string
          playlist_id: string
        }
        Insert: {
          content_id: string
          playlist_id: string
        }
        Update: {
          content_id?: string
          playlist_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "spotify_playlist_join_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["content_id"]
          },
          {
            foreignKeyName: "spotify_playlist_join_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "spotify_playlist_join_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "spotify_playlist_join_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "spotify_playlist_join_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "spotify_playlist_join_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "spotify_playlist_join_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "spotify_playlist_join_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "spotify_playlist_join_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "spotify_playlist_join_playlist_id_fkey"
            columns: ["playlist_id"]
            isOneToOne: false
            referencedRelation: "spotify_playlists"
            referencedColumns: ["id"]
          },
        ]
      }
      spotify_playlists: {
        Row: {
          id: string
          iframe: string
          user_id: string
        }
        Insert: {
          id?: string
          iframe: string
          user_id?: string
        }
        Update: {
          id?: string
          iframe?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "spotify_playlists_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      stripe_webhook_events: {
        Row: {
          created_at: string | null
          data: Json
          id: string
          object_id: string
          object_type: string
          processed: boolean | null
          processed_at: string | null
          processing_error: string | null
          type: string
        }
        Insert: {
          created_at?: string | null
          data: Json
          id: string
          object_id: string
          object_type: string
          processed?: boolean | null
          processed_at?: string | null
          processing_error?: string | null
          type: string
        }
        Update: {
          created_at?: string | null
          data?: Json
          id?: string
          object_id?: string
          object_type?: string
          processed?: boolean | null
          processed_at?: string | null
          processing_error?: string | null
          type?: string
        }
        Relationships: []
      }
      subscription_content_access: {
        Row: {
          content_id: string | null
          created_at: string | null
          creator_id: string
          id: string
          post_id: string | null
          post_type: string | null
          tier_key: string
        }
        Insert: {
          content_id?: string | null
          created_at?: string | null
          creator_id: string
          id?: string
          post_id?: string | null
          post_type?: string | null
          tier_key: string
        }
        Update: {
          content_id?: string | null
          created_at?: string | null
          creator_id?: string
          id?: string
          post_id?: string | null
          post_type?: string | null
          tier_key?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscription_content_access_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["content_id"]
          },
          {
            foreignKeyName: "subscription_content_access_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "subscription_content_access_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "subscription_content_access_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "subscription_content_access_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "subscription_content_access_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "subscription_content_access_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "subscription_content_access_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscription_content_access_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "subscription_content_access_creator_id_fkey"
            columns: ["creator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "accessible_media"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "subscription_content_access_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
        ]
      }
      subscriptions: {
        Row: {
          billing_cycle: string
          canceled_at: string | null
          cancels_at: string | null
          created_at: string | null
          id: string
          is_trial: boolean | null
          last_payment_date: string
          last_payment_status: string
          next_billing_date: string
          payments_count: number
          plan_name: string
          purchase_id: string
          status: string
          stripe_price_id: string
          stripe_product_id: string
          stripe_subscription_id: string
          tier: string
          total_paid: number
          trial_ends_at: string | null
          updated_at: string | null
        }
        Insert: {
          billing_cycle: string
          canceled_at?: string | null
          cancels_at?: string | null
          created_at?: string | null
          id?: string
          is_trial?: boolean | null
          last_payment_date: string
          last_payment_status: string
          next_billing_date: string
          payments_count?: number
          plan_name: string
          purchase_id: string
          status: string
          stripe_price_id: string
          stripe_product_id: string
          stripe_subscription_id: string
          tier: string
          total_paid: number
          trial_ends_at?: string | null
          updated_at?: string | null
        }
        Update: {
          billing_cycle?: string
          canceled_at?: string | null
          cancels_at?: string | null
          created_at?: string | null
          id?: string
          is_trial?: boolean | null
          last_payment_date?: string
          last_payment_status?: string
          next_billing_date?: string
          payments_count?: number
          plan_name?: string
          purchase_id?: string
          status?: string
          stripe_price_id?: string
          stripe_product_id?: string
          stripe_subscription_id?: string
          tier?: string
          total_paid?: number
          trial_ends_at?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "subscriptions_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
        ]
      }
      suggestions: {
        Row: {
          created_at: string | null
          id: string
          post_type: Database["public"]["Enums"]["post_type_enum"] | null
          suggestion: string
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          post_type?: Database["public"]["Enums"]["post_type_enum"] | null
          suggestion: string
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          post_type?: Database["public"]["Enums"]["post_type_enum"] | null
          suggestion?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "suggestions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      tags: {
        Row: {
          created_at: string | null
          id: string
          name: string
          post_type: Database["public"]["Enums"]["post_type_enum"]
        }
        Insert: {
          created_at?: string | null
          id?: string
          name: string
          post_type: Database["public"]["Enums"]["post_type_enum"]
        }
        Update: {
          created_at?: string | null
          id?: string
          name?: string
          post_type?: Database["public"]["Enums"]["post_type_enum"]
        }
        Relationships: []
      }
      tickets: {
        Row: {
          created_at: string | null
          days_before_unavailable: number | null
          description: string | null
          event_id: string
          id: string
          price: number
          quantity: number | null
          title: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          days_before_unavailable?: number | null
          description?: string | null
          event_id: string
          id?: string
          price: number
          quantity?: number | null
          title: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          days_before_unavailable?: number | null
          description?: string | null
          event_id?: string
          id?: string
          price?: number
          quantity?: number | null
          title?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "tickets_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "tickets_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "tickets_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tickets_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["event_id"]
          },
        ]
      }
      transcripts: {
        Row: {
          created_at: string | null
          error_message: string | null
          id: string
          language: string
          status: string
          transcript: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          error_message?: string | null
          id: string
          language: string
          status: string
          transcript: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          error_message?: string | null
          id?: string
          language?: string
          status?: string
          transcript?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "transcripts_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
        ]
      }
      universal_package_event_usage: {
        Row: {
          created_at: string | null
          credits_used: number
          event_booking_id: string
          event_id: string
          id: string
          original_ticket_price: number | null
          package_purchase_id: string
          ticket_id: string
          ticket_quantity: number
          usage_context: Json | null
        }
        Insert: {
          created_at?: string | null
          credits_used?: number
          event_booking_id: string
          event_id: string
          id?: string
          original_ticket_price?: number | null
          package_purchase_id: string
          ticket_id: string
          ticket_quantity?: number
          usage_context?: Json | null
        }
        Update: {
          created_at?: string | null
          credits_used?: number
          event_booking_id?: string
          event_id?: string
          id?: string
          original_ticket_price?: number | null
          package_purchase_id?: string
          ticket_id?: string
          ticket_quantity?: number
          usage_context?: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "universal_package_event_usage_event_booking_id_fkey"
            columns: ["event_booking_id"]
            isOneToOne: false
            referencedRelation: "event_bookings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "universal_package_event_usage_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "universal_package_event_usage_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "universal_package_event_usage_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "universal_package_event_usage_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "universal_package_event_usage_package_purchase_id_fkey"
            columns: ["package_purchase_id"]
            isOneToOne: false
            referencedRelation: "universal_package_purchases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "universal_package_event_usage_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "event_tickets_view"
            referencedColumns: ["ticket_id"]
          },
          {
            foreignKeyName: "universal_package_event_usage_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "tickets"
            referencedColumns: ["id"]
          },
        ]
      }
      universal_package_purchases: {
        Row: {
          activated_at: string | null
          appointment_credits_remaining: number | null
          content_credits_remaining: number | null
          created_at: string | null
          current_period_end: string | null
          current_period_start: string | null
          event_credits_remaining: number | null
          expires_at: string | null
          id: string
          is_recurring: boolean | null
          last_credit_refresh_at: string | null
          next_billing_date: string | null
          next_credit_refresh_at: string | null
          package_id: string
          purchase_id: string
          purchase_option: Database["public"]["Enums"]["purchase_option_enum"]
          status: string
          total_appointments_used: number | null
          total_content_accessed: number | null
          total_events_attended: number | null
          updated_at: string | null
        }
        Insert: {
          activated_at?: string | null
          appointment_credits_remaining?: number | null
          content_credits_remaining?: number | null
          created_at?: string | null
          current_period_end?: string | null
          current_period_start?: string | null
          event_credits_remaining?: number | null
          expires_at?: string | null
          id?: string
          is_recurring?: boolean | null
          last_credit_refresh_at?: string | null
          next_billing_date?: string | null
          next_credit_refresh_at?: string | null
          package_id: string
          purchase_id: string
          purchase_option?: Database["public"]["Enums"]["purchase_option_enum"]
          status?: string
          total_appointments_used?: number | null
          total_content_accessed?: number | null
          total_events_attended?: number | null
          updated_at?: string | null
        }
        Update: {
          activated_at?: string | null
          appointment_credits_remaining?: number | null
          content_credits_remaining?: number | null
          created_at?: string | null
          current_period_end?: string | null
          current_period_start?: string | null
          event_credits_remaining?: number | null
          expires_at?: string | null
          id?: string
          is_recurring?: boolean | null
          last_credit_refresh_at?: string | null
          next_billing_date?: string | null
          next_credit_refresh_at?: string | null
          package_id?: string
          purchase_id?: string
          purchase_option?: Database["public"]["Enums"]["purchase_option_enum"]
          status?: string
          total_appointments_used?: number | null
          total_content_accessed?: number | null
          total_events_attended?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "universal_package_purchases_package_id_fkey"
            columns: ["package_id"]
            isOneToOne: false
            referencedRelation: "universal_packages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "universal_package_purchases_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
        ]
      }
      universal_packages: {
        Row: {
          appointment_access_pattern:
            | Database["public"]["Enums"]["access_pattern_enum"]
            | null
          configuration: Json | null
          content_access_pattern:
            | Database["public"]["Enums"]["access_pattern_enum"]
            | null
          created_at: string | null
          creator_id: string
          currency: string
          description: string | null
          duration_weeks: number | null
          event_access_config: Json | null
          event_access_pattern:
            | Database["public"]["Enums"]["access_pattern_enum"]
            | null
          id: string
          is_active: boolean | null
          is_featured: boolean | null
          is_recurring: boolean | null
          is_user_defined: boolean | null
          max_active_subscriptions: number | null
          name: string
          one_time_duration_weeks: number | null
          one_time_price: number | null
          package_type: Database["public"]["Enums"]["package_access_type_enum"]
          price: number
          recurring_billing_interval: unknown
          recurring_interval_weeks: number | null
          recurring_price: number | null
          stripe_price_id: string | null
          stripe_product_id: string | null
          supports_one_time_purchase: boolean
          supports_recurring_purchase: boolean
          template_package_id: string | null
          total_appointment_credits: number | null
          total_content_credits: number | null
          total_event_credits: number | null
          updated_at: string | null
        }
        Insert: {
          appointment_access_pattern?:
            | Database["public"]["Enums"]["access_pattern_enum"]
            | null
          configuration?: Json | null
          content_access_pattern?:
            | Database["public"]["Enums"]["access_pattern_enum"]
            | null
          created_at?: string | null
          creator_id: string
          currency?: string
          description?: string | null
          duration_weeks?: number | null
          event_access_config?: Json | null
          event_access_pattern?:
            | Database["public"]["Enums"]["access_pattern_enum"]
            | null
          id?: string
          is_active?: boolean | null
          is_featured?: boolean | null
          is_recurring?: boolean | null
          is_user_defined?: boolean | null
          max_active_subscriptions?: number | null
          name: string
          one_time_duration_weeks?: number | null
          one_time_price?: number | null
          package_type?: Database["public"]["Enums"]["package_access_type_enum"]
          price: number
          recurring_billing_interval?: unknown
          recurring_interval_weeks?: number | null
          recurring_price?: number | null
          stripe_price_id?: string | null
          stripe_product_id?: string | null
          supports_one_time_purchase?: boolean
          supports_recurring_purchase?: boolean
          template_package_id?: string | null
          total_appointment_credits?: number | null
          total_content_credits?: number | null
          total_event_credits?: number | null
          updated_at?: string | null
        }
        Update: {
          appointment_access_pattern?:
            | Database["public"]["Enums"]["access_pattern_enum"]
            | null
          configuration?: Json | null
          content_access_pattern?:
            | Database["public"]["Enums"]["access_pattern_enum"]
            | null
          created_at?: string | null
          creator_id?: string
          currency?: string
          description?: string | null
          duration_weeks?: number | null
          event_access_config?: Json | null
          event_access_pattern?:
            | Database["public"]["Enums"]["access_pattern_enum"]
            | null
          id?: string
          is_active?: boolean | null
          is_featured?: boolean | null
          is_recurring?: boolean | null
          is_user_defined?: boolean | null
          max_active_subscriptions?: number | null
          name?: string
          one_time_duration_weeks?: number | null
          one_time_price?: number | null
          package_type?: Database["public"]["Enums"]["package_access_type_enum"]
          price?: number
          recurring_billing_interval?: unknown
          recurring_interval_weeks?: number | null
          recurring_price?: number | null
          stripe_price_id?: string | null
          stripe_product_id?: string | null
          supports_one_time_purchase?: boolean
          supports_recurring_purchase?: boolean
          template_package_id?: string | null
          total_appointment_credits?: number | null
          total_content_credits?: number | null
          total_event_credits?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "universal_packages_creator_id_fkey"
            columns: ["creator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "universal_packages_template_package_id_fkey"
            columns: ["template_package_id"]
            isOneToOne: false
            referencedRelation: "universal_packages"
            referencedColumns: ["id"]
          },
        ]
      }
      user_fcm_tokens: {
        Row: {
          created_at: string
          device_info: Json | null
          id: string
          is_active: boolean
          last_used_at: string | null
          token: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          device_info?: Json | null
          id?: string
          is_active?: boolean
          last_used_at?: string | null
          token: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          device_info?: Json | null
          id?: string
          is_active?: boolean
          last_used_at?: string | null
          token?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_fcm_tokens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_locations: {
        Row: {
          coordinates: unknown | null
          created_at: string | null
          location_id: string | null
          location_name: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          coordinates?: unknown | null
          created_at?: string | null
          location_id?: string | null
          location_name?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          coordinates?: unknown | null
          created_at?: string | null
          location_id?: string | null
          location_name?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_locations_location_id_fkey"
            columns: ["location_id"]
            isOneToOne: false
            referencedRelation: "locations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "ceremony_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "creator_profiles_complete_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "dance_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "meditation_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "movement_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "neuroflow_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "on_demand_base"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "post_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profile_cards_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_locations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "yoga_details"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string | null
          role: Database["public"]["Enums"]["user_role"]
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_stripe_data: {
        Row: {
          created_at: string | null
          customer_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          customer_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          customer_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_stripe_data_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_timezones: {
        Row: {
          created_at: string | null
          timezone: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          timezone?: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          timezone?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_timezones_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      video_assets: {
        Row: {
          aspect_ratio: string | null
          created_at: number | null
          duration: number | null
          encoding_tier: string | null
          errors: Json | null
          id: string
          ingest_type: string | null
          is_live: boolean | null
          live_stream_id: string | null
          master: Json | null
          master_access: string | null
          max_resolution_tier: string | null
          max_stored_frame_rate: number | null
          max_stored_resolution: string | null
          mp4_support: string | null
          non_standard_input_reasons: Json | null
          normalize_audio: boolean | null
          passthrough: Json | null
          per_title_encode: boolean | null
          playback_ids: Json | null
          recording_times: Json | null
          resolution_tier: string | null
          source_asset_id: string | null
          static_renditions: Json | null
          status: string | null
          test: boolean | null
          tracks: Json | null
          upload_id: string | null
          user_id: string
        }
        Insert: {
          aspect_ratio?: string | null
          created_at?: number | null
          duration?: number | null
          encoding_tier?: string | null
          errors?: Json | null
          id: string
          ingest_type?: string | null
          is_live?: boolean | null
          live_stream_id?: string | null
          master?: Json | null
          master_access?: string | null
          max_resolution_tier?: string | null
          max_stored_frame_rate?: number | null
          max_stored_resolution?: string | null
          mp4_support?: string | null
          non_standard_input_reasons?: Json | null
          normalize_audio?: boolean | null
          passthrough?: Json | null
          per_title_encode?: boolean | null
          playback_ids?: Json | null
          recording_times?: Json | null
          resolution_tier?: string | null
          source_asset_id?: string | null
          static_renditions?: Json | null
          status?: string | null
          test?: boolean | null
          tracks?: Json | null
          upload_id?: string | null
          user_id: string
        }
        Update: {
          aspect_ratio?: string | null
          created_at?: number | null
          duration?: number | null
          encoding_tier?: string | null
          errors?: Json | null
          id?: string
          ingest_type?: string | null
          is_live?: boolean | null
          live_stream_id?: string | null
          master?: Json | null
          master_access?: string | null
          max_resolution_tier?: string | null
          max_stored_frame_rate?: number | null
          max_stored_resolution?: string | null
          mp4_support?: string | null
          non_standard_input_reasons?: Json | null
          normalize_audio?: boolean | null
          passthrough?: Json | null
          per_title_encode?: boolean | null
          playback_ids?: Json | null
          recording_times?: Json | null
          resolution_tier?: string | null
          source_asset_id?: string | null
          static_renditions?: Json | null
          status?: string | null
          test?: boolean | null
          tracks?: Json | null
          upload_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "video_assets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      waitlist_entries: {
        Row: {
          claim_expires_at: string | null
          created_at: string | null
          email: string
          event_date_id: string | null
          event_id: string | null
          id: string
          last_notified_at: string | null
          metadata: Json | null
          notification_count: number | null
          package_id: string | null
          position: number
          service_id: string | null
          status: string
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          claim_expires_at?: string | null
          created_at?: string | null
          email: string
          event_date_id?: string | null
          event_id?: string | null
          id?: string
          last_notified_at?: string | null
          metadata?: Json | null
          notification_count?: number | null
          package_id?: string | null
          position: number
          service_id?: string | null
          status?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          claim_expires_at?: string | null
          created_at?: string | null
          email?: string
          event_date_id?: string | null
          event_id?: string | null
          id?: string
          last_notified_at?: string | null
          metadata?: Json | null
          notification_count?: number | null
          package_id?: string | null
          position?: number
          service_id?: string | null
          status?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "waitlist_entries_event_date_id_fkey"
            columns: ["event_date_id"]
            isOneToOne: false
            referencedRelation: "event_dates"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "waitlist_entries_event_date_id_fkey"
            columns: ["event_date_id"]
            isOneToOne: false
            referencedRelation: "event_dates_view"
            referencedColumns: ["date_id"]
          },
          {
            foreignKeyName: "waitlist_entries_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "waitlist_entries_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "waitlist_entries_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "waitlist_entries_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "waitlist_entries_package_id_fkey"
            columns: ["package_id"]
            isOneToOne: false
            referencedRelation: "service_packages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "waitlist_entries_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "waitlist_entries_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "waitlist_entries_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "waitlist_entries_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      waitlists: {
        Row: {
          created_at: string | null
          description: string
          id: string
          title: string
        }
        Insert: {
          created_at?: string | null
          description: string
          id?: string
          title: string
        }
        Update: {
          created_at?: string | null
          description?: string
          id?: string
          title?: string
        }
        Relationships: []
      }
      yoga: {
        Row: {
          chakras: string | null
          id: string
          movement_id: string
          yoga_style: string
        }
        Insert: {
          chakras?: string | null
          id?: string
          movement_id: string
          yoga_style: string
        }
        Update: {
          chakras?: string | null
          id?: string
          movement_id?: string
          yoga_style?: string
        }
        Relationships: [
          {
            foreignKeyName: "yoga_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "dance_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "yoga_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "movement_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "yoga_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "movements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "yoga_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "neuroflow_details"
            referencedColumns: ["movement_id"]
          },
          {
            foreignKeyName: "yoga_movement_id_fkey"
            columns: ["movement_id"]
            isOneToOne: true
            referencedRelation: "yoga_details"
            referencedColumns: ["movement_id"]
          },
        ]
      }
    }
    Views: {
      accessible_media: {
        Row: {
          access_type: string | null
          content_id: string | null
          description: string | null
          duration: unknown | null
          has_access: boolean | null
          media_type: Database["public"]["Enums"]["media_type_enum"] | null
          media_url: string | null
          post_id: string | null
          thumbnail_url: string | null
          title: string | null
        }
        Relationships: []
      }
      ceremony_details: {
        Row: {
          ceremony_focus: string | null
          ceremony_theme: string | null
          ceremony_type: string | null
          content: string | null
          created_at: string | null
          description: string | null
          duration: unknown | null
          event_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          id: string | null
          media_key: string | null
          media_type: Database["public"]["Enums"]["media_type_enum"] | null
          on_demand_created_at: string | null
          on_demand_media_id: string | null
          on_demand_updated_at: string | null
          post_type: string | null
          price: number | null
          profile_avatar_url: string | null
          profile_full_name: string | null
          profile_id: string | null
          service_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          slug: string | null
          space_holder_names: string | null
          spotify_playlist_ids: string[] | null
          spotify_playlist_iframes: string[] | null
          status: string | null
          tags: string[] | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
          user_id: string | null
          what_to_bring: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      comprehensive_events_view: {
        Row: {
          content: string | null
          created_at: string | null
          creator: Json | null
          creator_id: string | null
          dates: Json | null
          description: string | null
          event_id: string | null
          event_type: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          future_dates: Json | null
          location: Json | null
          min_price: number | null
          next_available_date: string | null
          post_id: string | null
          room: Json | null
          slug: string | null
          tags: Json | null
          thumbnail_url: string | null
          tickets: Json | null
          title: string | null
          updated_at: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["creator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      comprehensive_services_view: {
        Row: {
          appointments: Json | null
          auto_confirm: boolean | null
          availability_stats: Json | null
          booking_workflow: string | null
          confirmation_deadline_hours: number | null
          content: string | null
          created_at: string | null
          creator: Json | null
          creator_id: string | null
          description: string | null
          duration: string | null
          featured: boolean | null
          future_appointments: Json | null
          location: Json | null
          past_appointments: Json | null
          post_id: string | null
          price: number | null
          service_id: string | null
          service_type: Database["public"]["Enums"]["event_type_enum"] | null
          slug: string | null
          tags: string[] | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["creator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      creator_profiles_complete_view: {
        Row: {
          avatar_url: string | null
          background_video_url: string | null
          bio: string | null
          certifications: string[] | null
          contrast: number | null
          cover_image_url: string | null
          creator_profile_id: string | null
          creator_updated_at: string | null
          creator_user_id: string | null
          dark: boolean | null
          experience: string | null
          featured_testimonials: string[] | null
          full_name: string | null
          hue: number | null
          lightness: number | null
          philosophy: string | null
          profile_id: string | null
          profile_updated_at: string | null
          saturation: number | null
          short_bio: string | null
          title: string | null
          user_id: string | null
          user_role: Database["public"]["Enums"]["user_role"] | null
          username: string | null
          website: string | null
        }
        Relationships: [
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "creator_profiles_complete_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profile_cards_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "creator_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "creator_profiles_user_id_fkey"
            columns: ["creator_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      creator_sent_notifications: {
        Row: {
          content: string | null
          created_at: string | null
          delivered_count: number | null
          id: string | null
          recipients: Json | null
          reference_id: string | null
          reference_type: string | null
          sender_id: string | null
          title: string | null
          total_recipients: number | null
          type: Database["public"]["Enums"]["notification_type"] | null
        }
        Relationships: [
          {
            foreignKeyName: "notifications_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      dance_details: {
        Row: {
          body_focus: string | null
          content: string | null
          created_at: string | null
          description: string | null
          duration: unknown | null
          emotional_focus: string | null
          energy_level: number | null
          event_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          freeform_movement: boolean | null
          id: string | null
          instructor_name: string | null
          media_key: string | null
          media_type: Database["public"]["Enums"]["media_type_enum"] | null
          movement_created_at: string | null
          movement_id: string | null
          movement_updated_at: string | null
          on_demand_created_at: string | null
          on_demand_media_id: string | null
          on_demand_updated_at: string | null
          post_type: string | null
          price: number | null
          profile_avatar_url: string | null
          profile_full_name: string | null
          profile_id: string | null
          recommended_environment: string | null
          service_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          session_theme: string | null
          slug: string | null
          spiritual_elements: string | null
          spotify_playlist_ids: string[] | null
          spotify_playlist_iframes: string[] | null
          status: string | null
          tags: string[] | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      event_dates_view: {
        Row: {
          current_attendees: number | null
          date_id: string | null
          end_date: string | null
          event_id: string | null
          is_fully_booked: boolean | null
          is_future: boolean | null
          start_date: string | null
        }
        Insert: {
          current_attendees?: never
          date_id?: string | null
          end_date?: string | null
          event_id?: string | null
          is_fully_booked?: never
          is_future?: never
          start_date?: string | null
        }
        Update: {
          current_attendees?: never
          date_id?: string | null
          end_date?: string | null
          event_id?: string | null
          is_fully_booked?: never
          is_future?: never
          start_date?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "event_dates_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_dates_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "event_dates_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "event_dates_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["event_id"]
          },
        ]
      }
      event_details_view: {
        Row: {
          content: string | null
          created_at: string | null
          creator: Json | null
          creator_id: string | null
          description: string | null
          event_id: string | null
          event_type: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          location: Json | null
          post_id: string | null
          room: Json | null
          slug: string | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["creator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      event_tickets_view: {
        Row: {
          available_quantity: number | null
          days_before_unavailable: number | null
          description: string | null
          event_id: string | null
          is_sold_out: boolean | null
          price: number | null
          quantity: number | null
          ticket_id: string | null
          title: string | null
        }
        Insert: {
          available_quantity?: never
          days_before_unavailable?: number | null
          description?: string | null
          event_id?: string | null
          is_sold_out?: never
          price?: number | null
          quantity?: number | null
          ticket_id?: string | null
          title?: string | null
        }
        Update: {
          available_quantity?: never
          days_before_unavailable?: number | null
          description?: string | null
          event_id?: string | null
          is_sold_out?: never
          price?: number | null
          quantity?: number | null
          ticket_id?: string | null
          title?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "tickets_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tickets_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_events_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "tickets_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "event_details_view"
            referencedColumns: ["event_id"]
          },
          {
            foreignKeyName: "tickets_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events_view"
            referencedColumns: ["event_id"]
          },
        ]
      }
      events_view: {
        Row: {
          available_ticket_types_count: number | null
          content: string | null
          created_at: string | null
          creator: Json | null
          creator_id: string | null
          date_ids: string[] | null
          dates: Json | null
          description: string | null
          event_id: string | null
          event_status: string | null
          event_type: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          future_dates: Json | null
          future_dates_count: number | null
          has_available_future_dates: boolean | null
          latest_past_date: string | null
          location: Json | null
          location_name: string | null
          max_price: number | null
          min_price: number | null
          next_date: string | null
          past_dates_count: number | null
          post_id: string | null
          room: Json | null
          slug: string | null
          tags: Json | null
          thumbnail_url: string | null
          ticket_types_count: number | null
          tickets: Json | null
          title: string | null
          updated_at: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["creator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      geography_columns: {
        Row: {
          coord_dimension: number | null
          f_geography_column: unknown | null
          f_table_catalog: unknown | null
          f_table_name: unknown | null
          f_table_schema: unknown | null
          srid: number | null
          type: string | null
        }
        Relationships: []
      }
      geometry_columns: {
        Row: {
          coord_dimension: number | null
          f_geometry_column: unknown | null
          f_table_catalog: string | null
          f_table_name: unknown | null
          f_table_schema: unknown | null
          srid: number | null
          type: string | null
        }
        Insert: {
          coord_dimension?: number | null
          f_geometry_column?: unknown | null
          f_table_catalog?: string | null
          f_table_name?: unknown | null
          f_table_schema?: unknown | null
          srid?: number | null
          type?: string | null
        }
        Update: {
          coord_dimension?: number | null
          f_geometry_column?: unknown | null
          f_table_catalog?: string | null
          f_table_name?: unknown | null
          f_table_schema?: unknown | null
          srid?: number | null
          type?: string | null
        }
        Relationships: []
      }
      journal_entries_with_details: {
        Row: {
          content: string | null
          created_at: string | null
          id: number | null
          linked_content: Json | null
          media: Json | null
          mood: Database["public"]["Enums"]["mood_enum"] | null
          privacy:
            | Database["public"]["Enums"]["journal_entry_privacy_enum"]
            | null
          tags: Json | null
          title: string | null
          updated_at: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "journal_entries_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      meditation_details: {
        Row: {
          content: string | null
          created_at: string | null
          description: string | null
          duration: unknown | null
          event_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          id: string | null
          media_key: string | null
          media_type: Database["public"]["Enums"]["media_type_enum"] | null
          meditation_focus: string | null
          meditation_theme: string | null
          meditation_type: string | null
          on_demand_created_at: string | null
          on_demand_media_id: string | null
          on_demand_updated_at: string | null
          post_type: string | null
          price: number | null
          profile_avatar_url: string | null
          profile_full_name: string | null
          profile_id: string | null
          service_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          slug: string | null
          space_holder_names: string | null
          spotify_playlist_ids: string[] | null
          spotify_playlist_iframes: string[] | null
          status: string | null
          tags: string[] | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
          user_id: string | null
          what_to_bring: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      movement_details: {
        Row: {
          body_focus: string | null
          content: string | null
          created_at: string | null
          description: string | null
          duration: unknown | null
          emotional_focus: string | null
          energy_level: number | null
          event_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          id: string | null
          instructor_name: string | null
          media_key: string | null
          media_type: Database["public"]["Enums"]["media_type_enum"] | null
          movement_created_at: string | null
          movement_id: string | null
          movement_updated_at: string | null
          on_demand_created_at: string | null
          on_demand_media_id: string | null
          on_demand_updated_at: string | null
          post_type: string | null
          price: number | null
          profile_avatar_url: string | null
          profile_full_name: string | null
          profile_id: string | null
          recommended_environment: string | null
          service_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          session_theme: string | null
          slug: string | null
          spiritual_elements: string | null
          spotify_playlist_ids: string[] | null
          spotify_playlist_iframes: string[] | null
          status: string | null
          tags: string[] | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      neuroflow_details: {
        Row: {
          body_focus: string | null
          content: string | null
          created_at: string | null
          description: string | null
          duration: unknown | null
          emotional_focus: string | null
          energy_level: number | null
          event_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          id: string | null
          instructor_name: string | null
          media_key: string | null
          media_type: Database["public"]["Enums"]["media_type_enum"] | null
          movement_created_at: string | null
          movement_id: string | null
          movement_updated_at: string | null
          on_demand_created_at: string | null
          on_demand_media_id: string | null
          on_demand_updated_at: string | null
          personal_growth_outcomes: string | null
          post_type: string | null
          price: number | null
          profile_avatar_url: string | null
          profile_full_name: string | null
          profile_id: string | null
          recommended_environment: string | null
          service_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          session_focus: string | null
          session_theme: string | null
          slug: string | null
          spiritual_elements: string | null
          spotify_playlist_ids: string[] | null
          spotify_playlist_iframes: string[] | null
          status: string | null
          tags: string[] | null
          techniques_used: string | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      on_demand_base: {
        Row: {
          content: string | null
          created_at: string | null
          description: string | null
          duration: unknown | null
          event_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          id: string | null
          media_key: string | null
          media_type: Database["public"]["Enums"]["media_type_enum"] | null
          on_demand_created_at: string | null
          on_demand_media_id: string | null
          on_demand_updated_at: string | null
          post_type: string | null
          price: number | null
          profile_avatar_url: string | null
          profile_full_name: string | null
          profile_id: string | null
          service_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          slug: string | null
          spotify_playlist_ids: string[] | null
          spotify_playlist_iframes: string[] | null
          status: string | null
          tags: string[] | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_system_status: {
        Row: {
          component: string | null
          last_updated: string | null
          notes: string | null
          status: string | null
        }
        Relationships: []
      }
      pending_payment_appointments: {
        Row: {
          amount: number | null
          appointment_date: string | null
          created_at: string | null
          duration: number | null
          id: string | null
          meeting_url: string | null
          metadata: Json | null
          method: Database["public"]["Enums"]["appointment_method_enum"] | null
          notes: string | null
          owner_id: string | null
          payment_link: string | null
          payment_status:
            | Database["public"]["Enums"]["purchase_payment_status_enum"]
            | null
          purchase_id: string | null
          service_id: string | null
          service_name: string | null
          service_type: Database["public"]["Enums"]["event_type_enum"] | null
          status: Database["public"]["Enums"]["appointment_status_enum"] | null
          updated_at: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "appointment_purchases_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "purchases_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      post_details: {
        Row: {
          content: string | null
          created_at: string | null
          description: string | null
          event_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          id: string | null
          media_key: string | null
          post_type: string | null
          profile_avatar_url: string | null
          profile_full_name: string | null
          profile_id: string | null
          service_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          slug: string | null
          status: string | null
          tags: string[] | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      profile_cards_view: {
        Row: {
          avatar_url: string | null
          background_video_url: string | null
          contrast: number | null
          cover_image_url: string | null
          creator_profile_id: string | null
          creator_title: string | null
          dark: boolean | null
          full_name: string | null
          hue: number | null
          last_updated: string | null
          lightness: number | null
          saturation: number | null
          short_bio: string | null
          user_id: string | null
          user_role: Database["public"]["Enums"]["user_role"] | null
          username: string | null
          website: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      recent_errors: {
        Row: {
          additional_data: Json | null
          error_code: string | null
          error_level: string | null
          error_message: string | null
          function_name: string | null
          id: number | null
          ip_address: unknown | null
          line_number: number | null
          request_method: string | null
          request_path: string | null
          session_id: string | null
          source_file: string | null
          stack_trace: string | null
          timestamp: string | null
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          additional_data?: Json | null
          error_code?: string | null
          error_level?: string | null
          error_message?: string | null
          function_name?: string | null
          id?: number | null
          ip_address?: unknown | null
          line_number?: number | null
          request_method?: string | null
          request_path?: string | null
          session_id?: string | null
          source_file?: string | null
          stack_trace?: string | null
          timestamp?: string | null
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          additional_data?: Json | null
          error_code?: string | null
          error_level?: string | null
          error_message?: string | null
          function_name?: string | null
          id?: number | null
          ip_address?: unknown | null
          line_number?: number | null
          request_method?: string | null
          request_path?: string | null
          session_id?: string | null
          source_file?: string | null
          stack_trace?: string | null
          timestamp?: string | null
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      service_appointments_view: {
        Row: {
          appointment_date: string | null
          appointment_id: string | null
          client: Json | null
          client_id: string | null
          duration: number | null
          is_cancelled: boolean | null
          is_completed: boolean | null
          is_confirmed: boolean | null
          is_future: boolean | null
          meeting_id: string | null
          meeting_url: string | null
          method: Database["public"]["Enums"]["appointment_method_enum"] | null
          notes: string | null
          payment_status:
            | Database["public"]["Enums"]["purchase_payment_status_enum"]
            | null
          price_paid: number | null
          provider_id: string | null
          purchase_id: string | null
          service_id: string | null
          service_type:
            | Database["public"]["Enums"]["appointment_type_enum"]
            | null
          status: Database["public"]["Enums"]["appointment_status_enum"] | null
        }
        Relationships: [
          {
            foreignKeyName: "appointment_purchases_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "purchases_owner_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_user_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      service_details_view: {
        Row: {
          auto_confirm: boolean | null
          booking_workflow: string | null
          confirmation_deadline_hours: number | null
          content: string | null
          created_at: string | null
          creator: Json | null
          creator_id: string | null
          description: string | null
          duration: string | null
          featured: boolean | null
          location: Json | null
          post_id: string | null
          price: number | null
          service_id: string | null
          service_type: Database["public"]["Enums"]["event_type_enum"] | null
          slug: string | null
          tags: string[] | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["creator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_appointments_view: {
        Row: {
          amount: number | null
          appointment_date: string | null
          appointment_id: string | null
          duration: number | null
          is_future: boolean | null
          method: Database["public"]["Enums"]["appointment_method_enum"] | null
          payment_status:
            | Database["public"]["Enums"]["purchase_payment_status_enum"]
            | null
          provider_avatar: string | null
          provider_name: string | null
          purchase_id: string | null
          service_id: string | null
          service_title: string | null
          service_type:
            | Database["public"]["Enums"]["appointment_type_enum"]
            | null
          status: Database["public"]["Enums"]["appointment_status_enum"] | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "appointment_purchases_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "comprehensive_services_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "appointment_purchases_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "service_details_view"
            referencedColumns: ["service_id"]
          },
          {
            foreignKeyName: "purchases_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_journal_stats: {
        Row: {
          first_entry_date: string | null
          latest_entry_date: string | null
          mood_counts: Json | null
          total_content_links: number | null
          total_entries: number | null
          total_media_attachments: number | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "journal_entries_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_notifications_view: {
        Row: {
          action_url: string | null
          audience_type:
            | Database["public"]["Enums"]["notification_audience_type"]
            | null
          content: string | null
          created_at: string | null
          id: string | null
          is_read: boolean | null
          metadata: Json | null
          reference_id: string | null
          reference_type: string | null
          sender_id: string | null
          title: string | null
          type: Database["public"]["Enums"]["notification_type"] | null
          user_id: string | null
        }
        Relationships: []
      }
      user_notifications_with_broadcasts: {
        Row: {
          action_url: string | null
          audience_type:
            | Database["public"]["Enums"]["notification_audience_type"]
            | null
          content: string | null
          created_at: string | null
          id: string | null
          is_read: boolean | null
          metadata: Json | null
          reference_id: string | null
          reference_type: string | null
          sender_id: string | null
          title: string | null
          type: Database["public"]["Enums"]["notification_type"] | null
          user_id: string | null
        }
        Relationships: []
      }
      waitlist_details_view: {
        Row: {
          claim_expires_at: string | null
          created_at: string | null
          email: string | null
          event_info: Json | null
          id: string | null
          last_notified_at: string | null
          notification_count: number | null
          package_info: Json | null
          position: number | null
          service_info: Json | null
          status: string | null
          updated_at: string | null
          user_id: string | null
          user_info: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "waitlist_entries_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      yoga_details: {
        Row: {
          body_focus: string | null
          chakras: string | null
          content: string | null
          created_at: string | null
          description: string | null
          duration: unknown | null
          emotional_focus: string | null
          energy_level: number | null
          event_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          id: string | null
          instructor_name: string | null
          media_key: string | null
          media_type: Database["public"]["Enums"]["media_type_enum"] | null
          movement_created_at: string | null
          movement_id: string | null
          movement_updated_at: string | null
          on_demand_created_at: string | null
          on_demand_media_id: string | null
          on_demand_updated_at: string | null
          post_type: string | null
          price: number | null
          profile_avatar_url: string | null
          profile_full_name: string | null
          profile_id: string | null
          recommended_environment: string | null
          service_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          session_theme: string | null
          slug: string | null
          spiritual_elements: string | null
          spotify_playlist_ids: string[] | null
          spotify_playlist_iframes: string[] | null
          status: string | null
          tags: string[] | null
          thumbnail_url: string | null
          title: string | null
          updated_at: string | null
          user_id: string | null
          yoga_style: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      _postgis_deprecate: {
        Args: {
          oldname: string
          newname: string
          version: string
        }
        Returns: undefined
      }
      _postgis_index_extent: {
        Args: {
          tbl: unknown
          col: string
        }
        Returns: unknown
      }
      _postgis_pgsql_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      _postgis_scripts_pgsql_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      _postgis_selectivity: {
        Args: {
          tbl: unknown
          att_name: string
          geom: unknown
          mode?: string
        }
        Returns: number
      }
      _st_3dintersects: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      _st_bestsrid: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      _st_contains: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      _st_containsproperly: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      _st_coveredby:
        | {
            Args: {
              geog1: unknown
              geog2: unknown
            }
            Returns: boolean
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: boolean
          }
      _st_covers:
        | {
            Args: {
              geog1: unknown
              geog2: unknown
            }
            Returns: boolean
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: boolean
          }
      _st_crosses: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      _st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      _st_equals: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      _st_intersects: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      _st_linecrossingdirection: {
        Args: {
          line1: unknown
          line2: unknown
        }
        Returns: number
      }
      _st_longestline: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      _st_maxdistance: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: number
      }
      _st_orderingequals: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      _st_overlaps: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      _st_pointoutside: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      _st_sortablehash: {
        Args: {
          geom: unknown
        }
        Returns: number
      }
      _st_touches: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      _st_voronoi: {
        Args: {
          g1: unknown
          clip?: unknown
          tolerance?: number
          return_polygons?: boolean
        }
        Returns: unknown
      }
      _st_within: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      accept_alternative_reschedule_time: {
        Args: {
          p_appointment_id: string
          p_selected_datetime: string
          p_client_notes?: string
        }
        Returns: Json
      }
      accept_reschedule_time: {
        Args: {
          p_appointment_id: string
          p_new_datetime: string
          p_provider_notes?: string
        }
        Returns: Json
      }
      add_chat_participants: {
        Args: {
          p_chat_room_id: string
          p_user_ids: string[]
        }
        Returns: {
          chat_room_id: string
          id: string
          is_muted: boolean | null
          joined_at: string | null
          last_read_message_id: string | null
          left_at: string | null
          role: string | null
          user_id: string
        }[]
      }
      add_emotional_focuses: {
        Args: {
          p_post_id: string
          p_emotional_focuses: string[]
        }
        Returns: undefined
      }
      add_event_dates: {
        Args: {
          p_event_id: string
          p_event_dates: Database["public"]["CompositeTypes"]["event_date_input"][]
        }
        Returns: Json
      }
      add_journal_media: {
        Args: {
          p_journal_entry_id: number
          p_storage_path: string
          p_media_type: string
        }
        Returns: Json
      }
      add_movement_props: {
        Args: {
          p_movement_id: string
          p_props: string[]
        }
        Returns: undefined
      }
      add_package_access_rules: {
        Args: {
          p_package_id: string
          p_access_rules: Json
        }
        Returns: Json
      }
      add_playlist_associations: {
        Args: {
          p_content_id: string
          p_playlist_ids: string[]
        }
        Returns: undefined
      }
      add_service_to_universal_packages: {
        Args: {
          p_service_id: string
          p_package_ids: string[]
          p_credits_required?: number
          p_access_type?: Database["public"]["Enums"]["access_pattern_enum"]
          p_priority?: number
        }
        Returns: Json
      }
      add_tags_to_post: {
        Args: {
          p_post_id: string
          p_tags: string[]
        }
        Returns: undefined
      }
      add_tickets: {
        Args: {
          p_event_id: string
          p_tickets: Database["public"]["CompositeTypes"]["ticket_input"][]
        }
        Returns: undefined
      }
      addauth: {
        Args: {
          "": string
        }
        Returns: boolean
      }
      addgeometrycolumn:
        | {
            Args: {
              catalog_name: string
              schema_name: string
              table_name: string
              column_name: string
              new_srid_in: number
              new_type: string
              new_dim: number
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              schema_name: string
              table_name: string
              column_name: string
              new_srid: number
              new_type: string
              new_dim: number
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              table_name: string
              column_name: string
              new_srid: number
              new_type: string
              new_dim: number
              use_typmod?: boolean
            }
            Returns: string
          }
      approve_appointment_request: {
        Args: {
          p_appointment_id: string
          p_quoted_price: number
          p_payment_link: string
          p_notes?: string
        }
        Returns: Json
      }
      associate_post_location: {
        Args: {
          p_post_id: string
          p_location_id: string
        }
        Returns: undefined
      }
      audit_payment_system: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      authorizedas: {
        Args: {
          allowed_roles: Database["public"]["Enums"]["user_role"][]
        }
        Returns: boolean
      }
      auto_confirm_appointment_v2: {
        Args: {
          p_appointment_id: string
        }
        Returns: Json
      }
      backfill_embeddings: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      book_appointment: {
        Args: {
          p_facilitator_id: string
          p_client_id: string
          p_start_time: string
          p_end_time: string
        }
        Returns: string
      }
      book_appointment_with_package: {
        Args: {
          p_service_id: string
          p_package_purchase_id: string
          p_appointment_date: string
          p_duration?: unknown
          p_notes?: string
          p_booking_workflow?: string
        }
        Returns: {
          client_id: string | null
          created_at: string | null
          end_time: string
          facilitator_id: string | null
          id: string
          package_purchase_id: string | null
          start_time: string
          status: string | null
          updated_at: string | null
        }
      }
      book_event_with_credits: {
        Args: {
          p_package_purchase_id: string
          p_event_id: string
          p_date_id: string
          p_ticket_id: string
          p_quantity?: number
        }
        Returns: Json
      }
      box:
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
      box2d:
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
      box2d_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      box2d_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      box2df_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      box2df_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      box3d:
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
      box3d_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      box3d_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      box3dtobox: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      build_appointment_action_buttons: {
        Args: {
          p_status: string
          p_appointment_id: string
          p_payment_url?: string
          p_meeting_url?: string
        }
        Returns: Json
      }
      build_appointment_message_content: {
        Args: {
          p_status: string
          p_service_name: string
          p_appointment_date: string
          p_client_name: string
          p_owner_name: string
          p_payment_amount?: number
          p_service_type?: string
          p_meeting_url?: string
          p_location_info?: Json
        }
        Returns: string
      }
      bulk_book_package_sessions: {
        Args: {
          p_package_purchase_id: string
          p_session_dates: string[]
          p_notes?: string
        }
        Returns: Json
      }
      bytea:
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
      calculate_distance: {
        Args: {
          point1: unknown
          point2: unknown
          unit?: string
        }
        Returns: number
      }
      can_access_appointment: {
        Args: {
          service_id: string
          appointment_date: string
        }
        Returns: boolean
      }
      can_access_content: {
        Args: {
          content_id: string
        }
        Returns: boolean
      }
      can_access_content_enhanced: {
        Args: {
          p_content_id: string
        }
        Returns: boolean
      }
      can_access_content_v2: {
        Args: {
          input_content_id: string
        }
        Returns: boolean
      }
      can_access_event: {
        Args: {
          event_id: string
          date_id: string
        }
        Returns: boolean
      }
      can_access_with_package: {
        Args: {
          p_access_type: string
          p_resource_id: string
        }
        Returns: Json
      }
      can_attend_event: {
        Args: {
          p_event_id: string
          p_date_id: string
        }
        Returns: boolean
      }
      can_book_event_with_credits: {
        Args: {
          p_user_id: string
          p_event_id: string
          p_ticket_id: string
          p_quantity?: number
        }
        Returns: Json
      }
      cancel_appointment_request: {
        Args: {
          p_appointment_id: string
          p_reason?: string
          p_minimum_hours_before?: number
        }
        Returns: Json
      }
      cancel_package_subscription: {
        Args: {
          p_package_purchase_id: string
          p_immediate?: boolean
        }
        Returns: Json
      }
      check_capacity_and_notify_waitlist: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      check_schedule_conflicts: {
        Args: {
          p_provider_id: string
          p_start_time: string
          p_end_time: string
          p_exclude_appointment_id?: string
        }
        Returns: boolean
      }
      claim_waitlist_spot: {
        Args: {
          p_waitlist_entry_id: string
          p_user_id?: string
        }
        Returns: Json
      }
      cleanup_old_notifications: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      create_appointment_chat_room: {
        Args: {
          p_appointment_id: string
          p_client_id: string
          p_owner_id: string
          p_service_name?: string
          p_appointment_date?: string
        }
        Returns: string
      }
      create_appointment_request: {
        Args: {
          p_service_id: string
          p_appointment_date: string
          p_duration?: unknown
          p_notes?: string
          p_package_purchase_id?: string
        }
        Returns: {
          client_id: string | null
          created_at: string | null
          end_time: string
          facilitator_id: string | null
          id: string
          package_purchase_id: string | null
          start_time: string
          status: string | null
          updated_at: string | null
        }
      }
      create_article_content_with_details: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["article_content_creation_result"]
      }
      create_broadcast_announcement: {
        Args: {
          p_title: string
          p_content: string
          p_action_url?: string
          p_reference_id?: string
          p_reference_type?: string
          p_metadata?: Json
          p_audience_type?: Database["public"]["Enums"]["notification_audience_type"]
          p_audience_criteria?: Json
        }
        Returns: string
      }
      create_ceremony_content_with_details: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_playlist_ids: string[]
          p_ceremony_type: string
          p_ceremony_theme: string
          p_ceremony_focus: string
          p_what_to_bring: string
          p_space_holder_names: string
          p_user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["ceremony_content_creation_result"]
      }
      create_dance_content_with_details: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_emotional_focuses: string[]
          p_playlist_ids: string[]
          p_instructor_name: string
          p_session_theme: string
          p_energy_level: number
          p_spiritual_elements: string
          p_emotional_focus: string
          p_recommended_environment: string
          p_body_focus: string
          p_props: string[]
          p_freeform_movement: boolean
          p_user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["dance_content_creation_result"]
      }
      create_default_access_rules_for_templates: {
        Args: {
          p_creator_id?: string
        }
        Returns: Json
      }
      create_default_package_templates: {
        Args: {
          p_creator_id?: string
        }
        Returns: Json
      }
      create_event: {
        Args: {
          p_post_id: string
          p_content: string
          p_event_type: Database["public"]["Enums"]["event_type_enum"]
        }
        Returns: string
      }
      create_event_purchase: {
        Args: {
          p_event_id: string
          p_ticket_id: string
          p_date_id: string
          p_quantity: number
          p_is_virtual?: boolean
          p_payment_intent_id?: string
          p_payment_status?: string
        }
        Returns: Json
      }
      create_event_with_details: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_event_type: Database["public"]["Enums"]["event_type_enum"]
          p_event_dates: Database["public"]["CompositeTypes"]["event_date_input"][]
          p_tickets: Database["public"]["CompositeTypes"]["ticket_input"][]
          p_room_name?: string
          p_room_password?: string
          p_location_id?: string
          user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["event_creation_result"]
      }
      create_follower_broadcast: {
        Args: {
          p_follower_ids: string[]
          p_title: string
          p_content: string
          p_action_url?: string
          p_reference_id?: string
          p_reference_type?: string
          p_metadata?: Json
        }
        Returns: string
      }
      create_generic_ondemand_content: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_emotional_focuses: string[]
          p_playlist_ids: string[]
          p_user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["generic_ondemand_content_creation_result"]
      }
      create_journal_entry: {
        Args: {
          p_user_id: string
          p_title: string
          p_content: string
          p_mood?: Database["public"]["Enums"]["mood_enum"]
          p_privacy?: Database["public"]["Enums"]["journal_entry_privacy_enum"]
          p_tags?: string[]
          p_post_id?: string
        }
        Returns: Json
      }
      create_live_room: {
        Args: {
          p_post_id: string
          p_name: string
          p_password?: string
        }
        Returns: string
      }
      create_location: {
        Args: {
          p_name: string
          p_description: string
          p_image_url: string
          p_line_1: string
          p_line_2: string
          p_city: string
          p_country: string
          p_postcode: string
          p_maps_link: string
        }
        Returns: string
      }
      create_meditation_content_with_details: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_playlist_ids: string[]
          p_meditation_type: string
          p_meditation_theme: string
          p_meditation_focus: string
          p_user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["meditation_content_creation_result"]
      }
      create_movement: {
        Args: {
          p_content_id: string
          p_instructor_name: string
          p_session_theme: string
          p_energy_level: number
          p_spiritual_elements: string
          p_emotional_focus: string
          p_recommended_environment: string
          p_body_focus: string
        }
        Returns: string
      }
      create_neuroflow_content_with_details: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_emotional_focuses: string[]
          p_playlist_ids: string[]
          p_instructor_name: string
          p_session_theme: string
          p_energy_level: number
          p_spiritual_elements: string
          p_emotional_focus: string
          p_recommended_environment: string
          p_body_focus: string
          p_props: string[]
          p_techniques_used: string
          p_session_focus: string
          p_personal_growth_outcomes: string
          p_user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["neuroflow_content_creation_result"]
      }
      create_notification: {
        Args: {
          p_user_id: string
          p_sender_id: string
          p_title: string
          p_content: string
          p_type: string
          p_priority?: string
          p_related_entity_id?: string
          p_action?: string
          p_metadata?: Json
        }
        Returns: string
      }
      create_notification_for_all_users: {
        Args: {
          p_title: string
          p_content: string
          p_type: string
          p_action_url?: string
          p_reference_id?: string
          p_reference_type?: string
          p_metadata?: Json
        }
        Returns: number
      }
      create_notifications_batch: {
        Args: {
          p_user_ids: string[]
          p_sender_id: string
          p_title: string
          p_content: string
          p_type: string
          p_priority?: string
          p_related_entity_id?: string
          p_action?: string
          p_metadata?: Json
        }
        Returns: string[]
      }
      create_ondemand_content_with_details: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_post_type: Database["public"]["Enums"]["post_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_emotional_focuses: string[]
          p_playlist_ids: string[]
          p_instructor_name: string
          p_session_theme: string
          p_energy_level: number
          p_spiritual_elements: string
          p_emotional_focus: string
          p_recommended_environment: string
          p_body_focus: string
          p_props: string[]
          p_user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["ondemand_content_creation_result"]
      }
      create_ondemand_media: {
        Args: {
          p_post_id: string
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_user_id?: string
        }
        Returns: string
      }
      create_or_get_private_chat: {
        Args: {
          p_user_id1: string
          p_user_id2: string
        }
        Returns: string
      }
      create_or_update_appointment_message: {
        Args: {
          p_chat_room_id: string
          p_sender_id: string
          p_appointment_id: string
          p_status: string
          p_message_content: string
          p_action_buttons?: Json
          p_appointment_context?: Json
        }
        Returns: string
      }
      create_or_update_batched_chat_notification: {
        Args: {
          p_user_id: string
          p_sender_id: string
          p_chat_id: string
          p_message_preview: string
        }
        Returns: string
      }
      create_package_session_template: {
        Args: {
          p_package_id: string
          p_name: string
          p_frequency_type: string
          p_frequency_interval?: number
          p_preferred_days?: number[]
          p_preferred_times?: string[]
          p_description?: string
          p_auto_schedule?: boolean
        }
        Returns: {
          auto_schedule: boolean | null
          created_at: string | null
          description: string | null
          frequency_interval: number | null
          frequency_type: string
          id: string
          is_active: boolean | null
          name: string
          package_id: string
          preferred_days: number[] | null
          preferred_times: string[] | null
          session_duration: unknown | null
          updated_at: string | null
        }
      }
      create_payment_action_button: {
        Args: {
          p_appointment_id: string
          p_amount?: number
        }
        Returns: Json
      }
      create_post: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_post_type: Database["public"]["Enums"]["post_type_enum"]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_thumbnail_url: string
          p_user_id?: string
        }
        Returns: string
      }
      create_protected_media_data: {
        Args: {
          p_content_id: string
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_url: string
        }
        Returns: string
      }
      create_service_content_with_details: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_location_id: string
          p_price: number
          p_duration: unknown
          p_type: Database["public"]["Enums"]["event_type_enum"]
          p_booking_workflow?: string
          p_auto_confirm?: boolean
          p_confirmation_deadline_hours?: number
          p_capacity?: number
          p_waitlist_enabled?: boolean
          user_id?: string
          p_universal_package_ids?: string[]
          p_package_credits_required?: number
          p_package_access_type?: Database["public"]["Enums"]["access_pattern_enum"]
          p_package_priority?: number
        }
        Returns: Database["public"]["CompositeTypes"]["service_content_with_packages_result"]
      }
      create_universal_package: {
        Args: {
          p_name: string
          p_description?: string
          p_package_type?: Database["public"]["Enums"]["package_access_type_enum"]
          p_supports_one_time_purchase?: boolean
          p_supports_recurring_purchase?: boolean
          p_one_time_price?: number
          p_recurring_price?: number
          p_one_time_duration_weeks?: number
          p_recurring_billing_interval?: unknown
          p_currency?: string
          p_appointment_credits?: number
          p_content_credits?: number
          p_event_credits?: number
          p_post_credits?: number
          p_is_active?: boolean
          p_requires_approval?: boolean
          p_availability_start?: string
          p_availability_end?: string
          p_max_purchases?: number
          p_purchase_limit_per_user?: number
        }
        Returns: Database["public"]["CompositeTypes"]["create_universal_package_result"]
      }
      create_user_defined_package: {
        Args: {
          p_template_package_id: string
          p_custom_name: string
          p_appointment_credits?: number
          p_content_credits?: number
          p_event_credits?: number
          p_duration_weeks?: number
          p_is_recurring?: boolean
        }
        Returns: Json
      }
      create_yoga: {
        Args: {
          p_movement_id: string
          p_yoga_style: string
          p_chakras: string
        }
        Returns: string
      }
      create_yoga_content_with_details: {
        Args: {
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_emotional_focuses: string[]
          p_playlist_ids: string[]
          p_instructor_name: string
          p_session_theme: string
          p_energy_level: number
          p_spiritual_elements: string
          p_emotional_focus: string
          p_recommended_environment: string
          p_body_focus: string
          p_props: string[]
          p_yoga_style: string
          p_chakras: string
          p_user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["yoga_content_creation_result"]
      }
      custom_access_token_hook: {
        Args: {
          event: Json
        }
        Returns: Json
      }
      deactivate_fcm_token: {
        Args: {
          p_token: string
        }
        Returns: boolean
      }
      debug_notification_type: {
        Args: Record<PropertyKey, never>
        Returns: {
          enumlabel: string
        }[]
      }
      delete_playlist: {
        Args: {
          user_id: string
          iframe: string
        }
        Returns: undefined
      }
      disablelongtransactions: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      dropgeometrycolumn:
        | {
            Args: {
              catalog_name: string
              schema_name: string
              table_name: string
              column_name: string
            }
            Returns: string
          }
        | {
            Args: {
              schema_name: string
              table_name: string
              column_name: string
            }
            Returns: string
          }
        | {
            Args: {
              table_name: string
              column_name: string
            }
            Returns: string
          }
      dropgeometrytable:
        | {
            Args: {
              catalog_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | {
            Args: {
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | {
            Args: {
              table_name: string
            }
            Returns: string
          }
      enablelongtransactions: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      equals: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      exec_sql: {
        Args: {
          sql_query: string
          params?: Json
        }
        Returns: Json
      }
      filter_events: {
        Args: {
          filters?: Json
        }
        Returns: {
          event_id: string
          post_id: string
          slug: string
          title: string
          description: string
          thumbnail_url: string
          event_type: Database["public"]["Enums"]["event_type_enum"]
          location_name: string
          location: Json
          creator: Json
          featured: boolean
          next_date: string
          latest_past_date: string
          min_price: number
          tags: Json
          event_status: string
          has_available_tickets: boolean
          distance: number
          attendees_count: number
          date_attendees: Json
          total_count: number
        }[]
      }
      filter_service_appointments: {
        Args: {
          filters: Json
        }
        Returns: {
          appointment_id: string
          service_id: string
          post_id: string
          service_title: string
          appointment_date: string
          duration: unknown
          method: string
          service_type: string
          status: string
          client_id: string
          client_name: string
          client_avatar: string
          price: number
          is_future: boolean
          total_count: number
        }[]
      }
      find_nearby_locations: {
        Args: {
          lat: number
          lon: number
          radius_km?: number
          limit_count?: number
        }
        Returns: {
          id: string
          name: string
          distance_km: number
          line_1: string
          city: string
          postcode: string
          country: string
        }[]
      }
      find_nearby_users: {
        Args: {
          lat: number
          lon: number
          radius_km?: number
          limit_count?: number
        }
        Returns: {
          user_id: string
          distance_km: number
          location_id: string
        }[]
      }
      gbt_bit_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_bool_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_bool_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_bpchar_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_bytea_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_cash_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_cash_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_date_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_date_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_decompress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_enum_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_enum_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_float4_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_float4_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_float8_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_float8_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_inet_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_int2_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_int2_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_int4_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_int4_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_int8_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_int8_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_intv_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_intv_decompress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_intv_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_macad_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_macad_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_macad8_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_macad8_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_numeric_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_oid_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_oid_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_text_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_time_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_time_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_timetz_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_ts_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_ts_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_tstz_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_uuid_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_uuid_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_var_decompress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbt_var_fetch: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey_var_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey_var_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey16_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey16_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey2_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey2_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey32_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey32_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey4_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey4_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey8_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gbtreekey8_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      generate_coordinates_text: {
        Args: {
          line1: string
          line2: string
          city: string
          postcode: string
          country: string
        }
        Returns: string
      }
      generate_meeting_url: {
        Args: {
          p_appointment_id: string
        }
        Returns: string
      }
      generate_payment_link: {
        Args: {
          p_appointment_id: string
          p_amount: number
          p_currency?: string
          p_description?: string
        }
        Returns: string
      }
      generate_random_comment: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      geography:
        | {
            Args: {
              "": string
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
      geography_analyze: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      geography_gist_compress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geography_gist_decompress: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geography_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geography_send: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      geography_spgist_compress_nd: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geography_typmod_in: {
        Args: {
          "": unknown[]
        }
        Returns: number
      }
      geography_typmod_out: {
        Args: {
          "": number
        }
        Returns: unknown
      }
      geometry:
        | {
            Args: {
              "": string
            }
            Returns: unknown
          }
        | {
            Args: {
              "": string
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
      geometry_above: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_analyze: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      geometry_below: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_cmp: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: number
      }
      geometry_contained_3d: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_contains: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_contains_3d: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_distance_box: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: number
      }
      geometry_distance_centroid: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: number
      }
      geometry_eq: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_ge: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_gist_compress_2d: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geometry_gist_compress_nd: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geometry_gist_decompress_2d: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geometry_gist_decompress_nd: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geometry_gist_sortsupport_2d: {
        Args: {
          "": unknown
        }
        Returns: undefined
      }
      geometry_gt: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_hash: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      geometry_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geometry_le: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_left: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_lt: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geometry_overabove: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_overbelow: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_overlaps: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_overlaps_3d: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_overleft: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_overright: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_recv: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geometry_right: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_same: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_same_3d: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometry_send: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      geometry_sortsupport: {
        Args: {
          "": unknown
        }
        Returns: undefined
      }
      geometry_spgist_compress_2d: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geometry_spgist_compress_3d: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geometry_spgist_compress_nd: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      geometry_typmod_in: {
        Args: {
          "": unknown[]
        }
        Returns: number
      }
      geometry_typmod_out: {
        Args: {
          "": number
        }
        Returns: unknown
      }
      geometry_within: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      geometrytype:
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
      geomfromewkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      geomfromewkt: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      get_active_chat_messages: {
        Args: {
          p_chat_room_id: string
          p_limit?: number
          p_before?: string
        }
        Returns: {
          message_id: string
          sender_id: string
          sender_name: string
          message: string
          message_type: string
          action_buttons: Json
          appointment_context: Json
          created_at: string
          status: string
          is_superseded: boolean
        }[]
      }
      get_all_sales: {
        Args: {
          filters: Json
        }
        Returns: {
          id: string
          customername: string
          customeremail: string
          amount: number
          status: string
          type: string
          date: string
          productname: string
        }[]
      }
      get_appointment_sales: {
        Args: {
          filters: Json
        }
        Returns: {
          id: string
          customername: string
          customeremail: string
          amount: number
          status: string
          bookingdate: string
          appointmentdate: string
          duration: number
          servicename: string
          servicetype: string
          method: string
          notes: string
        }[]
      }
      get_availability: {
        Args: {
          p_user_id: string
        }
        Returns: {
          day: string
          is_active: boolean
          start_time: string
          end_time: string
        }[]
      }
      get_available_slots: {
        Args: {
          p_facilitator_id: string
          p_start_date: string
          p_end_date: string
        }
        Returns: {
          start_time: string
          end_time: string
        }[]
      }
      get_chat_messages: {
        Args: {
          p_chat_room_id: string
          p_limit?: number
          p_before?: string
          p_after?: string
          p_around_message_id?: string
        }
        Returns: {
          message_id: string
          sender_id: string
          sender_name: string
          message: string
          created_at: string
          status: Database["public"]["Enums"]["message_status_enum"]
          reply_to_message_id: string
          reply_to_message_text: string
          is_edited: boolean
          read_by_count: number
        }[]
      }
      get_chat_messages_simple: {
        Args: {
          p_chat_room_id: string
        }
        Returns: {
          message_id: string
          sender_id: string
          sender_name: string
          message: string
          created_at: string
          status: Database["public"]["Enums"]["message_status_enum"]
          reply_to_message_id: string
          reply_to_message_text: string
          is_edited: boolean
          read_by_count: number
        }[]
      }
      get_chat_messages_with_reactions: {
        Args: {
          p_chat_room_id: string
          p_limit?: number
          p_before?: string
          p_after?: string
          p_around_message_id?: string
        }
        Returns: {
          message_id: string
          sender_id: string
          sender_name: string
          message: string
          message_type: string
          action_buttons: Json
          appointment_context: Json
          created_at: string
          status: Database["public"]["Enums"]["message_status_enum"]
          reply_to_message_id: string
          reply_to_message_text: string
          is_edited: boolean
          read_by_count: number
          reactions: Json
          superseded_by: string
        }[]
      }
      get_comment_tree: {
        Args: {
          in_post_id: string
        }
        Returns: {
          id: number
          user_id: string
          post_id: string
          comment: string
          created_at: string
          updated_at: string
          deleted_at: string
          parent_id: number
          score: number
          is_edited: boolean
          depth: number
          reactions: Json
          attachments: Json
          mentions: Json
          author_name: string
          author_avatar: string
          path: number[]
        }[]
      }
      get_comments: {
        Args: {
          in_post_id: string
          in_limit?: number
          in_offset?: number
        }
        Returns: {
          id: number
          user_id: string
          post_id: string
          comment: string
          created_at: string
          updated_at: string
          deleted_at: string
          parent_id: number
          score: number
          is_edited: boolean
          depth: number
          reactions: Json
          attachments: Json
          mentions: Json
          author_name: string
          author_avatar: string
        }[]
      }
      get_comprehensive_service_details: {
        Args: {
          p_service_slug: string
          p_user_id?: string
        }
        Returns: {
          service_id: string
          service_slug: string
          service_title: string
          service_description: string
          service_content: string
          service_price: number
          service_duration: unknown
          service_type: Database["public"]["Enums"]["event_type_enum"]
          service_capacity: number
          service_current_bookings: number
          service_auto_confirm: boolean
          service_booking_workflow: string
          service_thumbnail_url: string
          service_tags: string[]
          service_status: string
          creator_id: string
          creator_name: string
          creator_avatar_url: string
          creator_username: string
          location_id: string
          location_name: string
          location_address: string
          associated_packages: Database["public"]["CompositeTypes"]["universal_package_detail"][]
          user_appointments: Database["public"]["CompositeTypes"]["user_appointment_detail"][]
          user_package_purchases: Database["public"]["CompositeTypes"]["user_package_purchase_detail"][]
          user_available_credits: Database["public"]["CompositeTypes"]["user_credits_summary"]
          user_can_access_service: boolean
          user_upcoming_appointments: Database["public"]["CompositeTypes"]["user_upcoming_appointment"][]
        }[]
      }
      get_content_sales: {
        Args: {
          filters: Json
        }
        Returns: {
          id: string
          customername: string
          customeremail: string
          amount: number
          status: string
          date: string
          contenttitle: string
          contenttype: string
          downloadcount: number
          issubscription: boolean
        }[]
      }
      get_creator_package_analytics: {
        Args: {
          p_creator_id?: string
          p_date_range_days?: number
        }
        Returns: Json
      }
      get_current_appointment_message: {
        Args: {
          p_appointment_id: string
        }
        Returns: {
          message_id: string
          chat_room_id: string
          message_content: string
          action_buttons: Json
          appointment_context: Json
          created_at: string
        }[]
      }
      get_enhanced_event_details: {
        Args: {
          event_slug: string
        }
        Returns: {
          event_details: Json
        }[]
      }
      get_event_bookings: {
        Args: {
          filters: Json
        }
        Returns: {
          id: string
          customername: string
          customeremail: string
          amount: number
          status: string
          bookingdate: string
          eventtitle: string
          eventdate: string
          attendees: number
          location: string
          isvirtual: boolean
        }[]
      }
      get_event_cards: {
        Args: {
          user_lat?: number
          user_lon?: number
          event_types?: Database["public"]["Enums"]["event_type_enum"][]
          time_filter?: string
          distance_limit?: number
          page_size?: number
          page_number?: number
          only_featured?: boolean
          user_ids?: string[]
        }
        Returns: {
          id: string
          slug: string
          title: string
          description: string
          thumbnail_url: string
          event_type: Database["public"]["Enums"]["event_type_enum"]
          location_name: string
          next_date: string
          available_tickets: number
          min_price: number
          distance: number
          total_count: number
          author: Json
          featured: boolean
        }[]
      }
      get_event_details: {
        Args: {
          event_slug: string
        }
        Returns: {
          id: string
          slug: string
          title: string
          description: string
          content: string
          thumbnail_url: string
          event_type: Database["public"]["Enums"]["event_type_enum"]
          featured: boolean
          created_at: string
          updated_at: string
          location: Json
          future_dates: Json[]
          tickets: Json[]
          author: Json
        }[]
      }
      get_filtered_movement_content: {
        Args: {
          input_post_ids?: string[]
          input_featured?: boolean
          post_type_array?: Database["public"]["Enums"]["post_type_enum"][]
          search_title?: string
          min_duration?: number
          max_duration?: number
          min_energy_level?: number
          max_energy_level?: number
          min_price?: number
          max_price?: number
          tag_array?: string[]
          p_limit?: number
          p_offset?: number
          p_media_key?: string
        }
        Returns: {
          post_id: string
          post_type: Database["public"]["Enums"]["post_type_enum"]
          title: string
          slug: string
          description: string
          thumbnail_url: string
          media_type: Database["public"]["Enums"]["media_type_enum"]
          duration: unknown
          price: number
          instructor_name: string
          session_theme: string
          energy_level: number
          spiritual_elements: string
          emotional_focus: string
          recommended_environment: string
          body_focus: string
          tags: string
          total_count: number
          featured: boolean
          updated_at: string
          media_key: string
        }[]
      }
      get_journal_entries: {
        Args: {
          p_user_id?: string
          p_tag_names?: string[]
          p_start_date?: string
          p_end_date?: string
          p_mood?: Database["public"]["Enums"]["mood_enum"]
          p_limit?: number
          p_offset?: number
        }
        Returns: Json
      }
      get_message_reactions: {
        Args: {
          p_message_id: string
        }
        Returns: {
          reaction_type: Database["public"]["Enums"]["reaction_type_enum"]
          emoji_code: string
          count: number
          user_ids: string[]
          user_has_reacted: boolean
        }[]
      }
      get_on_page_ceremony: {
        Args: {
          p_slug: string
        }
        Returns: {
          ceremony_details: Json
          protected_media_url: string
        }[]
      }
      get_on_page_dance: {
        Args: {
          p_slug: string
        }
        Returns: {
          dance_details: Json
          protected_media_url: string
        }[]
      }
      get_on_page_meditation: {
        Args: {
          p_slug: string
        }
        Returns: {
          meditation_details: Json
          protected_media_url: string
        }[]
      }
      get_on_page_neuro_flow: {
        Args: {
          p_slug: string
        }
        Returns: {
          neuroflow_details: Json
          protected_media_url: string
        }[]
      }
      get_on_page_yoga: {
        Args: {
          p_slug: string
        }
        Returns: {
          yoga_details: Json
          protected_media_url: string
        }[]
      }
      get_or_create_appointment_chat: {
        Args: {
          p_appointment_id: string
          p_client_id: string
          p_owner_id: string
          p_service_name?: string
          p_appointment_date?: string
        }
        Returns: string
      }
      get_package_booking_dashboard: {
        Args: {
          p_package_purchase_id: string
        }
        Returns: Json
      }
      get_package_pricing_options: {
        Args: {
          p_package_id: string
        }
        Returns: Json
      }
      get_package_purchase_details: {
        Args: {
          p_package_purchase_id: string
        }
        Returns: Json
      }
      get_package_usage_stats: {
        Args: {
          p_service_id: string
          p_package_id?: string
        }
        Returns: {
          package_id: string
          package_name: string
          total_purchases: number
          total_sessions_sold: number
          sessions_used: number
          sessions_remaining: number
          revenue: number
          active_customers: number
        }[]
      }
      get_pending_appointments: {
        Args: {
          p_facilitator_id: string
          p_start_date: string
          p_end_date: string
        }
        Returns: {
          appointment_id: string
          client_id: string
          start_time: string
          end_time: string
        }[]
      }
      get_post_type_tags: {
        Args: {
          post_type: Database["public"]["Enums"]["post_type_enum"]
        }
        Returns: {
          tag_id: string
          tag_name: string
        }[]
      }
      get_potential_recipients: {
        Args: {
          p_params: Json
        }
        Returns: {
          recipient_id: string
          name: string
          email: string
          group_type: string
          avatar_url: string
          appointment_id: string
          booking_id: string
          appointment_date: string
          post_title: string
          tickets_count: number
        }[]
      }
      get_proj4_from_srid: {
        Args: {
          "": number
        }
        Returns: string
      }
      get_protected_media_url: {
        Args: {
          content_id: string
        }
        Returns: string
      }
      get_protected_media_url_v2: {
        Args: {
          content_id: string
        }
        Returns: string
      }
      get_provider_availability: {
        Args: {
          p_provider_id: string
          p_start_date: string
          p_end_date: string
          p_slot_length_minutes: number
        }
        Returns: {
          date: string
          available_slots: Json
        }[]
      }
      get_reschedule_availability: {
        Args: {
          p_appointment_id: string
          p_days_ahead?: number
        }
        Returns: Json
      }
      get_sent_notifications: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_type?: string
          p_reference_id?: string
          p_start_date?: string
          p_end_date?: string
        }
        Returns: {
          id: string
          title: string
          content: string
          type: Database["public"]["Enums"]["notification_type"]
          reference_id: string
          reference_type: string
          created_at: string
          recipient_count: number
          read_count: number
        }[]
      }
      get_service_calendar_availability: {
        Args: {
          p_service_id: string
          p_days_ahead?: number
          p_timezone?: string
        }
        Returns: Json
      }
      get_service_details: {
        Args: {
          service_slug: string
        }
        Returns: Json
      }
      get_service_workflow_status: {
        Args: {
          p_service_id: string
        }
        Returns: Json
      }
      get_smart_comments: {
        Args: {
          in_post_id: string
          in_limit?: number
          in_offset?: number
          in_sort_by?: string
          in_show_replies?: boolean
          in_min_score?: number
        }
        Returns: {
          id: number
          content: string
          author_id: string
          author_name: string
          author_avatar: string
          created_at: string
          updated_at: string
          parent_id: number
          reactions: Json
          is_edited: boolean
          depth: number
          deleted_at: string
          has_replies: boolean
        }[]
      }
      get_subscriptions: {
        Args: {
          filters: Json
        }
        Returns: {
          id: string
          customername: string
          customeremail: string
          plan: string
          tier: string
          billingcycle: string
          amount: number
          status: string
          startdate: string
          nextbillingdate: string
          totalpaid: number
          paymentscount: number
          lastpaymentstatus: string
          lastpaymentdate: string
        }[]
      }
      get_suggested_appointments: {
        Args: {
          p_user_id: string
          p_start_date: string
          p_end_date: string
        }
        Returns: {
          appointment_id: string
          facilitator_id: string
          client_id: string
          start_time: string
          end_time: string
        }[]
      }
      get_upcoming_events: {
        Args: {
          user_lat?: number
          user_lon?: number
          event_types?: Database["public"]["Enums"]["event_type_enum"][]
          distance_limit?: number
          page_size?: number
          page_number?: number
          only_featured?: boolean
          creator_ids?: string[]
          tag_filter?: string[]
        }
        Returns: {
          event_id: string
          post_id: string
          slug: string
          title: string
          description: string
          thumbnail_url: string
          event_type: Database["public"]["Enums"]["event_type_enum"]
          location_name: string
          next_date: string
          available_tickets: boolean
          min_price: number
          distance: number
          total_count: number
          creator: Json
          featured: boolean
          tags: Json
        }[]
      }
      get_upcoming_service_appointments: {
        Args: {
          provider_id?: string
          limit_count?: number
        }
        Returns: {
          appointment_id: string
          service_id: string
          post_id: string
          service_title: string
          appointment_date: string
          duration: unknown
          method: string
          service_type: string
          status: string
          client_name: string
          client_avatar: string
          price: number
        }[]
      }
      get_user_appointments: {
        Args: {
          p_user_id?: string
          p_status?: string
          p_limit?: number
          p_offset?: number
        }
        Returns: Json
      }
      get_user_chat_rooms:
        | {
            Args: Record<PropertyKey, never>
            Returns: {
              room_id: string
              room_name: string
              room_type: Database["public"]["Enums"]["chat_type_enum"]
              room_description: string
              is_broadcast: boolean
              created_at: string
              updated_at: string
              latest_message: string
              latest_message_id: string
              latest_message_sender: string
              latest_message_time: string
              unread_count: number
              associated_appointment_id: string
              metadata: Json
              auto_notifications: boolean
              pinned_message_id: string
            }[]
          }
        | {
            Args: {
              p_user_id: string
            }
            Returns: {
              room_id: string
              room_name: string
              room_type: Database["public"]["Enums"]["chat_type_enum"]
              room_description: string
              is_broadcast: boolean
              created_at: string
              updated_at: string
              latest_message: string
              latest_message_id: string
              latest_message_sender: string
              latest_message_time: string
              unread_count: number
              associated_appointment_id: string
              metadata: Json
              auto_notifications: boolean
              pinned_message_id: string
            }[]
          }
      get_user_chat_rooms_filtered: {
        Args: {
          p_user_id?: string
          p_chat_types?: string[]
          p_has_appointment?: boolean
          p_appointment_status?: string
          p_has_unread?: boolean
          p_search_text?: string
          p_limit?: number
          p_offset?: number
        }
        Returns: {
          room_id: string
          room_name: string
          room_type: Database["public"]["Enums"]["chat_type_enum"]
          room_description: string
          is_broadcast: boolean
          created_at: string
          updated_at: string
          latest_message: string
          latest_message_id: string
          latest_message_sender: string
          latest_message_time: string
          unread_count: number
          associated_appointment_id: string
          metadata: Json
          auto_notifications: boolean
          pinned_message_id: string
          appointment_status: string
          appointment_date: string
          service_name: string
        }[]
      }
      get_user_event_purchases: {
        Args: {
          p_status?: string
        }
        Returns: {
          purchase_id: string
          event_id: string
          post_id: string
          title: string
          slug: string
          thumbnail_url: string
          ticket_id: string
          ticket_name: string
          ticket_price: number
          date_id: string
          event_date: string
          event_end_date: string
          purchase_date: string
          attendees: number
          amount: number
          payment_status: string
          booking_status: string
          ticket_code: string
          is_virtual: boolean
          event_type: Database["public"]["Enums"]["event_type_enum"]
          location: Json
          room: Json
        }[]
      }
      get_user_location: {
        Args: {
          user_uuid?: string
        }
        Returns: {
          latitude: number
          longitude: number
          location_id: string
          location_name: string
        }[]
      }
      get_user_packages_dashboard: {
        Args: {
          p_user_id?: string
        }
        Returns: Json
      }
      get_user_service_appointments: {
        Args: {
          user_id?: string
        }
        Returns: {
          appointment_id: string
          purchase_id: string
          service_id: string
          service_title: string
          provider_name: string
          provider_avatar: string
          appointment_date: string
          duration: number
          method: string
          service_type: string
          status: string
          payment_status: string
          amount: number
          is_future: boolean
        }[]
      }
      get_user_service_packages: {
        Args: {
          p_service_id: string
          p_user_id?: string
        }
        Returns: {
          package_purchase_id: string
          package_name: string
          sessions_remaining: number
          total_sessions: number
          expires_at: string
          purchase_date: string
        }[]
      }
      gettransactionid: {
        Args: Record<PropertyKey, never>
        Returns: unknown
      }
      gidx_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      gidx_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      grant_public_read_access: {
        Args: {
          table_name: string
        }
        Returns: undefined
      }
      handle_appointment_request: {
        Args: {
          p_service_id: string
          p_user_id: string
          p_owner_id: string
          p_post_id: string
          p_appointment_date: string
          p_duration: number
          p_method?: string
          p_message?: string
        }
        Returns: Json
      }
      has_active_subscription: {
        Args: {
          subscription_creator_id: string
          required_tier_key?: string
        }
        Returns: boolean
      }
      has_role: {
        Args: {
          role_to_check: string
        }
        Returns: boolean
      }
      hourly_waitlist_processor: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      iana_to_utc_offset: {
        Args: {
          iana_timezone: string
        }
        Returns: Database["public"]["Enums"]["timezone"]
      }
      insert_playlist: {
        Args: {
          iframe: string
        }
        Returns: undefined
      }
      is_creator_or_admin: {
        Args: Record<PropertyKey, never>
        Returns: boolean
      }
      isowned: {
        Args: {
          input_user_id?: string
        }
        Returns: boolean
      }
      isownedfolder: {
        Args: {
          object_name: string
        }
        Returns: boolean
      }
      join_waitlist: {
        Args: {
          p_user_id: string
          p_email: string
          p_service_id?: string
          p_event_id?: string
          p_event_date_id?: string
          p_package_id?: string
        }
        Returns: {
          claim_expires_at: string | null
          created_at: string | null
          email: string
          event_date_id: string | null
          event_id: string | null
          id: string
          last_notified_at: string | null
          metadata: Json | null
          notification_count: number | null
          package_id: string | null
          position: number
          service_id: string | null
          status: string
          updated_at: string | null
          user_id: string | null
        }
      }
      json: {
        Args: {
          "": unknown
        }
        Returns: Json
      }
      jsonb: {
        Args: {
          "": unknown
        }
        Returns: Json
      }
      leave_comment: {
        Args: {
          in_post_id: string
          in_comment: string
          in_parent_id?: number
          in_attachments?: Json
          in_mentions?: Json
        }
        Returns: number
      }
      legacy_create_notification: {
        Args: {
          p_user_id: string
          p_title: string
          p_content: string
          p_type: string
          p_action_url?: string
          p_reference_id?: string
          p_reference_type?: string
          p_metadata?: Json
        }
        Returns: string
      }
      link_journal_to_content: {
        Args: {
          p_journal_entry_id: number
          p_post_id: string
        }
        Returns: Json
      }
      lock_provider_schedule: {
        Args: {
          p_provider_id: string
        }
        Returns: number
      }
      log_error: {
        Args: {
          p_error_level: string
          p_error_message: string
          p_error_code?: string
          p_source_file?: string
          p_line_number?: number
          p_function_name?: string
          p_user_id?: string
          p_session_id?: string
          p_request_path?: string
          p_request_method?: string
          p_ip_address?: unknown
          p_user_agent?: string
          p_stack_trace?: string
          p_additional_data?: Json
        }
        Returns: undefined
      }
      longtransactionsenabled: {
        Args: Record<PropertyKey, never>
        Returns: boolean
      }
      manage_service_package: {
        Args: {
          p_service_id: string
          p_name: string
          p_sessions_count: number
          p_price: number
          p_booking_window_days?: number
          p_package_id?: string
          p_description?: string
          p_duration_weeks?: number
          p_is_active?: boolean
        }
        Returns: {
          booking_window_days: number | null
          created_at: string | null
          description: string | null
          duration_weeks: number | null
          id: string
          is_active: boolean | null
          name: string
          price: number
          scheduling_preferences: Json | null
          service_id: string
          sessions_count: number
          updated_at: string | null
        }
      }
      mark_all_notifications_as_read: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      mark_broadcast_notification_read: {
        Args: {
          p_notification_id: string
          p_user_id?: string
        }
        Returns: boolean
      }
      mark_message_as_read: {
        Args: {
          p_message_id: string
          p_user_id: string
        }
        Returns: boolean
      }
      mark_notification_as_read: {
        Args: {
          p_notification_id: string
        }
        Returns: boolean
      }
      mark_notifications_as_read:
        | {
            Args: {
              p_notification_ids: string[]
              p_user_id?: string
            }
            Returns: undefined
          }
        | {
            Args: {
              p_notification_ids?: string[]
              p_mark_all?: boolean
            }
            Returns: number
          }
      notify_event_attendees: {
        Args: {
          p_event_id: string
          p_title: string
          p_content: string
          p_action_url?: string
          p_metadata?: Json
        }
        Returns: number
      }
      notify_service_subscribers: {
        Args: {
          p_service_id: string
          p_title: string
          p_content: string
          p_action_url?: string
          p_metadata?: Json
        }
        Returns: number
      }
      notify_waitlist_manually: {
        Args: {
          p_service_id?: string
          p_event_date_id?: string
          p_package_id?: string
          p_message?: string
        }
        Returns: number
      }
      path: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      pgis_asflatgeobuf_finalfn: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      pgis_asgeobuf_finalfn: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      pgis_asmvt_finalfn: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      pgis_asmvt_serialfn: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      pgis_geometry_clusterintersecting_finalfn: {
        Args: {
          "": unknown
        }
        Returns: unknown[]
      }
      pgis_geometry_clusterwithin_finalfn: {
        Args: {
          "": unknown
        }
        Returns: unknown[]
      }
      pgis_geometry_collect_finalfn: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      pgis_geometry_makeline_finalfn: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      pgis_geometry_polygonize_finalfn: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      pgis_geometry_union_parallel_finalfn: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      pgis_geometry_union_parallel_serialfn: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      point: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      polygon: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      populate_geometry_columns:
        | {
            Args: {
              tbl_oid: unknown
              use_typmod?: boolean
            }
            Returns: number
          }
        | {
            Args: {
              use_typmod?: boolean
            }
            Returns: string
          }
      postgis_addbbox: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      postgis_constraint_dims: {
        Args: {
          geomschema: string
          geomtable: string
          geomcolumn: string
        }
        Returns: number
      }
      postgis_constraint_srid: {
        Args: {
          geomschema: string
          geomtable: string
          geomcolumn: string
        }
        Returns: number
      }
      postgis_constraint_type: {
        Args: {
          geomschema: string
          geomtable: string
          geomcolumn: string
        }
        Returns: string
      }
      postgis_dropbbox: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      postgis_extensions_upgrade: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_full_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_geos_noop: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      postgis_geos_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_getbbox: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      postgis_hasbbox: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      postgis_index_supportfn: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      postgis_lib_build_date: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_lib_revision: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_lib_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_libjson_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_liblwgeom_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_libprotobuf_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_libxml_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_noop: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      postgis_proj_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_scripts_build_date: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_scripts_installed: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_scripts_released: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_svn_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_type_name: {
        Args: {
          geomname: string
          coord_dimension: number
          use_new_name?: boolean
        }
        Returns: string
      }
      postgis_typmod_dims: {
        Args: {
          "": number
        }
        Returns: number
      }
      postgis_typmod_srid: {
        Args: {
          "": number
        }
        Returns: number
      }
      postgis_typmod_type: {
        Args: {
          "": number
        }
        Returns: string
      }
      postgis_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      postgis_wagyu_version: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      prepare_package_for_stripe: {
        Args: {
          p_package_id: string
        }
        Returns: Json
      }
      process_appointment_payment: {
        Args: {
          p_purchase_id: string
          p_payment_intent_id: string
          p_service_id: string
          p_appointment_date: string
          p_duration?: number
          p_method?: Database["public"]["Enums"]["appointment_method_enum"]
          p_service_type?: Database["public"]["Enums"]["appointment_type_enum"]
          p_notes?: string
        }
        Returns: Json
      }
      process_appointment_payment_confirmation: {
        Args: {
          p_purchase_id: string
          p_payment_intent_id: string
        }
        Returns: Json
      }
      process_appointment_payment_v2: {
        Args: {
          p_appointment_id: string
          p_payment_status: string
        }
        Returns: Json
      }
      process_event_booking_payment: {
        Args: {
          p_purchase_id: string
          p_payment_intent_id: string
          p_ticket_id: string
          p_date_id: string
          p_attendees?: number
          p_is_virtual?: boolean
        }
        Returns: Json
      }
      process_expired_waitlist_claims: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      process_invoice_paid:
        | {
            Args: {
              event_data: Json
            }
            Returns: undefined
          }
        | {
            Args: {
              invoice_id: string
              event_data: Json
            }
            Returns: string
          }
      process_invoice_payment_failed: {
        Args: {
          invoice_id: string
          subscription_id: string
          invoice_data: Json
        }
        Returns: undefined
      }
      process_package_purchase_payment: {
        Args: {
          p_purchase_id: string
          p_payment_intent_id: string
          p_package_id: string
          p_service_id: string
        }
        Returns: Json
      }
      process_payment_intent_succeeded: {
        Args: {
          payment_intent_id: string
          event_data: Json
        }
        Returns: string
      }
      process_payment_webhook: {
        Args: {
          p_appointment_id: string
          p_payment_status: string
          p_transaction_reference?: string
          p_payment_method?: string
          p_failure_reason?: string
        }
        Returns: Json
      }
      process_pending_notifications: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      process_subscription_updated: {
        Args: {
          subscription_id: string
          event_data: Json
        }
        Returns: string
      }
      process_universal_package_purchase_payment: {
        Args: {
          p_purchase_id: string
          p_payment_intent_id: string
          p_package_id: string
        }
        Returns: Json
      }
      propose_alternative_reschedule_times: {
        Args: {
          p_appointment_id: string
          p_alternative_times: Json
          p_provider_notes?: string
        }
        Returns: Json
      }
      purchase_service_package: {
        Args: {
          p_package_id: string
          p_amount: number
          p_stripe_payment_intent_id?: string
          p_user_id?: string
          p_currency?: string
        }
        Returns: Json
      }
      purchase_universal_package: {
        Args: {
          p_package_id: string
          p_purchase_option: Database["public"]["Enums"]["purchase_option_enum"]
          p_purchase_id?: string
          p_user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["purchase_universal_package_result"]
      }
      query_embeddings: {
        Args: {
          query_embedding: string
          match_threshold: number
        }
        Returns: {
          embedding: string | null
          id: string
          post_id: string | null
        }[]
      }
      query_video_assets: {
        Args: {
          track_filter?: string
          status_filter?: string
          p_limit?: number
          p_offset?: number
        }
        Returns: {
          assets: Database["public"]["CompositeTypes"]["video_asset_type"][]
          total_count: number
        }[]
      }
      random_future_date: {
        Args: {
          days_ahead: number
        }
        Returns: string
      }
      random_name: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      random_timestamp: {
        Args: {
          start_date: string
          end_date: string
        }
        Returns: string
      }
      refresh_package_credits: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      refresh_universal_package_credits: {
        Args: {
          p_purchase_id: string
        }
        Returns: undefined
      }
      regenerate_appointment_action_buttons: {
        Args: {
          p_appointment_id: string
        }
        Returns: Json
      }
      register_fcm_token: {
        Args: {
          p_token: string
          p_device_info?: Json
        }
        Returns: string
      }
      remove_service_from_universal_packages: {
        Args: {
          p_service_id: string
          p_package_ids?: string[]
        }
        Returns: Json
      }
      request_appointment_reschedule: {
        Args: {
          p_appointment_id: string
          p_suggested_times: Json
          p_client_notes?: string
        }
        Returns: Json
      }
      request_service_appointment: {
        Args: {
          p_service_id: string
          p_requested_date: string
          p_duration?: number
          p_method?: string
          p_service_type?: string
          p_notes?: string
          p_client_id?: string
        }
        Returns: Json
      }
      reschedule_appointment_direct: {
        Args: {
          p_appointment_id: string
          p_new_date: string
          p_duration?: number
          p_message?: string
        }
        Returns: Json
      }
      reschedule_package_session: {
        Args: {
          p_appointment_id: string
          p_new_date: string
          p_reason?: string
        }
        Returns: Json
      }
      respond_to_appointment: {
        Args: {
          p_appointment_id: string
          p_action: string
          p_new_start_time?: string
          p_new_end_time?: string
        }
        Returns: undefined
      }
      respond_to_appointment_request:
        | {
            Args: {
              p_appointment_id: string
              p_action: string
              p_alternative_time?: string
              p_provider_notes?: string
              p_base_url?: string
            }
            Returns: Json
          }
        | {
            Args: {
              p_appointment_id: string
              p_action: string
              p_quoted_price?: number
              p_payment_link?: string
              p_notes?: string
            }
            Returns: Json
          }
      run_seed_comments: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      sanitize_slug: {
        Args: {
          input: string
        }
        Returns: string
      }
      seed_comments: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      set_availability: {
        Args: {
          p_user_id: string
          p_day: string
          p_is_active: boolean
          p_start_time: string
          p_end_time: string
        }
        Returns: undefined
      }
      set_service_original_workflow: {
        Args: {
          p_service_id: string
          p_original_workflow: string
        }
        Returns: undefined
      }
      set_user_timezone_claim: {
        Args: {
          token: Json
          claims: Json
        }
        Returns: Json
      }
      spheroid_in: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      spheroid_out: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_3dclosestpoint: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_3ddistance: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: number
      }
      st_3dintersects: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      st_3dlength: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_3dlongestline: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_3dmakebox: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_3dmaxdistance: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: number
      }
      st_3dperimeter: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_3dshortestline: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_addpoint: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_angle:
        | {
            Args: {
              line1: unknown
              line2: unknown
            }
            Returns: number
          }
        | {
            Args: {
              pt1: unknown
              pt2: unknown
              pt3: unknown
              pt4?: unknown
            }
            Returns: number
          }
      st_area:
        | {
            Args: {
              "": string
            }
            Returns: number
          }
        | {
            Args: {
              "": unknown
            }
            Returns: number
          }
        | {
            Args: {
              geog: unknown
              use_spheroid?: boolean
            }
            Returns: number
          }
      st_area2d: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_asbinary:
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
      st_asencodedpolyline: {
        Args: {
          geom: unknown
          nprecision?: number
        }
        Returns: string
      }
      st_asewkb: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      st_asewkt:
        | {
            Args: {
              "": string
            }
            Returns: string
          }
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
      st_asgeojson:
        | {
            Args: {
              "": string
            }
            Returns: string
          }
        | {
            Args: {
              geog: unknown
              maxdecimaldigits?: number
              options?: number
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              maxdecimaldigits?: number
              options?: number
            }
            Returns: string
          }
        | {
            Args: {
              r: Record<string, unknown>
              geom_column?: string
              maxdecimaldigits?: number
              pretty_bool?: boolean
            }
            Returns: string
          }
      st_asgml:
        | {
            Args: {
              "": string
            }
            Returns: string
          }
        | {
            Args: {
              geog: unknown
              maxdecimaldigits?: number
              options?: number
              nprefix?: string
              id?: string
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              maxdecimaldigits?: number
              options?: number
            }
            Returns: string
          }
        | {
            Args: {
              version: number
              geog: unknown
              maxdecimaldigits?: number
              options?: number
              nprefix?: string
              id?: string
            }
            Returns: string
          }
        | {
            Args: {
              version: number
              geom: unknown
              maxdecimaldigits?: number
              options?: number
              nprefix?: string
              id?: string
            }
            Returns: string
          }
      st_ashexewkb: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      st_askml:
        | {
            Args: {
              "": string
            }
            Returns: string
          }
        | {
            Args: {
              geog: unknown
              maxdecimaldigits?: number
              nprefix?: string
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              maxdecimaldigits?: number
              nprefix?: string
            }
            Returns: string
          }
      st_aslatlontext: {
        Args: {
          geom: unknown
          tmpl?: string
        }
        Returns: string
      }
      st_asmarc21: {
        Args: {
          geom: unknown
          format?: string
        }
        Returns: string
      }
      st_asmvtgeom: {
        Args: {
          geom: unknown
          bounds: unknown
          extent?: number
          buffer?: number
          clip_geom?: boolean
        }
        Returns: unknown
      }
      st_assvg:
        | {
            Args: {
              "": string
            }
            Returns: string
          }
        | {
            Args: {
              geog: unknown
              rel?: number
              maxdecimaldigits?: number
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              rel?: number
              maxdecimaldigits?: number
            }
            Returns: string
          }
      st_astext:
        | {
            Args: {
              "": string
            }
            Returns: string
          }
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
      st_astwkb:
        | {
            Args: {
              geom: unknown[]
              ids: number[]
              prec?: number
              prec_z?: number
              prec_m?: number
              with_sizes?: boolean
              with_boxes?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              prec?: number
              prec_z?: number
              prec_m?: number
              with_sizes?: boolean
              with_boxes?: boolean
            }
            Returns: string
          }
      st_asx3d: {
        Args: {
          geom: unknown
          maxdecimaldigits?: number
          options?: number
        }
        Returns: string
      }
      st_azimuth:
        | {
            Args: {
              geog1: unknown
              geog2: unknown
            }
            Returns: number
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: number
          }
      st_boundary: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_boundingdiagonal: {
        Args: {
          geom: unknown
          fits?: boolean
        }
        Returns: unknown
      }
      st_buffer:
        | {
            Args: {
              geom: unknown
              radius: number
              options?: string
            }
            Returns: unknown
          }
        | {
            Args: {
              geom: unknown
              radius: number
              quadsegs: number
            }
            Returns: unknown
          }
      st_buildarea: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_centroid:
        | {
            Args: {
              "": string
            }
            Returns: unknown
          }
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
      st_cleangeometry: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_clipbybox2d: {
        Args: {
          geom: unknown
          box: unknown
        }
        Returns: unknown
      }
      st_closestpoint: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_clusterintersecting: {
        Args: {
          "": unknown[]
        }
        Returns: unknown[]
      }
      st_collect:
        | {
            Args: {
              "": unknown[]
            }
            Returns: unknown
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: unknown
          }
      st_collectionextract: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_collectionhomogenize: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_concavehull: {
        Args: {
          param_geom: unknown
          param_pctconvex: number
          param_allow_holes?: boolean
        }
        Returns: unknown
      }
      st_contains: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      st_containsproperly: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      st_convexhull: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_coorddim: {
        Args: {
          geometry: unknown
        }
        Returns: number
      }
      st_coveredby:
        | {
            Args: {
              geog1: unknown
              geog2: unknown
            }
            Returns: boolean
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: boolean
          }
      st_covers:
        | {
            Args: {
              geog1: unknown
              geog2: unknown
            }
            Returns: boolean
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: boolean
          }
      st_crosses: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      st_curvetoline: {
        Args: {
          geom: unknown
          tol?: number
          toltype?: number
          flags?: number
        }
        Returns: unknown
      }
      st_delaunaytriangles: {
        Args: {
          g1: unknown
          tolerance?: number
          flags?: number
        }
        Returns: unknown
      }
      st_difference: {
        Args: {
          geom1: unknown
          geom2: unknown
          gridsize?: number
        }
        Returns: unknown
      }
      st_dimension: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_disjoint: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      st_distance:
        | {
            Args: {
              geog1: unknown
              geog2: unknown
              use_spheroid?: boolean
            }
            Returns: number
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: number
          }
      st_distancesphere:
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: number
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
              radius: number
            }
            Returns: number
          }
      st_distancespheroid: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: number
      }
      st_dump: {
        Args: {
          "": unknown
        }
        Returns: Database["public"]["CompositeTypes"]["geometry_dump"][]
      }
      st_dumppoints: {
        Args: {
          "": unknown
        }
        Returns: Database["public"]["CompositeTypes"]["geometry_dump"][]
      }
      st_dumprings: {
        Args: {
          "": unknown
        }
        Returns: Database["public"]["CompositeTypes"]["geometry_dump"][]
      }
      st_dumpsegments: {
        Args: {
          "": unknown
        }
        Returns: Database["public"]["CompositeTypes"]["geometry_dump"][]
      }
      st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      st_endpoint: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_envelope: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_equals: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      st_expand:
        | {
            Args: {
              box: unknown
              dx: number
              dy: number
            }
            Returns: unknown
          }
        | {
            Args: {
              box: unknown
              dx: number
              dy: number
              dz?: number
            }
            Returns: unknown
          }
        | {
            Args: {
              geom: unknown
              dx: number
              dy: number
              dz?: number
              dm?: number
            }
            Returns: unknown
          }
      st_exteriorring: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_flipcoordinates: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_force2d: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_force3d: {
        Args: {
          geom: unknown
          zvalue?: number
        }
        Returns: unknown
      }
      st_force3dm: {
        Args: {
          geom: unknown
          mvalue?: number
        }
        Returns: unknown
      }
      st_force3dz: {
        Args: {
          geom: unknown
          zvalue?: number
        }
        Returns: unknown
      }
      st_force4d: {
        Args: {
          geom: unknown
          zvalue?: number
          mvalue?: number
        }
        Returns: unknown
      }
      st_forcecollection: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_forcecurve: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_forcepolygonccw: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_forcepolygoncw: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_forcerhr: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_forcesfs: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_generatepoints:
        | {
            Args: {
              area: unknown
              npoints: number
            }
            Returns: unknown
          }
        | {
            Args: {
              area: unknown
              npoints: number
              seed: number
            }
            Returns: unknown
          }
      st_geogfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geogfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geographyfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geohash:
        | {
            Args: {
              geog: unknown
              maxchars?: number
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              maxchars?: number
            }
            Returns: string
          }
      st_geomcollfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geomcollfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geometricmedian: {
        Args: {
          g: unknown
          tolerance?: number
          max_iter?: number
          fail_if_not_converged?: boolean
        }
        Returns: unknown
      }
      st_geometryfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geometrytype: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      st_geomfromewkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geomfromewkt: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geomfromgeojson:
        | {
            Args: {
              "": Json
            }
            Returns: unknown
          }
        | {
            Args: {
              "": Json
            }
            Returns: unknown
          }
        | {
            Args: {
              "": string
            }
            Returns: unknown
          }
      st_geomfromgml: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geomfromkml: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geomfrommarc21: {
        Args: {
          marc21xml: string
        }
        Returns: unknown
      }
      st_geomfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geomfromtwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_geomfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_gmltosql: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_hasarc: {
        Args: {
          geometry: unknown
        }
        Returns: boolean
      }
      st_hausdorffdistance: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: number
      }
      st_hexagon: {
        Args: {
          size: number
          cell_i: number
          cell_j: number
          origin?: unknown
        }
        Returns: unknown
      }
      st_hexagongrid: {
        Args: {
          size: number
          bounds: unknown
        }
        Returns: Record<string, unknown>[]
      }
      st_interpolatepoint: {
        Args: {
          line: unknown
          point: unknown
        }
        Returns: number
      }
      st_intersection: {
        Args: {
          geom1: unknown
          geom2: unknown
          gridsize?: number
        }
        Returns: unknown
      }
      st_intersects:
        | {
            Args: {
              geog1: unknown
              geog2: unknown
            }
            Returns: boolean
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: boolean
          }
      st_isclosed: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      st_iscollection: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      st_isempty: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      st_ispolygonccw: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      st_ispolygoncw: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      st_isring: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      st_issimple: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      st_isvalid: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      st_isvaliddetail: {
        Args: {
          geom: unknown
          flags?: number
        }
        Returns: Database["public"]["CompositeTypes"]["valid_detail"]
      }
      st_isvalidreason: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      st_isvalidtrajectory: {
        Args: {
          "": unknown
        }
        Returns: boolean
      }
      st_length:
        | {
            Args: {
              "": string
            }
            Returns: number
          }
        | {
            Args: {
              "": unknown
            }
            Returns: number
          }
        | {
            Args: {
              geog: unknown
              use_spheroid?: boolean
            }
            Returns: number
          }
      st_length2d: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_letters: {
        Args: {
          letters: string
          font?: Json
        }
        Returns: unknown
      }
      st_linecrossingdirection: {
        Args: {
          line1: unknown
          line2: unknown
        }
        Returns: number
      }
      st_linefromencodedpolyline: {
        Args: {
          txtin: string
          nprecision?: number
        }
        Returns: unknown
      }
      st_linefrommultipoint: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_linefromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_linefromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_linelocatepoint: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: number
      }
      st_linemerge: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_linestringfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_linetocurve: {
        Args: {
          geometry: unknown
        }
        Returns: unknown
      }
      st_locatealong: {
        Args: {
          geometry: unknown
          measure: number
          leftrightoffset?: number
        }
        Returns: unknown
      }
      st_locatebetween: {
        Args: {
          geometry: unknown
          frommeasure: number
          tomeasure: number
          leftrightoffset?: number
        }
        Returns: unknown
      }
      st_locatebetweenelevations: {
        Args: {
          geometry: unknown
          fromelevation: number
          toelevation: number
        }
        Returns: unknown
      }
      st_longestline: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_m: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_makebox2d: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_makeline:
        | {
            Args: {
              "": unknown[]
            }
            Returns: unknown
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: unknown
          }
      st_makepolygon: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_makevalid:
        | {
            Args: {
              "": unknown
            }
            Returns: unknown
          }
        | {
            Args: {
              geom: unknown
              params: string
            }
            Returns: unknown
          }
      st_maxdistance: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: number
      }
      st_maximuminscribedcircle: {
        Args: {
          "": unknown
        }
        Returns: Record<string, unknown>
      }
      st_memsize: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_minimumboundingcircle: {
        Args: {
          inputgeom: unknown
          segs_per_quarter?: number
        }
        Returns: unknown
      }
      st_minimumboundingradius: {
        Args: {
          "": unknown
        }
        Returns: Record<string, unknown>
      }
      st_minimumclearance: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_minimumclearanceline: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_mlinefromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_mlinefromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_mpointfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_mpointfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_mpolyfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_mpolyfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_multi: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_multilinefromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_multilinestringfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_multipointfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_multipointfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_multipolyfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_multipolygonfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_ndims: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_node: {
        Args: {
          g: unknown
        }
        Returns: unknown
      }
      st_normalize: {
        Args: {
          geom: unknown
        }
        Returns: unknown
      }
      st_npoints: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_nrings: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_numgeometries: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_numinteriorring: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_numinteriorrings: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_numpatches: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_numpoints: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_offsetcurve: {
        Args: {
          line: unknown
          distance: number
          params?: string
        }
        Returns: unknown
      }
      st_orderingequals: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      st_orientedenvelope: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_overlaps: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      st_perimeter:
        | {
            Args: {
              "": unknown
            }
            Returns: number
          }
        | {
            Args: {
              geog: unknown
              use_spheroid?: boolean
            }
            Returns: number
          }
      st_perimeter2d: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_pointfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_pointfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_pointm: {
        Args: {
          xcoordinate: number
          ycoordinate: number
          mcoordinate: number
          srid?: number
        }
        Returns: unknown
      }
      st_pointonsurface: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_points: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_pointz: {
        Args: {
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
          srid?: number
        }
        Returns: unknown
      }
      st_pointzm: {
        Args: {
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
          mcoordinate: number
          srid?: number
        }
        Returns: unknown
      }
      st_polyfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_polyfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_polygonfromtext: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_polygonfromwkb: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_polygonize: {
        Args: {
          "": unknown[]
        }
        Returns: unknown
      }
      st_project: {
        Args: {
          geog: unknown
          distance: number
          azimuth: number
        }
        Returns: unknown
      }
      st_quantizecoordinates: {
        Args: {
          g: unknown
          prec_x: number
          prec_y?: number
          prec_z?: number
          prec_m?: number
        }
        Returns: unknown
      }
      st_reduceprecision: {
        Args: {
          geom: unknown
          gridsize: number
        }
        Returns: unknown
      }
      st_relate: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: string
      }
      st_removerepeatedpoints: {
        Args: {
          geom: unknown
          tolerance?: number
        }
        Returns: unknown
      }
      st_reverse: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_segmentize: {
        Args: {
          geog: unknown
          max_segment_length: number
        }
        Returns: unknown
      }
      st_setsrid:
        | {
            Args: {
              geog: unknown
              srid: number
            }
            Returns: unknown
          }
        | {
            Args: {
              geom: unknown
              srid: number
            }
            Returns: unknown
          }
      st_sharedpaths: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_shiftlongitude: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_shortestline: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_simplifypolygonhull: {
        Args: {
          geom: unknown
          vertex_fraction: number
          is_outer?: boolean
        }
        Returns: unknown
      }
      st_split: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_square: {
        Args: {
          size: number
          cell_i: number
          cell_j: number
          origin?: unknown
        }
        Returns: unknown
      }
      st_squaregrid: {
        Args: {
          size: number
          bounds: unknown
        }
        Returns: Record<string, unknown>[]
      }
      st_srid:
        | {
            Args: {
              geog: unknown
            }
            Returns: number
          }
        | {
            Args: {
              geom: unknown
            }
            Returns: number
          }
      st_startpoint: {
        Args: {
          "": unknown
        }
        Returns: unknown
      }
      st_subdivide: {
        Args: {
          geom: unknown
          maxvertices?: number
          gridsize?: number
        }
        Returns: unknown[]
      }
      st_summary:
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
        | {
            Args: {
              "": unknown
            }
            Returns: string
          }
      st_swapordinates: {
        Args: {
          geom: unknown
          ords: unknown
        }
        Returns: unknown
      }
      st_symdifference: {
        Args: {
          geom1: unknown
          geom2: unknown
          gridsize?: number
        }
        Returns: unknown
      }
      st_symmetricdifference: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: unknown
      }
      st_tileenvelope: {
        Args: {
          zoom: number
          x: number
          y: number
          bounds?: unknown
          margin?: number
        }
        Returns: unknown
      }
      st_touches: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      st_transform:
        | {
            Args: {
              geom: unknown
              from_proj: string
              to_proj: string
            }
            Returns: unknown
          }
        | {
            Args: {
              geom: unknown
              from_proj: string
              to_srid: number
            }
            Returns: unknown
          }
        | {
            Args: {
              geom: unknown
              to_proj: string
            }
            Returns: unknown
          }
      st_triangulatepolygon: {
        Args: {
          g1: unknown
        }
        Returns: unknown
      }
      st_union:
        | {
            Args: {
              "": unknown[]
            }
            Returns: unknown
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
            }
            Returns: unknown
          }
        | {
            Args: {
              geom1: unknown
              geom2: unknown
              gridsize: number
            }
            Returns: unknown
          }
      st_voronoilines: {
        Args: {
          g1: unknown
          tolerance?: number
          extend_to?: unknown
        }
        Returns: unknown
      }
      st_voronoipolygons: {
        Args: {
          g1: unknown
          tolerance?: number
          extend_to?: unknown
        }
        Returns: unknown
      }
      st_within: {
        Args: {
          geom1: unknown
          geom2: unknown
        }
        Returns: boolean
      }
      st_wkbtosql: {
        Args: {
          wkb: string
        }
        Returns: unknown
      }
      st_wkttosql: {
        Args: {
          "": string
        }
        Returns: unknown
      }
      st_wrapx: {
        Args: {
          geom: unknown
          wrap: number
          move: number
        }
        Returns: unknown
      }
      st_x: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_xmax: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_xmin: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_y: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_ymax: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_ymin: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_z: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_zmax: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_zmflag: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      st_zmin: {
        Args: {
          "": unknown
        }
        Returns: number
      }
      suggest_package_session_dates: {
        Args: {
          p_package_purchase_id: string
          p_sessions_count?: number
          p_start_date?: string
          p_template_id?: string
        }
        Returns: Json
      }
      test_srtd_function: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      text: {
        Args: {
          "": unknown
        }
        Returns: string
      }
      toggle_comment_reaction: {
        Args: {
          in_comment_id: number
          in_reaction_type: string
        }
        Returns: undefined
      }
      toggle_message_reaction: {
        Args: {
          p_message_id: string
          p_reaction_type: Database["public"]["Enums"]["reaction_type_enum"]
          p_emoji_code?: string
        }
        Returns: boolean
      }
      unlockrows: {
        Args: {
          "": string
        }
        Returns: number
      }
      update_appointment_chat_message: {
        Args: {
          p_appointment_id: string
          p_new_status: string
          p_payment_url?: string
          p_meeting_url?: string
        }
        Returns: string
      }
      update_appointment_with_meeting_link: {
        Args: {
          p_appointment_id: string
          p_meeting_url: string
        }
        Returns: Json
      }
      update_article_content_with_details: {
        Args: {
          p_post_id: string
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
        }
        Returns: Database["public"]["CompositeTypes"]["article_content_creation_result"]
      }
      update_capacity_counters: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      update_ceremony_content_with_details: {
        Args: {
          p_post_id: string
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_playlist_ids: string[]
          p_ceremony_type: string
          p_ceremony_theme: string
          p_ceremony_focus: string
          p_what_to_bring: string
          p_space_holder_names: string
        }
        Returns: Database["public"]["CompositeTypes"]["ceremony_content_creation_result"]
      }
      update_dance_content_with_details: {
        Args: {
          p_post_id: string
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_emotional_focuses: string[]
          p_playlist_ids: string[]
          p_instructor_name: string
          p_session_theme: string
          p_energy_level: number
          p_spiritual_elements: string
          p_emotional_focus: string
          p_recommended_environment: string
          p_body_focus: string
          p_props: string[]
          p_freeform_movement: boolean
        }
        Returns: Database["public"]["CompositeTypes"]["dance_content_creation_result"]
      }
      update_event_purchase_status: {
        Args: {
          p_purchase_id: string
          p_payment_status: string
        }
        Returns: boolean
      }
      update_event_with_details: {
        Args: {
          p_event_id: string
          p_post_id: string
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_tags: string[]
          p_event_type: Database["public"]["Enums"]["event_type_enum"]
          p_event_dates: Database["public"]["CompositeTypes"]["event_date_input"][]
          p_tickets: Database["public"]["CompositeTypes"]["ticket_input"][]
          p_room_name?: string
          p_room_password?: string
          p_location_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["event_creation_result"]
      }
      update_journal_entry: {
        Args: {
          p_journal_entry_id: number
          p_title?: string
          p_content?: string
          p_mood?: Database["public"]["Enums"]["mood_enum"]
          p_privacy?: Database["public"]["Enums"]["journal_entry_privacy_enum"]
          p_tags?: string[]
        }
        Returns: Json
      }
      update_meditation_content_with_details: {
        Args: {
          p_post_id: string
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_playlist_ids: string[]
          p_meditation_type: string
          p_meditation_theme: string
          p_meditation_focus: string
        }
        Returns: Database["public"]["CompositeTypes"]["meditation_content_creation_result"]
      }
      update_message_status: {
        Args: {
          p_message_id: string
          p_status: Database["public"]["Enums"]["message_status_enum"]
        }
        Returns: boolean
      }
      update_neuroflow_content_with_details: {
        Args: {
          p_post_id: string
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_emotional_focuses: string[]
          p_playlist_ids: string[]
          p_instructor_name: string
          p_session_theme: string
          p_energy_level: number
          p_spiritual_elements: string
          p_emotional_focus: string
          p_recommended_environment: string
          p_body_focus: string
          p_props: string[]
          p_techniques_used: string
          p_session_focus: string
          p_personal_growth_outcomes: string
        }
        Returns: Database["public"]["CompositeTypes"]["neuroflow_content_creation_result"]
      }
      update_notification_preferences: {
        Args: {
          p_type: string
          p_in_app?: boolean
          p_email?: boolean
          p_push?: boolean
          p_sms?: boolean
        }
        Returns: boolean
      }
      update_notification_statistics: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      update_ondemand_content_with_details: {
        Args: {
          p_post_id: string
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_emotional_focuses: string[]
          p_playlist_ids: string[]
          p_instructor_name: string
          p_session_theme: string
          p_energy_level: number
          p_spiritual_elements: string
          p_emotional_focus: string
          p_recommended_environment: string
          p_body_focus: string
          p_props: string[]
        }
        Returns: Database["public"]["CompositeTypes"]["ondemand_content_creation_result"]
      }
      update_service_booking_settings: {
        Args: {
          p_service_id: string
          p_booking_workflow: string
          p_auto_confirm: boolean
          p_confirmation_deadline_hours?: number
        }
        Returns: Json
      }
      update_service_content_with_details: {
        Args: {
          p_post_id: string
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_location_id: string
          p_price: number
          p_duration: unknown
          p_type: Database["public"]["Enums"]["event_type_enum"]
          p_booking_workflow?: string
          p_auto_confirm?: boolean
          p_confirmation_deadline_hours?: number
          p_capacity?: number
          p_waitlist_enabled?: boolean
          p_universal_package_ids?: string[]
          p_package_credits_required?: number
          p_package_access_type?: Database["public"]["Enums"]["access_pattern_enum"]
          p_package_priority?: number
          p_replace_package_rules?: boolean
        }
        Returns: Database["public"]["CompositeTypes"]["service_content_with_packages_result"]
      }
      update_ticket: {
        Args: {
          p_event_id: string
          p_tickets: Database["public"]["CompositeTypes"]["ticket_input"][]
        }
        Returns: undefined
      }
      update_user_timezone: {
        Args: {
          new_timezone: string
        }
        Returns: undefined
      }
      update_yoga_content_with_details: {
        Args: {
          p_post_id: string
          p_title: string
          p_slug: string
          p_description: string
          p_content: string
          p_thumbnail_url: string
          p_tags: string[]
          p_status: Database["public"]["Enums"]["publish_status_enum"]
          p_media_type: Database["public"]["Enums"]["media_type_enum"]
          p_duration: unknown
          p_price: number
          p_protected_media_url: string
          p_emotional_focuses: string[]
          p_playlist_ids: string[]
          p_instructor_name: string
          p_session_theme: string
          p_energy_level: number
          p_spiritual_elements: string
          p_emotional_focus: string
          p_recommended_environment: string
          p_body_focus: string
          p_props: string[]
          p_yoga_style: string
          p_chakras: string
        }
        Returns: Database["public"]["CompositeTypes"]["yoga_content_creation_result"]
      }
      updategeometrysrid: {
        Args: {
          catalogn_name: string
          schema_name: string
          table_name: string
          column_name: string
          new_srid_in: number
        }
        Returns: string
      }
      upsert_user_location: {
        Args: {
          p_lat: number
          p_lon: number
          p_location_id?: string
          p_location_name?: string
        }
        Returns: {
          coordinates: unknown | null
          created_at: string | null
          location_id: string | null
          location_name: string | null
          updated_at: string | null
          user_id: string
        }
      }
      use_package_credits: {
        Args: {
          p_package_purchase_id: string
          p_access_type: string
          p_resource_id: string
          p_credits_used?: number
        }
        Returns: Json
      }
      user_can_view_notification: {
        Args: {
          notification_row: unknown
        }
        Returns: boolean
      }
      validate_payment_status_transition: {
        Args: {
          p_current_status: string
          p_new_status: string
        }
        Returns: boolean
      }
    }
    Enums: {
      access_pattern_enum:
        | "pay_per_use"
        | "unlimited"
        | "monthly_allowance"
        | "weekly_allowance"
      app_permission: "select" | "insert" | "update" | "delete"
      appointment_method_enum: "video" | "phone" | "in-person"
      appointment_status_enum:
        | "pending_approval"
        | "pending_payment"
        | "pending_auto_payment"
        | "confirmed"
        | "cancelled"
        | "completed"
        | "no_show"
        | "rescheduled"
        | "pending_reschedule"
      appointment_type_enum: "reading" | "healing" | "coaching" | "consultation"
      chat_type_enum:
        | "private"
        | "group"
        | "broadcast"
        | "appointment_booking"
        | "event_notification"
        | "service_updates"
        | "booking_support"
        | "transaction_channel"
      event_status_enum: "upcoming" | "past" | "all"
      event_type_enum: "online" | "in-person" | "hybrid"
      journal_entry_privacy_enum: "private" | "public" | "shared"
      media_type_enum: "video" | "audio"
      message_status_enum: "delivered" | "read" | "deleted"
      mood_enum: "great" | "good" | "neutral" | "poor" | "terrible"
      notification_audience_type: "individual" | "all" | "segment" | "followers"
      notification_type:
        | "appointment"
        | "system"
        | "general"
        | "announcement"
        | "payment"
        | "booking"
        | "waitlist"
        | "reminder"
        | "message"
        | "broadcast"
      package_access_type_enum:
        | "appointments_only"
        | "content_credits"
        | "unlimited_content"
        | "hybrid_credits"
        | "full_access"
        | "custom_bundle"
      post_type_enum:
        | "event"
        | "service"
        | "neuro_flow"
        | "yoga"
        | "dance"
        | "meditation"
        | "breath_work"
        | "primal"
        | "ritual"
        | "ceremony"
        | "article"
        | "video"
        | "on_demand"
      publish_status_enum: "draft" | "public" | "private" | "archived"
      purchase_option_enum: "one_time" | "recurring"
      purchase_payment_status_enum:
        | "completed"
        | "pending"
        | "refunded"
        | "failed"
        | "canceled"
      purchase_type_enum:
        | "content"
        | "event"
        | "appointment"
        | "subscription"
        | "article"
        | "package"
      reaction_type_enum:
        | "like"
        | "love"
        | "haha"
        | "wow"
        | "sad"
        | "angry"
        | "custom"
      timezone:
        | "UTC+00:00"
        | "UTC-12:00"
        | "UTC-11:00"
        | "UTC-10:00"
        | "UTC-09:30"
        | "UTC-09:00"
        | "UTC-08:00"
        | "UTC-07:00"
        | "UTC-06:00"
        | "UTC-05:00"
        | "UTC-04:00"
        | "UTC-03:30"
        | "UTC-03:00"
        | "UTC-02:00"
        | "UTC-01:00"
        | "UTC+01:00"
        | "UTC+02:00"
        | "UTC+03:00"
        | "UTC+03:30"
        | "UTC+04:00"
        | "UTC+04:30"
        | "UTC+05:00"
        | "UTC+05:30"
        | "UTC+05:45"
        | "UTC+06:00"
        | "UTC+06:30"
        | "UTC+07:00"
        | "UTC+08:00"
        | "UTC+08:45"
        | "UTC+09:00"
        | "UTC+09:30"
        | "UTC+10:00"
        | "UTC+10:30"
        | "UTC+11:00"
        | "UTC+12:00"
        | "UTC+12:45"
        | "UTC+13:00"
        | "UTC+14:00"
      user_role: "admin" | "moderator" | "creator" | "user"
    }
    CompositeTypes: {
      article_content_creation_result: {
        post_id: string | null
        article_id: string | null
        slug: string | null
      }
      ceremony_content_creation_result: {
        post_id: string | null
        ondemand_media_id: string | null
        protected_media_id: string | null
        ceremony_id: string | null
        slug: string | null
      }
      create_universal_package_result: {
        package_id: string | null
      }
      dance_content_creation_result: {
        post_id: string | null
        ondemand_media_id: string | null
        movement_id: string | null
        protected_media_id: string | null
        dance_id: string | null
        slug: string | null
      }
      event_creation_result: {
        event_id: string | null
        post_id: string | null
        room_id: string | null
        slug: string | null
      }
      event_date_input: {
        id: string | null
        start_date: string | null
        end_date: string | null
      }
      event_filters: {
        status: Database["public"]["Enums"]["event_status_enum"] | null
        event_types: Database["public"]["Enums"]["event_type_enum"][] | null
        creator_ids: string[] | null
        tags: string[] | null
        user_lat: number | null
        user_lon: number | null
        distance_limit: number | null
      }
      generic_ondemand_content_creation_result: {
        post_id: string | null
        ondemand_media_id: string | null
        protected_media_id: string | null
        slug: string | null
      }
      geometry_dump: {
        path: number[] | null
        geom: unknown | null
      }
      get_potential_recipients_params: {
        type: string | null
        postid: string | null
        serviceid: string | null
        eventid: string | null
        appointmentid: string | null
        bookingid: string | null
        eventdate: string | null
        limit: number | null
      }
      meditation_content_creation_result: {
        post_id: string | null
        ondemand_media_id: string | null
        protected_media_id: string | null
        meditation_id: string | null
        slug: string | null
      }
      neuroflow_content_creation_result: {
        post_id: string | null
        ondemand_media_id: string | null
        movement_id: string | null
        protected_media_id: string | null
        neuroflow_id: string | null
        slug: string | null
      }
      ondemand_content_creation_result: {
        post_id: string | null
        ondemand_media_id: string | null
        movement_id: string | null
        protected_media_id: string | null
        slug: string | null
      }
      package_credits: {
        appointments: number | null
        content: number | null
        events: number | null
        posts: number | null
      }
      package_pricing_option: {
        available: boolean | null
        price: number | null
        duration_weeks: number | null
        currency: string | null
      }
      package_pricing_options: {
        one_time:
          | Database["public"]["CompositeTypes"]["package_pricing_option"]
          | null
        recurring:
          | Database["public"]["CompositeTypes"]["package_recurring_pricing_option"]
          | null
      }
      package_pricing_options_result: {
        package_id: string | null
        pricing_options: Json | null
      }
      package_purchase_payment_result: {
        success: boolean | null
        purchase_id: string | null
        package_purchase_id: string | null
        package_id: string | null
        service_id: string | null
        sessions_remaining: number | null
        sessions_total: number | null
        expires_at: string | null
        package_name: string | null
        package_description: string | null
        user_id: string | null
        owner_id: string | null
        amount: number | null
        currency: string | null
      }
      package_recurring_pricing_option: {
        available: boolean | null
        price: number | null
        billing_interval: number | null
        currency: string | null
      }
      package_service_access: {
        access_type: string | null
        credits_required: number | null
        priority: number | null
      }
      purchase_universal_package_result: {
        success: boolean | null
        purchase_id: string | null
        package_purchase_id: string | null
        package_id: string | null
        expires_at: string | null
        appointment_credits: number | null
        content_credits: number | null
        event_credits: number | null
      }
      service_content_creation_result: {
        post_id: string | null
        service_id: string | null
        slug: string | null
      }
      service_content_with_packages_result: {
        post_id: string | null
        service_id: string | null
        slug: string | null
        package_rules_created: number | null
        package_ids: string[] | null
      }
      ticket_input: {
        id: string | null
        title: string | null
        description: string | null
        price: number | null
        quantity: number | null
        days_before_unavailable: number | null
      }
      universal_package_detail: {
        id: string | null
        name: string | null
        description: string | null
        package_type: string | null
        currency: string | null
        pricing_options:
          | Database["public"]["CompositeTypes"]["package_pricing_options"]
          | null
        credits: Database["public"]["CompositeTypes"]["package_credits"] | null
        service_access:
          | Database["public"]["CompositeTypes"]["package_service_access"]
          | null
        is_featured: boolean | null
        is_active: boolean | null
        credits_required: number | null
        access_type: string | null
        appointment_credits: number | null
      }
      user_appointment_detail: {
        id: string | null
        start_time: string | null
        end_time: string | null
        status: string | null
        booking_type: string | null
        package_purchase_id: string | null
        created_at: string | null
      }
      user_credits_summary: {
        total_appointment_credits: number | null
        total_content_credits: number | null
        total_event_credits: number | null
        active_packages: number | null
      }
      user_package_purchase_detail: {
        id: string | null
        package_id: string | null
        package_name: string | null
        purchase_option: string | null
        status: string | null
        expires_at: string | null
        is_recurring: boolean | null
        current_period_start: string | null
        current_period_end: string | null
        appointment_credits_remaining: number | null
        content_credits_remaining: number | null
        event_credits_remaining: number | null
        access_type: string | null
        credits_required: number | null
      }
      user_packages_dashboard_type: {
        active_packages: Json | null
        total_appointment_credits: number | null
        total_content_credits: number | null
        total_event_credits: number | null
        expiring_soon: Json | null
        usage_this_month: Json | null
      }
      user_upcoming_appointment: {
        id: string | null
        start_time: string | null
        end_time: string | null
        status: string | null
        package_purchase_id: string | null
      }
      valid_detail: {
        valid: boolean | null
        reason: string | null
        location: unknown | null
      }
      video_asset_type: {
        id: string | null
        user_id: string | null
        created_at: number | null
        encoding_tier: string | null
        master_access: string | null
        max_resolution_tier: string | null
        mp4_support: string | null
        status: string | null
        aspect_ratio: string | null
        duration: number | null
        errors: Json | null
        ingest_type: string | null
        is_live: boolean | null
        live_stream_id: string | null
        master: Json | null
        max_stored_frame_rate: number | null
        max_stored_resolution: string | null
        non_standard_input_reasons: Json | null
        normalize_audio: boolean | null
        passthrough: Json | null
        per_title_encode: boolean | null
        playback_ids: Json | null
        recording_times: Json | null
        resolution_tier: string | null
        source_asset_id: string | null
        static_renditions: Json | null
        test: boolean | null
        tracks: Json | null
        upload_id: string | null
      }
      yoga_content_creation_result: {
        post_id: string | null
        ondemand_media_id: string | null
        movement_id: string | null
        protected_media_id: string | null
        yoga_id: string | null
        slug: string | null
      }
    }
  }
  storage: {
    Tables: {
      buckets: {
        Row: {
          allowed_mime_types: string[] | null
          avif_autodetection: boolean | null
          created_at: string | null
          file_size_limit: number | null
          id: string
          name: string
          owner: string | null
          owner_id: string | null
          public: boolean | null
          updated_at: string | null
        }
        Insert: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id: string
          name: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          updated_at?: string | null
        }
        Update: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id?: string
          name?: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          updated_at?: string | null
        }
        Relationships: []
      }
      migrations: {
        Row: {
          executed_at: string | null
          hash: string
          id: number
          name: string
        }
        Insert: {
          executed_at?: string | null
          hash: string
          id: number
          name: string
        }
        Update: {
          executed_at?: string | null
          hash?: string
          id?: number
          name?: string
        }
        Relationships: []
      }
      objects: {
        Row: {
          bucket_id: string | null
          created_at: string | null
          id: string
          last_accessed_at: string | null
          metadata: Json | null
          name: string | null
          owner: string | null
          owner_id: string | null
          path_tokens: string[] | null
          updated_at: string | null
          user_metadata: Json | null
          version: string | null
        }
        Insert: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          user_metadata?: Json | null
          version?: string | null
        }
        Update: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          user_metadata?: Json | null
          version?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "objects_bucketId_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
        ]
      }
      s3_multipart_uploads: {
        Row: {
          bucket_id: string
          created_at: string
          id: string
          in_progress_size: number
          key: string
          owner_id: string | null
          upload_signature: string
          user_metadata: Json | null
          version: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          id: string
          in_progress_size?: number
          key: string
          owner_id?: string | null
          upload_signature: string
          user_metadata?: Json | null
          version: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          id?: string
          in_progress_size?: number
          key?: string
          owner_id?: string | null
          upload_signature?: string
          user_metadata?: Json | null
          version?: string
        }
        Relationships: [
          {
            foreignKeyName: "s3_multipart_uploads_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
        ]
      }
      s3_multipart_uploads_parts: {
        Row: {
          bucket_id: string
          created_at: string
          etag: string
          id: string
          key: string
          owner_id: string | null
          part_number: number
          size: number
          upload_id: string
          version: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          etag: string
          id?: string
          key: string
          owner_id?: string | null
          part_number: number
          size?: number
          upload_id: string
          version: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          etag?: string
          id?: string
          key?: string
          owner_id?: string | null
          part_number?: number
          size?: number
          upload_id?: string
          version?: string
        }
        Relationships: [
          {
            foreignKeyName: "s3_multipart_uploads_parts_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "s3_multipart_uploads_parts_upload_id_fkey"
            columns: ["upload_id"]
            isOneToOne: false
            referencedRelation: "s3_multipart_uploads"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      can_insert_object: {
        Args: {
          bucketid: string
          name: string
          owner: string
          metadata: Json
        }
        Returns: undefined
      }
      extension: {
        Args: {
          name: string
        }
        Returns: string
      }
      filename: {
        Args: {
          name: string
        }
        Returns: string
      }
      foldername: {
        Args: {
          name: string
        }
        Returns: string[]
      }
      get_size_by_bucket: {
        Args: Record<PropertyKey, never>
        Returns: {
          size: number
          bucket_id: string
        }[]
      }
      list_multipart_uploads_with_delimiter: {
        Args: {
          bucket_id: string
          prefix_param: string
          delimiter_param: string
          max_keys?: number
          next_key_token?: string
          next_upload_token?: string
        }
        Returns: {
          key: string
          id: string
          created_at: string
        }[]
      }
      list_objects_with_delimiter: {
        Args: {
          bucket_id: string
          prefix_param: string
          delimiter_param: string
          max_keys?: number
          start_after?: string
          next_token?: string
        }
        Returns: {
          name: string
          id: string
          metadata: Json
          updated_at: string
        }[]
      }
      operation: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      search: {
        Args: {
          prefix: string
          bucketname: string
          limits?: number
          levels?: number
          offsets?: number
          search?: string
          sortcolumn?: string
          sortorder?: string
        }
        Returns: {
          name: string
          id: string
          updated_at: string
          created_at: string
          last_accessed_at: string
          metadata: Json
        }[]
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type PublicSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (PublicSchema["Tables"] & PublicSchema["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (PublicSchema["Tables"] &
        PublicSchema["Views"])
    ? (PublicSchema["Tables"] &
        PublicSchema["Views"])[PublicTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof PublicSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof PublicSchema["Enums"]
    ? PublicSchema["Enums"][PublicEnumNameOrOptions]
    : never

