-- V28 Client Self-Service Portal migration
-- Apply in a staging project first. This migration adds an explicit profile-to-client link.
-- It does NOT replace or weaken existing RLS policies. Review policies before enabling client access.
alter table public.profiles add column if not exists client_id uuid references public.clients(id) on delete set null;
create index if not exists profiles_client_id_idx on public.profiles(client_id);
create index if not exists projects_client_created_idx on public.projects(client_id, created_at desc);
create index if not exists invoices_client_created_idx on public.invoices(client_id, created_at desc);
create index if not exists documents_client_visibility_idx on public.documents(client_id, visibility, created_at desc);
create index if not exists milestones_project_due_idx on public.milestones(project_id, due_date);
create index if not exists payments_invoice_paid_idx on public.payments(invoice_id, paid_at desc);

-- IMPORTANT SECURITY CHECKLIST
-- 1. Keep RLS enabled on profiles, clients, projects, invoices, payments, milestones, documents.
-- 2. Ensure clients can read only their own profile/client row, projects, invoices and documents.
-- 3. Ensure payments are readable only when their invoice belongs to the authenticated client's linked client_id.
-- 4. Ensure milestones are readable only when their project belongs to that linked client_id.
-- 5. Ensure storage.objects policies allow access only to explicitly client-visible objects for that client.
-- 6. Test with two client users and verify cross-client SELECT attempts return zero rows / permission denied.
-- The frontend filters are convenience only; RLS must enforce all access restrictions.
