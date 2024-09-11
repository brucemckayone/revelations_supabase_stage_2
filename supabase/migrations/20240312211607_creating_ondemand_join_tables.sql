-- Modify the emotional_focuses table
CREATE TABLE public.emotional_focuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (value)
);

-- Create index for faster lookups
CREATE INDEX idx_emotional_focuses_value ON public.emotional_focuses(value);

-- Modify the post_emotional_focuses table
CREATE TABLE public.post_emotional_focuses (
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    emotional_focus_id UUID REFERENCES public.emotional_focuses(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, emotional_focus_id)
);

-- Create indexes for faster lookups
CREATE INDEX idx_post_emotional_focuses_post_id ON public.post_emotional_focuses(post_id);
CREATE INDEX idx_post_emotional_focuses_emotional_focus_id ON public.post_emotional_focuses(emotional_focus_id);

-- Create a trigger to update the updated_at column for emotional_focuses
CREATE TRIGGER update_emotional_focuses_modtime
BEFORE UPDATE ON public.emotional_focuses
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();
