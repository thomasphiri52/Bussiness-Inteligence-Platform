-- V23: in-app notifications and milestone approval workflow.
-- Apply only after reviewing V19 schema and V22 client-access migration in staging.
create extension if not exists pgcrypto;

create unique index if not exists milestones_id_project_id_uq on public.milestones(id, project_id);

create table if not exists public.approval_requests (
 id uuid primary key default gen_random_uuid(),
 organisation_id uuid not null references public.organisations(id) on delete cascade,
 milestone_id uuid not null references public.milestones(id) on delete cascade,
 project_id uuid not null references public.projects(id) on delete cascade,
 requested_by uuid not null references public.profiles(id) on delete restrict,
 status text not null default 'pending' check (status in ('pending','approved','changes_requested')),
 note text check (char_length(note) <= 1200),
 decision_note text check (char_length(decision_note) <= 1200),
 reviewed_by uuid references public.profiles(id) on delete set null,
 created_at timestamptz not null default now(),
 reviewed_at timestamptz,
 constraint approval_request_milestone_project_fk foreign key (milestone_id, project_id) references public.milestones(id, project_id) deferrable initially immediate
);
-- Review the composite foreign key against the deployed schema before applying.

create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(),
 organisation_id uuid not null references public.organisations(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 title text not null check (char_length(title) <= 180),
 body text not null default '' check (char_length(body) <= 1200),
 entity_type text,
 entity_id uuid,
 read_at timestamptz,
 created_at timestamptz not null default now()
);
create index if not exists notifications_user_created_idx on public.notifications(user_id, created_at desc);
create index if not exists approval_requests_org_status_idx on public.approval_requests(organisation_id,status,created_at desc);

alter table public.approval_requests enable row level security;
alter table public.notifications enable row level security;

-- Clients can see only requests they submitted; staff can see requests within their organisation.
drop policy if exists v23_approval_select on public.approval_requests;
create policy v23_approval_select on public.approval_requests for select to authenticated
 using (organisation_id = public.current_organisation_id() and (requested_by = auth.uid() or public.current_user_role() in ('admin','project_manager','analyst')));
drop policy if exists v23_approval_insert on public.approval_requests;
create policy v23_approval_insert on public.approval_requests for insert to authenticated
 with check (
  organisation_id = public.current_organisation_id() and requested_by = auth.uid()
  and exists (select 1 from public.milestones m join public.projects p on p.id=m.project_id
    where m.id=milestone_id and p.id=project_id and m.project_id=approval_requests.project_id
      and m.organisation_id=approval_requests.organisation_id and p.organisation_id=approval_requests.organisation_id)
  and (public.current_user_role() in ('admin','project_manager','analyst') or exists (
    select 1 from public.profiles pr join public.projects p on p.id=approval_requests.project_id
    where pr.id=auth.uid() and pr.client_id is not null and p.client_id=pr.client_id
      and p.organisation_id=approval_requests.organisation_id))
 );
drop policy if exists v23_approval_staff_update on public.approval_requests;
create policy v23_approval_staff_update on public.approval_requests for update to authenticated
 using (organisation_id=public.current_organisation_id() and public.current_user_role() in ('admin','project_manager','analyst') and status='pending')
 with check (organisation_id=public.current_organisation_id() and public.current_user_role() in ('admin','project_manager','analyst') and status in ('approved','changes_requested') and reviewed_by=auth.uid());

-- Inbox rows are private to the target user. Clients cannot insert notifications directly.
drop policy if exists v23_notifications_select on public.notifications;
create policy v23_notifications_select on public.notifications for select to authenticated
 using (organisation_id=public.current_organisation_id() and user_id=auth.uid());
drop policy if exists v23_notifications_update on public.notifications;
create policy v23_notifications_update on public.notifications for update to authenticated
 using (organisation_id=public.current_organisation_id() and user_id=auth.uid())
 with check (organisation_id=public.current_organisation_id() and user_id=auth.uid());
revoke insert, delete on public.notifications from authenticated;

create or replace function public.v23_notify_approval_created() returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
declare staff record; m_title text;
begin
 select title into m_title from public.milestones where id=new.milestone_id;
 for staff in select id from public.profiles where organisation_id=new.organisation_id and role in ('admin','project_manager','analyst') loop
  insert into public.notifications(organisation_id,user_id,title,body,entity_type,entity_id)
  values(new.organisation_id,staff.id,'Milestone approval requested',coalesce(m_title,'Milestone')||' needs review.', 'approval_request',new.id);
 end loop;
 return new;
end $$;
drop trigger if exists v23_approval_created_notify on public.approval_requests;
create trigger v23_approval_created_notify after insert on public.approval_requests for each row execute function public.v23_notify_approval_created();

create or replace function public.v23_notify_approval_decision() returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
declare m_title text;
begin
 if old.status='pending' and new.status in ('approved','changes_requested') then
  select title into m_title from public.milestones where id=new.milestone_id;
  insert into public.notifications(organisation_id,user_id,title,body,entity_type,entity_id)
  values(new.organisation_id,new.requested_by,
   case when new.status='approved' then 'Milestone request approved' else 'Changes requested for milestone' end,
   coalesce(m_title,'Milestone')||case when coalesce(new.decision_note,'')<>'' then ': '||new.decision_note else '.' end,
   'approval_request',new.id);
 end if;
 return new;
end $$;
drop trigger if exists v23_approval_decision_notify on public.approval_requests;
create trigger v23_approval_decision_notify after update of status on public.approval_requests for each row execute function public.v23_notify_approval_decision();

-- Reminder: email/SMS delivery requires a separately deployed trusted Edge Function and provider secrets.
