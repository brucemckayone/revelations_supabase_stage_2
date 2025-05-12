-- Minimal seed file to create admin user for testing notification system

DO $$
DECLARE
    admin_user_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- brucemckayone@gmail.com
BEGIN
    -- Create admin user in auth.users table
    INSERT INTO auth.users (
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
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        admin_user_id,
        'authenticated',
        'authenticated',
        'brucemckayone@gmail.com',
        crypt('password123', gen_salt('bf')),
        current_timestamp,
        current_timestamp,
        current_timestamp,
        '{"provider":"email","providers":["email"]}',
        jsonb_build_object(
            'name', 'Bruce McKay',
            'email', 'brucemckayone@gmail.com',
            'picture', 'https://lh3.googleusercontent.com/a/ACg8ocIvrEMEKLc-Mp_7ejLgVvdkg_fs2z_gU3p928FoGv1aAVpX-Dtv=s96-c',
            'timezone', 'UTC+00:00',
            'full_name', 'Bruce McKay',
            'user_role', 'admin',
            'avatar_url', 'https://lh3.googleusercontent.com/a/ACg8ocIvrEMEKLc-Mp_7ejLgVvdkg_fs2z_gU3p928FoGv1aAVpX-Dtv=s96-c',
            'user_timezone', 'UTC+00:00',
            'email_verified', true,
            'phone_verified', false
        ),
        current_timestamp,
        current_timestamp,
        '',
        '',
        '',
        ''
    ) ON CONFLICT (id) DO UPDATE SET 
        raw_user_meta_data = jsonb_build_object(
            'name', 'Bruce McKay',
            'email', 'brucemckayone@gmail.com',
            'picture', 'https://lh3.googleusercontent.com/a/ACg8ocIvrEMEKLc-Mp_7ejLgVvdkg_fs2z_gU3p928FoGv1aAVpX-Dtv=s96-c',
            'timezone', 'UTC+00:00',
            'full_name', 'Bruce McKay',
            'user_role', 'admin',
            'avatar_url', 'https://lh3.googleusercontent.com/a/ACg8ocIvrEMEKLc-Mp_7ejLgVvdkg_fs2z_gU3p928FoGv1aAVpX-Dtv=s96-c',
            'user_timezone', 'UTC+00:00',
            'email_verified', true,
            'phone_verified', false
        );

    -- Create email identity for admin user
    INSERT INTO auth.identities (
        id,
        provider_id,
        user_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        uuid_generate_v4(),
        uuid_generate_v4(),
        admin_user_id,
        jsonb_build_object('sub', admin_user_id::text, 'email', 'brucemckayone@gmail.com'),
        'email',
        current_timestamp,
        current_timestamp,
        current_timestamp
    ) ON CONFLICT (provider, provider_id) DO NOTHING;

    -- Set admin role in user_roles table
    INSERT INTO public.user_roles (user_id, role)
    VALUES (admin_user_id, 'admin')
    ON CONFLICT (user_id) DO UPDATE SET role = 'admin';

    -- Insert into profiles table if needed
    INSERT INTO public.profiles (id, full_name, username)
    VALUES (admin_user_id, 'Bruce McKay', 'brucemckay')
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Admin user created/updated with ID: %', admin_user_id;
END $$; 