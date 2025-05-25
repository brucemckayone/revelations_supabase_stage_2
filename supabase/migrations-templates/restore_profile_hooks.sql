-- =============================================================================
-- RESTORE PROFILE HOOKS - MISSING TRIGGER FOR NEW USER SETUP
-- =============================================================================
-- This template restores the critical trigger that sets up profiles, user roles,
-- and timezones when new users sign up.


-- Create the trigger that calls handle_new_user when a new user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE PROCEDURE public.handle_new_user();

COMMENT ON TRIGGER on_auth_user_created ON auth.users IS 
'Automatically creates profile, user role, and timezone when a new user signs up';

-- Verify the handle_new_user function exists and is correct
-- (This should already exist from the init schema, but let's make sure it's correct)
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
    user_timezone public.timezone;
    iana_timezone TEXT;
BEGIN
    -- Insert into profiles
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');

    -- Set default user role
    INSERT INTO public.user_roles (user_id, role)
    VALUES (new.id, 'user');

    -- Check if user already has a timezone in metadata
    iana_timezone := new.raw_user_meta_data->>'timezone';

    -- Convert IANA timezone to UTC offset
    IF iana_timezone IS NOT NULL THEN
        BEGIN
            user_timezone := public.iana_to_utc_offset(iana_timezone);
        EXCEPTION
            WHEN others THEN
                -- If conversion fails, use UTC+00:00
                user_timezone := 'UTC+00:00'::public.timezone;
        END;
    ELSE
        user_timezone := 'UTC+00:00'::public.timezone;
    END IF;

    -- Update user metadata with UTC offset timezone
    UPDATE auth.users
    SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object('timezone', user_timezone::text)
    WHERE id = new.id;

    -- Insert into user_timezones table
    INSERT INTO public.user_timezones (user_id, timezone)
    VALUES (new.id, user_timezone);

    RETURN new;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS 
'Sets up user profile, role, and timezone when a new user signs up. Called by trigger on auth.users.'; 