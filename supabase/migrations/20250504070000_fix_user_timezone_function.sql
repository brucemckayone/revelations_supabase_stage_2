-- Create the user timezone hook function so the config.toml reference is valid
-- This function is used to set a custom claim for the user's timezone

DROP FUNCTION IF EXISTS set_user_timezone_claim;
CREATE OR REPLACE FUNCTION set_user_timezone_claim(token jsonb, claims jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_tz TEXT;
BEGIN
  -- Get the user's timezone from user_locations or user_preferences
  SELECT timezone INTO user_tz
  FROM user_locations
  WHERE user_id = claims->>'sub';
  
  -- If not found, try to get a default from elsewhere or use UTC
  IF user_tz IS NULL THEN
    user_tz := 'UTC';
  END IF;
  
  -- Add the timezone to the custom claims
  RETURN jsonb_set(claims, '{app_metadata, timezone}', to_jsonb(user_tz));
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION set_user_timezone_claim TO authenticated;
GRANT EXECUTE ON FUNCTION set_user_timezone_claim TO anon;
GRANT EXECUTE ON FUNCTION set_user_timezone_claim TO service_role; 