# V29 — Client Communication & Support Centre

## Features
- Create support tickets with category and priority.
- List account-visible tickets, status summaries and ticket conversations.
- Reply to a ticket with messages stored in Supabase.
- Tenant/client-scoped row-level security policies and supporting indexes.

## Setup
1. Back up the database and apply `supabase/v29_support_centre.sql` in staging first.
2. Ensure `profiles.client_id` exists (from V28 migration) and each client profile is linked correctly.
3. Confirm Supabase JS is loaded and the existing `tp_v19_supabase_config_v1` URL/public anon config is set.
4. Staff accounts must have one of the existing roles `admin`, `project_manager`, or `analyst`.
5. Test ticket creation, replies, staff reads/updates, and cross-client/cross-organisation denials with separate accounts.

## Security notes
- Client users can create tickets only for their linked client record; staff can read/update tickets within their organisation.
- Messages are scoped through their parent ticket and organisation.
- Review the existing `profiles`, `clients` and organisation policies; this migration assumes `current_organisation_id()` and `current_user_role()` exist as in the starter schema.
- The frontend does not send email notifications. Add a trusted server-side notification service only after testing RLS and rate limits.
- No service-role key belongs in browser code.
