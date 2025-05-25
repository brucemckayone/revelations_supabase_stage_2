-- =============================================================================
-- NOTIFICATION SYSTEM REFACTOR - TRIGGER-BASED APPROACH
-- =============================================================================
-- This template refactors the notification system to use triggers exclusively
-- for appointment-related notifications, making it more maintainable and consistent.

-- =============================================================================
-- 1. DROP EXISTING TRIGGERS AND FUNCTIONS FOR CLEAN STATE
-- =============================================================================

-- Drop existing notification triggers
DROP TRIGGER IF EXISTS appointment_status_change_trigger ON public.appointment_purchases;
DROP TRIGGER IF EXISTS appointment_notifications_trigger ON public.appointment_purchases;
DROP TRIGGER IF EXISTS appointment_reminders_trigger ON public.appointment_purchases;

-- Drop existing functions
DROP FUNCTION IF EXISTS public.handle_appointment_notifications;
DROP FUNCTION IF EXISTS public.handle_appointment_reminders;
DROP FUNCTION IF EXISTS public.notify_appointment_status_change;


-- =============================================================================
-- 2. CREATE ENHANCED NOTIFICATION TRIGGER FUNCTION
-- =============================================================================

CREATE FUNCTION public.handle_appointment_notifications()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_purchase_record RECORD;
  v_service_record RECORD;
  v_post_record RECORD;
  v_provider_profile RECORD;
  v_client_profile RECORD;
  v_notification_title TEXT;
  v_notification_content TEXT;
  v_action_url TEXT;
  v_metadata JSONB;
  v_appointment_date_formatted TEXT;
BEGIN
  -- Get related records for context
  SELECT 
    p.*,
    COALESCE(pr_client.full_name, 'Unknown Client') as client_name,
    COALESCE(pr_client.username, 'unknown') as client_username,
    COALESCE(pr_provider.full_name, 'Unknown Provider') as provider_name,
    COALESCE(pr_provider.username, 'unknown') as provider_username
  INTO v_purchase_record
  FROM purchases p
  LEFT JOIN profiles pr_client ON p.user_id = pr_client.id
  LEFT JOIN profiles pr_provider ON p.owner_id = pr_provider.id
  WHERE p.id = NEW.purchase_id;
  
  -- Get service details
  SELECT 
    s.*, 
    COALESCE(posts.title, 'Unknown Service') as service_title, 
    COALESCE(posts.description, '') as service_description
  INTO v_service_record
  FROM services s
  LEFT JOIN posts ON s.post_id = posts.id
  WHERE s.id = NEW.service_id;
  
  -- Format appointment date
  v_appointment_date_formatted := COALESCE(
    to_char(NEW.appointment_date, 'DD Mon YYYY at HH12:MI AM'),
    'Unknown Date'
  );
  
  -- Build base metadata
  v_metadata := jsonb_build_object(
    'appointment_id', NEW.id,
    'purchase_id', NEW.purchase_id,
    'service_id', NEW.service_id,
    'appointment_date', NEW.appointment_date,
    'old_status', CASE WHEN TG_OP = 'UPDATE' THEN OLD.status ELSE NULL END,
    'new_status', NEW.status,
    'service_title', COALESCE(v_service_record.service_title, 'Unknown Service'),
    'provider_name', COALESCE(v_purchase_record.provider_name, 'Unknown Provider'),
    'client_name', COALESCE(v_purchase_record.client_name, 'Unknown Client')
  );

  -- =============================================================================
  -- HANDLE DIFFERENT APPOINTMENT STATUS CHANGES
  -- =============================================================================
  
  IF TG_OP = 'INSERT' THEN
    -- New appointment created
    CASE NEW.status
      WHEN 'pending_approval' THEN
        -- Notify provider of new appointment request
        PERFORM create_notification(
          v_purchase_record.owner_id,                    -- provider user_id
          v_purchase_record.user_id,                     -- client sender_id  
          'New Appointment Request',                     -- title
          COALESCE(v_purchase_record.client_name, 'A client') || ' has requested a ' || 
          COALESCE(v_service_record.service_title, 'service') || ' appointment for ' || 
          v_appointment_date_formatted,                  -- content
          'appointment',                                 -- type
          NULL,                                          -- priority (ignored)
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
        -- Notify client of request submission
        PERFORM create_notification(
          v_purchase_record.user_id,                     -- client user_id
          NULL,                                          -- system sender
          'Appointment Request Submitted',               -- title
          'Your appointment request for ' || COALESCE(v_service_record.service_title, 'a service') || 
          ' on ' || v_appointment_date_formatted || ' has been submitted and is pending approval.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
      WHEN 'pending_auto_payment', 'pending_payment' THEN
        -- Notify client that payment is required
        v_action_url := COALESCE(NEW.payment_link, '/dashboard/appointments/' || NEW.id);
        
        PERFORM create_notification(
          v_purchase_record.user_id,                     -- client user_id
          v_purchase_record.owner_id,                    -- provider sender_id
          'Appointment Approved - Payment Required',     -- title
          'Your appointment with ' || COALESCE(v_purchase_record.provider_name, 'a provider') || 
          ' for ' || v_appointment_date_formatted || ' has been approved. Please complete payment to confirm.',
          'payment',                                     -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          v_action_url,                                  -- action_url
          v_metadata || jsonb_build_object('payment_link', NEW.payment_link)
        );
        
      WHEN 'confirmed' THEN
        -- Notify both parties of confirmation
        PERFORM create_notification(
          v_purchase_record.user_id,                     -- client user_id
          v_purchase_record.owner_id,                    -- provider sender_id
          'Appointment Confirmed',                       -- title
          'Your appointment with ' || COALESCE(v_purchase_record.provider_name, 'a provider') || 
          ' for ' || v_appointment_date_formatted || ' is confirmed.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
        PERFORM create_notification(
          v_purchase_record.owner_id,                    -- provider user_id
          v_purchase_record.user_id,                     -- client sender_id
          'Appointment Confirmed',                       -- title
          'Your appointment with ' || COALESCE(v_purchase_record.client_name, 'a client') || 
          ' for ' || v_appointment_date_formatted || ' is confirmed.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
      ELSE
        -- Handle other initial statuses if needed
        NULL;
    END CASE;
    
  ELSIF TG_OP = 'UPDATE' AND NEW.status != OLD.status THEN
    -- Handle status changes
    CASE NEW.status
      WHEN 'pending_payment', 'pending_auto_payment' THEN
        -- Only notify if not already handled in INSERT
        IF OLD.status != 'pending_approval' THEN
          v_action_url := COALESCE(NEW.payment_link, '/dashboard/appointments/' || NEW.id);
          
          PERFORM create_notification(
            v_purchase_record.user_id,                   -- client user_id
            v_purchase_record.owner_id,                  -- provider sender_id
            'Payment Required',                          -- title
            'Payment is required for your appointment on ' || v_appointment_date_formatted,
            'payment',                                   -- type
            NULL,                                        -- priority
            NEW.id,                                      -- reference_id
            v_action_url,                                -- action_url
            v_metadata || jsonb_build_object('payment_link', NEW.payment_link)
          );
        END IF;
        
      WHEN 'confirmed' THEN
        -- Confirmation notifications (both parties)
        PERFORM create_notification(
          v_purchase_record.user_id,                     -- client user_id
          v_purchase_record.owner_id,                    -- provider sender_id
          'Appointment Confirmed',                       -- title
          'Your appointment for ' || v_appointment_date_formatted || ' is confirmed.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
        PERFORM create_notification(
          v_purchase_record.owner_id,                    -- provider user_id
          v_purchase_record.user_id,                     -- client sender_id
          'Appointment Confirmed',                       -- title
          'Your appointment with ' || COALESCE(v_purchase_record.client_name, 'a client') || 
          ' for ' || v_appointment_date_formatted || ' is confirmed.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
      WHEN 'cancelled' THEN
        -- Cancellation notifications
        PERFORM create_notification(
          v_purchase_record.user_id,                     -- client user_id
          v_purchase_record.owner_id,                    -- provider sender_id
          'Appointment Cancelled',                       -- title
          'Your appointment for ' || v_appointment_date_formatted || ' has been cancelled.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
        PERFORM create_notification(
          v_purchase_record.owner_id,                    -- provider user_id
          v_purchase_record.user_id,                     -- client sender_id
          'Appointment Cancelled',                       -- title
          'Appointment with ' || COALESCE(v_purchase_record.client_name, 'a client') || 
          ' for ' || v_appointment_date_formatted || ' has been cancelled.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
      WHEN 'completed' THEN
        -- Completion notifications
        PERFORM create_notification(
          v_purchase_record.user_id,                     -- client user_id
          v_purchase_record.owner_id,                    -- provider sender_id
          'Appointment Completed',                       -- title
          'Your appointment for ' || v_appointment_date_formatted || ' has been completed.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
        PERFORM create_notification(
          v_purchase_record.owner_id,                    -- provider user_id
          v_purchase_record.user_id,                     -- client sender_id
          'Appointment Completed',                       -- title
          'Appointment with ' || COALESCE(v_purchase_record.client_name, 'a client') || 
          ' for ' || v_appointment_date_formatted || ' has been completed.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
      WHEN 'no_show' THEN
        -- No-show notifications
        PERFORM create_notification(
          v_purchase_record.user_id,                     -- client user_id
          v_purchase_record.owner_id,                    -- provider sender_id
          'Appointment No-Show',                         -- title
          'You were marked as no-show for your appointment on ' || v_appointment_date_formatted,
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
        PERFORM create_notification(
          v_purchase_record.owner_id,                    -- provider user_id
          v_purchase_record.user_id,                     -- client sender_id
          'Appointment No-Show',                         -- title
          COALESCE(v_purchase_record.client_name, 'Client') || ' was a no-show for appointment on ' || 
          v_appointment_date_formatted,
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
      WHEN 'rescheduled', 'pending_reschedule' THEN
        -- Reschedule notifications
        PERFORM create_notification(
          v_purchase_record.user_id,                     -- client user_id
          v_purchase_record.owner_id,                    -- provider sender_id
          'Appointment Rescheduled',                     -- title
          'Your appointment has been rescheduled. Please check the new details.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
        PERFORM create_notification(
          v_purchase_record.owner_id,                    -- provider user_id
          v_purchase_record.user_id,                     -- client sender_id
          'Appointment Rescheduled',                     -- title
          'Appointment with ' || COALESCE(v_purchase_record.client_name, 'a client') || 
          ' has been rescheduled.',
          'appointment',                                 -- type
          NULL,                                          -- priority
          NEW.id,                                        -- reference_id
          '/dashboard/appointments/' || NEW.id,          -- action_url
          v_metadata                                     -- metadata
        );
        
      ELSE
        -- Log unhandled status changes for debugging
        RAISE NOTICE 'Unhandled appointment status change: % -> %', 
                     COALESCE(OLD.status::text, 'NULL'), NEW.status::text;
    END CASE;
  END IF;

  -- Send external notification via PostgreSQL NOTIFY for real-time updates
  PERFORM pg_notify(
    'appointment_status_change',
    json_build_object(
      'appointment_id', NEW.id,
      'old_status', CASE WHEN TG_OP = 'UPDATE' THEN OLD.status ELSE NULL END,
      'new_status', NEW.status,
      'user_id', v_purchase_record.user_id,
      'provider_id', v_purchase_record.owner_id,
      'appointment_date', NEW.appointment_date,
      'trigger_operation', TG_OP
    )::text
  );

  RETURN NEW;
END;
$$;

-- =============================================================================
-- 3. CREATE APPOINTMENT REMINDER SYSTEM
-- =============================================================================

CREATE FUNCTION public.handle_appointment_reminders()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  
AS $$
DECLARE
  v_purchase_record RECORD;
  v_service_record RECORD;
  v_appointment_date_formatted TEXT;
  v_metadata JSONB;
  v_hours_until_appointment INTEGER;
BEGIN
  -- Only process for confirmed appointments with date changes
  IF NEW.status != 'confirmed' OR 
     (TG_OP = 'UPDATE' AND NEW.appointment_date = OLD.appointment_date) THEN
    RETURN NEW;
  END IF;
  
  -- Get related records
  SELECT 
    p.*,
    pr_client.full_name as client_name,
    pr_provider.full_name as provider_name
  INTO v_purchase_record
  FROM purchases p
  LEFT JOIN profiles pr_client ON p.user_id = pr_client.id
  LEFT JOIN profiles pr_provider ON p.owner_id = pr_provider.id
  WHERE p.id = NEW.purchase_id;
  
  SELECT s.*, posts.title as service_title
  INTO v_service_record
  FROM services s
  LEFT JOIN posts ON s.post_id = posts.id
  WHERE s.id = NEW.service_id;
  
  v_appointment_date_formatted := to_char(NEW.appointment_date, 'DD Mon YYYY at HH12:MI AM');
  v_hours_until_appointment := EXTRACT(EPOCH FROM (NEW.appointment_date - NOW())) / 3600;
  
  v_metadata := jsonb_build_object(
    'appointment_id', NEW.id,
    'appointment_date', NEW.appointment_date,
    'service_title', v_service_record.service_title,
    'reminder_type', 'appointment_scheduled'
  );
  
  -- Schedule reminders based on appointment timing
  IF v_hours_until_appointment > 24 THEN
    -- 24-hour reminder
    INSERT INTO notifications (
      user_id, sender_id, title, content, type, action_url, reference_id, reference_type, metadata,
      created_at
    ) VALUES (
      v_purchase_record.user_id,
      v_purchase_record.owner_id,
      'Appointment Reminder - 24 Hours',
      'Reminder: You have an appointment with ' || v_purchase_record.provider_name || 
      ' tomorrow at ' || to_char(NEW.appointment_date, 'HH12:MI AM'),
      'reminder',
      '/dashboard/appointments/' || NEW.id,
      NEW.id,
      'appointment',
      v_metadata || jsonb_build_object('reminder_type', '24_hour'),
      NEW.appointment_date - INTERVAL '24 hours'
    );
  END IF;
  
  IF v_hours_until_appointment > 1 THEN
    -- 1-hour reminder
    INSERT INTO notifications (
      user_id, sender_id, title, content, type, action_url, reference_id, reference_type, metadata,
      created_at
    ) VALUES (
      v_purchase_record.user_id,
      v_purchase_record.owner_id,
      'Appointment Reminder - 1 Hour',
      'Your appointment with ' || v_purchase_record.provider_name || 
      ' starts in 1 hour (' || to_char(NEW.appointment_date, 'HH12:MI AM') || ')',
      'reminder',
      '/dashboard/appointments/' || NEW.id,
      NEW.id,
      'appointment',
      v_metadata || jsonb_build_object('reminder_type', '1_hour'),
      NEW.appointment_date - INTERVAL '1 hour'
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- =============================================================================
-- 4. CREATE NEW TRIGGERS
-- =============================================================================

-- Create the new comprehensive notification trigger
CREATE TRIGGER appointment_notifications_trigger
  AFTER INSERT OR UPDATE OF status, appointment_date ON public.appointment_purchases
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_appointment_notifications();

-- Create reminder scheduling trigger  
CREATE TRIGGER appointment_reminders_trigger
  AFTER INSERT OR UPDATE OF status, appointment_date ON public.appointment_purchases
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_appointment_reminders();

-- =============================================================================
-- 5. LEGACY COMPATIBILITY FUNCTION (OPTIONAL)
-- =============================================================================

-- Keep a simplified version for backwards compatibility with external systems
CREATE FUNCTION public.notify_appointment_status_change() 
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- This function is deprecated - notifications are handled by handle_appointment_notifications()
  -- Keep only the pg_notify for backwards compatibility with external systems
  
  IF TG_OP = 'UPDATE' AND NEW.status != OLD.status THEN
    PERFORM pg_notify(
      'appointment_status_change_legacy', 
      jsonb_build_object(
        'appointment_id', NEW.id,
        'purchase_id', NEW.purchase_id,
        'old_status', OLD.status,
        'new_status', NEW.status,
        'deprecated', true,
        'message', 'Use appointment_status_change channel instead'
      )::text
    );
  ELSIF TG_OP = 'INSERT' THEN
    PERFORM pg_notify(
      'appointment_created_legacy',
      jsonb_build_object(
        'appointment_id', NEW.id,
        'purchase_id', NEW.purchase_id,
        'status', NEW.status,
        'deprecated', true,
        'message', 'Use appointment_created channel instead'
      )::text
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- =============================================================================
-- 6. COMMENTS
-- =============================================================================

COMMENT ON FUNCTION public.handle_appointment_notifications() IS 'Comprehensive trigger function that handles all appointment-related notifications based on status changes. Replaces manual notification creation in business logic functions.';

COMMENT ON FUNCTION public.handle_appointment_reminders() IS 'Creates scheduled reminder notifications for confirmed appointments';

COMMENT ON FUNCTION public.notify_appointment_status_change() IS 'DEPRECATED: Legacy function kept for backwards compatibility. Use handle_appointment_notifications() instead.';

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

-- The notification system is now trigger-based and much more maintainable:
-- 1. All appointment notifications are handled by handle_appointment_notifications()
-- 2. Reminders are handled by handle_appointment_reminders() 
-- 3. Business logic functions are simplified and focus on their core responsibilities
-- 4. Consistent notification patterns across all appointment status changes
-- 5. External system integration via pg_notify is preserved 