-- Migration: Appointment notification system
-- Creates functions to handle appointment request notifications and status updates

-- Function to handle initial appointment request
CREATE OR REPLACE FUNCTION handle_appointment_request(
  p_service_id UUID,
  p_user_id UUID,
  p_owner_id UUID,
  p_post_id UUID,
  p_appointment_date TIMESTAMP WITH TIME ZONE,
  p_duration INTEGER,
  p_method TEXT DEFAULT 'video',
  p_message TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
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

-- Function to approve appointment request and generate payment link
CREATE OR REPLACE FUNCTION approve_appointment_request(
  p_appointment_id UUID,
  p_price NUMERIC,
  p_message TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
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
BEGIN
  -- Get appointment details
  SELECT 
    ap.purchase_id, 
    p.user_id, 
    p.owner_id, 
    ap.service_id, 
    p.post_id,
    ap.appointment_date,
    ap.duration
  INTO 
    v_purchase_id, 
    v_user_id, 
    v_owner_id, 
    v_service_id, 
    v_post_id,
    v_appointment_date,
    v_duration
  FROM 
    appointment_purchases ap
    JOIN purchases p ON ap.purchase_id = p.id
  WHERE 
    ap.id = p_appointment_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Appointment not found');
  END IF;
  
  -- Update appointment status
  UPDATE appointment_purchases
  SET status = 'pending_payment',
      updated_at = NOW()
  WHERE id = p_appointment_id;
  
  -- Update purchase with price
  UPDATE purchases
  SET amount = p_price,
      payment_status = 'pending_payment',
      updated_at = NOW()
  WHERE id = v_purchase_id;
  
  -- Insert into chat system - Send approval notification with payment link
  INSERT INTO messages (
    sender_id,
    recipient_id,
    content,
    message_type,
    metadata
  ) VALUES (
    v_owner_id,
    v_user_id,
    COALESCE(p_message, 'Your appointment request has been approved. Please complete payment to confirm.'),
    'appointment_approved',
    jsonb_build_object(
      'appointment_id', p_appointment_id,
      'purchase_id', v_purchase_id,
      'service_id', v_service_id,
      'appointment_date', v_appointment_date,
      'duration', v_duration,
      'price', p_price,
      'status', 'pending_payment',
      'payment_required', true
    )
  );
  
  -- Build result with payment metadata
  v_result := jsonb_build_object(
    'purchase_id', v_purchase_id,
    'appointment_id', p_appointment_id,
    'user_id', v_user_id,
    'owner_id', v_owner_id,
    'service_id', v_service_id,
    'post_id', v_post_id,
    'appointment_date', v_appointment_date,
    'duration', v_duration,
    'price', p_price,
    'status', 'pending_payment'
  );
  
  -- Trigger email notification (in future implementation)
  PERFORM pg_notify('appointment_approved', v_result::text);
  
  RETURN v_result;
END;
$$;

-- Function to reschedule an appointment request
CREATE OR REPLACE FUNCTION reschedule_appointment_request(
  p_appointment_id UUID,
  p_new_date TIMESTAMP WITH TIME ZONE,
  p_duration INTEGER DEFAULT NULL,
  p_message TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_purchase_id UUID;
  v_user_id UUID;
  v_owner_id UUID;
  v_service_id UUID;
  v_old_date TIMESTAMP WITH TIME ZONE;
  v_duration INTEGER;
  v_result JSONB;
BEGIN
  -- Get appointment details
  SELECT 
    ap.purchase_id, 
    p.user_id, 
    p.owner_id, 
    ap.service_id,
    ap.appointment_date,
    ap.duration
  INTO 
    v_purchase_id, 
    v_user_id, 
    v_owner_id, 
    v_service_id,
    v_old_date,
    v_duration
  FROM 
    appointment_purchases ap
    JOIN purchases p ON ap.purchase_id = p.id
  WHERE 
    ap.id = p_appointment_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Appointment not found');
  END IF;
  
  -- Use provided duration or keep existing
  v_duration := COALESCE(p_duration, v_duration);
  
  -- Update appointment date
  UPDATE appointment_purchases
  SET appointment_date = p_new_date,
      duration = v_duration,
      status = 'rescheduled',
      updated_at = NOW()
  WHERE id = p_appointment_id;
  
  -- Update purchase dates
  UPDATE purchases
  SET start_date = p_new_date,
      end_date = p_new_date + (v_duration || ' minutes')::interval,
      updated_at = NOW()
  WHERE id = v_purchase_id;
  
  -- Insert into chat system - Send reschedule notification
  INSERT INTO messages (
    sender_id,
    recipient_id,
    content,
    message_type,
    metadata
  ) VALUES (
    v_owner_id,
    v_user_id,
    COALESCE(p_message, 'Your appointment has been rescheduled.'),
    'appointment_rescheduled',
    jsonb_build_object(
      'appointment_id', p_appointment_id,
      'purchase_id', v_purchase_id,
      'service_id', v_service_id,
      'old_date', v_old_date,
      'new_date', p_new_date,
      'duration', v_duration,
      'status', 'rescheduled'
    )
  );
  
  -- Build result
  v_result := jsonb_build_object(
    'purchase_id', v_purchase_id,
    'appointment_id', p_appointment_id,
    'user_id', v_user_id,
    'owner_id', v_owner_id,
    'old_date', v_old_date,
    'new_date', p_new_date,
    'duration', v_duration,
    'status', 'rescheduled'
  );
  
  -- Trigger email notification (in future implementation)
  PERFORM pg_notify('appointment_rescheduled', v_result::text);
  
  RETURN v_result;
END;
$$;

-- Modify the existing processAppointmentBooking function to update chat
CREATE OR REPLACE FUNCTION process_appointment_payment_confirmation(
  p_purchase_id UUID,
  p_payment_intent_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_owner_id UUID;
  v_appointment_id UUID;
  v_appointment_date TIMESTAMP WITH TIME ZONE;
  v_result JSONB;
BEGIN
  -- Update purchase status
  UPDATE purchases
  SET payment_status = 'completed',
      completed_at = NOW(),
      updated_at = NOW(),
      stripe_payment_intent_id = p_payment_intent_id
  WHERE id = p_purchase_id
  RETURNING user_id, owner_id INTO v_user_id, v_owner_id;
  
  -- Update appointment status
  UPDATE appointment_purchases
  SET status = 'confirmed',
      updated_at = NOW()
  WHERE purchase_id = p_purchase_id
  RETURNING id, appointment_date INTO v_appointment_id, v_appointment_date;
  
  -- Insert into chat system - Send confirmation notification
  INSERT INTO messages (
    sender_id,
    recipient_id,
    content,
    message_type,
    metadata
  ) VALUES (
    v_user_id,
    v_owner_id,
    'Payment completed for appointment on ' || v_appointment_date,
    'appointment_confirmed',
    jsonb_build_object(
      'appointment_id', v_appointment_id,
      'purchase_id', p_purchase_id,
      'status', 'confirmed',
      'appointment_date', v_appointment_date
    )
  );
  
  -- Also notify the user
  INSERT INTO messages (
    sender_id,
    recipient_id,
    content,
    message_type,
    metadata
  ) VALUES (
    v_owner_id,
    v_user_id,
    'Your appointment has been confirmed for ' || v_appointment_date,
    'appointment_confirmed',
    jsonb_build_object(
      'appointment_id', v_appointment_id,
      'purchase_id', p_purchase_id,
      'status', 'confirmed',
      'appointment_date', v_appointment_date
    )
  );
  
  -- Build result
  v_result := jsonb_build_object(
    'purchase_id', p_purchase_id,
    'appointment_id', v_appointment_id,
    'status', 'confirmed'
  );
  
  -- Trigger email notification (in future implementation)
  PERFORM pg_notify('appointment_confirmed', v_result::text);
  
  RETURN v_result;
END;
$$;

-- Add trigger for email notifications via pg_notify
CREATE OR REPLACE FUNCTION notify_appointment_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
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

-- Create trigger on appointment_purchases
DROP TRIGGER IF EXISTS appointment_status_change_trigger ON appointment_purchases;
CREATE TRIGGER appointment_status_change_trigger
AFTER INSERT OR UPDATE OF status
ON appointment_purchases
FOR EACH ROW
EXECUTE FUNCTION notify_appointment_status_change();

-- Add comments
COMMENT ON FUNCTION handle_appointment_request IS 'Creates a new appointment request and notifies the provider via chat';
COMMENT ON FUNCTION approve_appointment_request IS 'Approves an appointment request and generates payment info for the user';
COMMENT ON FUNCTION reschedule_appointment_request IS 'Reschedules an appointment and notifies the user';
COMMENT ON FUNCTION process_appointment_payment_confirmation IS 'Processes payment confirmation and updates appointment status';
COMMENT ON FUNCTION notify_appointment_status_change IS 'Notifies external systems of appointment status changes for email processing'; 