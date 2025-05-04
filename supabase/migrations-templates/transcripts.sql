drop table if exists public.transcripts;
create table public.transcripts
(
    id UUID primary key references public.assets (id) on delete cascade,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    transcript text not null,
    language text not null,
    status text not null,
    error_message text
);
