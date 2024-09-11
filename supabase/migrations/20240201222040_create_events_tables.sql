
-- Keep the existing event_type_enum
CREATE TYPE public.event_type_enum AS ENUM (
    'online',
    'in-person',
    'hybrid'
);

-- Modify the events table
CREATE TABLE public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    content TEXT,
    type event_type_enum NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id, post_id)
);

CREATE INDEX idx_events_post_id ON public.events(post_id);

-- Create the event_dates table
CREATE TABLE public.event_dates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    CHECK (start_date < end_date)
);


-- First, ensure the btree_gist extension is created
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Remove the existing constraint if it exists
ALTER TABLE public.event_dates DROP CONSTRAINT IF EXISTS no_overlapping_dates;

-- Now, add the correct constraint
ALTER TABLE public.event_dates
ADD CONSTRAINT no_overlapping_dates
EXCLUDE USING gist (
    event_id WITH =,
    tstzrange(start_date, end_date, '[)') WITH &&
);

-- Create a function to check if an event date can be deleted
CREATE OR REPLACE FUNCTION check_event_date_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if there are any purchases for this event date
    IF EXISTS (
        SELECT 1
        FROM public.ticket_purchases
        WHERE date_id = OLD.id
    ) THEN
        RAISE EXCEPTION 'You cannot delete this event date because tickets have already been purchased for it';
    END IF;
    
    -- If no purchases found, allow the delete
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger on the event_dates table
CREATE TRIGGER prevent_event_date_delete
BEFORE DELETE ON public.event_dates
FOR EACH ROW
EXECUTE FUNCTION check_event_date_delete();

-- Grant necessary permissions
GRANT DELETE ON public.event_dates TO authenticated;

-- Ensure the btree_gist extension is created
CREATE EXTENSION IF NOT EXISTS btree_gist;
-- Create an index on event_id for better performance
CREATE INDEX idx_event_dates_event_id ON public.event_dates(event_id);

-- Modify the tickets table
CREATE TABLE public.tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    quantity INTEGER,
    days_before_unavailable INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tickets_event_id ON public.tickets(event_id);

-- Create a table for ticket purchases
CREATE TABLE public.ticket_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date_id UUID NOT NULL REFERENCES public.event_dates(id) ON DELETE CASCADE,
    ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    quantity INTEGER NOT NULL DEFAULT 1,
    UNIQUE (user_id, ticket_id)
);

-- Create a function to check if a ticket can be deleted
CREATE OR REPLACE FUNCTION check_ticket_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if there are any purchases for this ticket
    IF EXISTS (
        SELECT 1
        FROM public.ticket_purchases
        WHERE ticket_id = OLD.id
    ) THEN
        RAISE EXCEPTION 'You cannot delete this ticket because it has already been purchased by a customer';
    END IF;
    
    -- If no purchases found, allow the delete
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;



-- Create a trigger on the tickets table
CREATE TRIGGER prevent_ticket_delete
BEFORE DELETE ON public.tickets
FOR EACH ROW
EXECUTE FUNCTION check_ticket_delete();

-- Modify permissions to allow delete on tickets table
GRANT DELETE ON public.tickets TO authenticated;

CREATE INDEX idx_ticket_purchases_user_id ON public.ticket_purchases(user_id);
CREATE INDEX idx_ticket_purchases_ticket_id ON public.ticket_purchases(ticket_id);

-- Create triggers to update the updated_at column
CREATE TRIGGER update_events_modtime
    BEFORE UPDATE ON public.events
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_tickets_modtime
    BEFORE UPDATE ON public.tickets
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- Grant necessary permissions
GRANT SELECT ON public.events, public.event_dates, public.tickets TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.ticket_purchases TO authenticated;