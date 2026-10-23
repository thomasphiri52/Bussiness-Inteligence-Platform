# V19 — Secure Backend & Live Database Layer

This release adds a Supabase Auth connection panel to the static portfolio and a PostgreSQL schema starter under `supabase/schema.sql`.

## What is included
- Browser-side Supabase client initialisation using the project's URL and public anon/publishable key.
- Email/password sign-in, sign-up and sign-out flows.
- Auth-session status and a protected `profiles` table health check.
- PostgreSQL starter schema for organisations, profiles, clients, opportunities, projects, milestones, documents, invoices, payments, tasks, messages and audit events.
- Row Level Security (RLS) policies and a profile creation trigger.
- Configuration stored locally in the current browser only; the key is not transmitted anywhere other than the configured Supabase project.

## Setup
1. Create a Supabase project.
2. In **SQL Editor**, review and run `supabase/schema.sql`.
3. In **Authentication → Providers**, enable Email and decide whether email confirmation is required.
4. In **Authentication → URL Configuration**, set the site URL and allowed redirect URLs for the deployed site.
5. Open the portfolio's **Secure Backend** section and enter the project URL plus the **public anon/publishable key** from Project Settings → API.
6. Click **Connect & check**, then create an account or sign in.
7. Click **Run health check**. A successful result verifies a query to `profiles` for the current session; it does not mean every business table is fully configured.

## Security warnings — read before using real customer data
- **Never put a Supabase `service_role` or secret key in this static site.** Only use the public anon/publishable key in the browser. Service-role credentials belong only in server-side environment secrets.
- The URL/key form stores configuration in `localStorage` on that browser. Do not use shared/public computers for this configuration. Clear it with **Clear settings** when finished.
- This is a tenant-level starter RLS model, not a completed client-specific isolation model. Before inviting real client accounts, implement and test per-client policies for projects, documents, messages and invoices, plus an explicit admin provisioning flow. New users are assigned the `client` role by default; do not promote roles from browser code.
- The starter `organisations` table does not automatically create or assign an organisation. Provision organisations and link profiles through a trusted admin workflow or a server-side Edge Function.
- Storage buckets, private signed URLs, payment processing, outbound email, backups, rate limiting, monitoring, audit writes and data-retention policies are not automatically configured by this release.
- Avoid storing card data or payment credentials. Record payment status/references only and use a compliant payment provider for transactions.
- Test migrations and RLS in a separate development project first. Have the policies reviewed before production.

## Local preview
Open `index.html`, or run `python -m http.server 8000` and visit `http://localhost:8000`. Supabase SDK loading requires internet access unless you self-host the approved SDK build.

## Deploy
Upload the updated `index.html` and the `supabase/` folder to your repository. The static portfolio deployment itself does not execute SQL; run the SQL in Supabase separately.
