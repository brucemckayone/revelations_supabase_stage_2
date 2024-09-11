-- Modify the locations table
CREATE TABLE public.locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    line_1 TEXT,
    line_2 TEXT,
    city TEXT,
    country TEXT,
    postcode TEXT,
    maps_link TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL
);
-- Modify the post_locations table
CREATE TABLE public.post_locations (
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    location_id UUID REFERENCES public.locations(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, location_id)
);

-- Create indexes for faster lookups
CREATE INDEX idx_post_locations_post_id ON public.post_locations(post_id);
CREATE INDEX idx_post_locations_location_id ON public.post_locations(location_id);

-- Create a trigger to update the updated_at column for locations
CREATE TRIGGER update_locations_modtime
BEFORE UPDATE ON public.locations
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();
