-- Add the missing trigger for handle_new_user function
CREATE OR REPLACE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Comment on the trigger to document its purpose
COMMENT ON TRIGGER on_auth_user_created ON auth.users
IS 'Trigger that runs after a user is created to set up profile, roles, and timezone settings';

