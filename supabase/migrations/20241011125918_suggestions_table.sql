create table public.suggestions (
    id UUID primary key default uuid_generate_v4(),
    suggestion text not null,
    post_type post_type_enum,
    user_id UUID references auth.users(id) default null,
    created_at timestamp with time zone default now()
);