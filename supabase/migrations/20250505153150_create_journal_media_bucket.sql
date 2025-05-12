-- Create a storage bucket for journal media attachments
insert into storage.buckets (id, name, public, avif_autodetection)
values ('journal_media', 'journal_media', false, false);
comment on table storage.objects is 'Media attachments for journal entries';

-- Set up access policies for the storage bucket
create policy "Users can view their own journal media"
on storage.objects for select
to authenticated
using (
  bucket_id = 'journal_media' and 
  (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can upload their own journal media"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'journal_media' and 
  (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update their own journal media"
on storage.objects for update
to authenticated
using (
  bucket_id = 'journal_media' and 
  (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete their own journal media"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'journal_media' and 
  (storage.foldername(name))[1] = auth.uid()::text
); 