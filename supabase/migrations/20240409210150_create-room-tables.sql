-- Modify the live_rooms table
CREATE TABLE public.live_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    password TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Create indexes for faster lookups
CREATE INDEX idx_live_rooms_post_id ON public.live_rooms(post_id);
CREATE INDEX idx_live_rooms_creator_id ON public.live_rooms(user_id);

-- Modify the live_rooms_users table
CREATE TABLE public.live_room_participants (
    room_id UUID REFERENCES public.live_rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (room_id, user_id)
);

-- Create indexes for faster lookups
CREATE INDEX idx_live_room_participants_room_id ON public.live_room_participants(room_id);
CREATE INDEX idx_live_room_participants_user_id ON public.live_room_participants(user_id);

-- The room_post table seems redundant since live_rooms already has a post_id column
-- If you need a many-to-many relationship between rooms and posts, you can keep it:
CREATE TABLE public.room_posts (
    room_id UUID REFERENCES public.live_rooms(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (room_id, post_id)
);

-- Create indexes for faster lookups
CREATE INDEX idx_room_posts_room_id ON public.room_posts(room_id);
CREATE INDEX idx_room_posts_post_id ON public.room_posts(post_id);

-- Create a trigger to update the updated_at column for live_rooms
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_live_rooms_modtime
BEFORE UPDATE ON public.live_rooms
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();
