-- Table definition
CREATE TABLE public.comments (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    post_id UUID REFERENCES public.posts(id) NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    parent_id BIGINT REFERENCES public.comments(id),
    score INTEGER DEFAULT 0
);

-- Index for faster queries
CREATE INDEX idx_comments_post_id ON public.comments(post_id);
CREATE INDEX idx_comments_parent_id ON public.comments(parent_id);

-- Trigger for updating the updated_at timestamp
CREATE OR REPLACE FUNCTION update_comment_date_time()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_comment_update
BEFORE UPDATE ON public.comments
FOR EACH ROW
EXECUTE FUNCTION update_comment_date_time();
