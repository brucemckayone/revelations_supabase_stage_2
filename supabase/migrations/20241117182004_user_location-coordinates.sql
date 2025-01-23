-- Drop existing table if it exists
DROP TABLE IF EXISTS public.user_locations CASCADE;

-- Create table for user locations with explicit reference to profiles
CREATE TABLE public.user_locations (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    location_id UUID REFERENCES public.locations(id) ON DELETE SET NULL,
    coordinates geography(Point, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    
);

alter table public.user_locations add column location_name TEXT default null;

-- Add a comment to explicitly declare the relationship for PostgREST
COMMENT ON CONSTRAINT user_locations_user_id_fkey ON public.user_locations IS 
    '@foreignKey (user_id) references profiles(id)';

-- Create index for geospatial queries
CREATE INDEX user_locations_coordinates_idx ON public.user_locations USING GIST (coordinates);

-- Create trigger to update the updated_at column
CREATE TRIGGER update_user_locations_modtime
    BEFORE UPDATE ON public.user_locations
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- Add RLS policies
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;

-- Users can view their own location
CREATE POLICY "Users can view own location" ON public.user_locations
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can update their own location
CREATE POLICY "Users can update own location" ON public.user_locations
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can insert their own location
CREATE POLICY "Users can insert own location" ON public.user_locations
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Function to update or insert user location
CREATE OR REPLACE FUNCTION public.upsert_user_location(
    p_lat double precision,
    p_lon double precision,
    p_location_id uuid DEFAULT NULL,
    p_location_name TEXT DEFAULT NULL
) RETURNS public.user_locations AS $$
DECLARE
    result public.user_locations;
BEGIN
    INSERT INTO public.user_locations (
        user_id,
        location_id,
        location_name,
        coordinates
    )
    VALUES (
        auth.uid(),
        p_location_id,
        p_location_name,
        ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        location_id = EXCLUDED.location_id,
        location_name = EXCLUDED.location_name,
        coordinates = EXCLUDED.coordinates,
        updated_at = CURRENT_TIMESTAMP
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to find nearby users
CREATE OR REPLACE FUNCTION find_nearby_users(
    lat double precision,
    lon double precision,
    radius_km double precision DEFAULT 10,
    limit_count integer DEFAULT 50
) RETURNS TABLE (
    user_id uuid,
    distance_km float,
    location_id uuid
) AS $$
BEGIN

    RETURN QUERY
    SELECT 
        ul.user_id,
        calculate_distance(
            ul.coordinates,
            ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
            'km'
        ) as distance_km,
        ul.location_id
    FROM user_locations ul
    WHERE ST_DWithin(
        ul.coordinates,
        ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
        radius_km * 1000  -- Convert km to meters
    )
    ORDER BY ul.coordinates <-> ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get user location as lat/long
CREATE OR REPLACE FUNCTION get_user_location(user_uuid UUID DEFAULT auth.uid())
RETURNS TABLE (
    latitude double precision,
    longitude double precision,
    location_id UUID,
    location_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ST_Y(ST_AsText(coordinates::geometry)::geography::geometry)::double precision as latitude,
        ST_X(ST_AsText(coordinates::geometry)::geography::geometry)::double precision as longitude,
        ul.location_id,
        ul.location_name
    FROM user_locations ul
    WHERE ul.user_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 