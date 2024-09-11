-- Modify the services table
CREATE TABLE public.services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE UNIQUE,
    location_id UUID REFERENCES public.locations(id),
    content TEXT,
    price NUMERIC(10, 2) NOT NULL,
    duration INTERVAL NOT NULL,
    type public.event_type_enum NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster lookups
CREATE INDEX idx_services_post_id ON public.services(post_id);
CREATE INDEX idx_services_location_id ON public.services(location_id);

-- Modify the services_dates table
CREATE TABLE public.service_dates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_time_range CHECK (start_time < end_time)
);

-- Create index for faster lookups
CREATE INDEX idx_service_dates_service_id ON public.service_dates(service_id);

-- Modify the services_access_control table
CREATE TABLE public.service_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    service_date_id UUID NOT NULL REFERENCES public.service_dates(id) ON DELETE CASCADE,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, service_date_id)
);

-- Create indexes for faster lookups
CREATE INDEX idx_service_purchases_user_id ON public.service_purchases(user_id);
CREATE INDEX idx_service_purchases_service_date_id ON public.service_purchases(service_date_id);

-- Create triggers to update the updated_at column
CREATE TRIGGER update_services_modtime
    BEFORE UPDATE ON public.services
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_service_dates_modtime
    BEFORE UPDATE ON public.service_dates
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_service_purchases_modtime
    BEFORE UPDATE ON public.service_purchases
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();
