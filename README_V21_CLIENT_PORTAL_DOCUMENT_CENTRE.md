# V21 — Client Portal & Document Centre

## Features
- Signed-in portal view of projects and milestones allowed by current RLS.
- Upload project documents to the private `client-documents` Supabase Storage bucket.
- Save document metadata to `public.documents`; failed metadata writes attempt to remove the uploaded object.
- Short-lived signed download URL generation for records the current session can read from storage.
- Milestone approval requests submitted as project messages for staff review.
- 10 MB UI upload limit and file extension allowlist. Storage bucket also carries a size and MIME-type configuration.

## Setup
1. Configure the V19 Supabase URL and public anon key and sign in. Never put a service-role key in browser code.
2. Apply `supabase/schema.sql` if not already applied.
3. Apply `supabase/v21_client_portal_storage.sql` in the Supabase SQL Editor.
4. Test using separate staff and client accounts in a non-production project.
5. Configure Auth redirect URLs and review bucket MIME types against your business requirements.

## Critical security limitation
The inherited schema is organisation-scoped, not client-specific. A client account in an organisation may be able to read more records than intended if relying on current policies. The UI filters internal document metadata but client-side filtering is not an access control. The included storage policies allow staff only; client downloads will fail until a trusted Edge Function or carefully designed client-specific Storage RLS verifies project/client membership and visibility. Implement client-specific RLS for projects, milestones, documents and messages before onboarding customers. The approval request is stored as a message; it does not constitute a legal sign-off or automatically change milestone status.

## Validation
JavaScript syntax is checked with Node when available and ZIP integrity is tested when packaged. No live Supabase instance is configured by this archive, so real database/storage behavior must be tested in your own project.
