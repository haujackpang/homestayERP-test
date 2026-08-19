-- Reservation-level guest-requested extra service records.
-- Apply to test first. Do not run against live unless live promotion is explicitly approved.
-- The report label is intentionally fixed as "Extra cleaning" even when the actual
-- guest request involved cleaning, laundry, hospitality/linen change, or a combination.

create table if not exists public.reservation_extra_services (
  id uuid primary key default gen_random_uuid(),
  reservation_code text not null,
  unit_name text not null,
  service_date date not null default current_date,
  quantity integer not null default 1 check (quantity > 0),
  unit_amount numeric(12,2) not null check (unit_amount > 0),
  description text not null default 'Extra cleaning',
  status text not null default 'Completed' check (status in ('Completed', 'Cancelled')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists reservation_extra_services_unit_date_idx
  on public.reservation_extra_services (unit_name, service_date);

create index if not exists reservation_extra_services_reservation_idx
  on public.reservation_extra_services (reservation_code, status);

alter table public.reservation_extra_services enable row level security;

drop policy if exists "reservation_extra_services_manager_select" on public.reservation_extra_services;
drop policy if exists "reservation_extra_services_manager_insert" on public.reservation_extra_services;
drop policy if exists "reservation_extra_services_manager_update" on public.reservation_extra_services;
drop policy if exists "reservation_extra_services_manager_delete" on public.reservation_extra_services;

create policy "reservation_extra_services_manager_select"
  on public.reservation_extra_services for select to authenticated
  using (public.get_my_role() in ('admin', 'manager'));

create policy "reservation_extra_services_manager_insert"
  on public.reservation_extra_services for insert to authenticated
  with check (public.get_my_role() in ('admin', 'manager'));

create policy "reservation_extra_services_manager_update"
  on public.reservation_extra_services for update to authenticated
  using (public.get_my_role() in ('admin', 'manager'))
  with check (public.get_my_role() in ('admin', 'manager'));

create policy "reservation_extra_services_manager_delete"
  on public.reservation_extra_services for delete to authenticated
  using (public.get_my_role() in ('admin', 'manager'));

grant select, insert, update, delete
  on table public.reservation_extra_services to authenticated, service_role;

-- Keep Data API privileges explicit for this newly-created public table.
revoke all on table public.reservation_extra_services from anon;
revoke references, trigger, truncate on table public.reservation_extra_services from authenticated, service_role;
