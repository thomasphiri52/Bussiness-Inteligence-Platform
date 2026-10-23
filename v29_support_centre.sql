-- V29 Client Communication & Support Centre
-- Review against your production schema and apply to staging first.
create table if not exists public.support_tickets (
 id uuid primary key default gen_random_uuid(),
 organisation_id uuid not null references public.organisations(id) on delete cascade,
 client_id uuid references public.clients(id) on delete set null,
 created_by uuid not null references public.profiles(id) on delete restrict,
 subject text not null check (length(trim(subject)) between 3 and 140),
 description text not null check (length(trim(description)) between 3 and 6000),
 category text not null default 'other' check (category in ('technical','billing','project','access','other')),
 priority text not null default 'normal' check (priority in ('low','normal','high')),
 status text not null default 'open' check (status in ('open','in_progress','waiting_client','resolved','closed')),
 ticket_number bigint generated always as identity,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.support_ticket_messages (
 id uuid primary key default gen_random_uuid(),
 ticket_id uuid not null references public.support_tickets(id) on delete cascade,
 organisation_id uuid not null references public.organisations(id) on delete cascade,
 sender_id uuid not null references public.profiles(id) on delete restrict,
 body text not null check (length(trim(body)) between 1 and 6000),
 created_at timestamptz not null default now()
);
create index if not exists support_tickets_org_created_idx on public.support_tickets(organisation_id,created_at desc);
create index if not exists support_tickets_client_created_idx on public.support_tickets(client_id,created_at desc);
create index if not exists support_tickets_status_idx on public.support_tickets(organisation_id,status,priority);
create index if not exists support_messages_ticket_created_idx on public.support_ticket_messages(ticket_id,created_at);
alter table public.support_tickets enable row level security;
alter table public.support_ticket_messages enable row level security;
-- Remove policies with these migration-owned names before re-applying.
drop policy if exists v29_ticket_read on public.support_tickets;
drop policy if exists v29_ticket_client_insert on public.support_tickets;
drop policy if exists v29_ticket_staff_update on public.support_tickets;
drop policy if exists v29_message_read on public.support_ticket_messages;
drop policy if exists v29_message_insert on public.support_ticket_messages;
create policy v29_ticket_read on public.support_tickets for select to authenticated
using (organisation_id = public.current_organisation_id() and (public.current_user_role() in ('admin','project_manager','analyst') or (public.current_user_role()='client' and client_id=(select p.client_id from public.profiles p where p.id=auth.uid()))));
create policy v29_ticket_client_insert on public.support_tickets for insert to authenticated
with check (organisation_id = public.current_organisation_id() and created_by=auth.uid() and public.current_user_role()='client' and client_id=(select p.client_id from public.profiles p where p.id=auth.uid()));
create policy v29_ticket_staff_update on public.support_tickets for update to authenticated
using (organisation_id = public.current_organisation_id() and public.current_user_role() in ('admin','project_manager','analyst'))
with check (organisation_id = public.current_organisation_id() and public.current_user_role() in ('admin','project_manager','analyst'));
create policy v29_message_read on public.support_ticket_messages for select to authenticated
using (organisation_id=public.current_organisation_id() and exists(select 1 from public.support_tickets t where t.id=ticket_id and t.organisation_id=public.current_organisation_id() and (public.current_user_role() in ('admin','project_manager','analyst') or (public.current_user_role()='client' and t.client_id=(select p.client_id from public.profiles p where p.id=auth.uid())))));
create policy v29_message_insert on public.support_ticket_messages for insert to authenticated
with check (organisation_id=public.current_organisation_id() and sender_id=auth.uid() and exists(select 1 from public.support_tickets t where t.id=ticket_id and t.organisation_id=public.current_organisation_id() and (public.current_user_role() in ('admin','project_manager','analyst') or (public.current_user_role()='client' and t.client_id=(select p.client_id from public.profiles p where p.id=auth.uid())))));
-- Staff ticket updates are allowed by role. Client ticket creation requires a linked client profile.
-- RLS is the security boundary; test with separate organisations and clients before production.
