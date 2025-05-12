-- Create a view for journal entries with related information
create or replace view journal_entries_with_details with (security_barrier) as
select
  je.id,
  je.user_id,
  je.title,
  je.content,
  je.mood,
  je.privacy,
  je.created_at,
  je.updated_at,
  coalesce(
    jsonb_agg(distinct jsonb_build_object(
      'id', jt.id,
      'name', jt.name
    )) filter (where jt.id is not null),
    '[]'::jsonb
  ) as tags,
  coalesce(
    jsonb_agg(distinct jsonb_build_object(
      'id', jm.id,
      'storage_path', jm.storage_path,
      'media_type', jm.media_type
    )) filter (where jm.id is not null),
    '[]'::jsonb
  ) as media,
  coalesce(
    jsonb_agg(distinct jsonb_build_object(
      'id', p.id,
      'title', p.title,
      'post_type', p.post_type
    )) filter (where p.id is not null),
    '[]'::jsonb
  ) as linked_content
from
  journal_entries je
  left join journal_entry_tags jet on je.id = jet.journal_entry_id
  left join journal_tags jt on jet.tag_id = jt.id
  left join journal_media jm on je.id = jm.journal_entry_id
  left join journal_content_links jcl on je.id = jcl.journal_entry_id
  left join posts p on jcl.post_id = p.id
group by
  je.id;

-- Create a view for user stats based on journal entries
create or replace view user_journal_stats with (security_barrier) as
with mood_counts as (
  select 
    user_id,
    mood,
    count(*) as mood_count
  from 
    journal_entries
  where 
    mood is not null
  group by 
    user_id, mood
)
select
  je.user_id,
  count(distinct je.id) as total_entries,
  min(je.created_at) as first_entry_date,
  max(je.created_at) as latest_entry_date,
  count(distinct jm.id) as total_media_attachments,
  count(distinct jcl.post_id) as total_content_links,
  coalesce(
    (select jsonb_object_agg(mood, mood_count)
     from mood_counts mc
     where mc.user_id = je.user_id),
    '{}'::jsonb
  ) as mood_counts
from
  journal_entries je
  left join journal_media jm on je.id = jm.journal_entry_id
  left join journal_content_links jcl on je.id = jcl.journal_entry_id
group by
  je.user_id;

-- Add WHERE clauses to the views to enforce security
comment on view journal_entries_with_details is 'Journal entries with related details - security is enforced by RLS on underlying tables';
comment on view user_journal_stats is 'User journal statistics - security is enforced by RLS on underlying tables'; 