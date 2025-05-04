-- Generate Purchase Data for User brucemckayone@gmail.com
-- This script creates sample purchase records for the new purchase system

DO $$
DECLARE
    user_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- brucemckayone@gmail.com
    creator_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- same user is also a creator
    purchase_id UUID;
    content_ids UUID[];
    event_ids UUID[];
    event_data RECORD;
    ticket_id UUID;
    date_id UUID;
    service_ids UUID[];
    statuses TEXT[] := ARRAY['completed', 'pending', 'refunded', 'failed'];
    random_status TEXT;
    i INTEGER;
    
    -- Payment data
    payment_intent TEXT;
    payment_amount NUMERIC(10,2);
    subscription_id UUID;
    subscription_details RECORD;
    
    -- Event booking data
    event_id UUID;
    
    -- Content data
    content_id UUID;
    
    -- Service/appointment data
    service_id UUID;
    appointment_date TIMESTAMP WITH TIME ZONE;
    
    -- Dates
    start_date TIMESTAMP WITH TIME ZONE;
    next_billing_date TIMESTAMP WITH TIME ZONE;
    last_payment_date TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Collect content IDs for various post types
    
    -- Get content IDs (on_demand_media)
    SELECT ARRAY_AGG(odm.id) INTO content_ids
    FROM on_demand_media odm
    JOIN posts p ON odm.post_id = p.id
    WHERE p.user_id = creator_id
    LIMIT 20;
    
    -- Get event IDs
    SELECT ARRAY_AGG(e.id) INTO event_ids
    FROM events e
    JOIN posts p ON e.post_id = p.id
    WHERE p.user_id = creator_id
    LIMIT 15;
    
    -- Get service IDs
    SELECT ARRAY_AGG(s.id) INTO service_ids
    FROM services s
    JOIN posts p ON s.post_id = p.id
    WHERE p.user_id = creator_id
    LIMIT 10;
    
    -- Generate purchases data
    
    -- 1. Content purchases (videos, audio, etc.)
    FOR i IN 1..20 LOOP
        -- Skip if we don't have enough content
        IF i > COALESCE(ARRAY_LENGTH(content_ids, 1), 0) THEN
            CONTINUE;
        END IF;
        
        -- Generate random status with 70% completed, 10% each for others
        random_status := CASE
            WHEN RANDOM() < 0.7 THEN 'completed'
            WHEN RANDOM() < 0.8 THEN 'pending'
            WHEN RANDOM() < 0.9 THEN 'refunded'
            ELSE 'failed'
        END;
        
        payment_intent := 'pi_' || MD5(RANDOM()::TEXT);
        payment_amount := (9.99 + (RANDOM() * 20))::NUMERIC(10,2);
        content_id := content_ids[i];
        
        -- Insert main purchase record
        INSERT INTO public.purchases (
            user_id, owner_id, stripe_payment_intent_id, amount, currency, 
            payment_status, content_id, purchase_type, purchase_date, 
            quantity, metadata
        ) VALUES (
            user_id, creator_id, payment_intent, payment_amount, 'USD',
            random_status, content_id, 'content', 
            NOW() - (RANDOM() * 90 || ' days')::INTERVAL,
            1, jsonb_build_object('payment_method', 'card')
        ) RETURNING id INTO purchase_id;
        
        -- Insert content purchase details
        IF random_status IN ('completed', 'pending') THEN
            INSERT INTO public.content_purchases (
                purchase_id, content_id, download_count, last_accessed, 
                is_subscription, access_expires_at
            ) VALUES (
                purchase_id, content_id, 
                FLOOR(RANDOM() * 10)::INTEGER, 
                CASE WHEN RANDOM() > 0.3 THEN NOW() - (RANDOM() * 30 || ' days')::INTERVAL ELSE NULL END,
                FALSE,
                NOW() + (30 || ' days')::INTERVAL
            );
        END IF;
    END LOOP;
    
    -- 2. Event bookings
    FOR i IN 1..COALESCE(ARRAY_LENGTH(event_ids, 1), 0) LOOP
        -- Generate random status with 70% completed, 10% each for others
        random_status := CASE
            WHEN RANDOM() < 0.7 THEN 'completed'
            WHEN RANDOM() < 0.8 THEN 'pending'
            WHEN RANDOM() < 0.9 THEN 'refunded'
            ELSE 'failed'
        END;
        
        payment_intent := 'pi_' || MD5(RANDOM()::TEXT);
        payment_amount := (19.99 + (RANDOM() * 50))::NUMERIC(10,2);
        
        event_id := event_ids[i];
        
        -- Get a random ticket and date for this event
        SELECT t.id, ed.id INTO ticket_id, date_id
        FROM tickets t
        CROSS JOIN event_dates ed
        WHERE t.event_id = event_id AND ed.event_id = event_id
        ORDER BY RANDOM()
        LIMIT 1;
        
        -- Only proceed if we found a ticket and date
        IF ticket_id IS NOT NULL AND date_id IS NOT NULL THEN
            -- Insert main purchase record
            INSERT INTO public.purchases (
                user_id, owner_id, stripe_payment_intent_id, amount, currency, 
                payment_status, event_id, purchase_type, purchase_date, 
                quantity, metadata
            ) VALUES (
                user_id, creator_id, payment_intent, payment_amount, 'USD',
                random_status, event_id, 'event', 
                NOW() - (RANDOM() * 60 || ' days')::INTERVAL,
                1 + FLOOR(RANDOM() * 3)::INTEGER, -- 1-3 tickets
                jsonb_build_object('payment_method', 'card')
            ) RETURNING id INTO purchase_id;
            
            -- Insert event booking details
            IF random_status IN ('completed', 'pending') THEN
                INSERT INTO public.event_bookings (
                    purchase_id, event_id, ticket_id, date_id, 
                    attendees, is_virtual, status, ticket_code
                ) VALUES (
                    purchase_id, event_id, ticket_id, date_id,
                    1 + FLOOR(RANDOM() * 3)::INTEGER, -- 1-3 attendees
                    RANDOM() > 0.5, -- 50% virtual
                    CASE
                        WHEN random_status = 'completed' THEN 'confirmed'
                        ELSE 'pending'
                    END,
                    'TIX-' || UPPER(MD5(RANDOM()::TEXT))
                );
            END IF;
        END IF;
    END LOOP;
    
    -- 3. Service appointments
    FOR i IN 1..COALESCE(ARRAY_LENGTH(service_ids, 1), 0) LOOP
        -- Generate random status with 70% completed, 10% each for others
        random_status := CASE
            WHEN RANDOM() < 0.7 THEN 'completed'
            WHEN RANDOM() < 0.8 THEN 'pending'
            WHEN RANDOM() < 0.9 THEN 'refunded'
            ELSE 'failed'
        END;
        
        payment_intent := 'pi_' || MD5(RANDOM()::TEXT);
        payment_amount := (49.99 + (RANDOM() * 100))::NUMERIC(10,2);
        service_id := service_ids[i];
        
        appointment_date := NOW() + ((RANDOM() * 30)::INTEGER || ' days')::INTERVAL;
        
        -- Insert main purchase record
        INSERT INTO public.purchases (
            user_id, owner_id, stripe_payment_intent_id, amount, currency, 
            payment_status, service_id, purchase_type, purchase_date, 
            start_date, end_date, quantity, metadata
        ) VALUES (
            user_id, creator_id, payment_intent, payment_amount, 'USD',
            random_status, service_id, 'appointment', 
            NOW() - (RANDOM() * 30 || ' days')::INTERVAL,
            appointment_date, appointment_date + (60 || ' minutes')::INTERVAL,
            1, jsonb_build_object('payment_method', 'card')
        ) RETURNING id INTO purchase_id;
        
        -- Insert appointment details
        IF random_status IN ('completed', 'pending') THEN
            INSERT INTO public.appointment_purchases (
                purchase_id, service_id, appointment_date, 
                duration, method, service_type, status, notes
            ) VALUES (
                purchase_id, service_id, appointment_date,
                60, -- 60 minutes duration
                (ARRAY['video', 'phone', 'in-person'])[1 + FLOOR(RANDOM() * 3)],
                (ARRAY['reading', 'healing', 'coaching', 'consultation'])[1 + FLOOR(RANDOM() * 4)],
                CASE
                    WHEN random_status = 'completed' THEN 'confirmed'
                    ELSE 'pending'
                END,
                'Client notes: Looking forward to this session!'
            );
        END IF;
    END LOOP;
    
    -- 4. Subscriptions
    FOR i IN 1..5 LOOP
        -- Generate random status with more completed for subscriptions
        random_status := CASE
            WHEN RANDOM() < 0.8 THEN 'completed'
            WHEN RANDOM() < 0.9 THEN 'pending'
            WHEN RANDOM() < 0.95 THEN 'refunded'
            ELSE 'failed'
        END;
        
        payment_intent := 'pi_' || MD5(RANDOM()::TEXT);
        payment_amount := (9.99 + (RANDOM() * 20))::NUMERIC(10,2);
        
        start_date := NOW() - (RANDOM() * 180 || ' days')::INTERVAL;
        next_billing_date := start_date + (30 || ' days')::INTERVAL * (1 + FLOOR(RANDOM() * 5));
        last_payment_date := start_date + (30 || ' days')::INTERVAL * FLOOR(RANDOM() * 5);
        
        -- Insert main purchase record
        INSERT INTO public.purchases (
            user_id, owner_id, stripe_payment_intent_id, stripe_subscription_id, 
            amount, currency, payment_status, purchase_type, purchase_date, 
            start_date, end_date, quantity, metadata
        ) VALUES (
            user_id, creator_id, payment_intent, 'sub_' || MD5(RANDOM()::TEXT),
            payment_amount, 'USD', random_status, 'subscription', 
            start_date, start_date, NULL, 1, 
            jsonb_build_object('payment_method', 'card')
        ) RETURNING id INTO purchase_id;
        
        -- Insert subscription details
        IF random_status IN ('completed', 'pending') THEN
            INSERT INTO public.subscriptions (
                purchase_id, stripe_subscription_id, stripe_price_id, stripe_product_id,
                plan_name, tier, billing_cycle, status,
                next_billing_date, payments_count, total_paid,
                last_payment_status, last_payment_date
            ) VALUES (
                purchase_id, 'sub_' || MD5(RANDOM()::TEXT), 
                'price_' || MD5(RANDOM()::TEXT), 'prod_' || MD5(RANDOM()::TEXT),
                (ARRAY['Basic Plan', 'Premium Plan', 'Unlimited Plan'])[1 + FLOOR(RANDOM() * 3)],
                (ARRAY['basic', 'premium', 'unlimited'])[1 + FLOOR(RANDOM() * 3)],
                (ARRAY['monthly', 'quarterly', 'annual'])[1 + FLOOR(RANDOM() * 3)],
                CASE
                    WHEN RANDOM() < 0.7 THEN 'active'
                    WHEN RANDOM() < 0.8 THEN 'trial'
                    WHEN RANDOM() < 0.9 THEN 'paused'
                    WHEN RANDOM() < 0.95 THEN 'past_due'
                    ELSE 'cancelled'
                END,
                next_billing_date,
                1 + FLOOR(RANDOM() * 10),
                payment_amount * (1 + FLOOR(RANDOM() * 10)),
                CASE
                    WHEN RANDOM() < 0.9 THEN 'completed'
                    WHEN RANDOM() < 0.95 THEN 'failed'
                    ELSE 'refunded'
                END,
                last_payment_date
            );
        END IF;
    END LOOP;
    
    -- 5. Article purchases
    FOR i IN 1..8 LOOP
        -- Generate random status
        random_status := CASE
            WHEN RANDOM() < 0.7 THEN 'completed'
            WHEN RANDOM() < 0.8 THEN 'pending'
            WHEN RANDOM() < 0.9 THEN 'refunded'
            ELSE 'failed'
        END;
        
        payment_intent := 'pi_' || MD5(RANDOM()::TEXT);
        payment_amount := (2.99 + (RANDOM() * 5))::NUMERIC(10,2);
        
        -- Get a random article post ID
        WITH random_article AS (
            SELECT id FROM posts
            WHERE post_type = 'article' AND user_id = creator_id
            ORDER BY RANDOM()
            LIMIT 1
        )
        
        -- Insert main purchase record
        INSERT INTO public.purchases (
            user_id, owner_id, stripe_payment_intent_id, amount, currency, 
            payment_status, post_id, purchase_type, purchase_date, 
            quantity, metadata
        ) VALUES (
            user_id, creator_id, payment_intent, payment_amount, 'USD',
            random_status, 
            (SELECT id FROM random_article), 
            'article', 
            NOW() - (RANDOM() * 90 || ' days')::INTERVAL,
            1, jsonb_build_object('payment_method', 'card')
        );
    END LOOP;
    
    RAISE NOTICE 'Generated purchase data for user_id: %', user_id;
END $$;

-- Sample queries to verify data

-- All purchases
-- SELECT * FROM purchases WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Content purchases
-- SELECT p.*, cp.* 
-- FROM purchases p
-- JOIN content_purchases cp ON p.id = cp.purchase_id
-- WHERE p.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Event bookings
-- SELECT p.*, eb.* 
-- FROM purchases p
-- JOIN event_bookings eb ON p.id = eb.purchase_id
-- WHERE p.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Appointment purchases
-- SELECT p.*, ap.* 
-- FROM purchases p
-- JOIN appointment_purchases ap ON p.id = ap.purchase_id
-- WHERE p.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- Subscriptions
-- SELECT p.*, s.* 
-- FROM purchases p
-- JOIN subscriptions s ON p.id = s.purchase_id
-- WHERE p.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; 