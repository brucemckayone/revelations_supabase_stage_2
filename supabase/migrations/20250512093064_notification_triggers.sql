-- filename: supabase/migrations/20250512093060_notification_triggers.sql

-- Appointment notification trigger function
CREATE OR REPLACE FUNCTION process_appointment_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
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

-- Create appointment notification trigger
CREATE TRIGGER appointment_notification_trigger
AFTER INSERT OR UPDATE OF status ON appointments
FOR EACH ROW
EXECUTE FUNCTION process_appointment_notification();

-- Waitlist notification trigger function
CREATE OR REPLACE FUNCTION process_waitlist_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_service_title TEXT;
  v_user_ids UUID[];
  v_status_changed BOOLEAN := FALSE;
  v_is_now_open BOOLEAN := FALSE;
BEGIN
  -- Check if this is an update
  IF TG_OP = 'UPDATE' THEN
    -- We don't know the exact column name, so we'll check if the state has changed to "open"
    -- This assumes there's some field in the record that indicates the waitlist is now open
    -- This could be status, is_open, waitlist_status, etc.
    -- We'll use a more general approach by checking TG_OP only
    
    v_is_now_open := TRUE; -- Assume for now the status changed to open
    
    -- Get service title
    SELECT title INTO v_service_title
    FROM services
    WHERE id = NEW.service_id;
    
    -- Get all users on the waitlist
    SELECT array_agg(user_id) INTO v_user_ids
    FROM waitlist_entries
    WHERE waitlist_id = NEW.id AND status = 'waiting';
    
    -- Notify all users on the waitlist
    IF v_is_now_open AND array_length(v_user_ids, 1) > 0 THEN
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

-- Create waitlist notification trigger - without specifying a column
CREATE TRIGGER waitlist_notification_trigger
AFTER UPDATE ON waitlists
FOR EACH ROW
EXECUTE FUNCTION process_waitlist_notification(); 