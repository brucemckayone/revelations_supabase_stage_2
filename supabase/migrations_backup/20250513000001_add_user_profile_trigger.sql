-- Add trigger to automatically create user profile on auth.users insert

BEGIN;

-- First check if the trigger already exists and drop it if it does
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger to handle new user profile creation
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

COMMENT ON TRIGGER on_auth_user_created ON auth.users IS 
  'Trigger to automatically create profile entries when a new user is created';

COMMIT; 