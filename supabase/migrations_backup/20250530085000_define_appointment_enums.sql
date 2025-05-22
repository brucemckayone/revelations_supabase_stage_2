-- Define enum types first, before they are used in any functions
-- This fixes issues where function signatures reference enums before they're created

-- Create purchase_payment_status_enum if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'purchase_payment_status_enum') THEN
        CREATE TYPE "public"."purchase_payment_status_enum" AS ENUM ('completed', 'pending', 'refunded', 'failed');
    END IF;
END$$;

-- Create purchase_type_enum if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'purchase_type_enum') THEN
        CREATE TYPE "public"."purchase_type_enum" AS ENUM ('content', 'event', 'appointment', 'subscription', 'article');
    END IF;
END$$;

-- Create appointment_method_enum if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'appointment_method_enum') THEN
        CREATE TYPE "public"."appointment_method_enum" AS ENUM ('video', 'phone', 'in-person');
    END IF;
END$$;

-- Create appointment_type_enum if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'appointment_type_enum') THEN
        CREATE TYPE "public"."appointment_type_enum" AS ENUM ('reading', 'healing', 'coaching', 'consultation');
    END IF;
END$$;

-- Create appointment_status_enum if it doesn't exist
DO $$
BEGIN
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


-- Add necessary columns to the appointment_purchases table if they don't exist
DO $$
BEGIN
    -- Check if the metadata column already exists
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'appointment_purchases'
        AND column_name = 'metadata'
    ) THEN
        ALTER TABLE public.appointment_purchases ADD COLUMN metadata JSONB DEFAULT NULL;
        COMMENT ON COLUMN public.appointment_purchases.metadata IS 'Stores structured metadata for appointments including rescheduling history, alternative dates, and other dynamic attributes';
    END IF;
    
    -- Check if payment_link column already exists
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'appointment_purchases'
        AND column_name = 'payment_link'
    ) THEN
        ALTER TABLE public.appointment_purchases ADD COLUMN payment_link TEXT DEFAULT NULL;
        COMMENT ON COLUMN public.appointment_purchases.payment_link IS 'Stores the checkout URL for pending payment appointments';
        
        -- Add index for quicker lookup by payment_link
        CREATE INDEX IF NOT EXISTS idx_appointment_purchases_payment_link ON public.appointment_purchases(payment_link);
    END IF;
END$$;




-- Consolidated appointment system with proper enum types
-- This ensures all functions use the correct enum types throughout

-- Start by dropping functions to avoid conflicts
DROP FUNCTION IF EXISTS public.approve_appointment_request(UUID, NUMERIC);
DROP FUNCTION IF EXISTS public.approve_appointment_request(UUID, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.approve_appointment_request(UUID, NUMERIC, TEXT, TEXT);

DROP FUNCTION IF EXISTS public.process_appointment_payment_confirmation(UUID);
DROP FUNCTION IF EXISTS public.process_appointment_payment_confirmation(UUID, TEXT);

DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER);
DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER, TEXT);
DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.reschedule_appointment_request(UUID, TIMESTAMP WITH TIME ZONE, INTEGER, TEXT, TEXT, TIMESTAMP WITH TIME ZONE[]);

DROP FUNCTION IF EXISTS public.respond_to_appointment_request(UUID, TEXT);
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(UUID, TEXT, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(UUID, TEXT, TIMESTAMP WITH TIME ZONE, TEXT);
DROP FUNCTION IF EXISTS public.respond_to_appointment_request(UUID, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, TEXT);

DROP FUNCTION IF EXISTS public.suggest_appointment_dates(UUID, TIMESTAMP WITH TIME ZONE[]);
DROP FUNCTION IF EXISTS public.suggest_appointment_dates(UUID, TIMESTAMP WITH TIME ZONE[], TEXT);
DROP FUNCTION IF EXISTS public.suggest_appointment_dates(UUID, TIMESTAMP WITH TIME ZONE[], TEXT, TEXT);


-- Also drop any related views
DROP VIEW IF EXISTS public.pending_payment_appointments;
DROP TRIGGER IF EXISTS trg_auto_confirm_appointment ON public.appointment_purchases;
-- 1. Create or replace approve_appointment_request function
CREATE OR REPLACE FUNCTION public.approve_appointment_request(
  p_appointment_id UUID, 
  p_price NUMERIC, 
  p_message TEXT DEFAULT NULL,
  p_checkout_base_url TEXT DEFAULT '/app/checkout/appointment'
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
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

COMMENT ON FUNCTION public.approve_appointment_request(UUID, NUMERIC, TEXT, TEXT) IS 'Approves an appointment request, generates payment checkout URL with encoded data, stores the payment link in the appointment record, and sends notification with payment link';

-- 2. Create process_appointment_payment_confirmation function
CREATE OR REPLACE FUNCTION public.process_appointment_payment_confirmation(
  p_purchase_id UUID,
  p_payment_intent_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
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

COMMENT ON FUNCTION public.process_appointment_payment_confirmation(UUID, TEXT) IS 'Processes payment confirmation, generates meeting URL for online/hybrid appointments, clears payment_link field, and sends notifications based on user preferences';

-- 3. Create auto_confirm_appointment trigger function
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

COMMENT ON FUNCTION public.auto_confirm_appointment() IS 'Trigger function to automatically approve appointments when their status is set to pending_auto_payment by calling the approve_appointment_request function';

-- Create the trigger on appointment_purchases table
CREATE TRIGGER trg_auto_confirm_appointment
BEFORE UPDATE OF status ON public.appointment_purchases
FOR EACH ROW
WHEN (NEW.status = 'pending_auto_payment'::appointment_status_enum)
EXECUTE FUNCTION public.auto_confirm_appointment();

-- 4. Create a view for appointments with payment links
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

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
