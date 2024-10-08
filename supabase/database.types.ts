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
      appointments: {
        Row: {
          client_id: string | null
          created_at: string | null
          end_time: string
          facilitator_id: string | null
          id: string
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
        ]
      }
      article_purchases: {
        Row: {
          article_id: string
          created_at: string | null
          expiry_date: string | null
          id: string
          purchase_date: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          article_id: string
          created_at?: string | null
          expiry_date?: string | null
          id?: string
          purchase_date?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          article_id?: string
          created_at?: string | null
          expiry_date?: string | null
          id?: string
          purchase_date?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "article_purchases_article_id_fkey"
            columns: ["article_id"]
            isOneToOne: false
            referencedRelation: "articles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "article_purchases_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
      comments: {
        Row: {
          comment: string
          created_at: string
          deleted_at: string | null
          id: number
          parent_id: number | null
          post_id: string
          score: number | null
          updated_at: string
          user_id: string
        }
        Insert: {
          comment: string
          created_at?: string
          deleted_at?: string | null
          id?: number
          parent_id?: number | null
          post_id: string
          score?: number | null
          updated_at?: string
          user_id: string
        }
        Update: {
          comment?: string
          created_at?: string
          deleted_at?: string | null
          id?: number
          parent_id?: number | null
          post_id?: string
          score?: number | null
          updated_at?: string
          user_id?: string
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
      event_bookings: {
        Row: {
          booking_id: string | null
          date_id: string | null
          id: string
          room_id: string | null
          ticket_id: string | null
        }
        Insert: {
          booking_id?: string | null
          date_id?: string | null
          id?: string
          room_id?: string | null
          ticket_id?: string | null
        }
        Update: {
          booking_id?: string | null
          date_id?: string | null
          id?: string
          room_id?: string | null
          ticket_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "event_bookings_booking_id_fkey"
            columns: ["booking_id"]
            isOneToOne: false
            referencedRelation: "bookings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_bookings_date_id_fkey"
            columns: ["date_id"]
            isOneToOne: false
            referencedRelation: "event_dates"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_bookings_room_id_fkey"
            columns: ["room_id"]
            isOneToOne: false
            referencedRelation: "live_rooms"
            referencedColumns: ["id"]
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
          end_date: string
          event_id: string
          id: string
          start_date: string
        }
        Insert: {
          end_date: string
          event_id: string
          id?: string
          start_date: string
        }
        Update: {
          end_date?: string
          event_id?: string
          id?: string
          start_date?: string
        }
        Relationships: [
          {
            foreignKeyName: "event_dates_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
      media_access_control: {
        Row: {
          content_id: string
          end_date: string | null
          id: string
          post_id: string | null
          purchase_date: string | null
          purchase_id: string | null
          user_id: string
        }
        Insert: {
          content_id: string
          end_date?: string | null
          id?: string
          post_id?: string | null
          purchase_date?: string | null
          purchase_id?: string | null
          user_id: string
        }
        Update: {
          content_id?: string
          end_date?: string | null
          id?: string
          post_id?: string | null
          purchase_date?: string | null
          purchase_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "media_access_control_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "media_access_control_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "media_access_control_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "media_access_control_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "media_access_control_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "media_access_control_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "media_access_control_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "on_demand_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["on_demand_media_id"]
          },
          {
            foreignKeyName: "media_access_control_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "meditation_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "movement_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "neuroflow_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "on_demand_base"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "post_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "service_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_access_control_user_id_fkey"
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
      purchases: {
        Row: {
          booking_id: string | null
          content_id: string | null
          created_at: string | null
          end_date: string | null
          id: string
          invoice_id: string
          post_id: string | null
          purchase_date: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          booking_id?: string | null
          content_id?: string | null
          created_at?: string | null
          end_date?: string | null
          id?: string
          invoice_id: string
          post_id?: string | null
          purchase_date?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          booking_id?: string | null
          content_id?: string | null
          created_at?: string | null
          end_date?: string | null
          id?: string
          invoice_id?: string
          post_id?: string | null
          purchase_date?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "purchases_booking_id_fkey"
            columns: ["booking_id"]
            isOneToOne: false
            referencedRelation: "bookings"
            referencedColumns: ["id"]
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
            referencedRelation: "dance_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "yoga_details"
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      service_purchases: {
        Row: {
          created_at: string | null
          expiry_date: string | null
          id: string
          purchase_date: string | null
          service_date_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          expiry_date?: string | null
          id?: string
          purchase_date?: string | null
          service_date_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          expiry_date?: string | null
          id?: string
          purchase_date?: string | null
          service_date_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "service_purchases_service_date_id_fkey"
            columns: ["service_date_id"]
            isOneToOne: false
            referencedRelation: "service_dates"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_purchases_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
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
          content: string | null
          created_at: string | null
          duration: unknown
          id: string
          location_id: string | null
          post_id: string
          price: number
          type: Database["public"]["Enums"]["event_type_enum"]
          updated_at: string | null
        }
        Insert: {
          content?: string | null
          created_at?: string | null
          duration: unknown
          id?: string
          location_id?: string | null
          post_id: string
          price: number
          type: Database["public"]["Enums"]["event_type_enum"]
          updated_at?: string | null
        }
        Update: {
          content?: string | null
          created_at?: string | null
          duration?: unknown
          id?: string
          location_id?: string | null
          post_id?: string
          price?: number
          type?: Database["public"]["Enums"]["event_type_enum"]
          updated_at?: string | null
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
            referencedRelation: "ceremony_details"
            referencedColumns: ["id"]
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
            referencedRelation: "service_details"
            referencedColumns: ["id"]
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
      subscriptions: {
        Row: {
          created_at: string | null
          end_date: string | null
          id: string
          purchase_id: string
          subscription_date: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          end_date?: string | null
          id?: string
          purchase_id: string
          subscription_date?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          end_date?: string | null
          id?: string
          purchase_id?: string
          subscription_date?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscriptions_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscriptions_user_id_fkey"
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
      ticket_purchases: {
        Row: {
          date_id: string
          id: string
          purchase_date: string | null
          quantity: number
          ticket_id: string
          user_id: string
        }
        Insert: {
          date_id: string
          id?: string
          purchase_date?: string | null
          quantity?: number
          ticket_id: string
          user_id: string
        }
        Update: {
          date_id?: string
          id?: string
          purchase_date?: string | null
          quantity?: number
          ticket_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ticket_purchases_date_id_fkey"
            columns: ["date_id"]
            isOneToOne: false
            referencedRelation: "event_dates"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_purchases_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "tickets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_purchases_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      ticket_purchases_event_date_user: {
        Row: {
          created_at: string | null
          date_id: string | null
          event_id: string | null
          id: string
          purchase_id: string
          ticket_id: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          date_id?: string | null
          event_id?: string | null
          id?: string
          purchase_id: string
          ticket_id?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          date_id?: string | null
          event_id?: string | null
          id?: string
          purchase_id?: string
          ticket_id?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ticket_purchases_event_date_user_date_id_fkey"
            columns: ["date_id"]
            isOneToOne: false
            referencedRelation: "event_dates"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_purchases_event_date_user_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_purchases_event_date_user_purchase_id_fkey"
            columns: ["purchase_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_purchases_event_date_user_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "tickets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_purchases_event_date_user_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
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
            referencedRelation: "events"
            referencedColumns: ["id"]
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
          created_at: string | null
          email: string
          id: string
          user_id: string | null
          waitlist_id: string
        }
        Insert: {
          created_at?: string | null
          email: string
          id?: string
          user_id?: string | null
          waitlist_id: string
        }
        Update: {
          created_at?: string | null
          email?: string
          id?: string
          user_id?: string | null
          waitlist_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "waitlist_entries_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "waitlist_entries_waitlist_id_fkey"
            columns: ["waitlist_id"]
            isOneToOne: false
            referencedRelation: "waitlists"
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
      meditation_details: {
        Row: {
          content: string | null
          created_at: string | null
          description: string | null
          duration: unknown | null
          event_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          id: string | null
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
      post_details: {
        Row: {
          content: string | null
          created_at: string | null
          description: string | null
          event_subtype: Database["public"]["Enums"]["event_type_enum"] | null
          featured: boolean | null
          id: string | null
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
      service_details: {
        Row: {
          content: string | null
          created_at: string | null
          description: string | null
          duration: unknown | null
          featured: boolean | null
          id: string | null
          location_name: string | null
          post_type: string | null
          price: number | null
          profile_avatar_url: string | null
          profile_full_name: string | null
          profile_id: string | null
          slug: string | null
          status: string | null
          tags: string[] | null
          thumbnail_url: string | null
          title: string | null
          type: Database["public"]["Enums"]["event_type_enum"] | null
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
      add_movement_props: {
        Args: {
          p_movement_id: string
          p_props: string[]
        }
        Returns: undefined
      }
      add_playlist_associations: {
        Args: {
          p_content_id: string
          p_playlist_ids: string[]
        }
        Returns: undefined
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
      associate_post_location: {
        Args: {
          p_post_id: string
          p_location_id: string
        }
        Returns: undefined
      }
      authorizedas: {
        Args: {
          allowed_roles: Database["public"]["Enums"]["user_role"][]
        }
        Returns: boolean
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
      create_event: {
        Args: {
          p_post_id: string
          p_content: string
          p_event_type: Database["public"]["Enums"]["event_type_enum"]
        }
        Returns: string
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
          user_id?: string
        }
        Returns: Database["public"]["CompositeTypes"]["service_content_creation_result"]
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
      delete_comment: {
        Args: {
          in_comment_id: number
        }
        Returns: undefined
      }
      delete_playlist: {
        Args: {
          user_id: string
          iframe: string
        }
        Returns: undefined
      }
      downvote_comment: {
        Args: {
          in_comment_id: number
        }
        Returns: undefined
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
      get_comment_replies: {
        Args: {
          in_comment_id: number
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
        }[]
      }
      get_comment_replies_tree: {
        Args: {
          in_comment_id: number
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
          depth: number
          path: number[]
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
          depth: number
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
        }[]
      }
      get_filtered_movement_content: {
        Args: {
          input_post_ids?: string[]
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
        }[]
      }
      get_on_page_ceremony: {
        Args: {
          p_slug: string
        }
        Returns: {
          like: unknown
          protected_media_url: string
        }[]
      }
      get_on_page_dance: {
        Args: {
          p_slug: string
        }
        Returns: {
          like: unknown
          protected_media_url: string
        }[]
      }
      get_on_page_meditation: {
        Args: {
          p_slug: string
        }
        Returns: {
          like: unknown
          protected_media_url: string
        }[]
      }
      get_on_page_neuro_flow: {
        Args: {
          p_slug: string
        }
        Returns: {
          like: unknown
          protected_media_url: string
        }[]
      }
      get_on_page_yoga: {
        Args: {
          p_slug: string
        }
        Returns: {
          like: unknown
          protected_media_url: string
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
      get_thread_depth: {
        Args: {
          in_comment_id: number
        }
        Returns: number
      }
      get_user_appointments: {
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
          status: string
        }[]
      }
      grant_public_read_access: {
        Args: {
          table_name: string
        }
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
          waitlist_id: string
          email: string
          user_id?: string
        }
        Returns: {
          created_at: string | null
          email: string
          id: string
          user_id: string | null
          waitlist_id: string
        }
      }
      leave_comment: {
        Args: {
          in_post_id: string
          in_comment: string
          in_parent_id?: number
        }
        Returns: number
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
      respond_to_appointment: {
        Args: {
          p_appointment_id: string
          p_action: string
          p_new_start_time?: string
          p_new_end_time?: string
        }
        Returns: undefined
      }
      sanitize_slug: {
        Args: {
          input: string
        }
        Returns: string
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
      set_user_timezone_claim: {
        Args: {
          event: Json
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
        }
        Returns: Database["public"]["CompositeTypes"]["service_content_creation_result"]
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
      upvote_comment: {
        Args: {
          in_comment_id: number
        }
        Returns: undefined
      }
    }
    Enums: {
      app_permission: "select" | "insert" | "update" | "delete"
      event_type_enum: "online" | "in-person" | "hybrid"
      media_type_enum: "video" | "audio"
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
      service_content_creation_result: {
        post_id: string | null
        service_id: string | null
        slug: string | null
      }
      ticket_input: {
        id: string | null
        title: string | null
        description: string | null
        price: number | null
        quantity: number | null
        days_before_unavailable: number | null
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

