-- Event purchase system tests
BEGIN;

-- This test performs validation on the event purchase system
-- We'll run multiple tests to verify functionality

-- Set plan for TAP output
SELECT plan(7);

-- First, test that the required tables exist
SELECT has_table('public', 'events', 'Events table should exist');
SELECT has_table('public', 'event_dates', 'Event dates table should exist');
SELECT has_table('public', 'tickets', 'Tickets table should exist');
SELECT has_table('public', 'event_bookings', 'Event bookings table should exist');
SELECT has_table('public', 'purchases', 'Purchases table should exist');

-- Then, verify that views exist
SELECT has_view('public', 'event_details_view', 'Event details view should exist');
SELECT has_view('public', 'comprehensive_events_view', 'Comprehensive events view should exist');

-- Now test the event purchase functionality directly without using functions
-- This is an integration test that directly manipulates the database

-- Create test users
DO $$
DECLARE
  v_creator_id uuid := '00000000-0000-0000-0000-000000000001';
  v_customer_id uuid := '00000000-0000-0000-0000-000000000002';
  v_post_id uuid;
  v_event_id uuid;
  v_date_id uuid;
  v_ticket_id uuid;
  v_purchase_id uuid;
  v_booking_id uuid;
  v_start_date timestamp with time zone := now() + interval '1 day';
  v_end_date timestamp with time zone := now() + interval '1 day' + interval '2 hours';
BEGIN
  -- Create test users in auth schema if they don't exist
  INSERT INTO auth.users (id, email)
  VALUES (v_creator_id, 'creator@example.com')
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO auth.users (id, email)
  VALUES (v_customer_id, 'customer@example.com')
  ON CONFLICT (id) DO NOTHING;
  
  -- Create profiles for the test users if needed
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (v_creator_id, 'Test Creator', 'https://example.com/creator.jpg')
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (v_customer_id, 'Test Customer', 'https://example.com/customer.jpg')
  ON CONFLICT (id) DO NOTHING;
  
  -- Create a post
  INSERT INTO public.posts (
    id, 
    user_id, 
    title, 
    slug, 
    description, 
    content, 
    post_type, 
    status, 
    thumbnail_url
  ) VALUES (
    gen_random_uuid(), 
    v_creator_id, 
    'Test Event', 
    'test-event-' || floor(random() * 1000)::text, 
    'Test event description', 
    'Test event content', 
    'event', 
    'public', 
    'https://example.com/image.jpg'
  ) RETURNING id INTO v_post_id;
  
  -- Create the event
  INSERT INTO public.events (
    id, 
    post_id, 
    content, 
    type
  ) VALUES (
    gen_random_uuid(), 
    v_post_id, 
    'Test event content', 
    'online'
  ) RETURNING id INTO v_event_id;
  
  -- Create event date
  INSERT INTO public.event_dates (
    id, 
    event_id, 
    start_date, 
    end_date
  ) VALUES (
    gen_random_uuid(), 
    v_event_id, 
    v_start_date, 
    v_end_date
  ) RETURNING id INTO v_date_id;
  
  -- Create a ticket
  INSERT INTO public.tickets (
    id, 
    event_id, 
    title, 
    description, 
    price, 
    quantity
  ) VALUES (
    gen_random_uuid(), 
    v_event_id, 
    'Regular Ticket', 
    'Standard admission', 
    10.00, 
    100
  ) RETURNING id INTO v_ticket_id;
  
  -- Create the purchase record
  INSERT INTO public.purchases (
    id,
    user_id,
    owner_id,
    event_id,
    purchase_type,
    payment_status,
    amount,
    currency,
    stripe_payment_intent_id,
    purchase_date,
    quantity
  ) VALUES (
    gen_random_uuid(),
    v_customer_id,
    v_creator_id,
    v_event_id,
    'event',
    'pending',
    20.00,
    'USD',
    'pi_test_' || floor(random() * 1000000)::text,
    now(),
    2
  ) RETURNING id INTO v_purchase_id;
  
  -- Create the booking record
  INSERT INTO public.event_bookings (
    id,
    purchase_id,
    event_id,
    ticket_id,
    date_id,
    attendees,
    is_virtual,
    status,
    ticket_code
  ) VALUES (
    gen_random_uuid(),
    v_purchase_id,
    v_event_id,
    v_ticket_id,
    v_date_id,
    2,
    false,
    'pending',
    'TIX-' || floor(random() * 1000000)::text
  ) RETURNING id INTO v_booking_id;
  
  -- Update purchase status 
  UPDATE public.purchases
  SET payment_status = 'completed'
  WHERE id = v_purchase_id;
  
  -- Update the booking status
  UPDATE public.event_bookings
  SET status = 'confirmed'
  WHERE purchase_id = v_purchase_id;
END;
$$;

-- Finish the tests
SELECT * FROM finish();

ROLLBACK; 