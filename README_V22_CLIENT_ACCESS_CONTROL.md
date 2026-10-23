# V22 — Client-specific access control

This release adds a security-readiness panel and a staging migration for client-specific row-level security (RLS).

## Included
- `supabase/v22_client_access_control.sql`: adds `profiles.client_id`, identity-derived helper functions, and client-scoped SELECT policies for client records, projects, milestones, client-visible documents/messages, invoices and payments. Opportunities and tasks are staff-only in this policy set.
- `index.html`: V22 rollout checklist and security model notes; checklist state is local to the current page and does not verify server settings.
- V21 client portal warning updated to point to the V22 migration and the need for trusted document-download authorization.

## Apply carefully
1. Back up and use a staging Supabase project first.
2. Review existing RLS policies. PostgreSQL permissive policies combine with OR; any older broad policy can bypass the intended restrictions. This migration drops known V19 tenant-read policy names, but custom policies must be reviewed separately.
3. Apply the SQL migration in the Supabase SQL editor.
4. Use a trusted administrator process to assign `profiles.client_id` to the correct `clients.id`. Do not expose role, organisation, or client assignment changes to client-side users.
5. Test with at least two client accounts from different client records, a staff account, and negative tests for cross-client reads and writes.
6. Keep `client-documents` storage staff-only. Before enabling client downloads, implement a trusted Supabase Edge Function that checks the authenticated user's client link, the document's visibility, its project/client assignment, and the exact storage path before generating a short-lived signed URL.

## Important limitations
- This is a starter migration, not a production security certification. Policies, functions, grants and custom policies must be audited against the deployed schema.
- The existing V21 frontend's direct signed-URL handler is not a secure client authorization boundary. Do not use it to serve client downloads until replaced with the trusted server-side flow.
- The migration does not automatically provision client links, deploy an Edge Function, send notifications, or run tests against your hosted database.
- Never place the Supabase service-role key in browser code.
