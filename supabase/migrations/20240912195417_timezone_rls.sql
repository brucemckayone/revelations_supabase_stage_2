-- Policy for reading dance records
CREATE POLICY "Users can read any dance" ON public.user_timezones
FOR SELECT
TO anon, authenticated
USING (true);


create policy "Users can read their own timezone" on public.user_timezones
for select
to authenticated
using (
    user_id = auth.uid()
);

create policy "Users can update their own timezone" on public.user_timezones
for update
to authenticated
using (
    user_id = auth.uid()
);

create policy "Users can insert their own timezone" on public.user_timezones
for insert
to authenticated
with check (
    user_id = auth.uid()
);

create policy "Users can delete their own timezone" on user_timezones
for delete
to authenticated
using (
    user_id = auth.uid()
);