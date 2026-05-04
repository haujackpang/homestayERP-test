create table if not exists public.unit_unavailability (
  id bigserial primary key,
  external_id text not null,
  code text,
  source_id text,
  hp_unit_id text,
  unit_name text not null default '',
  property_name text not null default '',
  start_date date not null,
  end_date date not null,
  nights integer not null default 0,
  reason text not null default 'unavailable',
  source text not null default 'hostplatform_type6',
  raw_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint unit_unavailability_external_id_key unique (external_id)
);

create index if not exists unit_unavailability_hp_unit_id_idx
  on public.unit_unavailability (hp_unit_id);

create index if not exists unit_unavailability_period_idx
  on public.unit_unavailability (start_date, end_date);

alter table public.unit_unavailability enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'unit_unavailability'
      and policyname = 'authenticated_read_unit_unavailability'
  ) then
    create policy authenticated_read_unit_unavailability
      on public.unit_unavailability
      for select
      to authenticated
      using (true);
  end if;
end
$$;

insert into public.unit_unavailability (
  external_id,
  code,
  source_id,
  hp_unit_id,
  unit_name,
  property_name,
  start_date,
  end_date,
  nights,
  reason,
  source,
  raw_data,
  created_at,
  updated_at
)
select
  r.ext_id,
  r.code,
  r.source_id,
  r.hp_unit_id,
  coalesce(r.unit_name, r.unit_raw, ''),
  coalesce(r.property_name, ''),
  r.start_date,
  r.end_date,
  coalesce(r.nights, 0),
  'unavailable',
  'hostplatform_type6',
  coalesce(r.raw_data, '{}'::jsonb),
  coalesce(r.ext_created_at, now()),
  now()
from public.reservations r
where r.booking_type = 6
  and r.ext_id is not null
  and r.start_date is not null
  and r.end_date is not null
on conflict (external_id) do update
set
  code = excluded.code,
  source_id = excluded.source_id,
  hp_unit_id = excluded.hp_unit_id,
  unit_name = excluded.unit_name,
  property_name = excluded.property_name,
  start_date = excluded.start_date,
  end_date = excluded.end_date,
  nights = excluded.nights,
  reason = excluded.reason,
  source = excluded.source,
  raw_data = excluded.raw_data,
  updated_at = now();
