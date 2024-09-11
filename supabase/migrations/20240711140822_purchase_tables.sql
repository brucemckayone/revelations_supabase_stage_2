-- Modify the purchases table
CREATE TABLE public.purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL,
    content_id UUID REFERENCES public.on_demand_media(id) ON DELETE SET NULL,
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster lookups
CREATE INDEX idx_purchases_user_id ON public.purchases(user_id);
CREATE INDEX idx_purchases_post_id ON public.purchases(post_id);
CREATE INDEX idx_purchases_content_id ON public.purchases(content_id);
CREATE INDEX idx_purchases_booking_id ON public.purchases(booking_id);

-- Modify the subscriptions table
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster lookups
CREATE INDEX idx_subscriptions_purchase_id ON public.subscriptions(purchase_id);
CREATE INDEX idx_subscriptions_user_id ON public.subscriptions(user_id);

-- Modify the ticket_purchases_event_date_user table
CREATE TABLE public.ticket_purchases_event_date_user (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date_id UUID REFERENCES public.event_dates(id) ON DELETE SET NULL,
    event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
    ticket_id UUID REFERENCES public.tickets(id) ON DELETE SET NULL,
    purchase_id UUID NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster lookups
CREATE INDEX idx_ticket_purchases_event_date_user_user_id ON public.ticket_purchases_event_date_user(user_id);
CREATE INDEX idx_ticket_purchases_event_date_user_event_id ON public.ticket_purchases_event_date_user(event_id);
CREATE INDEX idx_ticket_purchases_event_date_user_purchase_id ON public.ticket_purchases_event_date_user(purchase_id);

-- Create triggers to update the updated_at column
CREATE TRIGGER update_purchases_modtime
    BEFORE UPDATE ON public.purchases
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_subscriptions_modtime
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_ticket_purchases_event_date_user_modtime
    BEFORE UPDATE ON public.ticket_purchases_event_date_user
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();



CREATE TABLE public.media_access_control (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL REFERENCES public.on_demand_media(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    purchase_id UUID REFERENCES public.purchases(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP WITH TIME ZONE,
    UNIQUE (content_id, user_id)
);
-- Enable Row Level Security
ALTER TABLE public.media_access_control ENABLE ROW LEVEL SECURITY;

-- Create a policy for reading (SELECT) operations
CREATE POLICY read_own_media_access ON public.media_access_control
    FOR SELECT
    USING (auth.uid() = user_id);



-- Grant SELECT permission to authenticated users
GRANT SELECT ON public.media_access_control TO authenticated;

CREATE TABLE public.protected_media_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL REFERENCES public.on_demand_media(id) ON DELETE CASCADE UNIQUE,
    status public.publish_status_enum NOT NULL DEFAULT 'draft',
    url TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create a function to update the updated_at column
CREATE OR REPLACE FUNCTION update_protected_media_data_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to call the function before each update
CREATE TRIGGER update_protected_media_data_timestamp
BEFORE UPDATE ON public.protected_media_data
FOR EACH ROW
EXECUTE FUNCTION update_protected_media_data_timestamp();