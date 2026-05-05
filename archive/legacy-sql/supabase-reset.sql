-- ============================================================
-- COMPLETE DATABASE RESET for Home Expense System
-- Run in Supabase Dashboard > SQL Editor
-- WARNING: This drops ALL existing tables and recreates them
-- ============================================================

-- 1. Drop existing tables (cascade to remove dependencies)
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS claims CASCADE;
DROP TABLE IF EXISTS bank_info CASCADE;
DROP TABLE IF EXISTS claim_sequences CASCADE;
DROP TABLE IF EXISTS claim_counter CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- 2. Drop existing functions
DROP FUNCTION IF EXISTS public.get_my_role();
DROP FUNCTION IF EXISTS public.get_my_name();
DROP FUNCTION IF EXISTS public.handle_new_user();

-- ============================================================
-- CREATE TABLES
-- ============================================================

-- 3. Profiles (linked to Supabase Auth)
CREATE TABLE profiles (
  id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email text NOT NULL,
  full_name text NOT NULL DEFAULT '',
  role text NOT NULL DEFAULT 'employee' CHECK (role IN ('employee', 'manager', 'admin')),
  created_at timestamptz DEFAULT now()
);

-- 4. Claims (flat structure - employee name stored directly)
CREATE TABLE claims (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  claim_id text NOT NULL UNIQUE,
  emp text DEFAULT '',
  unit text DEFAULT '',
  category text DEFAULT '',
  description text NOT NULL,
  amount numeric(12,2) NOT NULL,
  date date NOT NULL,
  status text NOT NULL CHECK (status IN ('Draft','Submitted','Approved','Rejected','Claimed','Auto-Approved','Company-Paid')),
  reject_reason text DEFAULT '',
  slip_ref text DEFAULT '',
  receipt_refs text DEFAULT '',
  payment_slip_refs text DEFAULT '',
  pay_type text NOT NULL CHECK (pay_type IN ('employee','company')),
  submitted_by text NOT NULL CHECK (submitted_by IN ('self','manager')),
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 5. Bank info (keyed by employee name)
CREATE TABLE bank_info (
  employee_name text PRIMARY KEY,
  bank text DEFAULT '',
  acc text DEFAULT '',
  full_name text DEFAULT '',
  updated_at timestamptz DEFAULT now()
);

-- 6. Claim sequences (counter per year)
CREATE TABLE claim_sequences (
  year int PRIMARY KEY,
  last_number int NOT NULL DEFAULT 0
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_claims_status ON claims(status);
CREATE INDEX idx_claims_emp ON claims(emp);
CREATE INDEX idx_claims_date ON claims(date);

-- ============================================================
-- SECURITY DEFINER FUNCTIONS (avoid RLS recursion)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.get_my_name()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT full_name FROM public.profiles WHERE id = auth.uid()
$$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Claims
ALTER TABLE claims ENABLE ROW LEVEL SECURITY;
CREATE POLICY "claims_select_admin" ON claims FOR SELECT USING (
  public.get_my_role() IN ('admin', 'manager')
);
CREATE POLICY "claims_select_own" ON claims FOR SELECT USING (
  emp = public.get_my_name()
);
CREATE POLICY "claims_insert" ON claims FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "claims_update_admin" ON claims FOR UPDATE USING (
  public.get_my_role() IN ('admin', 'manager')
);
CREATE POLICY "claims_update_own" ON claims FOR UPDATE USING (
  emp = public.get_my_name() AND status IN ('Draft', 'Submitted', 'Auto-Approved')
);

-- Bank info
ALTER TABLE bank_info ENABLE ROW LEVEL SECURITY;
CREATE POLICY "bank_select" ON bank_info FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "bank_insert" ON bank_info FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "bank_update" ON bank_info FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Claim sequences
ALTER TABLE claim_sequences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "seq_select" ON claim_sequences FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "seq_insert" ON claim_sequences FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "seq_update" ON claim_sequences FOR UPDATE USING (auth.uid() IS NOT NULL);

-- ============================================================
-- REALTIME
-- ============================================================
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE claims;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE bank_info;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- SEED DATA
-- ============================================================

-- Bank info for demo employees
INSERT INTO bank_info (employee_name, bank, acc, full_name) VALUES
  ('Ahmad Razif', 'Maybank', '1234 5678 9012', 'Ahmad Razif bin Abdullah'),
  ('Siti Aminah', 'CIMB Bank', '8001 2345 6789', 'Siti Aminah binti Yusof'),
  ('Lee Wei Jian', '', '', ''),
  ('Priya Nair', 'RHB Bank', '5566 7788 9900', 'Priya d/o Nair Kumar')
ON CONFLICT (employee_name) DO NOTHING;

-- Claim sequence counter
INSERT INTO claim_sequences (year, last_number) VALUES (2026, 9)
ON CONFLICT (year) DO NOTHING;

-- ============================================================
-- DONE! Now:
-- 1. Go to Authentication > Settings > make sure Email provider is ON
-- 2. Open home_expense.htm in browser
-- 3. Sign up first user (will become the role you choose)
-- ============================================================
