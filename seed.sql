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
    current_user_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- brucemckayone@gmail.com
    current_creator_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- same user is also a creator
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
    v_event_themes TEXT[] := ARRAY['Wellness Summit', 'Mindfulness Retreat', 'Yoga Symposium', 'Health Conference', 'Spiritual Festival', 'Meditation Workshop', 'Healing Retreat', 'Transformation Festival', 'Consciousness Summit', 'Holistic Expo'];
    v_event_types event_type_enum[] := ARRAY['in-person', 'online', 'hybrid'];
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

    meditation_names TEXT[] := ARRAY[
        'Mindful Breathing', 'Body Scan Relaxation', 'Loving-Kindness Meditation',
        'Mindfulness of Thoughts', 'Zen Meditation', 'Transcendental Meditation',
        'Chakra Balancing', 'Guided Visualization', 'Mantra Meditation', 'Walking Meditation'
    ];
    meditation_types TEXT[] := ARRAY[
        'Mindfulness', 'Body Scan', 'Loving-Kindness',
        'Mindfulness', 'Zen', 'Transcendental',
        'Chakra', 'Visualization', 'Mantra', 'Movement'
    ];
    meditation_themes TEXT[] := ARRAY[
        'Stress Relief', 'Relaxation', 'Compassion',
        'Mental Clarity', 'Focus', 'Self-Discovery',
        'Energy Balance', 'Healing', 'Inner Peace', 'Presence'
    ];
    meditation_focuses TEXT[] := ARRAY[
        'Breath', 'Body', 'Emotions',
        'Thoughts', 'Present Moment', 'Mantra',
        'Energy Centers', 'Imagery', 'Sound', 'Movement'
    ];

    v_result_meditation meditation_content_creation_result;

        
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
        CASE WHEN ROW_NUMBER() OVER () = 1 THEN current_creator_id ELSE uuid_generate_v4() END,
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
    WHERE user_id = current_creator_id;

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
    -- Ceremony tags
    ('Sacred Circle', 'ceremony'),
    ('Full Moon Ritual', 'ceremony'),
    ('New Moon Ceremony', 'ceremony'),
    ('Sound Healing', 'ceremony'),
    ('Cacao Ceremony', 'ceremony'),
    ('Fire Ritual', 'ceremony'),
    ('Water Blessing', 'ceremony'),
    ('Shamanic Journey', 'ceremony'),
    ('Sweat Lodge', 'ceremony'),
    ('Breathwork Ceremony', 'ceremony'),
    ('Ancestral Healing', 'ceremony'),
    ('Ecstatic Dance', 'ceremony'),
    ('Tea Ceremony', 'ceremony'),
    ('Vision Quest', 'ceremony'),
    ('Drum Circle', 'ceremony'),
    ('Solstice Celebration', 'ceremony'),
    ('Equinox Ritual', 'ceremony'),
    ('Spiritual Cleansing', 'ceremony'),

    -- article tags 
    ('Spiritual Growth', 'article'),
    ('Meditation', 'article'),
    ('Mindfulness', 'article'),
    ('Energy Healing', 'article'),
    ('Chakra', 'article'),
    ('Sacred Wisdom', 'article'),
    ('Consciousness', 'article'),
    ('Inner Peace', 'article'),
    ('Divine Connection', 'article'),
    ('Soul Journey', 'article'),
    ('Ancient Practices', 'article'),
    ('Spiritual Awakening', 'article'),
    ('Higher Self', 'article'),
    ('Universal Energy', 'article'),
    ('Sacred Space', 'article'),
    ('Spiritual Guidance', 'article'),
    ('Divine Timing', 'article'),
    ('Soul Purpose', 'article'),
    ('Spiritual Community', 'article'),
    ('Sacred Knowledge', 'article');




    -- Update existing records in public.user_timezones table
    WITH user_timezone_assignments AS (
        SELECT 
            id AS user_id,
            CASE
                WHEN id = current_creator_id THEN 'UTC+00:00'::public.timezone
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
    (current_creator_id, uuid_generate_v4(), '<iframe style="border-radius:12px" src="https://open.spotify.com/embed/playlist/0mcuZOIzqlSzL1ikicTnr4?utm_source=generator&playlist=1" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>'),
    (current_creator_id, uuid_generate_v4(), '<iframe style="border-radius:12px" src="https://open.spotify.com/embed/playlist/0mcuZOIzqlSzL1ikicTnr4?utm_source=generator&playlist=2" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>'),
    (current_creator_id, uuid_generate_v4(), '<iframe style="border-radius:12px" src="https://open.spotify.com/embed/artist/4KmxYfZjBSyiS1t30dFpZB?utm_source=generator" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>'),
    (current_creator_id, uuid_generate_v4(), '<iframe style="border-radius:12px" src="https://open.spotify.com/embed/playlist/1llWqBMzdp3rKItC7cTtWY?utm_source=generator" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>'),
    (current_creator_id, uuid_generate_v4(), '<iframe style="border-radius:12px" src="https://open.spotify.com/embed/playlist/29Sk8fbyg2dSz1PVXtauL1?utm_source=generator" width="100%" height="352" frameBorder="0" allowfullscreen="" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>')
    ON CONFLICT (iframe) DO NOTHING;

   -- Select all playlist IDs for the creator
    SELECT array_agg(id) INTO playlist_ids
    FROM public.spotify_playlists
    WHERE user_id = current_creator_id;
    -- Create 10 yoga posts
    FOR i IN 1..10 LOOP
        PERFORM public.create_yoga_content_with_details(
            session_names[i] || ': Yoga Session ' || i,
            lower(replace(session_names[i], ' ', '-')) || '-yoga-session-' || i,
            'Join us for ' || session_names[i] || ', a yoga session designed to center your mind and body.',
            format(content_template, 
                session_names[i], 'Yoga', i,
                'yoga', session_names[i],
                session_names[i], 'centering',
                session_names[i], (i % 5) + 1,
                'Chakra', 'Balance, Peace, Strength',
                'Mat or Comfortable Floor', 'Full Body',
                'Yoga, Wellness, ' || (CASE WHEN i % 2 = 0 THEN 'Beginner' ELSE 'Intermediate' END),
                'Vinyasa',
                (CASE 
                    WHEN i % 5 = 0 THEN 'Hatha'
                    WHEN i % 5 = 1 THEN 'Vinyasa'
                    WHEN i % 5 = 2 THEN 'Yin'
                    WHEN i % 5 = 3 THEN 'Ashtanga'
                    ELSE 'Kundalini'
                END),
                session_names[i], 'yoga'
            ),
            image_urls[i],
            ARRAY (SELECT name FROM public.tags WHERE post_type = 'yoga' ORDER BY RANDOM() LIMIT 4),
            'public'::publish_status_enum,
            'video'::media_type_enum,
            (30 + (i * 5) || ' minutes')::INTERVAL,
            9.99 + (i * 0.5),
            'sA1ki006wrtZ3mIoQhmchFggNVt6ovT8WrbzHU6xprUU',
            ARRAY['flexibility', 'strength', (CASE WHEN i % 2 = 0 THEN 'balance' ELSE 'breathing' END)],
            playlist_ids,
            'Jane Doe',
            session_names[i] || ',Flow State',
            (i % 5) + 1,
            'Chakra',
            'Balance,Peace,Strength',
            'Mat or Comfortable Floor',
            'Full Body',
            ARRAY['yoga mat', 'comfortable clothing'],
            (CASE 
                WHEN i % 5 = 0 THEN 'Hatha'
                WHEN i % 5 = 1 THEN 'Vinyasa'
                WHEN i % 5 = 2 THEN 'Yin'
                WHEN i % 5 = 3 THEN 'Ashtanga'
                ELSE 'Kundalini'
            END),
            'Root Chakra (Muladhara),Sacral Chakra (Svadhishthana),' || 
            (CASE 
                WHEN i % 3 = 0 THEN 'Solar Plexus Chakra (Manipura)'
                WHEN i % 3 = 1 THEN 'Heart Chakra (Anahata)'
                ELSE 'Throat Chakra (Vishuddha)'
            END),
            current_creator_id
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
            (45 + (i * 5) || ' minutes')::INTERVAL,
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
            current_creator_id
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
            (40 + (i * 5) || ' minutes')::INTERVAL,
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
            current_creator_id
        );
    END LOOP;


    -- Create sample locations
    INSERT INTO public.locations (name, description, image_url, line_1, line_2, city, country, postcode, maps_link, user_id)
    VALUES 
        ('Parisian Retreat Center', 'A charming venue in the heart of Paris, perfect for cultural and artistic events', 'https://images.unsplash.com/photo-1525218291292-e46d2a90f77c?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZnJhbmNlfGVufDB8fDB8fHww', '15 Rue de la Paix', NULL, 'Paris', 'France', '75002', 'https://goo.gl/maps/parisretreat', current_creator_id),
        ('Zen Meditation Temple', 'A serene and traditional meditation space for spiritual retreats and workshops', 'https://images.unsplash.com/photo-1703510293022-9c62d7874e2b?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTh8fG1lZGl0YXRpb24lMjB0ZW1wbGV8ZW58MHx8MHx8fDA%3D', '123 Tranquility Lane', NULL, 'Kyoto', 'Japan', '605-0862', 'https://goo.gl/maps/zentemple', current_creator_id),
        ('Mountain Retreat Lodge', 'A stunning mountain lodge surrounded by nature, ideal for wellness and team-building events', 'https://images.unsplash.com/photo-1714303282652-58ad0218b411?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTF8fG1lZGl0YXRpb24lMjB0ZW1wbGV8ZW58MHx8MHx8fDA%3D', '789 Alpine Way', 'Suite 100', 'Aspen', 'USA', '81611', 'https://goo.gl/maps/mountainlodge', current_creator_id),
        ('Beachfront Conference Center', 'A modern conference facility with breathtaking ocean views', 'https://images.unsplash.com/photo-1714978472538-641500c65566?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTJ8fG1lZGl0YXRpb24lMjB0ZW1wbGV8ZW58MHx8MHx8fDA%3D', '1001 Coastal Highway', NULL, 'Malibu', 'USA', '90265', 'https://goo.gl/maps/beachcenter', current_creator_id),
        ('Urban Innovation Hub', 'Cutting-edge facility in the city center for tech events and creative workshops', 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3', '50 Tech Avenue', 'Floor 10', 'San Francisco', 'USA', '94105', 'https://goo.gl/maps/techhub', current_creator_id);

    -- Select location IDs
    SELECT ARRAY(SELECT id FROM public.locations WHERE user_id = current_creator_id) INTO v_location_ids;

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
            current_creator_id
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
            current_creator_id
        );

        RAISE NOTICE 'Created article: %', v_result_article;
    END LOOP;

    -- Create multiple meditations
    FOR i IN 1..10 LOOP
        -- Generate content
        v_content := format(
            '{"type":"doc","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Welcome to %s, a %s meditation session designed to help you focus on %s. This practice will guide you through a %s-minute journey of self-discovery and inner peace."}]},{"type":"heading","attrs":{"textAlign":"left","level":2},"content":[{"type":"text","text":"What to Expect"}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"During this meditation:"}]},{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"You''ll learn techniques to %s"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"We''ll focus on %s to enhance your %s"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"You''ll discover how to integrate %s into your daily life"}]}]}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Remember, there''s no right or wrong way to meditate. Simply follow along and allow yourself to be present in the moment."}]}]}',
            meditation_names[i],
            meditation_types[i],
            meditation_focuses[i],
            (15 + (i * 5))::TEXT,
            (CASE 
                WHEN i % 3 = 0 THEN 'calm your mind'
                WHEN i % 3 = 1 THEN 'relax your body'
                ELSE 'open your heart'
            END),
            lower(meditation_focuses[i]),
            lower(meditation_themes[i]),
            lower(meditation_types[i])
        );

        -- Generate description
        v_description := format('Experience the transformative power of %s with our %s meditation. This %s-minute session focuses on %s, helping you cultivate %s in your daily life.', 
            meditation_names[i], meditation_types[i], (15 + (i * 5))::TEXT, lower(meditation_focuses[i]), lower(meditation_themes[i]));

        v_result_meditation := public.create_meditation_content_with_details(
            meditation_names[i],
            lower(replace(meditation_names[i], ' ', '-')),
            v_description,
            v_content,
            event_image_urls[1 + (i % array_length(event_image_urls, 1))],
            ARRAY (SELECT name FROM public.tags WHERE post_type = 'meditation' ORDER BY RANDOM() LIMIT 4),
            'public'::publish_status_enum,
            'audio'::media_type_enum,
            ((15 + (i * 5)) || ' minutes')::INTERVAL,
            9.99 + (i * 0.5),
            'https://example.com/protected/meditation_' || i || '.mp3',
            playlist_ids,
            meditation_types[i],
            meditation_themes[i],
            meditation_focuses[i],
            current_creator_id
        );

        RAISE NOTICE 'Created meditation: %', v_result_meditation;
    END LOOP;

    -- Create multiple services
    FOR i IN 1..10 LOOP
        v_content := format(
            '{"type":"doc","content":[{"type":"heading","attrs":{"textAlign":"left","level":1},"content":[{"type":"text","text":"%s"}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"This premium service provides personalized guidance to help you achieve optimal mind-body harmony through expert consultation and targeted techniques."}]},{"type":"heading","attrs":{"textAlign":"left","level":2},"content":[{"type":"text","text":"What''s Included"}]},{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"One-on-one personalized session with our expert practitioner"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Comprehensive assessment of your current state and needs"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Customized techniques and practices tailored to your specific goals"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Follow-up resources and recommendations for continued progress"}]}]}]},{"type":"heading","attrs":{"textAlign":"left","level":2},"content":[{"type":"text","text":"Benefits"}]},{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Enhanced mental clarity and cognitive function"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Improved emotional regulation and stress management"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Better integration of mind-body awareness"}]}]},{"type":"listItem","content":[{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Practical tools for ongoing self-improvement"}]}]}]},{"type":"heading","attrs":{"textAlign":"left","level":2},"content":[{"type":"text","text":"How It Works"}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"After booking, you''ll receive a confirmation email with a pre-session questionnaire. This helps us prepare for your specific needs. The session will be conducted via your chosen method (video, phone, or in-person). Following your session, you''ll receive personalized recommendations and resources."}]},{"type":"heading","attrs":{"textAlign":"left","level":2},"content":[{"type":"text","text":"Book Your Session Today"}]},{"type":"paragraph","attrs":{"textAlign":"left"},"content":[{"type":"text","text":"Choose a time that works for you and begin your journey toward enhanced wellbeing and performance."}]}]}',
            service_themes[i]
        );

        v_description := 'Experience the transformative benefits of ' || service_themes[i] || ' with our expert practitioners. This personalized service helps you optimize your mind-body connection.';

        -- Create a location for this service if needed
        v_result_service := public.create_service_content_with_details(
            service_themes[i],
            sanitize_slug(service_themes[i]),
            v_description,
            v_content,
            event_image_urls[1 + (i % array_length(event_image_urls, 1))],
            ARRAY (SELECT name FROM public.tags WHERE post_type = 'service' ORDER BY RANDOM() LIMIT 4),
            'public'::publish_status_enum,
            v_location_ids[1 + (i % array_length(v_location_ids, 1))],
            79.99 + (i * 10.0),
            '60 minutes'::interval,
            (ARRAY['online', 'in-person', 'hybrid']::event_type_enum[])[1 + (i % 3)],
            'pre-approval',
            false,
            24,
            current_creator_id
        );

        RAISE NOTICE 'Created service: %', v_result_service;
    END LOOP;

    insert into public.waitlists (title, description) values ('become_a_creator', 'wait list for those who want to become a creator on the platform');    
    
END $$;

-- Generate sample purchase data for the new purchase system
DO $$
DECLARE
    current_user_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- brucemckayone@gmail.com
    current_creator_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- same user is also a creator
    random_user_ids UUID[];
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
    appointment_slots TIMESTAMP WITH TIME ZONE[];
    used_slots TIMESTAMP WITH TIME ZONE[];
    current_date_index INTEGER := 1;
    
    -- Dates
    start_date TIMESTAMP WITH TIME ZONE;
    next_billing_date TIMESTAMP WITH TIME ZONE;
    last_payment_date TIMESTAMP WITH TIME ZONE;
    
    -- Random user for current purchase
    buyer_id UUID;
BEGIN
    -- Get all user IDs except the creator's for using as buyers
    SELECT ARRAY_AGG(id) INTO random_user_ids
    FROM auth.users
    WHERE id != current_creator_id
    LIMIT 10;
    
    -- Collect content IDs for various post types
    
    -- Get content IDs (on_demand_media)
    SELECT ARRAY_AGG(odm.id) INTO content_ids
    FROM on_demand_media odm
    JOIN posts p ON odm.post_id = p.id
    WHERE p.user_id = current_creator_id::UUID
    LIMIT 20;
    
    -- Get event IDs
    SELECT ARRAY_AGG(e.id) INTO event_ids
    FROM events e
    JOIN posts p ON e.post_id = p.id
    WHERE p.user_id = current_creator_id::UUID
    LIMIT 15;
    
    -- Get service IDs
    SELECT ARRAY_AGG(s.id) INTO service_ids
    FROM services s
    JOIN posts p ON s.post_id = p.id
    WHERE p.user_id = current_creator_id::UUID
    LIMIT 10;
    
    -- Generate purchases data
    
    -- 1. Content purchases (videos, audio, etc.)
    FOR i IN 1..20 LOOP
        -- Skip if we don't have enough content
        IF i > COALESCE(ARRAY_LENGTH(content_ids, 1), 0) THEN
            CONTINUE;
        END IF;
        
        -- Select a random buyer from our user pool
        buyer_id := random_user_ids[1 + (i % array_length(random_user_ids, 1))];
        
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
            buyer_id, current_creator_id::UUID, payment_intent, payment_amount, 'USD',
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
        -- Select a random buyer from our user pool
        buyer_id := random_user_ids[1 + (i % array_length(random_user_ids, 1))];
        
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
        WHERE t.event_id = event_ids[i] AND ed.event_id = event_ids[i]
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
                buyer_id, current_creator_id::UUID, payment_intent, payment_amount, 'USD',
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
    
    -- Generate non-conflicting appointment slots over the next 30 days
    -- Morning slots (10 AM) for each day
    FOR i IN 1..30 LOOP
        appointment_slots := array_append(
            appointment_slots, 
            (CURRENT_DATE + (i || ' days')::INTERVAL + '10:00:00'::TIME)::TIMESTAMP WITH TIME ZONE
        );
    END LOOP;

    -- Afternoon slots (2 PM) for each day
    FOR i IN 1..30 LOOP
        appointment_slots := array_append(
            appointment_slots, 
            (CURRENT_DATE + (i || ' days')::INTERVAL + '14:00:00'::TIME)::TIMESTAMP WITH TIME ZONE
        );
    END LOOP;

    -- Evening slots (6 PM) for each day
    FOR i IN 1..30 LOOP
        appointment_slots := array_append(
            appointment_slots, 
            (CURRENT_DATE + (i || ' days')::INTERVAL + '18:00:00'::TIME)::TIMESTAMP WITH TIME ZONE
        );
    END LOOP;
    
    -- 3. Service appointments with non-conflicting dates
    FOR i IN 1..COALESCE(ARRAY_LENGTH(service_ids, 1), 0) LOOP
        -- Skip if we've run out of available slots
        IF current_date_index > array_length(appointment_slots, 1) THEN
            CONTINUE;
        END IF;
        
        -- Select a random buyer from our user pool
        buyer_id := random_user_ids[1 + (i % array_length(random_user_ids, 1))];
        
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
        
        -- Get a unique appointment slot
        appointment_date := appointment_slots[current_date_index];
        current_date_index := current_date_index + 1;
        
        -- Keep track of used slots
        used_slots := array_append(used_slots, appointment_date);
        
        -- Insert main purchase record
        INSERT INTO public.purchases (
            user_id, owner_id, stripe_payment_intent_id, amount, currency, 
            payment_status, service_id, purchase_type, purchase_date, 
            start_date, end_date, quantity, metadata
        ) VALUES (
            buyer_id, current_creator_id::UUID, payment_intent, payment_amount, 'USD',
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
                (ARRAY['video', 'phone', 'in-person'])[1 + (i % 3)],
                (ARRAY['reading', 'healing', 'coaching', 'consultation'])[1 + (i % 4)],
                CASE
                    WHEN random_status = 'completed' THEN 'confirmed'
                    ELSE 'pending'
                END,
                'Client notes: Looking forward to this session!'
            );
        END IF;
    END LOOP;
    
    -- Extra direct service appointment purchases using actual service IDs with non-conflicting dates
    FOR i IN 1..10 LOOP
        -- Skip if we've run out of available slots
        IF current_date_index > array_length(appointment_slots, 1) THEN
            CONTINUE;
        END IF;
        
        -- Select a random buyer from our user pool
        buyer_id := random_user_ids[1 + (i % array_length(random_user_ids, 1))];
        
        SELECT s.id INTO service_id
        FROM services s
        JOIN posts p ON s.post_id = p.id
        WHERE p.post_type = 'service' AND p.user_id = current_creator_id
        ORDER BY RANDOM()
        LIMIT 1;
        
        -- Skip if no services found
        IF service_id IS NULL THEN
            CONTINUE;
        END IF;
        
        -- Generate purchase for real service
        payment_intent := 'pi_' || MD5(RANDOM()::TEXT);
        payment_amount := (49.99 + (RANDOM() * 100))::NUMERIC(10,2);
        
        -- Get a unique appointment slot
        appointment_date := appointment_slots[current_date_index];
        current_date_index := current_date_index + 1;
        
        -- Keep track of used slots
        used_slots := array_append(used_slots, appointment_date);
        
        -- Insert purchase
        INSERT INTO public.purchases (
            user_id, owner_id, stripe_payment_intent_id, amount, currency, 
            payment_status, service_id, purchase_type, purchase_date, 
            start_date, end_date, quantity, metadata
        ) VALUES (
            buyer_id, current_creator_id::UUID, payment_intent, payment_amount, 'USD',
            'completed', service_id, 'appointment', 
            NOW() - (RANDOM() * 30 || ' days')::INTERVAL,
            appointment_date, appointment_date + (60 || ' minutes')::INTERVAL,
            1, jsonb_build_object('payment_method', 'card')
        ) RETURNING id INTO purchase_id;
        
        -- Insert appointment details
        INSERT INTO public.appointment_purchases (
            purchase_id, service_id, appointment_date, 
            duration, method, service_type, status, notes
        ) VALUES (
            purchase_id, service_id, appointment_date,
            60, -- 60 minutes duration
            (ARRAY['video', 'phone', 'in-person'])[1 + (i % 3)],
            (ARRAY['reading', 'healing', 'coaching', 'consultation'])[1 + (i % 4)],
            'confirmed',
            'Client notes: Looking forward to session #' || i
        );
    END LOOP;
    
    -- 4. Subscriptions
    FOR i IN 1..5 LOOP
        -- Select a random buyer from our user pool
        buyer_id := random_user_ids[1 + (i % array_length(random_user_ids, 1))];
        
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
            buyer_id, current_creator_id::UUID, payment_intent, 'sub_' || MD5(RANDOM()::TEXT),
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
    
    -- Skip article purchases for now to get the DB seeded
    -- Will implement article purchases later
    
    RAISE NOTICE 'Generated purchase data for users with creator: %', current_creator_id;
END $$;


DO $$
DECLARE
    creator_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- brucemckayone@gmail.com
    bronze_tier_id UUID;
    silver_tier_id UUID;
    gold_tier_id UUID;
    platinum_tier_id UUID;
    
    -- Sample content IDs
    v_content_ids UUID[];
    v_post_ids UUID[];
BEGIN
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
    
    -- Create subscription tiers for the creator
    
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
    
    -- Set up content access rules
    
    -- 1. Grant bronze tier access to specific content
    FOR i IN 1..5 LOOP
        -- Only if we have content IDs
        IF array_length(v_content_ids, 1) >= i THEN
            INSERT INTO subscription_content_access (
                creator_id, content_id, tier_key
            ) VALUES (
                creator_id, v_content_ids[i], 'bronze'
            );
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
            );
        END IF;
    END LOOP;
    
    -- 3. Grant gold tier access to all articles
    INSERT INTO subscription_content_access (
        creator_id, post_type, tier_key
    ) VALUES (
        creator_id, 'article', 'gold'
    );
    
    -- 4. Grant platinum tier access to all content types
    INSERT INTO subscription_content_access (
        creator_id, post_type, tier_key
    ) VALUES (
        creator_id, 'yoga', 'platinum'
    ),
    (
        creator_id, 'dance', 'platinum'
    ),
    (
        creator_id, 'neuro_flow', 'platinum'
    ),
    (
        creator_id, 'meditation', 'platinum'
    );
    
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
        -- Get user IDs
        SELECT ARRAY_AGG(id) INTO user_ids
        FROM auth.users
        WHERE id != creator_id
        LIMIT 10;
        
        -- Create subscriptions for 5 users
        FOR i IN 1..5 LOOP
            -- Pick a random user
            random_user_id := user_ids[(i % array_length(user_ids, 1)) + 1];
            
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
        END LOOP;
    END;
    
    RAISE NOTICE 'Created subscription tiers and sample data for creator: %', creator_id;
END $$; 
