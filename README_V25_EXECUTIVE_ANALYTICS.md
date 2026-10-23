# V25 — Executive Analytics & Scheduled Reports

## Included
- Executive metrics: project count, average progress, open tasks, overdue tasks/milestones, project health distribution and task status distribution.
- CSV export for loaded projects, tasks and milestones.
- User-owned recurring report schedule (daily, weekly, monthly), tied to the signed-in staff account email.
- Scheduled Supabase Edge Function that checks a server-only scheduler secret, processes due schedules and sends summary emails through Resend.

## Setup
1. Back up the database and test in a staging Supabase project first.
2. Apply `supabase/v25_executive_schedules.sql` after reviewing existing V19–V24 schema and policies.
3. Deploy `supabase/functions/v25-scheduled-report/index.ts` as Edge Function `v25-scheduled-report`.
4. Configure Edge Function secrets: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`, `REPORT_FROM_EMAIL`, `V25_SCHEDULER_SECRET`. Use a long random secret for `V25_SCHEDULER_SECRET`; never store it in HTML, GitHub, or browser localStorage.
5. Configure a trusted external scheduler (e.g. Supabase Cron / pg_cron + pg_net) to POST to the Edge Function URL every 15 minutes with header `x-scheduler-secret: <same secret>`. Store the secret in a server-side secret store such as Supabase Vault; do not hardcode it in committed SQL.
6. Sign in as `admin`, `project_manager`, or `analyst`; refresh analytics and save your schedule. Schedules email only the owner's configured account email.
7. Test daily/weekly/monthly next-run calculations, overlapping invocations, failed email provider responses, disabled schedules, and cross-organisation isolation.

## Important limitations
- The executive metrics reflect rows returned by the signed-in user's Supabase policies. Check RLS and organisation scope before real customer data is used.
- The scheduled Edge Function uses the service-role key only server-side, then explicitly filters business tables by the schedule's organisation. Review this function before production.
- The scheduler endpoint is protected by a server-only shared secret; rotate it if exposed, add monitoring/rate controls, and use a managed secret store. This starter does not provide a full atomic job-claim/locking system, so overlapping cron invocations should be prevented by scheduler configuration and tested.
- Schedule creation/update is constrained to the current user and organisation; however, validate schema policy behavior in staging before rollout.
- Email delivery requires a deployed function, valid Resend API key, verified sender domain, and a configured recurring trigger. No emails are sent until configured.
- This is a starter implementation, not a security certification or a substitute for a production review.
