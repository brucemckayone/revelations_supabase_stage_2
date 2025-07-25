-- Create exec_sql function for test utilities
-- This allows raw SQL execution from the test framework

create or replace function public.exec_sql(
  sql_query text,
  params jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer -- Runs with elevated privileges
as $$
declare
  result jsonb;
  rec record;
  results jsonb := '[]'::jsonb;
begin
  -- Security check - only allow in development/test environments
  -- Comment out this check if you want to allow in production (not recommended)
  if current_setting('app.environment', true) = 'production' then
    raise exception 'exec_sql function is disabled in production environment';
  end if;
  
  -- Execute the SQL query
  for rec in execute sql_query loop
    results := results || to_jsonb(rec);
  end loop;
  
  return results;
exception
  when others then
    -- Return error information as JSON
    return json_build_object(
      'error', true,
      'message', SQLERRM,
      'code', SQLSTATE
    );
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function public.exec_sql(text, jsonb) to authenticated;
grant execute on function public.exec_sql(text, jsonb) to service_role;

-- Add security comment
comment on function public.exec_sql is 'Raw SQL execution function for testing purposes. Should be disabled in production environments.'; 