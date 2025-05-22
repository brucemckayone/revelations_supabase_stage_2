-- Generated with srtd from template: supabase/migrations-templates/notification-my-email-templates.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

create table if not exists creator_emails (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id),
    name text not null,
    subject text not null,
    configuration jsonb not null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);



COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
