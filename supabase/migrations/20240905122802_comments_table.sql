-- Table definition
CREATE TABLE public.comments (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID default null,
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    parent_id BIGINT REFERENCES public.comments(id),
    score INTEGER DEFAULT 0
);

alter table public.comments add column hasReplies boolean default null;

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

-- Function to update hasReplies flag for parent comment
CREATE OR REPLACE FUNCTION update_comment_has_replies()
RETURNS TRIGGER AS $$
BEGIN
    -- Only execute if there is a parent_id (meaning this is a reply)
    IF NEW.parent_id IS NOT NULL THEN
        -- Update only the specific parent comment
        UPDATE comments 
        SET hasReplies = true 
        WHERE id = NEW.parent_id;
    END IF;
    
    -- Return the NEW row to complete the trigger
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER on_comment_insert
    BEFORE INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION update_comment_has_replies();



-- Add new columns to existing comments table
ALTER TABLE public.comments 
  ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS depth INTEGER DEFAULT 0;

-- Create reactions table
CREATE TABLE IF NOT EXISTS public.comment_reactions (
    id BIGSERIAL PRIMARY KEY,
    comment_id BIGINT REFERENCES public.comments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    reaction_type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(comment_id, user_id, reaction_type)
);

-- Create attachments table
CREATE TABLE IF NOT EXISTS public.comment_attachments (
    id BIGSERIAL PRIMARY KEY,
    comment_id BIGINT REFERENCES public.comments(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('image', 'file')),
    url TEXT NOT NULL,
    name TEXT NOT NULL,
    size INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create mentions table
CREATE TABLE IF NOT EXISTS public.comment_mentions (
    id BIGSERIAL PRIMARY KEY,
    comment_id BIGINT REFERENCES public.comments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(comment_id, user_id)
);


