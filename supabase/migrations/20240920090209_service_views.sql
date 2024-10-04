create or replace view
  service_details as
select
  p.id,
  p.user_id,
  p.title,
  p.slug,
  p.description,
  p.content,
  p.post_type::text as post_type,
  p.status::text as status,
  p.thumbnail_url,
  p.created_at,
  p.updated_at,
  p.featured,
  coalesce(
    array_agg(t.name) filter (
      where
        t.id is not null
    ),
    '{}'::text[]
  ) as tags,
  pr.id as profile_id,
  pr.full_name as profile_full_name,
  pr.avatar_url as profile_avatar_url,
  sr.duration,
  sr.price,
  sr.type,
  lc.name as location_name
from
  public.posts p
   inner join public.post_tags pt on p.id = pt.post_id
   inner join public.tags t on pt.tag_id = t.id
   left join public.profiles pr on p.user_id = pr.id
   inner join public.services sr on p.id = sr.post_id
   left join public.locations lc on sr.location_id = lc.id
group by
  p.id,
  p.user_id,
  p.title,
  p.slug,
  p.description,
  p.content,
  p.post_type,
  p.status,
  p.thumbnail_url,
  p.created_at,
  p.updated_at,
  p.featured,
  pr.id,
  pr.full_name,
  pr.avatar_url,
  sr.duration,
  sr.price,
  sr.type,
  lc.name;
