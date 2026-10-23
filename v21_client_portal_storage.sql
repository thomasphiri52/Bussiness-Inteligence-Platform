-- V21 Client Portal & private document storage additions. Review in a staging project first.
-- Creates a private bucket; application limits uploads to 10 MB and a conservative allowlist.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('client-documents', 'client-documents', false, 10485760, array['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','text/csv','text/plain','image/png','image/jpeg'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

-- Storage path convention: organisation UUID / uploader UUID / random filename.
-- These policies are organisation-scoped staff policies, not client-specific isolation.
drop policy if exists v21_staff_upload_org_documents on storage.objects;
create policy v21_staff_upload_org_documents on storage.objects for insert to authenticated
with check (bucket_id = 'client-documents' and (storage.foldername(name))[1] = public.current_organisation_id()::text and public.current_user_role() in ('admin','project_manager','analyst'));
drop policy if exists v21_staff_read_org_documents on storage.objects;
create policy v21_staff_read_org_documents on storage.objects for select to authenticated
using (bucket_id = 'client-documents' and (storage.foldername(name))[1] = public.current_organisation_id()::text and public.current_user_role() in ('admin','project_manager','analyst'));
drop policy if exists v21_staff_delete_org_documents on storage.objects;
create policy v21_staff_delete_org_documents on storage.objects for delete to authenticated
using (bucket_id = 'client-documents' and (storage.foldername(name))[1] = public.current_organisation_id()::text and public.current_user_role() = 'admin');

-- IMPORTANT: this starter migration deliberately limits storage object access to staff roles.
-- For client downloads, implement a trusted Edge Function that checks the requesting user's
-- client_id/project membership and document visibility, then returns a short-lived signed URL.
-- Do not grant all same-organisation clients direct storage access.
