-- First, create a custom type for the video asset
CREATE TYPE public.video_asset_type AS (
  id TEXT,
  user_id UUID,
  created_at BIGINT,
  encoding_tier TEXT,
  master_access TEXT,
  max_resolution_tier TEXT,
  mp4_support TEXT,
  status TEXT,
  aspect_ratio TEXT,
  duration FLOAT,
  errors JSONB,
  ingest_type TEXT,
  is_live BOOLEAN,
  live_stream_id TEXT,
  master JSONB,
  max_stored_frame_rate FLOAT,
  max_stored_resolution TEXT,
  non_standard_input_reasons JSONB,
  normalize_audio BOOLEAN,
  passthrough JSONB,
  per_title_encode BOOLEAN,
  playback_ids JSONB,
  recording_times JSONB,
  resolution_tier TEXT,
  source_asset_id TEXT,
  static_renditions JSONB,
  test BOOLEAN,
  tracks JSONB,
  upload_id TEXT
);

-- Now, create the function using this custom type
CREATE OR REPLACE FUNCTION public.query_video_assets(
  track_filter TEXT DEFAULT 'all',
  status_filter TEXT DEFAULT 'all',
  p_limit INTEGER DEFAULT 10,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  assets video_asset_type[],
  total_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Check if the user is authenticated
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = 'LOGIN';
  END IF;

  -- Validate input parameters
  IF track_filter NOT IN ('all', 'audio-only', 'with-video') THEN
    RAISE EXCEPTION 'Invalid track_filter. Must be ''all'', ''audio-only'', or ''with-video''.' USING ERRCODE = 'INVALID_PARAMETER_VALUE';
  END IF;

  IF status_filter NOT IN ('all', 'preparing', 'ready', 'errored') THEN
    RAISE EXCEPTION 'Invalid status_filter. Must be ''all'', ''preparing'', ''ready'', or ''errored''.' USING ERRCODE = 'INVALID_PARAMETER_VALUE';
  END IF;

  IF p_limit < 1 OR p_limit > 100 THEN
    RAISE EXCEPTION 'Invalid limit. Must be between 1 and 100.' USING ERRCODE = 'INVALID_PARAMETER_VALUE';
  END IF;

  IF p_offset < 0 THEN
    RAISE EXCEPTION 'Invalid offset. Must be non-negative.' USING ERRCODE = 'INVALID_PARAMETER_VALUE';
  END IF;

  -- Return the query results
  RETURN QUERY
  WITH filtered_assets AS (
    SELECT *
    FROM public.video_assets
    WHERE user_id = v_user_id
      AND (track_filter = 'all'
           OR (track_filter = 'audio-only' AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(tracks) AS track WHERE track->>'type' = 'video'))
           OR (track_filter = 'with-video' AND EXISTS (SELECT 1 FROM jsonb_array_elements(tracks) AS track WHERE track->>'type' = 'video')))
      AND (status_filter = 'all' OR status = status_filter)
  )
  SELECT 
    ARRAY(
      SELECT (fa.*)::video_asset_type
      FROM filtered_assets fa
      ORDER BY created_at DESC
      LIMIT p_limit
      OFFSET p_offset
    ) AS assets,
    (SELECT COUNT(*) FROM filtered_assets)::BIGINT AS total_count;

EXCEPTION
  WHEN OTHERS THEN
    -- Log the error (you might want to use a more sophisticated logging mechanism)
    RAISE NOTICE 'Error in query_video_assets: %', SQLERRM;
    -- Re-raise the exception
    RAISE;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.query_video_assets(TEXT, TEXT, INTEGER, INTEGER) TO authenticated;