DO $$ 
BEGIN
    -- Create creator_profiles table if it doesn't exist
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'creator_profiles') THEN
        CREATE TABLE public.creator_profiles (
            id uuid not null primary key,
            user_id uuid references auth.users on delete cascade not null,
            profile_id uuid references profiles on delete cascade not null,
            profile_name text,
            title text,
            updated_at timestamp with time zone,
            cover_image_url text,
            bio text,
            short_bio text,
            certifications text[],
            experience text,
            philosophy text,
            background_video_url text,
            featured_testimonials text[]
        );
    END IF;

    -- Create creator_branding table if it doesn't exist
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'creator_branding') THEN
        CREATE TABLE public.creator_branding (
            user_id UUID NOT NULL PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
            hue INTEGER,
            dark BOOLEAN,
            saturation INTEGER,
            lightness INTEGER,
            contrast INTEGER
        );
    END IF;

    -- Create onboarding_progress table if it doesn't exist
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'onboarding_progress') THEN
        CREATE TABLE public.onboarding_progress (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users NOT NULL,
            steps JSONB NOT NULL DEFAULT '{}',
            last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            completed_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            CONSTRAINT unique_user_onboarding UNIQUE (user_id)
        );

        -- Enable RLS
        ALTER TABLE public.onboarding_progress ENABLE ROW LEVEL SECURITY;

        -- Create policies if they don't exist
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'onboarding_progress' AND policyname = 'Users can view own onboarding progress') THEN
            CREATE POLICY "Users can view own onboarding progress"
                ON public.onboarding_progress
                FOR SELECT
                USING (auth.uid() = user_id);
        END IF;

        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'onboarding_progress' AND policyname = 'Users can update own onboarding progress') THEN
            CREATE POLICY "Users can update own onboarding progress"
                ON public.onboarding_progress
                FOR UPDATE
                USING (auth.uid() = user_id);
        END IF;

        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'onboarding_progress' AND policyname = 'Users can insert own onboarding progress') THEN
            CREATE POLICY "Users can insert own onboarding progress"
                ON public.onboarding_progress
                FOR INSERT
                WITH CHECK (auth.uid() = user_id);
        END IF;

        -- Create indexes if they don't exist
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_onboarding_user_id') THEN
            CREATE INDEX idx_onboarding_user_id ON public.onboarding_progress(user_id);
        END IF;

        IF NOT EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_onboarding_completed') THEN
            CREATE INDEX idx_onboarding_completed ON public.onboarding_progress(completed_at) WHERE completed_at IS NOT NULL;
        END IF;
    END IF;

    -- Create storage buckets if they don't exist
    INSERT INTO storage.buckets (id, name, public, avif_autodetection)
    VALUES ('creator_avatars', 'creator_avatars', TRUE, FALSE)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO storage.buckets (id, name, public, avif_autodetection)
    VALUES ('creator_coverImages', 'creator_coverImages', TRUE, FALSE)
    ON CONFLICT (id) DO NOTHING;
END $$;
