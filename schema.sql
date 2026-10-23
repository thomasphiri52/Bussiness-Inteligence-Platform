-- Thomas Phiri Portfolio V19: Supabase PostgreSQL starter schema
-- Review and test in a non-production project before using real customer data.
create extension if not exists pgcrypto;

create table if not exists public.organisations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  organisation_id uuid references public.organisations(id) on delete set null,
  full_name text,
  role text not null default 'client' check (role in ('admin','project_manager','analyst','client')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  name text not null, email text, company text, status text not null default 'lead', owner_id uuid references public.profiles(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.opportunities (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  client_id uuid references public.clients(id) on delete set null, title text not null, stage text not null default 'new',
  amount numeric(12,2) not null default 0 check (amount >= 0), expected_close date, owner_id uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  client_id uuid references public.clients(id) on delete set null, name text not null, status text not null default 'planned',
  health text not null default 'healthy' check (health in ('healthy','at_risk','critical')), progress integer not null default 0 check (progress between 0 and 100),
  start_date date, due_date date, owner_id uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.milestones (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade, title text not null, status text not null default 'pending', due_date date, completed_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null, client_id uuid references public.clients(id) on delete set null,
  title text not null, storage_path text not null, visibility text not null default 'client', uploaded_by uuid references public.profiles(id), created_at timestamptz not null default now()
);
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  client_id uuid references public.clients(id) on delete set null, project_id uuid references public.projects(id) on delete set null,
  invoice_number text not null, amount numeric(12,2) not null check (amount >= 0), currency char(3) not null default 'ZAR',
  status text not null default 'draft' check (status in ('draft','sent','paid','overdue','void')), due_date date, created_at timestamptz not null default now(),
  unique(organisation_id, invoice_number)
);
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  invoice_id uuid not null references public.invoices(id) on delete cascade, amount numeric(12,2) not null check (amount > 0),
  paid_at timestamptz, provider_reference text, status text not null default 'recorded', created_at timestamptz not null default now()
);
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null, title text not null, description text, status text not null default 'todo',
  due_date date, assigned_to uuid references public.profiles(id), created_by uuid references public.profiles(id), created_at timestamptz not null default now()
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null, sender_id uuid not null references public.profiles(id), body text not null,
  visibility text not null default 'client', created_at timestamptz not null default now()
);
create table if not exists public.audit_events (
  id bigint generated always as identity primary key, organisation_id uuid references public.organisations(id) on delete set null,
  actor_id uuid references public.profiles(id) on delete set null, action text not null, entity_type text, entity_id text,
  metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);

-- Helper functions. SECURITY DEFINER functions are fixed to public schema and use a safe search_path.
create or replace function public.current_organisation_id() returns uuid
language sql stable security definer set search_path = public, pg_temp
as $$ select organisation_id from public.profiles where id = auth.uid() limit 1 $$;
create or replace function public.current_user_role() returns text
language sql stable security definer set search_path = public, pg_temp
as $$ select role from public.profiles where id = auth.uid() limit 1 $$;

-- Provision a profile after a user registers. New users are clients by default; promote roles only via trusted admin process.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public, pg_temp
as $$ begin insert into public.profiles (id, full_name, role) values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), 'client') on conflict (id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- Enable RLS on all tenant-scoped business tables.
do $$ declare t text; begin
 foreach t in array array['clients','opportunities','projects','milestones','documents','invoices','payments','tasks','messages','audit_events'] loop
  execute format('alter table public.%I enable row level security', t);
 end loop;
end $$;
alter table public.organisations enable row level security;
alter table public.profiles enable row level security;

-- Profiles: users can read profiles in their organisation and update their own basic profile; role/org changes must be admin-only server operations.
create policy "profile self read" on public.profiles for select to authenticated using (id = auth.uid() or organisation_id = public.current_organisation_id());
create policy "profile self update" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "organisation same tenant read" on public.organisations for select to authenticated using (id = public.current_organisation_id());

-- Shared tenant policies for core tables. Admins/managers/analysts may manage organisation data; clients may read scoped client-facing data.
create policy "clients tenant read" on public.clients for select to authenticated using (organisation_id = public.current_organisation_id());
create policy "clients staff insert" on public.clients for insert to authenticated with check (organisation_id = public.current_organisation_id() and public.current_user_role() in ('admin','project_manager','analyst'));
create policy "clients staff update" on public.clients for update to authenticated using (organisation_id = public.current_organisation_id() and public.current_user_role() in ('admin','project_manager','analyst')) with check (organisation_id = public.current_organisation_id() and public.current_user_role() in ('admin','project_manager','analyst'));
create policy "clients admin delete" on public.clients for delete to authenticated using (organisation_id = public.current_organisation_id() and public.current_user_role() = 'admin');

-- Generate consistent organisation-scoped policies for operational tables.
do $$ declare t text; begin
 foreach t in array array['opportunities','projects','milestones','documents','invoices','payments','tasks','messages'] loop
  execute format('create policy %I on public.%I for select to authenticated using (organisation_id = public.current_organisation_id())', t||'_tenant_read', t);
  execute format('create policy %I on public.%I for insert to authenticated with check (organisation_id = public.current_organisation_id() and public.current_user_role() in (''admin'',''project_manager'',''analyst''))', t||'_staff_insert', t);
  execute format('create policy %I on public.%I for update to authenticated using (organisation_id = public.current_organisation_id() and public.current_user_role() in (''admin'',''project_manager'')) with check (organisation_id = public.current_organisation_id() and public.current_user_role() in (''admin'',''project_manager''))', t||'_manager_update', t);
  execute format('create policy %I on public.%I for delete to authenticated using (organisation_id = public.current_organisation_id() and public.current_user_role() = ''admin'')', t||'_admin_delete', t);
 end loop;
end $$;
create policy "audit tenant read" on public.audit_events for select to authenticated using (organisation_id = public.current_organisation_id() and public.current_user_role() in ('admin','project_manager'));
-- No client-side insert/update/delete policy for audit_events: write audit events from a trusted backend/Edge Function.

-- Restrict direct role escalation: do not expose role/org update through the client app.
revoke update (role, organisation_id) on public.profiles from authenticated;
revoke all on public.audit_events from anon, authenticated;
grant select on public.audit_events to authenticated;
grant select, update (full_name) on public.profiles to authenticated;
grant select on public.organisations to authenticated;
grant select, insert, update, delete on public.clients, public.opportunities, public.projects, public.milestones, public.documents, public.invoices, public.payments, public.tasks, public.messages to authenticated;
