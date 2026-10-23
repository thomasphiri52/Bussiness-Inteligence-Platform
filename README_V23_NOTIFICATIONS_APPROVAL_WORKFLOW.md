# V23 — Notifications & Approval Workflow

## Included
- Database-backed in-app notification inbox with per-user visibility and mark-as-read.
- Milestone approval requests with pending / approved / changes-requested states and decision notes.
- Database triggers create notifications for organisation staff when a request is submitted and notify the requester after a staff decision.
- Portfolio section at `#v23-workflows` using the existing V19 Supabase URL/public key configuration.

## Setup
1. Back up the database and test in a staging Supabase project.
2. Apply `supabase/v23_notifications_approval_workflow.sql` after the base schema and reviewed V22 client-access migration.
3. Confirm that `profiles.client_id` exists (from the V22 migration), project/client links are correct, and no other permissive policies bypass intended restrictions.
4. Sign in as a staff account and a client account. Test request submission, staff review, notification isolation and cross-client denial.

## Limitations / production checklist
- In-app notifications only. Email and SMS delivery are not implemented; deploy a trusted Supabase Edge Function and configure provider secrets if email is required.
- Review the composite milestone/project foreign key against your actual schema before applying. If the deployed schema differs, adapt the migration rather than running blindly.
- Existing permissive RLS policies combine with OR. Audit all policies and grants; this starter migration is not a security certification.
- Approval decisions update the request record only; they do not automatically change milestone, invoice, or payment state.
- Never expose a service-role key in browser code.
