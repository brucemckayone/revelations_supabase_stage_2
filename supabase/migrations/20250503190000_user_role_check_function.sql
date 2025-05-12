-- Create a security definer function to check if a user has a specific role
-- This allows checking roles without direct access to the user_roles table
CREATE OR REPLACE FUNCTION public.has_role(role_to_check text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = role_to_check::user_role
    );
END;
$$;

-- Grant execution permission on the function
GRANT EXECUTE ON FUNCTION public.has_role TO authenticated;

-- Update policies to use the new function
CREATE OR REPLACE FUNCTION update_admin_policies()
RETURNS void AS $$
BEGIN
    -- Update policy for purchases table
    DROP POLICY IF EXISTS purchase_admin ON public.purchases;
    CREATE POLICY purchase_admin ON public.purchases
        USING (public.has_role('admin'));
    
    -- Update policy for subscriptions table
    DROP POLICY IF EXISTS subscriptions_select ON public.subscriptions;
    CREATE POLICY subscriptions_select ON public.subscriptions
        FOR SELECT
        USING (
            EXISTS (
                SELECT 1 FROM purchases
                WHERE purchases.id = purchase_id
                AND (purchases.user_id = auth.uid() OR purchases.owner_id = auth.uid())
            ) OR
            public.has_role('admin')
        );
    
    -- Update policy for event_bookings table
    DROP POLICY IF EXISTS event_bookings_select ON public.event_bookings;
    CREATE POLICY event_bookings_select ON public.event_bookings
        FOR SELECT
        USING (
            EXISTS (
                SELECT 1 FROM purchases
                WHERE purchases.id = purchase_id
                AND (purchases.user_id = auth.uid() OR purchases.owner_id = auth.uid())
            ) OR
            public.has_role('admin')
        );
    
    -- Update policy for content_purchases table
    DROP POLICY IF EXISTS content_purchases_select ON public.content_purchases;
    CREATE POLICY content_purchases_select ON public.content_purchases
        FOR SELECT
        USING (
            EXISTS (
                SELECT 1 FROM purchases
                WHERE purchases.id = purchase_id
                AND (purchases.user_id = auth.uid() OR purchases.owner_id = auth.uid())
            ) OR
            public.has_role('admin')
        );
    
    -- Update policy for appointment_purchases table
    DROP POLICY IF EXISTS appointment_purchases_select ON public.appointment_purchases;
    CREATE POLICY appointment_purchases_select ON public.appointment_purchases
        FOR SELECT
        USING (
            EXISTS (
                SELECT 1 FROM purchases
                WHERE purchases.id = purchase_id
                AND (purchases.user_id = auth.uid() OR purchases.owner_id = auth.uid())
            ) OR
            public.has_role('admin')
        );
    
    -- Update policy for protected_media_data table
    DROP POLICY IF EXISTS admin_full_access_protected_media ON public.protected_media_data;
    CREATE POLICY admin_full_access_protected_media ON public.protected_media_data
        FOR ALL
        USING (public.has_role('admin'));
END;
$$ LANGUAGE plpgsql;

-- Execute the function to update all policies
SELECT update_admin_policies();

-- Drop the helper function as it's no longer needed
DROP FUNCTION update_admin_policies(); 