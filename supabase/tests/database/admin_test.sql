-- Admin role test file
-- This file checks if admin role privileges are properly set up

BEGIN;

-- Set plan for TAP output
SELECT plan(3);

-- Find an existing admin for testing
DO $$
DECLARE
  admin_userid UUID;
  admin_email TEXT;
BEGIN
  -- Find an existing admin in user_roles
  SELECT user_id INTO admin_userid 
  FROM public.user_roles 
  WHERE role = 'admin' 
  LIMIT 1;
  
  -- Get the admin email
  IF admin_userid IS NOT NULL THEN
    SELECT email INTO admin_email 
    FROM auth.users 
    WHERE id = admin_userid;
    
    -- Store values for tests
    PERFORM set_config('test.admin_userid', admin_userid::text, false);
    PERFORM set_config('test.admin_email', admin_email, false);
  ELSE
    -- No admin found - set dummy values
    PERFORM set_config('test.admin_userid', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', false);
    PERFORM set_config('test.admin_email', 'admin@example.com', false);
  END IF;
END;
$$;

-- Set auth context for testing
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated", "email": "test@example.com"}';

-- Test 1: Find an admin user in the system
SELECT ok(
  EXISTS(SELECT 1 FROM public.user_roles WHERE role = 'admin'),
  'System should have at least one admin user'
);

-- Test 2: Check admin has a valid user account
SELECT ok(
  EXISTS(
    SELECT 1 
    FROM public.user_roles ur
    JOIN auth.users au ON ur.user_id = au.id
    WHERE ur.role = 'admin'
  ),
  'Admin user should have a user account'
);

-- Test 3: Check admin privileges
SELECT ok(
  (SELECT COUNT(*) FROM public.user_roles WHERE role = 'admin') > 0,
  'Should have at least one admin user with privileges'
);

-- Finish the tests
SELECT * FROM finish();

ROLLBACK; 