-- Migration to fix appointment functions by using TEXT types in signatures and casting internally
-- This ensures the functions can be created even if enum types are created later

-- Drop existing functions with enum types in signatures
DROP FUNCTION IF EXISTS public.request_service_appointment(uuid, timestamp with time zone, integer, appointment_method_enum, appointment_type_enum, text, uuid);
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(uuid, text, timestamp with time zone, text, text);
DROP FUNCTION IF EXISTS public.process_appointment_payment(uuid, text, uuid, timestamp with time zone, integer, text, appointment_method_enum, text);

-- Recreate request_service_appointment with TEXT parameters
CREATE OR REPLACE FUNCTION "public"."request_service_appointment"(
    "p_service_id" uuid,
    "p_requested_date" timestamp with time zone,
    "p_duration" integer DEFAULT NULL::integer,
    "p_method" text DEFAULT 'video'::text,
    "p_service_type" text DEFAULT 'consultation'::text,
    "p_notes" text DEFAULT NULL::text,
    "p_client_id" uuid DEFAULT NULL::uuid
) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
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

COMMENT ON FUNCTION "public"."request_service_appointment"(uuid, timestamp with time zone, integer, text, text, text, uuid) IS 'Creates a new appointment request with initial status based on service booking workflow; supports direct booking, pre-approval, or waitlist workflows';

-- Recreate respond_to_appointment_request with TEXT parameters
CREATE OR REPLACE FUNCTION "public"."respond_to_appointment_request"(
    "p_appointment_id" uuid,
    "p_action" text,
    "p_alternative_time" timestamp with time zone DEFAULT NULL::timestamp with time zone,
    "p_provider_notes" text DEFAULT NULL::text,
    "p_base_url" text DEFAULT '/checkout/appointment'::text
) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
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

COMMENT ON FUNCTION "public"."respond_to_appointment_request"(uuid, text, timestamp with time zone, text, text) IS 'Allows providers to confirm, reject, or suggest alternative times for appointment requests';

-- Recreate process_appointment_payment with correct enum parameters
CREATE OR REPLACE FUNCTION "public"."process_appointment_payment"(
    "p_purchase_id" uuid,
    "p_payment_intent_id" text,
    "p_service_id" uuid,
    "p_appointment_date" timestamp with time zone,
    "p_duration" integer DEFAULT 60,
    "p_method" text DEFAULT 'video'::text,
    "p_service_type" text DEFAULT 'consultation'::text,
    "p_notes" text DEFAULT NULL::text
) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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

COMMENT ON FUNCTION "public"."process_appointment_payment"(uuid, text, uuid, timestamp with time zone, integer, text, text, text) IS 'Processes payment for an appointment, creating or updating the appointment record'; 