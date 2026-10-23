-- V24 reporting audit starter. Apply only after reviewing the existing schema and policies.
create table if not exists public.report_email_events (
 id uuid primary key default gen_random_uuid(),
 organisation_id uuid not null references public.organisations(id) on delete cascade,
 requested_by uuid not null references auth.users(id) on delete cascade,
 period_days integer not null check (period_days in (7,30,90)),
 recipient_email text not null,
 status text not null default 'requested' check (status in ('requested','sent','failed')),
 provider_id text, error_code text, created_at timestamptz not null default now()
);
alter table public.report_email_events enable row level security;
drop policy if exists "staff read own organisation report email events" on public.report_email_events;
create policy "staff read own organisation report email events" on public.report_email_events for select to authenticated using (organisation_id = public.current_organisation_id() and public.current_user_role() in ('admin','project_manager','analyst'));
-- No direct client INSERT/UPDATE policy: event writes should be performed by the trusted Edge Function.
