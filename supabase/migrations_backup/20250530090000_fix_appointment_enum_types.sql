-- Migration to ensure proper enum types for appointment system

-- Make sure all enum types exist with proper values
DO $$
BEGIN
    -- Create purchase_payment_status_enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'purchase_payment_status_enum') THEN
        CREATE TYPE "public"."purchase_payment_status_enum" AS ENUM ('completed', 'pending', 'refunded', 'failed');
    END IF;
    
    -- Create purchase_type_enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'purchase_type_enum') THEN
        CREATE TYPE "public"."purchase_type_enum" AS ENUM ('content', 'event', 'appointment', 'subscription', 'article');
    END IF;
    
    -- Create appointment_method_enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'appointment_method_enum') THEN
        CREATE TYPE "public"."appointment_method_enum" AS ENUM ('video', 'phone', 'in-person');
    END IF;
    
    -- Create appointment_type_enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'appointment_type_enum') THEN
        CREATE TYPE "public"."appointment_type_enum" AS ENUM ('reading', 'healing', 'coaching', 'consultation');
    END IF;
    
    -- Create appointment_status_enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'appointment_status_enum') THEN
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
    END IF;
END$$;

-- Fix the auto_confirm_appointment trigger function
CREATE OR REPLACE FUNCTION public.auto_confirm_appointment()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Make sure the trigger is properly configured with enum type
DROP TRIGGER IF EXISTS trg_auto_confirm_appointment ON public.appointment_purchases;

CREATE TRIGGER trg_auto_confirm_appointment
BEFORE UPDATE OF status ON public.appointment_purchases
FOR EACH ROW
WHEN (NEW.status = 'pending_auto_payment'::appointment_status_enum)
EXECUTE FUNCTION public.auto_confirm_appointment();

COMMENT ON FUNCTION public.auto_confirm_appointment() IS 'Trigger function to automatically approve appointments when their status is set to pending_auto_payment by calling the approve_appointment_request function';

-- Fix views to properly use the appointment status enum type
CREATE OR REPLACE VIEW public.pending_payment_appointments AS
SELECT 
  ap.id,
  ap.purchase_id,
  ap.service_id,
  ap.appointment_date,
  ap.duration,
  ap.method,
  ap.status,
  ap.created_at,
  ap.updated_at,
  ap.notes,
  ap.metadata,
  ap.meeting_url,
  ap.payment_link,
  p.user_id,
  p.owner_id,
  p.amount,
  p.payment_status,
  s.type as service_type,
  COALESCE(po.title, 'Service') as service_name
FROM 
  appointment_purchases ap
  JOIN purchases p ON ap.purchase_id = p.id
  JOIN services s ON ap.service_id = s.id
  LEFT JOIN posts po ON s.post_id = po.id
WHERE 
  ap.status = 'pending_payment'::appointment_status_enum
  AND ap.payment_link IS NOT NULL;

COMMENT ON VIEW public.pending_payment_appointments IS 'View to easily find appointments awaiting payment with their payment links';

-- Fix service_appointments_view to correctly use enum types
CREATE OR REPLACE VIEW "public"."service_appointments_view" AS
SELECT 
  "ap"."id" AS "appointment_id",
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
  (ap.status = 'confirmed'::appointment_status_enum) AS is_confirmed,
  (ap.status = 'completed'::appointment_status_enum) AS is_completed,
  (ap.status = 'cancelled'::appointment_status_enum) AS is_cancelled
FROM 
  "public"."appointment_purchases" "ap"
  JOIN "public"."purchases" "p" ON "ap"."purchase_id" = "p"."id"
  LEFT JOIN "public"."profiles" "cl" ON "p"."user_id" = "cl"."id";

COMMENT ON VIEW "public"."service_appointments_view" IS 'View of service appointments with client/provider details';

-- Fix comprehensive_services_view to correctly use enum types in all JSON aggregations
CREATE OR REPLACE VIEW "public"."comprehensive_services_view" AS
SELECT 
  "sv"."id" AS "service_id",
  "sv"."post_id",
  "sv"."content",
  "sv"."price",
  "sv"."duration",
  "sv"."booking_workflow",
  "sv"."auto_confirm",
  "sv"."type",
  "sv"."link_specific",
  "sv"."created_at",
  "sv"."updated_at",
  "po"."title",
  "po"."description",
  "po"."slug",
  "po"."thumbnail_url",
  "po"."user_id",
  "po"."status",
  "po"."published_at",
  "pr"."full_name" AS "provider_name",
  "pr"."avatar_url" AS "provider_avatar_url",
  COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "sav"."appointment_id", 'appointment_date', "sav"."appointment_date", 'duration', "sav"."duration", 'method', "sav"."method", 'service_type', "sav"."service_type", 'status', "sav"."status", 'client', "sav"."client", 'is_future', "sav"."is_future") ORDER BY "sav"."appointment_date") AS "jsonb_agg"
         FROM "public"."service_appointments_view" "sav"
        WHERE ((("sav"."service_id" = "sv"."service_id") AND (sav.status = ANY (ARRAY['confirmed'::appointment_status_enum, 'pending_payment'::appointment_status_enum,'pending_approval'::appointment_status_enum,'pending_reschedule'::appointment_status_enum])) AND ("sav"."provider_id" = "auth"."uid"())))), '[]'::jsonb) AS "appointments",
  COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "sav"."appointment_id", 'appointment_date', "sav"."appointment_date", 'duration', "sav"."duration", 'method', "sav"."method", 'service_type', "sav"."service_type", 'status', "sav"."status") ORDER BY "sav"."appointment_date") AS "jsonb_agg"
         FROM "public"."service_appointments_view" "sav"
        WHERE ((("sav"."service_id" = "sv"."service_id") AND ("sav"."is_future" = true) AND (sav.status = ANY (ARRAY['confirmed'::appointment_status_enum, 'pending_payment'::appointment_status_enum,'pending_approval'::appointment_status_enum,'pending_reschedule'::appointment_status_enum])) AND ("sav"."provider_id" = "auth"."uid"())))), '[]'::jsonb) AS "future_appointments",
  COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "sav"."appointment_id", 'appointment_date', "sav"."appointment_date", 'duration', "sav"."duration", 'method', "sav"."method", 'service_type', "sav"."service_type", 'status', "sav"."status", 'client', "sav"."client") ORDER BY "sav"."appointment_date" DESC) AS "jsonb_agg"
         FROM "public"."service_appointments_view" "sav"
        WHERE ((("sav"."service_id" = "sv"."service_id") AND ("sav"."is_future" = false) AND (sav.status = ANY (ARRAY['confirmed'::appointment_status_enum, 'completed'::appointment_status_enum])) AND ("sav"."provider_id" = "auth"."uid"())))), '[]'::jsonb) AS "past_appointments",
  "jsonb_build_object"('has_appointments', (EXISTS ( SELECT 1
         FROM "public"."service_appointments_view" "sav"
        WHERE ((("sav"."service_id" = "sv"."service_id") AND (sav.status = ANY (ARRAY['confirmed'::appointment_status_enum, 'pending_payment'::appointment_status_enum,'pending_approval'::appointment_status_enum,'pending_reschedule'::appointment_status_enum])) AND ("sav"."is_future" = true))))), 'upcoming_count', ( SELECT "count"(*) AS "count"
         FROM "public"."service_appointments_view" "sav"
        WHERE ((("sav"."service_id" = "sv"."service_id") AND (sav.status = ANY (ARRAY['confirmed'::appointment_status_enum, 'pending_payment'::appointment_status_enum,'pending_approval'::appointment_status_enum,'pending_reschedule'::appointment_status_enum])) AND ("sav"."is_future" = true)))), 'total_completed', ( SELECT "count"(*) AS "count"
         FROM "public"."service_appointments_view" "sav"
        WHERE ((("sav"."service_id" = "sv"."service_id") AND (sav.status = 'completed'::appointment_status_enum))))) AS "availability_stats"
FROM (((("public"."services" "sv"
  JOIN "public"."posts" "po" ON (("sv"."post_id" = "po"."id")))
  LEFT JOIN "public"."profiles" "pr" ON (("po"."user_id" = "pr"."id")))
  LEFT JOIN "public"."user_locations" "loc" ON (("po"."user_id" = "loc"."user_id"))))
WHERE (("po"."status" = 'published'::"text") AND ("auth"."uid"() = "po"."user_id"));

COMMENT ON VIEW "public"."comprehensive_services_view" IS 'View of services with their appointments and stats';

-- Migration to update functions to use proper enum types
-- This migration fixes functions after the enums have been properly defined

-- Update request_service_appointment function to use enum types
CREATE OR REPLACE FUNCTION "public"."request_service_appointment"("p_service_id" "uuid", "p_requested_date" timestamp with time zone, "p_duration" integer DEFAULT NULL::integer, "p_method" "public"."appointment_method_enum" DEFAULT 'video'::"public"."appointment_method_enum", "p_service_type" "public"."appointment_type_enum" DEFAULT 'consultation'::"public"."appointment_type_enum", "p_notes" "text" DEFAULT NULL::"text", "p_client_id" "uuid" DEFAULT NULL::"uuid") RETURNS "jsonb"
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
    v_initial_status appointment_status_enum;
    v_result JSONB;
    v_timezone TEXT;
    v_slot_available BOOLEAN;
    v_lock_key BIGINT;
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
            v_initial_status := 'confirmed'::appointment_status_enum;
        -- WHEN v_booking_workflow = 'direct' AND NOT v_auto_confirm THEN
        --     v_initial_status := 'pending_payment'::appointment_status_enum;
        WHEN v_booking_workflow = 'pre-approval' THEN
            if v_auto_confirm then
                v_initial_status := 'pending_payment'::appointment_status_enum;
            else 
                v_initial_status := 'pending_auto_payment'::appointment_status_enum;
            end if;
        WHEN v_booking_workflow = 'waitlist' THEN
            v_initial_status := 'pending_approval'::appointment_status_enum;
        ELSE
            v_initial_status := 'pending_approval'::appointment_status_enum;
    END CASE;
    
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
        CASE WHEN v_initial_status = 'confirmed'::appointment_status_enum THEN 'completed'::purchase_payment_status_enum ELSE 'pending'::purchase_payment_status_enum END,
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
        p_method,
        p_service_type,
        v_initial_status,
        p_notes
    ) RETURNING id INTO v_appointment_id;
    
    -- Return result with appropriate next steps
    v_result := jsonb_build_object(
        'success', TRUE,
        'appointment_id', v_appointment_id,
        'purchase_id', v_purchase_id,
        'service_id', p_service_id,
        'status', v_initial_status,
        'requires_payment', (v_initial_status = 'pending_payment'::appointment_status_enum),
        'requires_approval', (v_initial_status = 'pending_approval'::appointment_status_enum),
        'appointment_date', p_requested_date,
        'duration', v_service_duration,
        'price', v_service_price,
        'provider_id', v_service_owner_id,
        'client_id', v_client_id,
        'workflow', v_booking_workflow,
        'next_steps', CASE
            WHEN v_initial_status = 'pending_payment'::appointment_status_enum THEN 'Payment required to confirm booking'
            WHEN v_initial_status = 'pending_approval'::appointment_status_enum THEN 'Waiting for provider approval'
            WHEN v_initial_status = 'confirmed'::appointment_status_enum THEN 'Appointment confirmed'
            ELSE 'Review appointment details'
        END
    );
    
    RETURN v_result;
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', FALSE,
        'error', SQLERRM
    );
END;
$$;

-- Update respond_to_appointment_request function to use enum types
CREATE OR REPLACE FUNCTION "public"."respond_to_appointment_request"("p_appointment_id" "uuid", "p_action" "text", "p_alternative_time" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_provider_notes" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_appointment_record RECORD;
    v_provider_id UUID;
    v_current_status appointment_status_enum;
    v_source TEXT;
    v_purchase_id UUID;
    v_result JSONB;
BEGIN
    -- Determine which system the appointment is in
    
    -- First check appointment_purchases
    SELECT 
        ap.id, 
        ap.status, 
        p.owner_id AS provider_id,
        'appointment_purchase' AS source,
        p.id AS purchase_id
    INTO v_appointment_record
    FROM 
        public.appointment_purchases ap
    JOIN 
        public.purchases p ON ap.purchase_id = p.id
    WHERE 
        ap.id = p_appointment_id;
    
    -- If not found, check legacy appointments
    IF v_appointment_record.id IS NULL THEN
        SELECT 
            a.id, 
            a.status, 
            a.facilitator_id AS provider_id,
            'legacy_appointment' AS source,
            NULL AS purchase_id
        INTO v_appointment_record
        FROM 
            public.appointments a
        WHERE 
            a.id = p_appointment_id;
    END IF;
    
    -- If still not found, appointment doesn't exist
    IF v_appointment_record.id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Appointment not found'
        );
    END IF;
    
    -- Store found values
    v_provider_id := v_appointment_record.provider_id;
    v_current_status := v_appointment_record.status;
    v_source := v_appointment_record.source;
    v_purchase_id := v_appointment_record.purchase_id;
    
    -- Check permissions
    IF v_provider_id != auth.uid() AND NOT EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Permission denied'
        );
    END IF;
    
    -- Process the response based on source system
    IF v_source = 'appointment_purchase' THEN
        -- Handle appointment_purchases
        IF p_action = 'confirm' THEN
            IF v_current_status NOT IN ('pending_approval'::appointment_status_enum, 'pending_payment'::appointment_status_enum) THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Appointment cannot be confirmed in its current status: ' || v_current_status
                );
            END IF;
            
            -- Update to confirmed
            UPDATE public.appointment_purchases
            SET 
                status = 'confirmed'::appointment_status_enum,
                notes = CASE 
                    WHEN p_provider_notes IS NOT NULL THEN 
                        COALESCE(notes, '') || E'\nProvider notes: ' || p_provider_notes
                    ELSE notes
                END
            WHERE id = p_appointment_id;
            
            -- Also update purchase if needed
            IF v_current_status = 'pending_approval'::appointment_status_enum THEN
                UPDATE public.purchases
                SET payment_status = 'completed'::purchase_payment_status_enum
                WHERE id = v_purchase_id;
            END IF;
            
            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'confirm',
                'appointment_id', p_appointment_id,
                'status', 'confirmed'
            );
            
        ELSIF p_action = 'reject' THEN
            IF v_current_status NOT IN ('pending_approval'::appointment_status_enum, 'pending_payment'::appointment_status_enum, 'confirmed'::appointment_status_enum) THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Appointment cannot be rejected in its current status: ' || v_current_status
                );
            END IF;
            
            -- Update to cancelled
            UPDATE public.appointment_purchases
            SET 
                status = 'cancelled'::appointment_status_enum,
                notes = CASE 
                    WHEN p_provider_notes IS NOT NULL THEN 
                        COALESCE(notes, '') || E'\nRejection reason: ' || p_provider_notes
                    ELSE notes
                END
            WHERE id = p_appointment_id;
            
            -- If payment was already made, set to refunded
            IF v_current_status IN ('confirmed'::appointment_status_enum, 'pending_payment'::appointment_status_enum) THEN
                UPDATE public.purchases
                SET payment_status = 'refunded'::purchase_payment_status_enum
                WHERE id = v_purchase_id;
            END IF;
            
            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'reject',
                'appointment_id', p_appointment_id,
                'status', 'cancelled'
            );
            
        ELSIF p_action = 'suggest_alternative' THEN
            IF v_current_status NOT IN ('pending_approval'::appointment_status_enum, 'pending_payment'::appointment_status_enum) OR p_alternative_time IS NULL THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Cannot suggest alternative time'
                );
            END IF;
            
            -- Create a record of the suggestion in metadata
            UPDATE public.appointment_purchases
            SET 
                notes = COALESCE(notes, '') || E'\nAlternative time suggested: ' || 
                    TO_CHAR(p_alternative_time, 'YYYY-MM-DD HH24:MI:SS'),
                metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
                    'alternative_time', p_alternative_time,
                    'suggestion_notes', p_provider_notes
                )
            WHERE id = p_appointment_id;
            
            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'suggest_alternative',
                'appointment_id', p_appointment_id,
                'suggested_time', p_alternative_time
            );
        ELSE
            RETURN jsonb_build_object(
                'success', FALSE,
                'error', 'Invalid action: ' || p_action
            );
        END IF;
        
    ELSE
        -- Handle legacy appointments
        IF p_action = 'confirm' THEN
            UPDATE public.appointments
            SET status = 'confirmed'
            WHERE id = p_appointment_id AND status = 'pending';
            
        ELSIF p_action = 'reject' THEN
            UPDATE public.appointments
            SET status = 'rejected'
            WHERE id = p_appointment_id AND status = 'pending';
            
        ELSIF p_action = 'suggest_alternative' AND p_alternative_time IS NOT NULL THEN
            UPDATE public.appointments
            SET 
                status = 'suggested',
                start_time = p_alternative_time,
                end_time = p_alternative_time + interval '1 hour'
            WHERE id = p_appointment_id AND status = 'pending';
        ELSE
            RETURN jsonb_build_object(
                'success', FALSE,
                'error', 'Invalid action for legacy appointment'
            );
        END IF;
        
        v_result := jsonb_build_object(
            'success', TRUE,
            'action', p_action,
            'appointment_id', p_appointment_id
        );
    END IF;
    
    RETURN v_result;
END;
$$;

-- Fix views to properly use the appointment status enum type
CREATE OR REPLACE VIEW public.pending_payment_appointments AS
SELECT 
  ap.id,
  ap.purchase_id,
  ap.service_id,
  ap.appointment_date,
  ap.duration,
  ap.method,
  ap.status,
  ap.created_at,
  ap.updated_at,
  ap.notes,
  ap.metadata,
  ap.meeting_url,
  ap.payment_link,
  p.user_id,
  p.owner_id,
  p.amount,
  p.payment_status,
  s.type as service_type,
  COALESCE(po.title, 'Service') as service_name
FROM 
  appointment_purchases ap
  JOIN purchases p ON ap.purchase_id = p.id
  JOIN services s ON ap.service_id = s.id
  LEFT JOIN posts po ON s.post_id = po.id
WHERE 
  ap.status = 'pending_payment'::appointment_status_enum
  AND ap.payment_link IS NOT NULL;

COMMENT ON VIEW public.pending_payment_appointments IS 'View to easily find appointments awaiting payment with their payment links';

-- Fix service_appointments_view to correctly use enum types
CREATE OR REPLACE VIEW "public"."service_appointments_view" AS
SELECT 
  "ap"."id" AS "appointment_id",
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
  (ap.status = 'confirmed'::appointment_status_enum) AS is_confirmed,
  (ap.status = 'completed'::appointment_status_enum) AS is_completed,
  (ap.status = 'cancelled'::appointment_status_enum) AS is_cancelled
FROM 
  "public"."appointment_purchases" "ap"
  JOIN "public"."purchases" "p" ON "ap"."purchase_id" = "p"."id"
  LEFT JOIN "public"."profiles" "cl" ON "p"."user_id" = "cl"."id";

COMMENT ON VIEW "public"."service_appointments_view" IS 'View of service appointments with client/provider details';

-- Fix auto_confirm_appointment trigger function
CREATE OR REPLACE FUNCTION public.auto_confirm_appointment()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on appointment_purchases table
DROP TRIGGER IF EXISTS trg_auto_confirm_appointment ON public.appointment_purchases;

CREATE TRIGGER trg_auto_confirm_appointment
BEFORE UPDATE OF status ON public.appointment_purchases
FOR EACH ROW
WHEN (NEW.status = 'pending_auto_payment'::appointment_status_enum)
EXECUTE FUNCTION public.auto_confirm_appointment();

COMMENT ON FUNCTION public.auto_confirm_appointment() IS 'Trigger function to automatically approve appointments when their status is set to pending_auto_payment by calling the approve_appointment_request function';