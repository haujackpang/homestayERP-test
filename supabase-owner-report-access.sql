-- Owner read-only report access.
-- Apply to test first. Do not run against live unless live promotion is explicitly approved.

alter table public.profiles
  drop constraint if exists profiles_role_check;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('employee', 'manager', 'admin', 'owner'));

create table if not exists public.owner_unit_access (
  owner_id uuid not null references public.profiles(id) on delete cascade,
  unit_name text not null,
  created_at timestamptz not null default now(),
  primary key (owner_id, unit_name)
);

alter table public.owner_unit_access enable row level security;

drop policy if exists "owner_unit_access_admin_select" on public.owner_unit_access;
drop policy if exists "owner_unit_access_admin_insert" on public.owner_unit_access;
drop policy if exists "owner_unit_access_admin_update" on public.owner_unit_access;
drop policy if exists "owner_unit_access_admin_delete" on public.owner_unit_access;
drop policy if exists "owner_unit_access_owner_select" on public.owner_unit_access;

create policy "owner_unit_access_admin_select" on public.owner_unit_access
  for select using (public.get_my_role() = 'admin');

create policy "owner_unit_access_admin_insert" on public.owner_unit_access
  for insert with check (public.get_my_role() = 'admin');

create policy "owner_unit_access_admin_update" on public.owner_unit_access
  for update using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

create policy "owner_unit_access_admin_delete" on public.owner_unit_access
  for delete using (public.get_my_role() = 'admin');

create policy "owner_unit_access_owner_select" on public.owner_unit_access
  for select using (owner_id = auth.uid());
