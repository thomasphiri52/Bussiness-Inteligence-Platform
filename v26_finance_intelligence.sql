-- V26 Finance Intelligence: performance indexes only. Does not alter RLS or financial records.
-- Review and apply in a staging Supabase project first.
create index if not exists invoices_org_created_idx on public.invoices (organisation_id, created_at desc);
create index if not exists invoices_org_due_status_idx on public.invoices (organisation_id, due_date, status);
create index if not exists payments_org_paid_at_idx on public.payments (organisation_id, paid_at desc);
create index if not exists payments_invoice_id_idx on public.payments (invoice_id);
