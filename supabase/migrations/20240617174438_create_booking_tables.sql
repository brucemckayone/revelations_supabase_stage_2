-- Modify the bookings table
CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    client_name VARCHAR(255) NOT NULL,
    client_email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, post_id),
    CONSTRAINT check_time_range CHECK (start_time < end_time)
);

-- Create indexes for faster lookups
CREATE INDEX idx_bookings_post_id ON public.bookings(post_id);
CREATE INDEX idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX idx_bookings_start_time ON public.bookings(start_time);

-- Modify the availability table
CREATE TABLE public.availability (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    day VARCHAR(20) NOT NULL CHECK (day IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')),
    is_active BOOLEAN NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_availability PRIMARY KEY (user_id, day),
    CONSTRAINT check_time_range CHECK (start_time < end_time)
);

-- Create index for faster lookups
CREATE INDEX idx_availability_user_id ON public.availability(user_id);

-- Modify the service_bookings table
CREATE TABLE public.service_bookings (
    booking_id UUID PRIMARY KEY REFERENCES public.bookings(id) ON DELETE CASCADE,
    room_id UUID REFERENCES public.live_rooms(id) ON DELETE SET NULL
);

-- Create index for faster lookups
CREATE INDEX idx_service_bookings_room_id ON public.service_bookings(room_id);

-- Modify the event_bookings table
CREATE TABLE public.event_bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    date_id UUID REFERENCES public.event_dates(id),
    ticket_id UUID REFERENCES public.tickets(id),
    room_id UUID REFERENCES public.live_rooms(id) ON DELETE SET NULL
);

-- Create indexes for faster lookups
CREATE INDEX idx_event_bookings_booking_id ON public.event_bookings(booking_id);
CREATE INDEX idx_event_bookings_date_id ON public.event_bookings(date_id);
CREATE INDEX idx_event_bookings_ticket_id ON public.event_bookings(ticket_id);
CREATE INDEX idx_event_bookings_room_id ON public.event_bookings(room_id);

-- Create triggers to update the updated_at column
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_bookings_modtime
    BEFORE UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_availability_modtime
    BEFORE UPDATE ON public.availability
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();
