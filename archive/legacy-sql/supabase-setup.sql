-- ============================================================
-- Supabase SQL Setup for Home Expense System
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. Profiles table (linked to auth.users)
create table if not exists profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text not null,
  display_name text not null,
  role text not null check (role in ('employee', 'manager', 'admin')),
  created_at timestamptz default now()
);

-- 2. Bank info table
create table if not exists bank_info (
  id uuid default gen_random_uuid() primary key,
  employee_name text not null unique,
  bank text default '',
  acc text default '',
  full_name text default '',
  updated_at timestamptz default now()
);

-- 3. Claims table
create table if not exists claims (
  id uuid default gen_random_uuid() primary key,
  claim_id text not null unique,
  emp text default '',
  unit text default '',
  category text default '',
  description text not null,
  amount numeric(12,2) not null,
  date date not null,
  status text not null check (status in ('Draft','Submitted','Approved','Rejected','Claimed','Auto-Approved','Company-Paid')),
  reject_reason text default '',
  slip_ref text default '',
  receipt_refs text default '',
  payment_slip_refs text default '',
  pay_type text not null check (pay_type in ('employee','company')),
  submitted_by text not null check (submitted_by in ('self','manager')),
  created_by uuid references auth.users(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 4. Claim counter for generating IDs
create table if not exists claim_counter (
  id int primary key default 1 check (id = 1),
  counter int not null default 0
);
insert into claim_counter (id, counter) values (1, 8) on conflict (id) do nothing;

-- 5. Enable Row Level Security
alter table profiles enable row level security;
alter table bank_info enable row level security;
alter table claims enable row level security;
alter table claim_counter enable row level security;

-- 6. RLS Policies

-- Profiles: users can read all profiles, only insert/update own
create policy "Anyone can read profiles" on profiles for select using (true);
create policy "Users can insert own profile" on profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);

-- Bank info: admin can do all, employee can read
create policy "Anyone authenticated can read bank_info" on bank_info for select using (auth.uid() is not null);
create policy "Admin can insert bank_info" on bank_info for insert with check (
  exists (select 1 from profiles where id = auth.uid() and role in ('admin', 'manager'))
);
create policy "Admin can update bank_info" on bank_info for update using (
  exists (select 1 from profiles where id = auth.uid() and role in ('admin', 'manager'))
);

-- Claims: admin can read all, employee can read own
create policy "Admin can read all claims" on claims for select using (
  exists (select 1 from profiles where id = auth.uid() and role in ('admin', 'manager'))
);
create policy "Employee can read own claims" on claims for select using (
  emp = (select display_name from profiles where id = auth.uid())
);
-- Anyone authenticated can insert claims
create policy "Authenticated can insert claims" on claims for insert with check (auth.uid() is not null);
-- Admin can update any claim, employee can update own non-paid claims
create policy "Admin can update any claim" on claims for update using (
  exists (select 1 from profiles where id = auth.uid() and role in ('admin', 'manager'))
);
create policy "Employee can update own claims" on claims for update using (
  emp = (select display_name from profiles where id = auth.uid())
  and status in ('Draft', 'Submitted', 'Auto-Approved')
);

-- Claim counter: anyone authenticated can read/update
create policy "Authenticated can read counter" on claim_counter for select using (auth.uid() is not null);
create policy "Authenticated can update counter" on claim_counter for update using (auth.uid() is not null);

-- 7. Enable Realtime
alter publication supabase_realtime add table claims;
alter publication supabase_realtime add table bank_info;

-- 8. Insert seed data for bank_info
insert into bank_info (employee_name, bank, acc, full_name) values
  ('Ahmad Razif', 'Maybank', '1234 5678 9012', 'Ahmad Razif bin Abdullah'),
  ('Siti Aminah', 'CIMB Bank', '8001 2345 6789', 'Siti Aminah binti Yusof'),
  ('Lee Wei Jian', '', '', ''),
  ('Priya Nair', 'RHB Bank', '5566 7788 9900', 'Priya d/o Nair Kumar')
on conflict (employee_name) do nothing;

-- 9. Insert seed claims data
insert into claims (claim_id, emp, unit, category, description, amount, date, status, reject_reason, slip_ref, pay_type, submitted_by) values
  ('HE-2026-03-00001', 'Ahmad Razif', 'Villa Dahlia', 'Utilities', 'TNB Bill March', 245, '2026-03-01', 'Approved', '', '', 'employee', 'self'),
  ('HE-2026-03-00002', 'Ahmad Razif', '', '', 'Pipe leak repair', 180, '2026-03-05', 'Submitted', '', '', 'employee', 'self'),
  ('HE-2026-03-00003', 'Siti Aminah', '', '', 'Monthly cleaning service', 120, '2026-03-10', 'Rejected', 'Receipt photo not legible', '', 'employee', 'self'),
  ('HE-2026-03-00004', 'Lee Wei Jian', 'Office KL', 'Office Expenses', 'Printer cartridge', 89.50, '2026-03-12', 'Approved', '', '', 'employee', 'self'),
  ('HE-2026-03-00005', 'Priya Nair', 'Villa Mawar', 'Utilities', 'Unifi Monthly Bill', 139, '2026-03-15', 'Claimed', '', 'SLIP-001', 'employee', 'self'),
  ('HE-2026-02-00001', 'Ahmad Razif', 'Office KL', 'Office Expenses', 'Printer ink & stationery', 67, '2026-02-10', 'Approved', '', '', 'employee', 'self'),
  ('HE-2026-02-00002', 'Siti Aminah', 'Villa Dahlia', 'Laundry', 'Linen laundry Feb', 155, '2026-02-18', 'Approved', '', '', 'employee', 'self'),
  ('CO-2026-03-00001', '', 'Villa Mawar', 'Utilities', 'Water bill (company card)', 210, '2026-03-02', 'Company-Paid', '', '', 'company', 'manager'),
  ('MGR-2026-03-00001', 'Ahmad Razif', 'Office KL', 'Employee Welfare', 'Team lunch', 95, '2026-03-08', 'Auto-Approved', '', '', 'employee', 'manager')
on conflict (claim_id) do nothing;
