-- Function to update user metadata when onboarding is completed
CREATE OR REPLACE FUNCTION public.update_auth_user_onboarding_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Only execute if completed_at is being set (wasn't set before, now it is)
    IF (OLD.completed_at IS NULL AND NEW.completed_at IS NOT NULL) THEN
        -- Update the auth.users metadata with onboarding completion status
        UPDATE auth.users
        SET raw_user_meta_data = 
            COALESCE(raw_user_meta_data, '{}'::jsonb) || 
            jsonb_build_object(
                'onboarding_completed', true,
                'onboarding_completed_at', NEW.completed_at
            )
        WHERE id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger on onboarding_progress table
CREATE TRIGGER sync_onboarding_status_to_auth
AFTER UPDATE OF completed_at ON public.onboarding_progress
FOR EACH ROW
EXECUTE FUNCTION public.update_auth_user_onboarding_status();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.update_auth_user_onboarding_status TO supabase_auth_admin;

-- Add onboarding status to claims in the custom_access_token_hook function
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
    onboarding_completed boolean;
BEGIN
    -- Fetch data from auth.users metadata
    SELECT 
        (raw_user_meta_data->>'user_role')::public.user_role,
        (raw_user_meta_data->>'onboarding_completed')::boolean
    INTO 
        user_role, onboarding_completed
    FROM auth.users 
    WHERE id = (event->>'user_id')::uuid;

    claims := event->'claims';
    
    -- Set user role claim
    IF user_role IS NOT NULL THEN
        claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
    ELSE
        claims := jsonb_set(claims, '{user_role}', '"user"');
    END IF;

    -- Set onboarding status claim
    IF onboarding_completed IS NOT NULL THEN
        claims := jsonb_set(claims, '{onboarding_completed}', to_jsonb(onboarding_completed));
    ELSE
        claims := jsonb_set(claims, '{onboarding_completed}', 'false');
    END IF;

    -- Update the 'claims' object in the original event
    event := jsonb_set(event, '{claims}', claims);

    -- Return the modified event
    RETURN event;
END;
$$; 