-- Update ENUMs
ALTER TYPE public.post_type_enum ADD VALUE IF NOT EXISTS 'on_demand' AFTER 'video';

-- Create media_type_enum if it doesn't exist
CREATE TYPE public.media_type_enum AS ENUM ('video', 'audio');

--- Modify on_demand_media table
CREATE TABLE public.on_demand_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE UNIQUE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    media_type media_type_enum NOT NULL,
    duration INTERVAL NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);



CREATE INDEX idx_on_demand_media_user_id ON public.on_demand_media(user_id);

-- Modify movements table
CREATE TABLE public.movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL REFERENCES public.on_demand_media(id) ON DELETE CASCADE UNIQUE,
    instructor_name VARCHAR(100) NOT NULL,
    session_theme VARCHAR(255) NOT NULL,
    energy_level INTEGER NOT NULL CHECK (energy_level BETWEEN 1 AND 10),
    spiritual_elements TEXT,
    emotional_focus TEXT,
    recommended_environment TEXT,
    body_focus TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_movements_content_id ON public.movements(content_id);

-- Modify movement_props table
CREATE TABLE public.movement_props (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- Modify movement_props_join table
CREATE TABLE public.movement_props_join (
    movement_id UUID REFERENCES movements(id) ON DELETE CASCADE,
    prop_id UUID REFERENCES movement_props(id) ON DELETE CASCADE,
    PRIMARY KEY (movement_id, prop_id)
);

-- Modify yoga table
CREATE TABLE public.yoga (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movement_id UUID NOT NULL REFERENCES movements(id) ON DELETE CASCADE,
    yoga_style TEXT NOT NULL,
    chakras TEXT,
    UNIQUE(movement_id)
);

-- Modify dance table
CREATE TABLE public.dance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movement_id UUID NOT NULL REFERENCES movements(id) ON DELETE CASCADE,
    freeform_movement BOOLEAN NOT NULL DEFAULT false,
    UNIQUE(movement_id)
);

-- Modify neuroflow table
CREATE TABLE public.neuroflow (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movement_id UUID NOT NULL REFERENCES movements(id) ON DELETE CASCADE,
    techniques_used TEXT NOT NULL,
    session_focus TEXT NOT NULL,
    personal_growth_outcomes TEXT,
    UNIQUE(movement_id)
);


-- Modify ceremony table
CREATE TABLE public.ceremony (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL REFERENCES on_demand_media(id) ON DELETE CASCADE,
    ceremony_type TEXT NOT NULL,
    ceremony_theme TEXT NOT NULL,
    ceremony_focus TEXT NOT NULL,
    what_to_bring TEXT,
    space_holder_names TEXT
);

-- Modify meditations table
CREATE TABLE public.meditations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL REFERENCES on_demand_media(id) ON DELETE CASCADE,
    meditation_type TEXT NOT NULL,
    meditation_theme TEXT NOT NULL,
    meditation_focus TEXT NOT NULL,
    what_to_bring TEXT,
    space_holder_names TEXT
);

-- Modify spotify_playlists table
CREATE TABLE public.spotify_playlists (
    user_id UUID NOT NULL REFERENCES auth.users(id) default auth.uid(),
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    iframe TEXT NOT NULL UNIQUE
);

-- Modify spotify_playlist_join table
CREATE TABLE public.spotify_playlist_join (
    content_id UUID REFERENCES on_demand_media(id) ON DELETE CASCADE,
    playlist_id UUID REFERENCES spotify_playlists(id) ON DELETE CASCADE,
    PRIMARY KEY (content_id, playlist_id)
);

-- Add triggers for updated_at columns
CREATE TRIGGER update_on_demand_media_modtime
    BEFORE UPDATE ON public.on_demand_media
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_movements_modtime
    BEFORE UPDATE ON public.movements
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();


CREATE TABLE IF NOT EXISTS public.video_assets (
    id TEXT PRIMARY KEY NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    created_at BIGINT,
    encoding_tier TEXT CHECK (encoding_tier IN ('smart', 'baseline')),
    master_access TEXT CHECK (master_access IN ('temporary', 'none')),
    max_resolution_tier TEXT CHECK (max_resolution_tier IN ('1080p', '1440p', '2160p')),
    mp4_support TEXT CHECK (mp4_support IN ('standard', 'none', 'capped-1080p', 'audio-only', 'audio-only,capped-1080p')),
    status TEXT CHECK (status IN ('preparing', 'ready', 'errored')),
    aspect_ratio TEXT,
    duration FLOAT,
    errors JSONB,
    ingest_type TEXT CHECK (ingest_type IN ('on_demand_url', 'on_demand_direct_upload', 'on_demand_clip', 'live_rtmp', 'live_srt')),
    is_live BOOLEAN,
    live_stream_id TEXT,
    master JSONB,
    max_stored_frame_rate FLOAT,
    max_stored_resolution TEXT CHECK (max_stored_resolution IN ('Audio only', 'SD', 'HD', 'FHD', 'UHD')),
    non_standard_input_reasons JSONB,
    normalize_audio BOOLEAN,
    passthrough JSONB,
    per_title_encode BOOLEAN,
    playback_ids JSONB,
    recording_times JSONB,
    resolution_tier TEXT CHECK (resolution_tier IN ('audio-only', '720p', '1080p', '1440p', '2160p')),
    source_asset_id TEXT,
    static_renditions JSONB,
    test BOOLEAN,
    tracks JSONB,
    upload_id TEXT
);