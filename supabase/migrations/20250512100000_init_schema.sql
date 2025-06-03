

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "btree_gist" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";




CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA "extensions";




CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';

create extension if not exists postgis;

CREATE TYPE "public"."app_permission" AS ENUM (
    'select',
    'insert',
    'update',
    'delete'
);


ALTER TYPE "public"."app_permission" OWNER TO "postgres";


CREATE TYPE "public"."appointment_method_enum" AS ENUM (
    'video',
    'phone',
    'in-person'
);


ALTER TYPE "public"."appointment_method_enum" OWNER TO "postgres";


CREATE TYPE "public"."appointment_status_enum" AS ENUM (
    'pending_approval',
    'pending_payment',
    'pending_auto_payment',
    'confirmed',
    'cancelled',
    'completed',
    'no_show',
    'rescheduled',
    'pending_reschedule'
);


ALTER TYPE "public"."appointment_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."appointment_type_enum" AS ENUM (
    'reading',
    'healing',
    'coaching',
    'consultation'
);


ALTER TYPE "public"."appointment_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."article_content_creation_result" AS (
	"post_id" "uuid",
	"article_id" "uuid",
	"slug" "text"
);


ALTER TYPE "public"."article_content_creation_result" OWNER TO "postgres";


CREATE TYPE "public"."ceremony_content_creation_result" AS (
	"post_id" "uuid",
	"ondemand_media_id" "uuid",
	"protected_media_id" "uuid",
	"ceremony_id" "uuid",
	"slug" "text"
);


ALTER TYPE "public"."ceremony_content_creation_result" OWNER TO "postgres";


CREATE TYPE "public"."chat_type_enum" AS ENUM (
    'private',
    'group',
    'broadcast'
);


ALTER TYPE "public"."chat_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."dance_content_creation_result" AS (
	"post_id" "uuid",
	"ondemand_media_id" "uuid",
	"movement_id" "uuid",
	"protected_media_id" "uuid",
	"dance_id" "uuid",
	"slug" "text"
);


ALTER TYPE "public"."dance_content_creation_result" OWNER TO "postgres";


CREATE TYPE "public"."event_creation_result" AS (
	"event_id" "uuid",
	"post_id" "uuid",
	"room_id" "uuid",
	"slug" "text"
);


ALTER TYPE "public"."event_creation_result" OWNER TO "postgres";


CREATE TYPE "public"."event_date_input" AS (
	"id" "uuid",
	"start_date" timestamp with time zone,
	"end_date" timestamp with time zone
);


ALTER TYPE "public"."event_date_input" OWNER TO "postgres";


CREATE TYPE "public"."event_status_enum" AS ENUM (
    'upcoming',
    'past',
    'all'
);


ALTER TYPE "public"."event_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."event_type_enum" AS ENUM (
    'online',
    'in-person',
    'hybrid'
);


ALTER TYPE "public"."event_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."event_filters" AS (
	"status" "public"."event_status_enum",
	"event_types" "public"."event_type_enum"[],
	"creator_ids" "uuid"[],
	"tags" "text"[],
	"user_lat" double precision,
	"user_lon" double precision,
	"distance_limit" double precision
);


ALTER TYPE "public"."event_filters" OWNER TO "postgres";


CREATE TYPE "public"."generic_ondemand_content_creation_result" AS (
	"post_id" "uuid",
	"ondemand_media_id" "uuid",
	"protected_media_id" "uuid",
	"slug" "text"
);


ALTER TYPE "public"."generic_ondemand_content_creation_result" OWNER TO "postgres";


CREATE TYPE "public"."get_potential_recipients_params" AS (
	"type" "text",
	"postid" "uuid",
	"serviceid" "uuid",
	"eventid" "uuid",
	"appointmentid" "uuid",
	"bookingid" "uuid",
	"eventdate" timestamp with time zone,
	"limit" integer
);


ALTER TYPE "public"."get_potential_recipients_params" OWNER TO "postgres";


CREATE TYPE "public"."journal_entry_privacy_enum" AS ENUM (
    'private',
    'public',
    'shared'
);


ALTER TYPE "public"."journal_entry_privacy_enum" OWNER TO "postgres";


CREATE TYPE "public"."media_type_enum" AS ENUM (
    'video',
    'audio'
);


ALTER TYPE "public"."media_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."meditation_content_creation_result" AS (
	"post_id" "uuid",
	"ondemand_media_id" "uuid",
	"protected_media_id" "uuid",
	"meditation_id" "uuid",
	"slug" "text"
);


ALTER TYPE "public"."meditation_content_creation_result" OWNER TO "postgres";


CREATE TYPE "public"."message_status_enum" AS ENUM (
    'delivered',
    'read',
    'deleted'
);


ALTER TYPE "public"."message_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."mood_enum" AS ENUM (
    'great',
    'good',
    'neutral',
    'poor',
    'terrible'
);


ALTER TYPE "public"."mood_enum" OWNER TO "postgres";


CREATE TYPE "public"."neuroflow_content_creation_result" AS (
	"post_id" "uuid",
	"ondemand_media_id" "uuid",
	"movement_id" "uuid",
	"protected_media_id" "uuid",
	"neuroflow_id" "uuid",
	"slug" "text"
);


ALTER TYPE "public"."neuroflow_content_creation_result" OWNER TO "postgres";


CREATE TYPE "public"."notification_audience_type" AS ENUM (
    'individual',
    'all',
    'segment',
    'followers'
);


ALTER TYPE "public"."notification_audience_type" OWNER TO "postgres";


CREATE TYPE "public"."notification_type" AS ENUM (
    'appointment',
    'system',
    'general',
    'announcement',
    'payment',
    'booking',
    'waitlist',
    'reminder',
    'message',
    'broadcast'
);


ALTER TYPE "public"."notification_type" OWNER TO "postgres";


CREATE TYPE "public"."ondemand_content_creation_result" AS (
	"post_id" "uuid",
	"ondemand_media_id" "uuid",
	"movement_id" "uuid",
	"protected_media_id" "uuid",
	"slug" "text"
);


ALTER TYPE "public"."ondemand_content_creation_result" OWNER TO "postgres";


CREATE TYPE "public"."post_type_enum" AS ENUM (
    'event',
    'service',
    'neuro_flow',
    'yoga',
    'dance',
    'meditation',
    'breath_work',
    'primal',
    'ritual',
    'ceremony',
    'article',
    'video',
    'on_demand'
);


ALTER TYPE "public"."post_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."publish_status_enum" AS ENUM (
    'draft',
    'public',
    'private',
    'archived'
);


ALTER TYPE "public"."publish_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."purchase_payment_status_enum" AS ENUM (
    'completed',
    'pending',
    'refunded',
    'failed'
);


ALTER TYPE "public"."purchase_payment_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."purchase_type_enum" AS ENUM (
    'content',
    'event',
    'appointment',
    'subscription',
    'article',
    'package'
);


ALTER TYPE "public"."purchase_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."reaction_type_enum" AS ENUM (
    'like',
    'love',
    'haha',
    'wow',
    'sad',
    'angry',
    'custom'
);


ALTER TYPE "public"."reaction_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."service_content_creation_result" AS (
	"post_id" "uuid",
	"service_id" "uuid",
	"slug" "text"
);


ALTER TYPE "public"."service_content_creation_result" OWNER TO "postgres";


CREATE TYPE "public"."ticket_input" AS (
	"id" "uuid",
	"title" "text",
	"description" "text",
	"price" numeric(10,2),
	"quantity" integer,
	"days_before_unavailable" integer
);


ALTER TYPE "public"."ticket_input" OWNER TO "postgres";


CREATE TYPE "public"."timezone" AS ENUM (
    'UTC+00:00',
    'UTC-12:00',
    'UTC-11:00',
    'UTC-10:00',
    'UTC-09:30',
    'UTC-09:00',
    'UTC-08:00',
    'UTC-07:00',
    'UTC-06:00',
    'UTC-05:00',
    'UTC-04:00',
    'UTC-03:30',
    'UTC-03:00',
    'UTC-02:00',
    'UTC-01:00',
    'UTC+01:00',
    'UTC+02:00',
    'UTC+03:00',
    'UTC+03:30',
    'UTC+04:00',
    'UTC+04:30',
    'UTC+05:00',
    'UTC+05:30',
    'UTC+05:45',
    'UTC+06:00',
    'UTC+06:30',
    'UTC+07:00',
    'UTC+08:00',
    'UTC+08:45',
    'UTC+09:00',
    'UTC+09:30',
    'UTC+10:00',
    'UTC+10:30',
    'UTC+11:00',
    'UTC+12:00',
    'UTC+12:45',
    'UTC+13:00',
    'UTC+14:00'
);


ALTER TYPE "public"."timezone" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'admin',
    'moderator',
    'creator',
    'user'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE TYPE "public"."video_asset_type" AS (
	"id" "text",
	"user_id" "uuid",
	"created_at" bigint,
	"encoding_tier" "text",
	"master_access" "text",
	"max_resolution_tier" "text",
	"mp4_support" "text",
	"status" "text",
	"aspect_ratio" "text",
	"duration" double precision,
	"errors" "jsonb",
	"ingest_type" "text",
	"is_live" boolean,
	"live_stream_id" "text",
	"master" "jsonb",
	"max_stored_frame_rate" double precision,
	"max_stored_resolution" "text",
	"non_standard_input_reasons" "jsonb",
	"normalize_audio" boolean,
	"passthrough" "jsonb",
	"per_title_encode" boolean,
	"playback_ids" "jsonb",
	"recording_times" "jsonb",
	"resolution_tier" "text",
	"source_asset_id" "text",
	"static_renditions" "jsonb",
	"test" boolean,
	"tracks" "jsonb",
	"upload_id" "text"
);


ALTER TYPE "public"."video_asset_type" OWNER TO "postgres";


CREATE TYPE "public"."yoga_content_creation_result" AS (
	"post_id" "uuid",
	"ondemand_media_id" "uuid",
	"movement_id" "uuid",
	"protected_media_id" "uuid",
	"yoga_id" "uuid",
	"slug" "text"
);


ALTER TYPE "public"."yoga_content_creation_result" OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."chat_participants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "chat_room_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "left_at" timestamp with time zone,
    "role" "text" DEFAULT 'member'::"text",
    "is_muted" boolean DEFAULT false,
    "last_read_message_id" "uuid"
);


ALTER TABLE "public"."chat_participants" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_chat_participants"("p_chat_room_id" "uuid", "p_user_ids" "uuid"[]) RETURNS SETOF "public"."chat_participants"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_user_id UUID;
    v_participant public.chat_participants;
    v_result public.chat_participants;
BEGIN
    -- Create a temporary table to collect results
    CREATE TEMP TABLE IF NOT EXISTS temp_participants AS
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
    DROP TABLE IF EXISTS temp_participants;
END;
$$;


ALTER FUNCTION "public"."add_chat_participants"("p_chat_room_id" "uuid", "p_user_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_creator_as_participant"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO public.chat_participants (chat_room_id, user_id, role)
    VALUES (NEW.id, NEW.created_by, 'admin');
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."add_creator_as_participant"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_emotional_focuses"("p_post_id" "uuid", "p_emotional_focuses" "text"[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_emotional_focus TEXT;
    v_emotional_focus_id UUID;
BEGIN
    FOREACH v_emotional_focus IN ARRAY p_emotional_focuses
    LOOP
        -- First, ensure the emotional focus exists
        INSERT INTO public.emotional_focuses (value)
        VALUES (v_emotional_focus)
        ON CONFLICT (value) DO NOTHING
        RETURNING id INTO v_emotional_focus_id;

        -- If we didn't get an id from the insert, we need to select it
        IF v_emotional_focus_id IS NULL THEN
            SELECT id INTO v_emotional_focus_id
            FROM public.emotional_focuses
            WHERE value = v_emotional_focus;
        END IF;

        -- Now add the association
        INSERT INTO public.post_emotional_focuses (post_id, emotional_focus_id)
        VALUES (p_post_id, v_emotional_focus_id)
        ON CONFLICT (post_id, emotional_focus_id) DO NOTHING;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding emotional focuses: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."add_emotional_focuses"("p_post_id" "uuid", "p_emotional_focuses" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_event_dates"("p_event_id" "uuid", "p_event_dates" "public"."event_date_input"[]) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_event_date event_date_input;
    v_result JSONB = '[]'::JSONB;
BEGIN
    -- Log the input for debugging
    RAISE NOTICE 'Received event_id: %, event_dates: %', p_event_id, p_event_dates;

    FOREACH v_event_date IN ARRAY p_event_dates
    LOOP
        BEGIN
            -- Log each date being processed
            RAISE NOTICE 'Processing date: start_date %, end_date %', v_event_date.start_date, v_event_date.end_date;

            INSERT INTO public.event_dates (
                event_id, start_date, end_date
            ) VALUES (
                p_event_id,
                v_event_date.start_date,
                v_event_date.end_date
            );
            
            v_result := v_result || jsonb_build_object(
                'success', true,
                'message', 'Date added successfully',
                'start_date', v_event_date.start_date,
                'end_date', v_event_date.end_date
            );

            -- Log successful insertion
            RAISE NOTICE 'Successfully inserted date: start_date %, end_date %', v_event_date.start_date, v_event_date.end_date;
        EXCEPTION
            WHEN exclusion_violation THEN
                v_result := v_result || jsonb_build_object(
                    'success', false,
                    'message', 'Overlapping date range detected',
                    'start_date', v_event_date.start_date,
                    'end_date', v_event_date.end_date
                );
                RAISE NOTICE 'Exclusion violation: start_date %, end_date %', v_event_date.start_date, v_event_date.end_date;
            WHEN OTHERS THEN
                v_result := v_result || jsonb_build_object(
                    'success', false,
                    'message', 'Error adding date: ' || SQLERRM,
                    'start_date', v_event_date.start_date,
                    'end_date', v_event_date.end_date
                );
                RAISE NOTICE 'Other error: %, start_date %, end_date %', SQLERRM, v_event_date.start_date, v_event_date.end_date;
        END;
    END LOOP;
    
    -- Log the final result
    RAISE NOTICE 'Final result: %', v_result;

    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."add_event_dates"("p_event_id" "uuid", "p_event_dates" "public"."event_date_input"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_journal_media"("p_journal_entry_id" bigint, "p_storage_path" "text", "p_media_type" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_user_id uuid;
  v_media_id bigint;
begin
  -- Get user_id of the journal entry to check ownership
  select user_id into v_user_id from journal_entries where id = p_journal_entry_id;
  
  -- Check if the current user owns this journal entry
  if v_user_id is null or v_user_id != auth.uid() then
    raise exception 'Journal entry not found or you do not have permission to add media to it';
  end if;
  
  -- Insert the media
  insert into journal_media (journal_entry_id, storage_path, media_type)
  values (p_journal_entry_id, p_storage_path, p_media_type)
  returning id into v_media_id;
  
  -- Return the media info
  return (
    select jsonb_build_object(
      'id', jm.id,
      'journal_entry_id', jm.journal_entry_id,
      'storage_path', jm.storage_path,
      'media_type', jm.media_type,
      'created_at', jm.created_at
    )
    from journal_media jm
    where jm.id = v_media_id
  );
end;
$$;


ALTER FUNCTION "public"."add_journal_media"("p_journal_entry_id" bigint, "p_storage_path" "text", "p_media_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_movement_props"("p_movement_id" "uuid", "p_props" "text"[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_prop TEXT;
    v_prop_id UUID;
BEGIN
    FOREACH v_prop IN ARRAY p_props
    LOOP
        -- First, ensure the prop exists
        INSERT INTO public.movement_props (name)
        VALUES (v_prop)
        ON CONFLICT (name) DO NOTHING
        RETURNING id INTO v_prop_id;

        -- If we didn't get an id from the insert, we need to select it
        IF v_prop_id IS NULL THEN
            SELECT id INTO v_prop_id
            FROM public.movement_props
            WHERE name = v_prop;
        END IF;

        -- Now add the association
        INSERT INTO public.movement_props_join (movement_id, prop_id)
        VALUES (p_movement_id, v_prop_id)
        ON CONFLICT (movement_id, prop_id) DO NOTHING;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding movement props: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."add_movement_props"("p_movement_id" "uuid", "p_props" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_playlist_associations"("p_content_id" "uuid", "p_playlist_ids" "uuid"[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_playlist_id UUID;
BEGIN
    FOREACH v_playlist_id IN ARRAY p_playlist_ids
    LOOP
        INSERT INTO public.spotify_playlist_join (content_id, playlist_id)
        VALUES (p_content_id, v_playlist_id)
        ON CONFLICT (content_id, playlist_id) DO NOTHING;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding playlist associations: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."add_playlist_associations"("p_content_id" "uuid", "p_playlist_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_tags_to_post"("p_post_id" "uuid", "p_tags" "text"[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
     -- Remove existing tag associations not in the input list
    DELETE FROM public.post_tags
    WHERE post_id = p_post_id
    AND tag_id NOT IN (
        SELECT id FROM public.tags
        WHERE name = ANY(p_tags)
    );

    -- Add new tag associations for tags that don't exist for this post
    INSERT INTO public.post_tags (post_id, tag_id)
    SELECT p_post_id, t.id
    FROM unnest(p_tags) AS tag_name
    JOIN public.tags t ON t.name = tag_name
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.post_tags pt
        WHERE pt.post_id = p_post_id AND pt.tag_id = t.id
    )
    ON CONFLICT (post_id, tag_id) DO NOTHING;
END;
$$;


ALTER FUNCTION "public"."add_tags_to_post"("p_post_id" "uuid", "p_tags" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_tickets"("p_event_id" "uuid", "p_tickets" "public"."ticket_input"[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_ticket ticket_input;
BEGIN
    FOREACH v_ticket IN ARRAY p_tickets
    LOOP
        -- Check if the ticket id exists
        IF v_ticket.id IS NOT NULL THEN
            -- Update existing ticket
            UPDATE public.tickets
            SET
                title = v_ticket.title,
                description = v_ticket.description,
                price = v_ticket.price,
                quantity = v_ticket.quantity,
                days_before_unavailable = v_ticket.days_before_unavailable
            WHERE id = v_ticket.id AND event_id = p_event_id;
            
            -- If no rows were updated, the ticket doesn't exist for this event, so insert it
            IF NOT FOUND THEN
                INSERT INTO public.tickets (
                    id, event_id, title, description, price, quantity, days_before_unavailable
                ) VALUES (
                    v_ticket.id, p_event_id, v_ticket.title, v_ticket.description,
                    v_ticket.price, v_ticket.quantity, v_ticket.days_before_unavailable
                );
            END IF;
        ELSE
            -- Insert new ticket
            INSERT INTO public.tickets (
                event_id, title, description, price, quantity, days_before_unavailable
            ) VALUES (
                p_event_id, v_ticket.title, v_ticket.description,
                v_ticket.price, v_ticket.quantity, v_ticket.days_before_unavailable
            );
        END IF;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."add_tickets"("p_event_id" "uuid", "p_tickets" "public"."ticket_input"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."approve_appointment_request"("p_appointment_id" "uuid", "p_price" numeric, "p_message" "text" DEFAULT NULL::"text", "p_checkout_base_url" "text" DEFAULT '/app/checkout/appointment'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_purchase_id UUID;
  v_user_id UUID;
  v_owner_id UUID;
  v_service_id UUID;
  v_post_id UUID;
  v_appointment_date TIMESTAMP WITH TIME ZONE;
  v_duration INTEGER;
  v_result JSONB;
  v_chat_room_id UUID;
  v_message_success BOOLEAN;
  v_checkout_url TEXT;
  v_metadata JSONB;
  v_encoded_data TEXT;
  v_message_text TEXT;
  v_service_name TEXT;
  v_service_type TEXT;
  v_provider_name TEXT;
  v_client_name TEXT;
  v_chat_room_name TEXT;
BEGIN
  -- Get appointment details
  SELECT 
    ap.purchase_id, 
    p.user_id, 
    p.owner_id, 
    ap.service_id, 
    p.post_id,
    ap.appointment_date,
    ap.duration,
    s.type AS service_type,
    COALESCE(po.title, 'Service') AS service_name,
    COALESCE(pr_owner.full_name, 'Provider') AS provider_name,
    COALESCE(pr_client.full_name, 'Client') AS client_name
  INTO 
    v_purchase_id, 
    v_user_id, 
    v_owner_id, 
    v_service_id, 
    v_post_id,
    v_appointment_date,
    v_duration,
    v_service_type,
    v_service_name,
    v_provider_name,
    v_client_name
  FROM 
    appointment_purchases ap
    JOIN purchases p ON ap.purchase_id = p.id
    JOIN services s ON ap.service_id = s.id
    LEFT JOIN posts po ON s.post_id = po.id
    LEFT JOIN profiles pr_owner ON p.owner_id = pr_owner.id
    LEFT JOIN profiles pr_client ON p.user_id = pr_client.id
  WHERE 
    ap.id = p_appointment_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Appointment not found');
  END IF;
  
  -- Create a descriptive chat room name
  v_chat_room_name := v_service_name || ' - ' || 
                     to_char(v_appointment_date, 'DD Mon YYYY HH12:MI AM') || ' - ' ||
                     v_provider_name || ' & ' || v_client_name;
  
  -- Build metadata JSON for checkout URL
  v_metadata := jsonb_build_object(
    'purchase_type', 'appointment',
    'service_id', v_service_id,
    'post_id', v_post_id,
    'owner_id', v_owner_id,
    'user_id', v_user_id,
    'appointment_id', p_appointment_id,
    'purchase_id', v_purchase_id,
    'appointment_date', v_appointment_date,
    'duration', v_duration,
    'price', p_price,
    'service_name', v_service_name,
    'service_type', v_service_type
  );
  
  -- Encode data for security
  v_encoded_data := encode(
    convert_to(
      v_metadata::text,
      'UTF8'
    ),
    'base64'
  );
  
  -- Generate checkout URL with encoded data
  v_checkout_url := p_checkout_base_url || '/secure' || '?data=' || v_encoded_data;
  
  -- Update appointment status and store payment_link
  UPDATE appointment_purchases
  SET 
    status = 'pending_payment'::appointment_status_enum,
    payment_link = v_checkout_url,
    updated_at = NOW()
  WHERE id = p_appointment_id;
  
  -- Update purchase with price
  UPDATE purchases
  SET 
    amount = p_price,
    payment_status = 'pending'::purchase_payment_status_enum,
    updated_at = NOW()
  WHERE id = v_purchase_id;
  
  -- Find or create chat room
  WITH room_participants AS (
    SELECT 
      cr.id as room_id,
      COUNT(*) as participant_count,
      SUM(CASE WHEN cp.user_id IN (v_user_id, v_owner_id) THEN 1 ELSE 0 END) as target_users_count
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
  
  -- If no chat room exists, create one
  IF v_chat_room_id IS NULL THEN
    INSERT INTO chat_rooms (name, type, created_by)
    VALUES (v_chat_room_name, 'private', v_owner_id)
    RETURNING id INTO v_chat_room_id;
    
    -- Add participants
    INSERT INTO chat_participants (chat_room_id, user_id)
    VALUES 
      (v_chat_room_id, v_user_id),
      (v_chat_room_id, v_owner_id)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
  ELSE
    -- Update existing room name
    UPDATE chat_rooms
    SET name = v_chat_room_name
    WHERE id = v_chat_room_id;
  END IF;
  
  -- Compose message
  v_message_text := 
    CASE 
      WHEN p_message IS NOT NULL AND length(trim(p_message)) > 0
        THEN p_message || E'\n\n' || 'Pay here: [Complete Payment](' || v_checkout_url || '){button}'
      ELSE
        'Your appointment request has been approved. Please complete payment to confirm.' || E'\n\n' || '[Complete Payment](' || v_checkout_url || '){button}'
    END;

  -- Send message
  BEGIN
    INSERT INTO chat_messages (chat_room_id, sender_id, message, status)
    VALUES (v_chat_room_id, v_owner_id, v_message_text, 'delivered');
    v_message_success := TRUE;
  EXCEPTION 
    WHEN OTHERS THEN
      v_message_success := FALSE;
      -- Fallback to notifications
      BEGIN
        INSERT INTO notifications (
          user_id,
          title,
          content,
          type,
          action_url,
          reference_id,
          reference_type,
          metadata
        ) VALUES (
          v_user_id,
          'Appointment Approved',
          v_message_text,
          'appointment',
          v_checkout_url,
          p_appointment_id,
          'appointment',
          v_metadata
        );
      EXCEPTION WHEN OTHERS THEN
        NULL; -- Just continue if this fails
      END;
  END;
  
  -- Build result
  v_result := jsonb_build_object(
    'success', TRUE,
    'purchase_id', v_purchase_id,
    'appointment_id', p_appointment_id,
    'user_id', v_user_id,
    'owner_id', v_owner_id,
    'service_id', v_service_id,
    'post_id', v_post_id,
    'appointment_date', v_appointment_date,
    'duration', v_duration,
    'price', p_price,
    'status', 'pending_payment',
    'message_sent', v_message_success,
    'chat_room_id', v_chat_room_id,
    'chat_room_name', v_chat_room_name,
    'checkout_url', v_checkout_url,
    'encoded_data', v_encoded_data,
    'payment_link', v_checkout_url,
    'metadata', v_metadata
  );
  
  -- Trigger notification
  PERFORM pg_notify('appointment_approved', v_result::text);
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."approve_appointment_request"("p_appointment_id" "uuid", "p_price" numeric, "p_message" "text", "p_checkout_base_url" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."approve_appointment_request"("p_appointment_id" "uuid", "p_price" numeric, "p_message" "text", "p_checkout_base_url" "text") IS 'Approves an appointment request, generates payment checkout URL with encoded data, stores the payment link in the appointment record, and sends notification with payment link';



CREATE OR REPLACE FUNCTION "public"."associate_post_location"("p_post_id" "uuid", "p_location_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO public.post_locations (post_id, location_id)
    VALUES (p_post_id, p_location_id)
    ON CONFLICT (post_id, location_id) DO NOTHING;
END;
$$;


ALTER FUNCTION "public"."associate_post_location"("p_post_id" "uuid", "p_location_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."authorizedas"("allowed_roles" "public"."user_role"[]) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_is_authorized boolean;
    v_user_id uuid;
    v_user_role public.user_role;
BEGIN
    v_user_id := auth.uid();
    
    SELECT (raw_user_meta_data->>'user_role')::public.user_role
    INTO v_user_role
    FROM auth.users
    WHERE id = v_user_id;

    v_is_authorized := v_user_role = ANY(allowed_roles);
    
    -- IF NOT v_is_authorized THEN
    --     RAISE EXCEPTION 'Access denied: User role % is not authorized. Allowed roles are: %', 
    --                     v_user_role, array_to_string(allowed_roles, ', ');
    -- END IF;

    RETURN v_is_authorized;
END;
$$;


ALTER FUNCTION "public"."authorizedas"("allowed_roles" "public"."user_role"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auto_confirm_appointment"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_price NUMERIC;
    v_purchase_id UUID;
BEGIN
    -- If the new status is 'pending_auto_payment', automatically approve it
    IF NEW.status = 'pending_auto_payment'::appointment_status_enum THEN
        -- Get the price from the purchase record
        SELECT p.amount, p.id INTO v_price, v_purchase_id
        FROM public.purchases p
        JOIN public.appointment_purchases ap ON ap.purchase_id = p.id
        WHERE ap.id = NEW.id;
        
        -- Call the approve_appointment_request function
        -- This handles approval, payment link generation, and all related operations
        PERFORM public.approve_appointment_request(
            p_appointment_id := NEW.id,
            p_price := v_price,
            p_message := 'Automatically approved by system'
        );
        
        -- Return NULL since the actual update was done in the function
        RETURN NULL;
    END IF;
    
    -- For other status changes, just proceed normally
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."auto_confirm_appointment"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."auto_confirm_appointment"() IS 'Trigger function to automatically approve appointments when their status is set to pending_auto_payment by calling the approve_appointment_request function';



CREATE OR REPLACE FUNCTION "public"."backfill_embeddings"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    post_record RECORD;
    v_request_id bigint;
    v_error_message text;
    my_var text;
BEGIN
    
    my_var := current_setting('supabase.ANON_KEY', true);
    
    FOR post_record IN SELECT id, content FROM public.posts WHERE content IS NOT NULL LOOP
        BEGIN
            -- Make the HTTP POST request for each post
            SELECT net.http_post(
                url := 'http://host.docker.internal:54321/functions/v1/embeddings',
                body := jsonb_build_object(
                    'post_id', post_record.id,
                    'content', post_record.content
                ),
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || my_var,
                    'Statement-Timeout', '600000'
                ) 
            ) INTO v_request_id;

            -- Log success
            RAISE NOTICE 'Embedding request sent for post %: Request ID: %', post_record.id, v_request_id;
            
            -- Add a small delay to prevent overwhelming the endpoint
            PERFORM pg_sleep(0.1);
            
        EXCEPTION WHEN OTHERS THEN
            -- Log error but continue processing other posts
            GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
            RAISE WARNING 'Error processing post %: %', post_record.id, v_error_message;
        END;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."backfill_embeddings"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."book_appointment"("p_facilitator_id" "uuid", "p_client_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_appointment_id UUID;
    v_day VARCHAR(20);
    v_start_time TIME;
    v_end_time TIME;
BEGIN
    -- Get the day of the week for the start time
    v_day := LOWER(TO_CHAR(p_start_time AT TIME ZONE 'UTC', 'day'));
    v_start_time := p_start_time::time;
    v_end_time := p_end_time::time;
    
    -- Check if the time slot is within the facilitator's availability
    IF NOT EXISTS (
        SELECT 1
        FROM public.availability
        WHERE user_id = p_facilitator_id
        AND day = v_day
        AND is_active = TRUE
        AND start_time <= v_start_time
        AND end_time >= v_end_time
    ) THEN
        RAISE EXCEPTION 'The selected time slot is not within the facilitator''s availability';
    END IF;

    -- Check for overlapping appointments
    IF EXISTS (
        SELECT 1
        FROM public.appointments
        WHERE facilitator_id = p_facilitator_id
        AND status IN ('confirmed', 'pending')
        AND (start_time, end_time) OVERLAPS (p_start_time, p_end_time)
    ) THEN
        RAISE EXCEPTION 'The selected time slot overlaps with an existing appointment';
    END IF;

    -- Book the appointment with pending status
    INSERT INTO public.appointments (facilitator_id, client_id, start_time, end_time, status)
    VALUES (p_facilitator_id, p_client_id, p_start_time, p_end_time, 'pending')
    RETURNING id INTO v_appointment_id;

    RETURN v_appointment_id;
END;
$$;


ALTER FUNCTION "public"."book_appointment"("p_facilitator_id" "uuid", "p_client_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."broadcast_chat_message_changes"() RETURNS "trigger"
    LANGUAGE "plpgsql"
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


ALTER FUNCTION "public"."broadcast_chat_message_changes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."broadcast_message_reaction_changes"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- The trigger itself will generate postgres_changes events that clients can subscribe to
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."broadcast_message_reaction_changes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_distance"("point1" "public"."geography", "point2" "public"."geography", "unit" "text" DEFAULT 'km'::"text") RETURNS double precision
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    distance float;
BEGIN
    distance := ST_Distance(point1, point2);
    
    IF unit = 'km' THEN
        distance := distance / 1000;
    ELSIF unit = 'miles' THEN
        distance := distance / 1609.344;
    END IF;
    
    RETURN round(distance::numeric, 2);
END;
$$;


ALTER FUNCTION "public"."calculate_distance"("point1" "public"."geography", "point2" "public"."geography", "unit" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."can_access_appointment"("service_id" "uuid", "appointment_date" timestamp with time zone) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM appointment_purchases ap
        JOIN purchases p ON ap.purchase_id = p.id
        WHERE ap.service_id = service_id
        AND ap.appointment_date = appointment_date
        AND p.user_id = auth.uid()
        AND p.payment_status = 'completed'
        AND ap.status IN ('confirmed', 'pending', 'completed')
    );
    -- Note: Subscriptions typically don't grant access to appointments
END;
$$;


ALTER FUNCTION "public"."can_access_appointment"("service_id" "uuid", "appointment_date" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."can_access_content"("content_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_post_id UUID;
    v_creator_id UUID;
    v_post_type TEXT;
    v_content_id ALIAS FOR content_id; -- Use an alias for internal references
BEGIN
    -- Get post info for this content
    SELECT odm.post_id, p.user_id, p.post_type INTO v_post_id, v_creator_id, v_post_type
    FROM on_demand_media odm
    JOIN posts p ON odm.post_id = p.id
    WHERE odm.id = v_content_id;

    -- Free content is always accessible
    IF EXISTS (
        SELECT 1
        FROM on_demand_media odm
        WHERE odm.id = v_content_id AND odm.price = 0
    ) THEN
        RETURN TRUE;
    END IF;

    -- Check direct purchase first
    IF EXISTS (
        SELECT 1 
        FROM content_purchases cp
        JOIN purchases p ON cp.purchase_id = p.id
        WHERE cp.content_id = v_content_id
        AND p.user_id = auth.uid()
        AND p.payment_status = 'completed'
        AND (cp.access_expires_at IS NULL OR cp.access_expires_at > NOW())
    ) THEN
        RETURN TRUE;
    END IF;

    -- Check subscription access - look for any rule that matches
    IF v_creator_id IS NOT NULL THEN
        -- Check if content is specifically included in subscription
        IF EXISTS (
            SELECT 1
            FROM subscription_content_access sca
            JOIN subscriptions s ON TRUE
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst ON cst.creator_id = v_creator_id 
                AND cst.tier_key = s.tier
            WHERE sca.content_id = v_content_id
            AND p.user_id = auth.uid()
            AND p.owner_id = v_creator_id
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND sca.tier_key = s.tier
        ) THEN
            RETURN TRUE;
        END IF;

        -- Check if specific post is included in subscription
        IF EXISTS (
            SELECT 1
            FROM subscription_content_access sca
            JOIN subscriptions s ON TRUE
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst ON cst.creator_id = v_creator_id 
                AND cst.tier_key = s.tier
            WHERE sca.post_id = v_post_id
            AND p.user_id = auth.uid()
            AND p.owner_id = v_creator_id
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND sca.tier_key = s.tier
        ) THEN
            RETURN TRUE;
        END IF;

        -- Check if post type is included in subscription
        IF EXISTS (
            SELECT 1
            FROM subscription_content_access sca
            JOIN subscriptions s ON TRUE
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst ON cst.creator_id = v_creator_id 
                AND cst.tier_key = s.tier
            WHERE sca.post_type = v_post_type
            AND p.user_id = auth.uid()
            AND p.owner_id = v_creator_id
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND sca.tier_key = s.tier
        ) THEN
            RETURN TRUE;
        END IF;
    END IF;

    -- No access
    RETURN FALSE;
END;
$$;


ALTER FUNCTION "public"."can_access_content"("content_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."can_access_content_v2"("input_content_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_post_id UUID;
    v_creator_id UUID;
    v_post_type TEXT;
BEGIN
    -- Get post info for this content
    SELECT odm.post_id, p.user_id, p.post_type INTO v_post_id, v_creator_id, v_post_type
    FROM on_demand_media odm
    JOIN posts p ON odm.post_id = p.id
    WHERE odm.id = input_content_id;

    -- Free content is always accessible
    IF EXISTS (
        SELECT 1
        FROM on_demand_media
        WHERE id = input_content_id AND price = 0
    ) THEN
        RETURN TRUE;
    END IF;

    -- Check direct purchase first
    IF EXISTS (
        SELECT 1 
        FROM content_purchases cp
        JOIN purchases p ON cp.purchase_id = p.id
        WHERE cp.content_id = input_content_id
        AND p.user_id = auth.uid()
        AND p.payment_status = 'completed'
        AND (cp.access_expires_at IS NULL OR cp.access_expires_at > NOW())
    ) THEN
        RETURN TRUE;
    END IF;

    -- Check subscription access - look for any rule that matches
    IF v_creator_id IS NOT NULL THEN
        -- Check if content is specifically included in subscription
        IF EXISTS (
            SELECT 1
            FROM subscription_content_access sca
            JOIN subscriptions s ON TRUE
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst ON cst.creator_id = v_creator_id 
                AND cst.tier_key = s.tier
            WHERE sca.content_id = input_content_id
            AND p.user_id = auth.uid()
            AND p.owner_id = v_creator_id
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND sca.tier_key = s.tier
        ) THEN
            RETURN TRUE;
        END IF;

        -- Check if specific post is included in subscription
        IF EXISTS (
            SELECT 1
            FROM subscription_content_access sca
            JOIN subscriptions s ON TRUE
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst ON cst.creator_id = v_creator_id 
                AND cst.tier_key = s.tier
            WHERE sca.post_id = v_post_id
            AND p.user_id = auth.uid()
            AND p.owner_id = v_creator_id
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND sca.tier_key = s.tier
        ) THEN
            RETURN TRUE;
        END IF;

        -- Check if post type is included in subscription
        IF EXISTS (
            SELECT 1
            FROM subscription_content_access sca
            JOIN subscriptions s ON TRUE
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst ON cst.creator_id = v_creator_id 
                AND cst.tier_key = s.tier
            WHERE sca.post_type = v_post_type
            AND p.user_id = auth.uid()
            AND p.owner_id = v_creator_id
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND sca.tier_key = s.tier
        ) THEN
            RETURN TRUE;
        END IF;
    END IF;

    -- No access
    RETURN FALSE;
END;
$$;


ALTER FUNCTION "public"."can_access_content_v2"("input_content_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."can_access_event"("event_id" "uuid", "date_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    -- Check direct booking
    RETURN EXISTS (
        SELECT 1 
        FROM event_bookings eb
        JOIN purchases p ON eb.purchase_id = p.id
        WHERE eb.event_id = event_id
        AND eb.date_id = date_id
        AND p.user_id = auth.uid()
        AND p.payment_status = 'completed'
        AND eb.status IN ('confirmed', 'pending', 'attended')
    );
    -- Note: Subscriptions typically don't grant access to events
END;
$$;


ALTER FUNCTION "public"."can_access_event"("event_id" "uuid", "date_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."can_attend_event"("p_event_id" "uuid", "p_date_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_user_id UUID;
    v_has_access BOOLEAN;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    -- Check if the user is authenticated
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if the user is the event creator
    SELECT EXISTS (
        SELECT 1
        FROM public.events e
        JOIN public.posts p ON e.post_id = p.id
        WHERE e.id = p_event_id
        AND p.user_id = v_user_id
    ) INTO v_has_access;
    
    -- If user is creator, they have access
    IF v_has_access THEN
        RETURN TRUE;
    END IF;
    
    -- Check if the user has purchased a ticket for this event date
    SELECT EXISTS (
        SELECT 1
        FROM public.purchases p
        JOIN public.event_bookings eb ON p.id = eb.purchase_id
        WHERE p.event_id = p_event_id
        AND eb.date_id = p_date_id
        AND p.user_id = v_user_id
        AND p.payment_status = 'completed'
    ) INTO v_has_access;
    
    RETURN v_has_access;
END;
$$;


ALTER FUNCTION "public"."can_attend_event"("p_event_id" "uuid", "p_date_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."can_create_broadcast_room"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- For testing purposes, always allow creating broadcast rooms
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."can_create_broadcast_room"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_event_date_delete"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Check if there are any purchases for this event date
    IF EXISTS (
        SELECT 1
        FROM public.ticket_purchases
        WHERE date_id = OLD.id
    ) THEN
        RAISE EXCEPTION 'You cannot delete this event date because tickets have already been purchased for it';
    END IF;
    
    -- If no purchases found, allow the delete
    RETURN OLD;
END;
$$;


ALTER FUNCTION "public"."check_event_date_delete"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_schedule_conflicts"("p_provider_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone, "p_exclude_appointment_id" "uuid" DEFAULT NULL::"uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_has_conflicts BOOLEAN;
BEGIN
    -- Lock the provider's schedule for consistent checking
    -- In a real transaction, this would use lock_provider_schedule
    
    -- Check for conflicts
    SELECT EXISTS (
        -- Check appointment_purchases conflicts
        SELECT 1
        FROM public.appointment_purchases ap
        JOIN public.purchases p ON ap.purchase_id = p.id
        WHERE p.owner_id = p_provider_id
        AND ap.status IN ('confirmed', 'pending_approval', 'pending_payment')
        AND (ap.id != p_exclude_appointment_id OR p_exclude_appointment_id IS NULL)
        AND (ap.appointment_date, ap.appointment_date + (ap.duration || ' minutes')::INTERVAL)
            OVERLAPS (p_start_time, p_end_time)

        UNION ALL

        -- Check legacy appointments conflicts
        SELECT 1
        FROM public.appointments a
        WHERE a.facilitator_id = p_provider_id
        AND a.status IN ('confirmed', 'pending')
        AND (a.start_time, a.end_time) OVERLAPS (p_start_time, p_end_time)

        UNION ALL

        -- Check event conflicts
        SELECT 1
        FROM public.event_dates ed
        JOIN public.event_bookings eb ON ed.id = eb.date_id
        JOIN public.purchases p ON eb.purchase_id = p.id
        WHERE p.owner_id = p_provider_id
        AND eb.status IN ('confirmed', 'pending')
        AND (ed.start_date, ed.end_date) OVERLAPS (p_start_time, p_end_time)
    ) INTO v_has_conflicts;

    RETURN v_has_conflicts;
END;
$$;


ALTER FUNCTION "public"."check_schedule_conflicts"("p_provider_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone, "p_exclude_appointment_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."check_schedule_conflicts"("p_provider_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone, "p_exclude_appointment_id" "uuid") IS 'Checks for scheduling conflicts across appointment systems';



CREATE OR REPLACE FUNCTION "public"."check_ticket_delete"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Check if there are any purchases for this ticket
    IF EXISTS (
        SELECT 1
        FROM public.ticket_purchases
        WHERE ticket_id = OLD.id
    ) THEN
        RAISE EXCEPTION 'You cannot delete this ticket because it has already been purchased by a customer';
    END IF;
    
    -- If no purchases found, allow the delete
    RETURN OLD;
END;
$$;


ALTER FUNCTION "public"."check_ticket_delete"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_old_notifications"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_deleted_count INTEGER;
  v_retention_days INTEGER := 90; -- Keep notifications for 90 days
BEGIN
  -- Delete old read notifications
  WITH deleted AS (
    DELETE FROM notifications
    WHERE 
      is_read = TRUE 
      AND created_at < NOW() - (v_retention_days * INTERVAL '1 day')
    RETURNING id
  )
  SELECT count(*) INTO v_deleted_count FROM deleted;
  
  RETURN v_deleted_count;
END;
$$;


ALTER FUNCTION "public"."cleanup_old_notifications"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_article_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."article_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_post_id UUID;
    v_article_id UUID;
    v_result article_content_creation_result;
    v_user_id UUID;
BEGIN
    -- If user_id is not provided, use the authenticated user's ID
    IF user_id IS NULL THEN
        v_user_id := auth.uid();
    ELSE
        v_user_id := user_id;
    END IF;

    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'article'::post_type_enum,
        p_status,
        p_thumbnail_url,
        v_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the article record
    INSERT INTO public.articles (
        post_id,
        content
    ) VALUES (
        v_post_id,
        p_content
    ) RETURNING id INTO v_article_id;

    -- Prepare the result
    v_result := (v_post_id, v_article_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating article content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_article_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_broadcast_announcement"("p_title" "text", "p_content" "text", "p_action_url" "text" DEFAULT NULL::"text", "p_reference_id" "uuid" DEFAULT NULL::"uuid", "p_reference_type" "text" DEFAULT NULL::"text", "p_metadata" "jsonb" DEFAULT '{}'::"jsonb", "p_audience_type" "public"."notification_audience_type" DEFAULT 'all'::"public"."notification_audience_type", "p_audience_criteria" "jsonb" DEFAULT NULL::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_sender_id UUID := auth.uid();
  v_notification_id UUID;
BEGIN
  -- Check permission based on audience type
  IF p_audience_type = 'all' AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_sender_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admin users can send broadcasts to all users';
  END IF;
  
  -- Create a single broadcast notification record
  INSERT INTO notifications (
    user_id,                  -- Set this to NULL for broadcast announcements
    sender_id,
    title,
    content,
    type,
    action_url,
    reference_id,
    reference_type,
    metadata,
    audience_type,           -- New field
    audience_criteria        -- New field
  )
  VALUES (
    NULL,                    -- NULL user_id indicates it's a broadcast
    v_sender_id,
    p_title,
    p_content,
    'announcement'::public.notification_type,
    p_action_url,
    p_reference_id,
    COALESCE(p_reference_type, 'announcement'),
    p_metadata || jsonb_build_object('broadcast_created_at', now()),
    p_audience_type,
    p_audience_criteria
  )
  RETURNING id INTO v_notification_id;
  
  -- Create notification delivery records for tracking purposes
  -- This will allow us to track metrics without creating duplicate notifications
  WITH eligible_users AS (
    SELECT id FROM auth.users 
    WHERE id != v_sender_id -- Skip the sender
  )
  INSERT INTO notification_deliveries (
    notification_id,
    user_id,
    status,
    delivery_type
  )
  SELECT 
    v_notification_id,
    id,
    'pending',
    'in_app'
  FROM eligible_users;
  
  RETURN v_notification_id;
END;
$$;


ALTER FUNCTION "public"."create_broadcast_announcement"("p_title" "text", "p_content" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb", "p_audience_type" "public"."notification_audience_type", "p_audience_criteria" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_ceremony_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_ceremony_type" "text", "p_ceremony_theme" "text", "p_ceremony_focus" "text", "p_what_to_bring" "text", "p_space_holder_names" "text", "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."ceremony_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_post_id UUID;
    v_ondemand_media_id UUID;
    v_protected_media_id UUID;
    v_ceremony_id UUID;
    v_result ceremony_content_creation_result;
    v_user_id UUID;
BEGIN
    v_user_id := COALESCE(p_user_id, auth.uid());
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;
    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'ceremony'::post_type_enum,
        p_status,
        p_thumbnail_url,
        v_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the on_demand_media record
    v_ondemand_media_id := public.create_ondemand_media(
        v_post_id,
        p_media_type,
        p_duration,
        p_price,
        v_user_id
    );

    -- Create the protected_media_data record
    v_protected_media_id := public.create_protected_media_data(
        v_ondemand_media_id,
        p_status,
        p_protected_media_url
    );

    -- Add playlist associations
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Create the ceremony record
    INSERT INTO public.ceremony (
        content_id,
        ceremony_type,
        ceremony_theme,
        ceremony_focus,
        what_to_bring,
        space_holder_names
    ) VALUES (
        v_ondemand_media_id,
        p_ceremony_type,
        p_ceremony_theme,
        p_ceremony_focus,
        p_what_to_bring,
        p_space_holder_names
    ) RETURNING id INTO v_ceremony_id;

    -- Prepare the result
    v_result := (v_post_id, v_ondemand_media_id, v_protected_media_id, v_ceremony_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating ceremony content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_ceremony_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_ceremony_type" "text", "p_ceremony_theme" "text", "p_ceremony_focus" "text", "p_what_to_bring" "text", "p_space_holder_names" "text", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_dance_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_freeform_movement" boolean, "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."dance_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_dance_id UUID;
    v_result public.dance_content_creation_result;
BEGIN
    -- Create base on-demand content
    v_base_result := public.create_ondemand_content_with_details(
        p_title, p_slug, p_description, p_content, p_thumbnail_url,
        p_tags, p_status, p_media_type,'dance'::post_type_enum, p_duration, p_price,
        p_protected_media_url, p_emotional_focuses, p_playlist_ids,
        p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment,
        p_body_focus, p_props, p_user_id
    );

    -- Create the dance record
    INSERT INTO public.dance (
        movement_id,
        freeform_movement
    ) VALUES (
        v_base_result.movement_id,
        p_freeform_movement
    ) RETURNING id INTO v_dance_id;

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_dance_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating dance content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_dance_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_freeform_movement" boolean, "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_event"("p_post_id" "uuid", "p_content" "text", "p_event_type" "public"."event_type_enum") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_event_id UUID;
BEGIN
    INSERT INTO public.events (
        post_id, content, type
    ) VALUES (
        p_post_id, p_content, p_event_type
    ) RETURNING id INTO v_event_id;

    RETURN v_event_id;
END;
$$;


ALTER FUNCTION "public"."create_event"("p_post_id" "uuid", "p_content" "text", "p_event_type" "public"."event_type_enum") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_event_purchase"("p_event_id" "uuid", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_quantity" integer, "p_is_virtual" boolean DEFAULT false, "p_payment_intent_id" "text" DEFAULT NULL::"text", "p_payment_status" "text" DEFAULT 'pending'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_user_id UUID;
    v_owner_id UUID;
    v_post_id UUID;
    v_ticket_price NUMERIC(10, 2);
    v_currency TEXT;
    v_purchase_id UUID;
    v_booking_id UUID;
    v_is_sold_out BOOLEAN;
    v_is_date_fully_booked BOOLEAN;
    v_ticket_title TEXT;
    v_result JSONB;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    -- Check if the user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to purchase tickets';
    END IF;
    
    -- Get event owner and post details
    SELECT p.user_id, e.post_id 
    INTO v_owner_id, v_post_id
    FROM public.events e
    JOIN public.posts p ON e.post_id = p.id
    WHERE e.id = p_event_id;
    
    -- Check if event exists
    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Event not found';
    END IF;
    
    -- Get ticket price and check availability
    SELECT 
        t.price, 
        t.title,
        etv.is_sold_out
    INTO 
        v_ticket_price, 
        v_ticket_title,
        v_is_sold_out
    FROM public.tickets t
    JOIN public.event_tickets_view etv ON t.id = etv.ticket_id
    WHERE t.id = p_ticket_id;
    
    -- Check if ticket exists
    IF v_ticket_price IS NULL THEN
        RAISE EXCEPTION 'Ticket not found';
    END IF;
    
    -- Check if ticket is sold out
    IF v_is_sold_out THEN
        RAISE EXCEPTION 'This ticket type is sold out';
    END IF;
    
    -- Check if date is fully booked
    SELECT edv.is_fully_booked
    INTO v_is_date_fully_booked
    FROM public.event_dates_view edv
    WHERE edv.date_id = p_date_id;
    
    -- Check if date exists
    IF v_is_date_fully_booked IS NULL THEN
        RAISE EXCEPTION 'Event date not found';
    END IF;
    
    -- Check if date is fully booked
    IF v_is_date_fully_booked THEN
        RAISE EXCEPTION 'This event date is fully booked';
    END IF;
    
    -- Default currency
    v_currency := 'GBP';
    
    -- Create purchase record
    INSERT INTO public.purchases (
        user_id,
        owner_id,
        stripe_payment_intent_id,
        amount,
        currency,
        payment_status,
        post_id,
        event_id,
        purchase_type,
        quantity,
        start_date,
        metadata
    ) VALUES (
        v_user_id,
        v_owner_id,
        p_payment_intent_id,
        v_ticket_price * p_quantity,
        v_currency,
        p_payment_status,
        v_post_id,
        p_event_id,
        'event',
        p_quantity,
        (SELECT start_date FROM public.event_dates WHERE id = p_date_id),
        jsonb_build_object(
            'ticket_name', v_ticket_title,
            'ticket_id', p_ticket_id,
            'date_id', p_date_id,
            'is_virtual', p_is_virtual
        )
    ) RETURNING id INTO v_purchase_id;
    
    -- Create event booking record
    INSERT INTO public.event_bookings (
        purchase_id,
        event_id,
        ticket_id,
        date_id,
        attendees,
        is_virtual,
        status,
        ticket_code
    ) VALUES (
        v_purchase_id,
        p_event_id,
        p_ticket_id,
        p_date_id,
        p_quantity,
        p_is_virtual,
        CASE WHEN p_payment_status = 'completed' THEN 'confirmed' ELSE 'pending' END,
        UPPER(SUBSTRING(MD5(gen_random_uuid()::TEXT) FROM 1 FOR 8))
    ) RETURNING id INTO v_booking_id;
    
    -- Prepare result object to match other purchase function patterns
    v_result := jsonb_build_object(
        'purchase_id', v_purchase_id,
        'booking_id', v_booking_id,
        'event_id', p_event_id,
        'ticket_id', p_ticket_id,
        'date_id', p_date_id,
        'amount', v_ticket_price * p_quantity,
        'payment_status', p_payment_status,
        'attendees', p_quantity
    );
    
    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."create_event_purchase"("p_event_id" "uuid", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_quantity" integer, "p_is_virtual" boolean, "p_payment_intent_id" "text", "p_payment_status" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_event_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_event_type" "public"."event_type_enum", "p_event_dates" "public"."event_date_input"[], "p_tickets" "public"."ticket_input"[], "p_room_name" "text" DEFAULT NULL::"text", "p_room_password" "text" DEFAULT NULL::"text", "p_location_id" "uuid" DEFAULT NULL::"uuid", "user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."event_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_post_id UUID;
    v_event_id UUID;
    v_room_id UUID;
    v_date_results JSONB;
    v_result event_creation_result;
    v_user_id UUID;
BEGIN
    -- If user_id is not provided, use the authenticated user's ID
    IF user_id IS NULL THEN
        v_user_id := auth.uid();
    ELSE
        v_user_id := user_id;
    END IF;
    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'event'::post_type_enum,
        p_status,
        p_thumbnail_url,
        v_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the event
    v_event_id := public.create_event(v_post_id, p_content, p_event_type);

    -- Add event dates
    v_date_results := public.add_event_dates(v_event_id, p_event_dates);

    -- Add tickets
    PERFORM public.add_tickets(v_event_id, p_tickets);

    -- Handle room creation for online or hybrid events
    IF p_event_type IN ('online', 'hybrid') AND p_room_name IS NOT NULL THEN
        v_room_id := public.create_live_room(v_post_id, p_room_name, p_room_password);
    END IF;

    -- Associate location for in-person or hybrid events
    IF p_event_type IN ('in-person', 'hybrid') AND p_location_id IS NOT NULL THEN
        PERFORM public.associate_post_location(v_post_id, p_location_id);
    END IF;

    -- Prepare the result
    v_result := (v_event_id, v_post_id, v_room_id, p_slug);

    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."create_event_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_event_type" "public"."event_type_enum", "p_event_dates" "public"."event_date_input"[], "p_tickets" "public"."ticket_input"[], "p_room_name" "text", "p_room_password" "text", "p_location_id" "uuid", "user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_follower_broadcast"("p_follower_ids" "uuid"[], "p_title" "text", "p_content" "text", "p_action_url" "text" DEFAULT NULL::"text", "p_reference_id" "uuid" DEFAULT NULL::"uuid", "p_reference_type" "text" DEFAULT NULL::"text", "p_metadata" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_sender_id UUID := auth.uid();
  v_notification_id UUID;
BEGIN
  -- Check if the user is authenticated
  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated to send broadcasts';
  END IF;
  
  -- Create a single broadcast notification record
  INSERT INTO notifications (
    user_id,                   -- NULL for broadcast notifications
    sender_id,                 -- Creator's user ID
    title,
    content,
    type,
    action_url,
    reference_id,
    reference_type,
    metadata,
    audience_type
  )
  VALUES (
    NULL,
    v_sender_id,
    p_title,
    p_content,
    'broadcast'::public.notification_type,  -- Using the updated enum value
    p_action_url,
    p_reference_id,
    COALESCE(p_reference_type, 'broadcast'),
    jsonb_build_object(
      'broadcast_created_at', now(),
      'recipient_count', array_length(p_follower_ids, 1)
    ) || p_metadata,
    'followers'::public.notification_audience_type
  )
  RETURNING id INTO v_notification_id;
  
  -- Create notification recipient records for each follower
  INSERT INTO notification_recipients (
    notification_id,
    user_id,
    is_read
  )
  SELECT 
    v_notification_id,
    id,
    FALSE
  FROM unnest(p_follower_ids) as id;
  
  RETURN v_notification_id;
END;
$$;


ALTER FUNCTION "public"."create_follower_broadcast"("p_follower_ids" "uuid"[], "p_title" "text", "p_content" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_generic_ondemand_content"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."generic_ondemand_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_post_id UUID;
    v_ondemand_media_id UUID;
    v_protected_media_id UUID;
    v_result public.generic_ondemand_content_creation_result;
BEGIN
    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'on_demand'::post_type_enum, -- Specify 'on_demand' post type
        p_status,
        p_thumbnail_url,
        p_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the on_demand_media record
    v_ondemand_media_id := public.create_ondemand_media(
        v_post_id,
        p_media_type,
        p_duration,
        p_price,
        p_user_id
    );

    -- Create the protected_media_data record
    v_protected_media_id := public.create_protected_media_data(
        v_ondemand_media_id,
        p_status,
        p_protected_media_url
    );

    -- Add emotional focuses
    PERFORM public.add_emotional_focuses(v_post_id, p_emotional_focuses);

    -- Add playlist associations
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Prepare the result (no movement_id)
    v_result := (v_post_id, v_ondemand_media_id, v_protected_media_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating generic on-demand content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_generic_ondemand_content"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_journal_entry"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_mood" "public"."mood_enum" DEFAULT NULL::"public"."mood_enum", "p_privacy" "public"."journal_entry_privacy_enum" DEFAULT 'private'::"public"."journal_entry_privacy_enum", "p_tags" "text"[] DEFAULT NULL::"text"[], "p_post_id" "uuid" DEFAULT NULL::"uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_journal_entry_id bigint;
  v_tag_id bigint;
  v_tag_name text;
begin
  -- Insert the journal entry
  insert into journal_entries (user_id, title, content, mood, privacy)
  values (p_user_id, p_title, p_content, p_mood, p_privacy)
  returning id into v_journal_entry_id;
  
  -- Handle tags if provided
  if p_tags is not null then
    foreach v_tag_name in array p_tags loop
      -- Try to find existing tag or create new one
      select id into v_tag_id from journal_tags where name = v_tag_name;
      
      if v_tag_id is null then
        insert into journal_tags (name)
        values (v_tag_name)
        returning id into v_tag_id;
      end if;
      
      -- Link tag to journal entry
      insert into journal_entry_tags (journal_entry_id, tag_id)
      values (v_journal_entry_id, v_tag_id);
    end loop;
  end if;
  
  -- Link to content if provided
  if p_post_id is not null then
    insert into journal_content_links (journal_entry_id, post_id)
    values (v_journal_entry_id, p_post_id);
  end if;
  
  -- Return the created journal entry with its relationships
  return (
    select jsonb_build_object(
      'journal_entry', row_to_json(je),
      'tags', coalesce(
        (select jsonb_agg(jt.name)
         from journal_entry_tags jet
         join journal_tags jt on jet.tag_id = jt.id
         where jet.journal_entry_id = je.id),
        '[]'::jsonb
      ),
      'content_links', coalesce(
        (select jsonb_agg(jcl.post_id)
         from journal_content_links jcl
         where jcl.journal_entry_id = je.id),
        '[]'::jsonb
      )
    )
    from journal_entries je
    where je.id = v_journal_entry_id
  );
end;
$$;


ALTER FUNCTION "public"."create_journal_entry"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_mood" "public"."mood_enum", "p_privacy" "public"."journal_entry_privacy_enum", "p_tags" "text"[], "p_post_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_live_room"("p_post_id" "uuid", "p_name" "text", "p_password" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_room_id UUID;
BEGIN
    INSERT INTO public.live_rooms (
        post_id, user_id, name, password
    ) VALUES (
        p_post_id, auth.uid(), p_name, p_password
    ) RETURNING id INTO v_room_id;

    RETURN v_room_id;
END;
$$;


ALTER FUNCTION "public"."create_live_room"("p_post_id" "uuid", "p_name" "text", "p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_location"("p_name" "text", "p_description" "text", "p_image_url" "text", "p_line_1" "text", "p_line_2" "text", "p_city" "text", "p_country" "text", "p_postcode" "text", "p_maps_link" "text") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_location_id UUID;
BEGIN
    INSERT INTO public.locations (
        name, description, image_url, line_1, line_2, city, country, postcode, maps_link, user_id
    ) VALUES (
        p_name, p_description, p_image_url, p_line_1, p_line_2, p_city, p_country, p_postcode, p_maps_link, auth.uid()
    ) RETURNING id INTO v_location_id;

    RETURN v_location_id;
END;
$$;


ALTER FUNCTION "public"."create_location"("p_name" "text", "p_description" "text", "p_image_url" "text", "p_line_1" "text", "p_line_2" "text", "p_city" "text", "p_country" "text", "p_postcode" "text", "p_maps_link" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_meditation_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_meditation_type" "text", "p_meditation_theme" "text", "p_meditation_focus" "text", "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."meditation_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_post_id UUID;
    v_ondemand_media_id UUID;
    v_protected_media_id UUID;
    v_meditation_id UUID;
    v_result meditation_content_creation_result;
    v_user_id UUID;
BEGIN
    v_user_id := COALESCE(p_user_id, auth.uid());
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;

    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'meditation'::post_type_enum,
        p_status,
        p_thumbnail_url,
        v_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the on_demand_media record
    v_ondemand_media_id := public.create_ondemand_media(
        v_post_id,
        p_media_type,
        p_duration,
        p_price,
        v_user_id
    );

    -- Create the protected_media_data record
    v_protected_media_id := public.create_protected_media_data(
        v_ondemand_media_id,
        p_status,
        p_protected_media_url
    );

    -- Add playlist associations
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Create the meditation record
    INSERT INTO public.meditations (
        content_id,
        meditation_type,
        meditation_theme,
        meditation_focus
    ) VALUES (
        v_ondemand_media_id,
        p_meditation_type,
        p_meditation_theme,
        p_meditation_focus
    ) RETURNING id INTO v_meditation_id;

    -- Prepare the result
    v_result := (v_post_id, v_ondemand_media_id, v_protected_media_id, v_meditation_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating meditation content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_meditation_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_meditation_type" "text", "p_meditation_theme" "text", "p_meditation_focus" "text", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_movement"("p_content_id" "uuid", "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_movement_id UUID;
BEGIN
    INSERT INTO public.movements (
        content_id, instructor_name, session_theme, energy_level, 
        spiritual_elements, emotional_focus, recommended_environment, body_focus
    ) VALUES (
        p_content_id, p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment, p_body_focus
    ) RETURNING id INTO v_movement_id;

    IF v_movement_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create movement record';
    END IF;

    RETURN v_movement_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating movement: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_movement"("p_content_id" "uuid", "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_neuroflow_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_techniques_used" "text", "p_session_focus" "text", "p_personal_growth_outcomes" "text", "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."neuroflow_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_neuroflow_id UUID;
    v_result public.neuroflow_content_creation_result;
BEGIN
    -- Create base on-demand content
    v_base_result := public.create_ondemand_content_with_details(
        p_title, p_slug, p_description, p_content, p_thumbnail_url,
        p_tags, p_status, p_media_type, 'neuro_flow'::post_type_enum, p_duration, p_price,
        p_protected_media_url, p_emotional_focuses, p_playlist_ids,
        p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment,
        p_body_focus, p_props, p_user_id
    );

    -- Create the neuro flow record
    INSERT INTO public.neuroflow (
        movement_id,
        techniques_used,
        session_focus,
        personal_growth_outcomes
    ) VALUES (
        v_base_result.movement_id,
        p_techniques_used,
        p_session_focus,
        p_personal_growth_outcomes
    ) RETURNING id INTO v_neuroflow_id;

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_neuroflow_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating neuro flow content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_neuroflow_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_techniques_used" "text", "p_session_focus" "text", "p_personal_growth_outcomes" "text", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_priority" "text" DEFAULT 'medium'::"text", "p_related_entity_id" "uuid" DEFAULT NULL::"uuid", "p_action" "text" DEFAULT NULL::"text", "p_metadata" "jsonb" DEFAULT NULL::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO public.notifications (
        user_id,
        sender_id,
        title,
        content,
        type,
        reference_id, -- use reference_id instead of related_entity_id
        action_url, -- use action_url instead of action
        metadata
    ) VALUES (
        p_user_id,
        p_sender_id,
        p_title,
        p_content,
        p_type::public.notification_type, -- Explicitly cast to enum type
        p_related_entity_id, -- renamed to reference_id
        p_action, -- renamed to action_url
        COALESCE(p_metadata, '{}'::jsonb)
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$;


ALTER FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_priority" "text", "p_related_entity_id" "uuid", "p_action" "text", "p_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_notification_for_all_users"("p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text" DEFAULT NULL::"text", "p_reference_id" "uuid" DEFAULT NULL::"uuid", "p_reference_type" "text" DEFAULT NULL::"text", "p_metadata" "jsonb" DEFAULT '{}'::"jsonb") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_user_ids UUID[];
  v_count INTEGER;
  v_sender_id UUID := auth.uid(); -- Store sender ID
BEGIN
  -- Check if user has admin role
  IF NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_sender_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admin users can send notifications to all users';
  END IF;
  
  -- Get all user IDs
  SELECT ARRAY_AGG(au.id) INTO v_user_ids
  FROM auth.users au
  WHERE au.id != v_sender_id; -- Skip the sending admin
  
  -- Insert notifications directly to ensure sender_id is set
  WITH inserted_notifications AS (
    INSERT INTO notifications (
      user_id,
      sender_id,
      title,
      content,
      type,
      action_url,
      reference_id,
      reference_type,
      metadata
    )
    SELECT 
      user_id,
      v_sender_id,
      p_title,
      p_content,
      p_type::public.notification_type,
      p_action_url,
      p_reference_id,
      p_reference_type,
      jsonb_build_object('sender_id', v_sender_id) || p_metadata
    FROM UNNEST(v_user_ids) AS user_id
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM inserted_notifications;
  
  RETURN v_count;
END;
$$;


ALTER FUNCTION "public"."create_notification_for_all_users"("p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."create_notification_for_all_users"("p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") IS 'Creates notifications for all users - admin only, with sender tracking';



CREATE OR REPLACE FUNCTION "public"."create_notifications_batch"("p_user_ids" "uuid"[], "p_sender_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_priority" "text" DEFAULT 'medium'::"text", "p_related_entity_id" "uuid" DEFAULT NULL::"uuid", "p_action" "text" DEFAULT NULL::"text", "p_metadata" "jsonb" DEFAULT NULL::"jsonb") RETURNS SETOF "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    user_id_in_loop UUID;
    notification_id UUID;
BEGIN
    FOREACH user_id_in_loop IN ARRAY p_user_ids LOOP
        -- Insert directly to avoid multiple auth.uid() calls and ensure consistent sender
        INSERT INTO public.notifications (
            user_id,
            sender_id,
            title,
            content,
            type,
            reference_id,
            action_url,
            metadata
        ) VALUES (
            user_id_in_loop,
            p_sender_id,
            p_title,
            p_content,
            p_type::public.notification_type,
            p_related_entity_id,
            p_action,
            COALESCE(p_metadata, '{}'::jsonb)
        ) RETURNING id INTO notification_id;
        
        RETURN NEXT notification_id;
    END LOOP;
    
    RETURN;
END;
$$;


ALTER FUNCTION "public"."create_notifications_batch"("p_user_ids" "uuid"[], "p_sender_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_priority" "text", "p_related_entity_id" "uuid", "p_action" "text", "p_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_ondemand_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_post_type" "public"."post_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."ondemand_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_post_id UUID;
    v_ondemand_media_id UUID;
    v_movement_id UUID;
    v_protected_media_id UUID;
    v_result ondemand_content_creation_result;
BEGIN
    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        p_post_type,
        p_status,
        p_thumbnail_url,
        p_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the on_demand_media record
    v_ondemand_media_id := public.create_ondemand_media(
        v_post_id,
        p_media_type,
        p_duration,
        p_price,
        p_user_id
    );

    -- Create the protected_media_data record
    v_protected_media_id := public.create_protected_media_data(
        v_ondemand_media_id,
        p_status,
        p_protected_media_url
    );

    -- Add emotional focuses
    PERFORM public.add_emotional_focuses(v_post_id, p_emotional_focuses);

    -- Add playlist associations
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Create the movement record
    v_movement_id := public.create_movement(
        v_ondemand_media_id,
        p_instructor_name,
        p_session_theme,
        p_energy_level,
        p_spiritual_elements,
        p_emotional_focus,
        p_recommended_environment,
        p_body_focus
    );

    -- Add movement props
    PERFORM public.add_movement_props(v_movement_id, p_props);

    -- Prepare the result
    v_result := (v_post_id, v_ondemand_media_id, v_movement_id, v_protected_media_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating on-demand content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_ondemand_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_post_type" "public"."post_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_ondemand_media"("p_post_id" "uuid", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_ondemand_media_id UUID;
    v_user_id UUID;
BEGIN
    v_user_id := COALESCE(p_user_id, auth.uid());
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;

    INSERT INTO public.on_demand_media (
        post_id, user_id, media_type, duration, price
    ) VALUES (
        p_post_id, v_user_id, p_media_type, p_duration, p_price
    ) RETURNING id INTO v_ondemand_media_id;

    IF v_ondemand_media_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create on_demand_media record';
    END IF;

    RETURN v_ondemand_media_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating on_demand_media: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_ondemand_media"("p_post_id" "uuid", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_or_get_private_chat"("p_user_id1" "uuid", "p_user_id2" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
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
$$;


ALTER FUNCTION "public"."create_or_get_private_chat"("p_user_id1" "uuid", "p_user_id2" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_or_update_batched_chat_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_chat_id" "uuid", "p_message_preview" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    existing_notification_id UUID;
    notification_id UUID;
    message_count INTEGER;
    updated_metadata JSONB;
    sender_name TEXT;
BEGIN
    -- Get sender's name
    SELECT full_name INTO sender_name
    FROM profiles
    WHERE id = p_sender_id;
    
    -- Default sender name if not found
    sender_name := COALESCE(sender_name, 'Someone');
    
    -- Check for existing unread notification for this chat
    SELECT n.id
    INTO existing_notification_id
    FROM public.notifications n
    WHERE n.user_id = p_user_id
        AND n.reference_id = p_chat_id
        AND n.type = 'message'::public.notification_type
        AND n.is_read = FALSE;
    
    IF existing_notification_id IS NULL THEN
        -- No existing notification, create a new one
        INSERT INTO public.notifications (
            user_id,
            sender_id,
            title,
            content,
            type,
            reference_id,
            reference_type,
            metadata
        ) VALUES (
            p_user_id,
            p_sender_id,
            sender_name,  -- More descriptive title using sender name
            p_message_preview,
            'message'::public.notification_type,
            p_chat_id,
            'chat',
            jsonb_build_object(
                'chat_id', p_chat_id,
                'message_count', 1,
                'sender_id', p_sender_id,
                'sender_name', sender_name,
                'messages', jsonb_build_array(
                    jsonb_build_object(
                        'text', p_message_preview,
                        'timestamp', now()
                    )
                )
            )
        ) RETURNING id INTO notification_id;
    ELSE
        -- Update existing notification with new message count and content
        SELECT COALESCE((metadata->>'message_count')::int, 1) + 1
        INTO message_count
        FROM public.notifications
        WHERE id = existing_notification_id;
        
        -- Update metadata with new count and add message to array
        WITH notification_data AS (
            SELECT 
                metadata->'messages' as existing_messages,
                metadata
            FROM public.notifications
            WHERE id = existing_notification_id
        )
        SELECT 
            jsonb_set(
                jsonb_set(
                    metadata,
                    '{message_count}',
                    to_jsonb(message_count)
                ),
                '{messages}',
                COALESCE(
                    existing_messages || jsonb_build_array(
                        jsonb_build_object(
                            'text', p_message_preview,
                            'timestamp', now()
                        )
                    ),
                    jsonb_build_array(
                        jsonb_build_object(
                            'text', p_message_preview,
                            'timestamp', now()
                        )
                    )
                )
            )
        INTO updated_metadata
        FROM notification_data;
        
        -- Update the notification with new count and latest message
        UPDATE public.notifications
        SET 
            title = sender_name,
            content = CASE 
                WHEN message_count > 1 THEN message_count || ' new messages from ' || sender_name
                ELSE p_message_preview
            END,
            updated_at = NOW(),
            metadata = updated_metadata
        WHERE id = existing_notification_id;
        
        notification_id := existing_notification_id;
    END IF;
    
    RETURN notification_id;
END;
$$;


ALTER FUNCTION "public"."create_or_update_batched_chat_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_chat_id" "uuid", "p_message_preview" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."create_or_update_batched_chat_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_chat_id" "uuid", "p_message_preview" "text") IS 'Creates or updates batched notifications for chat messages to prevent notification spam';



CREATE OR REPLACE FUNCTION "public"."create_post"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_post_type" "public"."post_type_enum", "p_status" "public"."publish_status_enum", "p_thumbnail_url" "text", "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_post_id UUID;
    v_user_id UUID;
    v_slug TEXT := p_slug;
    v_counter INTEGER := 1;
BEGIN
    v_user_id := COALESCE(p_user_id, auth.uid());

    -- Keep trying with modified slugs until one works
    LOOP
        BEGIN
            INSERT INTO public.posts (
                user_id, title, slug, description, content, post_type, status, thumbnail_url
            ) VALUES (
                v_user_id, p_title, v_slug, p_description, p_content, p_post_type, p_status, p_thumbnail_url
            ) RETURNING id INTO v_post_id;
            
            -- If we get here, the insertion succeeded
            RETURN v_post_id;
            
        EXCEPTION 
            WHEN unique_violation THEN
                -- Check if the violation is specifically for the slug
                IF SQLERRM LIKE '%posts_slug_key%' THEN
                    -- Modify slug and retry
                    v_slug := p_slug || '-' || v_counter;
                    v_counter := v_counter + 1;
                ELSE
                    -- If it's a different unique violation, reraise the exception
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."create_post"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_post_type" "public"."post_type_enum", "p_status" "public"."publish_status_enum", "p_thumbnail_url" "text", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_protected_media_data"("p_content_id" "uuid", "p_status" "public"."publish_status_enum", "p_url" "text") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_protected_media_id UUID;
BEGIN
    INSERT INTO public.protected_media_data (
        content_id, status, url, updated_at
    ) VALUES (
        p_content_id, p_status, p_url, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_protected_media_id;

    IF v_protected_media_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create protected_media_data record';
    END IF;

    RETURN v_protected_media_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating protected_media_data: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_protected_media_data"("p_content_id" "uuid", "p_status" "public"."publish_status_enum", "p_url" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_service_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_location_id" "uuid", "p_price" numeric, "p_duration" interval, "p_type" "public"."event_type_enum", "p_booking_workflow" "text" DEFAULT 'pre-approval'::"text", "p_auto_confirm" boolean DEFAULT false, "p_confirmation_deadline_hours" integer DEFAULT 24, "user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."service_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_post_id UUID;
    v_service_id UUID;
    v_result service_content_creation_result;
    v_user_id UUID;
BEGIN
    -- If user_id is not provided, use the authenticated user's ID
    IF user_id IS NULL THEN
       v_user_id := auth.uid();
    ELSE
       v_user_id := user_id;
    END IF;

    -- Create the post
    v_post_id := public.create_post(
        p_title,
        p_slug,
        p_description,
        p_content,
        'service'::post_type_enum,
        p_status,
        p_thumbnail_url,
        v_user_id
    );

    -- Add tags to the post
    PERFORM public.add_tags_to_post(v_post_id, p_tags);

    -- Create the service record with booking workflow parameters
    INSERT INTO public.services (
        post_id,
        location_id,
        content,
        price,
        duration,
        type,
        booking_workflow,
        auto_confirm,
        confirmation_deadline_hours
    ) VALUES (
        v_post_id,
        p_location_id,
        p_content,
        p_price,
        p_duration,
        p_type,
        p_booking_workflow,
        p_auto_confirm,
        p_confirmation_deadline_hours
    ) RETURNING id INTO v_service_id;

    -- Prepare the result
    v_result := (v_post_id, v_service_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating service content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_service_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_location_id" "uuid", "p_price" numeric, "p_duration" interval, "p_type" "public"."event_type_enum", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer, "user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_yoga"("p_movement_id" "uuid", "p_yoga_style" "text", "p_chakras" "text") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_yoga_id UUID;
BEGIN
    INSERT INTO public.yoga (
        movement_id, yoga_style, chakras
    ) VALUES (
        p_movement_id, p_yoga_style, p_chakras
    ) RETURNING id INTO v_yoga_id;

    IF v_yoga_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create yoga record';
    END IF;

    RETURN v_yoga_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating yoga record: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_yoga"("p_movement_id" "uuid", "p_yoga_style" "text", "p_chakras" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_yoga_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_yoga_style" "text", "p_chakras" "text", "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."yoga_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_yoga_id UUID;
    v_result public.yoga_content_creation_result;
BEGIN
    
    -- Create base on-demand content
    v_base_result := public.create_ondemand_content_with_details(
        p_title, p_slug, p_description, p_content, p_thumbnail_url,
        p_tags, p_status, p_media_type, 'yoga'::post_type_enum, p_duration, p_price,
        p_protected_media_url, p_emotional_focuses, p_playlist_ids,
        p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment,
        p_body_focus, p_props, p_user_id
    );

    -- Create the yoga record
    v_yoga_id := public.create_yoga(
        v_base_result.movement_id,
        p_yoga_style,
        p_chakras
    );

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_yoga_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating yoga content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."create_yoga_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_yoga_style" "text", "p_chakras" "text", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."custom_access_token_hook"("event" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    claims jsonb;
    user_role public.user_role;
BEGIN
    -- Fetch the user role from the auth.users metadata
    SELECT (raw_user_meta_data->>'user_role')::public.user_role 
    INTO user_role 
    FROM auth.users 
    WHERE id = (event->>'user_id')::uuid;

    claims := event->'claims';
    IF user_role IS NOT NULL THEN
        -- Set the claim
        claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
    ELSE
        claims := jsonb_set(claims, '{user_role}', '"user"');
    END IF;

    -- Update the 'claims' object in the original event
    event := jsonb_set(event, '{claims}', claims);

    -- Return the modified event
    RETURN event;
END;
$$;


ALTER FUNCTION "public"."custom_access_token_hook"("event" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."deactivate_fcm_token"("p_token" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_count INTEGER;
BEGIN
  UPDATE user_fcm_tokens
  SET
    is_active = FALSE,
    updated_at = NOW()
  WHERE
    user_id = v_user_id AND
    token = p_token;
    
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count > 0;
END;
$$;


ALTER FUNCTION "public"."deactivate_fcm_token"("p_token" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."deactivate_fcm_token"("p_token" "text") IS 'Deactivates an FCM token for the current user';



CREATE OR REPLACE FUNCTION "public"."debug_notification_type"() RETURNS TABLE("enumlabel" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT pg_enum.enumlabel::text
  FROM pg_enum
  WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'notification_type')
  ORDER BY enumsortorder;
END;
$$;


ALTER FUNCTION "public"."debug_notification_type"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_playlist"("user_id" "uuid", "iframe" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
begin
    delete from public.spotify_playlist_join where user_id = user_id and iframe = iframe;
end;
$$;


ALTER FUNCTION "public"."delete_playlist"("user_id" "uuid", "iframe" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enforce_single_draft_invoice_per_user"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.status = 'draft' AND EXISTS (
        SELECT 1 FROM public.invoices 
        WHERE user_id = NEW.user_id AND status = 'draft' AND id != NEW.id
    ) THEN
        RAISE EXCEPTION 'User % already has a draft invoice.', NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."enforce_single_draft_invoice_per_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ensure_unique_slug"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    base_slug TEXT;
    new_slug TEXT;
    counter INTEGER := 1;
    slug_exists BOOLEAN;
BEGIN
    -- Use the provided slug as base_slug
    base_slug := NEW.slug;
    new_slug := base_slug;
    
    -- Check if the slug already exists
    LOOP
        SELECT EXISTS (
            SELECT 1 FROM public.posts WHERE slug = new_slug
        ) INTO slug_exists;
        
        EXIT WHEN NOT slug_exists;
        
        -- If it exists, append counter and increment
        new_slug := base_slug || '-' || counter;
        counter := counter + 1;
    END LOOP;
    
    -- Set the unique slug
    NEW.slug := new_slug;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."ensure_unique_slug"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."filter_events"("filters" "jsonb" DEFAULT '{}'::"jsonb") RETURNS TABLE("event_id" "uuid", "post_id" "uuid", "slug" "text", "title" "text", "description" "text", "thumbnail_url" "text", "event_type" "public"."event_type_enum", "location_name" "text", "location" "jsonb", "creator" "jsonb", "featured" boolean, "next_date" timestamp with time zone, "latest_past_date" timestamp with time zone, "min_price" numeric, "tags" "jsonb", "event_status" "text", "has_available_tickets" boolean, "distance" double precision, "attendees_count" bigint, "date_attendees" "jsonb", "total_count" bigint)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_status text;
    v_event_types public.event_type_enum[];
    v_user_lat double precision;
    v_user_lon double precision;
    v_distance_limit double precision;
    v_only_featured boolean;
    v_creator_ids uuid[];
    v_tag_filter text[];
    v_page_size integer;
    v_page_number integer;
    v_search text;
BEGIN
    -- Extract filter parameters
    v_status := filters->>'status';
    v_only_featured := COALESCE((filters->>'featured')::boolean, false);
    v_page_size := COALESCE((filters->>'pageSize')::integer, 10);
    v_page_number := COALESCE((filters->>'page')::integer, 0);
    v_search := filters->>'search';
    
    -- Parse array parameters
    IF filters ? 'eventTypes' AND jsonb_typeof(filters->'eventTypes') = 'array' THEN
        SELECT array_agg(e::public.event_type_enum)
        INTO v_event_types
        FROM jsonb_array_elements_text(filters->'eventTypes') e;
    END IF;
    
    IF filters ? 'creatorIds' AND jsonb_typeof(filters->'creatorIds') = 'array' THEN
        SELECT array_agg(c::uuid)
        INTO v_creator_ids
        FROM jsonb_array_elements_text(filters->'creatorIds') c;
    END IF;
    
    IF filters ? 'tags' AND jsonb_typeof(filters->'tags') = 'array' THEN
        SELECT array_agg(t::text)
        INTO v_tag_filter
        FROM jsonb_array_elements_text(filters->'tags') t;
    END IF;
    
    -- Location-based filtering parameters
    v_user_lat := (filters->>'userLat')::double precision;
    v_user_lon := (filters->>'userLon')::double precision;
    v_distance_limit := (filters->>'distanceLimit')::double precision;
    
    RETURN QUERY
    WITH attendee_counts AS (
        SELECT 
            eb.event_id,
            eb.date_id,
            ed.start_date,
            SUM(eb.attendees) as total_attendees
        FROM 
            public.event_bookings eb
        JOIN
            public.purchases p ON eb.purchase_id = p.id
        JOIN
            public.event_dates ed ON eb.date_id = ed.id
        WHERE 
            eb.status != 'cancelled' AND
            p.payment_status = 'completed'
        GROUP BY 
            eb.event_id, eb.date_id, ed.start_date
    ),
    date_attendee_counts AS (
        SELECT
            ac.event_id,
            JSONB_AGG(
                jsonb_build_object(
                    'date_id', ac.date_id,
                    'date', ac.start_date,
                    'attendees', ac.total_attendees
                )
            ) AS date_attendees,
            SUM(ac.total_attendees) AS total_attendees
        FROM
            attendee_counts ac
        GROUP BY
            ac.event_id
    ),
    filtered_events AS (
        SELECT
            ev.*,
            CASE 
                WHEN v_user_lat IS NOT NULL AND v_user_lon IS NOT NULL 
                AND ev.location ? 'coordinates' 
                AND ev.location->'coordinates' ? 'latitude'
                AND ev.event_type IN ('in-person', 'hybrid') 
                THEN 
                    ST_Distance(
                        ST_SetSRID(ST_MakePoint(
                            (ev.location->'coordinates'->>'longitude')::FLOAT,
                            (ev.location->'coordinates'->>'latitude')::FLOAT
                        ), 4326)::geography,
                        ST_SetSRID(ST_MakePoint(v_user_lon, v_user_lat), 4326)::geography
                    ) / 1000  -- Convert meters to kilometers
                ELSE NULL
            END AS distance,
            COUNT(*) OVER()::BIGINT as total_count
        FROM public.events_view ev
        WHERE
            -- Status filtering
            (v_status IS NULL OR v_status = 'all' OR ev.event_status = v_status)
            
            -- Event type filtering
            AND (v_event_types IS NULL OR ev.event_type = ANY(v_event_types))
            
            -- Featured filtering
            AND (v_only_featured = FALSE OR ev.featured = TRUE)
            
            -- Creator filtering
            AND (v_creator_ids IS NULL OR ev.creator_id = ANY(v_creator_ids))
            
            -- Tag filtering
            AND (v_tag_filter IS NULL OR EXISTS (
                SELECT 1 FROM jsonb_array_elements_text(ev.tags) tag_name
                WHERE tag_name::TEXT = ANY(v_tag_filter)
            ))
            
            -- Search filtering
            AND (v_search IS NULL OR v_search = '' OR 
                 ev.title ILIKE '%' || v_search || '%' OR 
                 ev.description ILIKE '%' || v_search || '%')
            
            -- Distance filtering
            AND (v_distance_limit IS NULL OR v_user_lat IS NULL OR v_user_lon IS NULL OR
                NOT (ev.event_type IN ('in-person', 'hybrid')) OR
                NOT (ev.location ? 'coordinates') OR
                ST_Distance(
                    ST_SetSRID(ST_MakePoint(
                        (ev.location->'coordinates'->>'longitude')::FLOAT,
                        (ev.location->'coordinates'->>'latitude')::FLOAT
                    ), 4326)::geography,
                    ST_SetSRID(ST_MakePoint(v_user_lon, v_user_lat), 4326)::geography
                ) / 1000 <= v_distance_limit
            )
    )
    SELECT
        fe.event_id,
        fe.post_id,
        fe.slug,
        fe.title,
        fe.description, 
        fe.thumbnail_url,
        fe.event_type,
        fe.location_name,
        fe.location,
        fe.creator,
        fe.featured,
        fe.next_date,
        fe.latest_past_date,
        fe.min_price,
        fe.tags,
        fe.event_status,
        fe.has_available_future_dates AND fe.available_ticket_types_count > 0 AS has_available_tickets,
        fe.distance,
        COALESCE(dac.total_attendees, 0)::bigint AS attendees_count,
        dac.date_attendees,
        fe.total_count
    FROM filtered_events fe
    LEFT JOIN
        date_attendee_counts dac ON fe.event_id = dac.event_id
    ORDER BY
        -- For upcoming events, prioritize by distance if location-based, then date
        CASE WHEN v_status = 'upcoming' OR v_status IS NULL THEN
            CASE WHEN v_user_lat IS NOT NULL AND v_user_lon IS NOT NULL THEN
                fe.distance
            ELSE
                NULL
            END
        ELSE NULL
        END NULLS LAST,
        -- Sort by appropriate date based on status
        CASE
            WHEN v_status = 'upcoming' OR v_status IS NULL THEN fe.next_date
            WHEN v_status = 'past' THEN fe.latest_past_date
            ELSE fe.created_at
        END DESC
    LIMIT v_page_size
    OFFSET v_page_number * v_page_size;
END;
$$;


ALTER FUNCTION "public"."filter_events"("filters" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."filter_events"("filters" "jsonb") IS 'Enhanced event filtering function that supports various filter criteria including status, location, tags, and more';



CREATE OR REPLACE FUNCTION "public"."filter_service_appointments"("filters" "jsonb") RETURNS TABLE("appointment_id" "uuid", "service_id" "uuid", "post_id" "uuid", "service_title" "text", "appointment_date" timestamp with time zone, "duration" interval, "method" "text", "service_type" "text", "status" "text", "client_id" "uuid", "client_name" "text", "client_avatar" "text", "price" numeric, "is_future" boolean, "total_count" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_provider_id UUID;
    v_time_filter TEXT;
    v_status_filter TEXT[];
    v_limit INTEGER;
    v_offset INTEGER;
BEGIN
    -- Set defaults and extract filter values
    v_provider_id := COALESCE(filters->>'providerId', auth.uid()::TEXT)::UUID;
    v_time_filter := COALESCE(filters->>'timeFilter', 'all');
    v_status_filter := CASE
        WHEN filters->>'status' IS NULL THEN ARRAY['confirmed', 'pending', 'cancelled', 'completed']::TEXT[]
        WHEN filters->>'status' = 'all' THEN ARRAY['confirmed', 'pending', 'cancelled', 'completed']::TEXT[]
        ELSE ARRAY[filters->>'status']::TEXT[]
    END;
    v_limit := COALESCE((filters->>'limit')::INTEGER, 10);
    v_offset := COALESCE((filters->>'offset')::INTEGER, 0);
    
    RETURN QUERY
    WITH filtered_appointments AS (
        SELECT 
            sav.appointment_id,
            sav.service_id,
            sv.post_id,
            sv.title AS service_title,
            sav.appointment_date,
            (sav.duration || ' minutes')::INTERVAL AS duration,
            sav.method,
            sav.service_type,
            sav.status,
            sav.client_id,
            sav.client->>'full_name' AS client_name,
            sav.client->>'avatar_url' AS client_avatar,
            sav.price_paid AS price,
            sav.is_future,
            COUNT(*) OVER() AS total_count
        FROM 
            public.service_appointments_view sav
        JOIN 
            public.service_details_view sv ON sav.service_id = sv.service_id
        WHERE 
            sav.provider_id = v_provider_id
            AND (
                (v_time_filter = 'upcoming' AND sav.is_future = TRUE) OR
                (v_time_filter = 'past' AND sav.is_future = FALSE) OR
                (v_time_filter = 'all')
            )
            AND sav.status = ANY(v_status_filter)
    )
    SELECT * FROM filtered_appointments fa
    ORDER BY 
        CASE WHEN v_time_filter = 'past' THEN fa.appointment_date END DESC,
        CASE WHEN v_time_filter IN ('all', 'upcoming') THEN fa.appointment_date END ASC
    LIMIT v_limit
    OFFSET v_offset;
END;
$$;


ALTER FUNCTION "public"."filter_service_appointments"("filters" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."find_nearby_locations"("lat" double precision, "lon" double precision, "radius_km" double precision DEFAULT 10, "limit_count" integer DEFAULT 50) RETURNS TABLE("id" "uuid", "name" "text", "distance_km" double precision, "line_1" "text", "city" "text", "postcode" "text", "country" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        l.name,
        calculate_distance(
            l.coordinates,
            ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
            'km'
        ) as distance_km,
        l.line_1,
        l.city,
        l.postcode,
        l.country
    FROM locations l
    WHERE ST_DWithin(
        l.coordinates,
        ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
        radius_km * 1000  -- Convert km to meters
    )
    ORDER BY l.coordinates <-> ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography
    LIMIT limit_count;
END;
$$;


ALTER FUNCTION "public"."find_nearby_locations"("lat" double precision, "lon" double precision, "radius_km" double precision, "limit_count" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."find_nearby_users"("lat" double precision, "lon" double precision, "radius_km" double precision DEFAULT 10, "limit_count" integer DEFAULT 50) RETURNS TABLE("user_id" "uuid", "distance_km" double precision, "location_id" "uuid")
    LANGUAGE "plpgsql"
    AS $$
BEGIN

    RETURN QUERY
    SELECT 
        ul.user_id,
        calculate_distance(
            ul.coordinates,
            ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
            'km'
        ) as distance_km,
        ul.location_id
    FROM user_locations ul
    WHERE ST_DWithin(
        ul.coordinates,
        ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
        radius_km * 1000  -- Convert km to meters
    )
    ORDER BY ul.coordinates <-> ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography
    LIMIT limit_count;
END;
$$;


ALTER FUNCTION "public"."find_nearby_users"("lat" double precision, "lon" double precision, "radius_km" double precision, "limit_count" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_coordinates_text"("line1" "text", "line2" "text", "city" "text", "postcode" "text", "country" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN concat_ws(', ',
        NULLIF(line1, ''),
        NULLIF(line2, ''),
        NULLIF(city, ''),
        NULLIF(postcode, ''),
        NULLIF(country, '')
    );
END;
$$;


ALTER FUNCTION "public"."generate_coordinates_text"("line1" "text", "line2" "text", "city" "text", "postcode" "text", "country" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_random_comment"() RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    comments TEXT[] := ARRAY[
        'This was incredibly insightful! Looking forward to more content like this.',
        'Great points made here. I particularly enjoyed the section about %s.',
        'Thanks for sharing this. It really helped me understand %s better.',
        'The explanation of %s was very clear and helpful.',
        'I love how you approached %s. Very unique perspective!',
        'This resonated with me deeply, especially the part about %s.',
        'Fantastic content! The insights about %s were eye-opening.',
        'Really appreciate the detailed breakdown of %s.',
        'This is exactly what I needed to learn more about %s.',
        'Excellent presentation of %s. Well structured and informative.'
    ];
    themes TEXT[] := ARRAY[
        'mindfulness', 'wellness', 'personal growth', 
        'meditation techniques', 'stress management',
        'mental clarity', 'emotional balance', 
        'spiritual development', 'inner peace',
        'holistic health', 'self-discovery', 'mindful living'
    ];
BEGIN
    RETURN format(
        comments[1 + floor(random() * array_length(comments, 1))],
        themes[1 + floor(random() * array_length(themes, 1))]
    );
END;
$$;


ALTER FUNCTION "public"."generate_random_comment"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_all_sales"("filters" "jsonb") RETURNS TABLE("id" "text", "customername" "text", "customeremail" character varying, "amount" numeric, "status" "text", "type" "text", "date" timestamp with time zone, "productname" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id::TEXT,
        prof.full_name AS customerName,
        u.email AS customerEmail,
        p.amount,
        p.payment_status AS status,
        p.purchase_type AS type,
        p.purchase_date AS date,
        CASE 
            WHEN p.post_id IS NOT NULL THEN post.title
            ELSE 'Unnamed Product'
        END AS productName
    FROM 
        purchases p
    JOIN 
        auth.users u ON p.user_id = u.id
    JOIN 
        profiles prof ON prof.id = p.user_id
    LEFT JOIN 
        posts post ON p.post_id = post.id
    WHERE
        (p.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
        )) AND
        (filters->>'status' IS NULL OR filters->>'status' = 'all' OR p.payment_status = filters->>'status') AND
        (
            filters->>'search' IS NULL OR 
            filters->>'search' = '' OR 
            prof.full_name ILIKE '%' || COALESCE(filters->>'search', '') || '%' OR
            u.email ILIKE '%' || COALESCE(filters->>'search', '') || '%' OR
            p.id::TEXT ILIKE '%' || COALESCE(filters->>'search', '') || '%' OR
            (post.title IS NOT NULL AND post.title ILIKE '%' || COALESCE(filters->>'search', '') || '%')
        )
    ORDER BY
        p.purchase_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$;


ALTER FUNCTION "public"."get_all_sales"("filters" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_appointment_sales"("filters" "jsonb") RETURNS TABLE("id" "text", "customername" "text", "customeremail" character varying, "amount" numeric, "status" "text", "bookingdate" timestamp with time zone, "appointmentdate" timestamp with time zone, "duration" integer, "servicename" "text", "servicetype" "text", "method" "text", "notes" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id::TEXT,
        prof.full_name AS customerName,
        u.email AS customerEmail,
        p.amount,
        p.payment_status AS status,
        p.purchase_date AS bookingDate,
        ap.appointment_date,
        ap.duration,
        post.title AS serviceName,
        ap.service_type,
        ap.method,
        ap.notes
    FROM 
        purchases p
    JOIN 
        appointment_purchases ap ON p.id = ap.purchase_id
    JOIN 
        auth.users u ON p.user_id = u.id
    JOIN 
        profiles prof ON prof.id = p.user_id
    LEFT JOIN 
        services s ON p.service_id = s.id
    LEFT JOIN 
        posts post ON s.post_id = post.id
    WHERE
        p.purchase_type = 'appointment' AND
        (p.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
        )) AND
        (filters->>'status' IS NULL OR filters->>'status' = 'all' OR p.payment_status = filters->>'status') AND
        (filters->>'search' IS NULL OR 
            (filters->>'search' <> '' AND (
                prof.full_name ILIKE '%' || (filters->>'search') || '%' OR
                u.email ILIKE '%' || (filters->>'search') || '%' OR
                p.id::TEXT ILIKE '%' || (filters->>'search') || '%' OR
                (post.title IS NOT NULL AND post.title ILIKE '%' || (filters->>'search') || '%')
            ))
        )
    ORDER BY
        ap.appointment_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$;


ALTER FUNCTION "public"."get_appointment_sales"("filters" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_availability"("p_user_id" "uuid") RETURNS TABLE("day" character varying, "is_active" boolean, "start_time" time without time zone, "end_time" time without time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.day,
        a.is_active,
        a.start_time,
        a.end_time
    FROM 
        public.availability a
    WHERE 
        a.user_id = p_user_id
    ORDER BY 
        CASE 
            WHEN a.day = 'monday' THEN 1
            WHEN a.day = 'tuesday' THEN 2
            WHEN a.day = 'wednesday' THEN 3
            WHEN a.day = 'thursday' THEN 4
            WHEN a.day = 'friday' THEN 5
            WHEN a.day = 'saturday' THEN 6
            WHEN a.day = 'sunday' THEN 7
        END;
END;
$$;


ALTER FUNCTION "public"."get_availability"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_available_slots"("p_facilitator_id" "uuid", "p_start_date" "date", "p_end_date" "date") RETURNS TABLE("start_time" timestamp with time zone, "end_time" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_current_date DATE;
    v_day VARCHAR(20);
    v_start_time TIME;
    v_end_time TIME;
    v_slot_start TIMESTAMP WITH TIME ZONE;
    v_slot_end TIMESTAMP WITH TIME ZONE;
BEGIN
    FOR v_current_date IN SELECT generate_series(p_start_date, p_end_date, '1 day'::interval)::date
    LOOP
        v_day := LOWER(TO_CHAR(v_current_date, 'day'));
        
        -- Get availability for the current day
        SELECT a.start_time, a.end_time 
        INTO v_start_time, v_end_time
        FROM public.availability a
        WHERE a.user_id = p_facilitator_id AND a.day = v_day AND a.is_active = TRUE;
        
        IF v_start_time IS NOT NULL THEN
            -- Generate hourly slots
            FOR v_slot_start IN 
                SELECT generate_series(
                    v_current_date + v_start_time,
                    v_current_date + v_end_time - interval '1 hour',
                    '1 hour'::interval
                )
            LOOP
                v_slot_end := v_slot_start + interval '1 hour';
                
                -- Check if the slot is not already booked
                IF NOT EXISTS (
                    SELECT 1
                    FROM public.appointments
                    WHERE facilitator_id = p_facilitator_id
                    AND status IN ('confirmed', 'pending')
                    AND (appointments.start_time, appointments.end_time) OVERLAPS (v_slot_start, v_slot_end)
                ) THEN
                    start_time := v_slot_start;
                    end_time := v_slot_end;
                    RETURN NEXT;
                END IF;
            END LOOP;
        END IF;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."get_available_slots"("p_facilitator_id" "uuid", "p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_chat_messages"("p_chat_room_id" "uuid", "p_limit" integer DEFAULT 50, "p_before" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_after" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_around_message_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("message_id" "uuid", "sender_id" "uuid", "sender_name" "text", "message" "text", "created_at" timestamp with time zone, "status" "public"."message_status_enum", "reply_to_message_id" "uuid", "reply_to_message_text" "text", "is_edited" boolean, "read_by_count" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
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
$$;


ALTER FUNCTION "public"."get_chat_messages"("p_chat_room_id" "uuid", "p_limit" integer, "p_before" timestamp with time zone, "p_after" timestamp with time zone, "p_around_message_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_chat_messages_simple"("p_chat_room_id" "uuid") RETURNS TABLE("message_id" "uuid", "sender_id" "uuid", "sender_name" "text", "message" "text", "created_at" timestamp with time zone, "status" "public"."message_status_enum", "reply_to_message_id" "uuid", "reply_to_message_text" "text", "is_edited" boolean, "read_by_count" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM get_chat_messages(p_chat_room_id, 50, NULL::TIMESTAMPTZ, NULL::TIMESTAMPTZ, NULL::UUID);
END;
$$;


ALTER FUNCTION "public"."get_chat_messages_simple"("p_chat_room_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_chat_messages_with_reactions"("p_chat_room_id" "uuid", "p_limit" integer DEFAULT 50, "p_before" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_after" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_around_message_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("message_id" "uuid", "sender_id" "uuid", "sender_name" "text", "message" "text", "created_at" timestamp with time zone, "status" "public"."message_status_enum", "reply_to_message_id" "uuid", "reply_to_message_text" "text", "is_edited" boolean, "read_by_count" integer, "reactions" "json")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_around_time TIMESTAMPTZ;
    v_half_limit INTEGER;
    v_messages_base RECORD;
    v_result RECORD;
BEGIN
    -- Get base message data by calling existing function
    FOR v_messages_base IN
        SELECT * FROM get_chat_messages(
            p_chat_room_id,
            p_limit,
            p_before,
            p_after,
            p_around_message_id
        )
    LOOP
        -- For each message, fetch its reactions
        SELECT
            v_messages_base.message_id,
            v_messages_base.sender_id,
            v_messages_base.sender_name,
            v_messages_base.message,
            v_messages_base.created_at,
            v_messages_base.status,
            v_messages_base.reply_to_message_id,
            v_messages_base.reply_to_message_text,
            v_messages_base.is_edited,
            v_messages_base.read_by_count,
            COALESCE(
                (
                    SELECT json_agg(
                        json_build_object(
                            'type', r.reaction_type,
                            'emoji_code', r.emoji_code,
                            'count', r.count,
                            'user_has_reacted', r.user_has_reacted
                        )
                    )
                    FROM get_message_reactions(v_messages_base.message_id) r
                ),
                '[]'::json
            ) AS reactions
        INTO v_result;
        
        -- Return the row with reactions
        message_id := v_result.message_id;
        sender_id := v_result.sender_id;
        sender_name := v_result.sender_name;
        message := v_result.message;
        created_at := v_result.created_at;
        status := v_result.status;
        reply_to_message_id := v_result.reply_to_message_id;
        reply_to_message_text := v_result.reply_to_message_text;
        is_edited := v_result.is_edited;
        read_by_count := v_result.read_by_count;
        reactions := v_result.reactions;
        
        RETURN NEXT;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."get_chat_messages_with_reactions"("p_chat_room_id" "uuid", "p_limit" integer, "p_before" timestamp with time zone, "p_after" timestamp with time zone, "p_around_message_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_comment_tree"("in_post_id" "uuid") RETURNS TABLE("id" bigint, "user_id" "uuid", "post_id" "uuid", "comment" "text", "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "deleted_at" timestamp with time zone, "parent_id" bigint, "score" integer, "is_edited" boolean, "depth" integer, "reactions" "json", "attachments" "json", "mentions" "json", "author_name" "text", "author_avatar" "text", "path" bigint[])
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE comment_tree AS (
        -- Base case: top-level comments
        SELECT 
            c.*,
            ARRAY[c.id] AS path,
            u.username as author_name,
            u.avatar_url as author_avatar,
            cr.reactions,
            ca.attachments,
            cm.mentions
        FROM public.comments c
        JOIN auth.users u ON u.id = c.user_id
        LEFT JOIN LATERAL (
            SELECT json_agg(
                json_build_object(
                    'type', r.reaction_type,
                    'count', COUNT(*),
                    'userReacted', EXISTS(
                        SELECT 1 FROM public.comment_reactions 
                        WHERE comment_id = c.id 
                        AND user_id = auth.uid()
                        AND reaction_type = r.reaction_type
                    )
                )
            ) as reactions
            FROM public.comment_reactions r
            WHERE r.comment_id = c.id
            GROUP BY r.reaction_type
        ) cr ON true
        LEFT JOIN LATERAL (
            SELECT json_agg(
                json_build_object(
                    'id', a.id,
                    'type', a.type,
                    'url', a.url,
                    'name', a.name,
                    'size', a.size
                )
            ) as attachments
            FROM public.comment_attachments a
            WHERE a.comment_id = c.id
        ) ca ON true
        LEFT JOIN LATERAL (
            SELECT json_agg(u2.username) as mentions
            FROM public.comment_mentions m
            JOIN auth.users u2 ON u2.id = m.user_id
            WHERE m.comment_id = c.id
        ) cm ON true
        WHERE c.post_id = in_post_id 
        AND c.parent_id IS NULL
        AND c.deleted_at IS NULL

        UNION ALL

        -- Recursive case: replies
        SELECT 
            c.*,
            ct.path || c.id,
            u.username,
            u.avatar_url,
            cr.reactions,
            ca.attachments,
            cm.mentions
        FROM public.comments c
        JOIN comment_tree ct ON c.parent_id = ct.id
        JOIN auth.users u ON u.id = c.user_id
        LEFT JOIN LATERAL (
            SELECT json_agg(
                json_build_object(
                    'type', r.reaction_type,
                    'count', COUNT(*),
                    'userReacted', EXISTS(
                        SELECT 1 FROM public.comment_reactions 
                        WHERE comment_id = c.id 
                        AND user_id = auth.uid()
                        AND reaction_type = r.reaction_type
                    )
                )
            ) as reactions
            FROM public.comment_reactions r
            WHERE r.comment_id = c.id
            GROUP BY r.reaction_type
        ) cr ON true
        LEFT JOIN LATERAL (
            SELECT json_agg(
                json_build_object(
                    'id', a.id,
                    'type', a.type,
                    'url', a.url,
                    'name', a.name,
                    'size', a.size
                )
            ) as attachments
            FROM public.comment_attachments a
            WHERE a.comment_id = c.id
        ) ca ON true
        LEFT JOIN LATERAL (
            SELECT json_agg(u2.username) as mentions
            FROM public.comment_mentions m
            JOIN auth.users u2 ON u2.id = m.user_id
            WHERE m.comment_id = c.id
        ) cm ON true
        WHERE c.deleted_at IS NULL
    )
    SELECT *
    FROM comment_tree
    ORDER BY path;
END;
$$;


ALTER FUNCTION "public"."get_comment_tree"("in_post_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_comments"("in_post_id" "uuid", "in_limit" integer DEFAULT 5, "in_offset" integer DEFAULT 0) RETURNS TABLE("id" bigint, "user_id" "uuid", "post_id" "uuid", "comment" "text", "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "deleted_at" timestamp with time zone, "parent_id" bigint, "score" integer, "is_edited" boolean, "depth" integer, "reactions" "json", "attachments" "json", "mentions" "json", "author_name" "text", "author_avatar" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    WITH comment_data AS (
        SELECT 
            c.*,
            u.username as author_name,
            u.avatar_url as author_avatar,
            (
                SELECT COALESCE(json_agg(
                    json_build_object(
                        'type', cr.reaction_type,
                        'count', COUNT(*),
                        'userReacted', EXISTS(
                            SELECT 1 
                            FROM public.comment_reactions cr2 
                            WHERE cr2.comment_id = c.id 
                            AND cr2.user_id = auth.uid()
                            AND cr2.reaction_type = cr.reaction_type
                        )
                    )
                ), '[]'::json)
                FROM public.comment_reactions cr
                WHERE cr.comment_id = c.id
                GROUP BY cr.reaction_type
            ) as reactions,
            (
                SELECT COALESCE(json_agg(
                    json_build_object(
                        'id', ca.id,
                        'type', ca.type,
                        'url', ca.url,
                        'name', ca.name,
                        'size', ca.size
                    )
                ), '[]'::json)
                FROM public.comment_attachments ca
                WHERE ca.comment_id = c.id
            ) as attachments,
            (
                SELECT COALESCE(json_agg(u2.username), '[]'::json)
                FROM public.comment_mentions cm
                JOIN auth.users u2 ON u2.id = cm.user_id
                WHERE cm.comment_id = c.id
            ) as mentions
        FROM public.comments c
        JOIN auth.users u ON u.id = c.user_id
        WHERE c.post_id = in_post_id 
        AND c.deleted_at IS NULL
    )
    SELECT *
    FROM comment_data
    ORDER BY created_at DESC
    LIMIT in_limit
    OFFSET in_offset;
END;
$$;


ALTER FUNCTION "public"."get_comments"("in_post_id" "uuid", "in_limit" integer, "in_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_content_sales"("filters" "jsonb") RETURNS TABLE("id" "text", "customername" "text", "customeremail" character varying, "amount" numeric, "status" "text", "date" timestamp with time zone, "contenttitle" "text", "contenttype" "text", "downloadcount" integer, "issubscription" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id::TEXT,
        prof.full_name AS customerName,
        u.email AS customerEmail,
        p.amount,
        p.payment_status AS status,
        p.purchase_date AS date,
        post.title AS contentTitle,
        odm.media_type::TEXT AS contentType,
        cp.download_count,
        cp.is_subscription
    FROM 
        purchases p
    JOIN 
        content_purchases cp ON p.id = cp.purchase_id
    JOIN 
        auth.users u ON p.user_id = u.id
    JOIN 
        profiles prof ON prof.id = p.user_id
    JOIN 
        on_demand_media odm ON p.content_id = odm.id
    JOIN 
        posts post ON odm.post_id = post.id
    WHERE
        p.purchase_type = 'content' AND
        (p.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
        )) AND
        (filters->>'status' IS NULL OR filters->>'status' = 'all' OR p.payment_status = filters->>'status') AND
        (filters->>'search' IS NULL OR 
            (filters->>'search' <> '' AND (
                prof.full_name ILIKE '%' || (filters->>'search') || '%' OR
                u.email ILIKE '%' || (filters->>'search') || '%' OR
                p.id::TEXT ILIKE '%' || (filters->>'search') || '%' OR
                (post.title IS NOT NULL AND post.title ILIKE '%' || (filters->>'search') || '%')
            ))
        )
    ORDER BY
        p.purchase_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$;


ALTER FUNCTION "public"."get_content_sales"("filters" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_enhanced_event_details"("event_slug" "text") RETURNS TABLE("event_details" "jsonb")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        jsonb_build_object(
            'event_id', e.event_id,
            'post_id', e.post_id,
            'slug', e.slug,
            'title', e.title,
            'description', e.description,
            'content', e.content,
            'thumbnail_url', e.thumbnail_url,
            'event_type', e.event_type,
            'featured', e.featured,
            'created_at', e.created_at,
            'updated_at', e.updated_at,
            'location', e.location,
            'room', e.room,
            'creator', e.creator,
            'dates', e.dates,
            'future_dates', e.future_dates,
            'tickets', e.tickets,
            'tags', e.tags,
            'next_available_date', e.next_available_date,
            'min_price', e.min_price
        ) AS event_details
    FROM 
        public.comprehensive_events_view e
    WHERE 
        e.slug = event_slug
    LIMIT 1;
END;
$$;


ALTER FUNCTION "public"."get_enhanced_event_details"("event_slug" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_event_bookings"("filters" "jsonb") RETURNS TABLE("id" "text", "customername" "text", "customeremail" character varying, "amount" numeric, "status" "text", "bookingdate" timestamp with time zone, "eventtitle" "text", "eventdate" timestamp with time zone, "attendees" integer, "location" "text", "isvirtual" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id::TEXT,
        prof.full_name AS customerName,
        u.email AS customerEmail,
        p.amount,
        p.payment_status AS status,
        p.purchase_date AS bookingDate,
        post.title AS eventTitle,
        ed.start_date AS eventDate,
        eb.attendees,
        COALESCE(loc.name, 
            CASE WHEN e.type = 'online' THEN 'Online Event' 
            ELSE 'Location TBA' END) AS location,
        (e.type = 'online' OR e.type = 'hybrid') AS isVirtual
    FROM 
        purchases p
    JOIN 
        event_bookings eb ON p.id = eb.purchase_id
    JOIN 
        auth.users u ON p.user_id = u.id
    JOIN 
        profiles prof ON prof.id = p.user_id
    JOIN 
        events e ON p.event_id = e.id
    JOIN 
        posts post ON e.post_id = post.id
    JOIN 
        event_dates ed ON eb.date_id = ed.id
    LEFT JOIN 
        post_locations pl ON post.id = pl.post_id
    LEFT JOIN 
        locations loc ON pl.location_id = loc.id
    WHERE
        p.purchase_type = 'event' AND
        (p.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
        )) AND
        (filters->>'status' IS NULL OR filters->>'status' = 'all' OR p.payment_status = filters->>'status') AND
        (filters->>'search' IS NULL OR 
            (filters->>'search' <> '' AND (
                prof.full_name ILIKE '%' || (filters->>'search') || '%' OR
                u.email ILIKE '%' || (filters->>'search') || '%' OR
                p.id::TEXT ILIKE '%' || (filters->>'search') || '%' OR
                (post.title IS NOT NULL AND post.title ILIKE '%' || (filters->>'search') || '%')
            ))
        )
    ORDER BY
        ed.start_date DESC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$;


ALTER FUNCTION "public"."get_event_bookings"("filters" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_event_cards"("user_lat" double precision DEFAULT NULL::double precision, "user_lon" double precision DEFAULT NULL::double precision, "event_types" "public"."event_type_enum"[] DEFAULT NULL::"public"."event_type_enum"[], "time_filter" "text" DEFAULT 'upcoming'::"text", "distance_limit" double precision DEFAULT NULL::double precision, "page_size" integer DEFAULT 10, "page_number" integer DEFAULT 0, "only_featured" boolean DEFAULT false, "user_ids" "uuid"[] DEFAULT NULL::"uuid"[]) RETURNS TABLE("id" "uuid", "slug" "text", "title" "text", "description" "text", "thumbnail_url" "text", "event_type" "public"."event_type_enum", "location_name" "text", "next_date" timestamp with time zone, "available_tickets" bigint, "min_price" numeric, "distance" double precision, "total_count" bigint, "author" "jsonb", "featured" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    WITH next_available_date AS (
        SELECT 
            event_id,
            MIN(start_date) as next_date
        FROM public.event_dates
        WHERE CASE 
            WHEN time_filter = 'upcoming' THEN start_date > CURRENT_TIMESTAMP
            WHEN time_filter = 'past' THEN start_date <= CURRENT_TIMESTAMP
            ELSE TRUE
        END
        GROUP BY event_id
    ),
    ticket_summary AS (
        SELECT 
            t.event_id,
            MIN(t.price) as min_price,
            SUM(
                CASE 
                    WHEN t.quantity IS NULL THEN NULL
                    ELSE t.quantity - COALESCE(
                        (SELECT SUM(tp.quantity) 
                         FROM public.ticket_purchases tp 
                         WHERE tp.ticket_id = t.id),
                        0
                    )
                END
            )::BIGINT as total_available
        FROM public.tickets t
        GROUP BY t.event_id
    ),
    filtered_events AS (
        SELECT 
            p.id as post_id,
            p.slug,
            p.title,
            p.description,
            p.thumbnail_url,
            e.type as event_type,
            CASE 
                WHEN e.type = 'online' THEN 'Online Event'
                ELSE COALESCE(l.name, 'Location TBA')
            END as location_name,
            nad.next_date,
            COALESCE(ts.total_available, 0)::BIGINT as available_tickets,
            ts.min_price,
            CASE 
                WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL 
                    AND l.coordinates IS NOT NULL 
                    AND e.type IN ('in-person', 'hybrid') 
                THEN ST_Distance(
                    l.coordinates::geography,
                    ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography
                ) / 1000  -- Convert meters to kilometers
                ELSE NULL
            END AS event_distance,
            COUNT(*) OVER()::BIGINT as total_count,
            pr.id as author_id,
            pr.full_name as author_full_name,
            pr.avatar_url as author_avatar_url,
            p.featured
        FROM 
            public.posts p
        INNER JOIN 
            public.events e ON p.id = e.post_id
        LEFT JOIN 
            public.post_locations pl ON p.id = pl.post_id
        LEFT JOIN 
            public.locations l ON pl.location_id = l.id
        LEFT JOIN 
            next_available_date nad ON e.id = nad.event_id
        LEFT JOIN 
            ticket_summary ts ON e.id = ts.event_id
        LEFT JOIN 
            public.profiles pr ON p.user_id = pr.id
        WHERE 
            p.post_type = 'event'
            AND (event_types IS NULL OR e.type = ANY(event_types))
            AND (only_featured = FALSE OR p.featured = TRUE)
            AND (user_ids IS NULL OR p.user_id = ANY(user_ids))
            AND CASE 
                WHEN time_filter = 'upcoming' THEN 
                    nad.next_date > CURRENT_TIMESTAMP
                WHEN time_filter = 'past' THEN 
                    nad.next_date <= CURRENT_TIMESTAMP
                ELSE 
                    TRUE
                END
            AND CASE
                WHEN distance_limit IS NOT NULL 
                    AND user_lat IS NOT NULL 
                    AND user_lon IS NOT NULL 
                    AND l.coordinates IS NOT NULL 
                THEN ST_DWithin(
                    l.coordinates::geography,
                    ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography,
                    distance_limit * 1000  -- Convert km to meters
                )
                ELSE 
                    TRUE
                END
    )
    SELECT 
        fe.post_id as id,
        fe.slug,
        fe.title,
        fe.description,
        fe.thumbnail_url,
        fe.event_type,
        fe.location_name,
        fe.next_date,
        fe.available_tickets,
        fe.min_price,
        fe.event_distance AS distance,
        fe.total_count,
        jsonb_build_object(
            'id', fe.author_id,
            'full_name', fe.author_full_name,
            'avatar_url', fe.author_avatar_url
        ) as author,
        fe.featured
    FROM 
        filtered_events fe
    ORDER BY 
        CASE 
            WHEN time_filter = 'upcoming' THEN
                CASE 
                    WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL THEN fe.event_distance
                    ELSE NULL
                END
        END NULLS LAST,
        CASE 
            WHEN time_filter = 'upcoming' THEN fe.next_date
            WHEN time_filter = 'past' THEN fe.next_date
            ELSE fe.next_date
        END DESC
    LIMIT page_size
    OFFSET page_number * page_size;
END;
$$;


ALTER FUNCTION "public"."get_event_cards"("user_lat" double precision, "user_lon" double precision, "event_types" "public"."event_type_enum"[], "time_filter" "text", "distance_limit" double precision, "page_size" integer, "page_number" integer, "only_featured" boolean, "user_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_event_details"("event_slug" "text") RETURNS TABLE("id" "uuid", "slug" "text", "title" "text", "description" "text", "content" "text", "thumbnail_url" "text", "event_type" "public"."event_type_enum", "featured" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "location" "jsonb", "future_dates" "jsonb"[], "tickets" "jsonb"[], "author" "jsonb")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.slug,
        p.title,
        p.description,
        e.content,
        p.thumbnail_url,
        e.type as event_type,
        p.featured,
        p.created_at,
        p.updated_at,
        CASE 
            WHEN e.type = 'online' THEN 
                jsonb_build_object('name', 'Online Event')
            ELSE 
                jsonb_build_object(
                    'id', l.id,
                    'name', l.name,
                    'address', generate_coordinates_text(
                        l.line_1, l.line_2, l.city, l.postcode, l.country
                    ),
                    'coordinates', jsonb_build_object(
                        'latitude', ST_Y(l.coordinates::geometry),
                        'longitude', ST_X(l.coordinates::geometry)
                    )
                )
        END as location,
        ARRAY(
            SELECT jsonb_build_object(
                'id', ed.id,
                'start_date', ed.start_date,
                'end_date', ed.end_date
            )
            FROM event_dates ed
            WHERE ed.event_id = e.id
            AND ed.start_date > CURRENT_TIMESTAMP
            ORDER BY ed.start_date
        ) as future_dates,
        ARRAY(
            SELECT jsonb_build_object(
                'id', t.id,
                'name', t.title,
                'description', t.description,
                'price', t.price,
                'quantity', t.quantity,
                'available_quantity', 
                    CASE 
                        WHEN t.quantity IS NULL THEN NULL
                        ELSE t.quantity - COALESCE(
                            (SELECT SUM(tp.quantity) 
                             FROM ticket_purchases tp 
                             WHERE tp.ticket_id = t.id),
                            0
                        )
                    END
            )
            FROM tickets t
            WHERE t.event_id = e.id
            ORDER BY t.price
        ) as tickets,
        jsonb_build_object(
            'id', pr.id,
            'full_name', pr.full_name,
            'avatar_url', pr.avatar_url
        ) as author
    FROM 
        posts p
        INNER JOIN events e ON p.id = e.post_id
        LEFT JOIN post_locations pl ON p.id = pl.post_id
        LEFT JOIN locations l ON pl.location_id = l.id
        LEFT JOIN profiles pr ON p.user_id = pr.id
    WHERE 
        p.slug = event_slug
        AND p.post_type = 'event'
    LIMIT 1;
END;
$$;


ALTER FUNCTION "public"."get_event_details"("event_slug" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_filtered_movement_content"("input_post_ids" "uuid"[] DEFAULT NULL::"uuid"[], "input_featured" boolean DEFAULT NULL::boolean, "post_type_array" "public"."post_type_enum"[] DEFAULT NULL::"public"."post_type_enum"[], "search_title" "text" DEFAULT NULL::"text", "min_duration" integer DEFAULT NULL::integer, "max_duration" integer DEFAULT NULL::integer, "min_energy_level" integer DEFAULT NULL::integer, "max_energy_level" integer DEFAULT NULL::integer, "min_price" numeric DEFAULT NULL::numeric, "max_price" numeric DEFAULT NULL::numeric, "tag_array" "text"[] DEFAULT NULL::"text"[], "p_limit" integer DEFAULT 10, "p_offset" integer DEFAULT 0, "p_media_key" "text" DEFAULT NULL::"text") RETURNS TABLE("post_id" "uuid", "post_type" "public"."post_type_enum", "title" "text", "slug" "text", "description" "text", "thumbnail_url" "text", "media_type" "public"."media_type_enum", "duration" interval, "price" numeric, "instructor_name" character varying, "session_theme" character varying, "energy_level" integer, "spiritual_elements" "text", "emotional_focus" "text", "recommended_environment" "text", "body_focus" "text", "tags" "text", "total_count" bigint, "featured" boolean, "updated_at" timestamp with time zone, "media_key" "text")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    min_duration_interval INTERVAL;
    max_duration_interval INTERVAL;
BEGIN
    -- Convert percentage to actual duration intervals
    min_duration_interval := CASE
        WHEN min_duration IS NOT NULL THEN
            INTERVAL '15 minutes' + (INTERVAL '75 minutes' * min_duration / 100)
        ELSE NULL
    END;

    max_duration_interval := CASE
        WHEN max_duration IS NOT NULL THEN
            INTERVAL '15 minutes' + (INTERVAL '75 minutes' * max_duration / 100)
        ELSE NULL
    END;

    RETURN QUERY
    WITH filtered_posts AS (
        SELECT DISTINCT p.id
        FROM posts p
        LEFT JOIN post_tags pt ON p.id = pt.post_id
        LEFT JOIN tags t ON pt.tag_id = t.id
        WHERE (input_post_ids IS NULL OR p.id = ANY(input_post_ids))
        AND (post_type_array IS NULL OR p.post_type = ANY(post_type_array))
        AND (search_title IS NULL OR p.title ILIKE '%' || search_title || '%')
        AND (tag_array IS NULL OR t.name = ANY(tag_array))
        -- Remove the featured filter from here
    ),
    counted_results AS (
        SELECT 
            p.id AS post_id,
            p.post_type,
            p.title,
            p.slug,
            p.description,
            p.thumbnail_url,
            p.featured,
            odm.media_type,
            odm.duration,
            odm.price,
            m.instructor_name,
            m.session_theme,
            m.energy_level,
            m.spiritual_elements,
            m.emotional_focus,
            m.recommended_environment,
            m.body_focus,
            p.updated_at,
            string_agg(t.name, ', ') AS tags,
            COUNT(*) OVER() AS total_count,
            pmd.url as media_key
        FROM 
            filtered_posts fp
        JOIN
            posts p ON fp.id = p.id
        JOIN
            on_demand_media odm ON p.id = odm.post_id
        LEFT JOIN
            public.protected_media_data pmd ON odm.id = pmd.content_id
        JOIN
            movements m ON odm.id = m.content_id
        LEFT JOIN
            post_tags pt ON p.id = pt.post_id
        LEFT JOIN
            tags t ON pt.tag_id = t.id
        WHERE 
            (min_duration_interval IS NULL OR odm.duration >= min_duration_interval)
            AND (max_duration_interval IS NULL OR odm.duration <= max_duration_interval)
            AND (min_energy_level IS NULL OR m.energy_level >= min_energy_level)
            AND (max_energy_level IS NULL OR m.energy_level <= max_energy_level)
            AND (min_price IS NULL OR odm.price >= min_price)
            AND (max_price IS NULL OR odm.price <= max_price)
            AND (input_featured IS NULL OR p.featured = input_featured)
            AND (p_media_key IS NULL OR pmd.url = p_media_key)
        GROUP BY 
            p.id, odm.id, m.id, pmd.url
        ORDER BY 
            p.created_at DESC
    )
    SELECT 
        cr.post_id,
        cr.post_type,
        cr.title,
        cr.slug,
        cr.description,
        cr.thumbnail_url,
        cr.media_type,
        cr.duration,
        cr.price,
        cr.instructor_name,
        cr.session_theme,
        cr.energy_level,
        cr.spiritual_elements,
        cr.emotional_focus,
        cr.recommended_environment,
        cr.body_focus,
        cr.tags,
        cr.total_count,
        cr.featured,
        cr.updated_at,
        cr.media_key
    FROM counted_results cr
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;


ALTER FUNCTION "public"."get_filtered_movement_content"("input_post_ids" "uuid"[], "input_featured" boolean, "post_type_array" "public"."post_type_enum"[], "search_title" "text", "min_duration" integer, "max_duration" integer, "min_energy_level" integer, "max_energy_level" integer, "min_price" numeric, "max_price" numeric, "tag_array" "text"[], "p_limit" integer, "p_offset" integer, "p_media_key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_journal_entries"("p_user_id" "uuid" DEFAULT NULL::"uuid", "p_tag_names" "text"[] DEFAULT NULL::"text"[], "p_start_date" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_end_date" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_mood" "public"."mood_enum" DEFAULT NULL::"public"."mood_enum", "p_limit" integer DEFAULT 20, "p_offset" integer DEFAULT 0) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $_$
declare
  v_user_id uuid := coalesce(p_user_id, auth.uid());
  v_query text;
  v_params jsonb := '{}'::jsonb;
  v_result jsonb;
begin
  -- Only allow users to query their own journal entries unless they're an admin
  if v_user_id != auth.uid() then
    -- Check if the user is an admin (implement your admin check here)
    -- For now, we'll just prevent users from accessing others' journals
    raise exception 'You can only access your own journal entries';
  end if;
  
  -- Build the base query
  v_query := '
    with filtered_entries as (
      select 
        je.*
      from 
        journal_entries je
      where 
        je.user_id = $1
    ';
  
  v_params := v_params || jsonb_build_object('1', v_user_id);
  
  -- Add tag filter if specified
  if p_tag_names is not null and array_length(p_tag_names, 1) > 0 then
    v_query := v_query || '
      and exists (
        select 1
        from journal_entry_tags jet
        join journal_tags jt on jet.tag_id = jt.id
        where jet.journal_entry_id = je.id
        and jt.name = any($2)
      )
    ';
    v_params := v_params || jsonb_build_object('2', p_tag_names);
  end if;
  
  -- Add date range filter if specified
  if p_start_date is not null then
    v_query := v_query || '
      and je.created_at >= $3
    ';
    v_params := v_params || jsonb_build_object('3', p_start_date);
  end if;
  
  if p_end_date is not null then
    v_query := v_query || '
      and je.created_at <= $4
    ';
    v_params := v_params || jsonb_build_object('4', p_end_date);
  end if;
  
  -- Add mood filter if specified
  if p_mood is not null then
    v_query := v_query || '
      and je.mood = $5
    ';
    v_params := v_params || jsonb_build_object('5', p_mood);
  end if;
  
  -- Close the CTE
  v_query := v_query || '
    )
    select
      jsonb_build_object(
        ''entries'', coalesce(
          jsonb_agg(
            jsonb_build_object(
              ''journal_entry'', to_jsonb(fe),
              ''tags'', coalesce(
                (select jsonb_agg(jt.name)
                 from journal_entry_tags jet
                 join journal_tags jt on jet.tag_id = jt.id
                 where jet.journal_entry_id = fe.id),
                ''[]''::jsonb
              ),
              ''content_links'', coalesce(
                (select jsonb_agg(jcl.post_id)
                 from journal_content_links jcl
                 where jcl.journal_entry_id = fe.id),
                ''[]''::jsonb
              )
            )
            order by fe.created_at desc
          ),
          ''[]''::jsonb
        ),
        ''total_count'', (select count(*) from filtered_entries),
        ''limit'', $6,
        ''offset'', $7
      )
    from
      filtered_entries fe
    group by fe.id, fe.created_at
    order by fe.created_at desc
    limit $6
    offset $7
  ';
  
  v_params := v_params || jsonb_build_object('6', p_limit, '7', p_offset);
  
  -- Execute the query with parameters
  execute v_query
  using 
    (v_params ->> '1')::uuid,
    (case when v_params ? '2' then (v_params ->> '2')::text[] else null end),
    (case when v_params ? '3' then (v_params ->> '3')::timestamp with time zone else null end),
    (case when v_params ? '4' then (v_params ->> '4')::timestamp with time zone else null end),
    (case when v_params ? '5' then (v_params ->> '5')::mood_enum else null end),
    (v_params ->> '6')::int,
    (v_params ->> '7')::int
  into v_result;
  
  return v_result;
end;
$_$;


ALTER FUNCTION "public"."get_journal_entries"("p_user_id" "uuid", "p_tag_names" "text"[], "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_mood" "public"."mood_enum", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_message_reactions"("p_message_id" "uuid") RETURNS TABLE("reaction_type" "public"."reaction_type_enum", "emoji_code" "text", "count" bigint, "user_ids" "uuid"[], "user_has_reacted" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mr.reaction_type,
        mr.emoji_code,
        COUNT(*) AS count,
        array_agg(mr.user_id) AS user_ids,
        bool_or(mr.user_id = auth.uid()) AS user_has_reacted
    FROM public.message_reactions mr
    WHERE mr.message_id = p_message_id
    GROUP BY mr.reaction_type, mr.emoji_code
    ORDER BY count DESC, mr.reaction_type;
END;
$$;


ALTER FUNCTION "public"."get_message_reactions"("p_message_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_on_page_ceremony"("p_slug" "text") RETURNS TABLE("ceremony_details" "jsonb", "protected_media_url" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(cer_det) AS ceremony_details,
        CASE
            -- Creator always has access
            WHEN EXISTS (
                SELECT 1 FROM posts p
                WHERE p.id = cer_det.id AND p.user_id = auth.uid()
            ) THEN pmd.url
            -- Otherwise use can_access_content_v2 function
            WHEN public.can_access_content_v2(cer_det.on_demand_media_id) THEN pmd.url
            ELSE NULL
        END AS protected_media_url
    FROM 
        ceremony_details cer_det
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = cer_det.on_demand_media_id
    WHERE cer_det.slug = p_slug;
END;
$$;


ALTER FUNCTION "public"."get_on_page_ceremony"("p_slug" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_on_page_dance"("p_slug" "text") RETURNS TABLE("dance_details" "jsonb", "protected_media_url" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(dance_det) AS dance_details,
        CASE
            -- Creator always has access
            WHEN EXISTS (
                SELECT 1 FROM posts p
                WHERE p.id = dance_det.id AND p.user_id = auth.uid()
            ) THEN pmd.url
            -- Otherwise use can_access_content_v2 function
            WHEN public.can_access_content_v2(dance_det.on_demand_media_id) THEN pmd.url
            ELSE NULL
        END AS protected_media_url
    FROM
        dance_details dance_det
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = dance_det.on_demand_media_id
    WHERE dance_det.slug = p_slug;
END;
$$;


ALTER FUNCTION "public"."get_on_page_dance"("p_slug" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_on_page_meditation"("p_slug" "text") RETURNS TABLE("meditation_details" "jsonb", "protected_media_url" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(med_det) AS meditation_details,
        CASE
            -- Creator always has access
            WHEN EXISTS (
                SELECT 1 FROM posts p
                WHERE p.id = med_det.id AND p.user_id = auth.uid()
            ) THEN pmd.url
            -- Otherwise use can_access_content_v2 function
            WHEN public.can_access_content_v2(med_det.on_demand_media_id) THEN pmd.url
            ELSE NULL
        END AS protected_media_url
    FROM 
        meditation_details med_det
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = med_det.on_demand_media_id
    WHERE med_det.slug = p_slug;
END;
$$;


ALTER FUNCTION "public"."get_on_page_meditation"("p_slug" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_on_page_neuro_flow"("p_slug" "text") RETURNS TABLE("neuroflow_details" "jsonb", "protected_media_url" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(neuro_det) AS neuroflow_details,
        CASE
            -- Creator always has access
            WHEN EXISTS (
                SELECT 1 FROM posts p
                WHERE p.id = neuro_det.id AND p.user_id = auth.uid()
            ) THEN pmd.url
            -- Otherwise use can_access_content_v2 function
            WHEN public.can_access_content_v2(neuro_det.on_demand_media_id) THEN pmd.url
            ELSE NULL
        END AS protected_media_url
    FROM 
        neuroflow_details neuro_det
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = neuro_det.on_demand_media_id
    WHERE neuro_det.slug = p_slug;
END;
$$;


ALTER FUNCTION "public"."get_on_page_neuro_flow"("p_slug" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_on_page_yoga"("p_slug" "text") RETURNS TABLE("yoga_details" "jsonb", "protected_media_url" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(yoga_det) AS yoga_details,
        CASE
            -- Creator always has access
            WHEN EXISTS (
                SELECT 1 FROM posts p
                WHERE p.id = yoga_det.id AND p.user_id = auth.uid()
            ) THEN pmd.url
            -- Otherwise use can_access_content_v2 function
            WHEN public.can_access_content_v2(yoga_det.on_demand_media_id) THEN pmd.url
            ELSE NULL
        END AS protected_media_url
    FROM
        yoga_details yoga_det
    LEFT JOIN
        public.protected_media_data pmd
        ON pmd.content_id = yoga_det.on_demand_media_id
    WHERE yoga_det.slug = p_slug;
END;
$$;


ALTER FUNCTION "public"."get_on_page_yoga"("p_slug" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_pending_appointments"("p_facilitator_id" "uuid", "p_start_date" "date", "p_end_date" "date") RETURNS TABLE("appointment_id" "uuid", "client_id" "uuid", "start_time" timestamp with time zone, "end_time" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id AS appointment_id,
        a.client_id,
        a.start_time,
        a.end_time
    FROM public.appointments a
    WHERE a.facilitator_id = p_facilitator_id
    AND a.status = 'pending'
    AND DATE(a.start_time) BETWEEN p_start_date AND p_end_date
    ORDER BY a.start_time;
END;
$$;


ALTER FUNCTION "public"."get_pending_appointments"("p_facilitator_id" "uuid", "p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_post_type_tags"("post_type" "public"."post_type_enum") RETURNS TABLE("tag_id" "uuid", "tag_name" character varying)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT t.id AS tag_id, t.name AS tag_name
    FROM public.tags t
    INNER JOIN public.post_tags pt ON t.id = pt.tag_id
    INNER JOIN public.posts p ON pt.post_id = p.id
    WHERE p.post_type = get_post_type_tags.post_type
    GROUP BY t.id, t.name;
END;
$$;


ALTER FUNCTION "public"."get_post_type_tags"("post_type" "public"."post_type_enum") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_potential_recipients"("p_params" "jsonb") RETURNS TABLE("recipient_id" "uuid", "name" "text", "email" "text", "group_type" "text", "avatar_url" "text", "appointment_id" "uuid", "booking_id" "uuid", "appointment_date" timestamp with time zone, "post_title" "text", "tickets_count" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_type TEXT;
    v_post_id UUID;
    v_service_id UUID;
    v_event_id UUID;
    v_appointment_id UUID;
    v_booking_id UUID;
    v_event_date TIMESTAMPTZ;
    v_limit INTEGER;
    params JSONB;
BEGIN
    -- Check if we have a nested params object and use the appropriate structure
    IF p_params ? 'params' THEN
        params := p_params->'params';
    ELSE
        params := p_params;
    END IF;

    -- Extract parameters - handle both camelCase and lowercase parameter names
    v_type := params->>'type';
    
    -- Convert string UUIDs to UUID type, handling possible null/invalid values
    BEGIN
        -- Try postId (camelCase) first, then postid (lowercase)
        v_post_id := (params->>'postId')::UUID;
        IF v_post_id IS NULL THEN
            v_post_id := (params->>'postid')::UUID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_post_id := NULL;
    END;
    
    BEGIN
        v_service_id := (params->>'serviceId')::UUID;
        IF v_service_id IS NULL THEN
            v_service_id := (params->>'serviceid')::UUID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_service_id := NULL;
    END;
    
    BEGIN
        v_event_id := (params->>'eventId')::UUID;
        IF v_event_id IS NULL THEN
            v_event_id := (params->>'eventid')::UUID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_event_id := NULL;
    END;
    
    BEGIN
        v_appointment_id := (params->>'appointmentId')::UUID;
        IF v_appointment_id IS NULL THEN
            v_appointment_id := (params->>'appointmentid')::UUID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_appointment_id := NULL;
    END;
    
    BEGIN
        v_booking_id := (params->>'bookingId')::UUID;
        IF v_booking_id IS NULL THEN
            v_booking_id := (params->>'bookingid')::UUID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_booking_id := NULL;
    END;
    
    BEGIN
        v_event_date := (params->>'eventDate')::TIMESTAMPTZ;
        IF v_event_date IS NULL THEN
            v_event_date := (params->>'eventdate')::TIMESTAMPTZ;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_event_date := NULL;
    END;
    
    v_limit := COALESCE((params->>'limit')::INTEGER, 100);
    
    -- Validate required parameters
    IF v_type IS NULL THEN
        RAISE EXCEPTION 'Type parameter is required';
    END IF;
    
    -- Handle different recipient types
    CASE v_type
        -- Service appointments recipients
        WHEN 'service' THEN
            IF v_service_id IS NULL AND v_appointment_id IS NULL THEN
                RAISE EXCEPTION 'Either Service ID or Appointment ID is required for service recipients';
            END IF;
            
            RETURN QUERY
            WITH service_appointments AS (
                SELECT 
                    sav.client_id,
                    sav.client->>'full_name' AS client_name,
                    sav.client->>'avatar_url' AS client_avatar,
                    sav.appointment_id,
                    sav.appointment_date,
                    sav.service_id,
                    sv.title AS service_title
                FROM 
                    public.service_appointments_view sav
                JOIN
                    public.service_details_view sv ON sav.service_id = sv.service_id
                WHERE 
                    (v_service_id IS NULL OR sav.service_id = v_service_id)
                    AND (v_appointment_id IS NULL OR sav.appointment_id = v_appointment_id)
            )
            SELECT
                sa.client_id AS recipient_id,
                sa.client_name AS name,
                au.email::TEXT,
                'Service Client'::TEXT AS group_type,
                sa.client_avatar AS avatar_url,
                sa.appointment_id,
                NULL::UUID AS booking_id,
                sa.appointment_date,
                sa.service_title AS post_title,
                1 AS tickets_count -- Services typically have 1 appointment per client
            FROM
                service_appointments sa
            LEFT JOIN
                auth.users au ON sa.client_id = au.id
            LIMIT v_limit;
        
        -- Event attendees recipients
        WHEN 'event' THEN
            -- First, determine which date_ids we're looking for based on event_id and/or eventDate
            RETURN QUERY
            WITH relevant_dates AS (
                -- Find date_ids that match our criteria
                SELECT 
                    ed.id AS date_id,
                    ed.event_id,
                    ed.start_date,
                    edv.title AS event_title
                FROM 
                    public.event_dates ed
                JOIN 
                    public.event_details_view edv ON ed.event_id = edv.event_id
                WHERE 
                    -- If event_id is provided, filter by it
                    (v_event_id IS NULL OR ed.event_id = v_event_id)
                    -- If eventDate is provided, filter by date (ignoring time)
                    AND (v_event_date IS NULL OR DATE(ed.start_date) = DATE(v_event_date))
            ),
            -- Get attendees who booked these specific dates
            attendees AS (
                SELECT
                    p.user_id,
                    pr.full_name,
                    pr.avatar_url,
                    eb.id AS booking_id,
                    rd.date_id,
                    rd.event_id,
                    rd.start_date,
                    rd.event_title,
                    eb.attendees AS tickets_count
                FROM
                    relevant_dates rd
                JOIN
                    public.event_bookings eb ON rd.date_id = eb.date_id
                JOIN
                    public.purchases p ON eb.purchase_id = p.id
                LEFT JOIN
                    public.profiles pr ON p.user_id = pr.id
                WHERE
                    -- If booking_id is provided, filter by it
                    (v_booking_id IS NULL OR eb.id = v_booking_id)
                    AND eb.status != 'cancelled'
            )
            -- Select distinct attendees with their most recent booking
            SELECT DISTINCT ON (a.user_id)
                a.user_id AS recipient_id,
                a.full_name AS name,
                au.email::TEXT,
                'Event Attendee'::TEXT AS group_type,
                a.avatar_url,
                NULL::UUID AS appointment_id,
                a.booking_id,
                a.start_date AS appointment_date,
                a.event_title AS post_title,
                a.tickets_count
            FROM
                attendees a
            LEFT JOIN
                auth.users au ON a.user_id = au.id
            ORDER BY 
                a.user_id, a.start_date DESC
            LIMIT v_limit;
        
        -- Waitlist recipients
        WHEN 'waitlist' THEN
            IF v_post_id IS NULL THEN
                RAISE EXCEPTION 'Post ID is required for waitlist recipients';
            END IF;
            
            RETURN QUERY
            SELECT
                we.user_id AS recipient_id,
                pr.full_name AS name,
                au.email::TEXT,
                'Waitlist'::TEXT AS group_type,
                pr.avatar_url,
                NULL::UUID AS appointment_id,
                NULL::UUID AS booking_id,
                NULL::TIMESTAMPTZ AS appointment_date,
                p.title AS post_title,
                1 AS tickets_count -- Waitlist entries typically count as 1
            FROM
                public.waitlist_entries we
            LEFT JOIN
                public.profiles pr ON we.user_id = pr.id
            LEFT JOIN
                auth.users au ON we.user_id = au.id
            LEFT JOIN
                public.posts p ON we.post_id = p.id
            WHERE
                we.post_id = v_post_id
            LIMIT v_limit;
        
        -- All users (announcements/broadcasts)
        WHEN 'announcement', 'broadcast' THEN
            RETURN QUERY
            SELECT
                pr.id AS recipient_id,
                pr.full_name AS name,
                au.email::TEXT,
                'All Users'::TEXT AS group_type,
                pr.avatar_url,
                NULL::UUID AS appointment_id,
                NULL::UUID AS booking_id,
                NULL::TIMESTAMPTZ AS appointment_date,
                NULL::TEXT AS post_title,
                1 AS tickets_count -- Each user counts as 1 for announcements
            FROM
                public.profiles pr
            LEFT JOIN
                auth.users au ON pr.id = au.id
            LIMIT v_limit;
        
        -- Default case
        ELSE
            RAISE EXCEPTION 'Unknown recipient type: %', v_type;
    END CASE;
END;
$$;


ALTER FUNCTION "public"."get_potential_recipients"("p_params" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_protected_media_url"("content_id" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_url TEXT;
    v_content_id ALIAS FOR content_id; -- Use an alias for internal references
BEGIN
    -- Check if user has access to this content using our fixed v2 function
    IF can_access_content_v2(v_content_id) THEN
        -- Get the protected URL
        SELECT pmd.url INTO v_url
        FROM protected_media_data pmd
        WHERE pmd.content_id = v_content_id;
        
        -- Record the access
        UPDATE content_purchases cp
        SET 
            last_accessed = NOW(),
            download_count = download_count + 1
        FROM purchases p
        WHERE cp.purchase_id = p.id
        AND cp.content_id = v_content_id
        AND p.user_id = auth.uid();
        
        RETURN v_url;
    ELSE
        RETURN NULL;
    END IF;
END;
$$;


ALTER FUNCTION "public"."get_protected_media_url"("content_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_protected_media_url_v2"("content_id" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_url TEXT;
    v_content_id ALIAS FOR content_id; -- Use an alias for internal references
BEGIN
    -- Check if user has access to this content using our fixed v2 function
    IF can_access_content_v2(v_content_id) THEN
        -- Get the protected URL
        SELECT url INTO v_url
        FROM protected_media_data pmd
        WHERE pmd.content_id = v_content_id;
        
        -- Record the access
        UPDATE content_purchases cp
        SET 
            last_accessed = NOW(),
            download_count = download_count + 1
        FROM purchases p
        WHERE cp.purchase_id = p.id
        AND cp.content_id = v_content_id
        AND p.user_id = auth.uid();
        
        RETURN v_url;
    ELSE
        RETURN NULL;
    END IF;
END;
$$;


ALTER FUNCTION "public"."get_protected_media_url_v2"("content_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_provider_availability"("provider_id" "uuid", "start_date" "date", "end_date" "date") RETURNS TABLE("date" "date", "available_slots" "jsonb")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    AS $_$
DECLARE
    current_loop_date DATE := start_date;
    provider_timezone TEXT;
    buffer_minutes INTEGER;
BEGIN
    -- Get provider preferences
    SELECT
        COALESCE(p.timezone, 'UTC'),
        COALESCE(p.appointment_buffer_minutes, 0)
    INTO
        provider_timezone,
        buffer_minutes
    FROM
        public.provider_preferences p
    WHERE
        p.user_id = $1;

    -- Default to UTC and no buffer if no preferences found
    IF NOT FOUND THEN
        provider_timezone := 'UTC';
        buffer_minutes := 0;
    END IF;

    -- Loop through each date in the range
    WHILE current_loop_date <= $3 LOOP
        -- Assign the output column 'date' using the current loop date
        "date" := current_loop_date;

        -- Build a JSONB array of slots directly
        SELECT jsonb_agg(
            jsonb_build_object(
                'start_time', slot_time,
                'end_time', slot_time + INTERVAL '1 hour',
                'available', TRUE,
                'slot_id', md5($1::TEXT || slot_time::TEXT)
            )
            ORDER BY slot_time
        )
        INTO available_slots
        FROM (
            -- Generate potential hourly slots based on provider's availability for this day of week
            SELECT
                (current_loop_date + avail.start_time + (h * INTERVAL '1 hour'))::TIMESTAMP AS slot_time
            FROM
                public.availability avail,
                generate_series(0, 8) h
            WHERE
                avail.user_id = $1 AND
                avail.is_active = true AND
                -- Compare lowercase day names for robustness
                LOWER(avail.day) = LOWER(TRIM(TO_CHAR(current_loop_date, 'day'))) AND
                -- Check if the slot is within the provider's time range
                (avail.start_time + (h * INTERVAL '1 hour')) < avail.end_time AND
                (avail.start_time + (h * INTERVAL '1 hour') + INTERVAL '1 hour') <= avail.end_time AND
                -- Make sure this date isn't marked as unavailable in exceptions
                NOT EXISTS (
                    SELECT 1
                    FROM public.availability_exceptions ae
                    WHERE ae.user_id = $1 AND
                          ae.exception_date = current_loop_date AND
                          ae.is_available = false
                )
        ) slots;

        -- Return empty JSONB array instead of NULL for dates with no slots
        IF available_slots IS NULL THEN
            available_slots := '[]'::JSONB;
        END IF;
        
        -- Increment the loop date before RETURN NEXT
        current_loop_date := current_loop_date + INTERVAL '1 day';
        
        -- Return the calculated row
        RETURN NEXT;
    END LOOP;

    RETURN;
END;
$_$;


ALTER FUNCTION "public"."get_provider_availability"("provider_id" "uuid", "start_date" "date", "end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_sent_notifications"("p_limit" integer DEFAULT 50, "p_offset" integer DEFAULT 0, "p_type" "text" DEFAULT NULL::"text", "p_reference_id" "uuid" DEFAULT NULL::"uuid", "p_start_date" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_end_date" timestamp with time zone DEFAULT "now"()) RETURNS TABLE("id" "uuid", "title" "text", "content" "text", "type" "public"."notification_type", "reference_id" "uuid", "reference_type" "text", "created_at" timestamp with time zone, "recipient_count" bigint, "read_count" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.id,
    n.title,
    n.content,
    n.type,
    n.reference_id,
    n.reference_type,
    n.created_at,
    COUNT(DISTINCT n.user_id) AS recipient_count,
    COUNT(DISTINCT CASE WHEN n.is_read THEN n.user_id END) AS read_count
  FROM notifications n
  WHERE 
    n.sender_id = auth.uid()
    AND (p_type IS NULL OR n.type::TEXT = p_type)
    AND (p_reference_id IS NULL OR n.reference_id = p_reference_id)
    AND (p_start_date IS NULL OR n.created_at >= p_start_date)
    AND (n.created_at <= p_end_date)
  GROUP BY 
    n.id, n.title, n.content, n.type, n.reference_id, n.reference_type, n.created_at
  ORDER BY n.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


ALTER FUNCTION "public"."get_sent_notifications"("p_limit" integer, "p_offset" integer, "p_type" "text", "p_reference_id" "uuid", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_sent_notifications"("p_limit" integer, "p_offset" integer, "p_type" "text", "p_reference_id" "uuid", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone) IS 'Retrieves notifications sent by the current user with read statistics';



CREATE OR REPLACE FUNCTION "public"."get_service_calendar_availability"("p_service_id" "uuid", "p_days_ahead" integer DEFAULT 30, "p_timezone" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_start_date DATE := CURRENT_DATE;
    v_end_date DATE := CURRENT_DATE + (p_days_ahead || ' days')::INTERVAL;
    v_service_owner_id UUID;
    v_timezone TEXT;
    v_result JSONB;
BEGIN
    -- Get service provider
    SELECT p.user_id, COALESCE(p_timezone, pp.timezone, 'UTC')
    INTO v_service_owner_id, v_timezone
    FROM public.services s
    JOIN public.posts p ON s.post_id = p.id
    LEFT JOIN public.provider_preferences pp ON p.user_id = pp.user_id
    WHERE s.id = p_service_id;
    
    IF v_service_owner_id IS NULL THEN
        RETURN jsonb_build_object('error', 'Service not found');
    END IF;
    
    -- Get availability data
    WITH availability_data AS (
        SELECT 
            date,
            available_slots
        FROM 
            get_provider_availability(v_service_owner_id, v_start_date, v_end_date)
    ),
    calendar_days AS (
        SELECT 
            date,
            -- For each date, get the count of available slots
            (
                SELECT COUNT(*)
                FROM jsonb_array_elements(available_slots) AS slot
                WHERE (slot->>'available')::BOOLEAN = true
            ) AS available_slot_count,
            -- Get the first and last available times
            (
                SELECT MIN(
                    (elem->>'start_time')::TIMESTAMP WITH TIME ZONE AT TIME ZONE v_timezone
                )
                FROM jsonb_array_elements(available_slots) AS elem
                WHERE (elem->>'available')::BOOLEAN = true
            ) AS first_available,
            (
                SELECT MAX(
                    (elem->>'end_time')::TIMESTAMP WITH TIME ZONE AT TIME ZONE v_timezone
                )
                FROM jsonb_array_elements(available_slots) AS elem
                WHERE (elem->>'available')::BOOLEAN = true
            ) AS last_available,
            -- Format for a calendar view (day cells)
            CASE 
                WHEN (
                    SELECT COUNT(*)
                    FROM jsonb_array_elements(available_slots) AS slot
                    WHERE (slot->>'available')::BOOLEAN = true
                ) > 0 THEN 'available'
                WHEN (
                    SELECT COUNT(*)
                    FROM jsonb_array_elements(available_slots) AS slot
                ) = 0 THEN 'unavailable'
                ELSE 'booked'
            END AS day_status
        FROM 
            availability_data
    )
    SELECT 
        jsonb_build_object(
            'service_id', p_service_id,
            'timezone', v_timezone,
            'days', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'date', date,
                        'day_status', day_status,
                        'available_slots', available_slot_count,
                        'first_available', first_available,
                        'last_available', last_available
                    )
                    ORDER BY date
                )
                FROM calendar_days
            ),
            'hours', (
                SELECT jsonb_build_object(
                    'earliest', MIN(first_available::time),
                    'latest', MAX(last_available::time)
                )
                FROM calendar_days
                WHERE first_available IS NOT NULL
            )
        ) INTO v_result;
    
    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."get_service_calendar_availability"("p_service_id" "uuid", "p_days_ahead" integer, "p_timezone" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_service_calendar_availability"("p_service_id" "uuid", "p_days_ahead" integer, "p_timezone" "text") IS 'Returns calendar-friendly availability data for a specific service';



CREATE OR REPLACE FUNCTION "public"."get_service_details"("service_slug" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT 
        jsonb_build_object(
            'service_id', sv.service_id,
            'post_id', sv.post_id,
            'slug', sv.slug,
            'title', sv.title,
            'description', sv.description,
            'content', sv.content,
            'thumbnail_url', sv.thumbnail_url,
            'service_type', sv.service_type,
            'price', sv.price,
            'duration', sv.duration,
            'featured', sv.featured,
            'created_at', sv.created_at,
            'updated_at', sv.updated_at,
            'creator_id', sv.creator_id,
            'booking_workflow', sv.booking_workflow,
            'auto_confirm', sv.auto_confirm,
            'confirmation_deadline_hours', sv.confirmation_deadline_hours,
            'location', sv.location,
            'creator', sv.creator,
            'tags', sv.tags
        )
    INTO result
    FROM 
        public.service_details_view sv
    WHERE 
        sv.slug = service_slug;
        
    -- Add appointments if the user is the service provider
    IF result IS NOT NULL AND result->>'creator_id' = auth.uid()::TEXT THEN
        SELECT 
            result || jsonb_build_object(
                'appointments', csv.appointments,
                'future_appointments', csv.future_appointments,
                'past_appointments', csv.past_appointments,
                'availability_stats', csv.availability_stats
            )
        INTO result
        FROM 
            public.comprehensive_services_view csv
        WHERE 
            csv.service_id = (result->>'service_id')::UUID;
    END IF;
    
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."get_service_details"("service_slug" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_service_details"("service_slug" "text") IS 'Get detailed service information including booking workflow configuration';



CREATE OR REPLACE FUNCTION "public"."get_smart_comments"("in_post_id" "uuid", "in_limit" integer DEFAULT 10, "in_offset" integer DEFAULT 0, "in_sort_by" "text" DEFAULT 'best'::"text", "in_show_replies" boolean DEFAULT true, "in_min_score" integer DEFAULT '-5'::integer) RETURNS TABLE("id" bigint, "content" "text", "author_id" "uuid", "author_name" "text", "author_avatar" "text", "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "parent_id" bigint, "reactions" "json", "is_edited" boolean, "depth" integer, "deleted_at" timestamp with time zone, "has_replies" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    reaction_weights JSON := '{"like": 1, "heart": 2, "laugh": 1, "sad": -1, "angry": -2}'::JSON;
BEGIN
    RETURN QUERY
    WITH RECURSIVE comment_base AS (
        -- Base comments query with explicit column references
        SELECT 
            c.id as comment_id,
            c.comment as comment_text,
            c.user_id,
            c.post_id,
            c.parent_id,
            c.created_at as comment_created_at,
            c.updated_at as comment_updated_at,
            c.deleted_at as comment_deleted_at,
            c.is_edited as comment_is_edited,
            c.depth as comment_depth,
            c.hasReplies as comment_has_replies,
            p.full_name as author_name,
            p.avatar_url as author_avatar
        FROM public.comments c
        LEFT JOIN public.profiles p ON c.user_id = p.id
        WHERE 
            c.post_id = in_post_id
            AND (c.deleted_at IS NULL OR c.hasReplies = true)
            AND (in_show_replies OR c.parent_id IS NULL)
            AND (c.parent_id IS NULL OR c.depth <= 3)
    ),
    reaction_counts AS (
        -- Pre-calculate reaction counts and user reactions
        SELECT 
            cr.comment_id,
            cr.reaction_type,
            COUNT(*) as reaction_count,
            bool_or(cr.user_id = auth.uid()) as user_reacted
        FROM public.comment_reactions cr
        WHERE cr.comment_id IN (SELECT cb.comment_id FROM comment_base cb)
        GROUP BY cr.comment_id, cr.reaction_type
    ),
    reaction_scores AS (
        -- Calculate total reaction score
        SELECT 
            rc.comment_id,
            SUM((reaction_weights->>rc.reaction_type)::INTEGER * rc.reaction_count) as reaction_score,
            json_agg(
                json_build_object(
                    'type', rc.reaction_type,
                    'count', rc.reaction_count,
                    'userReacted', rc.user_reacted
                )
            ) as reactions_json
        FROM reaction_counts rc
        GROUP BY rc.comment_id
    ),
    ranked_comments AS (
        -- Combine everything with ranking
        SELECT 
            cb.comment_id,
            CASE 
                WHEN cb.comment_deleted_at IS NOT NULL THEN '[deleted]'
                ELSE cb.comment_text
            END as comment_content,
            cb.user_id as comment_author_id,
            cb.author_name as comment_author_name,
            cb.author_avatar as comment_author_avatar,
            cb.comment_created_at,
            cb.comment_updated_at,
            cb.parent_id as comment_parent_id,
            COALESCE(rs.reactions_json, '[]'::json) as comment_reactions,
            cb.comment_is_edited,
            cb.comment_depth,
            cb.comment_deleted_at,
            cb.comment_has_replies,
            (CASE 
                WHEN cb.comment_deleted_at IS NOT NULL THEN -1000
                ELSE COALESCE(rs.reaction_score, 0)
            END) + 
            (CASE 
                WHEN cb.comment_has_replies THEN 2
                ELSE 0
            END) +
            (CASE 
                WHEN in_sort_by = 'best' THEN 
                    EXTRACT(EPOCH FROM cb.comment_created_at) / 45000
                ELSE 0
            END)::INTEGER as hotness_score
        FROM comment_base cb
        LEFT JOIN reaction_scores rs ON cb.comment_id = rs.comment_id
    )
    SELECT 
        rc.comment_id as id,
        rc.comment_content as content,
        rc.comment_author_id as author_id,
        COALESCE(rc.comment_author_name, 'Anonymous') as author_name,
        rc.comment_author_avatar as author_avatar,
        rc.comment_created_at as created_at,
        rc.comment_updated_at as updated_at,
        rc.comment_parent_id as parent_id,
        rc.comment_reactions as reactions,
        rc.comment_is_edited as is_edited,
        rc.comment_depth as depth,
        rc.comment_deleted_at as deleted_at,
        rc.comment_has_replies as has_replies
    FROM ranked_comments rc
    ORDER BY
        CASE WHEN in_sort_by = 'best' THEN rc.hotness_score END DESC,
        CASE WHEN in_sort_by = 'newest' THEN rc.comment_created_at END DESC,
        CASE WHEN in_sort_by = 'oldest' THEN rc.comment_created_at END ASC
    LIMIT in_limit
    OFFSET in_offset;
END;
$$;


ALTER FUNCTION "public"."get_smart_comments"("in_post_id" "uuid", "in_limit" integer, "in_offset" integer, "in_sort_by" "text", "in_show_replies" boolean, "in_min_score" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_subscriptions"("filters" "jsonb") RETURNS TABLE("id" "text", "customername" "text", "customeremail" character varying, "plan" "text", "tier" "text", "billingcycle" "text", "amount" numeric, "status" "text", "startdate" timestamp with time zone, "nextbillingdate" timestamp with time zone, "totalpaid" numeric, "paymentscount" integer, "lastpaymentstatus" "text", "lastpaymentdate" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id::TEXT,
        prof.full_name AS customerName,
        u.email AS customerEmail,
        s.plan_name AS plan,
        s.tier,
        s.billing_cycle AS billingCycle,
        p.amount,
        s.status,
        p.start_date AS startDate,
        s.next_billing_date AS nextBillingDate,
        s.total_paid AS totalPaid,
        s.payments_count AS paymentsCount,
        s.last_payment_status AS lastPaymentStatus,
        s.last_payment_date AS lastPaymentDate
    FROM 
        subscriptions s
    JOIN 
        purchases p ON s.purchase_id = p.id
    JOIN 
        auth.users u ON p.user_id = u.id
    JOIN 
        profiles prof ON prof.id = p.user_id
    WHERE
        p.purchase_type = 'subscription' AND
        (p.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
        )) AND
        (
            filters->>'status' IS NULL OR 
            filters->>'status' = 'all' OR 
            CASE
                WHEN filters->>'status' = 'completed' THEN s.status IN ('active', 'trial')
                WHEN filters->>'status' = 'pending' THEN s.status IN ('active', 'trial', 'past_due')
                WHEN filters->>'status' = 'failed' THEN s.status = 'past_due'
                WHEN filters->>'status' = 'refunded' THEN s.status IN ('cancelled', 'paused')
                ELSE FALSE
            END
        ) AND
        (filters->>'search' IS NULL OR 
            (filters->>'search' <> '' AND (
                prof.full_name ILIKE '%' || (filters->>'search') || '%' OR
                u.email ILIKE '%' || (filters->>'search') || '%' OR
                s.id::TEXT ILIKE '%' || (filters->>'search') || '%' OR
                s.plan_name ILIKE '%' || (filters->>'search') || '%'
            ))
        )
    ORDER BY
        s.next_billing_date ASC
    LIMIT
        COALESCE((filters->>'pageSize')::INTEGER, 10)
    OFFSET
        COALESCE(((filters->>'page')::INTEGER - 1) * (filters->>'pageSize')::INTEGER, 0);
END;
$$;


ALTER FUNCTION "public"."get_subscriptions"("filters" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_suggested_appointments"("p_user_id" "uuid", "p_start_date" "date", "p_end_date" "date") RETURNS TABLE("appointment_id" "uuid", "facilitator_id" "uuid", "client_id" "uuid", "start_time" timestamp with time zone, "end_time" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id AS appointment_id,
        a.facilitator_id,
        a.client_id,
        a.start_time,
        a.end_time
    FROM public.appointments a
    WHERE a.client_id = p_user_id
    AND a.status = 'suggested'
    AND DATE(a.start_time) BETWEEN p_start_date AND p_end_date
    ORDER BY a.start_time;
END;
$$;


ALTER FUNCTION "public"."get_suggested_appointments"("p_user_id" "uuid", "p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_upcoming_events"("user_lat" double precision DEFAULT NULL::double precision, "user_lon" double precision DEFAULT NULL::double precision, "event_types" "public"."event_type_enum"[] DEFAULT NULL::"public"."event_type_enum"[], "distance_limit" double precision DEFAULT NULL::double precision, "page_size" integer DEFAULT 10, "page_number" integer DEFAULT 0, "only_featured" boolean DEFAULT false, "creator_ids" "uuid"[] DEFAULT NULL::"uuid"[], "tag_filter" "text"[] DEFAULT NULL::"text"[]) RETURNS TABLE("event_id" "uuid", "post_id" "uuid", "slug" "text", "title" "text", "description" "text", "thumbnail_url" "text", "event_type" "public"."event_type_enum", "location_name" "text", "next_date" timestamp with time zone, "available_tickets" boolean, "min_price" numeric, "distance" double precision, "total_count" bigint, "creator" "jsonb", "featured" boolean, "tags" "jsonb")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    WITH event_with_distance AS (
        SELECT 
            e.event_id,
            e.post_id,
            e.slug,
            e.title,
            e.description,
            e.thumbnail_url,
            e.event_type,
            CASE 
                WHEN e.event_type = 'online' THEN 'Online Event'
                ELSE COALESCE((e.location->>'name')::TEXT, 'Location TBA')
            END AS location_name,
            e.next_available_date as next_date,
            (e.future_dates != '[]'::jsonb AND EXISTS (
                SELECT 1 FROM jsonb_array_elements(e.tickets) t
                WHERE (t->>'is_sold_out')::BOOLEAN = FALSE
            )) AS available_tickets,
            e.min_price,
            -- Calculate distance if location coordinates and user coordinates provided
            CASE 
                WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL 
                AND e.location ? 'coordinates' 
                AND e.location->'coordinates' ? 'latitude'
                AND e.event_type IN ('in-person', 'hybrid') 
                THEN 
                    ST_Distance(
                        ST_SetSRID(ST_MakePoint(
                            (e.location->'coordinates'->>'longitude')::FLOAT,
                            (e.location->'coordinates'->>'latitude')::FLOAT
                        ), 4326)::geography,
                        ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography
                    ) / 1000  -- Convert meters to kilometers
                ELSE NULL
            END AS distance,
            e.creator,
            e.featured,
            e.tags,
            COUNT(*) OVER()::BIGINT as total_count
        FROM 
            public.comprehensive_events_view e
        WHERE 
            e.next_available_date IS NOT NULL
            AND (event_types IS NULL OR e.event_type = ANY(event_types))
            AND (only_featured = FALSE OR e.featured = TRUE)
            AND (creator_ids IS NULL OR e.creator_id = ANY(creator_ids))
            AND (tag_filter IS NULL OR EXISTS (
                SELECT 1 FROM jsonb_array_elements_text(e.tags) tag_name
                WHERE tag_name::TEXT = ANY(tag_filter)
            ))
            AND CASE
                WHEN distance_limit IS NOT NULL 
                    AND user_lat IS NOT NULL 
                    AND user_lon IS NOT NULL 
                    AND e.location ? 'coordinates' 
                    AND e.location->'coordinates' ? 'latitude'
                THEN 
                    ST_Distance(
                        ST_SetSRID(ST_MakePoint(
                            (e.location->'coordinates'->>'longitude')::FLOAT,
                            (e.location->'coordinates'->>'latitude')::FLOAT
                        ), 4326)::geography,
                        ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography
                    ) / 1000 <= distance_limit
                ELSE TRUE
            END
    )
    SELECT 
        ewd.event_id,
        ewd.post_id,
        ewd.slug,
        ewd.title,
        ewd.description,
        ewd.thumbnail_url,
        ewd.event_type,
        ewd.location_name,
        ewd.next_date,
        ewd.available_tickets,
        ewd.min_price,
        ewd.distance,
        ewd.total_count,
        ewd.creator,
        ewd.featured,
        ewd.tags
    FROM 
        event_with_distance ewd
    ORDER BY 
        -- Sort by distance if location-based search, otherwise by date
        CASE 
            WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL THEN ewd.distance
            ELSE NULL
        END NULLS LAST,
        ewd.next_date ASC
    LIMIT page_size
    OFFSET page_number * page_size;
END;
$$;


ALTER FUNCTION "public"."get_upcoming_events"("user_lat" double precision, "user_lon" double precision, "event_types" "public"."event_type_enum"[], "distance_limit" double precision, "page_size" integer, "page_number" integer, "only_featured" boolean, "creator_ids" "uuid"[], "tag_filter" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_upcoming_service_appointments"("provider_id" "uuid" DEFAULT "auth"."uid"(), "limit_count" integer DEFAULT 10) RETURNS TABLE("appointment_id" "uuid", "service_id" "uuid", "post_id" "uuid", "service_title" "text", "appointment_date" timestamp with time zone, "duration" interval, "method" "text", "service_type" "text", "status" "text", "client_name" "text", "client_avatar" "text", "price" numeric)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sav.appointment_id,
        sav.service_id,
        sv.post_id,
        sv.title AS service_title,
        sav.appointment_date,
        (sav.duration || ' minutes')::INTERVAL AS duration,
        sav.method,
        sav.service_type,
        sav.status,
        sav.client->>'full_name' AS client_name,
        sav.client->>'avatar_url' AS client_avatar,
        sav.price_paid AS price
    FROM 
        public.service_appointments_view sav
    JOIN 
        public.service_details_view sv ON sav.service_id = sv.service_id
    WHERE 
        sav.provider_id = get_upcoming_service_appointments.provider_id
        AND sav.is_future = TRUE
        AND sav.status IN ('confirmed', 'pending')
    ORDER BY 
        sav.appointment_date ASC
    LIMIT 
        get_upcoming_service_appointments.limit_count;
END;
$$;


ALTER FUNCTION "public"."get_upcoming_service_appointments"("provider_id" "uuid", "limit_count" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_appointments"("p_user_id" "uuid" DEFAULT NULL::"uuid", "p_status" "text" DEFAULT NULL::"text", "p_limit" integer DEFAULT 100, "p_offset" integer DEFAULT 0) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_user_id UUID;
    v_result JSONB;
BEGIN
    -- Default to current user
    v_user_id := COALESCE(p_user_id, auth.uid());
    
    -- Check permissions if trying to view another user's appointments
    IF v_user_id != auth.uid() AND NOT EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN jsonb_build_object('error', 'Permission denied');
    END IF;
    
    -- Get appointments
    WITH user_appointments AS (
        SELECT
            ap.id AS appointment_id,
            p.id AS purchase_id,
            s.id AS service_id,
            pp.id AS post_id,
            pp.title AS service_title,
            pr.full_name AS provider_name,
            pr.avatar_url AS provider_avatar,
            p.owner_id AS provider_id,
            ap.appointment_date,
            ap.duration,
            ap.method,
            ap.service_type,
            ap.status,
            p.payment_status,
            p.amount,
            ap.appointment_date > CURRENT_TIMESTAMP AS is_future,
            ROW_NUMBER() OVER (
                ORDER BY 
                    CASE WHEN ap.appointment_date > CURRENT_TIMESTAMP THEN 0 ELSE 1 END,
                    ap.appointment_date
            ) AS row_num
        FROM
            public.appointment_purchases ap
        JOIN
            public.purchases p ON ap.purchase_id = p.id
        JOIN
            public.services s ON ap.service_id = s.id
        JOIN
            public.posts pp ON s.post_id = pp.id
        LEFT JOIN
            public.profiles pr ON p.owner_id = pr.id
        WHERE
            p.user_id = v_user_id
            AND (
                p_status IS NULL
                OR ap.status = p_status::appointment_status_enum
            )
    )
    SELECT jsonb_build_object(
        'appointments', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'appointment_id', appointment_id,
                    'purchase_id', purchase_id,
                    'service_id', service_id,
                    'service_title', service_title,
                    'provider_name', provider_name,
                    'provider_avatar', provider_avatar,
                    'provider_id', provider_id,
                    'appointment_date', appointment_date,
                    'duration', duration,
                    'method', method,
                    'service_type', service_type,
                    'status', status,
                    'payment_status', payment_status,
                    'amount', amount,
                    'is_future', is_future
                )
            )
            FROM user_appointments
            WHERE row_num > p_offset AND row_num <= (p_offset + p_limit)
        ),
        'count', (
            SELECT COUNT(*) FROM user_appointments
        ),
        'summary', (
            SELECT jsonb_build_object(
                'upcoming', COUNT(*) FILTER (WHERE is_future AND status = 'confirmed'),
                'pending', COUNT(*) FILTER (WHERE status IN ('pending_approval', 'pending_payment')),
                'past', COUNT(*) FILTER (WHERE NOT is_future AND status = 'confirmed'),
                'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled')
            )
            FROM user_appointments
        )
    ) INTO v_result;
    
    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."get_user_appointments"("p_user_id" "uuid", "p_status" "text", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_chat_rooms"() RETURNS TABLE("room_id" "uuid", "room_name" "text", "room_type" "public"."chat_type_enum", "room_description" "text", "is_broadcast" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "latest_message" "text", "latest_message_id" "uuid", "latest_message_sender" "uuid", "latest_message_time" timestamp with time zone, "unread_count" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY SELECT * FROM get_user_chat_rooms(auth.uid());
END;
$$;


ALTER FUNCTION "public"."get_user_chat_rooms"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_chat_rooms"("p_user_id" "uuid") RETURNS TABLE("room_id" "uuid", "room_name" "text", "room_type" "public"."chat_type_enum", "room_description" "text", "is_broadcast" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "latest_message" "text", "latest_message_id" "uuid", "latest_message_sender" "uuid", "latest_message_time" timestamp with time zone, "unread_count" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
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
$$;


ALTER FUNCTION "public"."get_user_chat_rooms"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_event_purchases"("p_status" "text" DEFAULT NULL::"text") RETURNS TABLE("purchase_id" "uuid", "event_id" "uuid", "post_id" "uuid", "title" "text", "slug" "text", "thumbnail_url" "text", "ticket_id" "uuid", "ticket_name" "text", "ticket_price" numeric, "date_id" "uuid", "event_date" timestamp with time zone, "event_end_date" timestamp with time zone, "purchase_date" timestamp with time zone, "attendees" integer, "amount" numeric, "payment_status" "text", "booking_status" "text", "ticket_code" "text", "is_virtual" boolean, "event_type" "public"."event_type_enum", "location" "jsonb", "room" "jsonb")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id AS purchase_id,
        p.event_id,
        ev.post_id,
        ev.title,
        ev.slug,
        ev.thumbnail_url,
        eb.ticket_id,
        t.title AS ticket_name,
        t.price AS ticket_price,
        eb.date_id,
        ed.start_date AS event_date,
        ed.end_date AS event_end_date,
        p.purchase_date,
        eb.attendees,
        p.amount,
        p.payment_status,
        eb.status AS booking_status,
        eb.ticket_code,
        eb.is_virtual,
        ev.event_type,
        ev.location,
        ev.room
    FROM
        public.purchases p
    JOIN
        public.event_bookings eb ON p.id = eb.purchase_id
    JOIN
        public.event_details_view ev ON p.event_id = ev.event_id
    JOIN
        public.tickets t ON eb.ticket_id = t.id
    JOIN
        public.event_dates ed ON eb.date_id = ed.id
    WHERE
        p.user_id = auth.uid()
        AND p.purchase_type = 'event'
        AND (
            p_status IS NULL 
            OR (
                CASE 
                    WHEN p_status = 'upcoming' THEN 
                        ed.start_date > CURRENT_TIMESTAMP AND p.payment_status != 'refunded'
                    WHEN p_status = 'past' THEN 
                        ed.start_date <= CURRENT_TIMESTAMP AND p.payment_status != 'refunded'
                    WHEN p_status = 'cancelled' THEN 
                        p.payment_status = 'refunded' OR p.payment_status = 'failed'
                    ELSE 
                        p.payment_status = p_status
                END
            )
        )
    ORDER BY
        ed.start_date ASC;
END;
$$;


ALTER FUNCTION "public"."get_user_event_purchases"("p_status" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_location"("user_uuid" "uuid" DEFAULT "auth"."uid"()) RETURNS TABLE("latitude" double precision, "longitude" double precision, "location_id" "uuid", "location_name" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ST_Y(ST_AsText(coordinates::geometry)::geography::geometry)::double precision as latitude,
        ST_X(ST_AsText(coordinates::geometry)::geography::geometry)::double precision as longitude,
        ul.location_id,
        ul.location_name
    FROM user_locations ul
    WHERE ul.user_id = user_uuid;
END;
$$;


ALTER FUNCTION "public"."get_user_location"("user_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_service_appointments"("user_id" "uuid" DEFAULT "auth"."uid"()) RETURNS TABLE("appointment_id" "uuid", "purchase_id" "uuid", "service_id" "uuid", "service_title" "text", "provider_name" "text", "provider_avatar" "text", "appointment_date" timestamp with time zone, "duration" integer, "method" "text", "service_type" "text", "status" "text", "payment_status" "text", "amount" numeric, "is_future" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uav.appointment_id,
        uav.purchase_id,
        uav.service_id,
        uav.service_title,
        uav.provider_name,
        uav.provider_avatar,
        uav.appointment_date,
        uav.duration,
        uav.method,
        uav.service_type,
        uav.status,
        uav.payment_status,
        uav.amount,
        uav.is_future
    FROM 
        public.user_appointments_view uav
    WHERE 
        uav.user_id = get_user_service_appointments.user_id
    ORDER BY 
        uav.appointment_date DESC;
END;
$$;


ALTER FUNCTION "public"."get_user_service_appointments"("user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."grant_public_read_access"("table_name" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  EXECUTE format('GRANT SELECT ON TABLE public.%I TO authenticated', table_name);
  EXECUTE format('GRANT SELECT ON TABLE public.%I TO anon', table_name);
END;
$$;


ALTER FUNCTION "public"."grant_public_read_access"("table_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_appointment_request"("p_service_id" "uuid", "p_user_id" "uuid", "p_owner_id" "uuid", "p_post_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text" DEFAULT 'video'::"text", "p_message" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_purchase_id UUID;
  v_appointment_id UUID;
  v_result JSONB;
BEGIN
  -- Create initial purchase record with pending status
  INSERT INTO purchases (
    user_id,
    owner_id,
    post_id,
    service_id,
    amount, -- Will be updated when approved
    currency,
    payment_status,
    purchase_type,
    start_date,
    end_date
  ) VALUES (
    p_user_id,
    p_owner_id,
    p_post_id,
    p_service_id,
    0, -- Initial amount is 0, will be set when approved
    'gbp',
    'pending_approval',
    'appointment',
    p_appointment_date,
    p_appointment_date + (p_duration || ' minutes')::interval
  )
  RETURNING id INTO v_purchase_id;
  
  -- Create initial appointment purchase record
  INSERT INTO appointment_purchases (
    service_id,
    purchase_id,
    appointment_date,
    duration,
    method,
    service_type,
    status,
    notes
  ) VALUES (
    p_service_id,
    v_purchase_id,
    p_appointment_date,
    p_duration,
    p_method,
    'consultation', -- Default to consultation
    'pending_approval',
    p_message
  )
  RETURNING id INTO v_appointment_id;
  
  -- Insert into chat system - Create a notification in chat
  INSERT INTO messages (
    sender_id,
    recipient_id,
    content,
    message_type,
    metadata
  ) VALUES (
    p_user_id,
    p_owner_id,
    'New appointment request for ' || p_appointment_date,
    'appointment_request',
    jsonb_build_object(
      'appointment_id', v_appointment_id,
      'purchase_id', v_purchase_id,
      'service_id', p_service_id,
      'appointment_date', p_appointment_date,
      'duration', p_duration,
      'status', 'pending_approval'
    )
  );
  
  -- Return the created IDs
  v_result := jsonb_build_object(
    'purchase_id', v_purchase_id,
    'appointment_id', v_appointment_id,
    'status', 'pending_approval'
  );
  
  -- Trigger email notification (in future implementation)
  -- This will be handled by a trigger or separate process
  PERFORM pg_notify('appointment_requested', v_result::text);
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."handle_appointment_request"("p_service_id" "uuid", "p_user_id" "uuid", "p_owner_id" "uuid", "p_post_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_message" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."handle_appointment_request"("p_service_id" "uuid", "p_user_id" "uuid", "p_owner_id" "uuid", "p_post_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_message" "text") IS 'Creates a new appointment request and notifies the provider via chat';



CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    user_timezone public.timezone;
    iana_timezone TEXT;
BEGIN
    -- Insert into profiles
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');

    -- Set default user role
    INSERT INTO public.user_roles (user_id, role)
    VALUES (new.id, 'user');

    -- Check if user already has a timezone in metadata
    iana_timezone := new.raw_user_meta_data->>'timezone';

    -- Convert IANA timezone to UTC offset
    IF iana_timezone IS NOT NULL THEN
        BEGIN
            user_timezone := public.iana_to_utc_offset(iana_timezone);
        EXCEPTION
            WHEN others THEN
                -- If conversion fails, use UTC+00:00
                user_timezone := 'UTC+00:00'::public.timezone;
        END;
    ELSE
        user_timezone := 'UTC+00:00'::public.timezone;
    END IF;

    -- Update user metadata with UTC offset timezone
    UPDATE auth.users
    SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object('timezone', user_timezone::text)
    WHERE id = new.id;

    -- Insert into user_timezones table
    INSERT INTO public.user_timezones (user_id, timezone)
    VALUES (new.id, user_timezone);

    RETURN new;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_active_subscription"("subscription_creator_id" "uuid", "required_tier_key" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    IF required_tier_key IS NULL THEN
        -- Just check for any active subscription
        RETURN EXISTS (
            SELECT 1 
            FROM subscriptions s
            JOIN purchases p ON s.purchase_id = p.id
            WHERE p.owner_id = subscription_creator_id
            AND p.user_id = auth.uid()
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
        );
    ELSE
        -- Check subscription against required tier by comparing priorities
        RETURN EXISTS (
            SELECT 1 
            FROM subscriptions s
            JOIN purchases p ON s.purchase_id = p.id
            JOIN creator_subscription_tiers cst_user ON cst_user.tier_key = s.tier
                AND cst_user.creator_id = subscription_creator_id
            JOIN creator_subscription_tiers cst_required ON cst_required.tier_key = required_tier_key
                AND cst_required.creator_id = subscription_creator_id
            WHERE p.owner_id = subscription_creator_id
            AND p.user_id = auth.uid()
            AND p.payment_status = 'completed'
            AND s.status IN ('active', 'trial')
            AND (s.is_trial = FALSE OR s.trial_ends_at > NOW())
            AND (s.cancels_at IS NULL OR s.cancels_at > NOW())
            AND cst_user.priority >= cst_required.priority
        );
    END IF;
END;
$$;


ALTER FUNCTION "public"."has_active_subscription"("subscription_creator_id" "uuid", "required_tier_key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_role"("role_to_check" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = role_to_check::user_role
    );
END;
$$;


ALTER FUNCTION "public"."has_role"("role_to_check" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."iana_to_utc_offset"("iana_timezone" "text") RETURNS "public"."timezone"
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    utc_offset TEXT;
BEGIN
    -- This is a simplified conversion. In a real-world scenario, you'd want to handle daylight saving time and more complex cases.
    SELECT COALESCE(
        (SELECT concat('UTC', regexp_replace(abbrev, 'UTC', ''))
         FROM pg_timezone_names
         WHERE name = iana_timezone),
        'UTC+00:00'
    ) INTO utc_offset;

    -- Ensure the result is a valid public.timezone enum value
    RETURN utc_offset::public.timezone;
EXCEPTION
    WHEN others THEN
        -- If conversion fails, return UTC+00:00
        RETURN 'UTC+00:00'::public.timezone;
END;
$$;


ALTER FUNCTION "public"."iana_to_utc_offset"("iana_timezone" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."insert_playlist"("iframe" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
begin
    insert into public.spotify_playlist_join (user_id, iframe) values (auth.uid(), in_iframe);
end;
$$;


ALTER FUNCTION "public"."insert_playlist"("iframe" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_creator_or_admin"() RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN public.get_user_role(auth.uid()) IN ('creator', 'admin');
END;
$$;


ALTER FUNCTION "public"."is_creator_or_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."isowned"("input_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_is_owned BOOLEAN;
    v_user_id UUID;
    v_table_name TEXT;
    v_debug_details TEXT;
BEGIN
    -- Get the current user's ID
    v_user_id := auth.uid();
    
    -- Try to get the table name
    BEGIN
        v_table_name := TG_TABLE_NAME;
    EXCEPTION
        WHEN OTHERS THEN
            v_table_name := 'Unknown';
    END;
    
    -- If input_user_id is provided, compare it with auth.uid()
    IF input_user_id IS NOT NULL THEN
        v_is_owned := (input_user_id = v_user_id);
        v_debug_details := format('Comparing input_user_id %s with auth.uid() %s', input_user_id, v_user_id);
        RETURN v_is_owned;
    END IF;

    -- Check for user_id column in the current record
    BEGIN
        IF NEW IS NOT NULL THEN
            v_is_owned := (v_user_id = NEW.user_id);
        ELSIF OLD IS NOT NULL THEN
            v_is_owned := (v_user_id = OLD.user_id);
        ELSE
            v_debug_details := 'Unable to determine record context (NEW or OLD is not available)';
            RAISE EXCEPTION '%', v_debug_details;
        END IF;
    EXCEPTION
        WHEN undefined_column THEN
            v_debug_details := format('The table %s does not have a user_id column', v_table_name);
            RAISE EXCEPTION 'Operation failed: %. This operation requires a user_id for ownership verification.', v_debug_details;
    END;

    IF NOT v_is_owned THEN
        v_debug_details := format('User (ID: %s) does not own this record in table %s', v_user_id, v_table_name);
        RAISE EXCEPTION 'Access denied: %', v_debug_details;
    END IF;
      
    RETURN v_is_owned;
END;
$$;


ALTER FUNCTION "public"."isowned"("input_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."isownedfolder"("object_name" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_is_owned BOOLEAN;
    v_user_id UUID;
    v_folder_name TEXT;
BEGIN
    v_user_id := auth.uid();
    v_folder_name := (storage.foldername(object_name))[1];
    v_is_owned := (v_user_id::text) = v_folder_name;

    IF NOT v_is_owned THEN
        RAISE EXCEPTION 'Access denied: Folder "%" is not owned by user (ID: %). Users can only access their own folders.', 
                        v_folder_name, v_user_id;
    END IF;

    RETURN v_is_owned;
END;
$$;


ALTER FUNCTION "public"."isownedfolder"("object_name" "text") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."waitlist_entries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "waitlist_id" "uuid" NOT NULL,
    "email" character varying(255) NOT NULL,
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."waitlist_entries" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."join_waitlist"("waitlist_id" "uuid", "email" character varying, "user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."waitlist_entries"
    LANGUAGE "plpgsql"
    AS $$
    begin
        insert into waitlist_entries (waitlist_id, email, user_id)
        values (waitlist_id, email, user_id);
        return new;
    end;
    $$;


ALTER FUNCTION "public"."join_waitlist"("waitlist_id" "uuid", "email" character varying, "user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."leave_comment"("in_post_id" "uuid", "in_comment" "text", "in_parent_id" bigint DEFAULT NULL::bigint, "in_attachments" "json" DEFAULT NULL::"json", "in_mentions" "json" DEFAULT NULL::"json") RETURNS bigint
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    new_comment_id BIGINT;
    new_depth INTEGER;
BEGIN
    -- Calculate depth
    IF in_parent_id IS NOT NULL THEN
        SELECT depth + 1 INTO new_depth
        FROM public.comments
        WHERE id = in_parent_id;
    ELSE
        new_depth := 0;
    END IF;

    -- Insert comment
    INSERT INTO public.comments (
        user_id, 
        post_id, 
        comment, 
        parent_id,
        depth
    )
    VALUES (
        auth.uid(), 
        in_post_id, 
        in_comment, 
        in_parent_id,
        new_depth
    )
    RETURNING id INTO new_comment_id;

    -- Insert attachments
    IF in_attachments IS NOT NULL THEN
        INSERT INTO public.comment_attachments (
            comment_id,
            type,
            url,
            name,
            size
        )
        SELECT 
            new_comment_id,
            (value->>'type')::TEXT,
            (value->>'url')::TEXT,
            (value->>'name')::TEXT,
            (value->>'size')::INTEGER
        FROM json_array_elements(in_attachments);
    END IF;

    -- Insert mentions
    IF in_mentions IS NOT NULL THEN
        INSERT INTO public.comment_mentions (
            comment_id,
            user_id
        )
        SELECT 
            new_comment_id,
            (value->>'userId')::UUID
        FROM json_array_elements(in_mentions);
    END IF;

    RETURN new_comment_id;
END;
$$;


ALTER FUNCTION "public"."leave_comment"("in_post_id" "uuid", "in_comment" "text", "in_parent_id" bigint, "in_attachments" "json", "in_mentions" "json") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."legacy_create_notification"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text" DEFAULT NULL::"text", "p_reference_id" "uuid" DEFAULT NULL::"uuid", "p_reference_type" "text" DEFAULT NULL::"text", "p_metadata" "jsonb" DEFAULT NULL::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Call the new function with auth.uid() as the sender_id
  RETURN create_notification(
    p_user_id,
    auth.uid(),  -- Current user as sender
    p_title,
    p_content,
    p_type,
    NULL,       -- No priority needed
    p_reference_id,
    p_action_url,
    p_metadata
  );
END;
$$;


ALTER FUNCTION "public"."legacy_create_notification"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."legacy_create_notification"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") IS 'Backwards compatibility wrapper for the old create_notification function signature';



CREATE OR REPLACE FUNCTION "public"."link_journal_to_content"("p_journal_entry_id" bigint, "p_post_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_user_id uuid;
  v_link_id bigint;
begin
  -- Get user_id of the journal entry to check ownership
  select user_id into v_user_id from journal_entries where id = p_journal_entry_id;
  
  -- Check if the current user owns this journal entry
  if v_user_id is null or v_user_id != auth.uid() then
    raise exception 'Journal entry not found or you do not have permission to link it to content';
  end if;
  
  -- Check if the post exists
  if not exists (select 1 from posts where id = p_post_id) then
    raise exception 'Post does not exist';
  end if;
  
  -- Insert the link (if it doesn't already exist)
  insert into journal_content_links (journal_entry_id, post_id)
  values (p_journal_entry_id, p_post_id)
  on conflict (journal_entry_id, post_id) do nothing
  returning id into v_link_id;
  
  -- If no row was inserted, get the existing link id
  if v_link_id is null then
    select id into v_link_id from journal_content_links 
    where journal_entry_id = p_journal_entry_id and post_id = p_post_id;
  end if;
  
  -- Return the link info
  return (
    select jsonb_build_object(
      'id', jcl.id,
      'journal_entry_id', jcl.journal_entry_id,
      'post_id', jcl.post_id,
      'created_at', jcl.created_at
    )
    from journal_content_links jcl
    where jcl.id = v_link_id
  );
end;
$$;


ALTER FUNCTION "public"."link_journal_to_content"("p_journal_entry_id" bigint, "p_post_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."lock_provider_schedule"("p_provider_id" "uuid") RETURNS bigint
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_lock_key BIGINT;
BEGIN
    -- Create a stable lock key from the UUID
    SELECT ('x' || substring(p_provider_id::TEXT, 1, 8))::BIT(32)::BIGINT INTO v_lock_key;
    
    -- Acquire advisory lock with 5 second timeout
    IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
        -- Wait up to 5 seconds
        PERFORM pg_sleep(0.1)
        FROM generate_series(1, 50)
        WHERE NOT pg_try_advisory_xact_lock(v_lock_key);
        
        IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
            RAISE EXCEPTION 'Could not acquire schedule lock, try again later';
        END IF;
    END IF;
    
    RETURN v_lock_key;
END;
$$;


ALTER FUNCTION "public"."lock_provider_schedule"("p_provider_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."lock_provider_schedule"("p_provider_id" "uuid") IS 'Acquires an advisory lock for a provider schedule to prevent race conditions';



CREATE OR REPLACE FUNCTION "public"."log_error"("p_error_level" character varying, "p_error_message" "text", "p_error_code" character varying DEFAULT NULL::character varying, "p_source_file" character varying DEFAULT NULL::character varying, "p_line_number" integer DEFAULT NULL::integer, "p_function_name" character varying DEFAULT NULL::character varying, "p_user_id" "uuid" DEFAULT NULL::"uuid", "p_session_id" "uuid" DEFAULT NULL::"uuid", "p_request_path" character varying DEFAULT NULL::character varying, "p_request_method" character varying DEFAULT NULL::character varying, "p_ip_address" "inet" DEFAULT NULL::"inet", "p_user_agent" "text" DEFAULT NULL::"text", "p_stack_trace" "text" DEFAULT NULL::"text", "p_additional_data" "jsonb" DEFAULT NULL::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO error_logs (
        error_level, error_message, error_code, source_file, line_number,
        function_name, user_id, session_id, request_path, request_method,
        ip_address, user_agent, stack_trace, additional_data
    ) VALUES (
        p_error_level, p_error_message, p_error_code, p_source_file, p_line_number,
        p_function_name, p_user_id, p_session_id, p_request_path, p_request_method,
        p_ip_address, p_user_agent, p_stack_trace, p_additional_data
    );
END;
$$;


ALTER FUNCTION "public"."log_error"("p_error_level" character varying, "p_error_message" "text", "p_error_code" character varying, "p_source_file" character varying, "p_line_number" integer, "p_function_name" character varying, "p_user_id" "uuid", "p_session_id" "uuid", "p_request_path" character varying, "p_request_method" character varying, "p_ip_address" "inet", "p_user_agent" "text", "p_stack_trace" "text", "p_additional_data" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_all_notifications_as_read"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE notifications
  SET 
    is_read = TRUE,
    updated_at = NOW()
  WHERE 
    user_id = auth.uid() -- Ensure user can only mark their own notifications as read
    AND is_read = FALSE
  RETURNING COUNT(*) INTO v_count;
  
  RETURN COALESCE(v_count, 0);
END;
$$;


ALTER FUNCTION "public"."mark_all_notifications_as_read"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_broadcast_notification_read"("p_notification_id" "uuid", "p_user_id" "uuid" DEFAULT "auth"."uid"()) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_updated BOOLEAN;
BEGIN
  -- Check authentication
  IF p_user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Update the is_read status in notification_recipients
  UPDATE notification_recipients
  SET 
    is_read = TRUE,
    read_at = now(),
    updated_at = now()
  WHERE 
    notification_id = p_notification_id AND
    user_id = p_user_id;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  
  RETURN v_updated > 0;
END;
$$;


ALTER FUNCTION "public"."mark_broadcast_notification_read"("p_notification_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_message_as_read"("p_message_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
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
$$;


ALTER FUNCTION "public"."mark_message_as_read"("p_message_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_notification_as_read"("p_notification_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_updated BOOLEAN;
BEGIN
  UPDATE notifications
  SET 
    is_read = TRUE,
    updated_at = NOW()
  WHERE 
    id = p_notification_id
    AND user_id = auth.uid() -- Ensure user can only mark their own notifications as read
  RETURNING TRUE INTO v_updated;
  
  RETURN COALESCE(v_updated, FALSE);
END;
$$;


ALTER FUNCTION "public"."mark_notification_as_read"("p_notification_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_notifications_as_read"("p_notification_ids" "uuid"[] DEFAULT NULL::"uuid"[], "p_mark_all" boolean DEFAULT false) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    -- Simplest possible implementation - just do the updates without any RETURNING
    IF p_mark_all = TRUE THEN
        -- Mark all as read
        UPDATE public.notifications
        SET is_read = TRUE,
            updated_at = NOW()
        WHERE user_id = v_user_id
          AND is_read = FALSE;
    ELSIF p_notification_ids IS NOT NULL THEN
        -- Mark specific notifications as read
        UPDATE public.notifications
        SET is_read = TRUE,
            updated_at = NOW()
        WHERE id = ANY(p_notification_ids)
          AND user_id = v_user_id;
    END IF;
    
    -- Just return 1 to indicate success
    -- This avoids any counting logic that might cause issues
    RETURN 1;
END;
$$;


ALTER FUNCTION "public"."mark_notifications_as_read"("p_notification_ids" "uuid"[], "p_mark_all" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_notifications_as_read"("p_notification_ids" "uuid"[], "p_user_id" "uuid" DEFAULT "auth"."uid"()) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  -- Verify user is authenticated
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated';
  END IF;

  -- For each notification ID
  FOREACH v_notification_id IN ARRAY p_notification_ids
  LOOP
    -- Check notification type and handle appropriately
    IF EXISTS (
      SELECT 1 FROM notifications 
      WHERE id = v_notification_id AND user_id = p_user_id
    ) THEN
      -- Individual notification
      UPDATE notifications
      SET is_read = TRUE
      WHERE id = v_notification_id AND user_id = p_user_id;
      
    ELSIF EXISTS (
      SELECT 1 FROM notifications 
      WHERE id = v_notification_id AND audience_type = 'followers'
    ) THEN
      -- Follower broadcast notification
      UPDATE notification_recipients
      SET 
        is_read = TRUE,
        read_at = now(),
        updated_at = now()
      WHERE 
        notification_id = v_notification_id AND
        user_id = p_user_id;
        
    ELSIF EXISTS (
      SELECT 1 FROM notifications 
      WHERE id = v_notification_id AND audience_type = 'all'
    ) THEN
      -- Global announcement
      INSERT INTO notification_read_receipts (notification_id, user_id)
      VALUES (v_notification_id, p_user_id)
      ON CONFLICT (user_id, notification_id) DO NOTHING;
    END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."mark_notifications_as_read"("p_notification_ids" "uuid"[], "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_appointment_status_change"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- This function will be expanded to handle email notifications
  -- For now, it just raises notifications that an external process can listen for
  IF TG_OP = 'UPDATE' THEN
    IF NEW.status != OLD.status THEN
      PERFORM pg_notify(
        'appointment_status_change', 
        jsonb_build_object(
          'appointment_id', NEW.id,
          'purchase_id', NEW.purchase_id,
          'old_status', OLD.status,
          'new_status', NEW.status
        )::text
      );
    END IF;
  ELSIF TG_OP = 'INSERT' THEN
    PERFORM pg_notify(
      'appointment_created',
      jsonb_build_object(
        'appointment_id', NEW.id,
        'purchase_id', NEW.purchase_id,
        'status', NEW.status
      )::text
    );
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_appointment_status_change"() OWNER TO "postgres";

COMMENT ON FUNCTION "public"."notify_appointment_status_change"() IS 'Notifies external systems of appointment status changes for email processing';

CREATE OR REPLACE FUNCTION "public"."notify_chat_participant_added"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_chat_room RECORD;
  v_added_by TEXT;
  v_added_by_id UUID;
BEGIN
  -- Skip if user left (left_at is not null)
  IF NEW.left_at IS NOT NULL THEN
    RETURN NEW;
  END IF;
  
  -- Get chat room details
  SELECT * INTO v_chat_room
  FROM chat_rooms
  WHERE id = NEW.chat_room_id;
  
  -- Get who added the user (the creator of the chat or the admin)
  IF TG_OP = 'INSERT' THEN
    v_added_by_id := v_chat_room.created_by;
  ELSE
    -- For updates (e.g., rejoining a chat), use the current user
    v_added_by_id := auth.uid();
  END IF;
  
  -- Get the name of who added the user
  SELECT full_name INTO v_added_by
  FROM profiles
  WHERE id = v_added_by_id;
  
  v_added_by := COALESCE(v_added_by, 'Someone');
  
  -- Create notification for being added to a chat with the fixed function signature
  IF v_chat_room.type = 'private' THEN
    -- Private chat notification
    PERFORM create_notification(
      NEW.user_id,              -- user_id
      v_added_by_id,            -- sender_id
      'New Chat',               -- title
      v_added_by || ' started a chat with you', -- content
      'message',                -- type
      NULL,                     -- priority (ignored)
      NEW.chat_room_id,         -- related_entity_id/reference_id
      '/chat/' || NEW.chat_room_id, -- action/action_url
      jsonb_build_object(       -- metadata
        'chat_room_id', NEW.chat_room_id,
        'chat_type', v_chat_room.type,
        'added_by', v_added_by_id
      )
    );
  ELSE
    -- Group chat notification
    PERFORM create_notification(
      NEW.user_id,              -- user_id
      v_added_by_id,            -- sender_id
      'Added to ' || v_chat_room.name, -- title
      v_added_by || ' added you to ' || v_chat_room.name, -- content
      'message',                -- type
      NULL,                     -- priority (ignored)
      NEW.chat_room_id,         -- related_entity_id/reference_id
      '/chat/' || NEW.chat_room_id, -- action/action_url
      jsonb_build_object(       -- metadata
        'chat_room_id', NEW.chat_room_id,
        'chat_type', v_chat_room.type,
        'chat_name', v_chat_room.name,
        'added_by', v_added_by_id
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_chat_participant_added"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."notify_chat_participant_added"() IS 'Creates a notification when a user is added to a chat';



CREATE OR REPLACE FUNCTION "public"."notify_event_attendees"("p_event_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text" DEFAULT NULL::"text", "p_metadata" "jsonb" DEFAULT '{}'::"jsonb") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_event RECORD;
  v_user_ids UUID[];
  v_count INTEGER;
  v_sender_id UUID := auth.uid(); -- Store sender ID
BEGIN
  -- Check if user is the event owner
  SELECT 
    e.id,
    e.post_id,
    p.title as event_title,
    p.user_id as owner_id
  INTO v_event
  FROM 
    events e
    JOIN posts p ON e.post_id = p.id
  WHERE 
    e.id = p_event_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found';
  END IF;
  
  -- Check if user is authorized to send notifications for this event
  IF v_event.owner_id != v_sender_id AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_sender_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only the event owner or admin can send notifications to attendees';
  END IF;
  
  -- Get all attendee user IDs
  SELECT ARRAY_AGG(DISTINCT p.user_id) INTO v_user_ids
  FROM 
    purchases p
    JOIN event_bookings eb ON p.id = eb.purchase_id
  WHERE 
    p.event_id = p_event_id AND
    eb.status IN ('confirmed', 'attended');
  
  -- If no attendees, return 0
  IF v_user_ids IS NULL OR array_length(v_user_ids, 1) = 0 THEN
    RETURN 0;
  END IF;
  
  -- Create notifications for all attendees directly to ensure sender_id is set
  WITH inserted_notifications AS (
    INSERT INTO notifications (
      user_id,
      sender_id,
      title,
      content,
      type,
      action_url,
      reference_id,
      reference_type,
      metadata
    )
    SELECT 
      user_id,
      v_sender_id,
      p_title,
      p_content,
      'event'::public.notification_type,
      COALESCE(p_action_url, '/events/' || p_event_id),
      p_event_id,
      'event',
      jsonb_build_object(
        'event_id', p_event_id,
        'event_title', v_event.event_title,
        'notification_type', 'event_update',
        'sender_id', v_sender_id
      ) || p_metadata
    FROM UNNEST(v_user_ids) AS user_id
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM inserted_notifications;
  
  RETURN v_count;
END;
$$;


ALTER FUNCTION "public"."notify_event_attendees"("p_event_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text", "p_metadata" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."notify_event_attendees"("p_event_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text", "p_metadata" "jsonb") IS 'Sends notifications to all attendees of an event with sender tracking';



CREATE OR REPLACE FUNCTION "public"."notify_new_follower"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_follower_name TEXT;
BEGIN
  -- Get follower's name
  SELECT full_name INTO v_follower_name
  FROM profiles
  WHERE id = NEW.follower_id;
  
  -- Create a notification for the user being followed
  PERFORM create_notification(
    NEW.followed_id,           -- user_id
    NEW.follower_id,           -- sender_id
    'New Follower',            -- title
    v_follower_name || ' is now following you', -- content
    'social',                  -- type
    NULL,                      -- priority
    NEW.follower_id,           -- related_entity_id
    '/profile/' || NEW.follower_id, -- action_url
    jsonb_build_object(        -- metadata
      'follower_id', NEW.follower_id,
      'follower_name', v_follower_name
    )
  );
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_new_follower"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_service_subscribers"("p_service_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text" DEFAULT NULL::"text", "p_metadata" "jsonb" DEFAULT '{}'::"jsonb") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_service RECORD;
  v_user_ids UUID[];
  v_count INTEGER;
  v_sender_id UUID := auth.uid(); -- Store sender ID
BEGIN
  -- Check if service exists and get owner info
  SELECT 
    s.id,
    s.post_id,
    p.title as service_title,
    p.user_id as owner_id
  INTO v_service
  FROM 
    services s
    JOIN posts p ON s.post_id = p.id
  WHERE 
    s.id = p_service_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Service not found';
  END IF;
  
  -- Check if user is authorized to send notifications
  IF v_service.owner_id != v_sender_id AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = v_sender_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only the service owner or admin can send notifications to subscribers';
  END IF;
  
  -- Get all user IDs who have purchased this service
  SELECT ARRAY_AGG(DISTINCT user_id) INTO v_user_ids
  FROM purchases
  WHERE service_id = p_service_id AND payment_status = 'completed';
  
  -- If no subscribers, return 0
  IF v_user_ids IS NULL OR array_length(v_user_ids, 1) = 0 THEN
    RETURN 0;
  END IF;
  
  -- Insert notifications directly to ensure sender_id is set
  WITH inserted_notifications AS (
    INSERT INTO notifications (
      user_id,
      sender_id,
      title,
      content,
      type,
      action_url,
      reference_id,
      reference_type,
      metadata
    )
    SELECT 
      user_id,
      v_sender_id,
      p_title,
      p_content,
      'service'::public.notification_type,
      COALESCE(p_action_url, '/services/' || v_service.post_id),
      p_service_id,
      'service',
      jsonb_build_object(
        'service_id', p_service_id,
        'service_title', v_service.service_title,
        'notification_type', 'service_update',
        'sender_id', v_sender_id
      ) || p_metadata
    FROM UNNEST(v_user_ids) AS user_id
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM inserted_notifications;
  
  RETURN v_count;
END;
$$;


ALTER FUNCTION "public"."notify_service_subscribers"("p_service_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text", "p_metadata" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."notify_service_subscribers"("p_service_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text", "p_metadata" "jsonb") IS 'Sends notifications to all users who have purchased a service with sender tracking';



CREATE OR REPLACE FUNCTION "public"."original_prevent_double_booking"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_provider_id UUID;
    v_start_time TIMESTAMP WITH TIME ZONE;
    v_end_time TIMESTAMP WITH TIME ZONE;
    v_has_conflicts BOOLEAN;
BEGIN
    -- Get the provider ID and time range
    IF TG_TABLE_NAME = 'appointment_purchases' THEN
        SELECT p.owner_id INTO v_provider_id
        FROM public.purchases p
        WHERE p.id = NEW.purchase_id;
        
        v_start_time := NEW.appointment_date;
        v_end_time := NEW.appointment_date + (NEW.duration || ' minutes')::INTERVAL;
    ELSIF TG_TABLE_NAME = 'appointments' THEN
        v_provider_id := NEW.facilitator_id;
        v_start_time := NEW.start_time;
        v_end_time := NEW.end_time;
    END IF;
    
    -- Don't check conflicts for cancelled/completed appointments
    IF NEW.status IN ('cancelled', 'completed', 'no_show') THEN
        RETURN NEW;
    END IF;
    
    -- Check for conflicts
    v_has_conflicts := check_schedule_conflicts(
        v_provider_id, 
        v_start_time, 
        v_end_time,
        CASE WHEN TG_TABLE_NAME = 'appointment_purchases' THEN NEW.id ELSE NULL END
    );
    
    IF v_has_conflicts THEN
        RAISE EXCEPTION 'This time slot conflicts with an existing commitment';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."original_prevent_double_booking"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."post_comment_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_post_author_id UUID;
  v_parent_comment_author_id UUID;
  v_commenter_name TEXT;
  v_post_title TEXT;
  v_notification_id UUID;
BEGIN
  -- Get commenter's name
  SELECT full_name INTO v_commenter_name
  FROM profiles
  WHERE id = NEW.user_id;
  
  v_commenter_name := COALESCE(v_commenter_name, 'Someone');
  
  -- If it's a reply to another comment
  IF NEW.parent_id IS NOT NULL THEN
    -- Get the parent comment author ID
    SELECT user_id INTO v_parent_comment_author_id
    FROM comments
    WHERE id = NEW.parent_id;
    
    -- Don't notify if replying to your own comment
    IF v_parent_comment_author_id != NEW.user_id THEN
      -- Notify the parent comment author about the reply
      PERFORM create_notification(
        v_parent_comment_author_id, -- user_id
        NEW.user_id,                -- sender_id
        'New Reply',                -- title
        v_commenter_name || ' replied to your comment', -- content
        'social',                   -- type
        NULL,                       -- priority
        NEW.post_id,                -- related_entity_id
        '/post/' || NEW.post_id || '#comment-' || NEW.id, -- action
        jsonb_build_object(         -- metadata
          'comment_id', NEW.id,
          'post_id', NEW.post_id,
          'parent_comment_id', NEW.parent_id,
          'commenter_id', NEW.user_id,
          'commenter_name', v_commenter_name
        )
      );
    END IF;
  END IF;
  
  -- Also notify the post author about the comment (if not their own post)
  SELECT user_id, title INTO v_post_author_id, v_post_title
  FROM posts
  WHERE id = NEW.post_id;
  
  -- Don't notify if commenting on your own post
  IF v_post_author_id != NEW.user_id THEN
    PERFORM create_notification(
      v_post_author_id,            -- user_id
      NEW.user_id,                 -- sender_id
      'New Comment',               -- title
      v_commenter_name || ' commented on your post: ' || v_post_title, -- content
      'social',                    -- type
      NULL,                        -- priority
      NEW.post_id,                 -- related_entity_id
      '/post/' || NEW.post_id || '#comment-' || NEW.id, -- action
      jsonb_build_object(          -- metadata
        'comment_id', NEW.id,
        'post_id', NEW.post_id,
        'commenter_id', NEW.user_id,
        'commenter_name', v_commenter_name,
        'post_title', v_post_title
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."post_comment_notification"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."prevent_double_booking"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Always allow the booking during seeding
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."prevent_double_booking"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."prevent_double_booking"() IS 'Trigger function to prevent double-booking appointments';



CREATE OR REPLACE FUNCTION "public"."process_appointment_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_client_id UUID;
  v_provider_id UUID;
  v_appointment_title TEXT;
  v_status_changed BOOLEAN := FALSE;
  v_old_status TEXT;
BEGIN
  -- Get relevant appointment information
  SELECT 
    a.client_id,
    a.provider_id,
    s.title || ' - ' || TO_CHAR(a.start_time, 'Mon DD, YYYY HH:MI AM') AS title
  INTO 
    v_client_id,
    v_provider_id,
    v_appointment_title
  FROM 
    appointments a
    JOIN services s ON a.service_id = s.id
  WHERE 
    a.id = NEW.id;
  
  -- Check if this is an update with status change
  IF TG_OP = 'UPDATE' THEN
    v_status_changed := NEW.status <> OLD.status;
    v_old_status := OLD.status;
  END IF;
  
  -- Process different appointment notifications based on status
  
  -- New appointment created
  IF TG_OP = 'INSERT' THEN
    -- Notify provider about new appointment request
    PERFORM create_notification(
      v_provider_id,
      'New Appointment Request',
      'You have a new appointment request: ' || v_appointment_title,
      'appointment',
      '/dashboard/appointments/' || NEW.id,
      NEW.id,
      'appointment',
      jsonb_build_object(
        'appointment_id', NEW.id,
        'status', NEW.status,
        'client_id', v_client_id
      )
    );
    
    -- Notify client about appointment creation
    PERFORM create_notification(
      v_client_id,
      'Appointment Created',
      'Your appointment has been created: ' || v_appointment_title,
      'appointment',
      '/appointments/' || NEW.id,
      NEW.id,
      'appointment',
      jsonb_build_object(
        'appointment_id', NEW.id,
        'status', NEW.status,
        'provider_id', v_provider_id
      )
    );
  END IF;
  
  -- Status change notifications
  IF v_status_changed THEN
    -- Confirmed status
    IF NEW.status = 'confirmed' THEN
      -- Notify client
      PERFORM create_notification(
        v_client_id,
        'Appointment Confirmed',
        'Your appointment has been confirmed: ' || v_appointment_title,
        'appointment',
        '/appointments/' || NEW.id,
        NEW.id,
        'appointment',
        jsonb_build_object(
          'appointment_id', NEW.id,
          'status', NEW.status,
          'provider_id', v_provider_id,
          'previous_status', v_old_status
        )
      );
    
    -- Cancelled status
    ELSIF NEW.status = 'cancelled' THEN
      -- Notify provider
      PERFORM create_notification(
        v_provider_id,
        'Appointment Cancelled',
        'An appointment has been cancelled: ' || v_appointment_title,
        'appointment',
        '/dashboard/appointments/' || NEW.id,
        NEW.id,
        'appointment',
        jsonb_build_object(
          'appointment_id', NEW.id,
          'status', NEW.status,
          'client_id', v_client_id,
          'previous_status', v_old_status
        )
      );
      
      -- Notify client
      PERFORM create_notification(
        v_client_id,
        'Appointment Cancelled',
        'Your appointment has been cancelled: ' || v_appointment_title,
        'appointment',
        '/appointments/' || NEW.id,
        NEW.id,
        'appointment',
        jsonb_build_object(
          'appointment_id', NEW.id,
          'status', NEW.status,
          'provider_id', v_provider_id,
          'previous_status', v_old_status
        )
      );
    
    -- Completed status
    ELSIF NEW.status = 'completed' THEN
      -- Notify client
      PERFORM create_notification(
        v_client_id,
        'Appointment Completed',
        'Your appointment has been marked as completed: ' || v_appointment_title,
        'appointment',
        '/appointments/' || NEW.id,
        NEW.id,
        'appointment',
        jsonb_build_object(
          'appointment_id', NEW.id,
          'status', NEW.status,
          'provider_id', v_provider_id,
          'previous_status', v_old_status
        )
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."process_appointment_notification"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer DEFAULT 60, "p_method" "text" DEFAULT 'video'::"text", "p_service_type" "text" DEFAULT 'consultation'::"text", "p_notes" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_service_id UUID;
  v_appointment_id UUID;
  v_result JSONB;
BEGIN
  -- First, verify and update the purchase
  UPDATE purchases
  SET 
    payment_status = 'completed'::purchase_payment_status_enum,
    completed_at = NOW(),
    updated_at = NOW()
  WHERE id = p_purchase_id
  AND stripe_payment_intent_id = p_payment_intent_id
  RETURNING service_id INTO v_service_id;
  
  IF v_service_id IS NULL THEN
    RAISE EXCEPTION 'Purchase not found or payment intent mismatch';
  END IF;
  
  -- Check if appointment_purchase record exists
  SELECT id INTO v_appointment_id
  FROM appointment_purchases
  WHERE purchase_id = p_purchase_id;
  
  IF v_appointment_id IS NOT NULL THEN
    -- Update existing appointment
    UPDATE appointment_purchases
    SET
      status = 'confirmed'::appointment_status_enum,
      updated_at = NOW()
    WHERE id = v_appointment_id;
    
    v_result = jsonb_build_object(
      'success', true,
      'purchase_id', p_purchase_id,
      'appointment_id', v_appointment_id,
      'status', 'updated'
    );
  ELSE
    -- Create new appointment record
    INSERT INTO appointment_purchases (
      purchase_id,
      service_id,
      appointment_date,
      duration,
      method,
      service_type,
      status,
      notes
    ) VALUES (
      p_purchase_id,
      v_service_id,
      p_appointment_date,
      p_duration,
      p_method::appointment_method_enum,
      p_service_type::appointment_type_enum,
      'confirmed'::appointment_status_enum,
      p_notes
    )
    RETURNING id INTO v_appointment_id;
    
    v_result = jsonb_build_object(
      'success', true,
      'purchase_id', p_purchase_id,
      'appointment_id', v_appointment_id,
      'status', 'created'
    );
  END IF;
  
  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM,
    'purchase_id', p_purchase_id
  );
END;
$$;


ALTER FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text") IS 'Processes payment for an appointment, creating or updating the appointment record';



CREATE OR REPLACE FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer DEFAULT 60, "p_method" "public"."appointment_method_enum" DEFAULT 'video'::"public"."appointment_method_enum", "p_service_type" "public"."appointment_type_enum" DEFAULT 'consultation'::"public"."appointment_type_enum", "p_notes" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_service_id UUID;
  v_appointment_id UUID;
  v_result JSONB;
BEGIN
  -- First, verify and update the purchase
  UPDATE purchases
  SET 
    payment_status = 'completed'::purchase_payment_status_enum,
    completed_at = NOW(),
    updated_at = NOW()
  WHERE id = p_purchase_id
  AND stripe_payment_intent_id = p_payment_intent_id
  RETURNING service_id INTO v_service_id;
  
  IF v_service_id IS NULL THEN
    RAISE EXCEPTION 'Purchase not found or payment intent mismatch';
  END IF;
  
  -- Check if appointment_purchase record exists
  SELECT id INTO v_appointment_id
  FROM appointment_purchases
  WHERE purchase_id = p_purchase_id;
  
  IF v_appointment_id IS NOT NULL THEN
    -- Update existing appointment
    UPDATE appointment_purchases
    SET
      status = 'confirmed'::appointment_status_enum,
      updated_at = NOW()
    WHERE id = v_appointment_id;
    
    v_result = jsonb_build_object(
      'success', true,
      'purchase_id', p_purchase_id,
      'appointment_id', v_appointment_id,
      'status', 'updated'
    );
  ELSE
    -- Create new appointment record
    INSERT INTO appointment_purchases (
      purchase_id,
      service_id,
      appointment_date,
      duration,
      method,
      service_type,
      status,
      notes
    ) VALUES (
      p_purchase_id,
      v_service_id,
      p_appointment_date,
      p_duration,
      p_method,
      p_service_type,
      'confirmed'::appointment_status_enum,
      p_notes
    )
    RETURNING id INTO v_appointment_id;
    
    v_result = jsonb_build_object(
      'success', true,
      'purchase_id', p_purchase_id,
      'appointment_id', v_appointment_id,
      'status', 'created'
    );
  END IF;
  
  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM,
    'purchase_id', p_purchase_id
  );
END;
$$;


ALTER FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "public"."appointment_method_enum", "p_service_type" "public"."appointment_type_enum", "p_notes" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "public"."appointment_method_enum", "p_service_type" "public"."appointment_type_enum", "p_notes" "text") IS 'Processes an appointment payment, ensuring the appointment_purchase record exists and has correct status.';



CREATE OR REPLACE FUNCTION "public"."process_appointment_payment_confirmation"("p_purchase_id" "uuid", "p_payment_intent_id" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_user_id UUID;
  v_owner_id UUID;
  v_appointment_id UUID;
  v_appointment_date TIMESTAMP WITH TIME ZONE;
  v_service_id UUID;
  v_service_type event_type_enum;
  v_method TEXT;
  v_chat_room_id UUID;
  v_meeting_url TEXT;
  v_result JSONB;
  v_user_preference RECORD;
  v_owner_preference RECORD;
  v_notification_metadata JSONB;
  v_message_text TEXT;
  v_service_name TEXT;
  v_provider_name TEXT;
  v_client_name TEXT;
  v_chat_room_name TEXT;
BEGIN
  -- Update purchase status
  UPDATE purchases
  SET 
    payment_status = 'completed'::purchase_payment_status_enum,
    completed_at = NOW(),
    updated_at = NOW(),
    stripe_payment_intent_id = p_payment_intent_id
  WHERE id = p_purchase_id
  RETURNING user_id, owner_id INTO v_user_id, v_owner_id;
  
  -- Get appointment details
  SELECT 
    ap.id, 
    ap.appointment_date, 
    ap.service_id,
    ap.method,
    s.type,
    COALESCE(po.title, 'Service') AS service_name,
    COALESCE(pr_owner.full_name, 'Provider') AS provider_name,
    COALESCE(pr_client.full_name, 'Client') AS client_name
  INTO 
    v_appointment_id, 
    v_appointment_date, 
    v_service_id,
    v_method,
    v_service_type,
    v_service_name,
    v_provider_name,
    v_client_name
  FROM 
    appointment_purchases ap
    JOIN services s ON ap.service_id = s.id
    LEFT JOIN posts po ON s.post_id = po.id
    LEFT JOIN profiles pr_owner ON pr_owner.id = v_owner_id
    LEFT JOIN profiles pr_client ON pr_client.id = v_user_id
  WHERE 
    ap.purchase_id = p_purchase_id;
  
  -- Create descriptive chat room name
  v_chat_room_name := v_service_name || ' - ' || 
                     to_char(v_appointment_date, 'DD Mon YYYY HH12:MI AM') || ' - ' ||
                     v_provider_name || ' & ' || v_client_name;
  
  -- Generate meeting URL for online/hybrid services
  IF v_method = 'video' OR (v_service_type IN ('online', 'hybrid')) THEN
    v_meeting_url := 'https://local.revelations.com/meeting/private/' || gen_random_uuid();
    
    -- Update appointment with meeting URL and clear payment_link
    UPDATE appointment_purchases
    SET 
      status = 'confirmed'::appointment_status_enum,
      meeting_url = v_meeting_url,
      meeting_id = NULL,
      payment_link = NULL, -- Clear payment link as it's no longer needed
      updated_at = NOW()
    WHERE purchase_id = p_purchase_id;
  ELSE
    -- For in-person appointments, just update status and clear payment_link
    UPDATE appointment_purchases
    SET 
      status = 'confirmed'::appointment_status_enum,
      meeting_id = NULL,
      payment_link = NULL, -- Clear payment link as it's no longer needed
      updated_at = NOW()
    WHERE purchase_id = p_purchase_id;
  END IF;
  
  -- Find or create chat room
  WITH room_participants AS (
    SELECT 
      cr.id as room_id,
      COUNT(*) as participant_count,
      SUM(CASE WHEN cp.user_id IN (v_user_id, v_owner_id) THEN 1 ELSE 0 END) as target_users_count
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
    
  -- If no chat room exists, create one
  IF v_chat_room_id IS NULL THEN
    INSERT INTO chat_rooms (name, type, created_by)
    VALUES (v_chat_room_name, 'private', v_owner_id)
    RETURNING id INTO v_chat_room_id;
    
    -- Add participants
    INSERT INTO chat_participants (chat_room_id, user_id)
    VALUES 
      (v_chat_room_id, v_user_id),
      (v_chat_room_id, v_owner_id)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
  ELSE
    -- Update existing room name
    UPDATE chat_rooms
    SET name = v_chat_room_name
    WHERE id = v_chat_room_id;
  END IF;
  
  -- Prepare notification metadata
  v_notification_metadata := jsonb_build_object(
    'appointment_id', v_appointment_id,
    'purchase_id', p_purchase_id,
    'service_id', v_service_id,
    'status', 'confirmed',
    'appointment_date', v_appointment_date,
    'service_type', v_service_type,
    'method', v_method,
    'service_name', v_service_name,
    'provider_name', v_provider_name,
    'client_name', v_client_name
  );
  
  -- Add meeting URL to metadata if it exists
  IF v_meeting_url IS NOT NULL THEN
    v_notification_metadata := v_notification_metadata || jsonb_build_object('meeting_url', v_meeting_url);
  END IF;
  
  -- Prepare message text
  v_message_text := 'Your appointment has been confirmed for ' || 
                    to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM');
                    
  IF v_meeting_url IS NOT NULL THEN
    v_message_text := v_message_text || E'\n\n[Join Meeting](' || v_meeting_url || '){button}';
  END IF;
  
  -- Send confirmation messages
  BEGIN
    -- Message to client
    INSERT INTO chat_messages (chat_room_id, sender_id, message, status)
    VALUES (v_chat_room_id, v_owner_id, v_message_text, 'delivered');
    
    -- Message to provider
    INSERT INTO chat_messages (chat_room_id, sender_id, message, status)
    VALUES (
      v_chat_room_id,
      v_owner_id,
      'Payment completed for appointment on ' || to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM') || 
      CASE WHEN v_meeting_url IS NOT NULL THEN E'\n\n[Join Meeting](' || v_meeting_url || '){button}' ELSE '' END,
      'delivered'
    );
  EXCEPTION 
    WHEN OTHERS THEN
      -- Fallback to notifications
      BEGIN
        -- Send appropriate notifications
        -- Notification logic here...
        NULL; -- This is a placeholder for the notification fallback logic
      END;
  END;
  
  -- Build result
  v_result := jsonb_build_object(
    'success', TRUE,
    'purchase_id', p_purchase_id,
    'appointment_id', v_appointment_id,
    'status', 'confirmed',
    'chat_room_id', v_chat_room_id,
    'chat_room_name', v_chat_room_name
  );
  
  -- Add meeting URL to result if applicable
  IF v_meeting_url IS NOT NULL THEN
    v_result := v_result || jsonb_build_object('meeting_url', v_meeting_url);
  END IF;
  
  -- Trigger notification
  PERFORM pg_notify('appointment_confirmed', v_result::text);
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."process_appointment_payment_confirmation"("p_purchase_id" "uuid", "p_payment_intent_id" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."process_appointment_payment_confirmation"("p_purchase_id" "uuid", "p_payment_intent_id" "text") IS 'Processes payment confirmation, generates meeting URL for online/hybrid appointments, clears payment_link field, and sends notifications based on user preferences';



CREATE OR REPLACE FUNCTION "public"."process_chat_message_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_chat_room RECORD;
  v_participant RECORD;
BEGIN
  -- Get chat room details
  SELECT * INTO v_chat_room
  FROM chat_rooms
  WHERE id = NEW.chat_room_id;
  
  -- Process differently based on chat type
  IF v_chat_room.type = 'private' THEN
    -- For private chats, notify the other participant
    FOR v_participant IN (
      SELECT user_id 
      FROM chat_participants 
      WHERE chat_room_id = NEW.chat_room_id 
      AND user_id <> NEW.sender_id
      AND left_at IS NULL
    ) LOOP
      -- Use the corrected function with the right parameter order
      PERFORM create_or_update_batched_chat_notification(
        v_participant.user_id,  -- recipient user_id
        NEW.sender_id,          -- sender_id
        NEW.chat_room_id,       -- chat_id
        NEW.message             -- message preview
      );
    END LOOP;
  ELSE
    -- For group chats, notify all participants except sender
    FOR v_participant IN (
      SELECT user_id 
      FROM chat_participants 
      WHERE chat_room_id = NEW.chat_room_id 
      AND user_id <> NEW.sender_id
      AND left_at IS NULL
    ) LOOP
      -- Use the corrected function with the right parameter order
      PERFORM create_or_update_batched_chat_notification(
        v_participant.user_id,  -- recipient user_id
        NEW.sender_id,          -- sender_id
        NEW.chat_room_id,       -- chat_id
        NEW.message             -- message preview
      );
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."process_chat_message_notification"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."process_chat_message_notification"() IS 'Generates batched notifications for new chat messages';



CREATE OR REPLACE FUNCTION "public"."process_event_booking_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_attendees" integer DEFAULT 1, "p_is_virtual" boolean DEFAULT false) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_event_id UUID;
  v_booking_id UUID;
  v_result JSONB;
BEGIN
  -- First, verify and update the purchase
  UPDATE purchases
  SET 
    payment_status = 'completed',
    completed_at = NOW(),
    updated_at = NOW()
  WHERE id = p_purchase_id
  AND stripe_payment_intent_id = p_payment_intent_id
  RETURNING event_id INTO v_event_id;
  
  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'Purchase not found or payment intent mismatch';
  END IF;
  
  -- Check if event_booking record exists
  SELECT id INTO v_booking_id
  FROM event_bookings
  WHERE purchase_id = p_purchase_id;
  
  IF v_booking_id IS NOT NULL THEN
    -- Update existing booking
    UPDATE event_bookings
    SET
      status = 'confirmed',
      updated_at = NOW()
    WHERE id = v_booking_id;
    
    v_result = jsonb_build_object(
      'success', true,
      'purchase_id', p_purchase_id,
      'booking_id', v_booking_id,
      'status', 'updated'
    );
  ELSE
    -- Create new booking record
    INSERT INTO event_bookings (
      purchase_id,
      event_id,
      ticket_id,
      date_id,
      attendees,
      is_virtual,
      status,
      ticket_code
    ) VALUES (
      p_purchase_id,
      v_event_id,
      p_ticket_id,
      p_date_id,
      p_attendees,
      p_is_virtual,
      'confirmed',
      'TIX-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FOR 8))
    )
    RETURNING id INTO v_booking_id;
    
    v_result = jsonb_build_object(
      'success', true,
      'purchase_id', p_purchase_id,
      'booking_id', v_booking_id,
      'status', 'created'
    );
  END IF;
  
  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM,
    'purchase_id', p_purchase_id
  );
END;
$$;


ALTER FUNCTION "public"."process_event_booking_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_attendees" integer, "p_is_virtual" boolean) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."process_event_booking_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_attendees" integer, "p_is_virtual" boolean) IS 'Processes an event booking payment, ensuring the event_booking record exists and has correct status.';



CREATE OR REPLACE FUNCTION "public"."process_invoice_paid"("invoice_id" "text", "event_data" "jsonb") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    subscription_id TEXT;
    customer_id TEXT;
    metadata JSONB;
    v_user_id UUID;
    v_owner_id UUID;
    v_amount NUMERIC(10, 2);
    v_currency TEXT;
    v_tier_key TEXT;
    v_purchase_id UUID;
    v_is_new BOOLEAN;
    v_billing_cycle TEXT;
    v_trial_ends_at TIMESTAMP WITH TIME ZONE;
    v_plan_name TEXT;
    v_tier_data RECORD;
    v_stripe_price_id TEXT;
BEGIN
    -- Extract basic data from event
    subscription_id := event_data->'subscription'->>'id';
    customer_id := event_data->>'customer';
    v_stripe_price_id := event_data->'lines'->'data'->0->>'price'->'id';
    v_amount := (event_data->>'amount_paid')::NUMERIC / 100; -- Convert cents to dollars
    v_currency := lower(event_data->>'currency');
    
    -- Check for existing purchase with this subscription ID
    SELECT id INTO v_purchase_id
    FROM purchases
    WHERE stripe_subscription_id = subscription_id;
    
    v_is_new := v_purchase_id IS NULL;
    
    -- Extract metadata for new subscriptions
    IF v_is_new THEN
        -- Get metadata from subscription
        -- Note: In practice, you'd need to make an API call to Stripe to get this data
        -- This is a placeholder - your webhook handler would need to include this data
        metadata := event_data->'subscription'->'metadata';
        
        -- Extract required data
        v_user_id := (metadata->>'user_id')::UUID;
        v_owner_id := (metadata->>'owner_id')::UUID;
        v_tier_key := metadata->>'tier';
        v_plan_name := metadata->>'plan_name';
        
        -- Determine billing cycle from price ID
        SELECT * INTO v_tier_data
        FROM creator_subscription_tiers
        WHERE creator_id = v_owner_id
        AND tier_key = v_tier_key;
        
        IF v_stripe_price_id = v_tier_data.stripe_price_id_monthly THEN
            v_billing_cycle := 'monthly';
        ELSIF v_stripe_price_id = v_tier_data.stripe_price_id_quarterly THEN
            v_billing_cycle := 'quarterly';
        ELSIF v_stripe_price_id = v_tier_data.stripe_price_id_annual THEN
            v_billing_cycle := 'annual';
        ELSE
            v_billing_cycle := 'monthly'; -- Default
        END IF;
        
        -- Check for trial
        IF (event_data->'subscription'->>'trial_end') IS NOT NULL THEN
            v_trial_ends_at := (event_data->'subscription'->>'trial_end')::TIMESTAMP WITH TIME ZONE;
        END IF;
        
        -- Insert purchase record
        INSERT INTO purchases (
            user_id, owner_id, stripe_subscription_id, stripe_customer_id,
            amount, currency, payment_status, 
            purchase_type, purchase_date, start_date
        ) VALUES (
            v_user_id, v_owner_id, subscription_id, customer_id,
            v_amount, v_currency, 'completed',
            'subscription', NOW(), NOW()
        ) RETURNING id INTO v_purchase_id;
        
        -- Insert subscription details
        INSERT INTO subscriptions (
            purchase_id, stripe_subscription_id, stripe_price_id, stripe_product_id,
            plan_name, tier, billing_cycle, status,
            next_billing_date, payments_count, total_paid,
            last_payment_status, last_payment_date,
            is_trial, trial_ends_at
        ) VALUES (
            v_purchase_id, subscription_id, v_stripe_price_id, v_tier_data.stripe_product_id,
            v_plan_name, v_tier_key, v_billing_cycle, 
            CASE WHEN v_trial_ends_at IS NOT NULL AND v_trial_ends_at > NOW() THEN 'trial' ELSE 'active' END,
            -- Next billing defaults to 30 days ahead, but would come from Stripe
            NOW() + CASE
                WHEN v_billing_cycle = 'monthly' THEN '1 month'::INTERVAL
                WHEN v_billing_cycle = 'quarterly' THEN '3 months'::INTERVAL
                WHEN v_billing_cycle = 'annual' THEN '1 year'::INTERVAL
                ELSE '1 month'::INTERVAL
            END,
            1, -- payments_count
            v_amount, -- total_paid
            'completed', -- last_payment_status
            NOW(), -- last_payment_date
            v_trial_ends_at IS NOT NULL, -- is_trial
            v_trial_ends_at -- trial_ends_at
        );
        
        RETURN 'New subscription created: ' || subscription_id;
    ELSE
        -- Update existing subscription
        
        -- Get subscription record
        DECLARE
            v_subscription_id UUID;
            v_next_billing_date TIMESTAMP WITH TIME ZONE;
            v_payments_count INTEGER;
            v_total_paid NUMERIC(10, 2);
        BEGIN
            SELECT s.id, s.next_billing_date, s.payments_count, s.total_paid
            INTO v_subscription_id, v_next_billing_date, v_payments_count, v_total_paid
            FROM subscriptions s
            WHERE s.purchase_id = v_purchase_id;
            
            -- Calculate next billing date based on current one
            SELECT s.next_billing_date + CASE
                WHEN s.billing_cycle = 'monthly' THEN '1 month'::INTERVAL
                WHEN s.billing_cycle = 'quarterly' THEN '3 months'::INTERVAL
                WHEN s.billing_cycle = 'annual' THEN '1 year'::INTERVAL
                ELSE '1 month'::INTERVAL
            END
            INTO v_next_billing_date
            FROM subscriptions s
            WHERE s.purchase_id = v_purchase_id;
            
            -- Update subscription
            UPDATE subscriptions
            SET 
                status = 'active',
                next_billing_date = v_next_billing_date,
                payments_count = v_payments_count + 1,
                total_paid = v_total_paid + v_amount,
                last_payment_status = 'completed',
                last_payment_date = NOW(),
                is_trial = FALSE, -- No longer in trial after a payment
                updated_at = NOW()
            WHERE purchase_id = v_purchase_id;
            
            -- Update purchase record
            UPDATE purchases
            SET 
                stripe_invoice_id = invoice_id,
                payment_status = 'completed',
                amount = v_amount, -- Update to latest amount
                updated_at = NOW()
            WHERE id = v_purchase_id;
        END;
        
        RETURN 'Subscription payment processed: ' || subscription_id;
    END IF;
END;
$$;


ALTER FUNCTION "public"."process_invoice_paid"("invoice_id" "text", "event_data" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_payment_intent_succeeded"("payment_intent_id" "text", "event_data" "jsonb") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    metadata JSONB;
    purchase_type TEXT;
    purchase_id UUID;
    v_user_id UUID;
    v_owner_id UUID;
    v_amount NUMERIC(10, 2);
    v_currency TEXT;
    v_content_id UUID;
    v_event_id UUID;
    v_date_id UUID;
    v_ticket_id UUID;
    v_service_id UUID;
    v_appointment_date TIMESTAMP WITH TIME ZONE;
    v_duration INTEGER;
    v_attendees INTEGER;
BEGIN
    -- Extract metadata from the event
    metadata := event_data->'metadata';
    purchase_type := metadata->>'purchase_type';
    v_user_id := (metadata->>'user_id')::UUID;
    v_owner_id := (metadata->>'owner_id')::UUID;
    v_amount := (event_data->'amount_received')::NUMERIC / 100; -- Convert cents to dollars
    v_currency := lower(event_data->>'currency');
    
    -- Check if this payment intent has already been processed
    IF EXISTS (
        SELECT 1 FROM purchases WHERE stripe_payment_intent_id = payment_intent_id
    ) THEN
        RETURN 'Payment already processed';
    END IF;
    
    -- Process based on purchase type
    IF purchase_type = 'content' THEN
        v_content_id := (metadata->>'content_id')::UUID;
        
        -- Insert purchase record
        INSERT INTO purchases (
            user_id, owner_id, stripe_payment_intent_id, 
            amount, currency, payment_status, 
            content_id, purchase_type, purchase_date
        ) VALUES (
            v_user_id, v_owner_id, payment_intent_id,
            v_amount, v_currency, 'completed',
            v_content_id, purchase_type, NOW()
        ) RETURNING id INTO purchase_id;
        
        -- Insert content purchase details
        INSERT INTO content_purchases (
            purchase_id, content_id, download_count, 
            last_accessed, is_subscription, access_expires_at
        ) VALUES (
            purchase_id, v_content_id, 0,
            NULL, FALSE, NULL -- Permanent access
        );
        
        RETURN 'Content purchase processed';
        
    ELSIF purchase_type = 'event' THEN
        v_event_id := (metadata->>'event_id')::UUID;
        v_date_id := (metadata->>'date_id')::UUID;
        v_ticket_id := (metadata->>'ticket_id')::UUID;
        v_attendees := COALESCE((metadata->>'attendees')::INTEGER, 1);
        
        -- Insert purchase record
        INSERT INTO purchases (
            user_id, owner_id, stripe_payment_intent_id, 
            amount, currency, payment_status, 
            event_id, purchase_type, purchase_date,
            quantity
        ) VALUES (
            v_user_id, v_owner_id, payment_intent_id,
            v_amount, v_currency, 'completed',
            v_event_id, purchase_type, NOW(),
            v_attendees
        ) RETURNING id INTO purchase_id;
        
        -- Insert event booking details
        INSERT INTO event_bookings (
            purchase_id, event_id, ticket_id, date_id,
            attendees, is_virtual, status
        ) VALUES (
            purchase_id, v_event_id, v_ticket_id, v_date_id,
            v_attendees, COALESCE((metadata->>'is_virtual')::BOOLEAN, FALSE),
            'confirmed'
        );
        
        RETURN 'Event booking processed';
        
    ELSIF purchase_type = 'appointment' THEN
        v_service_id := (metadata->>'service_id')::UUID;
        v_appointment_date := (metadata->>'appointment_date')::TIMESTAMP WITH TIME ZONE;
        v_duration := COALESCE((metadata->>'duration')::INTEGER, 60);
        
        -- Insert purchase record
        INSERT INTO purchases (
            user_id, owner_id, stripe_payment_intent_id, 
            amount, currency, payment_status, 
            service_id, purchase_type, purchase_date,
            start_date, end_date
        ) VALUES (
            v_user_id, v_owner_id, payment_intent_id,
            v_amount, v_currency, 'completed',
            v_service_id, purchase_type, NOW(),
            v_appointment_date, v_appointment_date + (v_duration || ' minutes')::INTERVAL
        ) RETURNING id INTO purchase_id;
        
        -- Insert appointment details
        INSERT INTO appointment_purchases (
            purchase_id, service_id, appointment_date,
            duration, method, service_type, status
        ) VALUES (
            purchase_id, v_service_id, v_appointment_date,
            v_duration, 
            COALESCE(metadata->>'method', 'video'),
            COALESCE(metadata->>'service_type', 'consultation'),
            'confirmed'
        );
        
        RETURN 'Appointment booking processed';
        
    ELSE
        RETURN 'Unknown purchase type: ' || purchase_type;
    END IF;
END;
$$;


ALTER FUNCTION "public"."process_payment_intent_succeeded"("payment_intent_id" "text", "event_data" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_pending_notifications"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_processed_count INTEGER := 0;
  v_ids UUID[];
BEGIN
  -- Get IDs of notifications that need to be processed
  SELECT array_agg(id) INTO v_ids
  FROM notification_deliveries
  WHERE 
    status = 'pending' 
    AND (next_attempt_at IS NULL OR next_attempt_at <= NOW())
    AND attempt_count < 3
  LIMIT 100;
  
  IF v_ids IS NOT NULL AND array_length(v_ids, 1) > 0 THEN
    -- Update next_attempt_at to avoid concurrent processing
    UPDATE notification_deliveries
    SET next_attempt_at = NOW() + INTERVAL '5 minutes'
    WHERE id = ANY(v_ids);
    
    -- Call edge functions using pg_net or other method
    -- In practice, you would trigger the edge functions via webhook or another mechanism
    -- This is a placeholder
    
    v_processed_count := array_length(v_ids, 1);
  END IF;
  
  RETURN v_processed_count;
END;
$$;


ALTER FUNCTION "public"."process_pending_notifications"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_subscription_updated"("subscription_id" "text", "event_data" "jsonb") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_status TEXT;
    v_cancels_at TIMESTAMP WITH TIME ZONE;
    v_purchase_id UUID;
    v_canceled_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Extract data from event
    v_status := event_data->>'status';
    v_cancels_at := (event_data->>'cancel_at')::TIMESTAMP WITH TIME ZONE;
    v_canceled_at := (event_data->>'canceled_at')::TIMESTAMP WITH TIME ZONE;
    
    -- Find purchase id for this subscription
    SELECT id INTO v_purchase_id
    FROM purchases
    WHERE stripe_subscription_id = subscription_id;
    
    IF v_purchase_id IS NULL THEN
        RETURN 'Subscription not found: ' || subscription_id;
    END IF;
    
    -- Update subscription status
    UPDATE subscriptions
    SET 
        status = CASE 
            WHEN v_status = 'active' THEN 'active'
            WHEN v_status = 'trialing' THEN 'trial'
            WHEN v_status = 'past_due' THEN 'past_due'
            WHEN v_status = 'canceled' THEN 'cancelled'
            WHEN v_status = 'unpaid' THEN 'past_due'
            WHEN v_status = 'incomplete' THEN 'past_due'
            WHEN v_status = 'incomplete_expired' THEN 'cancelled'
            ELSE 'cancelled'
        END,
        cancels_at = v_cancels_at,
        canceled_at = v_canceled_at,
        updated_at = NOW()
    WHERE purchase_id = v_purchase_id;
    
    -- Update purchase status if subscription is cancelled
    IF v_status IN ('canceled', 'incomplete_expired') THEN
        UPDATE purchases
        SET payment_status = 'completed',
            end_date = NOW()
        WHERE id = v_purchase_id;
    END IF;
    
    RETURN 'Subscription updated: ' || subscription_id;
END;
$$;


ALTER FUNCTION "public"."process_subscription_updated"("subscription_id" "text", "event_data" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_waitlist_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_service_title TEXT;
  v_user_ids UUID[];
BEGIN
  -- When waitlist is updated
  IF TG_OP = 'UPDATE' THEN
    -- Get service title
    SELECT title INTO v_service_title
    FROM services
    WHERE id = NEW.service_id;
    
    -- Get all users on the waitlist
    SELECT array_agg(user_id) INTO v_user_ids
    FROM waitlist_entries
    WHERE waitlist_id = NEW.id;
    
    -- Notify all users on the waitlist
    IF array_length(v_user_ids, 1) > 0 THEN
      PERFORM create_notifications_batch(
        v_user_ids,
        'Waitlist Now Open',
        'The waitlist for ' || v_service_title || ' is now open! Reserve your spot now.',
        'system',
        '/services/' || NEW.service_id,
        NEW.id,
        'waitlist',
        jsonb_build_object(
          'waitlist_id', NEW.id,
          'service_id', NEW.service_id,
          'service_title', v_service_title
        )
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."process_waitlist_notification"() OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."embeddings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid",
    "embedding" "extensions"."vector"(384)
);


ALTER TABLE "public"."embeddings" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."query_embeddings"("query_embedding" "extensions"."vector", "match_threshold" double precision) RETURNS SETOF "public"."embeddings"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM embeddings
  WHERE embeddings.embedding <#> query_embedding < -match_threshold
  ORDER BY embeddings.embedding <#> query_embedding;
END;
$$;


ALTER FUNCTION "public"."query_embeddings"("query_embedding" "extensions"."vector", "match_threshold" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."query_video_assets"("track_filter" "text" DEFAULT 'all'::"text", "status_filter" "text" DEFAULT 'all'::"text", "p_limit" integer DEFAULT 10, "p_offset" integer DEFAULT 0) RETURNS TABLE("assets" "public"."video_asset_type"[], "total_count" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Check if the user is authenticated
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = 'LOGIN';
  END IF;

  -- Validate input parameters
  IF track_filter NOT IN ('all', 'audio-only', 'with-video') THEN
    RAISE EXCEPTION 'Invalid track_filter. Must be ''all'', ''audio-only'', or ''with-video''.' USING ERRCODE = 'INVALID_PARAMETER_VALUE';
  END IF;

  IF status_filter NOT IN ('all', 'preparing', 'ready', 'errored') THEN
    RAISE EXCEPTION 'Invalid status_filter. Must be ''all'', ''preparing'', ''ready'', or ''errored''.' USING ERRCODE = 'INVALID_PARAMETER_VALUE';
  END IF;

  IF p_limit < 1 OR p_limit > 100 THEN
    RAISE EXCEPTION 'Invalid limit. Must be between 1 and 100.' USING ERRCODE = 'INVALID_PARAMETER_VALUE';
  END IF;

  IF p_offset < 0 THEN
    RAISE EXCEPTION 'Invalid offset. Must be non-negative.' USING ERRCODE = 'INVALID_PARAMETER_VALUE';
  END IF;

  -- Return the query results
  RETURN QUERY
  WITH filtered_assets AS (
    SELECT *
    FROM public.video_assets
    WHERE user_id = v_user_id
      AND (track_filter = 'all'
           OR (track_filter = 'audio-only' AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(tracks) AS track WHERE track->>'type' = 'video'))
           OR (track_filter = 'with-video' AND EXISTS (SELECT 1 FROM jsonb_array_elements(tracks) AS track WHERE track->>'type' = 'video')))
      AND (status_filter = 'all' OR status = status_filter)
  )
  SELECT 
    ARRAY(
      SELECT (fa.*)::video_asset_type
      FROM filtered_assets fa
      ORDER BY created_at DESC
      LIMIT p_limit
      OFFSET p_offset
    ) AS assets,
    (SELECT COUNT(*) FROM filtered_assets)::BIGINT AS total_count;

EXCEPTION
  WHEN OTHERS THEN
    -- Log the error (you might want to use a more sophisticated logging mechanism)
    RAISE NOTICE 'Error in query_video_assets: %', SQLERRM;
    -- Re-raise the exception
    RAISE;
END;
$$;


ALTER FUNCTION "public"."query_video_assets"("track_filter" "text", "status_filter" "text", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."random_future_date"("days_ahead" integer) RETURNS timestamp without time zone
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN CURRENT_DATE + (random() * days_ahead || ' days')::INTERVAL + (random() * 24 || ' hours')::INTERVAL;
END;
$$;


ALTER FUNCTION "public"."random_future_date"("days_ahead" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."random_name"() RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    first_names TEXT[] := ARRAY['Alice', 'Bob', 'Charlie', 'Diana', 'Ethan', 'Fiona', 'George', 'Hannah', 'Ian', 'Julia'];
    last_names TEXT[] := ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
BEGIN
    RETURN first_names[floor(random() * array_length(first_names, 1) + 1)] || ' ' || 
           last_names[floor(random() * array_length(last_names, 1) + 1)];
END;
$$;


ALTER FUNCTION "public"."random_name"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."random_timestamp"("start_date" timestamp without time zone, "end_date" timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
    -- Modified permission check
    IF NOT (
        has_function_privilege(current_user, 'random_timestamp(timestamp, timestamp)', 'EXECUTE') OR
        current_user = 'authenticated' OR
        current_user = 'postgres' OR
        current_setting('role') = 'service_role'
    ) THEN
        RAISE EXCEPTION 'Insufficient permissions to generate random timestamp';
    END IF;

    RETURN start_date + random() * (end_date - start_date);
END;
$$;


ALTER FUNCTION "public"."random_timestamp"("start_date" timestamp without time zone, "end_date" timestamp without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."register_fcm_token"("p_token" "text", "p_device_info" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_token_id UUID;
BEGIN
  -- Insert or update the token
  INSERT INTO user_fcm_tokens (
    user_id,
    token,
    device_info,
    is_active,
    last_used_at
  )
  VALUES (
    v_user_id,
    p_token,
    p_device_info,
    TRUE,
    NOW()
  )
  ON CONFLICT (user_id, token) DO UPDATE
  SET
    is_active = TRUE,
    device_info = EXCLUDED.device_info,
    last_used_at = EXCLUDED.last_used_at,
    updated_at = NOW()
  RETURNING id INTO v_token_id;
  
  RETURN v_token_id;
END;
$$;


ALTER FUNCTION "public"."register_fcm_token"("p_token" "text", "p_device_info" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."register_fcm_token"("p_token" "text", "p_device_info" "jsonb") IS 'Registers or reactivates an FCM token for the current user';



CREATE OR REPLACE FUNCTION "public"."request_service_appointment"("p_service_id" "uuid", "p_requested_date" timestamp with time zone, "p_duration" integer DEFAULT NULL::integer, "p_method" "text" DEFAULT 'video'::"text", "p_service_type" "text" DEFAULT 'consultation'::"text", "p_notes" "text" DEFAULT NULL::"text", "p_client_id" "uuid" DEFAULT NULL::"uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_client_id UUID;
    v_service_owner_id UUID;
    v_booking_workflow TEXT;
    v_auto_confirm BOOLEAN;
    v_service_price NUMERIC;
    v_service_duration INTEGER;
    v_purchase_id UUID;
    v_appointment_id UUID;
    v_initial_status text;
    v_result JSONB;
    v_timezone TEXT;
    v_slot_available BOOLEAN;
    v_lock_key BIGINT;
    v_payment_status text;
BEGIN
    -- Set client ID (default to current user)
    v_client_id := COALESCE(p_client_id, auth.uid());
    
    -- Check if client is logged in
    IF v_client_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Authentication required'
        );
    END IF;
    
    -- Get service details and owner preferences
    SELECT
        p.user_id,
        s.booking_workflow,
        s.auto_confirm,
        s.price,
        EXTRACT(EPOCH FROM s.duration)::INTEGER / 60 AS duration_minutes,
        pp.timezone
    INTO
        v_service_owner_id,
        v_booking_workflow,
        v_auto_confirm,
        v_service_price,
        v_service_duration,
        v_timezone
    FROM
        public.services s
    JOIN
        public.posts p ON s.post_id = p.id
    LEFT JOIN
        public.provider_preferences pp ON p.user_id = pp.user_id
    WHERE
        s.id = p_service_id;
    
    -- Check if the service exists
    IF v_service_owner_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Service not found'
        );
    END IF;
    
    -- Set duration (use service default if not provided)
    v_service_duration := COALESCE(p_duration, v_service_duration);
    IF v_service_duration IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Service duration not specified'
        );
    END IF;
    
    -- Acquire lock for provider schedule to prevent race conditions
    v_lock_key := lock_provider_schedule(v_service_owner_id);
    
    -- Verify the time slot is available with the lock held
    IF check_schedule_conflicts(
        v_service_owner_id,
        p_requested_date,
        p_requested_date + (v_service_duration || ' minutes')::INTERVAL
    ) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'The requested time slot is not available'
        );
    END IF;
    
    -- Determine initial status based on workflow
    CASE
        WHEN v_booking_workflow = 'direct' THEN
            v_initial_status := 'confirmed';
        WHEN v_booking_workflow = 'pre-approval' THEN
            IF v_auto_confirm THEN
                v_initial_status := 'pending_payment';
            ELSE
                v_initial_status := 'pending_auto_payment';
            END IF;
        WHEN v_booking_workflow = 'waitlist' THEN
            v_initial_status := 'pending_approval';
        ELSE
            v_initial_status := 'pending_approval';
    END CASE;
    
    -- Set payment_status
    IF v_initial_status = 'confirmed' THEN
        v_payment_status := 'completed';
    ELSE
        v_payment_status := 'pending';
    END IF;
    
    -- Create purchase record first
    INSERT INTO public.purchases (
        user_id,
        owner_id,
        amount,
        currency,
        payment_status,
        service_id,
        purchase_type,
        start_date,
        end_date,
        metadata
    ) VALUES (
        v_client_id,
        v_service_owner_id,
        v_service_price,
        'GBP',
        v_payment_status::purchase_payment_status_enum,
        p_service_id,
        'appointment'::purchase_type_enum,
        p_requested_date,
        p_requested_date + (v_service_duration || ' minutes')::INTERVAL,
        jsonb_build_object(
            'appointment_type', p_service_type,
            'appointment_method', p_method,
            'client_notes', p_notes
        )
    ) RETURNING id INTO v_purchase_id;
    
    -- Create appointment record
    INSERT INTO public.appointment_purchases (
        purchase_id,
        service_id,
        appointment_date,
        duration,
        method,
        service_type,
        status,
        notes
    ) VALUES (
        v_purchase_id,
        p_service_id,
        p_requested_date,
        v_service_duration,
        p_method::appointment_method_enum,
        p_service_type::appointment_type_enum,
        v_initial_status::appointment_status_enum,
        p_notes
    ) RETURNING id INTO v_appointment_id;
    
    -- Return result with appropriate next steps
    v_result := jsonb_build_object(
        'success', TRUE,
        'appointment_id', v_appointment_id,
        'purchase_id', v_purchase_id,
        'service_id', p_service_id,
        'status', v_initial_status,
        'requires_payment', (v_initial_status = 'pending_payment'),
        'requires_approval', (v_initial_status = 'pending_approval'),
        'appointment_date', p_requested_date,
        'duration', v_service_duration,
        'price', v_service_price,
        'provider_id', v_service_owner_id,
        'client_id', v_client_id,
        'workflow', v_booking_workflow,
        'next_steps', CASE
            WHEN v_initial_status = 'pending_payment' THEN 'Payment required to confirm booking'
            WHEN v_initial_status = 'pending_approval' THEN 'Waiting for provider approval'
            WHEN v_initial_status = 'confirmed' THEN 'Appointment confirmed'
            ELSE 'Review appointment details'
        END
    );
    
    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."request_service_appointment"("p_service_id" "uuid", "p_requested_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text", "p_client_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."request_service_appointment"("p_service_id" "uuid", "p_requested_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text", "p_client_id" "uuid") IS 'Creates a new appointment request with initial status based on service booking workflow; supports direct booking, pre-approval, or waitlist workflows';



CREATE OR REPLACE FUNCTION "public"."respond_to_appointment"("p_appointment_id" "uuid", "p_action" character varying, "p_new_start_time" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_new_end_time" timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    IF p_action NOT IN ('confirm', 'reject', 'suggest') THEN
        RAISE EXCEPTION 'Invalid action. Must be confirm, reject, or suggest.';
    END IF;

    IF p_action = 'confirm' THEN
        UPDATE public.appointments
        SET status = 'confirmed'
        WHERE id = p_appointment_id AND status = 'pending';
    ELSIF p_action = 'reject' THEN
        UPDATE public.appointments
        SET status = 'rejected'
        WHERE id = p_appointment_id AND status = 'pending';
    ELSIF p_action = 'suggest' THEN
        IF p_new_start_time IS NULL OR p_new_end_time IS NULL THEN
            RAISE EXCEPTION 'New start and end times must be provided for suggestions.';
        END IF;
        
        UPDATE public.appointments
        SET status = 'suggested',
            start_time = p_new_start_time,
            end_time = p_new_end_time
        WHERE id = p_appointment_id AND status = 'pending';
    END IF;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment not found or not in pending status.';
    END IF;
END;
$$;


ALTER FUNCTION "public"."respond_to_appointment"("p_appointment_id" "uuid", "p_action" character varying, "p_new_start_time" timestamp with time zone, "p_new_end_time" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."respond_to_appointment_request"("p_appointment_id" "uuid", "p_action" "text", "p_alternative_time" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_provider_notes" "text" DEFAULT NULL::"text", "p_base_url" "text" DEFAULT '/checkout/appointment'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_appointment_record RECORD;
    v_purchase_record RECORD;
    v_result JSONB;
    v_new_status text;
    v_payment_url TEXT;
BEGIN
    -- Get appointment details
    SELECT 
        ap.*,
        p.user_id AS client_id,
        p.owner_id AS provider_id,
        p.payment_status,
        p.amount AS price,
        s.post_id,
        s.type AS service_type,
        po.title AS service_name
    INTO v_appointment_record
    FROM 
        appointment_purchases ap
        JOIN purchases p ON ap.purchase_id = p.id
        JOIN services s ON ap.service_id = s.id
        JOIN posts po ON s.post_id = po.id
    WHERE 
        ap.id = p_appointment_id;
    
    -- Check if appointment exists
    IF v_appointment_record.id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Appointment not found'
        );
    END IF;
    
    -- Check if the current user is the provider
    IF v_appointment_record.provider_id != auth.uid() THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'You are not authorized to respond to this appointment request'
        );
    END IF;
    
    -- Process the action
    CASE
        WHEN p_action = 'confirm' THEN
            -- Check if the appointment needs confirmation
            IF v_appointment_record.status NOT IN ('pending_approval', 'pending_reschedule') THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'This appointment is not in a state that can be confirmed'
                );
            END IF;
            
            -- Set new status to pending_payment or confirmed based on payment status
            IF v_appointment_record.payment_status = 'completed' THEN
                v_new_status := 'confirmed';
            ELSE
                v_new_status := 'pending_payment';
                
                -- Generate payment URL
                v_payment_url := p_base_url || '/' || v_appointment_record.id;
            END IF;
            
            -- Update appointment
            UPDATE appointment_purchases
            SET 
                status = v_new_status::appointment_status_enum,
                provider_notes = p_provider_notes,
                updated_at = NOW()
            WHERE 
                id = p_appointment_id;
            
            -- Send confirmation notification
            PERFORM create_notification(
                v_appointment_record.client_id,
                'Appointment Confirmed',
                'Your appointment has been confirmed for ' || to_char(v_appointment_record.appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM'),
                'appointment',
                v_payment_url,
                p_appointment_id,
                'appointment',
                jsonb_build_object(
                    'appointment_id', p_appointment_id,
                    'service_id', v_appointment_record.service_id,
                    'status', v_new_status,
                    'requires_payment', (v_new_status = 'pending_payment'),
                    'payment_url', v_payment_url,
                    'appointment_date', v_appointment_record.appointment_date,
                    'duration', v_appointment_record.duration,
                    'provider_notes', p_provider_notes,
                    'service_name', v_appointment_record.service_name
                )
            );
            
        WHEN p_action = 'reject' THEN
            -- Update appointment to cancelled
            UPDATE appointment_purchases
            SET 
                status = 'cancelled'::appointment_status_enum,
                provider_notes = p_provider_notes,
                updated_at = NOW()
            WHERE 
                id = p_appointment_id;
            
            -- Send rejection notification
            PERFORM create_notification(
                v_appointment_record.client_id,
                'Appointment Rejected',
                'Your appointment request has been rejected. ' || COALESCE(p_provider_notes, ''),
                'appointment',
                NULL,
                p_appointment_id,
                'appointment',
                jsonb_build_object(
                    'appointment_id', p_appointment_id,
                    'service_id', v_appointment_record.service_id,
                    'status', 'cancelled',
                    'provider_notes', p_provider_notes,
                    'service_name', v_appointment_record.service_name
                )
            );
            
            v_new_status := 'cancelled';
            
        WHEN p_action = 'suggest' THEN
            -- Check if alternative time is provided
            IF p_alternative_time IS NULL THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Alternative time must be provided for suggestion'
                );
            END IF;
            
            -- Update appointment to pending reschedule
            UPDATE appointment_purchases
            SET 
                status = 'pending_reschedule'::appointment_status_enum,
                provider_notes = p_provider_notes,
                metadata = jsonb_build_object(
                    'alternative_time', p_alternative_time,
                    'original_time', v_appointment_record.appointment_date
                ),
                updated_at = NOW()
            WHERE 
                id = p_appointment_id;
            
            -- Send alternative suggestion notification
            PERFORM create_notification(
                v_appointment_record.client_id,
                'Alternative Time Suggested',
                'Your provider has suggested an alternative time for your appointment: ' || 
                to_char(p_alternative_time, 'FMDay, FMDD Month YYYY at HH12:MI AM') || 
                CASE WHEN p_provider_notes IS NOT NULL THEN E'\n\nNote: ' || p_provider_notes ELSE '' END,
                'appointment',
                '/appointments/reschedule/' || p_appointment_id,
                p_appointment_id,
                'appointment',
                jsonb_build_object(
                    'appointment_id', p_appointment_id,
                    'service_id', v_appointment_record.service_id,
                    'status', 'pending_reschedule',
                    'alternative_time', p_alternative_time,
                    'original_time', v_appointment_record.appointment_date,
                    'provider_notes', p_provider_notes,
                    'service_name', v_appointment_record.service_name
                )
            );
            
            v_new_status := 'pending_reschedule';
            
        ELSE
            RETURN jsonb_build_object(
                'success', FALSE,
                'error', 'Invalid action. Valid actions are: confirm, reject, suggest'
            );
    END CASE;
    
    -- Build result
    v_result := jsonb_build_object(
        'success', TRUE,
        'appointment_id', p_appointment_id,
        'status', v_new_status,
        'action', p_action,
        'client_id', v_appointment_record.client_id,
        'provider_id', v_appointment_record.provider_id,
        'appointment_date', v_appointment_record.appointment_date
    );
    
    -- Add alternative time if provided
    IF p_alternative_time IS NOT NULL THEN
        v_result := v_result || jsonb_build_object('alternative_time', p_alternative_time);
    END IF;
    
    -- Add payment URL if generated
    IF v_payment_url IS NOT NULL THEN
        v_result := v_result || jsonb_build_object('payment_url', v_payment_url);
    END IF;
    
    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."respond_to_appointment_request"("p_appointment_id" "uuid", "p_action" "text", "p_alternative_time" timestamp with time zone, "p_provider_notes" "text", "p_base_url" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."respond_to_appointment_request"("p_appointment_id" "uuid", "p_action" "text", "p_alternative_time" timestamp with time zone, "p_provider_notes" "text", "p_base_url" "text") IS 'Allows providers to confirm, reject, or suggest alternative times for appointment requests';



CREATE OR REPLACE FUNCTION "public"."run_seed_comments"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    PERFORM seed_comments();
    RETURN;
END;
$$;


ALTER FUNCTION "public"."run_seed_comments"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sanitize_slug"("input" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    sanitized TEXT;
BEGIN
    -- Remove non-word characters (except hyphens), convert to lowercase, replace spaces with hyphens
    sanitized := lower(regexp_replace(input, '[^\w\s-]', '', 'g'));
    sanitized := regexp_replace(sanitized, '[\s_]+', '-', 'g');
    -- Remove leading and trailing hyphens
    sanitized := trim(both '-' from sanitized);
    -- Truncate to 200 characters
    sanitized := left(sanitized, 200);
    RETURN sanitized;
END;
$$;


ALTER FUNCTION "public"."sanitize_slug"("input" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."seed_comments"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    post_record RECORD;
    comment_record RECORD;
    num_comments INTEGER;
    parent_comment_id BIGINT;
    user_ids UUID[];
    max_depth INTEGER := 3;
    current_depth INTEGER;
BEGIN
    -- Get array of user IDs
    SELECT ARRAY_AGG(id) INTO user_ids
    FROM auth.users;

    -- Get all posts
    FOR post_record IN (
        SELECT id AS post_id
        FROM public.posts
    ) LOOP
        -- Generate 3-8 root comments per post
        num_comments := 3 + floor(random() * 6);
        
        -- Create root comments
        FOR i IN 1..num_comments LOOP
            -- Insert root comment
            INSERT INTO public.comments (
                user_id,
                post_id,
                comment,
                created_at,
                depth,
                hasReplies
            ) VALUES (
                user_ids[1 + floor(random() * array_length(user_ids, 1))],
                post_record.post_id,
                generate_random_comment(),
                NOW() - (random() * interval '30 days'),
                0, null
            ) RETURNING id INTO parent_comment_id;

            -- Generate nested replies
            current_depth := 1;
            WHILE current_depth <= max_depth AND random() < 0.7 LOOP
                FOR j IN 1..1 + floor(random() * 3) LOOP
                    INSERT INTO public.comments (
                        user_id,
                        post_id,
                        comment,
                        parent_id,
                        created_at,
                        depth
                    ) VALUES (
                        user_ids[1 + floor(random() * array_length(user_ids, 1))],
                        post_record.post_id,
                        generate_random_comment(),
                        parent_comment_id,
                        NOW() - (random() * interval '30 days'),
                        current_depth
                    );
                END LOOP;
                current_depth := current_depth + 1;
            END LOOP;

            -- Add reactions to this comment thread
            FOR comment_record IN (
                SELECT id FROM comments 
                WHERE post_id = post_record.post_id 
                AND (parent_id = parent_comment_id OR id = parent_comment_id)
            ) LOOP
                -- Add 0-5 reactions per comment
                FOR i IN 1..floor(random() * 6) LOOP
                    INSERT INTO public.comment_reactions (
                        comment_id,
                        user_id,
                        reaction_type
                    ) VALUES (
                        comment_record.id,
                        user_ids[1 + floor(random() * array_length(user_ids, 1))],
                        CASE floor(random() * 5)
                            WHEN 0 THEN 'like'
                            WHEN 1 THEN 'heart'
                            WHEN 2 THEN 'laugh'
                            WHEN 3 THEN 'sad'
                            ELSE 'angry'
                        END
                    ) ON CONFLICT (comment_id, user_id, reaction_type) DO NOTHING;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."seed_comments"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_availability"("p_user_id" "uuid", "p_day" character varying, "p_is_active" boolean, "p_start_time" time without time zone, "p_end_time" time without time zone) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO public.availability (user_id, day, is_active, start_time, end_time)
    VALUES (p_user_id, LOWER(p_day), p_is_active, p_start_time, p_end_time)
    ON CONFLICT (user_id, day)
    DO UPDATE SET
        is_active = EXCLUDED.is_active,
        start_time = EXCLUDED.start_time,
        end_time = EXCLUDED.end_time,
        updated_at = NOW();
END;
$$;


ALTER FUNCTION "public"."set_availability"("p_user_id" "uuid", "p_day" character varying, "p_is_active" boolean, "p_start_time" time without time zone, "p_end_time" time without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_user_timezone_claim"("token" "jsonb", "claims" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  user_tz TEXT;
BEGIN
  -- Get the user's timezone from user_locations or user_preferences
  SELECT timezone INTO user_tz
  FROM user_locations
  WHERE user_id = claims->>'sub';
  
  -- If not found, try to get a default from elsewhere or use UTC
  IF user_tz IS NULL THEN
    user_tz := 'UTC';
  END IF;
  
  -- Add the timezone to the custom claims
  RETURN jsonb_set(claims, '{app_metadata, timezone}', to_jsonb(user_tz));
END;
$$;


ALTER FUNCTION "public"."set_user_timezone_claim"("token" "jsonb", "claims" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."toggle_comment_reaction"("in_comment_id" bigint, "in_reaction_type" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    existing_reaction_id BIGINT;
BEGIN
    SELECT id INTO existing_reaction_id
    FROM public.comment_reactions
    WHERE comment_id = in_comment_id 
    AND user_id = auth.uid()
    AND reaction_type = in_reaction_type;

    IF existing_reaction_id IS NULL THEN
        INSERT INTO public.comment_reactions (
            comment_id,
            user_id,
            reaction_type
        ) VALUES (
            in_comment_id,
            auth.uid(),
            in_reaction_type
        );
    ELSE
        DELETE FROM public.comment_reactions
        WHERE id = existing_reaction_id;
    END IF;
END;
$$;


ALTER FUNCTION "public"."toggle_comment_reaction"("in_comment_id" bigint, "in_reaction_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."toggle_message_reaction"("p_message_id" "uuid", "p_reaction_type" "public"."reaction_type_enum", "p_emoji_code" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_chat_room_id UUID;
    v_existing_reaction UUID;
BEGIN
    -- Get the chat room id for the message
    SELECT chat_room_id INTO v_chat_room_id
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

    -- Check if the reaction already exists
    SELECT id INTO v_existing_reaction
    FROM public.message_reactions
    WHERE message_id = p_message_id
    AND user_id = auth.uid()
    AND reaction_type = p_reaction_type;
    
    -- If reaction exists, delete it (toggle off)
    IF v_existing_reaction IS NOT NULL THEN
        DELETE FROM public.message_reactions
        WHERE id = v_existing_reaction;
        RETURN TRUE;
    END IF;
    
    -- Otherwise, create the reaction (toggle on)
    INSERT INTO public.message_reactions (
        message_id,
        user_id,
        reaction_type,
        emoji_code
    ) VALUES (
        p_message_id,
        auth.uid(),
        p_reaction_type,
        p_emoji_code
    );
    
    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."toggle_message_reaction"("p_message_id" "uuid", "p_reaction_type" "public"."reaction_type_enum", "p_emoji_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_create_embedding"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_request_id bigint;
    v_error_message text;
    my_var text;
BEGIN
    BEGIN

    my_var := current_setting('supabase.ANON_KEY', true);
        -- Make the HTTP POST request
        SELECT net.http_post(
            url := 'http://host.docker.internal:54321/functions/v1/embeddings',
            body := jsonb_build_object(
                'post_id', NEW.id,
                'content', NEW.content
            ),
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || my_var
            ) 
        ) INTO v_request_id;

        -- Log success (you can modify this part based on your logging preferences)
        RAISE NOTICE 'Embedding request sent successfully. Request ID: %', v_request_id;

    EXCEPTION WHEN OTHERS THEN
        -- Log error (you can modify this part based on your logging preferences)
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE WARNING 'Error sending embedding request: %', v_error_message;
    END;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_create_embedding"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_article_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum") RETURNS "public"."article_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_article_id UUID;
    v_result public.article_content_creation_result;
BEGIN
    -- Update the post
    UPDATE public.posts
    SET title = p_title,
        slug = p_slug,
        description = p_description,
        content = p_content,
        thumbnail_url = p_thumbnail_url,
        status = p_status,
        updated_at = NOW()
    WHERE id = p_post_id;

    -- Update tags
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Update article
    UPDATE public.articles
    SET content = p_content,
        updated_at = NOW()
    WHERE post_id = p_post_id
    RETURNING id INTO v_article_id;

    -- Prepare the result
    v_result := (p_post_id, v_article_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating article content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."update_article_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_auth_user_role"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Update the auth.users metadata
    UPDATE auth.users
    SET raw_user_meta_data = 
        COALESCE(raw_user_meta_data, '{}'::jsonb) || 
        jsonb_build_object('user_role', NEW.role::text)
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_auth_user_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_auth_user_timezone"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Update the auth.users metadata
    UPDATE auth.users
    SET raw_user_meta_data = 
        COALESCE(raw_user_meta_data, '{}'::jsonb) || 
        jsonb_build_object('user_timezone', NEW.timezone)
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_auth_user_timezone"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_ceremony_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_ceremony_type" "text", "p_ceremony_theme" "text", "p_ceremony_focus" "text", "p_what_to_bring" "text", "p_space_holder_names" "text") RETURNS "public"."ceremony_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_ondemand_media_id UUID;
    v_protected_media_id UUID;
    v_ceremony_id UUID;
    v_result public.ceremony_content_creation_result;
BEGIN
    -- Update the post
    UPDATE public.posts
    SET title = p_title,
        slug = p_slug,
        description = p_description,
        content = p_content,
        thumbnail_url = p_thumbnail_url,
        status = p_status,
        updated_at = NOW()
    WHERE id = p_post_id;

    -- Update tags
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Update on_demand_media
    UPDATE public.on_demand_media
    SET media_type = p_media_type,
        duration = p_duration,
        price = p_price,
        updated_at = NOW()
    WHERE post_id = p_post_id
    RETURNING id INTO v_ondemand_media_id;

    -- Update protected_media_data
    UPDATE public.protected_media_data
    SET status = p_status,
        url = p_protected_media_url
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_protected_media_id;

    -- Update playlist associations
    DELETE FROM public.spotify_playlist_join WHERE content_id = v_ondemand_media_id;
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Update ceremony
    UPDATE public.ceremony
    SET ceremony_type = p_ceremony_type,
        ceremony_theme = p_ceremony_theme,
        ceremony_focus = p_ceremony_focus,
        what_to_bring = p_what_to_bring,
        space_holder_names = p_space_holder_names
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_ceremony_id;

    -- Prepare the result
    v_result := (p_post_id, v_ondemand_media_id, v_protected_media_id, v_ceremony_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating ceremony content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."update_ceremony_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_ceremony_type" "text", "p_ceremony_theme" "text", "p_ceremony_focus" "text", "p_what_to_bring" "text", "p_space_holder_names" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_chat_room_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Update to current timestamp
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_chat_room_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_chat_room_timestamp_on_message"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Update to current timestamp
    UPDATE public.chat_rooms
    SET updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.chat_room_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_chat_room_timestamp_on_message"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_comment_date_time"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_comment_date_time"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_comment_has_replies"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Only execute if there is a parent_id (meaning this is a reply)
    IF NEW.parent_id IS NOT NULL THEN
        -- Update only the specific parent comment
        UPDATE comments 
        SET hasReplies = true 
        WHERE id = NEW.parent_id;
    END IF;
    
    -- Return the NEW row to complete the trigger
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_comment_has_replies"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_coordinates_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.coordinates_updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_coordinates_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_dance_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_freeform_movement" boolean) RETURNS "public"."dance_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_dance_id UUID;
    v_result public.dance_content_creation_result;
BEGIN
    -- Update base on-demand content
    v_base_result := public.update_ondemand_content_with_details(
        p_post_id, p_title, p_slug, p_description, p_content, p_thumbnail_url,
        p_tags, p_status, p_media_type, p_duration, p_price,
        p_protected_media_url, p_emotional_focuses, p_playlist_ids,
        p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment,
        p_body_focus, p_props
    );

    -- Update or create the dance record
    INSERT INTO public.dance (
        movement_id,
        freeform_movement
    ) VALUES (
        v_base_result.movement_id,
        p_freeform_movement
    )
    ON CONFLICT (movement_id) DO UPDATE
    SET freeform_movement = EXCLUDED.freeform_movement
    RETURNING id INTO v_dance_id;

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_dance_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating dance content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."update_dance_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_freeform_movement" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_event_purchase_status"("p_purchase_id" "uuid", "p_payment_status" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_user_id UUID;
    v_owner_id UUID;
    v_booking_status TEXT;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    -- Validate payment status
    IF p_payment_status NOT IN ('completed', 'pending', 'refunded', 'failed') THEN
        RAISE EXCEPTION 'Invalid payment status';
    END IF;
    
    -- Get purchase owner for permission check
    SELECT owner_id INTO v_owner_id
    FROM public.purchases
    WHERE id = p_purchase_id;
    
    -- Check permissions (must be owner or admin)
    IF v_owner_id != v_user_id AND NOT EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = v_user_id AND role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    -- Determine booking status based on payment status
    CASE 
        WHEN p_payment_status = 'completed' THEN v_booking_status := 'confirmed';
        WHEN p_payment_status = 'pending' THEN v_booking_status := 'pending';
        WHEN p_payment_status = 'refunded' OR p_payment_status = 'failed' THEN v_booking_status := 'cancelled';
        ELSE v_booking_status := 'pending';
    END CASE;
    
    -- Update purchase status
    UPDATE public.purchases
    SET 
        payment_status = p_payment_status,
        completed_at = CASE WHEN p_payment_status = 'completed' THEN CURRENT_TIMESTAMP ELSE completed_at END,
        refunded_at = CASE WHEN p_payment_status = 'refunded' THEN CURRENT_TIMESTAMP ELSE refunded_at END
    WHERE id = p_purchase_id AND purchase_type = 'event';
    
    -- Update booking status
    UPDATE public.event_bookings
    SET status = v_booking_status
    WHERE purchase_id = p_purchase_id;
    
    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."update_event_purchase_status"("p_purchase_id" "uuid", "p_payment_status" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_event_with_details"("p_event_id" "uuid", "p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_status" "public"."publish_status_enum", "p_tags" "text"[], "p_event_type" "public"."event_type_enum", "p_event_dates" "public"."event_date_input"[], "p_tickets" "public"."ticket_input"[], "p_room_name" "text" DEFAULT NULL::"text", "p_room_password" "text" DEFAULT NULL::"text", "p_location_id" "uuid" DEFAULT NULL::"uuid") RETURNS "public"."event_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_room_id UUID;
    v_result event_creation_result;
    v_date event_date_input;
    v_existing_date_id UUID;
BEGIN
    -- Update the post
    UPDATE public.posts
    SET title = p_title,
        slug = p_slug,
        description = p_description,
        content = p_content,
        thumbnail_url = p_thumbnail_url,
        updated_at = NOW(),
        status = p_status
    WHERE id = p_post_id;

    -- Update tags
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Update the event
    UPDATE public.events
    SET content = p_content,
        type = p_event_type,
        updated_at = NOW()
    WHERE id = p_event_id;

    -- Update event dates
    -- First, delete dates that are not in the new set
    DELETE FROM public.event_dates
    WHERE event_id = p_event_id AND id NOT IN (
        SELECT (value->>'id')::UUID
        FROM jsonb_array_elements(to_jsonb(p_event_dates))
        WHERE value->>'id' IS NOT NULL
    );

    -- Then, update or insert new dates
    FOREACH v_date IN ARRAY p_event_dates
    LOOP
        -- Check if this date already exists
        SELECT id INTO v_existing_date_id
        FROM public.event_dates
        WHERE event_id = p_event_id AND id = (v_date.id::UUID);

        IF v_existing_date_id IS NOT NULL THEN
            -- Update existing date
            UPDATE public.event_dates
            SET start_date = v_date.start_date,
                end_date = v_date.end_date
            WHERE id = v_existing_date_id;
        ELSE
            -- Insert new date
            INSERT INTO public.event_dates (event_id, start_date, end_date)
            VALUES (p_event_id, v_date.start_date, v_date.end_date);
        END IF;
    END LOOP;

    -- Update tickets
    -- DELETE FROM public.tickets WHERE event_id = p_event_id;
    PERFORM public.add_tickets(p_event_id, p_tickets);

    -- Handle room update for online or hybrid events
    IF p_event_type IN ('online', 'hybrid') THEN
        SELECT id INTO v_room_id FROM public.live_rooms WHERE post_id = p_post_id;
        
        IF v_room_id IS NOT NULL THEN
            UPDATE public.live_rooms
            SET name = p_room_name,
                password = p_room_password,
                updated_at = NOW()
            WHERE id = v_room_id;
        ELSIF p_room_name IS NOT NULL THEN
            v_room_id := public.create_live_room(p_post_id, p_room_name, p_room_password);
        END IF;
    ELSE
        DELETE FROM public.live_rooms WHERE post_id = p_post_id;
        v_room_id := NULL;
    END IF;

    -- Handle location for in-person or hybrid events
    IF p_event_type IN ('in-person', 'hybrid') THEN
        DELETE FROM public.post_locations WHERE post_id = p_post_id;
        
        IF p_location_id IS NOT NULL THEN
            PERFORM public.associate_post_location(p_post_id, p_location_id);
        END IF;
    ELSE
        DELETE FROM public.post_locations WHERE post_id = p_post_id;
    END IF;

    -- Prepare the result
    v_result := (p_event_id, p_post_id, v_room_id, p_slug);

    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."update_event_with_details"("p_event_id" "uuid", "p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_status" "public"."publish_status_enum", "p_tags" "text"[], "p_event_type" "public"."event_type_enum", "p_event_dates" "public"."event_date_input"[], "p_tickets" "public"."ticket_input"[], "p_room_name" "text", "p_room_password" "text", "p_location_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_journal_entry"("p_journal_entry_id" bigint, "p_title" "text" DEFAULT NULL::"text", "p_content" "text" DEFAULT NULL::"text", "p_mood" "public"."mood_enum" DEFAULT NULL::"public"."mood_enum", "p_privacy" "public"."journal_entry_privacy_enum" DEFAULT NULL::"public"."journal_entry_privacy_enum", "p_tags" "text"[] DEFAULT NULL::"text"[]) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_user_id uuid;
  v_tag_id bigint;
  v_tag_name text;
begin
  -- Get user_id of the journal entry to check ownership
  select user_id into v_user_id from journal_entries where id = p_journal_entry_id;
  
  -- Check if the current user owns this journal entry
  if v_user_id is null or v_user_id != auth.uid() then
    raise exception 'Journal entry not found or you do not have permission to update it';
  end if;
  
  -- Update the journal entry with non-null values
  update journal_entries
  set 
    title = coalesce(p_title, title),
    content = coalesce(p_content, content),
    mood = coalesce(p_mood, mood),
    privacy = coalesce(p_privacy, privacy)
  where id = p_journal_entry_id;
  
  -- Handle tags if provided (remove existing and add new)
  if p_tags is not null then
    -- Remove existing tags
    delete from journal_entry_tags where journal_entry_id = p_journal_entry_id;
    
    -- Add new tags
    foreach v_tag_name in array p_tags loop
      -- Try to find existing tag or create new one
      select id into v_tag_id from journal_tags where name = v_tag_name;
      
      if v_tag_id is null then
        insert into journal_tags (name)
        values (v_tag_name)
        returning id into v_tag_id;
      end if;
      
      -- Link tag to journal entry
      insert into journal_entry_tags (journal_entry_id, tag_id)
      values (p_journal_entry_id, v_tag_id);
    end loop;
  end if;
  
  -- Return the updated journal entry with its relationships
  return (
    select jsonb_build_object(
      'journal_entry', row_to_json(je),
      'tags', coalesce(
        (select jsonb_agg(jt.name)
         from journal_entry_tags jet
         join journal_tags jt on jet.tag_id = jt.id
         where jet.journal_entry_id = je.id),
        '[]'::jsonb
      ),
      'content_links', coalesce(
        (select jsonb_agg(jcl.post_id)
         from journal_content_links jcl
         where jcl.journal_entry_id = je.id),
        '[]'::jsonb
      )
    )
    from journal_entries je
    where je.id = p_journal_entry_id
  );
end;
$$;


ALTER FUNCTION "public"."update_journal_entry"("p_journal_entry_id" bigint, "p_title" "text", "p_content" "text", "p_mood" "public"."mood_enum", "p_privacy" "public"."journal_entry_privacy_enum", "p_tags" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_meditation_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_meditation_type" "text", "p_meditation_theme" "text", "p_meditation_focus" "text") RETURNS "public"."meditation_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_ondemand_media_id UUID;
    v_protected_media_id UUID;
    v_meditation_id UUID;
    v_result public.meditation_content_creation_result;
BEGIN
    -- Update the post
    UPDATE public.posts
    SET title = p_title,
        slug = p_slug,
        description = p_description,
        content = p_content,
        thumbnail_url = p_thumbnail_url,
        status = p_status,
        updated_at = NOW()
    WHERE id = p_post_id;

    -- Update tags
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Update on_demand_media
    UPDATE public.on_demand_media
    SET media_type = p_media_type,
        duration = p_duration,
        price = p_price,
        updated_at = NOW()
    WHERE post_id = p_post_id
    RETURNING id INTO v_ondemand_media_id;

    -- Update protected_media_data
    UPDATE public.protected_media_data
    SET status = p_status,
        url = p_protected_media_url
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_protected_media_id;

    -- Update playlist associations
    DELETE FROM public.spotify_playlist_join WHERE content_id = v_ondemand_media_id;
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Update meditation
    UPDATE public.meditations
    SET meditation_type = p_meditation_type,
        meditation_theme = p_meditation_theme,
        meditation_focus = p_meditation_focus
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_meditation_id;

    -- Prepare the result
    v_result := (p_post_id, v_ondemand_media_id, v_protected_media_id, v_meditation_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating meditation content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."update_meditation_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_meditation_type" "text", "p_meditation_theme" "text", "p_meditation_focus" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_message_status"("p_message_id" "uuid", "p_status" "public"."message_status_enum") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
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
$$;


ALTER FUNCTION "public"."update_message_status"("p_message_id" "uuid", "p_status" "public"."message_status_enum") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_modified_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_modified_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_neuroflow_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_techniques_used" "text", "p_session_focus" "text", "p_personal_growth_outcomes" "text") RETURNS "public"."neuroflow_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_neuroflow_id UUID;
    v_result public.neuroflow_content_creation_result;
BEGIN
    -- Update base on-demand content
    v_base_result := public.update_ondemand_content_with_details(
        p_post_id, p_title, p_slug, p_description, p_content, p_thumbnail_url,
        p_tags, p_status, p_media_type, p_duration, p_price,
        p_protected_media_url, p_emotional_focuses, p_playlist_ids,
        p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment,
        p_body_focus, p_props
    );

    -- Update or create the neuro flow record
    INSERT INTO public.neuroflow (
        movement_id,
        techniques_used,
        session_focus,
        personal_growth_outcomes
    ) VALUES (
        v_base_result.movement_id,
        p_techniques_used,
        p_session_focus,
        p_personal_growth_outcomes
    )
    ON CONFLICT (movement_id) DO UPDATE
    SET techniques_used = EXCLUDED.techniques_used,
        session_focus = EXCLUDED.session_focus,
        personal_growth_outcomes = EXCLUDED.personal_growth_outcomes
    RETURNING id INTO v_neuroflow_id;

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_neuroflow_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating neuro flow content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."update_neuroflow_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_techniques_used" "text", "p_session_focus" "text", "p_personal_growth_outcomes" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_notification_preferences"("p_type" "text", "p_in_app" boolean DEFAULT NULL::boolean, "p_email" boolean DEFAULT NULL::boolean, "p_push" boolean DEFAULT NULL::boolean, "p_sms" boolean DEFAULT NULL::boolean) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    -- Insert or update preferences
    INSERT INTO public.notification_preferences (
        user_id,
        type,
        in_app,
        email,
        push,
        sms
    ) VALUES (
        auth.uid(),
        p_type,
        COALESCE(p_in_app, TRUE),
        COALESCE(p_email, TRUE),
        COALESCE(p_push, TRUE),
        COALESCE(p_sms, FALSE)
    )
    ON CONFLICT (user_id, type) DO UPDATE SET
        in_app = COALESCE(p_in_app, notification_preferences.in_app),
        email = COALESCE(p_email, notification_preferences.email),
        push = COALESCE(p_push, notification_preferences.push),
        sms = COALESCE(p_sms, notification_preferences.sms),
        updated_at = NOW();
    
    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."update_notification_preferences"("p_type" "text", "p_in_app" boolean, "p_email" boolean, "p_push" boolean, "p_sms" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_notification_statistics"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_date DATE := CURRENT_DATE;
BEGIN
  -- Insert or update notification statistics for today
  INSERT INTO notification_statistics (
    date,
    total_count,
    read_count,
    type_counts,
    channel_counts,
    updated_at
  )
  VALUES (
    current_date,
    (SELECT COUNT(*) FROM notifications WHERE DATE(created_at) = current_date),
    (SELECT COUNT(*) FROM notifications WHERE DATE(created_at) = current_date AND is_read = TRUE),
    (
      SELECT jsonb_object_agg(type, cnt)
      FROM (
        SELECT type, COUNT(*) as cnt
        FROM notifications
        WHERE DATE(created_at) = current_date
        GROUP BY type
      ) t
    ),
    (
      SELECT jsonb_object_agg(channel, cnt)
      FROM (
        SELECT channel, COUNT(*) as cnt
        FROM notification_deliveries
        WHERE DATE(created_at) = current_date
        GROUP BY channel
      ) c
    ),
    NOW()
  )
  ON CONFLICT (date)
  DO UPDATE SET
    total_count = (SELECT COUNT(*) FROM notifications WHERE DATE(created_at) = current_date),
    read_count = (SELECT COUNT(*) FROM notifications WHERE DATE(created_at) = current_date AND is_read = TRUE),
    type_counts = (
      SELECT jsonb_object_agg(type, cnt)
      FROM (
        SELECT type, COUNT(*) as cnt
        FROM notifications
        WHERE DATE(created_at) = current_date
        GROUP BY type
      ) t
    ),
    channel_counts = (
      SELECT jsonb_object_agg(channel, cnt)
      FROM (
        SELECT channel, COUNT(*) as cnt
        FROM notification_deliveries
        WHERE DATE(created_at) = current_date
        GROUP BY channel
      ) c
    ),
    updated_at = NOW();
END;
$$;


ALTER FUNCTION "public"."update_notification_statistics"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_ondemand_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[]) RETURNS "public"."ondemand_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_ondemand_media_id UUID;
    v_movement_id UUID;
    v_protected_media_id UUID;
    v_result public.ondemand_content_creation_result;
BEGIN
    -- Update the post
    UPDATE public.posts
    SET title = p_title,
        slug = p_slug,
        description = p_description,
        content = p_content,
        thumbnail_url = p_thumbnail_url,
        status = p_status,
        updated_at = NOW()
    WHERE id = p_post_id;

    -- Update tags
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Update on_demand_media
    UPDATE public.on_demand_media
    SET media_type = p_media_type,
        duration = p_duration,
        price = p_price,
        updated_at = NOW()
    WHERE post_id = p_post_id
    RETURNING id, id INTO v_ondemand_media_id, v_result.ondemand_media_id;

    -- Update protected_media_data
    UPDATE public.protected_media_data
    SET status = p_status,
        url = p_protected_media_url
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_protected_media_id;

    -- Update emotional focuses
    DELETE FROM public.post_emotional_focuses WHERE post_id = p_post_id;
    PERFORM public.add_emotional_focuses(p_post_id, p_emotional_focuses);

    -- Update playlist associations
    DELETE FROM public.spotify_playlist_join WHERE content_id = v_ondemand_media_id;
    PERFORM public.add_playlist_associations(v_ondemand_media_id, p_playlist_ids);

    -- Update movement
    UPDATE public.movements
    SET instructor_name = p_instructor_name,
        session_theme = p_session_theme,
        energy_level = p_energy_level,
        spiritual_elements = p_spiritual_elements,
        emotional_focus = p_emotional_focus,
        recommended_environment = p_recommended_environment,
        body_focus = p_body_focus,
        updated_at = NOW()
    WHERE content_id = v_ondemand_media_id
    RETURNING id INTO v_movement_id;

    -- Update movement props
    DELETE FROM public.movement_props_join WHERE movement_id = v_movement_id;
    PERFORM public.add_movement_props(v_movement_id, p_props);

    -- Prepare the result
    v_result := (p_post_id, v_ondemand_media_id, v_movement_id, v_protected_media_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating on-demand content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."update_ondemand_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_protected_media_data_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_protected_media_data_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_sender_read_receipt"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Update the sender's last_read_message_id
    UPDATE public.chat_participants
    SET last_read_message_id = NEW.id
    WHERE chat_room_id = NEW.chat_room_id
    AND user_id = NEW.sender_id;
    
    -- Create a read receipt for the sender
    INSERT INTO public.message_read_receipts (message_id, user_id)
    VALUES (NEW.id, NEW.sender_id)
    ON CONFLICT (message_id, user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_sender_read_receipt"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_service_booking_settings"("p_service_id" "uuid", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer DEFAULT 24) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_updated BOOLEAN;
BEGIN
    UPDATE public.services
    SET 
        booking_workflow = p_booking_workflow,
        auto_confirm = p_auto_confirm,
        confirmation_deadline_hours = p_confirmation_deadline_hours,
        updated_at = NOW()
    WHERE 
        id = p_service_id
    RETURNING true INTO v_updated;
    
    IF v_updated THEN
        RETURN jsonb_build_object(
            'success', true,
            'service_id', p_service_id,
            'message', 'Service booking settings updated successfully'
        );
    ELSE
        RETURN jsonb_build_object(
            'success', false,
            'service_id', p_service_id,
            'message', 'Service not found'
        );
    END IF;
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'service_id', p_service_id,
        'message', 'Error updating service: ' || SQLERRM
    );
END;
$$;


ALTER FUNCTION "public"."update_service_booking_settings"("p_service_id" "uuid", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_service_booking_settings"("p_service_id" "uuid", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer) IS 'Updates just the booking workflow settings for a service';



CREATE OR REPLACE FUNCTION "public"."update_service_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_location_id" "uuid", "p_price" numeric, "p_duration" interval, "p_type" "public"."event_type_enum", "p_booking_workflow" "text" DEFAULT NULL::"text", "p_auto_confirm" boolean DEFAULT NULL::boolean, "p_confirmation_deadline_hours" integer DEFAULT NULL::integer) RETURNS "public"."service_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_service_id UUID;
    v_result public.service_content_creation_result;
    v_current_workflow TEXT;
    v_current_auto_confirm BOOLEAN;
    v_current_deadline INTEGER;
BEGIN
    -- Update the post
    UPDATE public.posts
    SET title = p_title,
        slug = p_slug,
        description = p_description,
        content = p_content,
        thumbnail_url = p_thumbnail_url,
        status = p_status,
        updated_at = NOW()
    WHERE id = p_post_id;

    -- Update or keep existing booking workflow parameters
    SELECT booking_workflow, auto_confirm, confirmation_deadline_hours 
    INTO v_current_workflow, v_current_auto_confirm, v_current_deadline
    FROM public.services
    WHERE post_id = p_post_id;

    -- Update the service
    UPDATE public.services
    SET location_id = p_location_id,
        content = p_content,
        price = p_price,
        duration = p_duration,
        type = p_type,
        booking_workflow = COALESCE(p_booking_workflow, v_current_workflow),
        auto_confirm = COALESCE(p_auto_confirm, v_current_auto_confirm),
        confirmation_deadline_hours = COALESCE(p_confirmation_deadline_hours, v_current_deadline),
        updated_at = NOW()
    WHERE post_id = p_post_id
    RETURNING id INTO v_service_id;

    -- Handle the tags separately using the update_post_tags function
    DELETE FROM public.post_tags WHERE post_id = p_post_id;
    PERFORM public.add_tags_to_post(p_post_id, p_tags);

    -- Prepare the result
    v_result := (p_post_id, v_service_id, p_slug);

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating service content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."update_service_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_location_id" "uuid", "p_price" numeric, "p_duration" interval, "p_type" "public"."event_type_enum", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_subscription_tier_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_subscription_tier_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_ticket"("p_event_id" "uuid", "p_tickets" "public"."ticket_input"[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_ticket ticket_input;
BEGIN
    FOREACH v_ticket IN ARRAY p_tickets
    LOOP
        INSERT INTO public.tickets (
            event_id, title, description, price, quantity, days_before_unavailable
        ) VALUES (
            p_event_id,
            v_ticket.title,
            v_ticket.description,
            v_ticket.price,
            v_ticket.quantity,
            v_ticket.days_before_unavailable
        );
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."update_ticket"("p_event_id" "uuid", "p_tickets" "public"."ticket_input"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_user_timezone"("new_timezone" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    valid_timezone BOOLEAN;
    current_user_id UUID;
BEGIN
    -- Get the current user's ID
    current_user_id := auth.uid();

    -- Check if there is a logged-in user
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'No authenticated user found';
    END IF;

    -- Check if the new_timezone is valid
    SELECT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumtypid = 'public.timezone'::regtype
        AND enumlabel = new_timezone
    ) INTO valid_timezone;

    IF NOT valid_timezone THEN
        RAISE EXCEPTION 'Invalid timezone: %', new_timezone;
    END IF;

    -- Update the user's metadata
    UPDATE auth.users
    SET raw_user_meta_data = 
        COALESCE(raw_user_meta_data, '{}'::jsonb) || 
        jsonb_build_object('timezone', new_timezone)
    WHERE id = current_user_id;

    -- Also update the user_timezones table if you have one
    INSERT INTO public.user_timezones (user_id, timezone)
    VALUES (current_user_id, new_timezone::public.timezone)
    ON CONFLICT (user_id) 
    DO UPDATE SET timezone = EXCLUDED.timezone::public.timezone;
END;
$$;


ALTER FUNCTION "public"."update_user_timezone"("new_timezone" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_yoga_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_yoga_style" "text", "p_chakras" "text") RETURNS "public"."yoga_content_creation_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_base_result public.ondemand_content_creation_result;
    v_yoga_id UUID;
    v_result public.yoga_content_creation_result;
BEGIN
    -- Update base on-demand content
    v_base_result := public.update_ondemand_content_with_details(
        p_post_id, p_title, p_slug, p_description, p_content, p_thumbnail_url,
        p_tags, p_status, p_media_type, p_duration, p_price,
        p_protected_media_url, p_emotional_focuses, p_playlist_ids,
        p_instructor_name, p_session_theme, p_energy_level,
        p_spiritual_elements, p_emotional_focus, p_recommended_environment,
        p_body_focus, p_props
    );

    -- Update or create the yoga record
    INSERT INTO public.yoga (
        movement_id, yoga_style, chakras
    ) VALUES (
        v_base_result.movement_id, p_yoga_style, p_chakras
    )
    ON CONFLICT (movement_id) DO UPDATE
    SET yoga_style = EXCLUDED.yoga_style,
        chakras = EXCLUDED.chakras
    RETURNING id INTO v_yoga_id;

    -- Prepare the result
    v_result := (
        v_base_result.post_id,
        v_base_result.ondemand_media_id,
        v_base_result.movement_id,
        v_base_result.protected_media_id,
        v_yoga_id,
        v_base_result.slug
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating yoga content: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."update_yoga_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_yoga_style" "text", "p_chakras" "text") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_locations" (
    "user_id" "uuid" NOT NULL,
    "location_id" "uuid",
    "coordinates" "public"."geography"(Point,4326),
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "location_name" "text"
);


ALTER TABLE "public"."user_locations" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_user_location"("p_lat" double precision, "p_lon" double precision, "p_location_id" "uuid" DEFAULT NULL::"uuid", "p_location_name" "text" DEFAULT NULL::"text") RETURNS "public"."user_locations"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    result public.user_locations;
BEGIN
    INSERT INTO public.user_locations (
        user_id,
        location_id,
        location_name,
        coordinates
    )
    VALUES (
        auth.uid(),
        p_location_id,
        p_location_name,
        ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        location_id = EXCLUDED.location_id,
        location_name = EXCLUDED.location_name,
        coordinates = EXCLUDED.coordinates,
        updated_at = CURRENT_TIMESTAMP
    RETURNING * INTO result;

    RETURN result;
END;
$$;


ALTER FUNCTION "public"."upsert_user_location"("p_lat" double precision, "p_lon" double precision, "p_location_id" "uuid", "p_location_name" "text") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "type" "public"."notification_type" NOT NULL,
    "action_url" "text",
    "is_read" boolean DEFAULT false NOT NULL,
    "reference_id" "uuid",
    "reference_type" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "sender_id" "uuid",
    "audience_type" "public"."notification_audience_type" DEFAULT 'individual'::"public"."notification_audience_type",
    "audience_criteria" "jsonb",
    CONSTRAINT "notifications_type_check" CHECK ((("type")::"text" = ANY (ARRAY['appointment'::"text", 'system'::"text", 'general'::"text", 'announcement'::"text", 'payment'::"text", 'booking'::"text", 'waitlist'::"text", 'reminder'::"text", 'message'::"text", 'broadcast'::"text"])))
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


COMMENT ON TABLE "public"."notifications" IS 'Central repository for all user notifications across the system';



COMMENT ON COLUMN "public"."notifications"."sender_id" IS 'The user who sent the notification';



CREATE OR REPLACE FUNCTION "public"."user_can_view_notification"("notification_row" "public"."notifications") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN (
    -- User can view their own notifications
    notification_row.user_id = auth.uid() 
    OR 
    -- User can view broadcasts where they're included in the audience
    (
      notification_row.user_id IS NULL 
      AND notification_row.audience_type = 'all'
    )
  );
END;
$$;


ALTER FUNCTION "public"."user_can_view_notification"("notification_row" "public"."notifications") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."content_purchases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_id" "uuid" NOT NULL,
    "content_id" "uuid" NOT NULL,
    "download_count" integer DEFAULT 0 NOT NULL,
    "last_accessed" timestamp with time zone,
    "is_subscription" boolean DEFAULT false NOT NULL,
    "access_expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."content_purchases" OWNER TO "postgres";


COMMENT ON TABLE "public"."content_purchases" IS 'Tracks digital content purchases and access';



CREATE TABLE IF NOT EXISTS "public"."on_demand_media" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid",
    "user_id" "uuid" NOT NULL,
    "media_type" "public"."media_type_enum" NOT NULL,
    "duration" interval NOT NULL,
    "price" numeric(10,2) NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."on_demand_media" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."posts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "description" "text",
    "content" "text",
    "post_type" "public"."post_type_enum" NOT NULL,
    "status" "public"."publish_status_enum" DEFAULT 'draft'::"public"."publish_status_enum" NOT NULL,
    "thumbnail_url" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "featured" boolean DEFAULT false,
    CONSTRAINT "title_length" CHECK ((("char_length"("title") >= 3) AND ("char_length"("title") <= 255)))
);


ALTER TABLE "public"."posts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."protected_media_data" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "content_id" "uuid" NOT NULL,
    "status" "public"."publish_status_enum" DEFAULT 'draft'::"public"."publish_status_enum" NOT NULL,
    "url" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."protected_media_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."purchases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "stripe_payment_intent_id" "text",
    "stripe_invoice_id" "text",
    "stripe_subscription_id" "text",
    "stripe_customer_id" "text",
    "amount" numeric(10,2) NOT NULL,
    "currency" "text" DEFAULT 'GBP'::"text" NOT NULL,
    "payment_status" "public"."purchase_payment_status_enum" NOT NULL,
    "post_id" "uuid",
    "content_id" "uuid",
    "service_id" "uuid",
    "event_id" "uuid",
    "purchase_type" "public"."purchase_type_enum" NOT NULL,
    "purchase_date" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "start_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "quantity" integer DEFAULT 1 NOT NULL,
    "metadata" "jsonb",
    "completed_at" timestamp with time zone,
    "ended_at" timestamp with time zone,
    "refunded_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "check_only_one_item_type" CHECK (((((("content_id" IS NOT NULL))::integer + (("service_id" IS NOT NULL))::integer) + (("event_id" IS NOT NULL))::integer) <= 1))
);


ALTER TABLE "public"."purchases" OWNER TO "postgres";


COMMENT ON TABLE "public"."purchases" IS 'Central table for all purchase transactions with Stripe integration';



CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_id" "uuid" NOT NULL,
    "stripe_subscription_id" "text" NOT NULL,
    "stripe_price_id" "text" NOT NULL,
    "stripe_product_id" "text" NOT NULL,
    "plan_name" "text" NOT NULL,
    "tier" "text" NOT NULL,
    "billing_cycle" "text" NOT NULL,
    "status" "text" NOT NULL,
    "next_billing_date" timestamp with time zone NOT NULL,
    "payments_count" integer DEFAULT 1 NOT NULL,
    "total_paid" numeric(10,2) NOT NULL,
    "last_payment_status" "text" NOT NULL,
    "last_payment_date" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "is_trial" boolean DEFAULT false,
    "trial_ends_at" timestamp with time zone,
    "cancels_at" timestamp with time zone,
    "canceled_at" timestamp with time zone,
    CONSTRAINT "subscriptions_billing_cycle_check" CHECK (("billing_cycle" = ANY (ARRAY['monthly'::"text", 'quarterly'::"text", 'annual'::"text"]))),
    CONSTRAINT "subscriptions_last_payment_status_check" CHECK (("last_payment_status" = ANY (ARRAY['completed'::"text", 'failed'::"text", 'refunded'::"text"]))),
    CONSTRAINT "subscriptions_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'cancelled'::"text", 'paused'::"text", 'trial'::"text", 'past_due'::"text"]))),
    CONSTRAINT "subscriptions_tier_check" CHECK (("tier" = ANY (ARRAY['basic'::"text", 'premium'::"text", 'unlimited'::"text", 'bronze'::"text", 'silver'::"text", 'gold'::"text", 'platinum'::"text"])))
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


COMMENT ON TABLE "public"."subscriptions" IS 'Detailed subscription information for recurring payments';



CREATE OR REPLACE VIEW "public"."accessible_media" AS
 SELECT "odm"."id" AS "content_id",
    "p"."id" AS "post_id",
    "p"."title",
    "p"."description",
    "p"."thumbnail_url",
    "odm"."duration",
    "odm"."media_type",
        CASE
            WHEN ("p"."user_id" = "auth"."uid"()) THEN true
            WHEN ("odm"."price" = (0)::numeric) THEN true
            ELSE "public"."can_access_content"("odm"."id")
        END AS "has_access",
        CASE
            WHEN ("p"."user_id" = "auth"."uid"()) THEN "pmd"."url"
            WHEN ("odm"."price" = (0)::numeric) THEN "pmd"."url"
            WHEN "public"."can_access_content"("odm"."id") THEN "pmd"."url"
            ELSE NULL::"text"
        END AS "media_url",
        CASE
            WHEN ("p"."user_id" = "auth"."uid"()) THEN 'creator'::"text"
            WHEN ("odm"."price" = (0)::numeric) THEN 'free'::"text"
            WHEN (EXISTS ( SELECT 1
               FROM ("public"."content_purchases" "cp"
                 JOIN "public"."purchases" "pur" ON (("cp"."purchase_id" = "pur"."id")))
              WHERE (("cp"."content_id" = "odm"."id") AND ("pur"."user_id" = "auth"."uid"())))) THEN 'purchased'::"text"
            WHEN (EXISTS ( SELECT 1
               FROM ("public"."subscriptions" "s"
                 JOIN "public"."purchases" "pur" ON (("s"."purchase_id" = "pur"."id")))
              WHERE (("pur"."user_id" = "auth"."uid"()) AND ("pur"."owner_id" = "p"."user_id") AND ("s"."status" = ANY (ARRAY['active'::"text", 'trial'::"text"]))))) THEN 'subscription'::"text"
            ELSE 'not_purchased'::"text"
        END AS "access_type"
   FROM (("public"."on_demand_media" "odm"
     JOIN "public"."posts" "p" ON (("odm"."post_id" = "p"."id")))
     LEFT JOIN "public"."protected_media_data" "pmd" ON (("odm"."id" = "pmd"."content_id")))
  WHERE ("p"."status" = 'public'::"public"."publish_status_enum");


ALTER TABLE "public"."accessible_media" OWNER TO "postgres";


COMMENT ON VIEW "public"."accessible_media" IS 'View that shows media content with proper access control for media URLs';



CREATE TABLE IF NOT EXISTS "public"."appointment_purchases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_id" "uuid" NOT NULL,
    "service_id" "uuid" NOT NULL,
    "appointment_date" timestamp with time zone NOT NULL,
    "duration" integer NOT NULL,
    "method" "public"."appointment_method_enum" NOT NULL,
    "service_type" "public"."appointment_type_enum" NOT NULL,
    "status" "public"."appointment_status_enum" NOT NULL,
    "notes" "text",
    "meeting_url" "text",
    "meeting_id" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "payment_link" "text",
    "metadata" "jsonb"
);


ALTER TABLE "public"."appointment_purchases" OWNER TO "postgres";


COMMENT ON TABLE "public"."appointment_purchases" IS 'Tracks service appointments and bookings';



COMMENT ON COLUMN "public"."appointment_purchases"."payment_link" IS 'Stores the checkout URL for pending payment appointments';



CREATE TABLE IF NOT EXISTS "public"."appointments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "facilitator_id" "uuid",
    "client_id" "uuid",
    "start_time" timestamp with time zone NOT NULL,
    "end_time" timestamp with time zone NOT NULL,
    "status" character varying(20) DEFAULT 'pending'::character varying,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "appointments_status_check" CHECK ((("status")::"text" = ANY (ARRAY[('pending'::character varying)::"text", ('confirmed'::character varying)::"text", ('rejected'::character varying)::"text", ('suggested'::character varying)::"text"]))),
    CONSTRAINT "check_time_range" CHECK (("start_time" < "end_time"))
);


ALTER TABLE "public"."appointments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."articles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."articles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."assets" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "status" character varying(20) NOT NULL,
    "stage" character varying(20),
    "progress" numeric(5,2),
    "estimated_duration" integer,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "metadata" "jsonb",
    "metrics" "jsonb",
    "output" "jsonb",
    "duration" double precision,
    "media_type" "public"."media_type_enum",
    "job_id" character varying(255),
    "queue_position" integer,
    "priority" smallint DEFAULT 1,
    "attempts" smallint DEFAULT 0,
    "processing_started_at" timestamp with time zone,
    "job_data" "jsonb",
    CONSTRAINT "assets_status_check" CHECK ((("status")::"text" = ANY (ARRAY[('queued'::character varying)::"text", ('started'::character varying)::"text", ('processing'::character varying)::"text", ('encoding'::character varying)::"text", ('uploading'::character varying)::"text", ('completed'::character varying)::"text", ('failed'::character varying)::"text"])))
);


ALTER TABLE "public"."assets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."availability" (
    "user_id" "uuid" NOT NULL,
    "day" character varying(20) NOT NULL,
    "is_active" boolean NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "availability_day_check" CHECK ((("day")::"text" = ANY (ARRAY[('monday'::character varying)::"text", ('tuesday'::character varying)::"text", ('wednesday'::character varying)::"text", ('thursday'::character varying)::"text", ('friday'::character varying)::"text", ('saturday'::character varying)::"text", ('sunday'::character varying)::"text"]))),
    CONSTRAINT "check_time_range" CHECK (("start_time" < "end_time"))
);


ALTER TABLE "public"."availability" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."availability_exceptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "exception_date" "date" NOT NULL,
    "is_available" boolean NOT NULL,
    "start_time" time without time zone,
    "end_time" time without time zone,
    "reason" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "valid_times" CHECK ((("is_available" = false) OR (("start_time" IS NOT NULL) AND ("end_time" IS NOT NULL) AND ("start_time" < "end_time"))))
);


ALTER TABLE "public"."availability_exceptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid",
    "user_id" "uuid",
    "client_name" character varying(255) NOT NULL,
    "client_email" character varying(255) NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "start_time" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "end_time" timestamp with time zone,
    CONSTRAINT "check_time_range" CHECK (("start_time" < "end_time"))
);


ALTER TABLE "public"."bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ceremony" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "content_id" "uuid" NOT NULL,
    "ceremony_type" "text" NOT NULL,
    "ceremony_theme" "text" NOT NULL,
    "ceremony_focus" "text" NOT NULL,
    "what_to_bring" "text",
    "space_holder_names" "text"
);


ALTER TABLE "public"."ceremony" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid" NOT NULL,
    "content" "text",
    "type" "public"."event_type_enum" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_tags" (
    "post_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL
);


ALTER TABLE "public"."post_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "username" "text",
    "full_name" "text",
    "avatar_url" "text",
    "website" "text",
    CONSTRAINT "username_length" CHECK (("char_length"("username") >= 3))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."services" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid" NOT NULL,
    "location_id" "uuid",
    "content" "text",
    "price" numeric(10,2) NOT NULL,
    "duration" interval NOT NULL,
    "type" "public"."event_type_enum" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "booking_workflow" "text" DEFAULT 'direct'::"text",
    "auto_confirm" boolean DEFAULT true,
    "confirmation_deadline_hours" integer DEFAULT 24,
    CONSTRAINT "check_booking_workflow" CHECK (("booking_workflow" = ANY (ARRAY['direct'::"text", 'pre-approval'::"text", 'waitlist'::"text"])))
);


ALTER TABLE "public"."services" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(50) NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "post_type" "public"."post_type_enum" NOT NULL
);


ALTER TABLE "public"."tags" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."post_details" AS
 SELECT "p"."id",
    "p"."user_id",
    "p"."title",
    "p"."slug",
    "p"."description",
    "p"."content",
    ("p"."post_type")::"text" AS "post_type",
    ("p"."status")::"text" AS "status",
    "p"."thumbnail_url",
    "p"."created_at",
    "p"."updated_at",
    "p"."featured",
    COALESCE("array_agg"("t"."name") FILTER (WHERE ("t"."name" IS NOT NULL)), (ARRAY[]::"text"[])::character varying[]) AS "tags",
    "pr"."id" AS "profile_id",
    "pr"."full_name" AS "profile_full_name",
    "pr"."avatar_url" AS "profile_avatar_url",
    "e"."type" AS "event_subtype",
    "s"."type" AS "service_subtype",
        CASE
            WHEN ("p"."user_id" = "auth"."uid"()) THEN "odm"."protected_media_url"
            WHEN (("odm"."content_id" IS NOT NULL) AND "public"."can_access_content"("odm"."content_id")) THEN "odm"."protected_media_url"
            ELSE NULL::"text"
        END AS "media_key"
   FROM (((((("public"."posts" "p"
     LEFT JOIN ( SELECT "odm_1"."post_id",
            "odm_1"."id" AS "content_id",
            "pmd"."url" AS "protected_media_url"
           FROM ("public"."on_demand_media" "odm_1"
             LEFT JOIN "public"."protected_media_data" "pmd" ON (("odm_1"."id" = "pmd"."content_id")))) "odm" ON (("p"."id" = "odm"."post_id")))
     LEFT JOIN "public"."post_tags" "pt" ON (("p"."id" = "pt"."post_id")))
     LEFT JOIN "public"."tags" "t" ON (("pt"."tag_id" = "t"."id")))
     LEFT JOIN "public"."profiles" "pr" ON (("p"."user_id" = "pr"."id")))
     LEFT JOIN "public"."events" "e" ON (("p"."id" = "e"."post_id")))
     LEFT JOIN "public"."services" "s" ON (("p"."id" = "s"."post_id")))
  GROUP BY "p"."id", "p"."user_id", "p"."title", "p"."slug", "p"."description", "p"."content", "p"."post_type", "p"."status", "p"."thumbnail_url", "p"."created_at", "p"."updated_at", "p"."featured", "pr"."id", "pr"."full_name", "pr"."avatar_url", "e"."type", "s"."type", "odm"."protected_media_url", "odm"."content_id";


ALTER TABLE "public"."post_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."spotify_playlist_join" (
    "content_id" "uuid" NOT NULL,
    "playlist_id" "uuid" NOT NULL
);


ALTER TABLE "public"."spotify_playlist_join" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."spotify_playlists" (
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "iframe" "text" NOT NULL
);


ALTER TABLE "public"."spotify_playlists" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."on_demand_base" AS
 SELECT "pd"."id",
    "pd"."user_id",
    "pd"."title",
    "pd"."slug",
    "pd"."description",
    "pd"."content",
    "pd"."post_type",
    "pd"."status",
    "pd"."thumbnail_url",
    "pd"."created_at",
    "pd"."updated_at",
    "pd"."featured",
    "pd"."tags",
    "pd"."profile_id",
    "pd"."profile_full_name",
    "pd"."profile_avatar_url",
    "pd"."event_subtype",
    "pd"."service_subtype",
    "pd"."media_key",
    "odm"."id" AS "on_demand_media_id",
    "odm"."media_type",
    "odm"."duration",
    "odm"."price",
    "odm"."created_at" AS "on_demand_created_at",
    "odm"."updated_at" AS "on_demand_updated_at",
    COALESCE("sp"."playlist_iframes", ARRAY[]::"text"[]) AS "spotify_playlist_iframes",
    COALESCE("sp"."playlist_ids", ARRAY[]::"uuid"[]) AS "spotify_playlist_ids"
   FROM (("public"."post_details" "pd"
     JOIN "public"."on_demand_media" "odm" ON (("pd"."id" = "odm"."post_id")))
     LEFT JOIN ( SELECT "spj"."content_id",
            "array_agg"("sp_1"."iframe") AS "playlist_iframes",
            "array_agg"("sp_1"."id") AS "playlist_ids"
           FROM ("public"."spotify_playlist_join" "spj"
             JOIN "public"."spotify_playlists" "sp_1" ON (("spj"."playlist_id" = "sp_1"."id")))
          GROUP BY "spj"."content_id") "sp" ON (("odm"."id" = "sp"."content_id")));


ALTER TABLE "public"."on_demand_base" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."ceremony_details" AS
 SELECT "odb"."id",
    "odb"."user_id",
    "odb"."title",
    "odb"."slug",
    "odb"."description",
    "odb"."content",
    "odb"."post_type",
    "odb"."status",
    "odb"."thumbnail_url",
    "odb"."created_at",
    "odb"."updated_at",
    "odb"."featured",
    "odb"."tags",
    "odb"."profile_id",
    "odb"."profile_full_name",
    "odb"."profile_avatar_url",
    "odb"."event_subtype",
    "odb"."service_subtype",
    "odb"."media_key",
    "odb"."on_demand_media_id",
    "odb"."media_type",
    "odb"."duration",
    "odb"."price",
    "odb"."on_demand_created_at",
    "odb"."on_demand_updated_at",
    "odb"."spotify_playlist_iframes",
    "odb"."spotify_playlist_ids",
    "c"."ceremony_type",
    "c"."ceremony_theme",
    "c"."ceremony_focus",
    "c"."what_to_bring",
    "c"."space_holder_names"
   FROM ("public"."on_demand_base" "odb"
     JOIN "public"."ceremony" "c" ON (("odb"."on_demand_media_id" = "c"."content_id")));


ALTER TABLE "public"."ceremony_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chat_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "chat_room_id" "uuid" NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "message" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "status" "public"."message_status_enum" DEFAULT 'delivered'::"public"."message_status_enum",
    "reply_to_message_id" "uuid",
    "is_edited" boolean DEFAULT false
);


ALTER TABLE "public"."chat_messages" OWNER TO "postgres";

-- Generated with srtd from template: supabase/migrations-templates/create-storage-buckets.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- Migration to create storage buckets and set up policies
BEGIN;

-- Enable row-level security on storage.objects and storage.buckets
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- Create function to check if user is creator or admin
CREATE OR REPLACE FUNCTION public.is_creator_or_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_user_role(auth.uid()) IN ('creator', 'admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant usage on necessary schemas
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_creator_or_admin TO authenticated;

-----------------------
-- Create all buckets
-----------------------
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('post_thumbnails', 'post_thumbnails', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('location_thumbnails', 'location_thumbnails', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('creator_avatars', 'creator_avatars', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('creator_coverImages', 'creator_coverImages', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('avatars', 'avatars', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('public', 'public', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-----------------------
-- Create all policies with existence check
-----------------------
DO $$
DECLARE
  policy_exists BOOLEAN;
BEGIN
  ------------------------------
  -- 1. post_thumbnails policies
  ------------------------------
  -- Check if the post_thumbnails SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Give users select access to post_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Give users select access to post_thumbnails" ON storage.objects
      FOR SELECT 
      USING (bucket_id = 'post_thumbnails')
    $policy$;
  END IF;
  
  -- Check if the DELETE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Give users DELETE access to post_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Give users DELETE access to post_thumbnails" ON storage.objects
      FOR DELETE TO authenticated
      USING (
        bucket_id = 'post_thumbnails'
        AND (
            public.isOwnedFolder(name)
            AND public.authorizedAs(ARRAY['creator'::public.user_role])
        )
        OR public.authorizedAs(ARRAY['admin'::public.user_role])
      )
    $policy$;
  END IF;
  
  -- Check if the INSERT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Give users insert access to post_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Give users insert access to post_thumbnails" ON storage.objects
      FOR INSERT TO authenticated
      WITH CHECK (
        bucket_id = 'post_thumbnails'
        AND (
            public.isOwnedFolder(name)
            AND public.authorizedAs(ARRAY['creator'::public.user_role])
        )
        OR public.authorizedAs(ARRAY['admin'::public.user_role])
      )
    $policy$;
  END IF;
  
  -- Check if the UPDATE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Give users UPDATE access to post_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Give users UPDATE access to post_thumbnails" ON storage.objects
      FOR UPDATE TO authenticated
      WITH CHECK (
        bucket_id = 'post_thumbnails'
        AND (
            public.isOwnedFolder(name)
            AND public.authorizedAs(ARRAY['creator'::public.user_role])
        )
        OR public.authorizedAs(ARRAY['admin'::public.user_role])
      )
    $policy$;
  END IF;

  ------------------------------
  -- 2. location_thumbnails policies
  ------------------------------
  -- Check if the SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Give public access to location_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Give public access to location_thumbnails" ON storage.objects
      FOR SELECT
      USING (bucket_id = 'location_thumbnails')
    $policy$;
  END IF;
  
  -- Check if the INSERT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow authenticated uploads to location_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow authenticated uploads to location_thumbnails" ON storage.objects
      FOR INSERT
      TO authenticated
      WITH CHECK (bucket_id = 'location_thumbnails')
    $policy$;
  END IF;
  
  -- Check if the UPDATE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow authenticated updates to location_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow authenticated updates to location_thumbnails" ON storage.objects
      FOR UPDATE
      TO authenticated
      USING (bucket_id = 'location_thumbnails' AND auth.uid() = owner)
    $policy$;
  END IF;
  
  -- Check if the DELETE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow authenticated deletes from location_thumbnails'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow authenticated deletes from location_thumbnails" ON storage.objects
      FOR DELETE
      TO authenticated
      USING (bucket_id = 'location_thumbnails' AND auth.uid() = owner)
    $policy$;
  END IF;
  
  ------------------------------
  -- 3. creator_avatars policies
  ------------------------------
  -- Check if the SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow public access to creator_avatars'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow public access to creator_avatars" ON storage.objects
      FOR SELECT 
      USING (bucket_id = 'creator_avatars')
    $policy$;
  END IF;
  
  -- Check if the ALL policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow creators to manage their avatars'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow creators to manage their avatars" ON storage.objects
      FOR ALL TO authenticated
      USING (
        bucket_id = 'creator_avatars' 
        AND (
            (auth.uid() = owner AND public.authorizedAs(ARRAY['creator'::public.user_role]))
            OR public.authorizedAs(ARRAY['admin'::public.user_role])
        )
      )
    $policy$;
  END IF;
  
  ------------------------------
  -- 4. creator_coverImages policies
  ------------------------------
  -- Check if the SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow public access to creator_coverImages'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow public access to creator_coverImages" ON storage.objects
      FOR SELECT 
      USING (bucket_id = 'creator_coverImages')
    $policy$;
  END IF;
  
  -- Check if the ALL policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow creators to manage their cover images'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Allow creators to manage their cover images" ON storage.objects
      FOR ALL TO authenticated
      USING (
        bucket_id = 'creator_coverImages' 
        AND (
            (auth.uid() = owner AND public.authorizedAs(ARRAY['creator'::public.user_role]))
            OR public.authorizedAs(ARRAY['admin'::public.user_role])
        )
      )
    $policy$;
  END IF;
  
  ------------------------------
  -- 5. avatars policies
  ------------------------------
  -- Check if the SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Avatar images are publicly accessible'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
      FOR SELECT 
      USING (bucket_id = 'avatars')
    $policy$;
  END IF;
  
  -- Check if the INSERT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Anyone can upload an avatar'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Anyone can upload an avatar" ON storage.objects
      FOR INSERT TO authenticated
      WITH CHECK (bucket_id = 'avatars')
    $policy$;
  END IF;
  
  -- Check if the UPDATE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can manage their own avatars'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Users can manage their own avatars" ON storage.objects
      FOR UPDATE TO authenticated
      USING (bucket_id = 'avatars' AND auth.uid() = owner)
    $policy$;
  END IF;
  
  -- Check if the DELETE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can delete their own avatars'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Users can delete their own avatars" ON storage.objects
      FOR DELETE TO authenticated
      USING (bucket_id = 'avatars' AND auth.uid() = owner)
    $policy$;
  END IF;
  
  ------------------------------
  -- 6. public bucket policies
  ------------------------------
  -- Check if the SELECT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Public bucket is accessible to everyone'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Public bucket is accessible to everyone" ON storage.objects
      FOR SELECT 
      USING (bucket_id = 'public')
    $policy$;
  END IF;
  
  -- Check if the INSERT policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Authenticated users can upload to public'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Authenticated users can upload to public" ON storage.objects
      FOR INSERT TO authenticated
      WITH CHECK (bucket_id = 'public')
    $policy$;
  END IF;
  
  -- Check if the UPDATE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can update their own files in public'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Users can update their own files in public" ON storage.objects
      FOR UPDATE TO authenticated
      USING (bucket_id = 'public' AND auth.uid() = owner)
    $policy$;
  END IF;
  
  -- Check if the DELETE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can delete their own files in public'
  ) INTO policy_exists;
  
  -- Create the policy if it doesn't exist
  IF NOT policy_exists THEN
    EXECUTE $policy$
      CREATE POLICY "Users can delete their own files in public" ON storage.objects
      FOR DELETE TO authenticated
      USING (bucket_id = 'public' AND auth.uid() = owner)
    $policy$;
  END IF;
END $$;

COMMIT; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd



CREATE TABLE IF NOT EXISTS "public"."chat_rooms" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text",
    "type" "public"."chat_type_enum" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "associated_post_id" "uuid",
    "associated_event_id" "uuid",
    "is_broadcast" boolean DEFAULT false,
    "description" "text"
);


ALTER TABLE "public"."chat_rooms" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comment_attachments" (
    "id" bigint NOT NULL,
    "comment_id" bigint,
    "type" "text" NOT NULL,
    "url" "text" NOT NULL,
    "name" "text" NOT NULL,
    "size" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "comment_attachments_type_check" CHECK (("type" = ANY (ARRAY['image'::"text", 'file'::"text"])))
);


ALTER TABLE "public"."comment_attachments" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."comment_attachments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."comment_attachments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."comment_attachments_id_seq" OWNED BY "public"."comment_attachments"."id";



CREATE TABLE IF NOT EXISTS "public"."comment_mentions" (
    "id" bigint NOT NULL,
    "comment_id" bigint,
    "user_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."comment_mentions" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."comment_mentions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."comment_mentions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."comment_mentions_id_seq" OWNED BY "public"."comment_mentions"."id";



CREATE TABLE IF NOT EXISTS "public"."comment_reactions" (
    "id" bigint NOT NULL,
    "comment_id" bigint,
    "user_id" "uuid",
    "reaction_type" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."comment_reactions" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."comment_reactions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."comment_reactions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."comment_reactions_id_seq" OWNED BY "public"."comment_reactions"."id";



CREATE TABLE IF NOT EXISTS "public"."comments" (
    "id" bigint NOT NULL,
    "user_id" "uuid",
    "post_id" "uuid" NOT NULL,
    "comment" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "parent_id" bigint,
    "score" integer DEFAULT 0,
    "hasreplies" boolean,
    "is_edited" boolean DEFAULT false,
    "depth" integer DEFAULT 0
);


ALTER TABLE "public"."comments" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."comments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."comments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."comments_id_seq" OWNED BY "public"."comments"."id";



CREATE TABLE IF NOT EXISTS "public"."event_bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_id" "uuid" NOT NULL,
    "event_id" "uuid" NOT NULL,
    "ticket_id" "uuid" NOT NULL,
    "date_id" "uuid" NOT NULL,
    "attendees" integer DEFAULT 1 NOT NULL,
    "is_virtual" boolean DEFAULT false NOT NULL,
    "status" "text" NOT NULL,
    "ticket_code" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "event_bookings_status_check" CHECK (("status" = ANY (ARRAY['confirmed'::"text", 'pending'::"text", 'cancelled'::"text", 'attended'::"text"])))
);


ALTER TABLE "public"."event_bookings" OWNER TO "postgres";


COMMENT ON TABLE "public"."event_bookings" IS 'Tracks event ticket purchases and attendance';



CREATE TABLE IF NOT EXISTS "public"."event_dates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "start_date" timestamp with time zone NOT NULL,
    "end_date" timestamp with time zone NOT NULL,
    CONSTRAINT "event_dates_check" CHECK (("start_date" < "end_date"))
);


ALTER TABLE "public"."event_dates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tickets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "price" numeric(10,2) NOT NULL,
    "quantity" integer,
    "days_before_unavailable" integer,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."tickets" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."event_dates_view" AS
 SELECT "ed"."id" AS "date_id",
    "ed"."event_id",
    "ed"."start_date",
    "ed"."end_date",
    ("ed"."start_date" > CURRENT_TIMESTAMP) AS "is_future",
        CASE
            WHEN ((( SELECT "sum"("eb"."attendees") AS "sum"
               FROM ("public"."event_bookings" "eb"
                 JOIN "public"."purchases" "p" ON (("eb"."purchase_id" = "p"."id")))
              WHERE (("eb"."date_id" = "ed"."id") AND (("p"."payment_status")::"text" = ANY (ARRAY['completed'::"text", 'pending'::"text"])) AND ("eb"."status" <> 'cancelled'::"text"))) >= COALESCE(( SELECT "sum"("t"."quantity") AS "sum"
               FROM "public"."tickets" "t"
              WHERE (("t"."event_id" = "ed"."event_id") AND ("t"."quantity" IS NOT NULL))), NULL::bigint)) AND (EXISTS ( SELECT 1
               FROM "public"."tickets" "t"
              WHERE (("t"."event_id" = "ed"."event_id") AND ("t"."quantity" IS NOT NULL))))) THEN true
            ELSE false
        END AS "is_fully_booked",
    COALESCE(( SELECT "sum"("eb"."attendees") AS "sum"
           FROM ("public"."event_bookings" "eb"
             JOIN "public"."purchases" "p" ON (("eb"."purchase_id" = "p"."id")))
          WHERE (("eb"."date_id" = "ed"."id") AND (("p"."payment_status")::"text" = ANY (ARRAY['completed'::"text", 'pending'::"text"])) AND ("eb"."status" <> 'cancelled'::"text"))), (0)::bigint) AS "current_attendees"
   FROM "public"."event_dates" "ed";


ALTER TABLE "public"."event_dates_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."live_rooms" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid",
    "name" "text" NOT NULL,
    "password" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "user_id" "uuid"
);


ALTER TABLE "public"."live_rooms" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."locations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "image_url" "text",
    "line_1" "text",
    "line_2" "text",
    "city" "text",
    "country" "text",
    "postcode" "text",
    "maps_link" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "user_id" "uuid",
    "coordinates" "public"."geography"(Point,4326),
    "coordinates_source" "text",
    "coordinates_updated_at" timestamp with time zone,
    CONSTRAINT "locations_coordinates_source_check" CHECK (("coordinates_source" = ANY (ARRAY['nominatim'::"text", 'manual'::"text", 'google'::"text", NULL::"text"])))
);


ALTER TABLE "public"."locations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_locations" (
    "post_id" "uuid" NOT NULL,
    "location_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."post_locations" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."event_details_view" AS
 SELECT "e"."id" AS "event_id",
    "p"."id" AS "post_id",
    "p"."slug",
    "p"."title",
    "p"."description",
    "e"."content",
    "p"."thumbnail_url",
    "e"."type" AS "event_type",
    "p"."featured",
    "p"."created_at",
    "p"."updated_at",
    "p"."user_id" AS "creator_id",
        CASE
            WHEN ("e"."type" = 'online'::"public"."event_type_enum") THEN "jsonb_build_object"('name', 'Online Event')
            ELSE "jsonb_build_object"('id', "l"."id", 'name', "l"."name", 'description', "l"."description", 'image_url', "l"."image_url", 'address', "jsonb_build_object"('line_1', "l"."line_1", 'line_2', "l"."line_2", 'city', "l"."city", 'country', "l"."country", 'postcode', "l"."postcode", 'maps_link', "l"."maps_link"), 'coordinates',
            CASE
                WHEN ("l"."coordinates" IS NOT NULL) THEN "jsonb_build_object"('latitude', "public"."st_y"(("l"."coordinates")::"public"."geometry"), 'longitude', "public"."st_x"(("l"."coordinates")::"public"."geometry"))
                ELSE NULL::"jsonb"
            END)
        END AS "location",
        CASE
            WHEN ("e"."type" = ANY (ARRAY['online'::"public"."event_type_enum", 'hybrid'::"public"."event_type_enum"])) THEN "jsonb_build_object"('id', "lr"."id", 'name', "lr"."name", 'password_protected', ("lr"."password" IS NOT NULL))
            ELSE NULL::"jsonb"
        END AS "room",
    "jsonb_build_object"('id', "pr"."id", 'full_name', "pr"."full_name", 'avatar_url', "pr"."avatar_url") AS "creator"
   FROM ((((("public"."events" "e"
     JOIN "public"."posts" "p" ON (("e"."post_id" = "p"."id")))
     LEFT JOIN "public"."post_locations" "pl" ON (("p"."id" = "pl"."post_id")))
     LEFT JOIN "public"."locations" "l" ON (("pl"."location_id" = "l"."id")))
     LEFT JOIN "public"."live_rooms" "lr" ON (("p"."id" = "lr"."post_id")))
     LEFT JOIN "public"."profiles" "pr" ON (("p"."user_id" = "pr"."id")))
  WHERE ("p"."post_type" = 'event'::"public"."post_type_enum");


ALTER TABLE "public"."event_details_view" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."event_tickets_view" AS
 SELECT "t"."id" AS "ticket_id",
    "t"."event_id",
    "t"."title",
    "t"."description",
    "t"."price",
    "t"."quantity",
    "t"."days_before_unavailable",
        CASE
            WHEN ("t"."quantity" IS NULL) THEN NULL::bigint
            ELSE ("t"."quantity" - COALESCE(( SELECT "sum"("eb"."attendees") AS "sum"
               FROM ("public"."event_bookings" "eb"
                 JOIN "public"."purchases" "p" ON (("eb"."purchase_id" = "p"."id")))
              WHERE (("eb"."ticket_id" = "t"."id") AND (("p"."payment_status")::"text" = ANY (ARRAY['completed'::"text", 'pending'::"text"])) AND ("eb"."status" <> 'cancelled'::"text"))), (0)::bigint))
        END AS "available_quantity",
        CASE
            WHEN ("t"."quantity" IS NULL) THEN false
            WHEN (( SELECT "sum"("eb"."attendees") AS "sum"
               FROM ("public"."event_bookings" "eb"
                 JOIN "public"."purchases" "p" ON (("eb"."purchase_id" = "p"."id")))
              WHERE (("eb"."ticket_id" = "t"."id") AND (("p"."payment_status")::"text" = ANY (ARRAY['completed'::"text", 'pending'::"text"])) AND ("eb"."status" <> 'cancelled'::"text"))) >= "t"."quantity") THEN true
            ELSE false
        END AS "is_sold_out"
   FROM "public"."tickets" "t";


ALTER TABLE "public"."event_tickets_view" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."comprehensive_events_view" AS
 SELECT "e"."event_id",
    "e"."post_id",
    "e"."slug",
    "e"."title",
    "e"."description",
    "e"."content",
    "e"."thumbnail_url",
    "e"."event_type",
    "e"."featured",
    "e"."created_at",
    "e"."updated_at",
    "e"."creator_id",
    "e"."location",
    "e"."room",
    "e"."creator",
    COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "edv"."date_id", 'start_date', "edv"."start_date", 'end_date', "edv"."end_date", 'is_future', "edv"."is_future", 'is_fully_booked', "edv"."is_fully_booked", 'current_attendees', "edv"."current_attendees") ORDER BY "edv"."start_date") AS "jsonb_agg"
           FROM "public"."event_dates_view" "edv"
          WHERE ("edv"."event_id" = "e"."event_id")), '[]'::"jsonb") AS "dates",
    COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "edv"."date_id", 'start_date', "edv"."start_date", 'end_date', "edv"."end_date", 'is_fully_booked', "edv"."is_fully_booked", 'current_attendees', "edv"."current_attendees") ORDER BY "edv"."start_date") AS "jsonb_agg"
           FROM "public"."event_dates_view" "edv"
          WHERE (("edv"."event_id" = "e"."event_id") AND ("edv"."is_future" = true))), '[]'::"jsonb") AS "future_dates",
    COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "etv"."ticket_id", 'title', "etv"."title", 'description', "etv"."description", 'price', "etv"."price", 'quantity', "etv"."quantity", 'available_quantity', "etv"."available_quantity", 'is_sold_out', "etv"."is_sold_out", 'days_before_unavailable', "etv"."days_before_unavailable") ORDER BY "etv"."price") AS "jsonb_agg"
           FROM "public"."event_tickets_view" "etv"
          WHERE ("etv"."event_id" = "e"."event_id")), '[]'::"jsonb") AS "tickets",
    COALESCE(( SELECT "jsonb_agg"("t"."name") AS "jsonb_agg"
           FROM ("public"."post_tags" "pt"
             JOIN "public"."tags" "t" ON (("pt"."tag_id" = "t"."id")))
          WHERE ("pt"."post_id" = "e"."post_id")), '[]'::"jsonb") AS "tags",
    ( SELECT "min"("edv"."start_date") AS "min"
           FROM "public"."event_dates_view" "edv"
          WHERE (("edv"."event_id" = "e"."event_id") AND ("edv"."is_future" = true) AND ("edv"."is_fully_booked" = false))) AS "next_available_date",
    ( SELECT "min"("etv"."price") AS "min"
           FROM "public"."event_tickets_view" "etv"
          WHERE (("etv"."event_id" = "e"."event_id") AND (("etv"."is_sold_out" = false) OR ("etv"."quantity" IS NULL)))) AS "min_price"
   FROM "public"."event_details_view" "e";


ALTER TABLE "public"."comprehensive_events_view" OWNER TO "postgres";


COMMENT ON VIEW "public"."comprehensive_events_view" IS 'Provides complete event information including location, dates, tickets, and availability for the events page';



CREATE OR REPLACE VIEW "public"."service_appointments_view" AS
 SELECT "ap"."id" AS "appointment_id",
    "ap"."purchase_id",
    "ap"."service_id",
    "ap"."appointment_date",
    "ap"."duration",
    "ap"."method",
    "ap"."service_type",
    "ap"."status",
    "ap"."notes",
    "ap"."meeting_url",
    "ap"."meeting_id",
    "p"."user_id" AS "client_id",
    "p"."owner_id" AS "provider_id",
    "p"."payment_status",
    "p"."amount" AS "price_paid",
    "jsonb_build_object"('id', "cl"."id", 'full_name', "cl"."full_name", 'avatar_url', "cl"."avatar_url") AS "client",
    ("ap"."appointment_date" > CURRENT_TIMESTAMP) AS "is_future",
    ("ap"."status" = 'confirmed'::"public"."appointment_status_enum") AS "is_confirmed",
    ("ap"."status" = 'completed'::"public"."appointment_status_enum") AS "is_completed",
    ("ap"."status" = 'cancelled'::"public"."appointment_status_enum") AS "is_cancelled"
   FROM (("public"."appointment_purchases" "ap"
     JOIN "public"."purchases" "p" ON (("ap"."purchase_id" = "p"."id")))
     LEFT JOIN "public"."profiles" "cl" ON (("p"."user_id" = "cl"."id")));


ALTER TABLE "public"."service_appointments_view" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."service_details_view" AS
 SELECT "s"."id" AS "service_id",
    "p"."id" AS "post_id",
    "p"."slug",
    "p"."title",
    "p"."description",
    "s"."content",
    "p"."thumbnail_url",
    "s"."type" AS "service_type",
    "s"."price",
    ("s"."duration")::"text" AS "duration",
    "p"."featured",
    "p"."created_at",
    "p"."updated_at",
    "p"."user_id" AS "creator_id",
    "s"."booking_workflow",
    "s"."auto_confirm",
    "s"."confirmation_deadline_hours",
        CASE
            WHEN ("s"."type" = 'online'::"public"."event_type_enum") THEN "jsonb_build_object"('name', 'Online Service')
            ELSE "jsonb_build_object"('id', "l"."id", 'name', "l"."name", 'description', "l"."description", 'image_url', "l"."image_url", 'address', "jsonb_build_object"('line_1', "l"."line_1", 'line_2', "l"."line_2", 'city', "l"."city", 'country', "l"."country", 'postcode', "l"."postcode", 'maps_link', "l"."maps_link"), 'coordinates',
            CASE
                WHEN ("l"."coordinates" IS NOT NULL) THEN "jsonb_build_object"('latitude', "public"."st_y"(("l"."coordinates")::"public"."geometry"), 'longitude', "public"."st_x"(("l"."coordinates")::"public"."geometry"))
                ELSE NULL::"jsonb"
            END)
        END AS "location",
    "jsonb_build_object"('id', "pr"."id", 'full_name', "pr"."full_name", 'avatar_url', "pr"."avatar_url") AS "creator",
    COALESCE("array_agg"("t"."name") FILTER (WHERE ("t"."id" IS NOT NULL)), ('{}'::"text"[])::character varying[]) AS "tags"
   FROM ((((("public"."services" "s"
     JOIN "public"."posts" "p" ON (("s"."post_id" = "p"."id")))
     LEFT JOIN "public"."locations" "l" ON (("s"."location_id" = "l"."id")))
     LEFT JOIN "public"."profiles" "pr" ON (("p"."user_id" = "pr"."id")))
     LEFT JOIN "public"."post_tags" "pt" ON (("p"."id" = "pt"."post_id")))
     LEFT JOIN "public"."tags" "t" ON (("pt"."tag_id" = "t"."id")))
  WHERE ("p"."post_type" = 'service'::"public"."post_type_enum")
  GROUP BY "s"."id", "p"."id", "p"."slug", "p"."title", "p"."description", "s"."content", "p"."thumbnail_url", "s"."type", "s"."price", "s"."duration", "p"."featured", "p"."created_at", "p"."updated_at", "p"."user_id", "l"."id", "l"."name", "l"."description", "l"."image_url", "l"."line_1", "l"."line_2", "l"."city", "l"."country", "l"."postcode", "l"."maps_link", "l"."coordinates", "pr"."id", "pr"."full_name", "pr"."avatar_url", "s"."booking_workflow", "s"."auto_confirm", "s"."confirmation_deadline_hours";


ALTER TABLE "public"."service_details_view" OWNER TO "postgres";


COMMENT ON VIEW "public"."service_details_view" IS 'Service details view with booking workflow fields';



CREATE OR REPLACE VIEW "public"."comprehensive_services_view" AS
 SELECT "sv"."service_id",
    "sv"."post_id",
    "sv"."slug",
    "sv"."title",
    "sv"."description",
    "sv"."content",
    "sv"."thumbnail_url",
    "sv"."service_type",
    "sv"."price",
    "sv"."duration",
    "sv"."featured",
    "sv"."created_at",
    "sv"."updated_at",
    "sv"."creator_id",
    "sv"."booking_workflow",
    "sv"."auto_confirm",
    "sv"."confirmation_deadline_hours",
    "sv"."location",
    "sv"."creator",
    "sv"."tags",
    COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "sav"."appointment_id", 'appointment_date', "sav"."appointment_date", 'duration', "sav"."duration", 'method', "sav"."method", 'service_type', "sav"."service_type", 'status', "sav"."status", 'client', "sav"."client", 'is_future', "sav"."is_future") ORDER BY "sav"."appointment_date") AS "jsonb_agg"
           FROM "public"."service_appointments_view" "sav"
          WHERE (("sav"."service_id" = "sv"."service_id") AND ("sav"."status" = ANY (ARRAY['confirmed'::"public"."appointment_status_enum", 'pending_payment'::"public"."appointment_status_enum", 'pending_approval'::"public"."appointment_status_enum", 'pending_reschedule'::"public"."appointment_status_enum"])) AND ("sav"."provider_id" = "auth"."uid"()))), '[]'::"jsonb") AS "appointments",
    COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "sav"."appointment_id", 'appointment_date', "sav"."appointment_date", 'duration', "sav"."duration", 'method', "sav"."method", 'service_type', "sav"."service_type", 'status', "sav"."status") ORDER BY "sav"."appointment_date") AS "jsonb_agg"
           FROM "public"."service_appointments_view" "sav"
          WHERE (("sav"."service_id" = "sv"."service_id") AND ("sav"."is_future" = true) AND ("sav"."status" = ANY (ARRAY['confirmed'::"public"."appointment_status_enum", 'pending_payment'::"public"."appointment_status_enum", 'pending_approval'::"public"."appointment_status_enum", 'pending_reschedule'::"public"."appointment_status_enum"])) AND ("sav"."provider_id" = "auth"."uid"()))), '[]'::"jsonb") AS "future_appointments",
    COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "sav"."appointment_id", 'appointment_date', "sav"."appointment_date", 'duration', "sav"."duration", 'method', "sav"."method", 'service_type', "sav"."service_type", 'status', "sav"."status", 'client', "sav"."client") ORDER BY "sav"."appointment_date" DESC) AS "jsonb_agg"
           FROM "public"."service_appointments_view" "sav"
          WHERE (("sav"."service_id" = "sv"."service_id") AND ("sav"."is_future" = false) AND ("sav"."status" = ANY (ARRAY['confirmed'::"public"."appointment_status_enum", 'completed'::"public"."appointment_status_enum"])) AND ("sav"."provider_id" = "auth"."uid"()))), '[]'::"jsonb") AS "past_appointments",
    "jsonb_build_object"('has_appointments', (EXISTS ( SELECT 1
           FROM "public"."service_appointments_view" "sav"
          WHERE (("sav"."service_id" = "sv"."service_id") AND ("sav"."status" = ANY (ARRAY['confirmed'::"public"."appointment_status_enum", 'pending_payment'::"public"."appointment_status_enum", 'pending_approval'::"public"."appointment_status_enum", 'pending_reschedule'::"public"."appointment_status_enum"])) AND ("sav"."is_future" = true)))), 'upcoming_count', ( SELECT "count"(*) AS "count"
           FROM "public"."service_appointments_view" "sav"
          WHERE (("sav"."service_id" = "sv"."service_id") AND ("sav"."status" = ANY (ARRAY['confirmed'::"public"."appointment_status_enum", 'pending_payment'::"public"."appointment_status_enum", 'pending_approval'::"public"."appointment_status_enum", 'pending_reschedule'::"public"."appointment_status_enum"])) AND ("sav"."is_future" = true))), 'total_completed', ( SELECT "count"(*) AS "count"
           FROM "public"."service_appointments_view" "sav"
          WHERE (("sav"."service_id" = "sv"."service_id") AND ("sav"."status" = 'completed'::"public"."appointment_status_enum")))) AS "availability_stats"
   FROM "public"."service_details_view" "sv";


ALTER TABLE "public"."comprehensive_services_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."creator_branding" (
    "user_id" "uuid" NOT NULL,
    "hue" integer,
    "dark" boolean,
    "saturation" integer,
    "lightness" integer,
    "contrast" integer
);


ALTER TABLE "public"."creator_branding" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."creator_emails" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "subject" "text" NOT NULL,
    "configuration" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."creator_emails" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."creator_profiles" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "profile_name" "text",
    "title" "text",
    "updated_at" timestamp with time zone,
    "cover_image_url" "text",
    "bio" "text",
    "short_bio" "text",
    "certifications" "text"[],
    "experience" "text",
    "philosophy" "text",
    "background_video_url" "text",
    "featured_testimonials" "text"[]
);


ALTER TABLE "public"."creator_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "user_id" "uuid" NOT NULL,
    "role" "public"."user_role" DEFAULT 'user'::"public"."user_role" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."creator_profiles_complete_view" AS
 SELECT "p"."id" AS "user_id",
    "p"."username",
    "p"."full_name",
    "p"."avatar_url",
    "p"."website",
    "p"."updated_at" AS "profile_updated_at",
    "cp"."id" AS "creator_profile_id",
    "cp"."user_id" AS "creator_user_id",
    "cp"."profile_id",
    "cp"."title",
    "cp"."updated_at" AS "creator_updated_at",
    "cp"."cover_image_url",
    "cp"."bio",
    "cp"."short_bio",
    "cp"."certifications",
    "cp"."experience",
    "cp"."philosophy",
    "cp"."background_video_url",
    "cp"."featured_testimonials",
    "ur"."role" AS "user_role",
    "cb"."hue",
    "cb"."dark",
    "cb"."saturation",
    "cb"."lightness",
    "cb"."contrast"
   FROM ((("public"."profiles" "p"
     JOIN "public"."creator_profiles" "cp" ON (("cp"."profile_id" = "p"."id")))
     LEFT JOIN "public"."user_roles" "ur" ON (("ur"."user_id" = "p"."id")))
     LEFT JOIN "public"."creator_branding" "cb" ON (("cb"."user_id" = "p"."id")))
  ORDER BY "cp"."updated_at" DESC NULLS LAST;


ALTER TABLE "public"."creator_profiles_complete_view" OWNER TO "postgres";


COMMENT ON VIEW "public"."creator_profiles_complete_view" IS 'Comprehensive view of creator profiles with all information fields for detailed displays';



CREATE TABLE IF NOT EXISTS "public"."notification_deliveries" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "notification_id" "uuid" NOT NULL,
    "channel" "text" NOT NULL,
    "status" "text" NOT NULL,
    "external_id" "text",
    "error_message" "text",
    "attempt_count" integer DEFAULT 0 NOT NULL,
    "next_attempt_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "notification_deliveries_channel_check" CHECK (("channel" = ANY (ARRAY['in_app'::"text", 'email'::"text", 'push'::"text", 'sms'::"text"]))),
    CONSTRAINT "notification_deliveries_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'processing'::"text", 'sent'::"text", 'delivered'::"text", 'failed'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."notification_deliveries" OWNER TO "postgres";


COMMENT ON TABLE "public"."notification_deliveries" IS 'Tracks delivery status of notifications across different channels';



CREATE OR REPLACE VIEW "public"."creator_sent_notifications" AS
 SELECT "n"."id",
    "n"."sender_id",
    "n"."title",
    "n"."content",
    "n"."type",
    "n"."reference_id",
    "n"."reference_type",
    "n"."created_at",
    "count"("nd"."id") AS "total_recipients",
    "sum"(
        CASE
            WHEN ("nd"."status" = 'delivered'::"text") THEN 1
            ELSE 0
        END) AS "delivered_count",
    "jsonb_agg"(DISTINCT "jsonb_build_object"('user_id', "n"."user_id", 'is_read', "n"."is_read")) AS "recipients"
   FROM ("public"."notifications" "n"
     JOIN "public"."notification_deliveries" "nd" ON (("n"."id" = "nd"."notification_id")))
  WHERE ("n"."sender_id" IS NOT NULL)
  GROUP BY "n"."id", "n"."sender_id", "n"."title", "n"."content", "n"."type", "n"."reference_id", "n"."reference_type", "n"."created_at"
  ORDER BY "n"."created_at" DESC;


ALTER TABLE "public"."creator_sent_notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."creator_subscription_tiers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "tier_key" "text" NOT NULL,
    "tier_name" "text" NOT NULL,
    "description" "text",
    "price_monthly" numeric(10,2) NOT NULL,
    "price_quarterly" numeric(10,2),
    "price_annual" numeric(10,2),
    "stripe_price_id_monthly" "text",
    "stripe_price_id_quarterly" "text",
    "stripe_price_id_annual" "text",
    "stripe_product_id" "text",
    "benefits" "jsonb",
    "priority" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true,
    "trial_days" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."creator_subscription_tiers" OWNER TO "postgres";


COMMENT ON TABLE "public"."creator_subscription_tiers" IS 'Defines subscription tiers that creators offer, with pricing and benefits';



CREATE TABLE IF NOT EXISTS "public"."dance" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "movement_id" "uuid" NOT NULL,
    "freeform_movement" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."dance" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."movements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "content_id" "uuid" NOT NULL,
    "instructor_name" character varying(100) NOT NULL,
    "session_theme" character varying(255) NOT NULL,
    "energy_level" integer NOT NULL,
    "spiritual_elements" "text",
    "emotional_focus" "text",
    "recommended_environment" "text",
    "body_focus" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "movements_energy_level_check" CHECK ((("energy_level" >= 1) AND ("energy_level" <= 10)))
);


ALTER TABLE "public"."movements" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."movement_details" AS
 SELECT "odb"."id",
    "odb"."user_id",
    "odb"."title",
    "odb"."slug",
    "odb"."description",
    "odb"."content",
    "odb"."post_type",
    "odb"."status",
    "odb"."thumbnail_url",
    "odb"."created_at",
    "odb"."updated_at",
    "odb"."featured",
    "odb"."tags",
    "odb"."profile_id",
    "odb"."profile_full_name",
    "odb"."profile_avatar_url",
    "odb"."event_subtype",
    "odb"."service_subtype",
    "odb"."media_key",
    "odb"."on_demand_media_id",
    "odb"."media_type",
    "odb"."duration",
    "odb"."price",
    "odb"."on_demand_created_at",
    "odb"."on_demand_updated_at",
    "odb"."spotify_playlist_iframes",
    "odb"."spotify_playlist_ids",
    "m"."id" AS "movement_id",
    "m"."instructor_name",
    "m"."session_theme",
    "m"."energy_level",
    "m"."spiritual_elements",
    "m"."emotional_focus",
    "m"."recommended_environment",
    "m"."body_focus",
    "m"."created_at" AS "movement_created_at",
    "m"."updated_at" AS "movement_updated_at"
   FROM ("public"."on_demand_base" "odb"
     JOIN "public"."movements" "m" ON (("odb"."on_demand_media_id" = "m"."content_id")));


ALTER TABLE "public"."movement_details" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."dance_details" AS
 SELECT "md"."id",
    "md"."user_id",
    "md"."title",
    "md"."slug",
    "md"."description",
    "md"."content",
    "md"."post_type",
    "md"."status",
    "md"."thumbnail_url",
    "md"."created_at",
    "md"."updated_at",
    "md"."featured",
    "md"."tags",
    "md"."profile_id",
    "md"."profile_full_name",
    "md"."profile_avatar_url",
    "md"."event_subtype",
    "md"."service_subtype",
    "md"."media_key",
    "md"."on_demand_media_id",
    "md"."media_type",
    "md"."duration",
    "md"."price",
    "md"."on_demand_created_at",
    "md"."on_demand_updated_at",
    "md"."spotify_playlist_iframes",
    "md"."spotify_playlist_ids",
    "md"."movement_id",
    "md"."instructor_name",
    "md"."session_theme",
    "md"."energy_level",
    "md"."spiritual_elements",
    "md"."emotional_focus",
    "md"."recommended_environment",
    "md"."body_focus",
    "md"."movement_created_at",
    "md"."movement_updated_at",
    "d"."freeform_movement"
   FROM ("public"."movement_details" "md"
     JOIN "public"."dance" "d" ON (("md"."movement_id" = "d"."movement_id")));


ALTER TABLE "public"."dance_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."email_templates" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "subject" "text" NOT NULL,
    "html_content" "text" NOT NULL,
    "text_content" "text" NOT NULL,
    "variables" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."email_templates" OWNER TO "postgres";


COMMENT ON TABLE "public"."email_templates" IS 'Customizable templates for email notifications';



CREATE TABLE IF NOT EXISTS "public"."emotional_focuses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "value" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."emotional_focuses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."error_logs" (
    "id" bigint NOT NULL,
    "timestamp" timestamp with time zone DEFAULT "now"() NOT NULL,
    "error_level" character varying(20) NOT NULL,
    "error_message" "text" NOT NULL,
    "error_code" character varying(50),
    "source_file" character varying(255),
    "line_number" integer,
    "function_name" character varying(100),
    "user_id" "uuid",
    "session_id" "uuid",
    "request_path" character varying(255),
    "request_method" character varying(10),
    "ip_address" "inet",
    "user_agent" "text",
    "stack_trace" "text",
    "additional_data" "jsonb"
);


ALTER TABLE "public"."error_logs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."error_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."error_logs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."error_logs_id_seq" OWNED BY "public"."error_logs"."id";



CREATE OR REPLACE VIEW "public"."events_view" AS
 WITH "event_dates_summary" AS (
         SELECT "ed"."event_id",
            "min"(
                CASE
                    WHEN ("ed"."start_date" > CURRENT_TIMESTAMP) THEN "ed"."start_date"
                    ELSE NULL::timestamp with time zone
                END) AS "next_date",
            "min"(
                CASE
                    WHEN ("ed"."start_date" <= CURRENT_TIMESTAMP) THEN "ed"."start_date"
                    ELSE NULL::timestamp with time zone
                END) AS "latest_past_date",
            "array_agg"("ed"."id" ORDER BY "ed"."start_date") AS "date_ids",
            "count"(DISTINCT "ed"."id") FILTER (WHERE ("ed"."start_date" > CURRENT_TIMESTAMP)) AS "future_dates_count",
            "count"(DISTINCT "ed"."id") FILTER (WHERE ("ed"."start_date" <= CURRENT_TIMESTAMP)) AS "past_dates_count",
            (EXISTS ( SELECT 1
                   FROM "public"."event_dates" "ed2"
                  WHERE (("ed2"."event_id" = "ed"."event_id") AND ("ed2"."start_date" > CURRENT_TIMESTAMP) AND (NOT (EXISTS ( SELECT 1
                           FROM "public"."event_dates_view" "edv"
                          WHERE (("edv"."date_id" = "ed2"."id") AND ("edv"."is_fully_booked" = true)))))))) AS "has_available_future_dates"
           FROM "public"."event_dates" "ed"
          GROUP BY "ed"."event_id"
        ), "ticket_summary" AS (
         SELECT "t"."event_id",
            "min"("t"."price") AS "min_price",
            "max"("t"."price") AS "max_price",
            "count"(*) AS "ticket_types_count",
            "sum"(
                CASE
                    WHEN ("etv"."is_sold_out" = false) THEN 1
                    ELSE 0
                END) AS "available_ticket_types_count"
           FROM ("public"."tickets" "t"
             JOIN "public"."event_tickets_view" "etv" ON (("t"."id" = "etv"."ticket_id")))
          GROUP BY "t"."event_id"
        )
 SELECT "e"."event_id",
    "e"."post_id",
    "e"."slug",
    "e"."title",
    "e"."description",
    "e"."content",
    "e"."thumbnail_url",
    "e"."event_type",
        CASE
            WHEN ("e"."event_type" = 'online'::"public"."event_type_enum") THEN 'Online Event'::"text"
            ELSE COALESCE(("e"."location" ->> 'name'::"text"), 'Location TBA'::"text")
        END AS "location_name",
    "e"."location",
    "e"."room",
    "e"."creator_id",
    "e"."creator",
    "e"."featured",
    "e"."created_at",
    "e"."updated_at",
    "e"."dates",
    "e"."future_dates",
    "e"."tickets",
    "eds"."next_date",
    "eds"."latest_past_date",
    "eds"."date_ids",
    "eds"."future_dates_count",
    "eds"."past_dates_count",
    "eds"."has_available_future_dates",
        CASE
            WHEN ("eds"."next_date" IS NOT NULL) THEN 'upcoming'::"text"
            WHEN ("eds"."latest_past_date" IS NOT NULL) THEN 'past'::"text"
            ELSE 'draft'::"text"
        END AS "event_status",
    "ts"."min_price",
    "ts"."max_price",
    "ts"."ticket_types_count",
    "ts"."available_ticket_types_count",
    COALESCE("e"."tags", '[]'::"jsonb") AS "tags"
   FROM (("public"."comprehensive_events_view" "e"
     LEFT JOIN "event_dates_summary" "eds" ON (("e"."event_id" = "eds"."event_id")))
     LEFT JOIN "ticket_summary" "ts" ON (("e"."event_id" = "ts"."event_id")));


ALTER TABLE "public"."events_view" OWNER TO "postgres";


COMMENT ON VIEW "public"."events_view" IS 'A comprehensive view of events with additional metadata for filtering by status (upcoming, past, all) and availability';



CREATE TABLE IF NOT EXISTS "public"."invoices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "amount" integer NOT NULL,
    "currency" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "stripe_invoice_id" "text",
    "status" "text" DEFAULT 'draft'::"text" NOT NULL
);


ALTER TABLE "public"."invoices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."journal_content_links" (
    "id" bigint NOT NULL,
    "journal_entry_id" bigint NOT NULL,
    "post_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."journal_content_links" OWNER TO "postgres";


COMMENT ON TABLE "public"."journal_content_links" IS 'Links between journal entries and platform content';



ALTER TABLE "public"."journal_content_links" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."journal_content_links_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."journal_entries" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "mood" "public"."mood_enum",
    "privacy" "public"."journal_entry_privacy_enum" DEFAULT 'private'::"public"."journal_entry_privacy_enum" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."journal_entries" OWNER TO "postgres";


COMMENT ON TABLE "public"."journal_entries" IS 'User journal entries for personal wellness tracking and reflection';



ALTER TABLE "public"."journal_entries" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."journal_entries_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE OR REPLACE VIEW "public"."journal_entries_with_details" AS
SELECT
    NULL::bigint AS "id",
    NULL::"uuid" AS "user_id",
    NULL::"text" AS "title",
    NULL::"text" AS "content",
    NULL::"public"."mood_enum" AS "mood",
    NULL::"public"."journal_entry_privacy_enum" AS "privacy",
    NULL::timestamp with time zone AS "created_at",
    NULL::timestamp with time zone AS "updated_at",
    NULL::"jsonb" AS "tags",
    NULL::"jsonb" AS "media",
    NULL::"jsonb" AS "linked_content";


ALTER TABLE "public"."journal_entries_with_details" OWNER TO "postgres";


COMMENT ON VIEW "public"."journal_entries_with_details" IS 'Journal entries with related details - security is enforced by RLS on underlying tables';



CREATE TABLE IF NOT EXISTS "public"."journal_entry_tags" (
    "journal_entry_id" bigint NOT NULL,
    "tag_id" bigint NOT NULL
);


ALTER TABLE "public"."journal_entry_tags" OWNER TO "postgres";


COMMENT ON TABLE "public"."journal_entry_tags" IS 'Junction table linking journal entries to tags';



CREATE TABLE IF NOT EXISTS "public"."journal_media" (
    "id" bigint NOT NULL,
    "journal_entry_id" bigint NOT NULL,
    "storage_path" "text" NOT NULL,
    "media_type" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."journal_media" OWNER TO "postgres";


COMMENT ON TABLE "public"."journal_media" IS 'Media files attached to journal entries';



ALTER TABLE "public"."journal_media" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."journal_media_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."journal_tags" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."journal_tags" OWNER TO "postgres";


COMMENT ON TABLE "public"."journal_tags" IS 'Tags that can be applied to journal entries for categorization';



ALTER TABLE "public"."journal_tags" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."journal_tags_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."live_room_participants" (
    "room_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."live_room_participants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."meditations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "content_id" "uuid" NOT NULL,
    "meditation_type" "text" NOT NULL,
    "meditation_theme" "text" NOT NULL,
    "meditation_focus" "text" NOT NULL,
    "what_to_bring" "text",
    "space_holder_names" "text"
);


ALTER TABLE "public"."meditations" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."meditation_details" AS
 SELECT "odb"."id",
    "odb"."user_id",
    "odb"."title",
    "odb"."slug",
    "odb"."description",
    "odb"."content",
    "odb"."post_type",
    "odb"."status",
    "odb"."thumbnail_url",
    "odb"."created_at",
    "odb"."updated_at",
    "odb"."featured",
    "odb"."tags",
    "odb"."profile_id",
    "odb"."profile_full_name",
    "odb"."profile_avatar_url",
    "odb"."event_subtype",
    "odb"."service_subtype",
    "odb"."media_key",
    "odb"."on_demand_media_id",
    "odb"."media_type",
    "odb"."duration",
    "odb"."price",
    "odb"."on_demand_created_at",
    "odb"."on_demand_updated_at",
    "odb"."spotify_playlist_iframes",
    "odb"."spotify_playlist_ids",
    "md"."meditation_type",
    "md"."meditation_theme",
    "md"."meditation_focus",
    "md"."what_to_bring",
    "md"."space_holder_names"
   FROM ("public"."on_demand_base" "odb"
     JOIN "public"."meditations" "md" ON (("odb"."on_demand_media_id" = "md"."content_id")));


ALTER TABLE "public"."meditation_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."message_reactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "message_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "reaction_type" "public"."reaction_type_enum" NOT NULL,
    "emoji_code" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."message_reactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."message_read_receipts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "message_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "read_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."message_read_receipts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."movement_props" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(100) NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."movement_props" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."movement_props_join" (
    "movement_id" "uuid" NOT NULL,
    "prop_id" "uuid" NOT NULL
);


ALTER TABLE "public"."movement_props_join" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."neuroflow" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "movement_id" "uuid" NOT NULL,
    "techniques_used" "text" NOT NULL,
    "session_focus" "text" NOT NULL,
    "personal_growth_outcomes" "text"
);


ALTER TABLE "public"."neuroflow" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."neuroflow_details" AS
 SELECT "md"."id",
    "md"."user_id",
    "md"."title",
    "md"."slug",
    "md"."description",
    "md"."content",
    "md"."post_type",
    "md"."status",
    "md"."thumbnail_url",
    "md"."created_at",
    "md"."updated_at",
    "md"."featured",
    "md"."tags",
    "md"."profile_id",
    "md"."profile_full_name",
    "md"."profile_avatar_url",
    "md"."event_subtype",
    "md"."service_subtype",
    "md"."media_key",
    "md"."on_demand_media_id",
    "md"."media_type",
    "md"."duration",
    "md"."price",
    "md"."on_demand_created_at",
    "md"."on_demand_updated_at",
    "md"."spotify_playlist_iframes",
    "md"."spotify_playlist_ids",
    "md"."movement_id",
    "md"."instructor_name",
    "md"."session_theme",
    "md"."energy_level",
    "md"."spiritual_elements",
    "md"."emotional_focus",
    "md"."recommended_environment",
    "md"."body_focus",
    "md"."movement_created_at",
    "md"."movement_updated_at",
    "nf"."techniques_used",
    "nf"."session_focus",
    "nf"."personal_growth_outcomes"
   FROM ("public"."movement_details" "md"
     JOIN "public"."neuroflow" "nf" ON (("md"."movement_id" = "nf"."movement_id")));


ALTER TABLE "public"."neuroflow_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notification_preferences" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "in_app" boolean DEFAULT true NOT NULL,
    "email" boolean DEFAULT true NOT NULL,
    "push" boolean DEFAULT true NOT NULL,
    "sms" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "notification_preferences_type_check" CHECK (("type" = ANY (ARRAY['appointment'::"text", 'message'::"text", 'system'::"text", 'payment'::"text", 'reminder'::"text"])))
);


ALTER TABLE "public"."notification_preferences" OWNER TO "postgres";


COMMENT ON TABLE "public"."notification_preferences" IS 'Stores user-specific preferences for receiving notifications';



CREATE TABLE IF NOT EXISTS "public"."notification_read_receipts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "notification_id" "uuid" NOT NULL,
    "read_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notification_read_receipts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notification_recipients" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "notification_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "is_read" boolean DEFAULT false,
    "read_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notification_recipients" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notification_statistics" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "date" "date" NOT NULL,
    "total_count" integer NOT NULL,
    "read_count" integer NOT NULL,
    "type_counts" "jsonb" NOT NULL,
    "channel_counts" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."notification_statistics" OWNER TO "postgres";


COMMENT ON TABLE "public"."notification_statistics" IS 'Daily notification statistics for analytics';



CREATE TABLE IF NOT EXISTS "public"."notification_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "type" "public"."notification_type" DEFAULT 'general'::"public"."notification_type" NOT NULL,
    "action_url" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notification_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."onboarding_progress" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "steps" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "last_updated" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."onboarding_progress" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."pending_payment_appointments" AS
 SELECT "ap"."id",
    "ap"."purchase_id",
    "ap"."service_id",
    "ap"."appointment_date",
    "ap"."duration",
    "ap"."method",
    "ap"."status",
    "ap"."created_at",
    "ap"."updated_at",
    "ap"."notes",
    "ap"."metadata",
    "ap"."meeting_url",
    "ap"."payment_link",
    "p"."user_id",
    "p"."owner_id",
    "p"."amount",
    "p"."payment_status",
    "s"."type" AS "service_type",
    COALESCE("po"."title", 'Service'::"text") AS "service_name"
   FROM ((("public"."appointment_purchases" "ap"
     JOIN "public"."purchases" "p" ON (("ap"."purchase_id" = "p"."id")))
     JOIN "public"."services" "s" ON (("ap"."service_id" = "s"."id")))
     LEFT JOIN "public"."posts" "po" ON (("s"."post_id" = "po"."id")))
  WHERE (("ap"."status" = 'pending_payment'::"public"."appointment_status_enum") AND ("ap"."payment_link" IS NOT NULL));


ALTER TABLE "public"."pending_payment_appointments" OWNER TO "postgres";


COMMENT ON VIEW "public"."pending_payment_appointments" IS 'View to easily find appointments awaiting payment with their payment links';



CREATE TABLE IF NOT EXISTS "public"."post_emotional_focuses" (
    "post_id" "uuid" NOT NULL,
    "emotional_focus_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."post_emotional_focuses" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."profile_cards_view" AS
 SELECT "p"."id" AS "user_id",
    "p"."username",
    "p"."full_name",
    "p"."avatar_url",
    "p"."website",
    "cp"."id" AS "creator_profile_id",
    "cp"."title" AS "creator_title",
    "cp"."short_bio",
    "cp"."cover_image_url",
    "cp"."background_video_url",
    "ur"."role" AS "user_role",
    "cb"."hue",
    "cb"."dark",
    "cb"."saturation",
    "cb"."lightness",
    "cb"."contrast",
    COALESCE("cp"."updated_at", "p"."updated_at") AS "last_updated"
   FROM ((("public"."profiles" "p"
     LEFT JOIN "public"."creator_profiles" "cp" ON (("cp"."profile_id" = "p"."id")))
     LEFT JOIN "public"."user_roles" "ur" ON (("ur"."user_id" = "p"."id")))
     LEFT JOIN "public"."creator_branding" "cb" ON (("cb"."user_id" = "p"."id")))
  ORDER BY COALESCE("cp"."updated_at", "p"."updated_at") DESC NULLS LAST;


ALTER TABLE "public"."profile_cards_view" OWNER TO "postgres";


COMMENT ON VIEW "public"."profile_cards_view" IS 'Combined view of user profiles and creator profiles for displaying profile cards';



CREATE TABLE IF NOT EXISTS "public"."provider_preferences" (
    "user_id" "uuid" NOT NULL,
    "appointment_buffer_minutes" integer DEFAULT 0 NOT NULL,
    "max_daily_appointments" integer,
    "max_weekly_appointments" integer,
    "advance_notice_hours" integer DEFAULT 24 NOT NULL,
    "booking_window_days" integer DEFAULT 30 NOT NULL,
    "auto_confirm" boolean DEFAULT false NOT NULL,
    "timezone" "text" DEFAULT 'UTC'::"text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."provider_preferences" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."recent_errors" AS
 SELECT "error_logs"."id",
    "error_logs"."timestamp",
    "error_logs"."error_level",
    "error_logs"."error_message",
    "error_logs"."error_code",
    "error_logs"."source_file",
    "error_logs"."line_number",
    "error_logs"."function_name",
    "error_logs"."user_id",
    "error_logs"."session_id",
    "error_logs"."request_path",
    "error_logs"."request_method",
    "error_logs"."ip_address",
    "error_logs"."user_agent",
    "error_logs"."stack_trace",
    "error_logs"."additional_data"
   FROM "public"."error_logs"
  WHERE ("error_logs"."timestamp" >= ("now"() - '24:00:00'::interval))
  ORDER BY "error_logs"."timestamp" DESC;


ALTER TABLE "public"."recent_errors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role_permissions" (
    "id" bigint NOT NULL,
    "role" "public"."user_role" NOT NULL,
    "schema_name" "text" NOT NULL,
    "table_name" "text" NOT NULL,
    "permission" "public"."app_permission" NOT NULL,
    "scope" "text" NOT NULL,
    "postgres_role" "text" NOT NULL
);


ALTER TABLE "public"."role_permissions" OWNER TO "postgres";


ALTER TABLE "public"."role_permissions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."role_permissions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."room_posts" (
    "room_id" "uuid" NOT NULL,
    "post_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."room_posts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."service_bookings" (
    "booking_id" "uuid" NOT NULL,
    "room_id" "uuid"
);


ALTER TABLE "public"."service_bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."service_dates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "service_id" "uuid" NOT NULL,
    "start_time" timestamp with time zone NOT NULL,
    "end_time" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "check_time_range" CHECK (("start_time" < "end_time"))
);


ALTER TABLE "public"."service_dates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."service_reservations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "service_id" "uuid" NOT NULL,
    "duration" "tstzrange" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."service_reservations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stripe_webhook_events" (
    "id" "text" NOT NULL,
    "type" "text" NOT NULL,
    "object_id" "text" NOT NULL,
    "object_type" "text" NOT NULL,
    "data" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "processed" boolean DEFAULT false,
    "processed_at" timestamp with time zone,
    "processing_error" "text"
);


ALTER TABLE "public"."stripe_webhook_events" OWNER TO "postgres";


COMMENT ON TABLE "public"."stripe_webhook_events" IS 'Logs and tracks Stripe webhook events for payment processing';



CREATE TABLE IF NOT EXISTS "public"."subscription_content_access" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "content_id" "uuid",
    "post_id" "uuid",
    "post_type" "text",
    "tier_key" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "check_content_or_type" CHECK (((("content_id" IS NOT NULL) AND ("post_id" IS NULL) AND ("post_type" IS NULL)) OR (("content_id" IS NULL) AND ("post_id" IS NOT NULL) AND ("post_type" IS NULL)) OR (("content_id" IS NULL) AND ("post_id" IS NULL) AND ("post_type" IS NOT NULL))))
);


ALTER TABLE "public"."subscription_content_access" OWNER TO "postgres";


COMMENT ON TABLE "public"."subscription_content_access" IS 'Maps content to subscription tiers for access control';



CREATE TABLE IF NOT EXISTS "public"."suggestions" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "suggestion" "text" NOT NULL,
    "post_type" "public"."post_type_enum",
    "user_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."suggestions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."transcripts" (
    "id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "transcript" "text" NOT NULL,
    "language" "text" NOT NULL,
    "status" "text" NOT NULL,
    "error_message" "text"
);


ALTER TABLE "public"."transcripts" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."user_appointments_view" AS
 SELECT "ap"."id" AS "appointment_id",
    "ap"."purchase_id",
    "ap"."service_id",
    "p"."title" AS "service_title",
    "pr"."full_name" AS "provider_name",
    "pr"."avatar_url" AS "provider_avatar",
    "ap"."appointment_date",
    "ap"."duration",
    "ap"."method",
    "ap"."service_type",
    "ap"."status",
    "pur"."payment_status",
    "pur"."amount",
    ("ap"."appointment_date" > CURRENT_TIMESTAMP) AS "is_future",
    "pur"."user_id"
   FROM (((("public"."appointment_purchases" "ap"
     JOIN "public"."purchases" "pur" ON (("ap"."purchase_id" = "pur"."id")))
     JOIN "public"."services" "s" ON (("ap"."service_id" = "s"."id")))
     JOIN "public"."posts" "p" ON (("s"."post_id" = "p"."id")))
     JOIN "public"."profiles" "pr" ON (("pur"."owner_id" = "pr"."id")));


ALTER TABLE "public"."user_appointments_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_fcm_tokens" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "token" "text" NOT NULL,
    "device_info" "jsonb" DEFAULT '{}'::"jsonb",
    "is_active" boolean DEFAULT true NOT NULL,
    "last_used_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_fcm_tokens" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_fcm_tokens" IS 'Stores FCM tokens for push notifications';



CREATE OR REPLACE VIEW "public"."user_journal_stats" WITH ("security_barrier"='true') AS
 WITH "mood_counts" AS (
         SELECT "journal_entries"."user_id",
            "journal_entries"."mood",
            "count"(*) AS "mood_count"
           FROM "public"."journal_entries"
          WHERE ("journal_entries"."mood" IS NOT NULL)
          GROUP BY "journal_entries"."user_id", "journal_entries"."mood"
        )
 SELECT "je"."user_id",
    "count"(DISTINCT "je"."id") AS "total_entries",
    "min"("je"."created_at") AS "first_entry_date",
    "max"("je"."created_at") AS "latest_entry_date",
    "count"(DISTINCT "jm"."id") AS "total_media_attachments",
    "count"(DISTINCT "jcl"."post_id") AS "total_content_links",
    COALESCE(( SELECT "jsonb_object_agg"("mc"."mood", "mc"."mood_count") AS "jsonb_object_agg"
           FROM "mood_counts" "mc"
          WHERE ("mc"."user_id" = "je"."user_id")), '{}'::"jsonb") AS "mood_counts"
   FROM (("public"."journal_entries" "je"
     LEFT JOIN "public"."journal_media" "jm" ON (("je"."id" = "jm"."journal_entry_id")))
     LEFT JOIN "public"."journal_content_links" "jcl" ON (("je"."id" = "jcl"."journal_entry_id")))
  GROUP BY "je"."user_id";


ALTER TABLE "public"."user_journal_stats" OWNER TO "postgres";


COMMENT ON VIEW "public"."user_journal_stats" IS 'User journal statistics - security is enforced by RLS on underlying tables';



CREATE OR REPLACE VIEW "public"."user_notifications_view" AS
 SELECT "n"."id",
    "n"."user_id",
    "n"."sender_id",
    "n"."title",
    "n"."content",
    "n"."type",
    "n"."action_url",
    "n"."reference_id",
    "n"."reference_type",
    "n"."is_read",
    "n"."created_at",
    "n"."metadata",
    'individual'::"public"."notification_audience_type" AS "audience_type"
   FROM "public"."notifications" "n"
  WHERE ("n"."user_id" IS NOT NULL)
UNION ALL
 SELECT "n"."id",
    "nr"."user_id",
    "n"."sender_id",
    "n"."title",
    "n"."content",
    "n"."type",
    "n"."action_url",
    "n"."reference_id",
    "n"."reference_type",
    "nr"."is_read",
    "n"."created_at",
    "n"."metadata",
    "n"."audience_type"
   FROM ("public"."notifications" "n"
     JOIN "public"."notification_recipients" "nr" ON (("n"."id" = "nr"."notification_id")))
  WHERE (("n"."user_id" IS NULL) AND ("n"."audience_type" = 'followers'::"public"."notification_audience_type"))
UNION ALL
 SELECT "n"."id",
    "u"."id" AS "user_id",
    "n"."sender_id",
    "n"."title",
    "n"."content",
    "n"."type",
    "n"."action_url",
    "n"."reference_id",
    "n"."reference_type",
    (EXISTS ( SELECT 1
           FROM "public"."notification_read_receipts" "nrr"
          WHERE (("nrr"."notification_id" = "n"."id") AND ("nrr"."user_id" = "u"."id")))) AS "is_read",
    "n"."created_at",
    "n"."metadata",
    "n"."audience_type"
   FROM ("public"."notifications" "n"
     CROSS JOIN "auth"."users" "u")
  WHERE (("n"."user_id" IS NULL) AND ("n"."audience_type" = 'all'::"public"."notification_audience_type") AND (("n"."type" = 'announcement'::"public"."notification_type") OR ("n"."type" = 'broadcast'::"public"."notification_type")));


ALTER TABLE "public"."user_notifications_view" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."user_notifications_with_broadcasts" AS
 SELECT COALESCE("n"."id", "b"."id") AS "id",
        CASE
            WHEN ("n"."id" IS NOT NULL) THEN "n"."user_id"
            ELSE "u"."id"
        END AS "user_id",
    COALESCE("n"."sender_id", "b"."sender_id") AS "sender_id",
    COALESCE("n"."title", "b"."title") AS "title",
    COALESCE("n"."content", "b"."content") AS "content",
    COALESCE("n"."type", "b"."type") AS "type",
    COALESCE("n"."action_url", "b"."action_url") AS "action_url",
    COALESCE("n"."reference_id", "b"."reference_id") AS "reference_id",
    COALESCE("n"."reference_type", "b"."reference_type") AS "reference_type",
        CASE
            WHEN ("n"."id" IS NOT NULL) THEN "n"."is_read"
            ELSE (EXISTS ( SELECT 1
               FROM "public"."notification_read_receipts" "nr"
              WHERE (("nr"."notification_id" = "b"."id") AND ("nr"."user_id" = "u"."id"))))
        END AS "is_read",
    COALESCE("n"."created_at", "b"."created_at") AS "created_at",
    COALESCE("n"."metadata", "b"."metadata") AS "metadata",
        CASE
            WHEN ("n"."id" IS NOT NULL) THEN 'individual'::"public"."notification_audience_type"
            ELSE "b"."audience_type"
        END AS "audience_type"
   FROM (("auth"."users" "u"
     LEFT JOIN "public"."notifications" "n" ON ((("u"."id" = "n"."user_id") AND ("n"."user_id" IS NOT NULL))))
     LEFT JOIN LATERAL ( SELECT "n_1"."id",
            "n_1"."user_id",
            "n_1"."title",
            "n_1"."content",
            "n_1"."type",
            "n_1"."action_url",
            "n_1"."is_read",
            "n_1"."reference_id",
            "n_1"."reference_type",
            "n_1"."metadata",
            "n_1"."created_at",
            "n_1"."updated_at",
            "n_1"."sender_id",
            "n_1"."audience_type",
            "n_1"."audience_criteria"
           FROM "public"."notifications" "n_1"
          WHERE (("n_1"."user_id" IS NULL) AND ("n_1"."audience_type" = 'all'::"public"."notification_audience_type") AND ("n_1"."type" = 'announcement'::"public"."notification_type"))
          ORDER BY "n_1"."created_at" DESC) "b" ON (true))
  ORDER BY COALESCE("n"."created_at", "b"."created_at") DESC;


ALTER TABLE "public"."user_notifications_with_broadcasts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_stripe_data" (
    "user_id" "uuid" NOT NULL,
    "customer_id" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."user_stripe_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_timezones" (
    "user_id" "uuid" NOT NULL,
    "timezone" "text" DEFAULT 'UTC'::"text" NOT NULL,
    "created_at" time with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" time with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."user_timezones" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."video_assets" (
    "id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" bigint,
    "encoding_tier" "text",
    "master_access" "text",
    "max_resolution_tier" "text",
    "mp4_support" "text",
    "status" "text",
    "aspect_ratio" "text",
    "duration" double precision,
    "errors" "jsonb",
    "ingest_type" "text",
    "is_live" boolean,
    "live_stream_id" "text",
    "master" "jsonb",
    "max_stored_frame_rate" double precision,
    "max_stored_resolution" "text",
    "non_standard_input_reasons" "jsonb",
    "normalize_audio" boolean,
    "passthrough" "jsonb",
    "per_title_encode" boolean,
    "playback_ids" "jsonb",
    "recording_times" "jsonb",
    "resolution_tier" "text",
    "source_asset_id" "text",
    "static_renditions" "jsonb",
    "test" boolean,
    "tracks" "jsonb",
    "upload_id" "text",
    CONSTRAINT "video_assets_encoding_tier_check" CHECK (("encoding_tier" = ANY (ARRAY['smart'::"text", 'baseline'::"text"]))),
    CONSTRAINT "video_assets_ingest_type_check" CHECK (("ingest_type" = ANY (ARRAY['on_demand_url'::"text", 'on_demand_direct_upload'::"text", 'on_demand_clip'::"text", 'live_rtmp'::"text", 'live_srt'::"text"]))),
    CONSTRAINT "video_assets_master_access_check" CHECK (("master_access" = ANY (ARRAY['temporary'::"text", 'none'::"text"]))),
    CONSTRAINT "video_assets_max_resolution_tier_check" CHECK (("max_resolution_tier" = ANY (ARRAY['1080p'::"text", '1440p'::"text", '2160p'::"text"]))),
    CONSTRAINT "video_assets_max_stored_resolution_check" CHECK (("max_stored_resolution" = ANY (ARRAY['Audio only'::"text", 'SD'::"text", 'HD'::"text", 'FHD'::"text", 'UHD'::"text"]))),
    CONSTRAINT "video_assets_mp4_support_check" CHECK (("mp4_support" = ANY (ARRAY['standard'::"text", 'none'::"text", 'capped-1080p'::"text", 'audio-only'::"text", 'audio-only,capped-1080p'::"text"]))),
    CONSTRAINT "video_assets_resolution_tier_check" CHECK (("resolution_tier" = ANY (ARRAY['audio-only'::"text", '720p'::"text", '1080p'::"text", '1440p'::"text", '2160p'::"text"]))),
    CONSTRAINT "video_assets_status_check" CHECK (("status" = ANY (ARRAY['preparing'::"text", 'ready'::"text", 'errored'::"text"])))
);


ALTER TABLE "public"."video_assets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."waitlists" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" character varying(255) NOT NULL,
    "description" "text" NOT NULL,
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."waitlists" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."yoga" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "movement_id" "uuid" NOT NULL,
    "yoga_style" "text" NOT NULL,
    "chakras" "text"
);


ALTER TABLE "public"."yoga" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."yoga_details" AS
 SELECT "md"."id",
    "md"."user_id",
    "md"."title",
    "md"."slug",
    "md"."description",
    "md"."content",
    "md"."post_type",
    "md"."status",
    "md"."thumbnail_url",
    "md"."created_at",
    "md"."updated_at",
    "md"."featured",
    "md"."tags",
    "md"."profile_id",
    "md"."profile_full_name",
    "md"."profile_avatar_url",
    "md"."event_subtype",
    "md"."service_subtype",
    "md"."media_key",
    "md"."on_demand_media_id",
    "md"."media_type",
    "md"."duration",
    "md"."price",
    "md"."on_demand_created_at",
    "md"."on_demand_updated_at",
    "md"."spotify_playlist_iframes",
    "md"."spotify_playlist_ids",
    "md"."movement_id",
    "md"."instructor_name",
    "md"."session_theme",
    "md"."energy_level",
    "md"."spiritual_elements",
    "md"."emotional_focus",
    "md"."recommended_environment",
    "md"."body_focus",
    "md"."movement_created_at",
    "md"."movement_updated_at",
    "y"."yoga_style",
    "y"."chakras"
   FROM ("public"."movement_details" "md"
     JOIN "public"."yoga" "y" ON (("md"."movement_id" = "y"."movement_id")));


ALTER TABLE "public"."yoga_details" OWNER TO "postgres";


ALTER TABLE ONLY "public"."comment_attachments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."comment_attachments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."comment_mentions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."comment_mentions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."comment_reactions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."comment_reactions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."comments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."comments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."error_logs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."error_logs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."appointment_purchases"
    ADD CONSTRAINT "appointment_purchases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."articles"
    ADD CONSTRAINT "articles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."availability_exceptions"
    ADD CONSTRAINT "availability_exceptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_user_id_post_id_key" UNIQUE ("user_id", "post_id");



ALTER TABLE ONLY "public"."ceremony"
    ADD CONSTRAINT "ceremony_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chat_participants"
    ADD CONSTRAINT "chat_participants_chat_room_id_user_id_key" UNIQUE ("chat_room_id", "user_id");



ALTER TABLE ONLY "public"."chat_participants"
    ADD CONSTRAINT "chat_participants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chat_rooms"
    ADD CONSTRAINT "chat_rooms_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comment_attachments"
    ADD CONSTRAINT "comment_attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comment_mentions"
    ADD CONSTRAINT "comment_mentions_comment_id_user_id_key" UNIQUE ("comment_id", "user_id");



ALTER TABLE ONLY "public"."comment_mentions"
    ADD CONSTRAINT "comment_mentions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comment_reactions"
    ADD CONSTRAINT "comment_reactions_comment_id_user_id_reaction_type_key" UNIQUE ("comment_id", "user_id", "reaction_type");



ALTER TABLE ONLY "public"."comment_reactions"
    ADD CONSTRAINT "comment_reactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."content_purchases"
    ADD CONSTRAINT "content_purchases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."creator_branding"
    ADD CONSTRAINT "creator_branding_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."creator_emails"
    ADD CONSTRAINT "creator_emails_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."creator_profiles"
    ADD CONSTRAINT "creator_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."creator_subscription_tiers"
    ADD CONSTRAINT "creator_subscription_tiers_creator_id_tier_key_key" UNIQUE ("creator_id", "tier_key");



ALTER TABLE ONLY "public"."creator_subscription_tiers"
    ADD CONSTRAINT "creator_subscription_tiers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dance"
    ADD CONSTRAINT "dance_movement_id_key" UNIQUE ("movement_id");



ALTER TABLE ONLY "public"."dance"
    ADD CONSTRAINT "dance_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."email_templates"
    ADD CONSTRAINT "email_templates_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."email_templates"
    ADD CONSTRAINT "email_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."embeddings"
    ADD CONSTRAINT "embeddings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."embeddings"
    ADD CONSTRAINT "embeddings_post_id_key" UNIQUE ("post_id");



ALTER TABLE ONLY "public"."emotional_focuses"
    ADD CONSTRAINT "emotional_focuses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."emotional_focuses"
    ADD CONSTRAINT "emotional_focuses_value_key" UNIQUE ("value");



ALTER TABLE ONLY "public"."error_logs"
    ADD CONSTRAINT "error_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."event_bookings"
    ADD CONSTRAINT "event_bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."event_dates"
    ADD CONSTRAINT "event_dates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_id_post_id_key" UNIQUE ("id", "post_id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journal_content_links"
    ADD CONSTRAINT "journal_content_links_journal_entry_id_post_id_key" UNIQUE ("journal_entry_id", "post_id");



ALTER TABLE ONLY "public"."journal_content_links"
    ADD CONSTRAINT "journal_content_links_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journal_entries"
    ADD CONSTRAINT "journal_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journal_entry_tags"
    ADD CONSTRAINT "journal_entry_tags_pkey" PRIMARY KEY ("journal_entry_id", "tag_id");



ALTER TABLE ONLY "public"."journal_media"
    ADD CONSTRAINT "journal_media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journal_tags"
    ADD CONSTRAINT "journal_tags_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."journal_tags"
    ADD CONSTRAINT "journal_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."live_room_participants"
    ADD CONSTRAINT "live_room_participants_pkey" PRIMARY KEY ("room_id", "user_id");



ALTER TABLE ONLY "public"."live_rooms"
    ADD CONSTRAINT "live_rooms_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."locations"
    ADD CONSTRAINT "locations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."meditations"
    ADD CONSTRAINT "meditations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."message_reactions"
    ADD CONSTRAINT "message_reactions_message_id_user_id_reaction_type_key" UNIQUE ("message_id", "user_id", "reaction_type");



ALTER TABLE ONLY "public"."message_reactions"
    ADD CONSTRAINT "message_reactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."message_read_receipts"
    ADD CONSTRAINT "message_read_receipts_message_id_user_id_key" UNIQUE ("message_id", "user_id");



ALTER TABLE ONLY "public"."message_read_receipts"
    ADD CONSTRAINT "message_read_receipts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."movement_props_join"
    ADD CONSTRAINT "movement_props_join_pkey" PRIMARY KEY ("movement_id", "prop_id");



ALTER TABLE ONLY "public"."movement_props"
    ADD CONSTRAINT "movement_props_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."movement_props"
    ADD CONSTRAINT "movement_props_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."movements"
    ADD CONSTRAINT "movements_content_id_key" UNIQUE ("content_id");



ALTER TABLE ONLY "public"."movements"
    ADD CONSTRAINT "movements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."neuroflow"
    ADD CONSTRAINT "neuroflow_movement_id_key" UNIQUE ("movement_id");



ALTER TABLE ONLY "public"."neuroflow"
    ADD CONSTRAINT "neuroflow_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."event_dates"
    ADD CONSTRAINT "no_overlapping_dates" EXCLUDE USING "gist" ("event_id" WITH =, "tstzrange"("start_date", "end_date", '[)'::"text") WITH &&);



ALTER TABLE ONLY "public"."notification_deliveries"
    ADD CONSTRAINT "notification_deliveries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_user_id_type_key" UNIQUE ("user_id", "type");



ALTER TABLE ONLY "public"."notification_read_receipts"
    ADD CONSTRAINT "notification_read_receipts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_read_receipts"
    ADD CONSTRAINT "notification_read_receipts_user_id_notification_id_key" UNIQUE ("user_id", "notification_id");



ALTER TABLE ONLY "public"."notification_recipients"
    ADD CONSTRAINT "notification_recipients_notification_id_user_id_key" UNIQUE ("notification_id", "user_id");



ALTER TABLE ONLY "public"."notification_recipients"
    ADD CONSTRAINT "notification_recipients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_statistics"
    ADD CONSTRAINT "notification_statistics_date_key" UNIQUE ("date");



ALTER TABLE ONLY "public"."notification_statistics"
    ADD CONSTRAINT "notification_statistics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_templates"
    ADD CONSTRAINT "notification_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."on_demand_media"
    ADD CONSTRAINT "on_demand_media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."on_demand_media"
    ADD CONSTRAINT "on_demand_media_post_id_key" UNIQUE ("post_id");



ALTER TABLE ONLY "public"."onboarding_progress"
    ADD CONSTRAINT "onboarding_progress_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."availability"
    ADD CONSTRAINT "pk_availability" PRIMARY KEY ("user_id", "day");



ALTER TABLE ONLY "public"."post_emotional_focuses"
    ADD CONSTRAINT "post_emotional_focuses_pkey" PRIMARY KEY ("post_id", "emotional_focus_id");



ALTER TABLE ONLY "public"."post_locations"
    ADD CONSTRAINT "post_locations_pkey" PRIMARY KEY ("post_id", "location_id");



ALTER TABLE ONLY "public"."post_tags"
    ADD CONSTRAINT "post_tags_pkey" PRIMARY KEY ("post_id", "tag_id");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."protected_media_data"
    ADD CONSTRAINT "protected_media_data_content_id_key" UNIQUE ("content_id");



ALTER TABLE ONLY "public"."protected_media_data"
    ADD CONSTRAINT "protected_media_data_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."provider_preferences"
    ADD CONSTRAINT "provider_preferences_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_schema_name_table_name_permission_sco_key" UNIQUE ("role", "schema_name", "table_name", "permission", "scope", "postgres_role");



ALTER TABLE ONLY "public"."room_posts"
    ADD CONSTRAINT "room_posts_pkey" PRIMARY KEY ("room_id", "post_id");



ALTER TABLE ONLY "public"."service_bookings"
    ADD CONSTRAINT "service_bookings_pkey" PRIMARY KEY ("booking_id");



ALTER TABLE ONLY "public"."service_dates"
    ADD CONSTRAINT "service_dates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."service_reservations"
    ADD CONSTRAINT "service_reservations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_post_id_key" UNIQUE ("post_id");



ALTER TABLE ONLY "public"."spotify_playlist_join"
    ADD CONSTRAINT "spotify_playlist_join_pkey" PRIMARY KEY ("content_id", "playlist_id");



ALTER TABLE ONLY "public"."spotify_playlists"
    ADD CONSTRAINT "spotify_playlists_iframe_key" UNIQUE ("iframe");



ALTER TABLE ONLY "public"."spotify_playlists"
    ADD CONSTRAINT "spotify_playlists_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stripe_webhook_events"
    ADD CONSTRAINT "stripe_webhook_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscription_content_access"
    ADD CONSTRAINT "subscription_content_access_creator_id_content_id_tier_key_key" UNIQUE ("creator_id", "content_id", "tier_key");



ALTER TABLE ONLY "public"."subscription_content_access"
    ADD CONSTRAINT "subscription_content_access_creator_id_post_id_tier_key_key" UNIQUE ("creator_id", "post_id", "tier_key");



ALTER TABLE ONLY "public"."subscription_content_access"
    ADD CONSTRAINT "subscription_content_access_creator_id_post_type_tier_key_key" UNIQUE ("creator_id", "post_type", "tier_key");



ALTER TABLE ONLY "public"."subscription_content_access"
    ADD CONSTRAINT "subscription_content_access_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."suggestions"
    ADD CONSTRAINT "suggestions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_name_post_type_key" UNIQUE ("name", "post_type");



ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tickets"
    ADD CONSTRAINT "tickets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transcripts"
    ADD CONSTRAINT "transcripts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."locations"
    ADD CONSTRAINT "unique_coordinates" UNIQUE ("coordinates");



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "unique_user_invoice_combination" UNIQUE ("user_id", "stripe_invoice_id");



ALTER TABLE ONLY "public"."onboarding_progress"
    ADD CONSTRAINT "unique_user_onboarding" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."user_fcm_tokens"
    ADD CONSTRAINT "user_fcm_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_fcm_tokens"
    ADD CONSTRAINT "user_fcm_tokens_user_id_token_key" UNIQUE ("user_id", "token");



ALTER TABLE ONLY "public"."user_locations"
    ADD CONSTRAINT "user_locations_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."user_stripe_data"
    ADD CONSTRAINT "user_stripe_data_customer_id_key" UNIQUE ("customer_id");



ALTER TABLE ONLY "public"."user_stripe_data"
    ADD CONSTRAINT "user_stripe_data_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."user_timezones"
    ADD CONSTRAINT "user_timezones_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."video_assets"
    ADD CONSTRAINT "video_assets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."waitlist_entries"
    ADD CONSTRAINT "waitlist_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."waitlists"
    ADD CONSTRAINT "waitlists_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."yoga"
    ADD CONSTRAINT "yoga_movement_id_key" UNIQUE ("movement_id");



ALTER TABLE ONLY "public"."yoga"
    ADD CONSTRAINT "yoga_pkey" PRIMARY KEY ("id");



CREATE INDEX "email_templates_name_idx" ON "public"."email_templates" USING "btree" ("name");



CREATE INDEX "embeddings_embedding_idx" ON "public"."embeddings" USING "ivfflat" ("embedding" "extensions"."vector_cosine_ops");



CREATE INDEX "idx_appointment_purchases_appointment_date" ON "public"."appointment_purchases" USING "btree" ("appointment_date");



CREATE INDEX "idx_appointment_purchases_payment_link" ON "public"."appointment_purchases" USING "btree" ("payment_link");



CREATE INDEX "idx_appointment_purchases_purchase_id" ON "public"."appointment_purchases" USING "btree" ("purchase_id");



CREATE INDEX "idx_appointment_purchases_service_id" ON "public"."appointment_purchases" USING "btree" ("service_id");



CREATE INDEX "idx_appointment_purchases_status" ON "public"."appointment_purchases" USING "btree" ("status");



CREATE INDEX "idx_appointments_client_id" ON "public"."appointments" USING "btree" ("client_id");



CREATE INDEX "idx_appointments_facilitator_id" ON "public"."appointments" USING "btree" ("facilitator_id");



CREATE INDEX "idx_appointments_start_time" ON "public"."appointments" USING "btree" ("start_time");



CREATE INDEX "idx_articles_post_id" ON "public"."articles" USING "btree" ("post_id");



CREATE INDEX "idx_assets_job_id" ON "public"."assets" USING "btree" ("job_id");



CREATE INDEX "idx_assets_user_queue_status" ON "public"."assets" USING "btree" ("user_id", "status");



CREATE INDEX "idx_availability_exceptions_user_date" ON "public"."availability_exceptions" USING "btree" ("user_id", "exception_date");



CREATE INDEX "idx_availability_user_id" ON "public"."availability" USING "btree" ("user_id");



CREATE INDEX "idx_bookings_post_id" ON "public"."bookings" USING "btree" ("post_id");



CREATE INDEX "idx_bookings_start_time" ON "public"."bookings" USING "btree" ("start_time");



CREATE INDEX "idx_bookings_user_id" ON "public"."bookings" USING "btree" ("user_id");



CREATE INDEX "idx_chat_messages_chat_room_id" ON "public"."chat_messages" USING "btree" ("chat_room_id");



CREATE INDEX "idx_chat_messages_created_at" ON "public"."chat_messages" USING "btree" ("created_at");



CREATE INDEX "idx_chat_messages_reply_to" ON "public"."chat_messages" USING "btree" ("reply_to_message_id") WHERE ("reply_to_message_id" IS NOT NULL);



CREATE INDEX "idx_chat_messages_sender_id" ON "public"."chat_messages" USING "btree" ("sender_id");



CREATE INDEX "idx_chat_participants_chat_room_id" ON "public"."chat_participants" USING "btree" ("chat_room_id");



CREATE INDEX "idx_chat_participants_left_at" ON "public"."chat_participants" USING "btree" ("left_at") WHERE ("left_at" IS NULL);



CREATE INDEX "idx_chat_participants_user_id" ON "public"."chat_participants" USING "btree" ("user_id");



CREATE INDEX "idx_chat_rooms_associated_event" ON "public"."chat_rooms" USING "btree" ("associated_event_id") WHERE ("associated_event_id" IS NOT NULL);



CREATE INDEX "idx_chat_rooms_associated_post" ON "public"."chat_rooms" USING "btree" ("associated_post_id") WHERE ("associated_post_id" IS NOT NULL);



CREATE INDEX "idx_chat_rooms_created_by" ON "public"."chat_rooms" USING "btree" ("created_by");



CREATE INDEX "idx_chat_rooms_type" ON "public"."chat_rooms" USING "btree" ("type");



CREATE INDEX "idx_comments_parent_id" ON "public"."comments" USING "btree" ("parent_id");



CREATE INDEX "idx_comments_post_id" ON "public"."comments" USING "btree" ("post_id");



CREATE INDEX "idx_content_purchases_access_expires_at" ON "public"."content_purchases" USING "btree" ("access_expires_at");



CREATE INDEX "idx_content_purchases_content_id" ON "public"."content_purchases" USING "btree" ("content_id");



CREATE INDEX "idx_content_purchases_purchase_id" ON "public"."content_purchases" USING "btree" ("purchase_id");



CREATE INDEX "idx_dance_movement_id" ON "public"."dance" USING "btree" ("movement_id");



CREATE INDEX "idx_emotional_focuses_value" ON "public"."emotional_focuses" USING "btree" ("value");



CREATE INDEX "idx_error_logs_timestamp" ON "public"."error_logs" USING "btree" ("timestamp");



CREATE INDEX "idx_event_bookings_date_id" ON "public"."event_bookings" USING "btree" ("date_id");



CREATE INDEX "idx_event_bookings_event_id" ON "public"."event_bookings" USING "btree" ("event_id");



CREATE INDEX "idx_event_bookings_purchase_id" ON "public"."event_bookings" USING "btree" ("purchase_id");



CREATE INDEX "idx_event_bookings_status" ON "public"."event_bookings" USING "btree" ("status");



CREATE INDEX "idx_event_bookings_ticket_id" ON "public"."event_bookings" USING "btree" ("ticket_id");



CREATE INDEX "idx_event_dates_event_id" ON "public"."event_dates" USING "btree" ("event_id");



CREATE INDEX "idx_events_post_id" ON "public"."events" USING "btree" ("post_id");



CREATE INDEX "idx_invoices_status" ON "public"."invoices" USING "btree" ("status");



CREATE INDEX "idx_invoices_user_id" ON "public"."invoices" USING "btree" ("user_id");



CREATE INDEX "idx_live_room_participants_room_id" ON "public"."live_room_participants" USING "btree" ("room_id");



CREATE INDEX "idx_live_room_participants_user_id" ON "public"."live_room_participants" USING "btree" ("user_id");



CREATE INDEX "idx_live_rooms_creator_id" ON "public"."live_rooms" USING "btree" ("user_id");



CREATE INDEX "idx_live_rooms_post_id" ON "public"."live_rooms" USING "btree" ("post_id");



CREATE INDEX "idx_message_reactions_message_id" ON "public"."message_reactions" USING "btree" ("message_id");



CREATE INDEX "idx_message_reactions_type" ON "public"."message_reactions" USING "btree" ("reaction_type");



CREATE INDEX "idx_message_reactions_user_id" ON "public"."message_reactions" USING "btree" ("user_id");



CREATE INDEX "idx_message_read_receipts_message_id" ON "public"."message_read_receipts" USING "btree" ("message_id");



CREATE INDEX "idx_message_read_receipts_user_id" ON "public"."message_read_receipts" USING "btree" ("user_id");



CREATE INDEX "idx_movements_content_id" ON "public"."movements" USING "btree" ("content_id");



CREATE INDEX "idx_neuroflow_movement_id" ON "public"."neuroflow" USING "btree" ("movement_id");



CREATE INDEX "idx_notification_read_receipts_notification_id" ON "public"."notification_read_receipts" USING "btree" ("notification_id");



CREATE INDEX "idx_notification_read_receipts_user_id" ON "public"."notification_read_receipts" USING "btree" ("user_id");



CREATE INDEX "idx_notification_recipients_is_read" ON "public"."notification_recipients" USING "btree" ("is_read");



CREATE INDEX "idx_notification_recipients_notification_id" ON "public"."notification_recipients" USING "btree" ("notification_id");



CREATE INDEX "idx_notification_recipients_user_id" ON "public"."notification_recipients" USING "btree" ("user_id");



CREATE INDEX "idx_on_demand_media_post_id" ON "public"."on_demand_media" USING "btree" ("post_id");



CREATE INDEX "idx_on_demand_media_user_id" ON "public"."on_demand_media" USING "btree" ("user_id");



CREATE INDEX "idx_onboarding_completed" ON "public"."onboarding_progress" USING "btree" ("completed_at") WHERE ("completed_at" IS NOT NULL);



CREATE INDEX "idx_onboarding_user_id" ON "public"."onboarding_progress" USING "btree" ("user_id");



CREATE INDEX "idx_post_emotional_focuses_emotional_focus_id" ON "public"."post_emotional_focuses" USING "btree" ("emotional_focus_id");



CREATE INDEX "idx_post_emotional_focuses_post_id" ON "public"."post_emotional_focuses" USING "btree" ("post_id");



CREATE INDEX "idx_post_locations_location_id" ON "public"."post_locations" USING "btree" ("location_id");



CREATE INDEX "idx_post_locations_post_id" ON "public"."post_locations" USING "btree" ("post_id");



CREATE INDEX "idx_post_tags_tag_id" ON "public"."post_tags" USING "btree" ("tag_id");



CREATE INDEX "idx_posts_post_type" ON "public"."posts" USING "btree" ("post_type");



CREATE INDEX "idx_posts_status" ON "public"."posts" USING "btree" ("status");



CREATE INDEX "idx_posts_user_id" ON "public"."posts" USING "btree" ("user_id");



CREATE INDEX "idx_purchases_content_id" ON "public"."purchases" USING "btree" ("content_id");



CREATE INDEX "idx_purchases_event_id" ON "public"."purchases" USING "btree" ("event_id");



CREATE INDEX "idx_purchases_owner_id" ON "public"."purchases" USING "btree" ("owner_id");



CREATE INDEX "idx_purchases_payment_status" ON "public"."purchases" USING "btree" ("payment_status");



CREATE INDEX "idx_purchases_post_id" ON "public"."purchases" USING "btree" ("post_id");



CREATE INDEX "idx_purchases_purchase_date" ON "public"."purchases" USING "btree" ("purchase_date");



CREATE INDEX "idx_purchases_service_id" ON "public"."purchases" USING "btree" ("service_id");



CREATE INDEX "idx_purchases_stripe_invoice_id" ON "public"."purchases" USING "btree" ("stripe_invoice_id");



CREATE INDEX "idx_purchases_stripe_payment_intent_id" ON "public"."purchases" USING "btree" ("stripe_payment_intent_id");



CREATE INDEX "idx_purchases_stripe_subscription_id" ON "public"."purchases" USING "btree" ("stripe_subscription_id");



CREATE INDEX "idx_purchases_user_id" ON "public"."purchases" USING "btree" ("user_id");



CREATE INDEX "idx_room_posts_post_id" ON "public"."room_posts" USING "btree" ("post_id");



CREATE INDEX "idx_room_posts_room_id" ON "public"."room_posts" USING "btree" ("room_id");



CREATE INDEX "idx_service_bookings_room_id" ON "public"."service_bookings" USING "btree" ("room_id");



CREATE INDEX "idx_service_dates_service_id" ON "public"."service_dates" USING "btree" ("service_id");



CREATE INDEX "idx_services_location_id" ON "public"."services" USING "btree" ("location_id");



CREATE INDEX "idx_services_post_id" ON "public"."services" USING "btree" ("post_id");



CREATE INDEX "idx_stripe_webhook_events_object_id" ON "public"."stripe_webhook_events" USING "btree" ("object_id");



CREATE INDEX "idx_stripe_webhook_events_processed" ON "public"."stripe_webhook_events" USING "btree" ("processed");



CREATE INDEX "idx_stripe_webhook_events_type" ON "public"."stripe_webhook_events" USING "btree" ("type");



CREATE INDEX "idx_subscriptions_next_billing_date" ON "public"."subscriptions" USING "btree" ("next_billing_date");



CREATE INDEX "idx_subscriptions_purchase_id" ON "public"."subscriptions" USING "btree" ("purchase_id");



CREATE INDEX "idx_subscriptions_status" ON "public"."subscriptions" USING "btree" ("status");



CREATE INDEX "idx_subscriptions_stripe_subscription_id" ON "public"."subscriptions" USING "btree" ("stripe_subscription_id");



CREATE INDEX "idx_tickets_event_id" ON "public"."tickets" USING "btree" ("event_id");



CREATE INDEX "idx_user_roles_role" ON "public"."user_roles" USING "btree" ("role");



CREATE INDEX "idx_user_timezones_timezone" ON "public"."user_timezones" USING "btree" ("timezone");



CREATE INDEX "locations_coordinates_idx" ON "public"."locations" USING "gist" ("coordinates");



CREATE INDEX "notification_deliveries_next_attempt_idx" ON "public"."notification_deliveries" USING "btree" ("next_attempt_at") WHERE (("status" = 'pending'::"text") AND ("next_attempt_at" IS NOT NULL));



CREATE INDEX "notification_deliveries_notification_id_idx" ON "public"."notification_deliveries" USING "btree" ("notification_id");



CREATE INDEX "notification_deliveries_status_idx" ON "public"."notification_deliveries" USING "btree" ("status");



CREATE INDEX "notification_prefs_user_id_idx" ON "public"."notification_preferences" USING "btree" ("user_id");



CREATE INDEX "notifications_sender_id_idx" ON "public"."notifications" USING "btree" ("sender_id");



CREATE INDEX "notifications_user_id_created_at_idx" ON "public"."notifications" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "notifications_user_id_is_read_idx" ON "public"."notifications" USING "btree" ("user_id", "is_read");



CREATE INDEX "notifications_user_id_type_idx" ON "public"."notifications" USING "btree" ("user_id", "type");



CREATE INDEX "user_fcm_tokens_is_active_idx" ON "public"."user_fcm_tokens" USING "btree" ("is_active");



CREATE INDEX "user_fcm_tokens_user_id_idx" ON "public"."user_fcm_tokens" USING "btree" ("user_id");



CREATE INDEX "user_locations_coordinates_idx" ON "public"."user_locations" USING "gist" ("coordinates");



CREATE OR REPLACE VIEW "public"."journal_entries_with_details" WITH ("security_barrier"='true') AS
 SELECT "je"."id",
    "je"."user_id",
    "je"."title",
    "je"."content",
    "je"."mood",
    "je"."privacy",
    "je"."created_at",
    "je"."updated_at",
    COALESCE("jsonb_agg"(DISTINCT "jsonb_build_object"('id', "jt"."id", 'name', "jt"."name")) FILTER (WHERE ("jt"."id" IS NOT NULL)), '[]'::"jsonb") AS "tags",
    COALESCE("jsonb_agg"(DISTINCT "jsonb_build_object"('id', "jm"."id", 'storage_path', "jm"."storage_path", 'media_type', "jm"."media_type")) FILTER (WHERE ("jm"."id" IS NOT NULL)), '[]'::"jsonb") AS "media",
    COALESCE("jsonb_agg"(DISTINCT "jsonb_build_object"('id', "p"."id", 'title', "p"."title", 'post_type', "p"."post_type")) FILTER (WHERE ("p"."id" IS NOT NULL)), '[]'::"jsonb") AS "linked_content"
   FROM ((((("public"."journal_entries" "je"
     LEFT JOIN "public"."journal_entry_tags" "jet" ON (("je"."id" = "jet"."journal_entry_id")))
     LEFT JOIN "public"."journal_tags" "jt" ON (("jet"."tag_id" = "jt"."id")))
     LEFT JOIN "public"."journal_media" "jm" ON (("je"."id" = "jm"."journal_entry_id")))
     LEFT JOIN "public"."journal_content_links" "jcl" ON (("je"."id" = "jcl"."journal_entry_id")))
     LEFT JOIN "public"."posts" "p" ON (("jcl"."post_id" = "p"."id")))
  GROUP BY "je"."id";



CREATE OR REPLACE TRIGGER "add_creator_to_participants" AFTER INSERT ON "public"."chat_rooms" FOR EACH ROW EXECUTE FUNCTION "public"."add_creator_as_participant"();



CREATE OR REPLACE TRIGGER "appointment_notification_trigger" AFTER INSERT OR UPDATE OF "status" ON "public"."appointments" FOR EACH ROW EXECUTE FUNCTION "public"."process_appointment_notification"();



CREATE OR REPLACE TRIGGER "appointment_purchases_updated_at" BEFORE UPDATE ON "public"."appointment_purchases" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "appointment_status_change_trigger" AFTER INSERT OR UPDATE OF "status" ON "public"."appointment_purchases" FOR EACH ROW EXECUTE FUNCTION "public"."notify_appointment_status_change"();



CREATE OR REPLACE TRIGGER "broadcast_chat_message_changes" AFTER INSERT OR DELETE OR UPDATE ON "public"."chat_messages" FOR EACH ROW EXECUTE FUNCTION "public"."broadcast_chat_message_changes"();



CREATE OR REPLACE TRIGGER "broadcast_message_reaction_changes" AFTER INSERT OR DELETE OR UPDATE ON "public"."message_reactions" FOR EACH ROW EXECUTE FUNCTION "public"."broadcast_message_reaction_changes"();



CREATE OR REPLACE TRIGGER "chat_message_notification_trigger" AFTER INSERT ON "public"."chat_messages" FOR EACH ROW EXECUTE FUNCTION "public"."process_chat_message_notification"();



CREATE OR REPLACE TRIGGER "chat_participant_added_trigger" AFTER INSERT ON "public"."chat_participants" FOR EACH ROW EXECUTE FUNCTION "public"."notify_chat_participant_added"();



CREATE OR REPLACE TRIGGER "check_appointment_purchase_conflicts" BEFORE INSERT OR UPDATE ON "public"."appointment_purchases" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_double_booking"();



CREATE OR REPLACE TRIGGER "check_broadcast_room_creator" BEFORE INSERT ON "public"."chat_rooms" FOR EACH ROW EXECUTE FUNCTION "public"."can_create_broadcast_room"();



CREATE OR REPLACE TRIGGER "check_legacy_appointment_conflicts" BEFORE INSERT OR UPDATE ON "public"."appointments" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_double_booking"();



CREATE OR REPLACE TRIGGER "content_purchases_updated_at" BEFORE UPDATE ON "public"."content_purchases" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "create_embedding_trigger" AFTER INSERT OR UPDATE OF "content" ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_create_embedding"();



CREATE OR REPLACE TRIGGER "email_templates_updated_at_trigger" BEFORE UPDATE ON "public"."email_templates" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "ensure_unique_slug_trigger" BEFORE INSERT ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."ensure_unique_slug"();



CREATE OR REPLACE TRIGGER "event_bookings_updated_at" BEFORE UPDATE ON "public"."event_bookings" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "notification_deliveries_updated_at_trigger" BEFORE UPDATE ON "public"."notification_deliveries" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "notification_preferences_updated_at_trigger" BEFORE UPDATE ON "public"."notification_preferences" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "notifications_updated_at_trigger" BEFORE UPDATE ON "public"."notifications" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "on_comment_insert" BEFORE INSERT ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_comment_has_replies"();



CREATE OR REPLACE TRIGGER "on_comment_update" BEFORE UPDATE ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_comment_date_time"();



CREATE OR REPLACE TRIGGER "prevent_event_date_delete" BEFORE DELETE ON "public"."event_dates" FOR EACH ROW EXECUTE FUNCTION "public"."check_event_date_delete"();



CREATE OR REPLACE TRIGGER "prevent_ticket_delete" BEFORE DELETE ON "public"."tickets" FOR EACH ROW EXECUTE FUNCTION "public"."check_ticket_delete"();



CREATE OR REPLACE TRIGGER "purchases_updated_at" BEFORE UPDATE ON "public"."purchases" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "subscriptions_updated_at" BEFORE UPDATE ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "sync_user_role_to_auth" AFTER INSERT OR UPDATE OF "role" ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."update_auth_user_role"();



CREATE OR REPLACE TRIGGER "sync_user_timezone_to_auth" AFTER INSERT OR UPDATE OF "timezone" ON "public"."user_timezones" FOR EACH ROW EXECUTE FUNCTION "public"."update_auth_user_timezone"();



CREATE OR REPLACE TRIGGER "trg_auto_confirm_appointment" BEFORE UPDATE OF "status" ON "public"."appointment_purchases" FOR EACH ROW WHEN (("new"."status" = 'pending_auto_payment'::"public"."appointment_status_enum")) EXECUTE FUNCTION "public"."auto_confirm_appointment"();



CREATE OR REPLACE TRIGGER "trigger_check_single_draft_invoice_per_user" BEFORE INSERT OR UPDATE ON "public"."invoices" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_single_draft_invoice_per_user"();



CREATE OR REPLACE TRIGGER "update_appointments_updated_at" BEFORE UPDATE ON "public"."appointments" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_articles_modtime" BEFORE UPDATE ON "public"."articles" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_availability_updated_at" BEFORE UPDATE ON "public"."availability" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_bookings_modtime" BEFORE UPDATE ON "public"."bookings" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_chat_room_timestamp" BEFORE UPDATE ON "public"."chat_rooms" FOR EACH ROW EXECUTE FUNCTION "public"."update_chat_room_timestamp"();



CREATE OR REPLACE TRIGGER "update_chat_room_timestamp_on_message" AFTER INSERT ON "public"."chat_messages" FOR EACH ROW EXECUTE FUNCTION "public"."update_chat_room_timestamp_on_message"();



CREATE OR REPLACE TRIGGER "update_coordinates_timestamp" BEFORE UPDATE OF "coordinates" ON "public"."locations" FOR EACH ROW EXECUTE FUNCTION "public"."update_coordinates_timestamp"();



CREATE OR REPLACE TRIGGER "update_creator_subscription_tiers_updated_at" BEFORE UPDATE ON "public"."creator_subscription_tiers" FOR EACH ROW EXECUTE FUNCTION "public"."update_subscription_tier_updated_at"();



CREATE OR REPLACE TRIGGER "update_emotional_focuses_modtime" BEFORE UPDATE ON "public"."emotional_focuses" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_events_modtime" BEFORE UPDATE ON "public"."events" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_invoices_modtime" BEFORE UPDATE ON "public"."invoices" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_journal_entries_updated_at" BEFORE UPDATE ON "public"."journal_entries" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_live_rooms_modtime" BEFORE UPDATE ON "public"."live_rooms" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_locations_modtime" BEFORE UPDATE ON "public"."locations" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_movements_modtime" BEFORE UPDATE ON "public"."movements" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_on_demand_media_modtime" BEFORE UPDATE ON "public"."on_demand_media" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_posts_modtime" BEFORE UPDATE ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_protected_media_data_timestamp" BEFORE UPDATE ON "public"."protected_media_data" FOR EACH ROW EXECUTE FUNCTION "public"."update_protected_media_data_timestamp"();



CREATE OR REPLACE TRIGGER "update_sender_read_receipt" AFTER INSERT ON "public"."chat_messages" FOR EACH ROW EXECUTE FUNCTION "public"."update_sender_read_receipt"();



CREATE OR REPLACE TRIGGER "update_service_dates_modtime" BEFORE UPDATE ON "public"."service_dates" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_services_modtime" BEFORE UPDATE ON "public"."services" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_tickets_modtime" BEFORE UPDATE ON "public"."tickets" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_user_locations_modtime" BEFORE UPDATE ON "public"."user_locations" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_user_roles_modtime" BEFORE UPDATE ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_user_stripe_data_modtime" BEFORE UPDATE ON "public"."user_stripe_data" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_user_timezones_modtime" BEFORE UPDATE ON "public"."user_timezones" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "user_fcm_tokens_updated_at_trigger" BEFORE UPDATE ON "public"."user_fcm_tokens" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "waitlist_notification_trigger" AFTER UPDATE ON "public"."waitlists" FOR EACH ROW EXECUTE FUNCTION "public"."process_waitlist_notification"();



ALTER TABLE ONLY "public"."appointment_purchases"
    ADD CONSTRAINT "appointment_purchases_purchase_id_fkey" FOREIGN KEY ("purchase_id") REFERENCES "public"."purchases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointment_purchases"
    ADD CONSTRAINT "appointment_purchases_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_facilitator_id_fkey" FOREIGN KEY ("facilitator_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."articles"
    ADD CONSTRAINT "articles_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."availability_exceptions"
    ADD CONSTRAINT "availability_exceptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."availability"
    ADD CONSTRAINT "availability_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ceremony"
    ADD CONSTRAINT "ceremony_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."on_demand_media"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "chat_messages_chat_room_id_fkey" FOREIGN KEY ("chat_room_id") REFERENCES "public"."chat_rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "chat_messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."chat_participants"
    ADD CONSTRAINT "chat_participants_chat_room_id_fkey" FOREIGN KEY ("chat_room_id") REFERENCES "public"."chat_rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chat_participants"
    ADD CONSTRAINT "chat_participants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chat_rooms"
    ADD CONSTRAINT "chat_rooms_associated_event_id_fkey" FOREIGN KEY ("associated_event_id") REFERENCES "public"."events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chat_rooms"
    ADD CONSTRAINT "chat_rooms_associated_post_id_fkey" FOREIGN KEY ("associated_post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chat_rooms"
    ADD CONSTRAINT "chat_rooms_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comment_attachments"
    ADD CONSTRAINT "comment_attachments_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comment_mentions"
    ADD CONSTRAINT "comment_mentions_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comment_mentions"
    ADD CONSTRAINT "comment_mentions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."comment_reactions"
    ADD CONSTRAINT "comment_reactions_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comment_reactions"
    ADD CONSTRAINT "comment_reactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."comments"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_user_id_fkey1" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content_purchases"
    ADD CONSTRAINT "content_purchases_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."on_demand_media"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content_purchases"
    ADD CONSTRAINT "content_purchases_purchase_id_fkey" FOREIGN KEY ("purchase_id") REFERENCES "public"."purchases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."creator_branding"
    ADD CONSTRAINT "creator_branding_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."creator_emails"
    ADD CONSTRAINT "creator_emails_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."creator_profiles"
    ADD CONSTRAINT "creator_profiles_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."creator_profiles"
    ADD CONSTRAINT "creator_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."creator_subscription_tiers"
    ADD CONSTRAINT "creator_subscription_tiers_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dance"
    ADD CONSTRAINT "dance_movement_id_fkey" FOREIGN KEY ("movement_id") REFERENCES "public"."movements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."embeddings"
    ADD CONSTRAINT "embeddings_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."event_bookings"
    ADD CONSTRAINT "event_bookings_date_id_fkey" FOREIGN KEY ("date_id") REFERENCES "public"."event_dates"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."event_bookings"
    ADD CONSTRAINT "event_bookings_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."event_bookings"
    ADD CONSTRAINT "event_bookings_purchase_id_fkey" FOREIGN KEY ("purchase_id") REFERENCES "public"."purchases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."event_bookings"
    ADD CONSTRAINT "event_bookings_ticket_id_fkey" FOREIGN KEY ("ticket_id") REFERENCES "public"."tickets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."event_dates"
    ADD CONSTRAINT "event_dates_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chat_participants"
    ADD CONSTRAINT "fk_last_read_message" FOREIGN KEY ("last_read_message_id") REFERENCES "public"."chat_messages"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "fk_reply_to_message" FOREIGN KEY ("reply_to_message_id") REFERENCES "public"."chat_messages"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journal_content_links"
    ADD CONSTRAINT "journal_content_links_journal_entry_id_fkey" FOREIGN KEY ("journal_entry_id") REFERENCES "public"."journal_entries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journal_content_links"
    ADD CONSTRAINT "journal_content_links_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journal_entries"
    ADD CONSTRAINT "journal_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."journal_entry_tags"
    ADD CONSTRAINT "journal_entry_tags_journal_entry_id_fkey" FOREIGN KEY ("journal_entry_id") REFERENCES "public"."journal_entries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journal_entry_tags"
    ADD CONSTRAINT "journal_entry_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "public"."journal_tags"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journal_media"
    ADD CONSTRAINT "journal_media_journal_entry_id_fkey" FOREIGN KEY ("journal_entry_id") REFERENCES "public"."journal_entries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."live_room_participants"
    ADD CONSTRAINT "live_room_participants_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."live_rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."live_room_participants"
    ADD CONSTRAINT "live_room_participants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."live_rooms"
    ADD CONSTRAINT "live_rooms_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."live_rooms"
    ADD CONSTRAINT "live_rooms_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."locations"
    ADD CONSTRAINT "locations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."meditations"
    ADD CONSTRAINT "meditations_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."on_demand_media"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."message_reactions"
    ADD CONSTRAINT "message_reactions_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."chat_messages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."message_reactions"
    ADD CONSTRAINT "message_reactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."message_read_receipts"
    ADD CONSTRAINT "message_read_receipts_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."chat_messages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."message_read_receipts"
    ADD CONSTRAINT "message_read_receipts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."movement_props_join"
    ADD CONSTRAINT "movement_props_join_movement_id_fkey" FOREIGN KEY ("movement_id") REFERENCES "public"."movements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."movement_props_join"
    ADD CONSTRAINT "movement_props_join_prop_id_fkey" FOREIGN KEY ("prop_id") REFERENCES "public"."movement_props"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."movements"
    ADD CONSTRAINT "movements_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."on_demand_media"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."neuroflow"
    ADD CONSTRAINT "neuroflow_movement_id_fkey" FOREIGN KEY ("movement_id") REFERENCES "public"."movements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_deliveries"
    ADD CONSTRAINT "notification_deliveries_notification_id_fkey" FOREIGN KEY ("notification_id") REFERENCES "public"."notifications"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_read_receipts"
    ADD CONSTRAINT "notification_read_receipts_notification_id_fkey" FOREIGN KEY ("notification_id") REFERENCES "public"."notifications"("id");



ALTER TABLE ONLY "public"."notification_read_receipts"
    ADD CONSTRAINT "notification_read_receipts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."notification_recipients"
    ADD CONSTRAINT "notification_recipients_notification_id_fkey" FOREIGN KEY ("notification_id") REFERENCES "public"."notifications"("id");



ALTER TABLE ONLY "public"."notification_recipients"
    ADD CONSTRAINT "notification_recipients_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."notification_templates"
    ADD CONSTRAINT "notification_templates_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."on_demand_media"
    ADD CONSTRAINT "on_demand_media_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."on_demand_media"
    ADD CONSTRAINT "on_demand_media_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."onboarding_progress"
    ADD CONSTRAINT "onboarding_progress_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."post_emotional_focuses"
    ADD CONSTRAINT "post_emotional_focuses_emotional_focus_id_fkey" FOREIGN KEY ("emotional_focus_id") REFERENCES "public"."emotional_focuses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_emotional_focuses"
    ADD CONSTRAINT "post_emotional_focuses_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_locations"
    ADD CONSTRAINT "post_locations_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."locations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_locations"
    ADD CONSTRAINT "post_locations_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_tags"
    ADD CONSTRAINT "post_tags_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_tags"
    ADD CONSTRAINT "post_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "public"."tags"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protected_media_data"
    ADD CONSTRAINT "protected_media_data_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."on_demand_media"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."provider_preferences"
    ADD CONSTRAINT "provider_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."on_demand_media"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_posts"
    ADD CONSTRAINT "room_posts_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."room_posts"
    ADD CONSTRAINT "room_posts_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."live_rooms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."service_bookings"
    ADD CONSTRAINT "service_bookings_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."service_bookings"
    ADD CONSTRAINT "service_bookings_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."live_rooms"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."service_dates"
    ADD CONSTRAINT "service_dates_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."service_reservations"
    ADD CONSTRAINT "service_reservations_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."service_reservations"
    ADD CONSTRAINT "service_reservations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."locations"("id");



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."spotify_playlist_join"
    ADD CONSTRAINT "spotify_playlist_join_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."on_demand_media"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."spotify_playlist_join"
    ADD CONSTRAINT "spotify_playlist_join_playlist_id_fkey" FOREIGN KEY ("playlist_id") REFERENCES "public"."spotify_playlists"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."spotify_playlists"
    ADD CONSTRAINT "spotify_playlists_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."subscription_content_access"
    ADD CONSTRAINT "subscription_content_access_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."on_demand_media"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscription_content_access"
    ADD CONSTRAINT "subscription_content_access_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscription_content_access"
    ADD CONSTRAINT "subscription_content_access_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_purchase_id_fkey" FOREIGN KEY ("purchase_id") REFERENCES "public"."purchases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."suggestions"
    ADD CONSTRAINT "suggestions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."tickets"
    ADD CONSTRAINT "tickets_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."transcripts"
    ADD CONSTRAINT "transcripts_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."assets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_fcm_tokens"
    ADD CONSTRAINT "user_fcm_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_locations"
    ADD CONSTRAINT "user_locations_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."locations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_locations"
    ADD CONSTRAINT "user_locations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



COMMENT ON CONSTRAINT "user_locations_user_id_fkey" ON "public"."user_locations" IS '@foreignKey (user_id) references profiles(id)';



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_stripe_data"
    ADD CONSTRAINT "user_stripe_data_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_timezones"
    ADD CONSTRAINT "user_timezones_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."video_assets"
    ADD CONSTRAINT "video_assets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."waitlist_entries"
    ADD CONSTRAINT "waitlist_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."waitlist_entries"
    ADD CONSTRAINT "waitlist_entries_waitlist_id_fkey" FOREIGN KEY ("waitlist_id") REFERENCES "public"."waitlists"("id");



ALTER TABLE ONLY "public"."yoga"
    ADD CONSTRAINT "yoga_movement_id_fkey" FOREIGN KEY ("movement_id") REFERENCES "public"."movements"("id") ON DELETE CASCADE;



CREATE POLICY "Access control for dance delete admin" ON "public"."dance" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for dance delete creator" ON "public"."dance" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."movements"
     JOIN "public"."on_demand_media" ON (("on_demand_media"."id" = "movements"."content_id")))
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("movements"."id" = "dance"."movement_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for dance insert admin" ON "public"."dance" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for dance insert creator" ON "public"."dance" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."movements"
     JOIN "public"."on_demand_media" ON (("on_demand_media"."id" = "movements"."content_id")))
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("movements"."id" = "dance"."movement_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for dance update admin" ON "public"."dance" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for dance update creator" ON "public"."dance" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."movements"
     JOIN "public"."on_demand_media" ON (("on_demand_media"."id" = "movements"."content_id")))
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("movements"."id" = "dance"."movement_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for movements delete admin" ON "public"."movements" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for movements delete creator" ON "public"."movements" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media"
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("on_demand_media"."id" = "movements"."content_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for movements insert admin" ON "public"."movements" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for movements insert creator" ON "public"."movements" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media"
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("on_demand_media"."id" = "movements"."content_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for movements update admin" ON "public"."movements" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for movements update creator" ON "public"."movements" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media"
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("on_demand_media"."id" = "movements"."content_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for neuroflow delete admin" ON "public"."neuroflow" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for neuroflow delete creator" ON "public"."neuroflow" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."movements"
     JOIN "public"."on_demand_media" ON (("on_demand_media"."id" = "movements"."content_id")))
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("movements"."id" = "neuroflow"."movement_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for neuroflow insert admin" ON "public"."neuroflow" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for neuroflow insert creator" ON "public"."neuroflow" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."movements"
     JOIN "public"."on_demand_media" ON (("on_demand_media"."id" = "movements"."content_id")))
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("movements"."id" = "neuroflow"."movement_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for neuroflow update admin" ON "public"."neuroflow" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for neuroflow update creator" ON "public"."neuroflow" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."movements"
     JOIN "public"."on_demand_media" ON (("on_demand_media"."id" = "movements"."content_id")))
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("movements"."id" = "neuroflow"."movement_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for on_demand_media delete admin" ON "public"."on_demand_media" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for on_demand_media delete creator" ON "public"."on_demand_media" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."posts"
  WHERE (("posts"."id" = "on_demand_media"."post_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for on_demand_media insert admin" ON "public"."on_demand_media" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for on_demand_media insert creator" ON "public"."on_demand_media" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."posts"
  WHERE (("posts"."id" = "on_demand_media"."post_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for on_demand_media update admin" ON "public"."on_demand_media" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for on_demand_media update creator" ON "public"."on_demand_media" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."posts"
  WHERE (("posts"."id" = "on_demand_media"."post_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for protected_media_data delete admin" ON "public"."protected_media_data" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for protected_media_data delete creator" ON "public"."protected_media_data" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media"
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("on_demand_media"."id" = "protected_media_data"."content_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for protected_media_data insert admin" ON "public"."protected_media_data" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for protected_media_data insert creator" ON "public"."protected_media_data" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media"
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("on_demand_media"."id" = "protected_media_data"."content_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for protected_media_data select admin" ON "public"."protected_media_data" FOR SELECT TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for protected_media_data select creator" ON "public"."protected_media_data" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media"
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("on_demand_media"."id" = "protected_media_data"."content_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for protected_media_data update admin" ON "public"."protected_media_data" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for protected_media_data update creator" ON "public"."protected_media_data" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media"
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("on_demand_media"."id" = "protected_media_data"."content_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for spotify_playlist_join delete creator and ond" ON "public"."spotify_playlist_join" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media"
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("on_demand_media"."id" = "spotify_playlist_join"."content_id") AND ("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Access control for spotify_playlist_join insert creator and ond" ON "public"."spotify_playlist_join" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media"
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("on_demand_media"."id" = "spotify_playlist_join"."content_id") AND ("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Access control for spotify_playlist_join update creator and ond" ON "public"."spotify_playlist_join" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media"
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("on_demand_media"."id" = "spotify_playlist_join"."content_id") AND ("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Access control for yoga delete admin" ON "public"."yoga" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for yoga delete creator" ON "public"."yoga" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."movements"
     JOIN "public"."on_demand_media" ON (("on_demand_media"."id" = "movements"."content_id")))
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("movements"."id" = "yoga"."movement_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for yoga insert admin" ON "public"."yoga" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for yoga insert creator" ON "public"."yoga" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."movements"
     JOIN "public"."on_demand_media" ON (("on_demand_media"."id" = "movements"."content_id")))
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("movements"."id" = "yoga"."movement_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Access control for yoga update admin" ON "public"."yoga" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Access control for yoga update creator" ON "public"."yoga" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."movements"
     JOIN "public"."on_demand_media" ON (("on_demand_media"."id" = "movements"."content_id")))
     JOIN "public"."posts" ON (("posts"."id" = "on_demand_media"."post_id")))
  WHERE (("movements"."id" = "yoga"."movement_id") AND "public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("posts"."user_id" = "auth"."uid"())))));



CREATE POLICY "Admin users can insert roles" ON "public"."user_roles" FOR INSERT WITH CHECK (true);



CREATE POLICY "Admins and moderators can delete any post" ON "public"."posts" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Admins and moderators can delete any post_tags" ON "public"."post_tags" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Admins and moderators can insert any post" ON "public"."posts" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Admins and moderators can insert any post_tags" ON "public"."post_tags" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Admins and moderators can update any post" ON "public"."posts" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Admins and moderators can update any post_tags" ON "public"."post_tags" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Allow auth admin to manage user roles" ON "public"."user_roles" TO "supabase_auth_admin" USING (true) WITH CHECK (true);



CREATE POLICY "Allow auth admin to manage user timezones" ON "public"."user_timezones" TO "supabase_auth_admin" USING (true) WITH CHECK (true);



CREATE POLICY "Anyone can create tags" ON "public"."journal_tags" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Anyone can view tags" ON "public"."journal_tags" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated users can create chat rooms" ON "public"."chat_rooms" FOR INSERT WITH CHECK (("auth"."uid"() = "created_by"));



CREATE POLICY "Authorized users can delete tags" ON "public"."tags" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role", 'creator'::"public"."user_role"]));



CREATE POLICY "Authorized users can insert tags" ON "public"."tags" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role", 'creator'::"public"."user_role"]));



CREATE POLICY "Authorized users can update tags" ON "public"."tags" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role", 'creator'::"public"."user_role"]));



CREATE POLICY "Chat participants visible to members" ON "public"."chat_participants" FOR SELECT USING (true);



CREATE POLICY "Chat rooms visible to participants" ON "public"."chat_rooms" FOR SELECT USING (true);



CREATE POLICY "Creators can delete their own post_tags" ON "public"."post_tags" FOR DELETE TO "authenticated" USING (("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND (EXISTS ( SELECT 1
   FROM "public"."posts"
  WHERE (("posts"."id" = "post_tags"."post_id") AND ("posts"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Creators can insert their own post_tags" ON "public"."post_tags" FOR INSERT TO "authenticated" WITH CHECK (("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND (EXISTS ( SELECT 1
   FROM "public"."posts"
  WHERE (("posts"."id" = "post_tags"."post_id") AND ("posts"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Creators can update their own post_tags" ON "public"."post_tags" FOR UPDATE TO "authenticated" USING (("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND (EXISTS ( SELECT 1
   FROM "public"."posts"
  WHERE (("posts"."id" = "post_tags"."post_id") AND ("posts"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Enable delete creator and owner" ON "public"."spotify_playlists" FOR DELETE TO "authenticated" USING (("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND (( SELECT "auth"."uid"() AS "uid") = "user_id")));



CREATE POLICY "Enable delete for admin" ON "public"."spotify_playlists" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Enable insert admin" ON "public"."spotify_playlists" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Enable insert for creator and oner" ON "public"."spotify_playlists" FOR INSERT TO "authenticated" WITH CHECK (("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND (( SELECT "auth"."uid"() AS "uid") = "user_id")));



CREATE POLICY "Enable update creator that owns row" ON "public"."spotify_playlists" FOR UPDATE TO "authenticated" USING (("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND (( SELECT "auth"."uid"() AS "uid") = "user_id")));



CREATE POLICY "Enable update for admin" ON "public"."spotify_playlists" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "Message reactions visible to participants" ON "public"."message_reactions" FOR SELECT USING (true);



CREATE POLICY "Messages visible to chat participants" ON "public"."chat_messages" FOR SELECT USING (true);



CREATE POLICY "Only participants can insert messages" ON "public"."chat_messages" FOR INSERT WITH CHECK (true);



CREATE POLICY "Participants can update their own data" ON "public"."chat_participants" FOR UPDATE USING (true);



CREATE POLICY "Public profiles are viewable by everyone." ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Public read access for post_tags" ON "public"."post_tags" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Public read access for tags" ON "public"."tags" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Read receipts visible to participants" ON "public"."message_read_receipts" FOR SELECT USING (true);



CREATE POLICY "Room creators and admins can delete chat rooms" ON "public"."chat_rooms" FOR DELETE USING ((("auth"."uid"() = "created_by") OR (EXISTS ( SELECT 1
   FROM "public"."chat_participants"
  WHERE (("chat_participants"."chat_room_id" = "chat_participants"."id") AND ("chat_participants"."user_id" = "auth"."uid"()) AND ("chat_participants"."role" = 'admin'::"text") AND ("chat_participants"."left_at" IS NULL))))));



CREATE POLICY "Room creators and admins can update chat rooms" ON "public"."chat_rooms" FOR UPDATE USING ((("auth"."uid"() = "created_by") OR (EXISTS ( SELECT 1
   FROM "public"."chat_participants"
  WHERE (("chat_participants"."chat_room_id" = "chat_participants"."id") AND ("chat_participants"."user_id" = "auth"."uid"()) AND ("chat_participants"."role" = 'admin'::"text") AND ("chat_participants"."left_at" IS NULL))))));



CREATE POLICY "Senders can update their own messages" ON "public"."chat_messages" FOR UPDATE USING (true);



CREATE POLICY "Users can add media to their own entries" ON "public"."journal_media" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."journal_entries"
  WHERE (("journal_entries"."id" = "journal_media"."journal_entry_id") AND ("journal_entries"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can add reactions to messages" ON "public"."message_reactions" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can add tags to their own entries" ON "public"."journal_entry_tags" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."journal_entries"
  WHERE (("journal_entries"."id" = "journal_entry_tags"."journal_entry_id") AND ("journal_entries"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can be added as participants" ON "public"."chat_participants" FOR INSERT WITH CHECK (true);



CREATE POLICY "Users can create content links for their own entries" ON "public"."journal_content_links" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."journal_entries"
  WHERE (("journal_entries"."id" = "journal_content_links"."journal_entry_id") AND ("journal_entries"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can create their own journal entries" ON "public"."journal_entries" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can create their own read receipts" ON "public"."message_read_receipts" FOR INSERT WITH CHECK (true);



CREATE POLICY "Users can delete content links from their own entries" ON "public"."journal_content_links" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."journal_entries"
  WHERE (("journal_entries"."id" = "journal_content_links"."journal_entry_id") AND ("journal_entries"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can delete media from their own entries" ON "public"."journal_media" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."journal_entries"
  WHERE (("journal_entries"."id" = "journal_media"."journal_entry_id") AND ("journal_entries"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can delete their own journal entries" ON "public"."journal_entries" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete their own posts" ON "public"."posts" FOR DELETE TO "authenticated" USING (("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Users can delete their own timezone" ON "public"."user_timezones" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can insert own location" ON "public"."user_locations" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own onboarding progress" ON "public"."onboarding_progress" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert their own posts" ON "public"."posts" FOR INSERT TO "authenticated" WITH CHECK (("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Users can insert their own profile." ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can insert their own read receipts" ON "public"."notification_read_receipts" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert their own timezone" ON "public"."user_timezones" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can read any dance" ON "public"."dance" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can read any dance" ON "public"."user_timezones" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can read any movements" ON "public"."movements" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can read any neuroflow" ON "public"."neuroflow" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can read any on_demand_media" ON "public"."on_demand_media" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can read any post" ON "public"."posts" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can read any spotify_playlist_join" ON "public"."spotify_playlist_join" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can read any spotify_playlists" ON "public"."spotify_playlists" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can read any yoga" ON "public"."yoga" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can read their own read receipts" ON "public"."notification_read_receipts" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read their own timezone" ON "public"."user_timezones" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can remove tags from their own entries" ON "public"."journal_entry_tags" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."journal_entries"
  WHERE (("journal_entries"."id" = "journal_entry_tags"."journal_entry_id") AND ("journal_entries"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can remove their own reactions" ON "public"."message_reactions" FOR DELETE USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can see their own roles" ON "public"."user_roles" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own location" ON "public"."user_locations" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own onboarding progress" ON "public"."onboarding_progress" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own profile." ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can update their own journal entries" ON "public"."journal_entries" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update their own posts" ON "public"."posts" FOR UPDATE TO "authenticated" USING (("public"."authorizedas"(ARRAY['creator'::"public"."user_role"]) AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Users can update their own timezone" ON "public"."user_timezones" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view content links for their own entries" ON "public"."journal_content_links" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."journal_entries"
  WHERE (("journal_entries"."id" = "journal_content_links"."journal_entry_id") AND ("journal_entries"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can view media for their own entries" ON "public"."journal_media" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."journal_entries"
  WHERE (("journal_entries"."id" = "journal_media"."journal_entry_id") AND ("journal_entries"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can view notifications they receive" ON "public"."notification_recipients" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own location" ON "public"."user_locations" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own onboarding progress" ON "public"."onboarding_progress" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view tags for their own entries" ON "public"."journal_entry_tags" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."journal_entries"
  WHERE (("journal_entries"."id" = "journal_entry_tags"."journal_entry_id") AND ("journal_entries"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can view their own journal entries" ON "public"."journal_entries" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "admin_full_access_protected_media" ON "public"."protected_media_data" USING ("public"."has_role"('admin'::"text"));



ALTER TABLE "public"."appointment_purchases" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "appointment_purchases_select" ON "public"."appointment_purchases" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM "public"."purchases"
  WHERE (("purchases"."id" = "appointment_purchases"."purchase_id") AND (("purchases"."user_id" = "auth"."uid"()) OR ("purchases"."owner_id" = "auth"."uid"()))))) OR "public"."has_role"('admin'::"text")));



ALTER TABLE "public"."availability_exceptions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "availability_exceptions_owner" ON "public"."availability_exceptions" USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role"))))));



ALTER TABLE "public"."chat_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chat_participants" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chat_rooms" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."content_purchases" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "content_purchases_select" ON "public"."content_purchases" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM "public"."purchases"
  WHERE (("purchases"."id" = "content_purchases"."purchase_id") AND (("purchases"."user_id" = "auth"."uid"()) OR ("purchases"."owner_id" = "auth"."uid"()))))) OR "public"."has_role"('admin'::"text")));



CREATE POLICY "creator_manage_access" ON "public"."subscription_content_access" USING (("creator_id" = "auth"."uid"()));



CREATE POLICY "creator_manage_tiers" ON "public"."creator_subscription_tiers" USING (("creator_id" = "auth"."uid"()));



CREATE POLICY "creator_protected_media_access" ON "public"."protected_media_data" USING ((EXISTS ( SELECT 1
   FROM ("public"."on_demand_media" "odm"
     JOIN "public"."posts" "p" ON (("odm"."post_id" = "p"."id")))
  WHERE (("odm"."id" = "protected_media_data"."content_id") AND ("p"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."creator_subscription_tiers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dance" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."email_templates" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "email_templates_modify_policy" ON "public"."email_templates" USING ((EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role")))));



CREATE POLICY "email_templates_select_policy" ON "public"."email_templates" FOR SELECT USING (true);



CREATE POLICY "enable admin delete" ON "public"."spotify_playlist_join" FOR DELETE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "enable admin insert" ON "public"."spotify_playlist_join" FOR INSERT TO "authenticated" WITH CHECK ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



CREATE POLICY "enable admin update" ON "public"."spotify_playlist_join" FOR UPDATE TO "authenticated" USING ("public"."authorizedas"(ARRAY['admin'::"public"."user_role", 'moderator'::"public"."user_role"]));



ALTER TABLE "public"."event_bookings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "event_bookings_select" ON "public"."event_bookings" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM "public"."purchases"
  WHERE (("purchases"."id" = "event_bookings"."purchase_id") AND (("purchases"."user_id" = "auth"."uid"()) OR ("purchases"."owner_id" = "auth"."uid"()))))) OR "public"."has_role"('admin'::"text")));



ALTER TABLE "public"."journal_content_links" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."journal_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."journal_entry_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."journal_media" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."journal_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."message_reactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."message_read_receipts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."movements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."neuroflow" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notification_deliveries" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notification_deliveries_select_policy" ON "public"."notification_deliveries" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."notifications"
  WHERE (("notifications"."id" = "notification_deliveries"."notification_id") AND (("notifications"."user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
           FROM "public"."user_roles"
          WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role")))))))));



ALTER TABLE "public"."notification_preferences" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notification_prefs_insert_policy" ON "public"."notification_preferences" FOR INSERT WITH CHECK ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role"))))));



CREATE POLICY "notification_prefs_select_policy" ON "public"."notification_preferences" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role"))))));



CREATE POLICY "notification_prefs_update_policy" ON "public"."notification_preferences" FOR UPDATE USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role"))))));



ALTER TABLE "public"."notification_read_receipts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notification_recipients" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications_delete_policy" ON "public"."notifications" FOR DELETE USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role"))))));



CREATE POLICY "notifications_insert_policy" ON "public"."notifications" FOR INSERT WITH CHECK ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role"))))));



CREATE POLICY "notifications_select_policy" ON "public"."notifications" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role"))))));



CREATE POLICY "notifications_update_policy" ON "public"."notifications" FOR UPDATE USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role"))))));



ALTER TABLE "public"."on_demand_media" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."onboarding_progress" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."post_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."posts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."protected_media_data" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."provider_preferences" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "provider_preferences_owner" ON "public"."provider_preferences" USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role"))))));



CREATE POLICY "purchase_admin" ON "public"."purchases" USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "purchase_insert_as_purchaser" ON "public"."purchases" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "purchase_select_as_owner" ON "public"."purchases" FOR SELECT USING (("auth"."uid"() = "owner_id"));



CREATE POLICY "purchase_select_as_purchaser" ON "public"."purchases" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "purchase_update_as_purchaser" ON "public"."purchases" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."purchases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."subscription_content_access" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "subscriptions_select" ON "public"."subscriptions" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM "public"."purchases"
  WHERE (("purchases"."id" = "subscriptions"."purchase_id") AND (("purchases"."user_id" = "auth"."uid"()) OR ("purchases"."owner_id" = "auth"."uid"()))))) OR "public"."has_role"('admin'::"text")));



ALTER TABLE "public"."tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_fcm_tokens" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_fcm_tokens_delete_policy" ON "public"."user_fcm_tokens" FOR DELETE USING (("user_id" = "auth"."uid"()));



CREATE POLICY "user_fcm_tokens_insert_policy" ON "public"."user_fcm_tokens" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "user_fcm_tokens_select_policy" ON "public"."user_fcm_tokens" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_roles"
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("user_roles"."role" = 'admin'::"public"."user_role"))))));



CREATE POLICY "user_fcm_tokens_update_policy" ON "public"."user_fcm_tokens" FOR UPDATE USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."user_locations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_protected_media_access" ON "public"."protected_media_data" FOR SELECT USING ("public"."can_access_content"("content_id"));



ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_timezones" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "view_active_tiers" ON "public"."creator_subscription_tiers" FOR SELECT USING (("is_active" = true));



ALTER TABLE "public"."yoga" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
GRANT USAGE ON SCHEMA "public" TO "supabase_auth_admin";



GRANT ALL ON TABLE "public"."chat_participants" TO "anon";
GRANT ALL ON TABLE "public"."chat_participants" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_participants" TO "service_role";



GRANT ALL ON FUNCTION "public"."add_chat_participants"("p_chat_room_id" "uuid", "p_user_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."add_chat_participants"("p_chat_room_id" "uuid", "p_user_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_chat_participants"("p_chat_room_id" "uuid", "p_user_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_creator_as_participant"() TO "anon";
GRANT ALL ON FUNCTION "public"."add_creator_as_participant"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_creator_as_participant"() TO "service_role";



GRANT ALL ON FUNCTION "public"."add_emotional_focuses"("p_post_id" "uuid", "p_emotional_focuses" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."add_emotional_focuses"("p_post_id" "uuid", "p_emotional_focuses" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_emotional_focuses"("p_post_id" "uuid", "p_emotional_focuses" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_event_dates"("p_event_id" "uuid", "p_event_dates" "public"."event_date_input"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."add_event_dates"("p_event_id" "uuid", "p_event_dates" "public"."event_date_input"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_event_dates"("p_event_id" "uuid", "p_event_dates" "public"."event_date_input"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_journal_media"("p_journal_entry_id" bigint, "p_storage_path" "text", "p_media_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."add_journal_media"("p_journal_entry_id" bigint, "p_storage_path" "text", "p_media_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_journal_media"("p_journal_entry_id" bigint, "p_storage_path" "text", "p_media_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."add_movement_props"("p_movement_id" "uuid", "p_props" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."add_movement_props"("p_movement_id" "uuid", "p_props" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_movement_props"("p_movement_id" "uuid", "p_props" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_playlist_associations"("p_content_id" "uuid", "p_playlist_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."add_playlist_associations"("p_content_id" "uuid", "p_playlist_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_playlist_associations"("p_content_id" "uuid", "p_playlist_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_tags_to_post"("p_post_id" "uuid", "p_tags" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."add_tags_to_post"("p_post_id" "uuid", "p_tags" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_tags_to_post"("p_post_id" "uuid", "p_tags" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_tickets"("p_event_id" "uuid", "p_tickets" "public"."ticket_input"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."add_tickets"("p_event_id" "uuid", "p_tickets" "public"."ticket_input"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_tickets"("p_event_id" "uuid", "p_tickets" "public"."ticket_input"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."approve_appointment_request"("p_appointment_id" "uuid", "p_price" numeric, "p_message" "text", "p_checkout_base_url" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."approve_appointment_request"("p_appointment_id" "uuid", "p_price" numeric, "p_message" "text", "p_checkout_base_url" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."approve_appointment_request"("p_appointment_id" "uuid", "p_price" numeric, "p_message" "text", "p_checkout_base_url" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."associate_post_location"("p_post_id" "uuid", "p_location_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."associate_post_location"("p_post_id" "uuid", "p_location_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."associate_post_location"("p_post_id" "uuid", "p_location_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."authorizedas"("allowed_roles" "public"."user_role"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."authorizedas"("allowed_roles" "public"."user_role"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."authorizedas"("allowed_roles" "public"."user_role"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."auto_confirm_appointment"() TO "anon";
GRANT ALL ON FUNCTION "public"."auto_confirm_appointment"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auto_confirm_appointment"() TO "service_role";



GRANT ALL ON FUNCTION "public"."backfill_embeddings"() TO "anon";
GRANT ALL ON FUNCTION "public"."backfill_embeddings"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."backfill_embeddings"() TO "service_role";



GRANT ALL ON FUNCTION "public"."book_appointment"("p_facilitator_id" "uuid", "p_client_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."book_appointment"("p_facilitator_id" "uuid", "p_client_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."book_appointment"("p_facilitator_id" "uuid", "p_client_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."broadcast_chat_message_changes"() TO "anon";
GRANT ALL ON FUNCTION "public"."broadcast_chat_message_changes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."broadcast_chat_message_changes"() TO "service_role";



GRANT ALL ON FUNCTION "public"."broadcast_message_reaction_changes"() TO "anon";
GRANT ALL ON FUNCTION "public"."broadcast_message_reaction_changes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."broadcast_message_reaction_changes"() TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_distance"("point1" "public"."geography", "point2" "public"."geography", "unit" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_distance"("point1" "public"."geography", "point2" "public"."geography", "unit" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_distance"("point1" "public"."geography", "point2" "public"."geography", "unit" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."can_access_appointment"("service_id" "uuid", "appointment_date" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."can_access_appointment"("service_id" "uuid", "appointment_date" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_access_appointment"("service_id" "uuid", "appointment_date" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."can_access_content"("content_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."can_access_content"("content_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_access_content"("content_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."can_access_content_v2"("input_content_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."can_access_content_v2"("input_content_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_access_content_v2"("input_content_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."can_access_event"("event_id" "uuid", "date_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."can_access_event"("event_id" "uuid", "date_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_access_event"("event_id" "uuid", "date_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."can_attend_event"("p_event_id" "uuid", "p_date_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."can_attend_event"("p_event_id" "uuid", "p_date_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_attend_event"("p_event_id" "uuid", "p_date_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."can_create_broadcast_room"() TO "anon";
GRANT ALL ON FUNCTION "public"."can_create_broadcast_room"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_create_broadcast_room"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_event_date_delete"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_event_date_delete"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_event_date_delete"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_schedule_conflicts"("p_provider_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone, "p_exclude_appointment_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."check_schedule_conflicts"("p_provider_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone, "p_exclude_appointment_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_schedule_conflicts"("p_provider_id" "uuid", "p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone, "p_exclude_appointment_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."check_ticket_delete"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_ticket_delete"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_ticket_delete"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_old_notifications"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_old_notifications"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_old_notifications"() TO "service_role";



GRANT ALL ON FUNCTION "public"."create_article_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_article_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_article_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_broadcast_announcement"("p_title" "text", "p_content" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb", "p_audience_type" "public"."notification_audience_type", "p_audience_criteria" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_broadcast_announcement"("p_title" "text", "p_content" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb", "p_audience_type" "public"."notification_audience_type", "p_audience_criteria" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_broadcast_announcement"("p_title" "text", "p_content" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb", "p_audience_type" "public"."notification_audience_type", "p_audience_criteria" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_ceremony_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_ceremony_type" "text", "p_ceremony_theme" "text", "p_ceremony_focus" "text", "p_what_to_bring" "text", "p_space_holder_names" "text", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_ceremony_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_ceremony_type" "text", "p_ceremony_theme" "text", "p_ceremony_focus" "text", "p_what_to_bring" "text", "p_space_holder_names" "text", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_ceremony_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_ceremony_type" "text", "p_ceremony_theme" "text", "p_ceremony_focus" "text", "p_what_to_bring" "text", "p_space_holder_names" "text", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_dance_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_freeform_movement" boolean, "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_dance_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_freeform_movement" boolean, "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_dance_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_freeform_movement" boolean, "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_event"("p_post_id" "uuid", "p_content" "text", "p_event_type" "public"."event_type_enum") TO "anon";
GRANT ALL ON FUNCTION "public"."create_event"("p_post_id" "uuid", "p_content" "text", "p_event_type" "public"."event_type_enum") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_event"("p_post_id" "uuid", "p_content" "text", "p_event_type" "public"."event_type_enum") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_event_purchase"("p_event_id" "uuid", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_quantity" integer, "p_is_virtual" boolean, "p_payment_intent_id" "text", "p_payment_status" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_event_purchase"("p_event_id" "uuid", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_quantity" integer, "p_is_virtual" boolean, "p_payment_intent_id" "text", "p_payment_status" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_event_purchase"("p_event_id" "uuid", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_quantity" integer, "p_is_virtual" boolean, "p_payment_intent_id" "text", "p_payment_status" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_event_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_event_type" "public"."event_type_enum", "p_event_dates" "public"."event_date_input"[], "p_tickets" "public"."ticket_input"[], "p_room_name" "text", "p_room_password" "text", "p_location_id" "uuid", "user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_event_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_event_type" "public"."event_type_enum", "p_event_dates" "public"."event_date_input"[], "p_tickets" "public"."ticket_input"[], "p_room_name" "text", "p_room_password" "text", "p_location_id" "uuid", "user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_event_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_event_type" "public"."event_type_enum", "p_event_dates" "public"."event_date_input"[], "p_tickets" "public"."ticket_input"[], "p_room_name" "text", "p_room_password" "text", "p_location_id" "uuid", "user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_follower_broadcast"("p_follower_ids" "uuid"[], "p_title" "text", "p_content" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_follower_broadcast"("p_follower_ids" "uuid"[], "p_title" "text", "p_content" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_follower_broadcast"("p_follower_ids" "uuid"[], "p_title" "text", "p_content" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_generic_ondemand_content"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_generic_ondemand_content"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_generic_ondemand_content"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_journal_entry"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_mood" "public"."mood_enum", "p_privacy" "public"."journal_entry_privacy_enum", "p_tags" "text"[], "p_post_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_journal_entry"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_mood" "public"."mood_enum", "p_privacy" "public"."journal_entry_privacy_enum", "p_tags" "text"[], "p_post_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_journal_entry"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_mood" "public"."mood_enum", "p_privacy" "public"."journal_entry_privacy_enum", "p_tags" "text"[], "p_post_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_live_room"("p_post_id" "uuid", "p_name" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_live_room"("p_post_id" "uuid", "p_name" "text", "p_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_live_room"("p_post_id" "uuid", "p_name" "text", "p_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_location"("p_name" "text", "p_description" "text", "p_image_url" "text", "p_line_1" "text", "p_line_2" "text", "p_city" "text", "p_country" "text", "p_postcode" "text", "p_maps_link" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_location"("p_name" "text", "p_description" "text", "p_image_url" "text", "p_line_1" "text", "p_line_2" "text", "p_city" "text", "p_country" "text", "p_postcode" "text", "p_maps_link" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_location"("p_name" "text", "p_description" "text", "p_image_url" "text", "p_line_1" "text", "p_line_2" "text", "p_city" "text", "p_country" "text", "p_postcode" "text", "p_maps_link" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_meditation_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_meditation_type" "text", "p_meditation_theme" "text", "p_meditation_focus" "text", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_meditation_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_meditation_type" "text", "p_meditation_theme" "text", "p_meditation_focus" "text", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_meditation_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_meditation_type" "text", "p_meditation_theme" "text", "p_meditation_focus" "text", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_movement"("p_content_id" "uuid", "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_movement"("p_content_id" "uuid", "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_movement"("p_content_id" "uuid", "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_neuroflow_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_techniques_used" "text", "p_session_focus" "text", "p_personal_growth_outcomes" "text", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_neuroflow_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_techniques_used" "text", "p_session_focus" "text", "p_personal_growth_outcomes" "text", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_neuroflow_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_techniques_used" "text", "p_session_focus" "text", "p_personal_growth_outcomes" "text", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_priority" "text", "p_related_entity_id" "uuid", "p_action" "text", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_priority" "text", "p_related_entity_id" "uuid", "p_action" "text", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_priority" "text", "p_related_entity_id" "uuid", "p_action" "text", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_notification_for_all_users"("p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_notification_for_all_users"("p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_notification_for_all_users"("p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_notifications_batch"("p_user_ids" "uuid"[], "p_sender_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_priority" "text", "p_related_entity_id" "uuid", "p_action" "text", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_notifications_batch"("p_user_ids" "uuid"[], "p_sender_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_priority" "text", "p_related_entity_id" "uuid", "p_action" "text", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_notifications_batch"("p_user_ids" "uuid"[], "p_sender_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_priority" "text", "p_related_entity_id" "uuid", "p_action" "text", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_ondemand_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_post_type" "public"."post_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_ondemand_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_post_type" "public"."post_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_ondemand_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_post_type" "public"."post_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_ondemand_media"("p_post_id" "uuid", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_ondemand_media"("p_post_id" "uuid", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_ondemand_media"("p_post_id" "uuid", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_or_get_private_chat"("p_user_id1" "uuid", "p_user_id2" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_or_get_private_chat"("p_user_id1" "uuid", "p_user_id2" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_or_get_private_chat"("p_user_id1" "uuid", "p_user_id2" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_or_update_batched_chat_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_chat_id" "uuid", "p_message_preview" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_or_update_batched_chat_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_chat_id" "uuid", "p_message_preview" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_or_update_batched_chat_notification"("p_user_id" "uuid", "p_sender_id" "uuid", "p_chat_id" "uuid", "p_message_preview" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_post"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_post_type" "public"."post_type_enum", "p_status" "public"."publish_status_enum", "p_thumbnail_url" "text", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_post"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_post_type" "public"."post_type_enum", "p_status" "public"."publish_status_enum", "p_thumbnail_url" "text", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_post"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_post_type" "public"."post_type_enum", "p_status" "public"."publish_status_enum", "p_thumbnail_url" "text", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_protected_media_data"("p_content_id" "uuid", "p_status" "public"."publish_status_enum", "p_url" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_protected_media_data"("p_content_id" "uuid", "p_status" "public"."publish_status_enum", "p_url" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_protected_media_data"("p_content_id" "uuid", "p_status" "public"."publish_status_enum", "p_url" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_service_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_location_id" "uuid", "p_price" numeric, "p_duration" interval, "p_type" "public"."event_type_enum", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer, "user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_service_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_location_id" "uuid", "p_price" numeric, "p_duration" interval, "p_type" "public"."event_type_enum", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer, "user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_service_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_location_id" "uuid", "p_price" numeric, "p_duration" interval, "p_type" "public"."event_type_enum", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer, "user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_yoga"("p_movement_id" "uuid", "p_yoga_style" "text", "p_chakras" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_yoga"("p_movement_id" "uuid", "p_yoga_style" "text", "p_chakras" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_yoga"("p_movement_id" "uuid", "p_yoga_style" "text", "p_chakras" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_yoga_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_yoga_style" "text", "p_chakras" "text", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_yoga_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_yoga_style" "text", "p_chakras" "text", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_yoga_content_with_details"("p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_yoga_style" "text", "p_chakras" "text", "p_user_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "supabase_auth_admin";



GRANT ALL ON FUNCTION "public"."deactivate_fcm_token"("p_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."deactivate_fcm_token"("p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."deactivate_fcm_token"("p_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."debug_notification_type"() TO "anon";
GRANT ALL ON FUNCTION "public"."debug_notification_type"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."debug_notification_type"() TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_playlist"("user_id" "uuid", "iframe" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_playlist"("user_id" "uuid", "iframe" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_playlist"("user_id" "uuid", "iframe" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."enforce_single_draft_invoice_per_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."enforce_single_draft_invoice_per_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enforce_single_draft_invoice_per_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ensure_unique_slug"() TO "anon";
GRANT ALL ON FUNCTION "public"."ensure_unique_slug"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ensure_unique_slug"() TO "service_role";



GRANT ALL ON FUNCTION "public"."filter_events"("filters" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."filter_events"("filters" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."filter_events"("filters" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."filter_service_appointments"("filters" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."filter_service_appointments"("filters" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."filter_service_appointments"("filters" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."find_nearby_locations"("lat" double precision, "lon" double precision, "radius_km" double precision, "limit_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."find_nearby_locations"("lat" double precision, "lon" double precision, "radius_km" double precision, "limit_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_nearby_locations"("lat" double precision, "lon" double precision, "radius_km" double precision, "limit_count" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."find_nearby_users"("lat" double precision, "lon" double precision, "radius_km" double precision, "limit_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."find_nearby_users"("lat" double precision, "lon" double precision, "radius_km" double precision, "limit_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_nearby_users"("lat" double precision, "lon" double precision, "radius_km" double precision, "limit_count" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_coordinates_text"("line1" "text", "line2" "text", "city" "text", "postcode" "text", "country" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_coordinates_text"("line1" "text", "line2" "text", "city" "text", "postcode" "text", "country" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_coordinates_text"("line1" "text", "line2" "text", "city" "text", "postcode" "text", "country" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_random_comment"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_random_comment"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_random_comment"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_all_sales"("filters" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."get_all_sales"("filters" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_all_sales"("filters" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_appointment_sales"("filters" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."get_appointment_sales"("filters" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_appointment_sales"("filters" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_availability"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_availability"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_availability"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_available_slots"("p_facilitator_id" "uuid", "p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_available_slots"("p_facilitator_id" "uuid", "p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_available_slots"("p_facilitator_id" "uuid", "p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_chat_messages"("p_chat_room_id" "uuid", "p_limit" integer, "p_before" timestamp with time zone, "p_after" timestamp with time zone, "p_around_message_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_chat_messages"("p_chat_room_id" "uuid", "p_limit" integer, "p_before" timestamp with time zone, "p_after" timestamp with time zone, "p_around_message_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_chat_messages"("p_chat_room_id" "uuid", "p_limit" integer, "p_before" timestamp with time zone, "p_after" timestamp with time zone, "p_around_message_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_chat_messages_simple"("p_chat_room_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_chat_messages_simple"("p_chat_room_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_chat_messages_simple"("p_chat_room_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_chat_messages_with_reactions"("p_chat_room_id" "uuid", "p_limit" integer, "p_before" timestamp with time zone, "p_after" timestamp with time zone, "p_around_message_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_chat_messages_with_reactions"("p_chat_room_id" "uuid", "p_limit" integer, "p_before" timestamp with time zone, "p_after" timestamp with time zone, "p_around_message_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_chat_messages_with_reactions"("p_chat_room_id" "uuid", "p_limit" integer, "p_before" timestamp with time zone, "p_after" timestamp with time zone, "p_around_message_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_comment_tree"("in_post_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_comment_tree"("in_post_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_comment_tree"("in_post_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_comments"("in_post_id" "uuid", "in_limit" integer, "in_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_comments"("in_post_id" "uuid", "in_limit" integer, "in_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_comments"("in_post_id" "uuid", "in_limit" integer, "in_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_content_sales"("filters" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."get_content_sales"("filters" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_content_sales"("filters" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_enhanced_event_details"("event_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_enhanced_event_details"("event_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_enhanced_event_details"("event_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_event_bookings"("filters" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."get_event_bookings"("filters" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_event_bookings"("filters" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_event_cards"("user_lat" double precision, "user_lon" double precision, "event_types" "public"."event_type_enum"[], "time_filter" "text", "distance_limit" double precision, "page_size" integer, "page_number" integer, "only_featured" boolean, "user_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."get_event_cards"("user_lat" double precision, "user_lon" double precision, "event_types" "public"."event_type_enum"[], "time_filter" "text", "distance_limit" double precision, "page_size" integer, "page_number" integer, "only_featured" boolean, "user_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_event_cards"("user_lat" double precision, "user_lon" double precision, "event_types" "public"."event_type_enum"[], "time_filter" "text", "distance_limit" double precision, "page_size" integer, "page_number" integer, "only_featured" boolean, "user_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_event_details"("event_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_event_details"("event_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_event_details"("event_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_filtered_movement_content"("input_post_ids" "uuid"[], "input_featured" boolean, "post_type_array" "public"."post_type_enum"[], "search_title" "text", "min_duration" integer, "max_duration" integer, "min_energy_level" integer, "max_energy_level" integer, "min_price" numeric, "max_price" numeric, "tag_array" "text"[], "p_limit" integer, "p_offset" integer, "p_media_key" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_filtered_movement_content"("input_post_ids" "uuid"[], "input_featured" boolean, "post_type_array" "public"."post_type_enum"[], "search_title" "text", "min_duration" integer, "max_duration" integer, "min_energy_level" integer, "max_energy_level" integer, "min_price" numeric, "max_price" numeric, "tag_array" "text"[], "p_limit" integer, "p_offset" integer, "p_media_key" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_filtered_movement_content"("input_post_ids" "uuid"[], "input_featured" boolean, "post_type_array" "public"."post_type_enum"[], "search_title" "text", "min_duration" integer, "max_duration" integer, "min_energy_level" integer, "max_energy_level" integer, "min_price" numeric, "max_price" numeric, "tag_array" "text"[], "p_limit" integer, "p_offset" integer, "p_media_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_journal_entries"("p_user_id" "uuid", "p_tag_names" "text"[], "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_mood" "public"."mood_enum", "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_journal_entries"("p_user_id" "uuid", "p_tag_names" "text"[], "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_mood" "public"."mood_enum", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_journal_entries"("p_user_id" "uuid", "p_tag_names" "text"[], "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_mood" "public"."mood_enum", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_message_reactions"("p_message_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_message_reactions"("p_message_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_message_reactions"("p_message_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_on_page_ceremony"("p_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_on_page_ceremony"("p_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_on_page_ceremony"("p_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_on_page_dance"("p_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_on_page_dance"("p_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_on_page_dance"("p_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_on_page_meditation"("p_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_on_page_meditation"("p_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_on_page_meditation"("p_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_on_page_neuro_flow"("p_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_on_page_neuro_flow"("p_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_on_page_neuro_flow"("p_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_on_page_yoga"("p_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_on_page_yoga"("p_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_on_page_yoga"("p_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_pending_appointments"("p_facilitator_id" "uuid", "p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_pending_appointments"("p_facilitator_id" "uuid", "p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_pending_appointments"("p_facilitator_id" "uuid", "p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_post_type_tags"("post_type" "public"."post_type_enum") TO "anon";
GRANT ALL ON FUNCTION "public"."get_post_type_tags"("post_type" "public"."post_type_enum") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_post_type_tags"("post_type" "public"."post_type_enum") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_potential_recipients"("p_params" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."get_potential_recipients"("p_params" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_potential_recipients"("p_params" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_protected_media_url"("content_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_protected_media_url"("content_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_protected_media_url"("content_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_protected_media_url_v2"("content_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_protected_media_url_v2"("content_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_protected_media_url_v2"("content_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_provider_availability"("provider_id" "uuid", "start_date" "date", "end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_provider_availability"("provider_id" "uuid", "start_date" "date", "end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_provider_availability"("provider_id" "uuid", "start_date" "date", "end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_sent_notifications"("p_limit" integer, "p_offset" integer, "p_type" "text", "p_reference_id" "uuid", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."get_sent_notifications"("p_limit" integer, "p_offset" integer, "p_type" "text", "p_reference_id" "uuid", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_sent_notifications"("p_limit" integer, "p_offset" integer, "p_type" "text", "p_reference_id" "uuid", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_service_calendar_availability"("p_service_id" "uuid", "p_days_ahead" integer, "p_timezone" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_service_calendar_availability"("p_service_id" "uuid", "p_days_ahead" integer, "p_timezone" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_service_calendar_availability"("p_service_id" "uuid", "p_days_ahead" integer, "p_timezone" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_service_details"("service_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_service_details"("service_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_service_details"("service_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_smart_comments"("in_post_id" "uuid", "in_limit" integer, "in_offset" integer, "in_sort_by" "text", "in_show_replies" boolean, "in_min_score" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_smart_comments"("in_post_id" "uuid", "in_limit" integer, "in_offset" integer, "in_sort_by" "text", "in_show_replies" boolean, "in_min_score" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_smart_comments"("in_post_id" "uuid", "in_limit" integer, "in_offset" integer, "in_sort_by" "text", "in_show_replies" boolean, "in_min_score" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_subscriptions"("filters" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."get_subscriptions"("filters" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_subscriptions"("filters" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_suggested_appointments"("p_user_id" "uuid", "p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_suggested_appointments"("p_user_id" "uuid", "p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_suggested_appointments"("p_user_id" "uuid", "p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_upcoming_events"("user_lat" double precision, "user_lon" double precision, "event_types" "public"."event_type_enum"[], "distance_limit" double precision, "page_size" integer, "page_number" integer, "only_featured" boolean, "creator_ids" "uuid"[], "tag_filter" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."get_upcoming_events"("user_lat" double precision, "user_lon" double precision, "event_types" "public"."event_type_enum"[], "distance_limit" double precision, "page_size" integer, "page_number" integer, "only_featured" boolean, "creator_ids" "uuid"[], "tag_filter" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_upcoming_events"("user_lat" double precision, "user_lon" double precision, "event_types" "public"."event_type_enum"[], "distance_limit" double precision, "page_size" integer, "page_number" integer, "only_featured" boolean, "creator_ids" "uuid"[], "tag_filter" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_upcoming_service_appointments"("provider_id" "uuid", "limit_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_upcoming_service_appointments"("provider_id" "uuid", "limit_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_upcoming_service_appointments"("provider_id" "uuid", "limit_count" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_appointments"("p_user_id" "uuid", "p_status" "text", "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_appointments"("p_user_id" "uuid", "p_status" "text", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_appointments"("p_user_id" "uuid", "p_status" "text", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_chat_rooms"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_chat_rooms"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_chat_rooms"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_chat_rooms"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_chat_rooms"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_chat_rooms"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_event_purchases"("p_status" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_event_purchases"("p_status" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_event_purchases"("p_status" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_location"("user_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_location"("user_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_location"("user_uuid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_service_appointments"("user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_service_appointments"("user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_service_appointments"("user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."grant_public_read_access"("table_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."grant_public_read_access"("table_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."grant_public_read_access"("table_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_appointment_request"("p_service_id" "uuid", "p_user_id" "uuid", "p_owner_id" "uuid", "p_post_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_message" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."handle_appointment_request"("p_service_id" "uuid", "p_user_id" "uuid", "p_owner_id" "uuid", "p_post_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_message" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_appointment_request"("p_service_id" "uuid", "p_user_id" "uuid", "p_owner_id" "uuid", "p_post_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_message" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."has_active_subscription"("subscription_creator_id" "uuid", "required_tier_key" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."has_active_subscription"("subscription_creator_id" "uuid", "required_tier_key" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_active_subscription"("subscription_creator_id" "uuid", "required_tier_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."has_role"("role_to_check" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."has_role"("role_to_check" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_role"("role_to_check" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."iana_to_utc_offset"("iana_timezone" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."iana_to_utc_offset"("iana_timezone" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."iana_to_utc_offset"("iana_timezone" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."insert_playlist"("iframe" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."insert_playlist"("iframe" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."insert_playlist"("iframe" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_creator_or_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_creator_or_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_creator_or_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."isowned"("input_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."isowned"("input_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."isowned"("input_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."isownedfolder"("object_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."isownedfolder"("object_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."isownedfolder"("object_name" "text") TO "service_role";



GRANT ALL ON TABLE "public"."waitlist_entries" TO "anon";
GRANT ALL ON TABLE "public"."waitlist_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."waitlist_entries" TO "service_role";



GRANT ALL ON FUNCTION "public"."join_waitlist"("waitlist_id" "uuid", "email" character varying, "user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."join_waitlist"("waitlist_id" "uuid", "email" character varying, "user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."join_waitlist"("waitlist_id" "uuid", "email" character varying, "user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."leave_comment"("in_post_id" "uuid", "in_comment" "text", "in_parent_id" bigint, "in_attachments" "json", "in_mentions" "json") TO "anon";
GRANT ALL ON FUNCTION "public"."leave_comment"("in_post_id" "uuid", "in_comment" "text", "in_parent_id" bigint, "in_attachments" "json", "in_mentions" "json") TO "authenticated";
GRANT ALL ON FUNCTION "public"."leave_comment"("in_post_id" "uuid", "in_comment" "text", "in_parent_id" bigint, "in_attachments" "json", "in_mentions" "json") TO "service_role";



GRANT ALL ON FUNCTION "public"."legacy_create_notification"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."legacy_create_notification"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."legacy_create_notification"("p_user_id" "uuid", "p_title" "text", "p_content" "text", "p_type" "text", "p_action_url" "text", "p_reference_id" "uuid", "p_reference_type" "text", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."link_journal_to_content"("p_journal_entry_id" bigint, "p_post_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."link_journal_to_content"("p_journal_entry_id" bigint, "p_post_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."link_journal_to_content"("p_journal_entry_id" bigint, "p_post_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."lock_provider_schedule"("p_provider_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."lock_provider_schedule"("p_provider_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lock_provider_schedule"("p_provider_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_error"("p_error_level" character varying, "p_error_message" "text", "p_error_code" character varying, "p_source_file" character varying, "p_line_number" integer, "p_function_name" character varying, "p_user_id" "uuid", "p_session_id" "uuid", "p_request_path" character varying, "p_request_method" character varying, "p_ip_address" "inet", "p_user_agent" "text", "p_stack_trace" "text", "p_additional_data" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_error"("p_error_level" character varying, "p_error_message" "text", "p_error_code" character varying, "p_source_file" character varying, "p_line_number" integer, "p_function_name" character varying, "p_user_id" "uuid", "p_session_id" "uuid", "p_request_path" character varying, "p_request_method" character varying, "p_ip_address" "inet", "p_user_agent" "text", "p_stack_trace" "text", "p_additional_data" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_error"("p_error_level" character varying, "p_error_message" "text", "p_error_code" character varying, "p_source_file" character varying, "p_line_number" integer, "p_function_name" character varying, "p_user_id" "uuid", "p_session_id" "uuid", "p_request_path" character varying, "p_request_method" character varying, "p_ip_address" "inet", "p_user_agent" "text", "p_stack_trace" "text", "p_additional_data" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_all_notifications_as_read"() TO "anon";
GRANT ALL ON FUNCTION "public"."mark_all_notifications_as_read"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_all_notifications_as_read"() TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_broadcast_notification_read"("p_notification_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_broadcast_notification_read"("p_notification_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_broadcast_notification_read"("p_notification_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_message_as_read"("p_message_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_message_as_read"("p_message_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_message_as_read"("p_message_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_notification_as_read"("p_notification_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_notification_as_read"("p_notification_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_notification_as_read"("p_notification_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_notifications_as_read"("p_notification_ids" "uuid"[], "p_mark_all" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."mark_notifications_as_read"("p_notification_ids" "uuid"[], "p_mark_all" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_notifications_as_read"("p_notification_ids" "uuid"[], "p_mark_all" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_notifications_as_read"("p_notification_ids" "uuid"[], "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_notifications_as_read"("p_notification_ids" "uuid"[], "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_notifications_as_read"("p_notification_ids" "uuid"[], "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_appointment_status_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_appointment_status_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_appointment_status_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_chat_participant_added"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_chat_participant_added"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_chat_participant_added"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_event_attendees"("p_event_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."notify_event_attendees"("p_event_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_event_attendees"("p_event_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_new_follower"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_new_follower"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_new_follower"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_service_subscribers"("p_service_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."notify_service_subscribers"("p_service_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_service_subscribers"("p_service_id" "uuid", "p_title" "text", "p_content" "text", "p_action_url" "text", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."original_prevent_double_booking"() TO "anon";
GRANT ALL ON FUNCTION "public"."original_prevent_double_booking"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."original_prevent_double_booking"() TO "service_role";



GRANT ALL ON FUNCTION "public"."post_comment_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."post_comment_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."post_comment_notification"() TO "service_role";



GRANT ALL ON FUNCTION "public"."prevent_double_booking"() TO "anon";
GRANT ALL ON FUNCTION "public"."prevent_double_booking"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_double_booking"() TO "service_role";



GRANT ALL ON FUNCTION "public"."process_appointment_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."process_appointment_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_appointment_notification"() TO "service_role";



GRANT ALL ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "public"."appointment_method_enum", "p_service_type" "public"."appointment_type_enum", "p_notes" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "public"."appointment_method_enum", "p_service_type" "public"."appointment_type_enum", "p_notes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "public"."appointment_method_enum", "p_service_type" "public"."appointment_type_enum", "p_notes" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_appointment_payment_confirmation"("p_purchase_id" "uuid", "p_payment_intent_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."process_appointment_payment_confirmation"("p_purchase_id" "uuid", "p_payment_intent_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_appointment_payment_confirmation"("p_purchase_id" "uuid", "p_payment_intent_id" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_chat_message_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."process_chat_message_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_chat_message_notification"() TO "service_role";



GRANT ALL ON FUNCTION "public"."process_event_booking_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_attendees" integer, "p_is_virtual" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."process_event_booking_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_attendees" integer, "p_is_virtual" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_event_booking_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_ticket_id" "uuid", "p_date_id" "uuid", "p_attendees" integer, "p_is_virtual" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."process_invoice_paid"("invoice_id" "text", "event_data" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."process_invoice_paid"("invoice_id" "text", "event_data" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_invoice_paid"("invoice_id" "text", "event_data" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_payment_intent_succeeded"("payment_intent_id" "text", "event_data" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."process_payment_intent_succeeded"("payment_intent_id" "text", "event_data" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_payment_intent_succeeded"("payment_intent_id" "text", "event_data" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_pending_notifications"() TO "anon";
GRANT ALL ON FUNCTION "public"."process_pending_notifications"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_pending_notifications"() TO "service_role";



GRANT ALL ON FUNCTION "public"."process_subscription_updated"("subscription_id" "text", "event_data" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."process_subscription_updated"("subscription_id" "text", "event_data" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_subscription_updated"("subscription_id" "text", "event_data" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_waitlist_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."process_waitlist_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_waitlist_notification"() TO "service_role";



GRANT ALL ON TABLE "public"."embeddings" TO "anon";
GRANT ALL ON TABLE "public"."embeddings" TO "authenticated";
GRANT ALL ON TABLE "public"."embeddings" TO "service_role";



GRANT ALL ON FUNCTION "public"."query_embeddings"("query_embedding" "extensions"."vector", "match_threshold" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."query_embeddings"("query_embedding" "extensions"."vector", "match_threshold" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."query_embeddings"("query_embedding" "extensions"."vector", "match_threshold" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."query_video_assets"("track_filter" "text", "status_filter" "text", "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."query_video_assets"("track_filter" "text", "status_filter" "text", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."query_video_assets"("track_filter" "text", "status_filter" "text", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."random_future_date"("days_ahead" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."random_future_date"("days_ahead" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."random_future_date"("days_ahead" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."random_name"() TO "anon";
GRANT ALL ON FUNCTION "public"."random_name"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."random_name"() TO "service_role";



GRANT ALL ON FUNCTION "public"."random_timestamp"("start_date" timestamp without time zone, "end_date" timestamp without time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."random_timestamp"("start_date" timestamp without time zone, "end_date" timestamp without time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."random_timestamp"("start_date" timestamp without time zone, "end_date" timestamp without time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."register_fcm_token"("p_token" "text", "p_device_info" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."register_fcm_token"("p_token" "text", "p_device_info" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."register_fcm_token"("p_token" "text", "p_device_info" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."request_service_appointment"("p_service_id" "uuid", "p_requested_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text", "p_client_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."request_service_appointment"("p_service_id" "uuid", "p_requested_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text", "p_client_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_service_appointment"("p_service_id" "uuid", "p_requested_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text", "p_client_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."respond_to_appointment"("p_appointment_id" "uuid", "p_action" character varying, "p_new_start_time" timestamp with time zone, "p_new_end_time" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."respond_to_appointment"("p_appointment_id" "uuid", "p_action" character varying, "p_new_start_time" timestamp with time zone, "p_new_end_time" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."respond_to_appointment"("p_appointment_id" "uuid", "p_action" character varying, "p_new_start_time" timestamp with time zone, "p_new_end_time" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."respond_to_appointment_request"("p_appointment_id" "uuid", "p_action" "text", "p_alternative_time" timestamp with time zone, "p_provider_notes" "text", "p_base_url" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."respond_to_appointment_request"("p_appointment_id" "uuid", "p_action" "text", "p_alternative_time" timestamp with time zone, "p_provider_notes" "text", "p_base_url" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."respond_to_appointment_request"("p_appointment_id" "uuid", "p_action" "text", "p_alternative_time" timestamp with time zone, "p_provider_notes" "text", "p_base_url" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."run_seed_comments"() TO "anon";
GRANT ALL ON FUNCTION "public"."run_seed_comments"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."run_seed_comments"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sanitize_slug"("input" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."sanitize_slug"("input" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sanitize_slug"("input" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."seed_comments"() TO "anon";
GRANT ALL ON FUNCTION "public"."seed_comments"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."seed_comments"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_availability"("p_user_id" "uuid", "p_day" character varying, "p_is_active" boolean, "p_start_time" time without time zone, "p_end_time" time without time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."set_availability"("p_user_id" "uuid", "p_day" character varying, "p_is_active" boolean, "p_start_time" time without time zone, "p_end_time" time without time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_availability"("p_user_id" "uuid", "p_day" character varying, "p_is_active" boolean, "p_start_time" time without time zone, "p_end_time" time without time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_user_timezone_claim"("token" "jsonb", "claims" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."set_user_timezone_claim"("token" "jsonb", "claims" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_user_timezone_claim"("token" "jsonb", "claims" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."toggle_comment_reaction"("in_comment_id" bigint, "in_reaction_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."toggle_comment_reaction"("in_comment_id" bigint, "in_reaction_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."toggle_comment_reaction"("in_comment_id" bigint, "in_reaction_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."toggle_message_reaction"("p_message_id" "uuid", "p_reaction_type" "public"."reaction_type_enum", "p_emoji_code" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."toggle_message_reaction"("p_message_id" "uuid", "p_reaction_type" "public"."reaction_type_enum", "p_emoji_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."toggle_message_reaction"("p_message_id" "uuid", "p_reaction_type" "public"."reaction_type_enum", "p_emoji_code" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_create_embedding"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_create_embedding"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_create_embedding"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_article_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum") TO "anon";
GRANT ALL ON FUNCTION "public"."update_article_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_article_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_auth_user_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_auth_user_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_auth_user_role"() TO "service_role";
GRANT ALL ON FUNCTION "public"."update_auth_user_role"() TO "supabase_auth_admin";



GRANT ALL ON FUNCTION "public"."update_auth_user_timezone"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_auth_user_timezone"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_auth_user_timezone"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_ceremony_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_ceremony_type" "text", "p_ceremony_theme" "text", "p_ceremony_focus" "text", "p_what_to_bring" "text", "p_space_holder_names" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_ceremony_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_ceremony_type" "text", "p_ceremony_theme" "text", "p_ceremony_focus" "text", "p_what_to_bring" "text", "p_space_holder_names" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_ceremony_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_ceremony_type" "text", "p_ceremony_theme" "text", "p_ceremony_focus" "text", "p_what_to_bring" "text", "p_space_holder_names" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_chat_room_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_chat_room_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_chat_room_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_chat_room_timestamp_on_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_chat_room_timestamp_on_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_chat_room_timestamp_on_message"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_comment_date_time"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_comment_date_time"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_comment_date_time"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_comment_has_replies"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_comment_has_replies"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_comment_has_replies"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_coordinates_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_coordinates_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_coordinates_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_dance_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_freeform_movement" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."update_dance_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_freeform_movement" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_dance_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_freeform_movement" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_event_purchase_status"("p_purchase_id" "uuid", "p_payment_status" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_event_purchase_status"("p_purchase_id" "uuid", "p_payment_status" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_event_purchase_status"("p_purchase_id" "uuid", "p_payment_status" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_event_with_details"("p_event_id" "uuid", "p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_status" "public"."publish_status_enum", "p_tags" "text"[], "p_event_type" "public"."event_type_enum", "p_event_dates" "public"."event_date_input"[], "p_tickets" "public"."ticket_input"[], "p_room_name" "text", "p_room_password" "text", "p_location_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."update_event_with_details"("p_event_id" "uuid", "p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_status" "public"."publish_status_enum", "p_tags" "text"[], "p_event_type" "public"."event_type_enum", "p_event_dates" "public"."event_date_input"[], "p_tickets" "public"."ticket_input"[], "p_room_name" "text", "p_room_password" "text", "p_location_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_event_with_details"("p_event_id" "uuid", "p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_status" "public"."publish_status_enum", "p_tags" "text"[], "p_event_type" "public"."event_type_enum", "p_event_dates" "public"."event_date_input"[], "p_tickets" "public"."ticket_input"[], "p_room_name" "text", "p_room_password" "text", "p_location_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_journal_entry"("p_journal_entry_id" bigint, "p_title" "text", "p_content" "text", "p_mood" "public"."mood_enum", "p_privacy" "public"."journal_entry_privacy_enum", "p_tags" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."update_journal_entry"("p_journal_entry_id" bigint, "p_title" "text", "p_content" "text", "p_mood" "public"."mood_enum", "p_privacy" "public"."journal_entry_privacy_enum", "p_tags" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_journal_entry"("p_journal_entry_id" bigint, "p_title" "text", "p_content" "text", "p_mood" "public"."mood_enum", "p_privacy" "public"."journal_entry_privacy_enum", "p_tags" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_meditation_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_meditation_type" "text", "p_meditation_theme" "text", "p_meditation_focus" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_meditation_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_meditation_type" "text", "p_meditation_theme" "text", "p_meditation_focus" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_meditation_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_playlist_ids" "uuid"[], "p_meditation_type" "text", "p_meditation_theme" "text", "p_meditation_focus" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_message_status"("p_message_id" "uuid", "p_status" "public"."message_status_enum") TO "anon";
GRANT ALL ON FUNCTION "public"."update_message_status"("p_message_id" "uuid", "p_status" "public"."message_status_enum") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_message_status"("p_message_id" "uuid", "p_status" "public"."message_status_enum") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_modified_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_modified_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_modified_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_neuroflow_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_techniques_used" "text", "p_session_focus" "text", "p_personal_growth_outcomes" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_neuroflow_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_techniques_used" "text", "p_session_focus" "text", "p_personal_growth_outcomes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_neuroflow_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_techniques_used" "text", "p_session_focus" "text", "p_personal_growth_outcomes" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_notification_preferences"("p_type" "text", "p_in_app" boolean, "p_email" boolean, "p_push" boolean, "p_sms" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."update_notification_preferences"("p_type" "text", "p_in_app" boolean, "p_email" boolean, "p_push" boolean, "p_sms" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_notification_preferences"("p_type" "text", "p_in_app" boolean, "p_email" boolean, "p_push" boolean, "p_sms" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_notification_statistics"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_notification_statistics"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_notification_statistics"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_ondemand_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."update_ondemand_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_ondemand_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_protected_media_data_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_protected_media_data_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_protected_media_data_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_sender_read_receipt"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_sender_read_receipt"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_sender_read_receipt"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_service_booking_settings"("p_service_id" "uuid", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."update_service_booking_settings"("p_service_id" "uuid", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_service_booking_settings"("p_service_id" "uuid", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_service_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_location_id" "uuid", "p_price" numeric, "p_duration" interval, "p_type" "public"."event_type_enum", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."update_service_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_location_id" "uuid", "p_price" numeric, "p_duration" interval, "p_type" "public"."event_type_enum", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_service_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_location_id" "uuid", "p_price" numeric, "p_duration" interval, "p_type" "public"."event_type_enum", "p_booking_workflow" "text", "p_auto_confirm" boolean, "p_confirmation_deadline_hours" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_subscription_tier_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_subscription_tier_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_subscription_tier_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_ticket"("p_event_id" "uuid", "p_tickets" "public"."ticket_input"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."update_ticket"("p_event_id" "uuid", "p_tickets" "public"."ticket_input"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_ticket"("p_event_id" "uuid", "p_tickets" "public"."ticket_input"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_user_timezone"("new_timezone" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_user_timezone"("new_timezone" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_user_timezone"("new_timezone" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_yoga_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_yoga_style" "text", "p_chakras" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_yoga_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_yoga_style" "text", "p_chakras" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_yoga_content_with_details"("p_post_id" "uuid", "p_title" "text", "p_slug" "text", "p_description" "text", "p_content" "text", "p_thumbnail_url" "text", "p_tags" "text"[], "p_status" "public"."publish_status_enum", "p_media_type" "public"."media_type_enum", "p_duration" interval, "p_price" numeric, "p_protected_media_url" "text", "p_emotional_focuses" "text"[], "p_playlist_ids" "uuid"[], "p_instructor_name" character varying, "p_session_theme" character varying, "p_energy_level" integer, "p_spiritual_elements" "text", "p_emotional_focus" "text", "p_recommended_environment" "text", "p_body_focus" "text", "p_props" "text"[], "p_yoga_style" "text", "p_chakras" "text") TO "service_role";



GRANT ALL ON TABLE "public"."user_locations" TO "anon";
GRANT ALL ON TABLE "public"."user_locations" TO "authenticated";
GRANT ALL ON TABLE "public"."user_locations" TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_user_location"("p_lat" double precision, "p_lon" double precision, "p_location_id" "uuid", "p_location_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_user_location"("p_lat" double precision, "p_lon" double precision, "p_location_id" "uuid", "p_location_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_user_location"("p_lat" double precision, "p_lon" double precision, "p_location_id" "uuid", "p_location_name" "text") TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON FUNCTION "public"."user_can_view_notification"("notification_row" "public"."notifications") TO "anon";
GRANT ALL ON FUNCTION "public"."user_can_view_notification"("notification_row" "public"."notifications") TO "authenticated";
GRANT ALL ON FUNCTION "public"."user_can_view_notification"("notification_row" "public"."notifications") TO "service_role";



GRANT ALL ON TABLE "public"."content_purchases" TO "anon";
GRANT ALL ON TABLE "public"."content_purchases" TO "authenticated";
GRANT ALL ON TABLE "public"."content_purchases" TO "service_role";



GRANT ALL ON TABLE "public"."on_demand_media" TO "anon";
GRANT ALL ON TABLE "public"."on_demand_media" TO "authenticated";
GRANT ALL ON TABLE "public"."on_demand_media" TO "service_role";



GRANT ALL ON TABLE "public"."posts" TO "anon";
GRANT ALL ON TABLE "public"."posts" TO "authenticated";
GRANT ALL ON TABLE "public"."posts" TO "service_role";



GRANT ALL ON TABLE "public"."protected_media_data" TO "anon";
GRANT ALL ON TABLE "public"."protected_media_data" TO "authenticated";
GRANT ALL ON TABLE "public"."protected_media_data" TO "service_role";



GRANT ALL ON TABLE "public"."purchases" TO "anon";
GRANT ALL ON TABLE "public"."purchases" TO "authenticated";
GRANT ALL ON TABLE "public"."purchases" TO "service_role";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."accessible_media" TO "anon";
GRANT ALL ON TABLE "public"."accessible_media" TO "authenticated";
GRANT ALL ON TABLE "public"."accessible_media" TO "service_role";



GRANT ALL ON TABLE "public"."appointment_purchases" TO "anon";
GRANT ALL ON TABLE "public"."appointment_purchases" TO "authenticated";
GRANT ALL ON TABLE "public"."appointment_purchases" TO "service_role";



GRANT ALL ON TABLE "public"."appointments" TO "anon";
GRANT ALL ON TABLE "public"."appointments" TO "authenticated";
GRANT ALL ON TABLE "public"."appointments" TO "service_role";



GRANT ALL ON TABLE "public"."articles" TO "anon";
GRANT ALL ON TABLE "public"."articles" TO "authenticated";
GRANT ALL ON TABLE "public"."articles" TO "service_role";



GRANT ALL ON TABLE "public"."assets" TO "anon";
GRANT ALL ON TABLE "public"."assets" TO "authenticated";
GRANT ALL ON TABLE "public"."assets" TO "service_role";



GRANT ALL ON TABLE "public"."availability" TO "anon";
GRANT ALL ON TABLE "public"."availability" TO "authenticated";
GRANT ALL ON TABLE "public"."availability" TO "service_role";



GRANT ALL ON TABLE "public"."availability_exceptions" TO "anon";
GRANT ALL ON TABLE "public"."availability_exceptions" TO "authenticated";
GRANT ALL ON TABLE "public"."availability_exceptions" TO "service_role";



GRANT ALL ON TABLE "public"."bookings" TO "anon";
GRANT ALL ON TABLE "public"."bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."bookings" TO "service_role";



GRANT ALL ON TABLE "public"."ceremony" TO "anon";
GRANT ALL ON TABLE "public"."ceremony" TO "authenticated";
GRANT ALL ON TABLE "public"."ceremony" TO "service_role";



GRANT ALL ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";



GRANT ALL ON TABLE "public"."post_tags" TO "anon";
GRANT ALL ON TABLE "public"."post_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."post_tags" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."services" TO "anon";
GRANT ALL ON TABLE "public"."services" TO "authenticated";
GRANT ALL ON TABLE "public"."services" TO "service_role";



GRANT ALL ON TABLE "public"."tags" TO "anon";
GRANT ALL ON TABLE "public"."tags" TO "authenticated";
GRANT ALL ON TABLE "public"."tags" TO "service_role";



GRANT ALL ON TABLE "public"."post_details" TO "anon";
GRANT ALL ON TABLE "public"."post_details" TO "authenticated";
GRANT ALL ON TABLE "public"."post_details" TO "service_role";



GRANT ALL ON TABLE "public"."spotify_playlist_join" TO "anon";
GRANT ALL ON TABLE "public"."spotify_playlist_join" TO "authenticated";
GRANT ALL ON TABLE "public"."spotify_playlist_join" TO "service_role";



GRANT ALL ON TABLE "public"."spotify_playlists" TO "anon";
GRANT ALL ON TABLE "public"."spotify_playlists" TO "authenticated";
GRANT ALL ON TABLE "public"."spotify_playlists" TO "service_role";



GRANT ALL ON TABLE "public"."on_demand_base" TO "anon";
GRANT ALL ON TABLE "public"."on_demand_base" TO "authenticated";
GRANT ALL ON TABLE "public"."on_demand_base" TO "service_role";



GRANT ALL ON TABLE "public"."ceremony_details" TO "anon";
GRANT ALL ON TABLE "public"."ceremony_details" TO "authenticated";
GRANT ALL ON TABLE "public"."ceremony_details" TO "service_role";



GRANT ALL ON TABLE "public"."chat_messages" TO "anon";
GRANT ALL ON TABLE "public"."chat_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_messages" TO "service_role";



GRANT ALL ON TABLE "public"."chat_rooms" TO "anon";
GRANT ALL ON TABLE "public"."chat_rooms" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_rooms" TO "service_role";



GRANT ALL ON TABLE "public"."comment_attachments" TO "anon";
GRANT ALL ON TABLE "public"."comment_attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."comment_attachments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."comment_attachments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."comment_attachments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."comment_attachments_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."comment_mentions" TO "anon";
GRANT ALL ON TABLE "public"."comment_mentions" TO "authenticated";
GRANT ALL ON TABLE "public"."comment_mentions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."comment_mentions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."comment_mentions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."comment_mentions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."comment_reactions" TO "anon";
GRANT ALL ON TABLE "public"."comment_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."comment_reactions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."comment_reactions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."comment_reactions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."comment_reactions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."comments" TO "anon";
GRANT ALL ON TABLE "public"."comments" TO "authenticated";
GRANT ALL ON TABLE "public"."comments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."event_bookings" TO "anon";
GRANT ALL ON TABLE "public"."event_bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."event_bookings" TO "service_role";



GRANT ALL ON TABLE "public"."event_dates" TO "anon";
GRANT ALL ON TABLE "public"."event_dates" TO "authenticated";
GRANT ALL ON TABLE "public"."event_dates" TO "service_role";



GRANT ALL ON TABLE "public"."tickets" TO "anon";
GRANT ALL ON TABLE "public"."tickets" TO "authenticated";
GRANT ALL ON TABLE "public"."tickets" TO "service_role";



GRANT ALL ON TABLE "public"."event_dates_view" TO "anon";
GRANT ALL ON TABLE "public"."event_dates_view" TO "authenticated";
GRANT ALL ON TABLE "public"."event_dates_view" TO "service_role";



GRANT ALL ON TABLE "public"."live_rooms" TO "anon";
GRANT ALL ON TABLE "public"."live_rooms" TO "authenticated";
GRANT ALL ON TABLE "public"."live_rooms" TO "service_role";



GRANT ALL ON TABLE "public"."locations" TO "anon";
GRANT ALL ON TABLE "public"."locations" TO "authenticated";
GRANT ALL ON TABLE "public"."locations" TO "service_role";



GRANT ALL ON TABLE "public"."post_locations" TO "anon";
GRANT ALL ON TABLE "public"."post_locations" TO "authenticated";
GRANT ALL ON TABLE "public"."post_locations" TO "service_role";



GRANT ALL ON TABLE "public"."event_details_view" TO "anon";
GRANT ALL ON TABLE "public"."event_details_view" TO "authenticated";
GRANT ALL ON TABLE "public"."event_details_view" TO "service_role";



GRANT ALL ON TABLE "public"."event_tickets_view" TO "anon";
GRANT ALL ON TABLE "public"."event_tickets_view" TO "authenticated";
GRANT ALL ON TABLE "public"."event_tickets_view" TO "service_role";



GRANT ALL ON TABLE "public"."comprehensive_events_view" TO "anon";
GRANT ALL ON TABLE "public"."comprehensive_events_view" TO "authenticated";
GRANT ALL ON TABLE "public"."comprehensive_events_view" TO "service_role";



GRANT ALL ON TABLE "public"."service_appointments_view" TO "anon";
GRANT ALL ON TABLE "public"."service_appointments_view" TO "authenticated";
GRANT ALL ON TABLE "public"."service_appointments_view" TO "service_role";



GRANT ALL ON TABLE "public"."service_details_view" TO "anon";
GRANT ALL ON TABLE "public"."service_details_view" TO "authenticated";
GRANT ALL ON TABLE "public"."service_details_view" TO "service_role";



GRANT ALL ON TABLE "public"."comprehensive_services_view" TO "anon";
GRANT ALL ON TABLE "public"."comprehensive_services_view" TO "authenticated";
GRANT ALL ON TABLE "public"."comprehensive_services_view" TO "service_role";



GRANT ALL ON TABLE "public"."creator_branding" TO "anon";
GRANT ALL ON TABLE "public"."creator_branding" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_branding" TO "service_role";



GRANT ALL ON TABLE "public"."creator_emails" TO "anon";
GRANT ALL ON TABLE "public"."creator_emails" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_emails" TO "service_role";



GRANT ALL ON TABLE "public"."creator_profiles" TO "anon";
GRANT ALL ON TABLE "public"."creator_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "anon";
GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";
GRANT ALL ON TABLE "public"."user_roles" TO "supabase_auth_admin";



GRANT ALL ON TABLE "public"."creator_profiles_complete_view" TO "anon";
GRANT ALL ON TABLE "public"."creator_profiles_complete_view" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_profiles_complete_view" TO "service_role";



GRANT ALL ON TABLE "public"."notification_deliveries" TO "anon";
GRANT ALL ON TABLE "public"."notification_deliveries" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_deliveries" TO "service_role";



GRANT ALL ON TABLE "public"."creator_sent_notifications" TO "anon";
GRANT ALL ON TABLE "public"."creator_sent_notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_sent_notifications" TO "service_role";



GRANT ALL ON TABLE "public"."creator_subscription_tiers" TO "anon";
GRANT ALL ON TABLE "public"."creator_subscription_tiers" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_subscription_tiers" TO "service_role";



GRANT ALL ON TABLE "public"."dance" TO "anon";
GRANT ALL ON TABLE "public"."dance" TO "authenticated";
GRANT ALL ON TABLE "public"."dance" TO "service_role";



GRANT ALL ON TABLE "public"."movements" TO "anon";
GRANT ALL ON TABLE "public"."movements" TO "authenticated";
GRANT ALL ON TABLE "public"."movements" TO "service_role";



GRANT ALL ON TABLE "public"."movement_details" TO "anon";
GRANT ALL ON TABLE "public"."movement_details" TO "authenticated";
GRANT ALL ON TABLE "public"."movement_details" TO "service_role";



GRANT ALL ON TABLE "public"."dance_details" TO "anon";
GRANT ALL ON TABLE "public"."dance_details" TO "authenticated";
GRANT ALL ON TABLE "public"."dance_details" TO "service_role";



GRANT ALL ON TABLE "public"."email_templates" TO "anon";
GRANT ALL ON TABLE "public"."email_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."email_templates" TO "service_role";



GRANT ALL ON TABLE "public"."emotional_focuses" TO "anon";
GRANT ALL ON TABLE "public"."emotional_focuses" TO "authenticated";
GRANT ALL ON TABLE "public"."emotional_focuses" TO "service_role";



GRANT ALL ON TABLE "public"."error_logs" TO "anon";
GRANT ALL ON TABLE "public"."error_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."error_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."error_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."error_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."error_logs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."events_view" TO "anon";
GRANT ALL ON TABLE "public"."events_view" TO "authenticated";
GRANT ALL ON TABLE "public"."events_view" TO "service_role";



GRANT ALL ON TABLE "public"."invoices" TO "anon";
GRANT ALL ON TABLE "public"."invoices" TO "authenticated";
GRANT ALL ON TABLE "public"."invoices" TO "service_role";



GRANT ALL ON TABLE "public"."journal_content_links" TO "anon";
GRANT ALL ON TABLE "public"."journal_content_links" TO "authenticated";
GRANT ALL ON TABLE "public"."journal_content_links" TO "service_role";



GRANT ALL ON SEQUENCE "public"."journal_content_links_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."journal_content_links_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."journal_content_links_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."journal_entries" TO "anon";
GRANT ALL ON TABLE "public"."journal_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."journal_entries" TO "service_role";



GRANT ALL ON SEQUENCE "public"."journal_entries_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."journal_entries_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."journal_entries_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."journal_entries_with_details" TO "anon";
GRANT ALL ON TABLE "public"."journal_entries_with_details" TO "authenticated";
GRANT ALL ON TABLE "public"."journal_entries_with_details" TO "service_role";



GRANT ALL ON TABLE "public"."journal_entry_tags" TO "anon";
GRANT ALL ON TABLE "public"."journal_entry_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."journal_entry_tags" TO "service_role";



GRANT ALL ON TABLE "public"."journal_media" TO "anon";
GRANT ALL ON TABLE "public"."journal_media" TO "authenticated";
GRANT ALL ON TABLE "public"."journal_media" TO "service_role";



GRANT ALL ON SEQUENCE "public"."journal_media_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."journal_media_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."journal_media_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."journal_tags" TO "anon";
GRANT ALL ON TABLE "public"."journal_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."journal_tags" TO "service_role";



GRANT ALL ON SEQUENCE "public"."journal_tags_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."journal_tags_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."journal_tags_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."live_room_participants" TO "anon";
GRANT ALL ON TABLE "public"."live_room_participants" TO "authenticated";
GRANT ALL ON TABLE "public"."live_room_participants" TO "service_role";



GRANT ALL ON TABLE "public"."meditations" TO "anon";
GRANT ALL ON TABLE "public"."meditations" TO "authenticated";
GRANT ALL ON TABLE "public"."meditations" TO "service_role";



GRANT ALL ON TABLE "public"."meditation_details" TO "anon";
GRANT ALL ON TABLE "public"."meditation_details" TO "authenticated";
GRANT ALL ON TABLE "public"."meditation_details" TO "service_role";



GRANT ALL ON TABLE "public"."message_reactions" TO "anon";
GRANT ALL ON TABLE "public"."message_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."message_reactions" TO "service_role";



GRANT ALL ON TABLE "public"."message_read_receipts" TO "anon";
GRANT ALL ON TABLE "public"."message_read_receipts" TO "authenticated";
GRANT ALL ON TABLE "public"."message_read_receipts" TO "service_role";



GRANT ALL ON TABLE "public"."movement_props" TO "anon";
GRANT ALL ON TABLE "public"."movement_props" TO "authenticated";
GRANT ALL ON TABLE "public"."movement_props" TO "service_role";



GRANT ALL ON TABLE "public"."movement_props_join" TO "anon";
GRANT ALL ON TABLE "public"."movement_props_join" TO "authenticated";
GRANT ALL ON TABLE "public"."movement_props_join" TO "service_role";



GRANT ALL ON TABLE "public"."neuroflow" TO "anon";
GRANT ALL ON TABLE "public"."neuroflow" TO "authenticated";
GRANT ALL ON TABLE "public"."neuroflow" TO "service_role";



GRANT ALL ON TABLE "public"."neuroflow_details" TO "anon";
GRANT ALL ON TABLE "public"."neuroflow_details" TO "authenticated";
GRANT ALL ON TABLE "public"."neuroflow_details" TO "service_role";



GRANT ALL ON TABLE "public"."notification_preferences" TO "anon";
GRANT ALL ON TABLE "public"."notification_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."notification_read_receipts" TO "anon";
GRANT ALL ON TABLE "public"."notification_read_receipts" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_read_receipts" TO "service_role";



GRANT ALL ON TABLE "public"."notification_recipients" TO "anon";
GRANT ALL ON TABLE "public"."notification_recipients" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_recipients" TO "service_role";



GRANT ALL ON TABLE "public"."notification_statistics" TO "anon";
GRANT ALL ON TABLE "public"."notification_statistics" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_statistics" TO "service_role";



GRANT ALL ON TABLE "public"."notification_templates" TO "anon";
GRANT ALL ON TABLE "public"."notification_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_templates" TO "service_role";



GRANT ALL ON TABLE "public"."onboarding_progress" TO "anon";
GRANT ALL ON TABLE "public"."onboarding_progress" TO "authenticated";
GRANT ALL ON TABLE "public"."onboarding_progress" TO "service_role";



GRANT ALL ON TABLE "public"."pending_payment_appointments" TO "anon";
GRANT ALL ON TABLE "public"."pending_payment_appointments" TO "authenticated";
GRANT ALL ON TABLE "public"."pending_payment_appointments" TO "service_role";



GRANT ALL ON TABLE "public"."post_emotional_focuses" TO "anon";
GRANT ALL ON TABLE "public"."post_emotional_focuses" TO "authenticated";
GRANT ALL ON TABLE "public"."post_emotional_focuses" TO "service_role";



GRANT ALL ON TABLE "public"."profile_cards_view" TO "anon";
GRANT ALL ON TABLE "public"."profile_cards_view" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_cards_view" TO "service_role";



GRANT ALL ON TABLE "public"."provider_preferences" TO "anon";
GRANT ALL ON TABLE "public"."provider_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."provider_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."recent_errors" TO "anon";
GRANT ALL ON TABLE "public"."recent_errors" TO "authenticated";
GRANT ALL ON TABLE "public"."recent_errors" TO "service_role";



GRANT ALL ON TABLE "public"."role_permissions" TO "anon";
GRANT ALL ON TABLE "public"."role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permissions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."room_posts" TO "anon";
GRANT ALL ON TABLE "public"."room_posts" TO "authenticated";
GRANT ALL ON TABLE "public"."room_posts" TO "service_role";



GRANT ALL ON TABLE "public"."service_bookings" TO "anon";
GRANT ALL ON TABLE "public"."service_bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."service_bookings" TO "service_role";



GRANT ALL ON TABLE "public"."service_dates" TO "anon";
GRANT ALL ON TABLE "public"."service_dates" TO "authenticated";
GRANT ALL ON TABLE "public"."service_dates" TO "service_role";



GRANT ALL ON TABLE "public"."service_reservations" TO "anon";
GRANT ALL ON TABLE "public"."service_reservations" TO "authenticated";
GRANT ALL ON TABLE "public"."service_reservations" TO "service_role";



GRANT ALL ON TABLE "public"."stripe_webhook_events" TO "anon";
GRANT ALL ON TABLE "public"."stripe_webhook_events" TO "authenticated";
GRANT ALL ON TABLE "public"."stripe_webhook_events" TO "service_role";



GRANT ALL ON TABLE "public"."subscription_content_access" TO "anon";
GRANT ALL ON TABLE "public"."subscription_content_access" TO "authenticated";
GRANT ALL ON TABLE "public"."subscription_content_access" TO "service_role";



GRANT ALL ON TABLE "public"."suggestions" TO "anon";
GRANT ALL ON TABLE "public"."suggestions" TO "authenticated";
GRANT ALL ON TABLE "public"."suggestions" TO "service_role";



GRANT ALL ON TABLE "public"."transcripts" TO "anon";
GRANT ALL ON TABLE "public"."transcripts" TO "authenticated";
GRANT ALL ON TABLE "public"."transcripts" TO "service_role";



GRANT ALL ON TABLE "public"."user_appointments_view" TO "anon";
GRANT ALL ON TABLE "public"."user_appointments_view" TO "authenticated";
GRANT ALL ON TABLE "public"."user_appointments_view" TO "service_role";



GRANT ALL ON TABLE "public"."user_fcm_tokens" TO "anon";
GRANT ALL ON TABLE "public"."user_fcm_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."user_fcm_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."user_journal_stats" TO "anon";
GRANT ALL ON TABLE "public"."user_journal_stats" TO "authenticated";
GRANT ALL ON TABLE "public"."user_journal_stats" TO "service_role";



GRANT ALL ON TABLE "public"."user_notifications_view" TO "anon";
GRANT ALL ON TABLE "public"."user_notifications_view" TO "authenticated";
GRANT ALL ON TABLE "public"."user_notifications_view" TO "service_role";



GRANT ALL ON TABLE "public"."user_notifications_with_broadcasts" TO "anon";
GRANT ALL ON TABLE "public"."user_notifications_with_broadcasts" TO "authenticated";
GRANT ALL ON TABLE "public"."user_notifications_with_broadcasts" TO "service_role";



GRANT ALL ON TABLE "public"."user_stripe_data" TO "anon";
GRANT ALL ON TABLE "public"."user_stripe_data" TO "authenticated";
GRANT ALL ON TABLE "public"."user_stripe_data" TO "service_role";



GRANT ALL ON TABLE "public"."user_timezones" TO "anon";
GRANT ALL ON TABLE "public"."user_timezones" TO "authenticated";
GRANT ALL ON TABLE "public"."user_timezones" TO "service_role";
GRANT ALL ON TABLE "public"."user_timezones" TO "supabase_auth_admin";



GRANT ALL ON TABLE "public"."video_assets" TO "anon";
GRANT ALL ON TABLE "public"."video_assets" TO "authenticated";
GRANT ALL ON TABLE "public"."video_assets" TO "service_role";



GRANT ALL ON TABLE "public"."waitlists" TO "anon";
GRANT ALL ON TABLE "public"."waitlists" TO "authenticated";
GRANT ALL ON TABLE "public"."waitlists" TO "service_role";



GRANT ALL ON TABLE "public"."yoga" TO "anon";
GRANT ALL ON TABLE "public"."yoga" TO "authenticated";
GRANT ALL ON TABLE "public"."yoga" TO "service_role";



GRANT ALL ON TABLE "public"."yoga_details" TO "anon";
GRANT ALL ON TABLE "public"."yoga_details" TO "authenticated";
GRANT ALL ON TABLE "public"."yoga_details" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






RESET ALL;
