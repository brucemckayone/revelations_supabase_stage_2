-- Fix ambiguous column references in get_protected_media_url function
-- This function is called by our on-page functions

-- Create a properly qualified version of get_protected_media_url
CREATE OR REPLACE FUNCTION get_protected_media_url(content_id UUID)
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_url TEXT;
    v_content_id ALIAS FOR content_id; -- Use an alias for internal references
BEGIN
    -- Check if user has access to this content using our fixed v2 function
    IF can_access_content_v2(v_content_id) THEN
        -- Get the protected URL
        SELECT pmd.url INTO v_url
        FROM protected_media_data pmd
        WHERE pmd.content_id = v_content_id;
        
        -- Record the access
        UPDATE content_purchases cp
        SET 
            last_accessed = NOW(),
            download_count = download_count + 1
        FROM purchases p
        WHERE cp.purchase_id = p.id
        AND cp.content_id = v_content_id
        AND p.user_id = auth.uid();
        
        RETURN v_url;
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_protected_media_url TO authenticated;

-- Create a new version that uses qualified references but keeps the parameter name
CREATE OR REPLACE FUNCTION get_protected_media_url_v2(content_id UUID)
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_url TEXT;
    v_content_id ALIAS FOR content_id; -- Use an alias for internal references
BEGIN
    -- Check if user has access to this content using our fixed v2 function
    IF can_access_content_v2(v_content_id) THEN
        -- Get the protected URL
        SELECT url INTO v_url
        FROM protected_media_data pmd
        WHERE pmd.content_id = v_content_id;
        
        -- Record the access
        UPDATE content_purchases cp
        SET 
            last_accessed = NOW(),
            download_count = download_count + 1
        FROM purchases p
        WHERE cp.purchase_id = p.id
        AND cp.content_id = v_content_id
        AND p.user_id = auth.uid();
        
        RETURN v_url;
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_protected_media_url_v2 TO authenticated; 