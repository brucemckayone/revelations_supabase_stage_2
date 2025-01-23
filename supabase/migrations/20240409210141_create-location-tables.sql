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

-- First, add PostGIS extension if not already added
CREATE EXTENSION IF NOT EXISTS postgis;

-- Then alter the table to add geography column for coordinates
ALTER TABLE public.locations
ADD COLUMN coordinates geography(Point, 4326),
ADD COLUMN coordinates_source TEXT CHECK (coordinates_source IN ('nominatim', 'manual', 'google', null)),
ADD COLUMN coordinates_updated_at TIMESTAMP WITH TIME ZONE;

-- Create an index for geospatial queries
CREATE INDEX locations_coordinates_idx ON public.locations USING GIST (coordinates);

-- Create a function to automatically update coordinates_updated_at
CREATE OR REPLACE FUNCTION update_coordinates_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.coordinates_updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to automatically update coordinates_updated_at
CREATE TRIGGER update_coordinates_timestamp
    BEFORE UPDATE OF coordinates
    ON public.locations
    FOR EACH ROW
    EXECUTE FUNCTION update_coordinates_timestamp();

-- Add a function to calculate distance between two points (fixed syntax)
CREATE OR REPLACE FUNCTION calculate_distance(
    point1 geography,
    point2 geography,
    unit text DEFAULT 'km'
) RETURNS float AS $$
DECLARE
    distance float;
BEGIN
    distance := ST_Distance(point1, point2);
    
    IF unit = 'km' THEN
        distance := distance / 1000;
    ELSIF unit = 'miles' THEN
        distance := distance / 1609.344;
    END IF;
    
    RETURN round(distance::numeric, 2);
END;
$$ LANGUAGE plpgsql;

-- Add a function to find nearby locations
CREATE OR REPLACE FUNCTION find_nearby_locations(
    lat double precision,
    lon double precision,
    radius_km double precision DEFAULT 10,
    limit_count integer DEFAULT 50
) RETURNS TABLE (
    id uuid,
    name text,
    distance_km float,
    line_1 text,
    city text,
    postcode text,
    country text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        l.name,
        calculate_distance(
            l.coordinates,
            ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
            'km'
        ) as distance_km,
        l.line_1,
        l.city,
        l.postcode,
        l.country
    FROM locations l
    WHERE ST_DWithin(
        l.coordinates,
        ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
        radius_km * 1000  -- Convert km to meters
    )
    ORDER BY l.coordinates <-> ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Add helper function to generate address text
CREATE OR REPLACE FUNCTION generate_coordinates_text(
    line1 text,
    line2 text,
    city text,
    postcode text,
    country text
) RETURNS text AS $$
BEGIN
    RETURN concat_ws(', ',
        NULLIF(line1, ''),
        NULLIF(line2, ''),
        NULLIF(city, ''),
        NULLIF(postcode, ''),
        NULLIF(country, '')
    );
END;
$$ LANGUAGE plpgsql;

-- Add unique constraint for coordinates
ALTER TABLE public.locations
ADD CONSTRAINT unique_coordinates UNIQUE (coordinates);


