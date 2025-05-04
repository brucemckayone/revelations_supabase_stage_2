-- Generated with srtd from template: supabase/migrations-templates/transcripts.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

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


COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
