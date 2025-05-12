-- Function to create a new journal entry
create or replace function create_journal_entry(
  p_user_id uuid,
  p_title text,
  p_content text,
  p_mood mood_enum default null,
  p_privacy journal_entry_privacy_enum default 'private',
  p_tags text[] default null,
  p_post_id uuid default null
) returns jsonb as $$
declare
  v_journal_entry_id bigint;
  v_tag_id bigint;
  v_tag_name text;
begin
  -- Insert the journal entry
  insert into journal_entries (user_id, title, content, mood, privacy)
  values (p_user_id, p_title, p_content, p_mood, p_privacy)
  returning id into v_journal_entry_id;
  
  -- Handle tags if provided
  if p_tags is not null then
    foreach v_tag_name in array p_tags loop
      -- Try to find existing tag or create new one
      select id into v_tag_id from journal_tags where name = v_tag_name;
      
      if v_tag_id is null then
        insert into journal_tags (name)
        values (v_tag_name)
        returning id into v_tag_id;
      end if;
      
      -- Link tag to journal entry
      insert into journal_entry_tags (journal_entry_id, tag_id)
      values (v_journal_entry_id, v_tag_id);
    end loop;
  end if;
  
  -- Link to content if provided
  if p_post_id is not null then
    insert into journal_content_links (journal_entry_id, post_id)
    values (v_journal_entry_id, p_post_id);
  end if;
  
  -- Return the created journal entry with its relationships
  return (
    select jsonb_build_object(
      'journal_entry', row_to_json(je),
      'tags', coalesce(
        (select jsonb_agg(jt.name)
         from journal_entry_tags jet
         join journal_tags jt on jet.tag_id = jt.id
         where jet.journal_entry_id = je.id),
        '[]'::jsonb
      ),
      'content_links', coalesce(
        (select jsonb_agg(jcl.post_id)
         from journal_content_links jcl
         where jcl.journal_entry_id = je.id),
        '[]'::jsonb
      )
    )
    from journal_entries je
    where je.id = v_journal_entry_id
  );
end;
$$ language plpgsql security definer;

-- Function to update an existing journal entry
create or replace function update_journal_entry(
  p_journal_entry_id bigint,
  p_title text default null,
  p_content text default null,
  p_mood mood_enum default null,
  p_privacy journal_entry_privacy_enum default null,
  p_tags text[] default null
) returns jsonb as $$
declare
  v_user_id uuid;
  v_tag_id bigint;
  v_tag_name text;
begin
  -- Get user_id of the journal entry to check ownership
  select user_id into v_user_id from journal_entries where id = p_journal_entry_id;
  
  -- Check if the current user owns this journal entry
  if v_user_id is null or v_user_id != auth.uid() then
    raise exception 'Journal entry not found or you do not have permission to update it';
  end if;
  
  -- Update the journal entry with non-null values
  update journal_entries
  set 
    title = coalesce(p_title, title),
    content = coalesce(p_content, content),
    mood = coalesce(p_mood, mood),
    privacy = coalesce(p_privacy, privacy)
  where id = p_journal_entry_id;
  
  -- Handle tags if provided (remove existing and add new)
  if p_tags is not null then
    -- Remove existing tags
    delete from journal_entry_tags where journal_entry_id = p_journal_entry_id;
    
    -- Add new tags
    foreach v_tag_name in array p_tags loop
      -- Try to find existing tag or create new one
      select id into v_tag_id from journal_tags where name = v_tag_name;
      
      if v_tag_id is null then
        insert into journal_tags (name)
        values (v_tag_name)
        returning id into v_tag_id;
      end if;
      
      -- Link tag to journal entry
      insert into journal_entry_tags (journal_entry_id, tag_id)
      values (p_journal_entry_id, v_tag_id);
    end loop;
  end if;
  
  -- Return the updated journal entry with its relationships
  return (
    select jsonb_build_object(
      'journal_entry', row_to_json(je),
      'tags', coalesce(
        (select jsonb_agg(jt.name)
         from journal_entry_tags jet
         join journal_tags jt on jet.tag_id = jt.id
         where jet.journal_entry_id = je.id),
        '[]'::jsonb
      ),
      'content_links', coalesce(
        (select jsonb_agg(jcl.post_id)
         from journal_content_links jcl
         where jcl.journal_entry_id = je.id),
        '[]'::jsonb
      )
    )
    from journal_entries je
    where je.id = p_journal_entry_id
  );
end;
$$ language plpgsql security definer;

-- Function to get journal entries with optional filtering
create or replace function get_journal_entries(
  p_user_id uuid default null,
  p_tag_names text[] default null,
  p_start_date timestamp with time zone default null,
  p_end_date timestamp with time zone default null,
  p_mood mood_enum default null,
  p_limit int default 20,
  p_offset int default 0
) returns jsonb as $$
declare
  v_user_id uuid := coalesce(p_user_id, auth.uid());
  v_query text;
  v_params jsonb := '{}'::jsonb;
  v_result jsonb;
begin
  -- Only allow users to query their own journal entries unless they're an admin
  if v_user_id != auth.uid() then
    -- Check if the user is an admin (implement your admin check here)
    -- For now, we'll just prevent users from accessing others' journals
    raise exception 'You can only access your own journal entries';
  end if;
  
  -- Build the base query
  v_query := '
    with filtered_entries as (
      select 
        je.*
      from 
        journal_entries je
      where 
        je.user_id = $1
    ';
  
  v_params := v_params || jsonb_build_object('1', v_user_id);
  
  -- Add tag filter if specified
  if p_tag_names is not null and array_length(p_tag_names, 1) > 0 then
    v_query := v_query || '
      and exists (
        select 1
        from journal_entry_tags jet
        join journal_tags jt on jet.tag_id = jt.id
        where jet.journal_entry_id = je.id
        and jt.name = any($2)
      )
    ';
    v_params := v_params || jsonb_build_object('2', p_tag_names);
  end if;
  
  -- Add date range filter if specified
  if p_start_date is not null then
    v_query := v_query || '
      and je.created_at >= $3
    ';
    v_params := v_params || jsonb_build_object('3', p_start_date);
  end if;
  
  if p_end_date is not null then
    v_query := v_query || '
      and je.created_at <= $4
    ';
    v_params := v_params || jsonb_build_object('4', p_end_date);
  end if;
  
  -- Add mood filter if specified
  if p_mood is not null then
    v_query := v_query || '
      and je.mood = $5
    ';
    v_params := v_params || jsonb_build_object('5', p_mood);
  end if;
  
  -- Close the CTE
  v_query := v_query || '
    )
    select
      jsonb_build_object(
        ''entries'', coalesce(
          jsonb_agg(
            jsonb_build_object(
              ''journal_entry'', to_jsonb(fe),
              ''tags'', coalesce(
                (select jsonb_agg(jt.name)
                 from journal_entry_tags jet
                 join journal_tags jt on jet.tag_id = jt.id
                 where jet.journal_entry_id = fe.id),
                ''[]''::jsonb
              ),
              ''content_links'', coalesce(
                (select jsonb_agg(jcl.post_id)
                 from journal_content_links jcl
                 where jcl.journal_entry_id = fe.id),
                ''[]''::jsonb
              )
            )
            order by fe.created_at desc
          ),
          ''[]''::jsonb
        ),
        ''total_count'', (select count(*) from filtered_entries),
        ''limit'', $6,
        ''offset'', $7
      )
    from
      filtered_entries fe
    group by fe.id, fe.created_at
    order by fe.created_at desc
    limit $6
    offset $7
  ';
  
  v_params := v_params || jsonb_build_object('6', p_limit, '7', p_offset);
  
  -- Execute the query with parameters
  execute v_query
  using 
    (v_params ->> '1')::uuid,
    (case when v_params ? '2' then (v_params ->> '2')::text[] else null end),
    (case when v_params ? '3' then (v_params ->> '3')::timestamp with time zone else null end),
    (case when v_params ? '4' then (v_params ->> '4')::timestamp with time zone else null end),
    (case when v_params ? '5' then (v_params ->> '5')::mood_enum else null end),
    (v_params ->> '6')::int,
    (v_params ->> '7')::int
  into v_result;
  
  return v_result;
end;
$$ language plpgsql security definer;

-- Function to add media to a journal entry
create or replace function add_journal_media(
  p_journal_entry_id bigint,
  p_storage_path text,
  p_media_type text
) returns jsonb as $$
declare
  v_user_id uuid;
  v_media_id bigint;
begin
  -- Get user_id of the journal entry to check ownership
  select user_id into v_user_id from journal_entries where id = p_journal_entry_id;
  
  -- Check if the current user owns this journal entry
  if v_user_id is null or v_user_id != auth.uid() then
    raise exception 'Journal entry not found or you do not have permission to add media to it';
  end if;
  
  -- Insert the media
  insert into journal_media (journal_entry_id, storage_path, media_type)
  values (p_journal_entry_id, p_storage_path, p_media_type)
  returning id into v_media_id;
  
  -- Return the media info
  return (
    select jsonb_build_object(
      'id', jm.id,
      'journal_entry_id', jm.journal_entry_id,
      'storage_path', jm.storage_path,
      'media_type', jm.media_type,
      'created_at', jm.created_at
    )
    from journal_media jm
    where jm.id = v_media_id
  );
end;
$$ language plpgsql security definer;

-- Function to link journal entry to platform content
create or replace function link_journal_to_content(
  p_journal_entry_id bigint,
  p_post_id uuid
) returns jsonb as $$
declare
  v_user_id uuid;
  v_link_id bigint;
begin
  -- Get user_id of the journal entry to check ownership
  select user_id into v_user_id from journal_entries where id = p_journal_entry_id;
  
  -- Check if the current user owns this journal entry
  if v_user_id is null or v_user_id != auth.uid() then
    raise exception 'Journal entry not found or you do not have permission to link it to content';
  end if;
  
  -- Check if the post exists
  if not exists (select 1 from posts where id = p_post_id) then
    raise exception 'Post does not exist';
  end if;
  
  -- Insert the link (if it doesn't already exist)
  insert into journal_content_links (journal_entry_id, post_id)
  values (p_journal_entry_id, p_post_id)
  on conflict (journal_entry_id, post_id) do nothing
  returning id into v_link_id;
  
  -- If no row was inserted, get the existing link id
  if v_link_id is null then
    select id into v_link_id from journal_content_links 
    where journal_entry_id = p_journal_entry_id and post_id = p_post_id;
  end if;
  
  -- Return the link info
  return (
    select jsonb_build_object(
      'id', jcl.id,
      'journal_entry_id', jcl.journal_entry_id,
      'post_id', jcl.post_id,
      'created_at', jcl.created_at
    )
    from journal_content_links jcl
    where jcl.id = v_link_id
  );
end;
$$ language plpgsql security definer; 