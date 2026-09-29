-- Apply in TEST first. One row represents one actual payment or a voided payment.
create table if not exists public.owner_settlements (
  id uuid primary key default gen_random_uuid(),
  unit_name text not null,
  settlement_month text not null check (settlement_month ~ '^\d{4}-(0[1-9]|1[0-2])$'),
  owner_name text not null default '',
  kind text not null check (kind in ('profit_distribution', 'owner_reimbursement')),
  amount numeric(12,2) not null check (amount > 0),
  paid_on date not null,
  status text not null default 'paid' check (status in ('paid', 'void')),
  payment_reference text not null default '',
  note text not null default '',
  source_claim_id text,
  proof_ref text not null check (proof_ref <> ''),
  report_snapshot jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  void_reason text not null default '',
  check (kind <> 'owner_reimbursement' or nullif(source_claim_id, '') is not null)
);

create index if not exists owner_settlements_unit_month_idx
  on public.owner_settlements (unit_name, settlement_month, status);

create unique index if not exists owner_settlements_payment_ref_unique
  on public.owner_settlements (unit_name, payment_reference)
  where status = 'paid' and payment_reference <> '';

create or replace function public.owner_settlement_void_only()
returns trigger language plpgsql as $$
begin
  if old.status <> 'paid' or new.status <> 'void'
     or new.void_reason = ''
     or (to_jsonb(new) - 'status' - 'void_reason' - 'updated_at')
        <> (to_jsonb(old) - 'status' - 'void_reason' - 'updated_at') then
    raise exception 'Only voiding a paid settlement is allowed';
  end if;
  return new;
end;
$$;

drop trigger if exists owner_settlement_void_only_trigger on public.owner_settlements;
create trigger owner_settlement_void_only_trigger before update on public.owner_settlements
  for each row execute function public.owner_settlement_void_only();

alter table public.owner_settlements enable row level security;

drop policy if exists owner_settlements_manager_select on public.owner_settlements;
drop policy if exists owner_settlements_manager_insert on public.owner_settlements;
drop policy if exists owner_settlements_manager_update on public.owner_settlements;

create policy owner_settlements_manager_select on public.owner_settlements
  for select to authenticated using (public.get_my_role() in ('admin', 'manager'));
create policy owner_settlements_manager_insert on public.owner_settlements
  for insert to authenticated with check (public.get_my_role() in ('admin', 'manager') and status = 'paid');
create policy owner_settlements_manager_update on public.owner_settlements
  for update to authenticated using (public.get_my_role() in ('admin', 'manager'))
  with check (public.get_my_role() in ('admin', 'manager') and status = 'void' and void_reason <> '');

revoke all on table public.owner_settlements from anon;
revoke all on table public.owner_settlements from authenticated;
grant select, insert, update on table public.owner_settlements to authenticated;
grant select, insert, update on table public.owner_settlements to service_role;
