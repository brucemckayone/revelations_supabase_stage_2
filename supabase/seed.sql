-- Function to generate random dates
CREATE OR REPLACE FUNCTION random_future_date(days_ahead INT) RETURNS TIMESTAMP AS $$
BEGIN
    RETURN CURRENT_DATE + (random() * days_ahead || ' days')::INTERVAL + (random() * 24 || ' hours')::INTERVAL;
END;
$$ LANGUAGE plpgsql;

-- Function to sanitize slugs
CREATE OR REPLACE FUNCTION sanitize_slug(input TEXT) RETURNS TEXT AS $$
DECLARE
    sanitized TEXT;
BEGIN
    -- Remove non-word characters (except hyphens), convert to lowercase, replace spaces with hyphens
    sanitized := lower(regexp_replace(input, '[^\w\s-]', '', 'g'));
    sanitized := regexp_replace(sanitized, '[\s_]+', '-', 'g');
    -- Remove leading and trailing hyphens
    sanitized := trim(both '-' from sanitized);
    -- Truncate to 200 characters
    sanitized := left(sanitized, 200);
    RETURN sanitized;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION random_name() RETURNS TEXT AS $$
DECLARE
    first_names TEXT[] := ARRAY['Alice', 'Bob', 'Charlie', 'Diana', 'Ethan', 'Fiona', 'George', 'Hannah', 'Ian', 'Julia'];
    last_names TEXT[] := ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
BEGIN
    RETURN first_names[floor(random() * array_length(first_names, 1) + 1)] || ' ' || 
           last_names[floor(random() * array_length(last_names, 1) + 1)];
END;
$$ LANGUAGE plpgsql;


DO $$
DECLARE
    creator_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    playlist_ids UUID[];
    session_names TEXT[] := ARRAY[
        'Morning Revitalize', 'Sunset Serenity', 'Midday Recharge',
        'Gentle Awakening', 'Evening Unwind', 'Energizing Flow',
        'Mindful Movement', 'Balance and Harmony', 'Stress Relief Session',
        'Inner Peace Practice'
    ];
    image_urls TEXT[] := ARRAY[
        'https://images.unsplash.com/photo-1725555610696-723ad3e0ab88?q=80&w=3687&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1724775624688-d407aa8d9c23?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1529693662653-9d480530a697?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1429277096327-11ee3b761c93?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1593811167562-9cef47bfc4d7?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1517760307355-e48f68215de6?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1559595500-e15296bdbb48?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1510034141778-a4d065653d92?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1604046767104-e53cd9f82be5?w=800&auto=format&fit=crop'
    ];

    event_image_urls TEXT[] := ARRAY[
        'https://images.unsplash.com/photo-1647795411204-03342e304c12?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGV2ZW50c3xlbnwwfHwwfHx8MA%3D%3D',
        'https://images.unsplash.com/photo-1556125574-d7f27ec36a06?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8N3x8ZXZlbnRzfGVufDB8fDB8fHww',
        'https://images.unsplash.com/photo-1648073380875-5a46e345ecf2?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTB8fGV2ZW50c3xlbnwwfHwwfHx8MA%3D%3D',
        'https://images.unsplash.com/photo-1566731372839-859e7cead0ef?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTR8fGV2ZW50c3xlbnwwfHwwfHx8MA%3D%3D',
        'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGV2ZW50cyUyMHdlbGxuZXNzfGVufDB8fDB8fHww',
        'https://images.unsplash.com/photo-1556760544-74068565f05c?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTh8fGV2ZW50cyUyMHdlbGxuZXNzfGVufDB8fDB8fHww',
        'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTd8fGV2ZW50cyUyMHdlbGxuZXNzfGVufDB8fDB8fHww',
        'https://images.unsplash.com/photo-1634155323530-385a795dd103?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTV8fGV2ZW50cyUyMHdlbGxuZXNzfGVufDB8fDB8fHww',
        'https://images.unsplash.com/photo-1634155322814-907072ac721f?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTN8fGV2ZW50cyUyMHdlbGxuZXNzfGVufDB8fDB8fHww',
        'https://images.unsplash.com/photo-1577253313708-cab167d2c474?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NTZ8fG1lZGl0YXRpb258ZW58MHx8MHx8fDA%3D'
    ];

    profile_pictures TEXT[] := ARRAY[
        'https://images.unsplash.com/photo-1570158268183-d296b2892211?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MzB8fGd1cnUlMjBmYWNlfGVufDB8fDB8fHww',
        'https://images.unsplash.com/photo-1499996860823-5214fcc65f8f?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mjh8fGd1cnUlMjBmYWNlfGVufDB8fDB8fHww',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MzJ8fGd1cnUlMjBmYWNlfGVufDB8fDB8fHww',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mjd8fGd1cnUlMjBmYWNlfGVufDB8fDB8fHww',
        'https://images.unsplash.com/photo-1640564282316-6a7a91ffc69a?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8Z3VydSUyMGZhY2V8ZW58MHx8MHx8fDA%3D'
    ];

    timezones TEXT[] := ARRAY[
        'UTC-08:00', 'UTC-05:00', 'UTC+00:00', 'UTC+01:00', 'UTC+02:00', 
        'UTC+03:00', 'UTC+05:30', 'UTC+08:00', 'UTC+09:00', 'UTC+10:00'
    ];

    content_template TEXT := '{"type":"doc","content":[{"type":"heading","attrs":{"textAlign":"left","level":1},"content":[{"type":"text","text":"%s: %s Session %s"}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"In today''s %s session, we will be focusing on %s and the flow of energy through our bodies. This session will include movements that target the Root Chakra, Sacral Chakra, and Throat Chakra. These chakras play a vital role in grounding us, enhancing creativity, and facilitating clear communication."}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Our instructor for this session is Jane Doe, and her teachings will guide us in finding balance within ourselves and the universe. The theme of %s and Energy Flow will set the tone for a deeply %s and rejuvenating experience."}]},{"type":"heading","attrs":{"textAlign":"left","level":2},"content":[{"type":"text","text":"Session Details"}]},{"type":"bulletList","attrs":{"tight":true},"content":[{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","marks":[{"type":"bold"}],"text":"Instructor:"},{"type":"text","text":" Jane Doe"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","marks":[{"type":"bold"}],"text":"Session Theme:"},{"type":"text","text":" %s, Energy Flow"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","marks":[{"type":"bold"}],"text":"Energy Level:"},{"type":"text","text":" %s"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","marks":[{"type":"bold"}],"text":"Spiritual Elements:"},{"type":"text","text":" %s"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","marks":[{"type":"bold"}],"text":"Emotional Focus:"},{"type":"text","text":" %s"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","marks":[{"type":"bold"}],"text":"Recommended Environment:"},{"type":"text","text":" %s"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","marks":[{"type":"bold"}],"text":"Body Focus:"},{"type":"text","text":" %s"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","marks":[{"type":"bold"}],"text":"Tags:"},{"type":"text","text":" %s"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","marks":[{"type":"bold"}],"text":"%s Style:"},{"type":"text","text":" %s"}]}]}]},{"type":"heading","attrs":{"textAlign":"left","level":2},"content":[{"type":"text","text":"Conclusion"}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"As we prepare for our %s session, let us set our intentions on finding balance, calmness, and joy within ourselves. Whether you are a beginner or experienced, this session will provide a nurturing space for you to connect with your body, mind, and spirit. So get ready to flow with the energy and discover the transformative power of %s. Namaste."}]}]}';

    v_location_ids UUID[];
    v_event_themes TEXT[] := ARRAY['Wellness Retreat', 'Tech Conference', 'Music Festival', 'Art Exhibition', 'Food & Wine Tasting', 'Fitness Challenge', 'Business Networking', 'Environmental Workshop', 'Cultural Celebration', 'Educational Seminar'];
    v_event_types event_type_enum[] := ARRAY['online', 'in-person', 'hybrid'];
    v_result event_creation_result;

    article_themes TEXT[] := ARRAY[
        'The Future of AI',
        'Sustainable Living Tips',
        'Mental Health in the Digital Age',
        'Space Exploration Breakthroughs',
        'The Art of Mindfulness',
        'Emerging Tech Trends',
        'Climate Change Solutions',
        'The Power of Positive Psychology',
        'Nutrition Myths Debunked',
        'Innovations in Renewable Energy'
    ];
    v_result_article article_content_creation_result;

    v_content TEXT;
    v_description TEXT;

        
    service_themes TEXT[] := ARRAY[
        'Neuro-Somatic Intelligence Session',
        'Mind-Body Connection Workshop',
        'Stress Relief and Relaxation Therapy',
        'Cognitive Enhancement Training',
        'Emotional Regulation Coaching',
        'Physical Performance Optimization',
        'Creativity Boost and Expression Session',
        'Holistic Wellness Consultation',
        'Pain Management and Recovery Program',
        'Personal Growth and Development Seminar'
    ];
    v_result_service service_content_creation_result;


BEGIN
    -- create test users
    INSERT INTO
        auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            recovery_sent_at,
            last_sign_in_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            email_change,
            email_change_token_new,
            recovery_token
        )
    SELECT
        '00000000-0000-0000-0000-000000000000',
        CASE WHEN ROW_NUMBER() OVER () = 1 THEN creator_id ELSE uuid_generate_v4() END,
        'authenticated',
        'authenticated',
        CASE 
            WHEN ROW_NUMBER() OVER () = 1 THEN 'brucemckayone@gmail.com'
            ELSE 'user' || (ROW_NUMBER() OVER ()) || '@example.com'
        END,
        crypt('password123', gen_salt('bf')),
        current_timestamp,
        current_timestamp,
        current_timestamp,
        '{"provider":"email","providers":["email"]}',
        CASE
            WHEN ROW_NUMBER() OVER () = 1 THEN
                jsonb_build_object(
                    'name', 'Bruce McKay',
                    'email', 'brucemckayone@gmail.com',
                    'picture', 'https://lh3.googleusercontent.com/a/ACg8ocIvrEMEKLc-Mp_7ejLgVvdkg_fs2z_gU3p928FoGv1aAVpX-Dtv=s96-c',
                    'timezone', 'UTC+00:00',
                    'full_name', 'Bruce McKay',
                    'user_role', 'creator',
                    'avatar_url', 'https://lh3.googleusercontent.com/a/ACg8ocIvrEMEKLc-Mp_7ejLgVvdkg_fs2z_gU3p928FoGv1aAVpX-Dtv=s96-c',
                    'user_timezone', 'UTC+00:00',
                    'email_verified', true,
                    'phone_verified', false
                )
            ELSE
                jsonb_build_object(
                    'name', random_name(),
                    'email', 'user' || (ROW_NUMBER() OVER ()) || '@example.com',
                    'picture', profile_pictures[1 + (ROW_NUMBER() OVER () % array_length(profile_pictures, 1))],
                    'timezone', timezones[1 + (ROW_NUMBER() OVER () % array_length(timezones, 1))],
                    'full_name', random_name(),
                    'user_role', 'user',
                    'avatar_url', profile_pictures[1 + (ROW_NUMBER() OVER () % array_length(profile_pictures, 1))],
                    'user_timezone', timezones[1 + (ROW_NUMBER() OVER () % array_length(timezones, 1))],
                    'email_verified', true,
                    'phone_verified', false
                )
        END,
        current_timestamp,
        current_timestamp,
        '',
        '',
        '',
        ''
    FROM
        generate_series(1, 10);

    -- test user email identities
    INSERT INTO
        auth.identities (
            id,
            provider_id,
            user_id,
            identity_data,
            provider,
            last_sign_in_at,
            created_at,
            updated_at
        )
    SELECT
        uuid_generate_v4(),
        uuid_generate_v4(),
        id,
        jsonb_build_object('sub', id::text, 'email', email),
        'email',
        current_timestamp,
        current_timestamp,
        current_timestamp
    FROM
        auth.users;

    UPDATE public.user_roles
    SET role = 'creator'
    WHERE user_id = creator_id;

    -- Insert tags for each post type
    -- Insert tags for each post type
    INSERT INTO public.tags (name, post_type) VALUES
    -- Yoga tags
    ('Hatha Yoga', 'yoga'), ('Vinyasa Yoga', 'yoga'), ('Yin Yoga', 'yoga'), ('Restorative Yoga', 'yoga'), ('Ashtanga Yoga', 'yoga'),
    ('Beginner Yoga', 'yoga'), ('Intermediate Yoga', 'yoga'), ('Advanced Yoga', 'yoga'),
    ('Yoga Flexibility', 'yoga'), ('Yoga Strength', 'yoga'), ('Yoga Balance', 'yoga'), ('Yoga Relaxation', 'yoga'),
    
    -- Dance tags
    ('Contemporary Dance', 'dance'), ('Hip Hop Dance', 'dance'), ('Jazz Dance', 'dance'), ('Ballet Dance', 'dance'), ('Freestyle Dance', 'dance'),
    ('Beginner Dance', 'dance'), ('Intermediate Dance', 'dance'), ('Advanced Dance', 'dance'),
    ('Dance Cardio', 'dance'), ('Dance Choreography', 'dance'), ('Dance Expression', 'dance'), ('Dance Rhythm', 'dance'),
    
    -- Neuro flow tags
    ('Neuro Meditation', 'neuro_flow'), ('Neuro Breathwork', 'neuro_flow'), ('Neuro Visualization', 'neuro_flow'),
    ('Neuro Movement', 'neuro_flow'), ('Neuro Integration', 'neuro_flow'),
    ('Brain Optimization', 'neuro_flow'), ('Neuroplasticity', 'neuro_flow'), ('Neuro Focus', 'neuro_flow'),
    ('Neuro Creativity', 'neuro_flow'), ('Cognitive Enhancement', 'neuro_flow'),
    
    -- Event tags
    ('Event Conference', 'event'), ('Event Workshop', 'event'), ('Event Retreat', 'event'), ('Event Seminar', 'event'),
    ('Online Event', 'event'), ('In-Person Event', 'event'), ('Hybrid Event', 'event'),
    ('Professional Event', 'event'), ('Entertainment Event', 'event'), ('Wellness Event', 'event'),
    
    -- Article tags
    ('Technology Article', 'article'), ('Science Article', 'article'), ('Health Article', 'article'), ('Environment Article', 'article'),
    ('Innovation Article', 'article'), ('Research Article', 'article'), ('Analysis Article', 'article'), ('Opinion Article', 'article'),
    
    -- Service tags
    ('Coaching Service', 'service'), ('Therapy Service', 'service'), ('Consultation Service', 'service'), ('Training Service', 'service'),
    ('Online Service', 'service'), ('In-Person Service', 'service'), ('Hybrid Service', 'service'),
    ('Wellness Service', 'service'), ('Personal Development Service', 'service'), ('Performance Service', 'service'),


    -- Meditation tags
    ('Mindfulness', 'meditation'),
    ('Transcendental', 'meditation'),
    ('Loving-Kindness', 'meditation'),
    ('Vipassana', 'meditation'),
    ('Zen', 'meditation'),
    ('Beginner', 'meditation'),
    ('Intermediate', 'meditation'),
    ('Advanced', 'meditation'),
    ('Guided', 'meditation'),
    ('Body Scan', 'meditation'),
    ('Breath Awareness', 'meditation'),
    ('Mantra', 'meditation'),

    -- article tags 
    ('Coaching', 'article'),
    ('Therapy', 'article'), 
    ('Consultation', 'article'), 
    ('Training', 'article'), 
    ('Online Wellness', 'article'), 
    ('In-Person Wellness', 'article'), 
    ('Hybrid Wellness', 'article'), 
    ('Wellness', 'article'), 
    ('Personal Development', 'article'), 
    ('Performance', 'article'), 
    ('Mindfulness', 'article'), 
    ('Meditation', 'article'), 
    ('Stress Management', 'article'), 
    ('Holistic Health', 'article'), 
    ('Nutrition', 'article'), 
    ('Fitness', 'article'), 
    ('Emotional Well-being', 'article'), 
    ('Self-Care', 'article'), 
    ('Mental Health', 'article'), 
    ('Yoga', 'article'), 
    ('Sleep Health', 'article'), 
    ('Work-Life Balance', 'article'), 
    ('Positive Thinking', 'article'), 
    ('Resilience', 'article'), 
    ('Healthy Habits', 'article'), 
    ('Breathing Techniques', 'article');




    -- Update existing records in public.user_timezones table
    WITH user_timezone_assignments AS (
        SELECT 
            id AS user_id,
            CASE
                WHEN id = creator_id THEN 'UTC+00:00'::public.timezone
                ELSE (timezones[(ROW_NUMBER() OVER (ORDER BY id) % array_length(timezones, 1)) + 1])::public.timezone
            END AS assigned_timezone
        FROM 
            auth.users
    )
    UPDATE public.user_timezones
    SET timezone = uta.assigned_timezone
    FROM user_timezone_assignments uta
    WHERE public.user_timezones.user_id = uta.user_id;
    

    -- Insert playlists for the creator
    INSERT INTO public.spotify_playlists (user_id, id, iframe)
    VALUES 
    (creator_id, uuid_generate_v4(), '<iframe style="border-radius:12px" src="https://open.spotify.com/embed/playlist/0mcuZOIzqlSzL1ikicTnr4?utm_source=generator&playlist=1" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>'),
    (creator_id, uuid_generate_v4(), '<iframe style="border-radius:12px" src="https://open.spotify.com/embed/playlist/0mcuZOIzqlSzL1ikicTnr4?utm_source=generator&playlist=2" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>'),
    (creator_id, uuid_generate_v4(), '<iframe style="border-radius:12px" src="https://open.spotify.com/embed/artist/4KmxYfZjBSyiS1t30dFpZB?utm_source=generator" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>'),
    (creator_id, uuid_generate_v4(), '<iframe style="border-radius:12px" src="https://open.spotify.com/embed/playlist/1llWqBMzdp3rKItC7cTtWY?utm_source=generator" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>'),
    (creator_id, uuid_generate_v4(), '<iframe style="border-radius:12px" src="https://open.spotify.com/embed/playlist/29Sk8fbyg2dSz1PVXtauL1?utm_source=generator" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>')
    ON CONFLICT (iframe) DO NOTHING;

   -- Select all playlist IDs for the creator
    SELECT array_agg(id) INTO playlist_ids
    FROM public.spotify_playlists
    WHERE user_id = creator_id;
    -- Create 10 yoga posts
    FOR i IN 1..10 LOOP
        PERFORM public.create_yoga_content_with_details(
            session_names[i] || ': Yoga Session ' || i,
            lower(replace(session_names[i], ' ', '-')) || '-yoga-session-' || i,
            'Join us for ' || session_names[i] || ', a yoga session designed to bring balance and harmony to your day.',
            format(content_template, 
                session_names[i], 'Yoga', i,
                'yoga', session_names[i],
                session_names[i], 'calming',
                session_names[i], (i % 5) + 1,
                'Balance', 'Calmness, Joy, Resilience',
                'Outdoor Balcony or Patio', 'Full Body',
                'Yoga, Wellness, ' || (CASE WHEN i % 2 = 0 THEN 'Beginner' ELSE 'Intermediate' END),
                'Yoga',
                (CASE 
                    WHEN i % 5 = 0 THEN 'Hatha'
                    WHEN i % 5 = 1 THEN 'Vinyasa'
                    WHEN i % 5 = 2 THEN 'Yin'
                    WHEN i % 5 = 3 THEN 'Restorative'
                    ELSE 'Ashtanga'
                END),
                session_names[i], 'yoga'
            ),
            image_urls[i],
            ARRAY (SELECT name FROM public.tags WHERE post_type = 'yoga' ORDER BY RANDOM() LIMIT 4),
            'public'::publish_status_enum,
            'video'::media_type_enum,
            (30 + (i * 5) || ' minutes')::interval,
            9.99 + (i * 0.5),
            'sA1ki006wrtZ3mIoQhmchFggNVt6ovT8WrbzHU6xprUU',
            ARRAY['stress relief', 'flexibility', (CASE WHEN i % 2 = 0 THEN 'strength' ELSE 'balance' END)],
            playlist_ids,
            'Jane Doe',
            session_names[i] || ',Energy Flow',
            (i % 5) + 1,
            'Balance',
            'Calmness,Joy,Resilience',
            'Outdoor Balcony or Patio',
            'Full Body',
            ARRAY['yoga mat', 'blocks', (CASE WHEN i % 2 = 0 THEN 'strap' ELSE 'blanket' END)],
            (CASE 
                WHEN i % 5 = 0 THEN 'Hatha'
                WHEN i % 5 = 1 THEN 'Vinyasa'
                WHEN i % 5 = 2 THEN 'Yin'
                WHEN i % 5 = 3 THEN 'Restorative'
                ELSE 'Ashtanga'
            END),
            'Root Chakra (Muladhara),Sacral Chakra (Svadhishthana),' || 
            (CASE 
                WHEN i % 3 = 0 THEN 'Solar Plexus Chakra (Manipura)'
                WHEN i % 3 = 1 THEN 'Heart Chakra (Anahata)'
                ELSE 'Throat Chakra (Vishuddha)'
            END),
            creator_id
        );
    END LOOP;

    -- Create 10 dance posts
    FOR i IN 1..10 LOOP
        PERFORM public.create_dance_content_with_details(
            session_names[i] || ': Dance Session ' || i,
            lower(replace(session_names[i], ' ', '-')) || '-dance-session-' || i,
            'Join us for ' || session_names[i] || ', a dance session designed to express yourself through movement.',
            format(content_template, 
                session_names[i], 'Dance', i,
                'dance', session_names[i],
                session_names[i], 'energizing',
                session_names[i], (i % 5) + 1,
                'Expression', 'Joy, Confidence, Freedom',
                'Studio or Open Space', 'Full Body',
                'Dance, Fitness, ' || (CASE WHEN i % 2 = 0 THEN 'Beginner' ELSE 'Intermediate' END),
                'Dance',
                (CASE 
                    WHEN i % 5 = 0 THEN 'Contemporary'
                    WHEN i % 5 = 1 THEN 'Hip Hop'
                    WHEN i % 5 = 2 THEN 'Jazz'
                    WHEN i % 5 = 3 THEN 'Ballet'
                    ELSE 'Freestyle'
                END),
                session_names[i], 'dance'
            ),
            image_urls[i],
            ARRAY(
                SELECT name 
                FROM public.tags 
                WHERE post_type = 'dance' 
                ORDER BY RANDOM() 
                LIMIT 4
            ),
            'public'::publish_status_enum,
            'video'::media_type_enum,
            (45 + (i * 5) || ' minutes')::interval,
            12.99 + (i * 0.5),
            'sA1ki006wrtZ3mIoQhmchFggNVt6ovT8WrbzHU6xprUU',
            ARRAY['expression', 'rhythm', (CASE WHEN i % 2 = 0 THEN 'cardio' ELSE 'coordination' END)],
            playlist_ids,
            'Jane Doe',
            session_names[i] || ',Rhythmic Flow',
            (i % 5) + 1,
            'Expression',
            'Joy,Confidence,Freedom',
            'Studio or Open Space',
            'Full Body',
            ARRAY['comfortable shoes', 'water bottle'],
            (i % 2 = 0),
            creator_id
        );
    END LOOP;

    -- Create 10 neuro flow posts
    FOR i IN 1..10 LOOP
        PERFORM public.create_neuroflow_content_with_details(
            session_names[i] || ': Neuro Flow Session ' || i,
            lower(replace(session_names[i], ' ', '-')) || '-neuro-flow-session-' || i,
            'Join us for ' || session_names[i] || ', a neuro flow session designed to optimize your brain-body connection.',
            format(content_template, 
                session_names[i], 'Neuro Flow', i,
                'neuro flow', session_names[i],
                session_names[i], 'transformative',
                session_names[i], (i % 5) + 1,
                'Mind-Body Connection', 'Focus, Clarity, Adaptability',
                'Quiet Room', 'Brain and Nervous System',
                'Neuro Flow, Wellness, ' || (CASE WHEN i % 2 = 0 THEN 'Beginner' ELSE 'Intermediate' END),
                'Neuro Flow',
                (CASE 
                    WHEN i % 5 = 0 THEN 'Meditation'
                    WHEN i % 5 = 1 THEN 'Breathwork'
                    WHEN i % 5 = 2 THEN 'Visualization'
                    WHEN i % 5 = 3 THEN 'Movement'
                    ELSE 'Integration'
                END),
                session_names[i], 'neuro flow'
            ),
            image_urls[i],
            ARRAY (SELECT name FROM public.tags WHERE post_type = 'neuro_flow' ORDER BY RANDOM() LIMIT 4),
            'public'::publish_status_enum,
            'video'::media_type_enum,
            (40 + (i * 5) || ' minutes')::interval,
            14.99 + (i * 0.5),
            'sA1ki006wrtZ3mIoQhmchFggNVt6ovT8WrbzHU6xprUU',
            ARRAY['brain optimization', 'neuroplasticity', (CASE WHEN i % 2 = 0 THEN 'focus' ELSE 'creativity' END)],
            playlist_ids,
            'Jane Doe',
            session_names[i] || ',Neural Harmony',
            (i % 5) + 1,
            'Mind-Body Connection',
            'Focus,Clarity,Adaptability',
            'Quiet Room',
            'Brain and Nervous System',
            ARRAY['meditation cushion', 'journal'],
            'Neuroplasticity techniques',
            'Cognitive enhancement',
            'Improved neural pathways',
            creator_id
        );
    END LOOP;


    -- Create sample locations
    INSERT INTO public.locations (name, description, image_url, line_1, line_2, city, country, postcode, maps_link, user_id)
    VALUES 
        ('Parisian Retreat Center', 'A charming venue in the heart of Paris, perfect for cultural and artistic events', 'https://images.unsplash.com/photo-1525218291292-e46d2a90f77c?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZnJhbmNlfGVufDB8fDB8fHww', '15 Rue de la Paix', NULL, 'Paris', 'France', '75002', 'https://goo.gl/maps/parisretreat', creator_id),
        ('Zen Meditation Temple', 'A serene and traditional meditation space for spiritual retreats and workshops', 'https://images.unsplash.com/photo-1703510293022-9c62d7874e2b?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTh8fG1lZGl0YXRpb24lMjB0ZW1wbGV8ZW58MHx8MHx8fDA%3D', '123 Tranquility Lane', NULL, 'Kyoto', 'Japan', '605-0862', 'https://goo.gl/maps/zentemple', creator_id),
        ('Mountain Retreat Lodge', 'A stunning mountain lodge surrounded by nature, ideal for wellness and team-building events', 'https://images.unsplash.com/photo-1714303282652-58ad0218b411?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTF8fG1lZGl0YXRpb24lMjB0ZW1wbGV8ZW58MHx8MHx8fDA%3D', '789 Alpine Way', 'Suite 100', 'Aspen', 'USA', '81611', 'https://goo.gl/maps/mountainlodge', creator_id),
        ('Beachfront Conference Center', 'A modern conference facility with breathtaking ocean views', 'https://images.unsplash.com/photo-1714978472538-641500c65566?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTJ8fG1lZGl0YXRpb24lMjB0ZW1wbGV8ZW58MHx8MHx8fDA%3D', '1001 Coastal Highway', NULL, 'Malibu', 'USA', '90265', 'https://goo.gl/maps/beachcenter', creator_id),
        ('Urban Innovation Hub', 'Cutting-edge facility in the city center for tech events and creative workshops', 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3', '50 Tech Avenue', 'Floor 10', 'San Francisco', 'USA', '94105', 'https://goo.gl/maps/techhub', creator_id);

    -- Select location IDs
    SELECT ARRAY(SELECT id FROM public.locations WHERE user_id = creator_id) INTO v_location_ids;

   -- Create multiple events
    FOR i IN 1..10 LOOP
        v_result := public.create_event_with_details(
            -- Title
            v_event_themes[i] || ' ' || TO_CHAR(CURRENT_DATE + (i || ' months')::INTERVAL, 'YYYY'),
            -- Slug (sanitized)
            sanitize_slug(v_event_themes[i] || '-' || TO_CHAR(CURRENT_DATE + (i || ' months')::INTERVAL, 'YYYY')),
            -- Description
            'Join us for the ' || v_event_themes[i] || ' event of the year! Experience cutting-edge insights, network with industry leaders, and enjoy a day filled with innovation and inspiration.',
            -- Content
            format('{"type":"doc","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Welcome to our %s event! This will be an unforgettable experience filled with learning, networking, and fun. Get ready for an exciting program of speakers, workshops, and activities."}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Our event will feature:"}]},{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Keynote speeches from industry experts"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Interactive workshops and panel discussions"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Networking opportunities with like-minded professionals"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Showcases of the latest innovations and technologies"}]}]}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Don''t miss this opportunity to be part of something extraordinary!"}]}]}', v_event_themes[i]),
            -- Thumbnail URL
            event_image_urls[1 + (i % array_length(event_image_urls, 1))],
            -- Tags
            ARRAY (SELECT name FROM public.tags WHERE post_type = 'event' ORDER BY RANDOM() LIMIT 4),
            -- Status
            'public'::publish_status_enum,
            -- Event Type
            v_event_types[1 + (i % 3)],
            -- Event Dates (4 dates for each event)
            ARRAY[
                (NULL::UUID, random_future_date(30), random_future_date(30) + '4 hours'::INTERVAL)::event_date_input,
                (NULL::UUID, random_future_date(60), random_future_date(60) + '5 hours'::INTERVAL)::event_date_input,
                (NULL::UUID, random_future_date(120), random_future_date(120) + '6 hours'::INTERVAL)::event_date_input,
                (NULL::UUID, random_future_date(180), random_future_date(180) + '7 hours'::INTERVAL)::event_date_input
            ],
            -- Tickets
            ARRAY[
                (NULL::UUID, 'Early Bird', 'Get your tickets early and save! Limited availability.', 50.00, 100, 30)::ticket_input,
                (NULL::UUID, 'Regular', 'Standard admission to the event. Access to all main sessions and exhibits.', 75.00, 200, 7)::ticket_input,
                (NULL::UUID, 'VIP', 'Get the full VIP experience with exclusive access and perks.', 150.00, 50, 1)::ticket_input
            ],
            -- Room Name (for online/hybrid events)
            CASE WHEN v_event_types[1 + (i % 3)] IN ('online', 'hybrid') THEN 
                'room_' || sanitize_slug(v_event_themes[i])
            ELSE NULL END,
            -- Room Password (optional)
            CASE WHEN v_event_types[1 + (i % 3)] IN ('online', 'hybrid') THEN 
                'pass_' || sanitize_slug(v_event_themes[i])
            ELSE NULL END,
            -- Location ID (for in-person/hybrid events)
            CASE WHEN v_event_types[1 + (i % 3)] IN ('in-person', 'hybrid') THEN 
                v_location_ids[(i % array_length(v_location_ids, 1)) + 1]
            ELSE NULL END,
            -- creator id
            creator_id
        );

        RAISE NOTICE 'Created event: %', v_result;
    END LOOP;


    -- Create multiple articles
    FOR i IN 1..10 LOOP
        -- Generate unique content for each article
        v_content := format(
            '{"type":"doc","content":[
                {"type":"heading","attrs":{"level":1},"content":[{"type":"text","text":"%1$s"}]},
                {"type":"paragraph","content":[{"type":"text","text":"In recent years, %2$s has become an increasingly important topic in both academic and public discourse. This article delves into the various aspects of %2$s, exploring its history, current developments, and potential future implications."}]},
                
                {"type":"heading","attrs":{"level":2},"content":[{"type":"text","text":"Background and History"}]},
                {"type":"paragraph","content":[{"type":"text","text":"The concept of %2$s first emerged in the mid-20th century, but its roots can be traced back to earlier scientific and philosophical ideas. Initially, %2$s was primarily a theoretical concept, but over time it has evolved into a practical field with wide-ranging applications."}]},
                {"type":"paragraph","content":[{"type":"text","text":"Key milestones in the development of %2$s include:"}]},
                {"type":"bulletList","content":[
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"1950s: Early theoretical foundations laid"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"1970s: First practical applications emerge"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"1990s: Rapid advancement due to technological progress"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"2000s onwards: Integration into everyday life and business"}]}]}
                ]},
                
                {"type":"heading","attrs":{"level":2},"content":[{"type":"text","text":"Current State of %1$s"}]},
                {"type":"paragraph","content":[{"type":"text","text":"Today, %2$s plays a crucial role in various sectors, including technology, healthcare, education, and environmental science. Recent advancements have led to breakthroughs in areas such as:"}]},
                {"type":"bulletList","content":[
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Advanced data analysis and prediction models"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Improved efficiency in resource management"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Novel approaches to solving complex societal issues"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Enhanced understanding of human behavior and cognition"}]}]}
                ]},
                
                {"type":"heading","attrs":{"level":2},"content":[{"type":"text","text":"Key Aspects of %1$s"}]},
                {"type":"paragraph","content":[{"type":"text","text":"Several key aspects define the current landscape of %2$s:"}]},
                {"type":"bulletList","content":[
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Interdisciplinary nature: %2$s combines insights from multiple fields"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Rapid evolution: New discoveries and applications emerge frequently"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Global impact: %2$s affects societies and economies worldwide"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Ethical considerations: The advancement of %2$s raises important moral questions"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Technological dependencies: Progress in %2$s is often tied to technological advancements"}]}]}
                ]},
                
                {"type":"heading","attrs":{"level":2},"content":[{"type":"text","text":"Challenges and Controversies"}]},
                {"type":"paragraph","content":[{"type":"text","text":"Despite its promise, %2$s is not without challenges and controversies. Some of the main issues include:"}]},
                {"type":"bulletList","content":[
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Privacy concerns related to data collection and use"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Potential job displacement due to automation"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Unequal access to benefits across different socioeconomic groups"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Debates over regulation and governance of %2$s technologies"}]}]}
                ]},
                
                {"type":"heading","attrs":{"level":2},"content":[{"type":"text","text":"Future Prospects"}]},
                {"type":"paragraph","content":[{"type":"text","text":"Looking ahead, the future of %2$s appears both exciting and challenging. Experts predict several trends:"}]},
                {"type":"bulletList","content":[
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Increased integration of %2$s in everyday life"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Development of more sophisticated and autonomous systems"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Greater focus on ethical and sustainable applications"}]}]},
                    {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Potential for groundbreaking discoveries in related fields"}]}]}
                ]},
                
                {"type":"heading","attrs":{"level":2},"content":[{"type":"text","text":"Conclusion"}]},
                {"type":"paragraph","content":[{"type":"text","text":"%1$s represents a fascinating and rapidly evolving field that has the potential to reshape many aspects of our world. As we continue to explore and develop %2$s, it is crucial to balance innovation with ethical considerations and societal impact. The coming years will undoubtedly bring new discoveries, applications, and challenges in this exciting domain."}]},
                
                {"type":"paragraph","content":[{"type":"text","text":"As research progresses and technology advances, %2$s will likely play an increasingly significant role in shaping our future. It is an area that deserves continued attention, study, and thoughtful discussion to ensure that its benefits are maximized while potential risks are mitigated."}]}
            ]}',
            article_themes[i],  -- %1$s: Used for title case
            lower(article_themes[i])  -- %2$s: Used for sentence case
        );

        -- Generate description
        v_description := 'An in-depth look at ' || article_themes[i] || ' and its implications for our future.';

        v_result_article := public.create_article_content_with_details(
            -- Title
            article_themes[i],
            -- Slug (sanitized)
            sanitize_slug(article_themes[i]),
            -- Description
            v_description,
            -- Content
            v_content,
            -- Thumbnail URL (using event images as placeholders)
            event_image_urls[1 + (i % array_length(event_image_urls, 1))],
            -- Tags
            ARRAY (SELECT name FROM public.tags WHERE post_type = 'article' ORDER BY RANDOM() LIMIT 4),
            -- Status
            'public'::publish_status_enum,
            -- creator id
            creator_id
        );

        RAISE NOTICE 'Created article: %', v_result_article;
    END LOOP;

    -- Create multiple services
    FOR i IN 1..10 LOOP
        -- Generate content (using a simplified version of the provided content)
        v_content := format(
            '{"type":"doc","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Embark on a journey of self-discovery and optimization with our exclusive %s. This innovative approach combines cutting-edge techniques to unlock your full potential and elevate your overall well-being."}]},{"type":"heading","attrs":{"textAlign":"left","level":2},"content":[{"type":"text","text":"Session Overview"}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"In this personalized session, you''ll work one-on-one with a certified practitioner to explore and expand your potential. Using a combination of guided exercises, targeted discussions, and real-time feedback, you''ll learn valuable techniques and strategies."}]},{"type":"heading","attrs":{"textAlign":"left","level":2},"content":[{"type":"text","text":"What to Expect"}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Your session will be tailored to your specific needs and goals, focusing on %s and related aspects of personal development."}]}]}',
            service_themes[i],
            lower(service_themes[i])
        );

        -- Generate description
        v_description := 'Experience the transformative power of ' || service_themes[i] || '. This personalized session is designed to help you achieve optimal well-being and unlock your full potential.';

        v_result_service := public.create_service_content_with_details(
            -- Title
            service_themes[i],
            -- Slug (sanitized)
            sanitize_slug(service_themes[i]),
            -- Description
            v_description,
            -- Content
            v_content,
            -- Thumbnail URL (using event images as placeholders)
            event_image_urls[1 + (i % array_length(event_image_urls, 1))],
            -- Tags
            ARRAY (SELECT name FROM public.tags WHERE post_type = 'service' ORDER BY RANDOM() LIMIT 4),
            -- Status
            'public'::publish_status_enum,
            -- Location ID (cycling through available locations)
            v_location_ids[1 + (i % array_length(v_location_ids, 1))],
            -- Price (varying between 30 and 100)
            30 + (i * 7)::NUMERIC(10, 2),
            -- Duration (varying between 30 and 120 minutes)
            ((30 + (i * 10)) || ' minutes')::INTERVAL,
            -- Type (cycling through online, in-person, hybrid)
            (CASE 
                WHEN i % 3 = 0 THEN 'online'
                WHEN i % 3 = 1 THEN 'in-person'
                ELSE 'hybrid'
            END)::public.event_type_enum,
            creator_id
        );

        RAISE NOTICE 'Created service: %', v_result_service;
    END LOOP;

    insert into public.waitlists (title, description) values ('become_a_creator', 'wait list for those who want to become a creator on the platform');    
END $$;