-- 1. authorizedAs function
CREATE OR REPLACE FUNCTION public.authorizedAs(allowed_roles public.user_role[])
RETURNS boolean AS $$
DECLARE
    v_is_authorized boolean;
    v_user_id uuid;
    v_user_role public.user_role;
BEGIN
    v_user_id := auth.uid();
    
    SELECT (raw_user_meta_data->>'user_role')::public.user_role
    INTO v_user_role
    FROM auth.users
    WHERE id = v_user_id;

    v_is_authorized := v_user_role = ANY(allowed_roles);
    
    -- IF NOT v_is_authorized THEN
    --     RAISE EXCEPTION 'Access denied: User role % is not authorized. Allowed roles are: %', 
    --                     v_user_role, array_to_string(allowed_roles, ', ');
    -- END IF;

    RETURN v_is_authorized;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.isOwned(input_user_id UUID DEFAULT NULL)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_owned BOOLEAN;
    v_user_id UUID;
    v_table_name TEXT;
    v_debug_details TEXT;
BEGIN
    -- Get the current user's ID
    v_user_id := auth.uid();
    
    -- Try to get the table name
    BEGIN
        v_table_name := TG_TABLE_NAME;
    EXCEPTION
        WHEN OTHERS THEN
            v_table_name := 'Unknown';
    END;
    
    -- If input_user_id is provided, compare it with auth.uid()
    IF input_user_id IS NOT NULL THEN
        v_is_owned := (input_user_id = v_user_id);
        v_debug_details := format('Comparing input_user_id %s with auth.uid() %s', input_user_id, v_user_id);
        RETURN v_is_owned;
    END IF;

    -- Check for user_id column in the current record
    BEGIN
        IF NEW IS NOT NULL THEN
            v_is_owned := (v_user_id = NEW.user_id);
        ELSIF OLD IS NOT NULL THEN
            v_is_owned := (v_user_id = OLD.user_id);
        ELSE
            v_debug_details := 'Unable to determine record context (NEW or OLD is not available)';
            RAISE EXCEPTION '%', v_debug_details;
        END IF;
    EXCEPTION
        WHEN undefined_column THEN
            v_debug_details := format('The table %s does not have a user_id column', v_table_name);
            RAISE EXCEPTION 'Operation failed: %. This operation requires a user_id for ownership verification.', v_debug_details;
    END;

    IF NOT v_is_owned THEN
        v_debug_details := format('User (ID: %s) does not own this record in table %s', v_user_id, v_table_name);
        RAISE EXCEPTION 'Access denied: %', v_debug_details;
    END IF;
      
    RETURN v_is_owned;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3. isOwnedFolder function
CREATE OR REPLACE FUNCTION public.isOwnedFolder(object_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_owned BOOLEAN;
    v_user_id UUID;
    v_folder_name TEXT;
BEGIN
    v_user_id := auth.uid();
    v_folder_name := (storage.foldername(object_name))[1];
    v_is_owned := (v_user_id::text) = v_folder_name;

    IF NOT v_is_owned THEN
        RAISE EXCEPTION 'Access denied: Folder "%" is not owned by user (ID: %). Users can only access their own folders.', 
                        v_folder_name, v_user_id;
    END IF;

    RETURN v_is_owned;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION grant_public_read_access(table_name TEXT)
RETURNS VOID AS $$
BEGIN
  EXECUTE format('GRANT SELECT ON TABLE public.%I TO authenticated', table_name);
  EXECUTE format('GRANT SELECT ON TABLE public.%I TO anon', table_name);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;