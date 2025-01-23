-- Create location_thumbnails bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('location_thumbnails', 'location_thumbnails', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Create storage policy to allow public access to read files
CREATE POLICY "Give public access to location_thumbnails" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'location_thumbnails');

-- Create storage policy to allow authenticated users to upload files
CREATE POLICY "Allow authenticated uploads to location_thumbnails" ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'location_thumbnails');

-- Create storage policy to allow authenticated users to update their own files
CREATE POLICY "Allow authenticated updates to location_thumbnails" ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (bucket_id = 'location_thumbnails' AND auth.uid() = owner);

-- Create storage policy to allow authenticated users to delete their own files
CREATE POLICY "Allow authenticated deletes from location_thumbnails" ON storage.objects
    FOR DELETE
    TO authenticated
    USING (bucket_id = 'location_thumbnails' AND auth.uid() = owner);
