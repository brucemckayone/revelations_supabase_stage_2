-- SEED SUBSCRIPTION DATA
-- Creates sample subscription tiers and access rules for the test creator
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- First we need to insert a test user with the required UUID for our seeding 
DO $$
DECLARE
    creator_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- brucemckayone@gmail.com
BEGIN
    -- Skip user and profile creation completely - these are now handled in seed.sql
    -- We'll just focus on subscription tiers and content access rules

    -- If we need to ensure the user has the creator role, do it conditionally
    IF EXISTS (SELECT 1 FROM auth.users WHERE id = creator_id) 
       AND NOT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = creator_id AND role = 'creator') THEN
        -- Add user role only if needed
        INSERT INTO public.user_roles (
            user_id,
            role
        ) VALUES (
            creator_id,
            'creator'
        );
    END IF;
END $$;

-- Now create all the creator subscription data
DO $$
DECLARE
    creator_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- brucemckayone@gmail.com
    bronze_tier_id UUID;
    silver_tier_id UUID;
    gold_tier_id UUID;
    platinum_tier_id UUID;
    profile_id UUID;
    
    -- Sample content IDs
    v_content_ids UUID[];
    v_post_ids UUID[];
BEGIN
    profile_id := creator_id;
    
    -- Ensure creator exists before proceeding with subscription data
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = creator_id) THEN
        RAISE NOTICE 'Creator user does not exist. Skipping subscription setup.';
        RETURN;
    END IF;
    
    -- Skip creator_profiles creation - this will be handled by seed.sql
    -- Skip creator_branding creation - this will be handled by seed.sql

    -- Create seed data first if needed
    -- Only create posts if creator exists and has no posts yet
    IF EXISTS (SELECT 1 FROM auth.users WHERE id = creator_id) AND 
       NOT EXISTS (SELECT 1 FROM public.posts WHERE user_id = creator_id LIMIT 1) THEN
        -- Create a few sample posts for the creator
        INSERT INTO public.posts (
            id, user_id, title, slug, publish_status, post_type, 
            created_at, updated_at, scheduled_for
        )
        SELECT 
            gen_random_uuid(), 
            creator_id, 
            'Sample Post ' || i, 
            'sample-post-' || i, 
            'public', 
            CASE 
                WHEN i % 5 = 0 THEN 'article'
                WHEN i % 5 = 1 THEN 'yoga'
                WHEN i % 5 = 2 THEN 'meditation'
                WHEN i % 5 = 3 THEN 'dance'
                ELSE 'neuro_flow'
            END,
            NOW(), 
            NOW(), 
            NULL
        FROM generate_series(1, 10) i;

        -- Create some sample content (needed for the subscription content access table)
        WITH new_posts AS (
            SELECT id, post_type 
            FROM public.posts 
            WHERE user_id = creator_id 
            AND id NOT IN (SELECT post_id FROM public.on_demand_media)
        )
        INSERT INTO public.on_demand_media (
            id, post_id, media_url, duration, price, is_free
        )
        SELECT 
            gen_random_uuid(),
            id,
            'https://example.com/media/' || id, 
            INTERVAL '10 minutes' * (RANDOM() * 6 + 1)::integer,
            CASE WHEN RANDOM() < 0.3 THEN 0 ELSE 9.99 END,
            RANDOM() < 0.3
        FROM new_posts;
    END IF;
    
    -- Get some random content IDs
    SELECT ARRAY_AGG(odm.id) INTO v_content_ids
    FROM on_demand_media odm
    JOIN posts p ON odm.post_id = p.id
    WHERE p.user_id = creator_id
    LIMIT 20;
    
    -- Get some random post IDs
    SELECT ARRAY_AGG(p.id) INTO v_post_ids
    FROM posts p
    WHERE p.user_id = creator_id
    LIMIT 10;
    
    -- Only proceed if we have content and posts for this creator
    IF array_length(v_content_ids, 1) > 0 AND array_length(v_post_ids, 1) > 0 THEN
        -- Create subscription tiers for the creator if not already exist
        IF NOT EXISTS (SELECT 1 FROM creator_subscription_tiers WHERE creator_id = creator_id AND tier_key = 'bronze') THEN
            -- 1. Bronze tier (basic access)
            INSERT INTO creator_subscription_tiers (
                creator_id, tier_key, tier_name, description,
                price_monthly, price_quarterly, price_annual,
                stripe_price_id_monthly, stripe_price_id_quarterly, stripe_price_id_annual,
                stripe_product_id, benefits, priority, is_active, trial_days
            ) VALUES (
                creator_id, 'bronze', 'Bronze Membership', 'Basic access to exclusive content',
                9.99, 26.99, 99.99,
                'price_bronze_monthly', 'price_bronze_quarterly', 'price_bronze_annual',
                'prod_bronze',
                '{"features": ["Access to selected content", "Monthly newsletter", "Community access"]}',
                10, true, 7
            ) RETURNING id INTO bronze_tier_id;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM creator_subscription_tiers WHERE creator_id = creator_id AND tier_key = 'silver') THEN
            -- 2. Silver tier (mid-level access)
            INSERT INTO creator_subscription_tiers (
                creator_id, tier_key, tier_name, description,
                price_monthly, price_quarterly, price_annual,
                stripe_price_id_monthly, stripe_price_id_quarterly, stripe_price_id_annual,
                stripe_product_id, benefits, priority, is_active, trial_days
            ) VALUES (
                creator_id, 'silver', 'Silver Membership', 'Enhanced access to exclusive content',
                19.99, 53.99, 199.99,
                'price_silver_monthly', 'price_silver_quarterly', 'price_silver_annual',
                'prod_silver',
                '{"features": ["Access to most content", "Weekly newsletter", "Community access", "Monthly Q&A session"]}',
                20, true, 7
            ) RETURNING id INTO silver_tier_id;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM creator_subscription_tiers WHERE creator_id = creator_id AND tier_key = 'gold') THEN
            -- 3. Gold tier (premium access)
            INSERT INTO creator_subscription_tiers (
                creator_id, tier_key, tier_name, description,
                price_monthly, price_quarterly, price_annual,
                stripe_price_id_monthly, stripe_price_id_quarterly, stripe_price_id_annual,
                stripe_product_id, benefits, priority, is_active, trial_days
            ) VALUES (
                creator_id, 'gold', 'Gold Membership', 'Premium access to all content',
                29.99, 80.99, 299.99,
                'price_gold_monthly', 'price_gold_quarterly', 'price_gold_annual',
                'prod_gold',
                '{"features": ["Access to all content", "Daily newsletter", "VIP community access", "Weekly Q&A session", "Early access to new content"]}',
                30, true, 7
            ) RETURNING id INTO gold_tier_id;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM creator_subscription_tiers WHERE creator_id = creator_id AND tier_key = 'platinum') THEN
            -- 4. Platinum tier (ultimate access)
            INSERT INTO creator_subscription_tiers (
                creator_id, tier_key, tier_name, description,
                price_monthly, price_quarterly, price_annual,
                stripe_price_id_monthly, stripe_price_id_quarterly, stripe_price_id_annual,
                stripe_product_id, benefits, priority, is_active, trial_days
            ) VALUES (
                creator_id, 'platinum', 'Platinum Membership', 'Ultimate access with personalized services',
                49.99, 134.99, 499.99,
                'price_platinum_monthly', 'price_platinum_quarterly', 'price_platinum_annual',
                'prod_platinum',
                '{"features": ["Access to all content", "Premium newsletter", "VIP community access", "Personal Q&A sessions", "1-on-1 monthly call", "Personalized content recommendations"]}',
                40, true, 7
            ) RETURNING id INTO platinum_tier_id;
        END IF;
        
        -- Set up content access rules (with ON CONFLICT DO NOTHING to avoid errors if they already exist)
        
        -- 1. Grant bronze tier access to specific content
        FOR i IN 1..5 LOOP
            -- Only if we have content IDs
            IF array_length(v_content_ids, 1) >= i THEN
                INSERT INTO subscription_content_access (
                    creator_id, content_id, tier_key
                ) VALUES (
                    creator_id, v_content_ids[i], 'bronze'
                ) ON CONFLICT DO NOTHING;
            END IF;
        END LOOP;
        
        -- 2. Grant silver tier access to specific posts
        FOR i IN 1..3 LOOP
            -- Only if we have post IDs
            IF array_length(v_post_ids, 1) >= i THEN
                INSERT INTO subscription_content_access (
                    creator_id, post_id, tier_key
                ) VALUES (
                    creator_id, v_post_ids[i], 'silver'
                ) ON CONFLICT DO NOTHING;
            END IF;
        END LOOP;
        
        -- 3. Grant gold tier access to all articles
        INSERT INTO subscription_content_access (
            creator_id, post_type, tier_key
        ) VALUES (
            creator_id, 'article', 'gold'
        ) ON CONFLICT DO NOTHING;
        
        -- 4. Grant platinum tier access to all content types
        INSERT INTO subscription_content_access (
            creator_id, post_type, tier_key
        ) VALUES (
            creator_id, 'yoga', 'platinum'
        ) ON CONFLICT DO NOTHING;
        
        INSERT INTO subscription_content_access (
            creator_id, post_type, tier_key
        ) VALUES (
            creator_id, 'dance', 'platinum'
        ) ON CONFLICT DO NOTHING;
        
        INSERT INTO subscription_content_access (
            creator_id, post_type, tier_key
        ) VALUES (
            creator_id, 'neuro_flow', 'platinum'
        ) ON CONFLICT DO NOTHING;
        
        INSERT INTO subscription_content_access (
            creator_id, post_type, tier_key
        ) VALUES (
            creator_id, 'meditation', 'platinum'
        ) ON CONFLICT DO NOTHING;
        
        -- Create some sample subscriptions for users to this creator
        
        -- Get random users (not the creator)
        DECLARE
            user_ids UUID[];
            random_user_id UUID;
            purchase_id UUID;
            subscription_id TEXT;
            v_status TEXT;
            v_tier TEXT;
            v_billing_cycle TEXT;
            v_next_billing_date TIMESTAMP WITH TIME ZONE;
            v_trial_ends_at TIMESTAMP WITH TIME ZONE;
        BEGIN
            -- Create at least one more test user if we don't have any
            IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id <> creator_id LIMIT 1) THEN
                -- Create a couple test users
                FOR i IN 1..5 LOOP
                    random_user_id := uuid_generate_v4();
                    
                    INSERT INTO auth.users (
                        id,
                        instance_id,
                        email,
                        encrypted_password,
                        email_confirmed_at,
                        aud,
                        role
                    ) 
                    VALUES (
                        random_user_id,
                        '00000000-0000-0000-0000-000000000000',
                        'test.user' || i || '@example.com',
                        '$2a$10$zrLH9SoQy7GXzrDzVX..Z.TbRmV3ZaDA.4XPo3XfN0WbB3tq/PBKG', -- random string
                        NOW(),
                        'authenticated',
                        'authenticated'
                    );
                    
                    -- Add profile record
                    INSERT INTO public.profiles (
                        id,
                        full_name,
                        updated_at
                    ) VALUES (
                        random_user_id,
                        'Test User ' || i,
                        NOW()
                    );
                END LOOP;
            END IF;
            
            -- Get user IDs
            SELECT ARRAY_AGG(id) INTO user_ids
            FROM auth.users
            WHERE id != creator_id
            LIMIT 10;
            
            -- Create subscriptions for 5 users if we have users
            IF array_length(user_ids, 1) > 0 THEN
                FOR i IN 1..5 LOOP
                    -- If we have user IDs to work with
                    IF array_length(user_ids, 1) >= i THEN
                        -- Pick a random user
                        random_user_id := user_ids[i]; -- Use sequential instead of random to avoid array index issues
                        
                        -- Pick tier based on index
                        CASE 
                            WHEN i % 4 = 0 THEN v_tier := 'platinum';
                            WHEN i % 4 = 1 THEN v_tier := 'gold';
                            WHEN i % 4 = 2 THEN v_tier := 'silver';
                            ELSE v_tier := 'bronze';
                        END CASE;
                        
                        -- Pick billing cycle
                        CASE 
                            WHEN i % 3 = 0 THEN v_billing_cycle := 'annual';
                            WHEN i % 3 = 1 THEN v_billing_cycle := 'quarterly';
                            ELSE v_billing_cycle := 'monthly';
                        END CASE;
                        
                        -- Pick status
                        CASE 
                            WHEN i = 1 THEN 
                                v_status := 'trial';
                                v_trial_ends_at := NOW() + '7 days'::INTERVAL;
                            WHEN i = 5 THEN 
                                v_status := 'past_due';
                                v_trial_ends_at := NULL;
                            ELSE 
                                v_status := 'active';
                                v_trial_ends_at := NULL;
                        END CASE;
                        
                        -- Set next billing date
                        v_next_billing_date := NOW() + CASE
                            WHEN v_billing_cycle = 'monthly' THEN '1 month'::INTERVAL
                            WHEN v_billing_cycle = 'quarterly' THEN '3 months'::INTERVAL
                            WHEN v_billing_cycle = 'annual' THEN '1 year'::INTERVAL
                            ELSE '1 month'::INTERVAL
                        END;
                        
                        -- Generate a fake Stripe subscription ID
                        subscription_id := 'sub_' || left(md5(random()::text), 24);
                        
                        -- Check if this subscription already exists
                        IF NOT EXISTS (
                            SELECT 1 FROM subscriptions s
                            JOIN purchases p ON s.purchase_id = p.id
                            WHERE p.user_id = random_user_id 
                            AND p.owner_id = creator_id
                            AND s.tier = v_tier
                        ) THEN
                            -- Insert purchase record
                            INSERT INTO purchases (
                                user_id, owner_id, stripe_subscription_id, stripe_customer_id,
                                amount, currency, payment_status, 
                                purchase_type, purchase_date, start_date
                            ) VALUES (
                                random_user_id, creator_id, subscription_id, 'cus_' || left(md5(random()::text), 24),
                                CASE 
                                    WHEN v_tier = 'bronze' AND v_billing_cycle = 'monthly' THEN 9.99
                                    WHEN v_tier = 'bronze' AND v_billing_cycle = 'quarterly' THEN 26.99
                                    WHEN v_tier = 'bronze' AND v_billing_cycle = 'annual' THEN 99.99
                                    WHEN v_tier = 'silver' AND v_billing_cycle = 'monthly' THEN 19.99
                                    WHEN v_tier = 'silver' AND v_billing_cycle = 'quarterly' THEN 53.99
                                    WHEN v_tier = 'silver' AND v_billing_cycle = 'annual' THEN 199.99
                                    WHEN v_tier = 'gold' AND v_billing_cycle = 'monthly' THEN 29.99
                                    WHEN v_tier = 'gold' AND v_billing_cycle = 'quarterly' THEN 80.99
                                    WHEN v_tier = 'gold' AND v_billing_cycle = 'annual' THEN 299.99
                                    WHEN v_tier = 'platinum' AND v_billing_cycle = 'monthly' THEN 49.99
                                    WHEN v_tier = 'platinum' AND v_billing_cycle = 'quarterly' THEN 134.99
                                    WHEN v_tier = 'platinum' AND v_billing_cycle = 'annual' THEN 499.99
                                    ELSE 9.99
                                END,
                                'usd', 'completed',
                                'subscription', NOW() - (random() * 30 || ' days')::INTERVAL, NOW() - (random() * 30 || ' days')::INTERVAL
                            ) RETURNING id INTO purchase_id;
                            
                            -- Insert subscription details
                            INSERT INTO subscriptions (
                                purchase_id, stripe_subscription_id, stripe_price_id, stripe_product_id,
                                plan_name, tier, billing_cycle, status,
                                next_billing_date, payments_count, total_paid,
                                last_payment_status, last_payment_date,
                                is_trial, trial_ends_at
                            ) VALUES (
                                purchase_id, 
                                subscription_id, 
                                'price_' || v_tier || '_' || v_billing_cycle, 
                                'prod_' || v_tier,
                                v_tier || ' ' || 'Membership',
                                v_tier, 
                                v_billing_cycle, 
                                v_status,
                                v_next_billing_date,
                                CASE WHEN v_status = 'trial' THEN 0 ELSE floor(random() * 6) + 1 END,
                                CASE 
                                    WHEN v_status = 'trial' THEN 0 
                                    ELSE (CASE 
                                        WHEN v_tier = 'bronze' AND v_billing_cycle = 'monthly' THEN 9.99
                                        WHEN v_tier = 'bronze' AND v_billing_cycle = 'quarterly' THEN 26.99
                                        WHEN v_tier = 'bronze' AND v_billing_cycle = 'annual' THEN 99.99
                                        WHEN v_tier = 'silver' AND v_billing_cycle = 'monthly' THEN 19.99
                                        WHEN v_tier = 'silver' AND v_billing_cycle = 'quarterly' THEN 53.99
                                        WHEN v_tier = 'silver' AND v_billing_cycle = 'annual' THEN 199.99
                                        WHEN v_tier = 'gold' AND v_billing_cycle = 'monthly' THEN 29.99
                                        WHEN v_tier = 'gold' AND v_billing_cycle = 'quarterly' THEN 80.99
                                        WHEN v_tier = 'gold' AND v_billing_cycle = 'annual' THEN 299.99
                                        WHEN v_tier = 'platinum' AND v_billing_cycle = 'monthly' THEN 49.99
                                        WHEN v_tier = 'platinum' AND v_billing_cycle = 'quarterly' THEN 134.99
                                        WHEN v_tier = 'platinum' AND v_billing_cycle = 'annual' THEN 499.99
                                        ELSE 9.99
                                    END * (floor(random() * 6) + 1))
                                END,
                                'completed',
                                CASE WHEN v_status = 'trial' THEN NOW() ELSE NOW() - (random() * 15 || ' days')::INTERVAL END,
                                v_status = 'trial',
                                v_trial_ends_at
                            );
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END;
    END IF;
    
    RAISE NOTICE 'Created subscription tiers and sample data for creator: %', creator_id;
END $$; 