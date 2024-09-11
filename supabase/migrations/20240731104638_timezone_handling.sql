
CREATE TABLE public.user_timezones (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    timezone TEXT NOT NULL DEFAULT 'UTC',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster lookups
CREATE INDEX idx_user_timezones_timezone ON public.user_timezones(timezone);

CREATE OR REPLACE FUNCTION public.update_auth_user_timezone()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the auth.users metadata
    UPDATE auth.users
    SET raw_user_meta_data = 
        COALESCE(raw_user_meta_data, '{}'::jsonb) || 
        jsonb_build_object('user_timezone', NEW.timezone)
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER sync_user_timezone_to_auth
AFTER INSERT OR UPDATE OF timezone ON public.user_timezones
FOR EACH ROW
EXECUTE FUNCTION public.update_auth_user_timezone();

CREATE TRIGGER update_user_timezones_modtime
    BEFORE UPDATE ON public.user_timezones
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE OR REPLACE FUNCTION public.set_user_timezone_claim(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    claims jsonb;
    user_timezone public.timezone;
BEGIN
    -- Fetch the user timezone from the auth.users metadata
    SELECT (raw_user_meta_data->>'timezone')::public.timezone
    INTO user_timezone
    FROM auth.users 
    WHERE id = (event->>'user_id')::uuid;

    claims := event->'claims';
    IF user_timezone IS NOT NULL THEN
        -- Set the timezone claim
        claims := jsonb_set(claims, '{user_timezone}', to_jsonb(user_timezone::text));
    ELSE
        claims := jsonb_set(claims, '{user_timezone}', '"UTC+00:00"');
    END IF;

    -- Update the 'claims' object in the original event
    event := jsonb_set(event, '{claims}', claims);

    -- Return the modified event
    RETURN event;
END;
$$;
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT ALL ON TABLE public.user_timezones TO supabase_auth_admin;
REVOKE ALL ON TABLE public.user_timezones FROM authenticated, anon, public;

CREATE POLICY "Allow auth admin to manage user timezones" ON public.user_timezones
AS PERMISSIVE FOR ALL
TO supabase_auth_admin
USING (true)
WITH CHECK (true);

ALTER TABLE public.user_timezones ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.user_timezones FROM authenticated, anon, public;


-- Create the function
CREATE OR REPLACE FUNCTION public.update_user_timezone(new_timezone TEXT)
RETURNS VOID AS $$
DECLARE
    valid_timezone BOOLEAN;
    current_user_id UUID;
BEGIN
    -- Get the current user's ID
    current_user_id := auth.uid();

    -- Check if there is a logged-in user
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'No authenticated user found';
    END IF;

    -- Check if the new_timezone is valid
    SELECT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumtypid = 'public.timezone'::regtype
        AND enumlabel = new_timezone
    ) INTO valid_timezone;

    IF NOT valid_timezone THEN
        RAISE EXCEPTION 'Invalid timezone: %', new_timezone;
    END IF;

    -- Update the user's metadata
    UPDATE auth.users
    SET raw_user_meta_data = 
        COALESCE(raw_user_meta_data, '{}'::jsonb) || 
        jsonb_build_object('timezone', new_timezone)
    WHERE id = current_user_id;

    -- Also update the user_timezones table if you have one
    INSERT INTO public.user_timezones (user_id, timezone)
    VALUES (current_user_id, new_timezone::public.timezone)
    ON CONFLICT (user_id) 
    DO UPDATE SET timezone = EXCLUDED.timezone::public.timezone;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.update_user_timezone(TEXT) TO authenticated;

CREATE POLICY "Users can update their own timezone" 
ON auth.users
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);