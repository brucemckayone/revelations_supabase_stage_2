
create extension vector
with
  schema extensions;

-- Recreate post type and publish status enums
CREATE TYPE public.post_type_enum AS ENUM (
    'event',
    'service',
    'neuro_flow',
    'yoga',
    'dance',
    'meditation',
    'breath_work',
    'primal',
    'ritual',
    'ceremony',
    'article',
    'video'
);

CREATE TYPE public.publish_status_enum AS ENUM (
    'draft',
    'public',
    'private',
    'archived'
);



-- Create posts table
CREATE TABLE public.posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID  REFERENCES auth.users(id) ON DELETE CASCADE not null,
    title TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    content TEXT,
    post_type post_type_enum NOT NULL,
    status publish_status_enum NOT NULL DEFAULT 'draft',
    thumbnail_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (slug),
    featured BOOLEAN DEFAULT FALSE,
    CONSTRAINT title_length CHECK (char_length(title) >= 3 AND char_length(title) <= 255)
);


-- Create indexes for posts table
CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_posts_post_type ON public.posts(post_type);
CREATE INDEX idx_posts_status ON public.posts(status);

CREATE TABLE IF NOT EXISTS public.embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID UNIQUE REFERENCES public.posts(id) ON DELETE CASCADE,
    embedding vector(384)
);

-- Create an index on the embedding column for faster similarity searches
CREATE INDEX ON public.embeddings USING ivfflat (embedding vector_cosine_ops);



-- Create or replace the function to trigger the embedding creation
CREATE OR REPLACE FUNCTION trigger_create_embedding()
RETURNS TRIGGER AS $$
DECLARE
    v_request_id bigint;
    v_error_message text;
    my_var text;
BEGIN
    BEGIN

    my_var := current_setting('supabase.ANON_KEY', true);
        -- Make the HTTP POST request
        SELECT net.http_post(
            url := 'http://host.docker.internal:54321/functions/v1/embeddings',
            body := jsonb_build_object(
                'post_id', NEW.id,
                'content', NEW.content
            ),
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || my_var
            ) 
        ) INTO v_request_id;

        -- Log success (you can modify this part based on your logging preferences)
        RAISE NOTICE 'Embedding request sent successfully. Request ID: %', v_request_id;

    EXCEPTION WHEN OTHERS THEN
        -- Log error (you can modify this part based on your logging preferences)
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE WARNING 'Error sending embedding request: %', v_error_message;
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the new trigger
CREATE TRIGGER create_embedding_trigger
AFTER INSERT OR UPDATE OF content ON public.posts
FOR EACH ROW
EXECUTE FUNCTION trigger_create_embedding();


CREATE OR REPLACE FUNCTION query_embeddings(query_embedding vector(384), match_threshold float)
RETURNS SETOF embeddings
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM embeddings
  WHERE embeddings.embedding <#> query_embedding < -match_threshold
  ORDER BY embeddings.embedding <#> query_embedding;
END;
$$;

-- Create tags table
CREATE TABLE public.tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    post_type post_type_enum NOT NULL,
    UNIQUE (name, post_type)
);

-- Create post_tags table
CREATE TABLE public.post_tags (
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES public.tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

-- Create index for faster tag lookups
CREATE INDEX idx_post_tags_tag_id ON public.post_tags(tag_id);

-- Create the function to update the modified time
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the public.posts table
CREATE TRIGGER update_posts_modtime
BEFORE UPDATE ON public.posts
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

