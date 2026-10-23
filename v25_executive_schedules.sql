-- V25 recurring report schedules. Review schema and apply in staging first.
create table if not exists public.report_schedules (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null unique references auth.users(id) on delete cascade,
 organisation_id uuid not null references public.organisations(id) on delete cascade,
 recipient_email text not null,
 frequency text not null check (frequency in ('daily','weekly','monthly')),
 enabled boolean not null default true,
 next_run_at timestamptz not null default now(),
 last_run_at timestamptz,
 last_status text not null default 'pending' check (last_status in ('pending','sent','failed')),
 last_error_code text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.report_schedules enable row level security;
drop policy if exists "schedule owner read" on public.report_schedules;
create policy "schedule owner read" on public.report_schedules for select to authenticated using (owner_id = auth.uid() and organisation_id = public.current_organisation_id());
drop policy if exists "staff create own report schedule" on public.report_schedules;
create policy "staff create own report schedule" on public.report_schedules for insert to authenticated with check (owner_id = auth.uid() and organisation_id = public.current_organisation_id() and recipient_email = (auth.jwt() ->> 'email') and public.current_user_role() in ('admin','project_manager','analyst'));
drop policy if exists "staff update own report schedule" on public.report_schedules;
create policy "staff update own report schedule" on public.report_schedules for update to authenticated using (owner_id = auth.uid() and organisation_id = public.current_organisation_id() and public.current_user_role() in ('admin','project_manager','analyst')) with check (owner_id = auth.uid() and organisation_id = public.current_organisation_id() and recipient_email = (auth.jwt() ->> 'email'));
revoke delete on public.report_schedules from authenticated;
create index if not exists report_schedules_due_idx on public.report_schedules(enabled,next_run_at) where enabled=true;
-- No browser permissions for arbitrary recipient addresses. The scheduler function runs with service role
-- only after checking a server-only V25_SCHEDULER_SECRET header.
