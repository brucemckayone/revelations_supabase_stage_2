
-- Add metadata column to appointment_purchases table
DO $$
BEGIN
    -- Check if the column already exists before adding it
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'appointment_purchases'
        AND column_name = 'metadata'
    ) THEN
        -- Add the metadata column as JSONB
        ALTER TABLE public.appointment_purchases ADD COLUMN metadata JSONB DEFAULT NULL;
        
        -- Add comment explaining the column's purpose
        COMMENT ON COLUMN public.appointment_purchases.metadata IS 'Stores structured metadata for appointments including rescheduling history, alternative dates, and other dynamic attributes';
    END IF;
END
$$;


