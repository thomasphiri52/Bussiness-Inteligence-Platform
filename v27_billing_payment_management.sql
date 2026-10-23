-- V27 Billing & Payment Management
-- Apply only after reviewing the existing V19/V22 RLS policies in a non-production project.
-- This migration adds helpful indexes only; it does not broaden permissions or auto-create permissive policies.
create index if not exists invoices_org_created_idx on public.invoices (organisation_id, created_at desc);
create index if not exists invoices_org_due_status_idx on public.invoices (organisation_id, due_date, status);
create index if not exists payments_org_invoice_paid_idx on public.payments (organisation_id, invoice_id, paid_at desc);
-- Required security review before production:
-- 1. Restrict invoice INSERT/UPDATE to admin/project_manager roles within current_organisation_id().
-- 2. Restrict payment INSERT to authorised finance roles within current_organisation_id().
-- 3. Ensure invoice/payment SELECT policies prevent cross-organisation reads and client users only see linked records.
-- 4. Validate payment totals, prevent duplicate gateway webhooks, and implement an immutable audit trail server-side.
-- Frontend role checks are convenience only and are not a security boundary.
