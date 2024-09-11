-- Create a table for public profiles
create table profiles (
  id uuid references auth.users on delete cascade not null primary key,
  updated_at timestamp with time zone,
  username text unique,
  full_name text,
  avatar_url text,
  website text,
  constraint username_length check (char_length(username) >= 3)
);
-- Set up Row Level Security (RLS)
-- See https://supabase.com/docs/guides/auth/row-level-security for more details.
alter table profiles
  enable row level security;

create policy "Public profiles are viewable by everyone." on profiles
  for select using (true);

create policy "Users can insert their own profile." on profiles
  for insert with check (auth.uid() = id);

create policy "Users can update own profile." on profiles
  for update using (auth.uid() = id);

-- Create user roles table
CREATE TABLE public.user_roles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster role lookups
CREATE INDEX idx_user_roles_role ON public.user_roles(role);

    -- 1. Create a function to update auth.users metadata
CREATE OR REPLACE FUNCTION public.update_auth_user_role()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the auth.users metadata
    UPDATE auth.users
    SET raw_user_meta_data = 
        COALESCE(raw_user_meta_data, '{}'::jsonb) || 
        jsonb_build_object('user_role', NEW.role::text)
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create a trigger on user_roles table
CREATE TRIGGER sync_user_role_to_auth
AFTER INSERT OR UPDATE OF role ON public.user_roles
FOR EACH ROW
EXECUTE FUNCTION public.update_auth_user_role();

-- 3. Modify the custom_access_token_hook function
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    claims jsonb;
    user_role public.user_role;
BEGIN
    -- Fetch the user role from the auth.users metadata
    SELECT (raw_user_meta_data->>'user_role')::public.user_role 
    INTO user_role 
    FROM auth.users 
    WHERE id = (event->>'user_id')::uuid;

    claims := event->'claims';
    IF user_role IS NOT NULL THEN
        -- Set the claim
        claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
    ELSE
        claims := jsonb_set(claims, '{user_role}', '"user"');
    END IF;

    -- Update the 'claims' object in the original event
    event := jsonb_set(event, '{claims}', claims);

    -- Return the modified event
    RETURN event;
END;
$$;

-- 4. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.update_auth_user_role TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook FROM authenticated, anon, public;
GRANT ALL ON TABLE public.user_roles TO supabase_auth_admin;
REVOKE ALL ON TABLE public.user_roles FROM authenticated, anon, public;

-- 5. Create RLS policy for user_roles table
CREATE POLICY "Allow auth admin to manage user roles" ON public.user_roles
AS PERMISSIVE FOR ALL
TO supabase_auth_admin
USING (true)
WITH CHECK (true);

-- 6. Enable RLS on user_roles table
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;


CREATE OR REPLACE FUNCTION public.iana_to_utc_offset(iana_timezone TEXT)
RETURNS public.timezone AS $$
DECLARE
    utc_offset TEXT;
BEGIN
    -- This is a simplified conversion. In a real-world scenario, you'd want to handle daylight saving time and more complex cases.
    SELECT COALESCE(
        (SELECT concat('UTC', regexp_replace(abbrev, 'UTC', ''))
         FROM pg_timezone_names
         WHERE name = iana_timezone),
        'UTC+00:00'
    ) INTO utc_offset;

    -- Ensure the result is a valid public.timezone enum value
    RETURN utc_offset::public.timezone;
EXCEPTION
    WHEN others THEN
        -- If conversion fails, return UTC+00:00
        RETURN 'UTC+00:00'::public.timezone;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- 8. Create a trigger on auth.users for new user signup
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 9. Backfill existing users (if needed)
INSERT INTO public.user_roles (user_id, role)
SELECT id, COALESCE((raw_user_meta_data->>'user_role')::public.user_role, 'user'::public.user_role)
FROM auth.users
ON CONFLICT (user_id) DO NOTHING;


-- Create function to update 'updated_at' column
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to update 'updated_at' column
CREATE TRIGGER update_user_roles_modtime
    BEFORE UPDATE ON public.user_roles
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- Set up Storage!
insert into storage.buckets (id, name)
  values ('avatars', 'avatars');

-- Set up access controls for storage.
-- See https://supabase.com/docs/guides/storage#policy-examples for more details.
create policy "Avatar images are publicly accessible." on storage.objects
  for select using (bucket_id = 'avatars');

create policy "Anyone can upload an avatar." on storage.objects
  for insert with check (bucket_id = 'avatars');