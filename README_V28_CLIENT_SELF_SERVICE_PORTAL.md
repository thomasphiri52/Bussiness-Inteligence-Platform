# V28 — Client Self-Service Portal

## Included
- Read-only client workspace for linked projects, progress, milestones, invoices, recorded payments and client-visible document metadata.
- Client portal metrics and CSV export of the signed-in user's visible data.
- Supabase client uses the existing V19 browser configuration and authentication session.
- SQL migration adds `profiles.client_id` and indexes for client portal queries.

## Setup
1. Back up your database and test in a staging Supabase project.
2. Apply `supabase/v28_client_self_service.sql`.
3. Link each client's auth profile to the correct `clients.id` using `profiles.client_id`; make sure `profiles.role` is `client` and `organisation_id` is correct.
4. Review existing RLS policies before exposing this portal. The migration intentionally does not create broad access policies because the correct policy logic depends on your existing production policies.
5. Test using at least two client accounts. Verify that each can see only their own projects, invoices, payments, milestones, and documents. Test Storage object access separately.
6. Deploy the updated `index.html` and confirm the existing Supabase JS client is available on the page.

## Security and limitations
- Front-end filtering is not security. Existing RLS policies must enforce tenant and client boundaries.
- Client role accounts only are admitted by the portal UI; database RLS must independently enforce this.
- Document metadata is shown, but this version does not create public storage links or grant file access. Storage must use private buckets and reviewed policies.
- Portal is read-only; invoice creation, payment recording, refunds, and support messaging remain in staff workflows.
- Do not expose real client data until cross-client authorization tests pass.
