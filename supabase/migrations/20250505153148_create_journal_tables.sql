-- Create journal-related enums
create type journal_entry_privacy_enum as enum ('private', 'public', 'shared');
create type mood_enum as enum ('great', 'good', 'neutral', 'poor', 'terrible');

-- Create journal entries table
create table journal_entries (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) not null,
  title text not null,
  content text not null,
  mood mood_enum,
  privacy journal_entry_privacy_enum not null default 'private',
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);
comment on table journal_entries is 'User journal entries for personal wellness tracking and reflection';

-- Create journal tags table
create table journal_tags (
  id bigint generated always as identity primary key,
  name text not null unique,
  created_at timestamp with time zone default now() not null
);
comment on table journal_tags is 'Tags that can be applied to journal entries for categorization';

-- Create junction table for journal entries and tags
create table journal_entry_tags (
  journal_entry_id bigint references journal_entries(id) on delete cascade not null,
  tag_id bigint references journal_tags(id) on delete cascade not null,
  primary key (journal_entry_id, tag_id)
);
comment on table journal_entry_tags is 'Junction table linking journal entries to tags';

-- Create journal media attachments table
create table journal_media (
  id bigint generated always as identity primary key,
  journal_entry_id bigint references journal_entries(id) on delete cascade not null,
  storage_path text not null,
  media_type text not null,
  created_at timestamp with time zone default now() not null
);
comment on table journal_media is 'Media files attached to journal entries';

-- Create journal entry connection to platform content
create table journal_content_links (
  id bigint generated always as identity primary key,
  journal_entry_id bigint references journal_entries(id) on delete cascade not null,
  post_id uuid references posts(id) on delete cascade,
  created_at timestamp with time zone default now() not null,
  unique(journal_entry_id, post_id)
);
comment on table journal_content_links is 'Links between journal entries and platform content';

-- Setup basic triggers for updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_journal_entries_updated_at
before update on journal_entries
for each row
execute function update_updated_at_column();

-- Setup RLS policies
alter table journal_entries enable row level security;
alter table journal_tags enable row level security;
alter table journal_entry_tags enable row level security;
alter table journal_media enable row level security;
alter table journal_content_links enable row level security;

-- Journal entries policies
create policy "Users can create their own journal entries"
on journal_entries for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can view their own journal entries"
on journal_entries for select
to authenticated
using (auth.uid() = user_id);

create policy "Users can update their own journal entries"
on journal_entries for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their own journal entries"
on journal_entries for delete
to authenticated
using (auth.uid() = user_id);

-- Journal tags policies
create policy "Anyone can view tags"
on journal_tags for select
to authenticated
using (true);

create policy "Anyone can create tags"
on journal_tags for insert
to authenticated
with check (true);

-- Journal entry tags policies
create policy "Users can view tags for their own entries"
on journal_entry_tags for select
to authenticated
using (
  exists (
    select 1 from journal_entries
    where journal_entries.id = journal_entry_tags.journal_entry_id
    and journal_entries.user_id = auth.uid()
  )
);

create policy "Users can add tags to their own entries"
on journal_entry_tags for insert
to authenticated
with check (
  exists (
    select 1 from journal_entries
    where journal_entries.id = journal_entry_tags.journal_entry_id
    and journal_entries.user_id = auth.uid()
  )
);

create policy "Users can remove tags from their own entries"
on journal_entry_tags for delete
to authenticated
using (
  exists (
    select 1 from journal_entries
    where journal_entries.id = journal_entry_tags.journal_entry_id
    and journal_entries.user_id = auth.uid()
  )
);

-- Journal media policies
create policy "Users can view media for their own entries"
on journal_media for select
to authenticated
using (
  exists (
    select 1 from journal_entries
    where journal_entries.id = journal_media.journal_entry_id
    and journal_entries.user_id = auth.uid()
  )
);

create policy "Users can add media to their own entries"
on journal_media for insert
to authenticated
with check (
  exists (
    select 1 from journal_entries
    where journal_entries.id = journal_media.journal_entry_id
    and journal_entries.user_id = auth.uid()
  )
);

create policy "Users can delete media from their own entries"
on journal_media for delete
to authenticated
using (
  exists (
    select 1 from journal_entries
    where journal_entries.id = journal_media.journal_entry_id
    and journal_entries.user_id = auth.uid()
  )
);

-- Journal content links policies
create policy "Users can view content links for their own entries"
on journal_content_links for select
to authenticated
using (
  exists (
    select 1 from journal_entries
    where journal_entries.id = journal_content_links.journal_entry_id
    and journal_entries.user_id = auth.uid()
  )
);

create policy "Users can create content links for their own entries"
on journal_content_links for insert
to authenticated
with check (
  exists (
    select 1 from journal_entries
    where journal_entries.id = journal_content_links.journal_entry_id
    and journal_entries.user_id = auth.uid()
  )
);

create policy "Users can delete content links from their own entries"
on journal_content_links for delete
to authenticated
using (
  exists (
    select 1 from journal_entries
    where journal_entries.id = journal_content_links.journal_entry_id
    and journal_entries.user_id = auth.uid()
  )
); 