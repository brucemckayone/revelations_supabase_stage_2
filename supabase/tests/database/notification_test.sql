-- Notification System Test Queries
-- Use these queries to test notification functions (requires existing users)

BEGIN;

-- Set plan for TAP output
SELECT plan(12);

-- Create test admin user if needed
DO $$
DECLARE
  test_admin_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
  test_user_id UUID := 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22';
BEGIN
  -- Create test admin user
  INSERT INTO auth.users (id, email, email_confirmed_at, created_at, updated_at)
  VALUES 
    (test_admin_id, 'brucemckayone@gmail.com', NOW(), NOW(), NOW()),
    (test_user_id, 'testuser@example.com', NOW(), NOW(), NOW())
  ON CONFLICT (id) DO NOTHING;
  
  -- Set admin role
  INSERT INTO public.user_roles (user_id, role)
  VALUES (test_admin_id, 'admin')
  ON CONFLICT (user_id) DO UPDATE SET role = 'admin';
  
  -- Set regular user role
  INSERT INTO public.user_roles (user_id, role)
  VALUES (test_user_id, 'user')
  ON CONFLICT (user_id) DO NOTHING;
END;
$$;

-- Set auth context for testing (as admin user)
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "role": "authenticated", "email": "brucemckayone@gmail.com"}';

-- Test 1: Create a single notification
SELECT lives_ok(
  $$SELECT create_notification(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- user_id (admin user)
    'Test Notification',
    'This is a test notification',
    'system',  -- type
    'high',    -- priority
    NULL,      -- related_entity_id
    NULL,      -- action
    NULL       -- metadata
  )$$,
  'Test 1: Create single notification'
);

-- Test 2: Create notification with action and metadata
SELECT lives_ok(
  $$SELECT create_notification(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- user_id (admin user)
    'Action Required',
    'Please review your profile',
    'system',
    'medium',
    NULL,
    '/profile',  -- action
    jsonb_build_object('section', 'personal_info') -- metadata
  )$$,
  'Test 2: Create notification with action and metadata'
);

-- Test 3: Create notification with related entity
SELECT lives_ok(
  $$SELECT create_notification(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- user_id (admin user)
    'New Message',
    'You have a new message',
    'message',
    'low',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- related_entity_id (conversation ID)
    '/messages/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    jsonb_build_object('sender', 'Sample User')
  )$$,
  'Test 3: Create notification with related entity'
);

-- Test 4: Create batch notifications
SELECT lives_ok(
  $$SELECT create_notifications_batch(
    ARRAY['a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid, 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22'::uuid], -- user_ids
    'Batch Notification',
    'This is a batch notification',
    'system',
    'medium',
    NULL,
    '/announcements',
    jsonb_build_object('category', 'general')
  )$$,
  'Test 4: Create batch notifications'
);

-- Test 5: Test preference-based notifications
SELECT lives_ok(
  $$SELECT create_notification(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- user_id (admin user)
    'Preference Test',
    'Testing notification preferences',
    'system',  -- This will follow the user's system notification preferences
    'medium',
    NULL,
    NULL,
    NULL
  )$$,
  'Test 5: Test preference-based notifications'
);

-- Test 6: Test chat notification batching
SELECT lives_ok(
  $$SELECT create_or_update_batched_chat_notification(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- user_id (recipient)
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- sender_id (admin user)
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- chat_id
    'New message from system'
  )$$,
  'Test 6: Test chat notification batching'
);

-- Test 7: Test notification verification (notifications should exist)
SELECT ok(
  EXISTS(
    SELECT 1 FROM notifications
    WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    AND type = 'system'
  ),
  'Test 7: Verify system notifications were created'
);

-- Test 8: Create an appointment reminder notification
SELECT lives_ok(
  $$SELECT create_notification(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- user_id (admin user)
    'Appointment Reminder',
    'You have an appointment tomorrow at 2:00 PM',
    'appointment',
    'high',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- appointment_id
    '/appointments/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    jsonb_build_object('provider', 'Dr. Smith', 'time', '2023-06-15 14:00:00')
  )$$,
  'Test 8: Create appointment reminder'
);

-- Test 9: Test updating notification preferences
SELECT lives_ok(
  $$SELECT update_notification_preferences(
    'message',      -- notification type
    TRUE,           -- in_app (keep on)
    FALSE,          -- email (turn off)
    TRUE,           -- push (keep on)
    FALSE           -- sms (turn off)
  )$$,
  'Test 9: Update notification preferences'
);

-- Test 10: Mark notifications as read
SELECT lives_ok(
  $$WITH user_notifications AS (
    SELECT id
    FROM notifications
    WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    ORDER BY created_at DESC
    LIMIT 2
  )
  SELECT mark_notifications_as_read(
    ARRAY(SELECT id FROM user_notifications),
    FALSE -- don't mark all
  )$$,
  'Test 10: Mark notifications as read'
);

-- Test 11: Mark all notifications as read
SELECT lives_ok(
  $$SELECT mark_notifications_as_read(
    NULL,  -- notification_ids
    TRUE   -- mark_all
  )$$,
  'Test 11: Mark all notifications as read'
);

-- Test 12: Count notifications for a user
SELECT ok(
  (SELECT COUNT(*) FROM notifications WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11') > 0,
  'Test 12: User should have notifications'
);

-- Finish the tests
SELECT * FROM finish();

COMMIT; 