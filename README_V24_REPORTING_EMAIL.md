# V24 — Reporting & Automated Email

## Features
- Adds a Project Reporting Centre to `index.html`.
- Loads project, task and milestone data through the signed-in Supabase client, subject to database RLS.
- Exports loaded records to CSV in the browser.
- Sends a summary to the signed-in staff user's own auth email using the `v24-email-report` Supabase Edge Function.
- Edge Function verifies the bearer token, checks the profile role and organisation, queries only that organisation, then sends through Resend.

## Deploy / test
1. Back up the database and use a staging Supabase project first.
2. Confirm existing V19–V23 schema, organisation assignment, role values and RLS.
3. Optional audit migration: run `supabase/v24_reporting_audit.sql` after reviewing it.
4. Deploy `supabase/functions/v24-email-report/index.ts` as Edge Function `v24-email-report`.
5. Set Edge Function secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`, `REPORT_FROM_EMAIL`. Use the Supabase project URL, public anon key, service role key, Resend API key, and a sender address on a verified domain. Never put service-role or Resend secrets in the HTML, GitHub, or `.env.example` committed to source control.
6. Sign in with an admin, project_manager or analyst profile, load report data, export CSV, and send a test report to the same account's email.
7. Verify function logs, Resend delivery, and organisation boundaries using separate test organisations.

## Limitations / safety
- The browser CSV contains only records returned by the signed-in user's policies; check the policies before using real customer data.
- Email is sent only to the authenticated account email; this implementation does not allow arbitrary recipient addresses.
- The server function uses a service role only after authenticating the caller and checking their role and organisation. Review before production, add rate limiting/abuse controls, verify sender identity, and configure monitoring.
- The optional audit insert is best-effort. Provider failure events are visible in Edge Function logs but are not recorded in the audit table by this starter.
- No automatic recurring scheduler is included. This is on-demand reporting, not a scheduled email service.
- Email delivery depends on correct secrets, verified sender domain, Supabase deployment and Resend account status; not live until configured and tested.
