-- SERVICE APPOINTMENT SYSTEM TESTS
-- Tests the basic functionality of the enhanced service appointment system

-- 1. Basic test setup
BEGIN;

-- Use UUIDs from the seed data
DO $$
DECLARE
    creator_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- From seed.sql
    client_id UUID;
    service_id UUID;
BEGIN
    -- Get a client ID (any user that's not the creator)
    SELECT id INTO client_id
    FROM auth.users
    WHERE id != creator_id
    LIMIT 1;

    -- Get a service ID belonging to the creator
    SELECT s.id INTO service_id
    FROM services s
    JOIN posts p ON s.post_id = p.id
    WHERE p.user_id = creator_id
    LIMIT 1;

    RAISE NOTICE 'Testing with creator_id: %, client_id: %, service_id: %', creator_id, client_id, service_id;

    -- Clean up any existing test data
    DELETE FROM public.provider_preferences WHERE user_id = creator_id;
    DELETE FROM public.availability_exceptions WHERE user_id = creator_id;
    DELETE FROM public.availability WHERE user_id = creator_id;

    -- Create test provider preferences
    INSERT INTO public.provider_preferences(user_id, appointment_buffer_minutes, timezone)
    VALUES (creator_id, 15, 'Europe/London');

    -- Set weekly availability for the provider
    INSERT INTO public.availability(user_id, day, is_active, start_time, end_time)
    VALUES 
        (creator_id, 'monday', true, '09:00', '17:00'),
        (creator_id, 'tuesday', true, '09:00', '17:00'),
        (creator_id, 'wednesday', true, '09:00', '17:00'),
        (creator_id, 'thursday', true, '09:00', '17:00'),
        (creator_id, 'friday', true, '09:00', '17:00');

    -- Add a date exception (e.g., holiday)
    INSERT INTO public.availability_exceptions(user_id, exception_date, is_available, reason)
    VALUES (creator_id, CURRENT_DATE + INTERVAL '5 days', false, 'Holiday');

    -- Store the real IDs in session variables for later use
    PERFORM set_config('test.creator_id', creator_id::text, false);
    PERFORM set_config('test.client_id', COALESCE(client_id::text, creator_id::text), false); -- Fallback to creator if no client
    PERFORM set_config('test.service_id', COALESCE(service_id::text, '00000000-0000-0000-0000-000000000001'), false); -- Fallback to dummy ID if needed
END $$;

-- 2. Test availability calculation
DO $$
DECLARE
    availability_data jsonb;
    creator_id UUID := current_setting('test.creator_id')::UUID;
BEGIN
    -- Get availability for the next 7 days
    SELECT jsonb_agg(
        jsonb_build_object(
            'date', date,
            'available_slots_count', jsonb_array_length(
                (SELECT jsonb_agg(slot)
                FROM jsonb_array_elements(available_slots) slot
                WHERE (slot->>'available')::boolean = true)
            )
        )
        ORDER BY date
    )
    INTO availability_data
    FROM get_provider_availability(
        creator_id, 
        CURRENT_DATE, 
        CURRENT_DATE + INTERVAL '7 days'
    );

    -- Output availability data for inspection
    RAISE NOTICE 'Availability data: %', availability_data;
    
    -- Verify the holiday date has no available slots
    ASSERT (
        SELECT jsonb_array_length(
            (SELECT jsonb_agg(item)
            FROM jsonb_array_elements(availability_data) item
            WHERE (item->>'date')::date = CURRENT_DATE + INTERVAL '5 days'
                AND (item->>'available_slots_count')::int = 0)
        )
    ) = 1, 'Holiday should show as unavailable';
END $$;

-- 3. Test appointment booking
DO $$
DECLARE
    booking_request jsonb;
    booking_result jsonb;
    test_date timestamp with time zone;
    creator_id UUID := current_setting('test.creator_id')::UUID;
    client_id UUID := current_setting('test.client_id')::UUID;
    service_id UUID := current_setting('test.service_id')::UUID;
BEGIN
    -- Set a test date (next Monday at 10am if today is not Monday)
    test_date := CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 1 THEN -- Monday
            (CURRENT_DATE + INTERVAL '0 days')::date + INTERVAL '10 hours'
        ELSE
            (CURRENT_DATE + INTERVAL '7 days' - EXTRACT(DOW FROM CURRENT_DATE)::int * INTERVAL '1 day' + INTERVAL '1 day')::date + INTERVAL '10 hours'
        END;
    
    -- Mock context for testing without actual authentication
    SET session.auth.uid TO client_id;
    
    -- Attempt to book an appointment
    RAISE NOTICE 'Would attempt to book appointment on % for service %', test_date, service_id;
    
    -- In an actual test environment, we would do something like:
    /*
    SELECT request_service_appointment(
        service_id,                  -- service_id
        test_date,                   -- requested_date
        60,                          -- duration
        'video',                     -- method
        'consultation',              -- service_type
        'Test booking notes',        -- notes
        client_id                    -- client_id
    ) INTO booking_result;
    
    RAISE NOTICE 'Booking result: %', booking_result;
    
    -- Verify the booking was successful
    ASSERT (booking_result->>'success')::boolean = true, 'Booking should succeed';
    */
END $$;

-- 4. Calendar view test
DO $$
DECLARE
    calendar_data jsonb;
    service_id UUID := current_setting('test.service_id')::UUID;
BEGIN    
    -- We can't fully test without proper authentication, but we can show what we'd test
    RAISE NOTICE 'Would test calendar view generation for service %', service_id;
    
    -- In actual test environment:
    /*
    SELECT get_service_calendar_availability(
        service_id,  -- service_id
        7,           -- days_ahead
        'UTC'        -- timezone
    ) INTO calendar_data;
    
    RAISE NOTICE 'Calendar data: %', calendar_data;
    
    -- Verify calendar contains expected days
    ASSERT jsonb_array_length(calendar_data->'days') = 7, 'Calendar should have 7 days';
    */
END $$;

-- Test cleanup
DO $$
DECLARE
    creator_id UUID := current_setting('test.creator_id')::UUID;
BEGIN
    -- Clean up our test data
    DELETE FROM public.provider_preferences WHERE user_id = creator_id;
    DELETE FROM public.availability_exceptions WHERE user_id = creator_id;
    DELETE FROM public.availability WHERE user_id = creator_id;
    
    RAISE NOTICE 'Tests completed and data cleaned up';
END $$;

ROLLBACK; -- Don't actually commit our test data 