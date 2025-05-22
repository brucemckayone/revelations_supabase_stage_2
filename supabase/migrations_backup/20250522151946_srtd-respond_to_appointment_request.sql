-- Generated with srtd from template: supabase/migrations-templates/respond_to_appointment_request.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;



CREATE OR REPLACE FUNCTION "public"."respond_to_appointment_request"(
  "p_appointment_id" "uuid", 
  "p_action" "text", 
  "p_alternative_time" timestamp with time zone DEFAULT NULL::timestamp with time zone, 
  "p_provider_notes" "text" DEFAULT NULL::"text",
  "p_base_url" TEXT DEFAULT 'https://local.revelations.com'
) RETURNS "jsonb"
LANGUAGE "plpgsql" SECURITY DEFINER
AS $$
DECLARE
    v_appointment_record RECORD;
    v_provider_id UUID;
    v_user_id UUID;
    v_current_status TEXT;
    v_source TEXT;
    v_purchase_id UUID;
    v_service_id UUID;
    v_appointment_date TIMESTAMP WITH TIME ZONE;
    v_method TEXT;
    v_service_type event_type_enum;
    v_duration INTEGER;
    v_meeting_url TEXT;
    v_chat_room_id UUID;
    v_message_text TEXT;
    v_notification_metadata JSONB;
    v_confirmation_url TEXT;
    v_reschedule_url TEXT;
    v_payment_url TEXT;
    v_price NUMERIC;
    v_result JSONB;
    v_user_preference RECORD;
    v_message_success BOOLEAN;
    v_encoded_data TEXT;
BEGIN
    -- Determine which system the appointment is in
    
    -- First check appointment_purchases
    SELECT 
        ap.id, 
        ap.status, 
        ap.service_id,
        ap.appointment_date,
        ap.method,
        ap.meeting_url,
        ap.duration,
        p.owner_id AS provider_id,
        p.user_id,
        p.amount AS price,
        'appointment_purchase' AS source,
        p.id AS purchase_id,
        s.type AS service_type
    INTO v_appointment_record
    FROM 
        public.appointment_purchases ap
    JOIN 
        public.purchases p ON ap.purchase_id = p.id
    JOIN
        public.services s ON ap.service_id = s.id
    WHERE 
        ap.id = p_appointment_id;
    
    
    -- If still not found, appointment doesn't exist
    IF v_appointment_record.id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Appointment not found'
        );
    END IF;
    
    -- Store found values
    v_provider_id := v_appointment_record.provider_id;
    v_user_id := v_appointment_record.user_id;
    v_current_status := v_appointment_record.status;
    v_source := v_appointment_record.source;
    v_purchase_id := v_appointment_record.purchase_id;
    v_service_id := v_appointment_record.service_id;
    v_appointment_date := v_appointment_record.appointment_date;
    v_method := v_appointment_record.method;
    v_meeting_url := v_appointment_record.meeting_url;
    v_service_type := v_appointment_record.service_type;
    v_duration := v_appointment_record.duration;
    v_price := v_appointment_record.price;
    
    -- Generate secure token for actions
    v_encoded_data := encode(
      hmac(
        p_appointment_id::text || '_' || clock_timestamp()::text,
        current_setting('app.settings.jwt_secret'),
        'sha256'
      ),
      'hex'
    );
    
    -- Generate URLs for actions with secure tokens
    v_confirmation_url := p_base_url || '/app/appointments/confirm?id=' || p_appointment_id || '&token=' || v_encoded_data;
    v_reschedule_url := p_base_url || '/app/appointments/reschedule?id=' || p_appointment_id || '&token=' || v_encoded_data;
    
    -- Generate payment URL if needed
    IF v_price IS NOT NULL AND v_price > 0 THEN
        -- Build metadata JSON for checkout URL similar to approve_appointment_request function
        v_notification_metadata := jsonb_build_object(
            'purchase_type', 'appointment',
            'service_id', v_service_id,
            'post_id', NULL, -- We might not have this, but approve_appointment_request uses it
            'owner_id', v_provider_id,
            'user_id', v_user_id,
            'appointment_id', p_appointment_id,
            'purchase_id', v_purchase_id,
            'appointment_date', CASE WHEN p_action = 'suggest_alternative' THEN p_alternative_time ELSE v_appointment_date END,
            'duration', v_duration,
            'price', v_price
        );
        
        -- Encode data for security as in approve_appointment_request
        v_encoded_data := encode(
            convert_to(
                v_notification_metadata::text,
                'UTF8'
            ),
            'base64'
        );
        
        -- Generate checkout URL with encoded data
        v_payment_url := p_base_url || '/checkout/appointment/secure?data=' || v_encoded_data;
    END IF;
    
    -- Process the response based on source system
    IF v_source = 'appointment_purchase' THEN
        -- Handle appointment_purchases
        IF p_action = 'confirm' THEN
            IF v_current_status NOT IN ('pending_approval', 'pending_payment') THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Appointment cannot be confirmed in its current status: ' || v_current_status
                );
            END IF;
            
            -- Update to confirmed
            UPDATE public.appointment_purchases
            SET 
                status = 'confirmed',
                notes = CASE 
                    WHEN p_provider_notes IS NOT NULL THEN 
                        COALESCE(notes, '') || E'\nProvider notes: ' || p_provider_notes
                    ELSE notes
                END
            WHERE id = p_appointment_id;
            
            -- Also update purchase if needed
            IF v_current_status = 'pending_approval' THEN
                UPDATE public.purchases
                SET payment_status = 'completed'
                WHERE id = v_purchase_id;
            END IF;
            
            -- Generate meeting URL for online/hybrid services if not exists
            IF (v_method = 'video' OR v_service_type IN ('online', 'hybrid')) AND v_meeting_url IS NULL THEN
                v_meeting_url := p_base_url || '/meeting/private/' || gen_random_uuid();
                
                -- Update appointment with meeting URL
                UPDATE appointment_purchases
                SET meeting_url = v_meeting_url,
                    meeting_id = NULL -- Remove as requested
                WHERE id = p_appointment_id;
            END IF;
            
            v_message_text := 'Your appointment has been confirmed for ' || 
                            to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM');
                            
            IF v_meeting_url IS NOT NULL THEN
                v_message_text := v_message_text || E'\n\nJoin the meeting at: ' || v_meeting_url;
            END IF;
            
            IF p_provider_notes IS NOT NULL AND LENGTH(TRIM(p_provider_notes)) > 0 THEN
                v_message_text := v_message_text || E'\n\nNotes from provider: ' || p_provider_notes;
            END IF;
            
            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'confirm',
                'appointment_id', p_appointment_id,
                'status', 'confirmed'
            );
            
        ELSIF p_action = 'reject' THEN
            IF v_current_status NOT IN ('pending_approval', 'pending_payment', 'confirmed') THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Appointment cannot be rejected in its current status: ' || v_current_status
                );
            END IF;
            
            -- Update to cancelled
            UPDATE public.appointment_purchases
            SET 
                status = 'cancelled',
                notes = CASE 
                    WHEN p_provider_notes IS NOT NULL THEN 
                        COALESCE(notes, '') || E'\nRejection reason: ' || p_provider_notes
                    ELSE notes
                END
            WHERE id = p_appointment_id;
            
            -- If payment was already made, set to refunded
            IF v_current_status IN ('confirmed', 'pending_payment') THEN
                UPDATE public.purchases
                SET payment_status = 'refunded'
                WHERE id = v_purchase_id;
            END IF;
            
            v_message_text := 'Your appointment request for ' || 
                            to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM') || 
                            ' has been rejected.';
                            
            IF p_provider_notes IS NOT NULL AND LENGTH(TRIM(p_provider_notes)) > 0 THEN
                v_message_text := v_message_text || E'\n\nReason: ' || p_provider_notes;
            END IF;
            
            v_message_text := v_message_text || E'\n\nIf you would like to book another appointment, please visit our scheduling page: ' || p_base_url || '/appointments/schedule';
            
            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'reject',
                'appointment_id', p_appointment_id,
                'status', 'cancelled'
            );
            
        ELSIF p_action = 'suggest_alternative' THEN
            IF v_current_status NOT IN ('pending_approval', 'pending_payment') OR p_alternative_time IS NULL THEN
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
            
            v_message_text := 'Your appointment request for ' || 
                            to_char(v_appointment_date, 'FMDay, FMDD Month YYYY at HH12:MI AM') || 
                            ' could not be accommodated at the requested time.' || 
                            E'\n\nThe provider has suggested an alternative time: ' || 
                            to_char(p_alternative_time, 'FMDay, FMDD Month YYYY at HH12:MI AM');
                            
            IF p_provider_notes IS NOT NULL AND LENGTH(TRIM(p_provider_notes)) > 0 THEN
                v_message_text := v_message_text || E'\n\nProvider message: ' || p_provider_notes;
            END IF;
            
            -- Include action links based on whether payment is required
            IF v_price IS NOT NULL AND v_price > 0 THEN
                v_message_text := v_message_text || 
                                E'\n\nPlease choose one of the following options:' ||
                                E'\n\n1. Accept and pay for the suggested time: ' || v_payment_url || 
                                E'\n\n2. Suggest another time that works better for you: ' || v_reschedule_url;
            ELSE
                v_message_text := v_message_text || 
                                E'\n\nPlease choose one of the following options:' ||
                                E'\n\n1. Accept the suggested time: ' || v_confirmation_url || 
                                E'\n\n2. Suggest another time that works better for you: ' || v_reschedule_url;
            END IF;
            
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
        
        -- Find or create chat room for messaging
        WITH room_participants AS (
            SELECT 
                cr.id as room_id,
                COUNT(*) as participant_count,
                SUM(CASE WHEN cp.user_id IN (v_user_id, v_provider_id) THEN 1 ELSE 0 END) as target_users_count
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
            VALUES ('Appointment Chat', 'private', v_provider_id)
            RETURNING id INTO v_chat_room_id;
            
            -- Add participants with ON CONFLICT DO NOTHING
            INSERT INTO chat_participants (chat_room_id, user_id)
            VALUES 
                (v_chat_room_id, v_user_id),
                (v_chat_room_id, v_provider_id)
            ON CONFLICT (chat_room_id, user_id) DO NOTHING;
        END IF;
        
        -- Prepare notification metadata
        v_notification_metadata := jsonb_build_object(
            'appointment_id', p_appointment_id,
            'purchase_id', v_purchase_id,
            'service_id', v_service_id,
            'status', CASE 
                WHEN p_action = 'confirm' THEN 'confirmed'
                WHEN p_action = 'reject' THEN 'cancelled'
                WHEN p_action = 'suggest_alternative' THEN 'pending_reschedule'
                ELSE v_current_status
            END,
            'appointment_date', v_appointment_date,
            'service_type', v_service_type,
            'method', v_method,
            'action', p_action,
            'price', v_price
        );
        
        -- Add meeting URL to metadata if it exists
        IF v_meeting_url IS NOT NULL THEN
            v_notification_metadata := v_notification_metadata || jsonb_build_object('meeting_url', v_meeting_url);
        END IF;
        
        -- Add alternative time to metadata if provided
        IF p_alternative_time IS NOT NULL THEN
            v_notification_metadata := v_notification_metadata || jsonb_build_object('alternative_time', p_alternative_time);
        END IF;
        
        -- Add action URLs to metadata
        IF p_action = 'suggest_alternative' THEN
            v_notification_metadata := v_notification_metadata || jsonb_build_object(
                'confirmation_url', COALESCE(v_payment_url, v_confirmation_url),
                'reschedule_url', v_reschedule_url
            );
        END IF;
        
        -- Send message in chat
        BEGIN
            INSERT INTO chat_messages (
                chat_room_id,
                sender_id,
                message,
                status
            ) VALUES (
                v_chat_room_id,
                v_provider_id,
                v_message_text,
                'delivered'
            );
            v_message_success := TRUE;
        EXCEPTION WHEN OTHERS THEN
            -- If chat message fails, fall back to notifications
            v_message_success := FALSE;
            
            BEGIN
                -- Check user notification preferences for appointments
                SELECT * INTO v_user_preference 
                FROM notification_preferences 
                WHERE user_id = v_user_id AND type = 'appointment';
                
                -- If no specific preference, use default (all enabled)
                IF NOT FOUND THEN
                    v_user_preference := ROW(NULL, v_user_id, 'appointment', TRUE, TRUE, TRUE, FALSE)::notification_preferences;
                END IF;
                
                -- Notify client (user) based on preferences
                IF v_user_preference.in_app THEN
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
                        CASE 
                            WHEN p_action = 'confirm' THEN 'Appointment Confirmed'
                            WHEN p_action = 'reject' THEN 'Appointment Rejected'
                            WHEN p_action = 'suggest_alternative' THEN 'Alternative Appointment Time Suggested'
                        END,
                        v_message_text,
                        'appointment',
                        CASE 
                            WHEN p_action = 'suggest_alternative' THEN COALESCE(v_payment_url, v_confirmation_url)
                            ELSE '/appointments/' || p_appointment_id
                        END,
                        p_appointment_id,
                        'appointment',
                        v_notification_metadata
                    );
                END IF;
                
                -- Trigger email notifications based on preferences
                IF v_user_preference.email THEN
                    PERFORM pg_notify('email_notification', 
                        jsonb_build_object(
                            'recipient_id', v_user_id,
                            'type', 'appointment_' || p_action,
                            'data', v_notification_metadata
                        )::text
                    );
                END IF;
                
                -- Trigger push notifications based on preferences
                IF v_user_preference.push THEN
                    PERFORM pg_notify('push_notification', 
                        jsonb_build_object(
                            'recipient_id', v_user_id,
                            'title', CASE 
                                WHEN p_action = 'confirm' THEN 'Appointment Confirmed'
                                WHEN p_action = 'reject' THEN 'Appointment Rejected'
                                WHEN p_action = 'suggest_alternative' THEN 'New Time Suggested'
                            END,
                            'body', CASE 
                                WHEN p_action = 'confirm' THEN 'Your appointment has been confirmed'
                                WHEN p_action = 'reject' THEN 'Your appointment request was rejected'
                                WHEN p_action = 'suggest_alternative' THEN 'An alternative time has been suggested for your appointment'
                            END,
                            'data', v_notification_metadata
                        )::text
                    );
                END IF;
                
                -- Trigger SMS notifications based on preferences
                IF v_user_preference.sms THEN
                    PERFORM pg_notify('sms_notification', 
                        jsonb_build_object(
                            'recipient_id', v_user_id,
                            'message', CASE 
                                WHEN p_action = 'confirm' THEN 'Your appointment on ' || to_char(v_appointment_date, 'DD MMM') || ' has been confirmed'
                                WHEN p_action = 'reject' THEN 'Your appointment request for ' || to_char(v_appointment_date, 'DD MMM') || ' has been rejected'
                                WHEN p_action = 'suggest_alternative' THEN 'Alternative time suggested for your appointment: ' || to_char(p_alternative_time, 'DD MMM, HH12:MI AM') || 
                                    '. Please check your email or app for action links.'
                            END,
                            'data', v_notification_metadata
                        )::text
                    );
                END IF;
            EXCEPTION WHEN OTHERS THEN
                -- Just continue if this fails too
                NULL;
            END;
        END;
        
        -- Add notification details to result
        v_result := v_result || jsonb_build_object(
            'message_sent', v_message_success,
            'chat_room_id', v_chat_room_id
        );
        
        -- Add URLs to result
        IF p_action = 'suggest_alternative' THEN
            v_result := v_result || jsonb_build_object(
                'confirmation_url', COALESCE(v_payment_url, v_confirmation_url),
                'reschedule_url', v_reschedule_url
            );
        END IF;
        
        -- Add meeting URL to result if applicable
        IF v_meeting_url IS NOT NULL AND p_action = 'confirm' THEN
            v_result := v_result || jsonb_build_object('meeting_url', v_meeting_url);
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
    
    -- Trigger system notification for appointment status change
    PERFORM pg_notify('appointment_' || p_action, v_result::text);
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION "public"."respond_to_appointment_request"("uuid", "text", timestamp with time zone, "text", "text") IS 'Responds to an appointment request with confirmation, rejection, or alternative time suggestion, including actionable links for payment or rescheduling'; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
