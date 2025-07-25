-- Fix exec_sql function to handle parameterized queries properly
-- Replaces $1, $2, etc. with actual parameter values

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
  processed_query text;
  param_value text;
  i integer;
begin
  -- Security check - only allow in development/test environments
  -- Comment out this check if you want to allow in production (not recommended)
  if current_setting('app.environment', true) = 'production' then
    raise exception 'exec_sql function is disabled in production environment';
  end if;
  
  -- Start with the original query
  processed_query := sql_query;
  
  -- Replace parameters if provided
  if params is not null and jsonb_array_length(params) > 0 then
    for i in 0..(jsonb_array_length(params) - 1) loop
      param_value := params->>i;
      
      -- Escape single quotes and wrap strings in quotes
      if param_value is not null then
        param_value := quote_literal(param_value);
      else
        param_value := 'NULL';
      end if;
      
      -- Replace $1, $2, etc. with actual values
      processed_query := replace(processed_query, '$' || (i + 1)::text, param_value);
    end loop;
  end if;
  
  -- Execute the processed SQL query
  for rec in execute processed_query loop
    results := results || to_jsonb(rec);
  end loop;
  
  return results;
exception
  when others then
    -- Return error information as JSON
    return json_build_object(
      'error', true,
      'message', SQLERRM,
      'code', SQLSTATE,
      'processed_query', processed_query
    );
end;
$$;

-- Test the fixed function
SELECT public.exec_sql(
  'SELECT $1::text as test_param, $2::integer as test_number',
  '["hello", 42]'::jsonb
) as test_result; 