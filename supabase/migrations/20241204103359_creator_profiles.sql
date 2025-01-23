
create table creator_profiles (
  id uuid not null primary key,
  user_id uuid references auth.users on delete cascade not null,
  profile_id uuid references profiles on delete cascade not null,
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

CREATE TABLE creator_branding (
    user_id UUID NOT NULL PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    hue INTEGER,
    dark BOOLEAN,
    saturation INTEGER,
    lightness INTEGER,
    contrast INTEGER
);
 
CREATE TABLE public.onboarding_progress (
    -- Primary key using UUID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign key to auth.users
    user_id UUID REFERENCES auth.users NOT NULL,
    
    -- JSONB field for flexible steps storage
    steps JSONB NOT NULL DEFAULT '{}',
    
    -- Timestamps
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Add an index on user_id for faster lookups
    CONSTRAINT unique_user_onboarding UNIQUE (user_id)
);

-- Add RLS policies
ALTER TABLE public.onboarding_progress ENABLE ROW LEVEL SECURITY;

-- Policy for users to read their own onboarding progress
CREATE POLICY "Users can view own onboarding progress"
    ON public.onboarding_progress
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for users to update their own onboarding progress
CREATE POLICY "Users can update own onboarding progress"
    ON public.onboarding_progress
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Policy for users to insert their own onboarding progress
CREATE POLICY "Users can insert own onboarding progress"
    ON public.onboarding_progress
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Add helpful indexes
CREATE INDEX idx_onboarding_user_id ON public.onboarding_progress(user_id);
CREATE INDEX idx_onboarding_completed ON public.onboarding_progress(completed_at) WHERE completed_at IS NOT NULL;

-- Create post_thumbnails bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('creator_avatars', 'creator_avatars', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('creator_coverImages', 'creator_coverImages', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;


