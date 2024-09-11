-- Modify the articles table
CREATE TABLE public.articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index on post_id for faster lookups
CREATE INDEX idx_articles_post_id ON public.articles(post_id);

-- Modify the article_purchases table
CREATE TABLE public.article_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, article_id)
);

-- Create indexes for faster lookups
CREATE INDEX idx_article_purchases_user_id ON public.article_purchases(user_id);
CREATE INDEX idx_article_purchases_article_id ON public.article_purchases(article_id);


-- Create triggers to update the updated_at column
CREATE TRIGGER update_articles_modtime
BEFORE UPDATE ON public.articles
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_article_purchases_modtime
BEFORE UPDATE ON public.article_purchases
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();
