-- ============================================================
-- Supabase FIX Script — Run in Supabase Dashboard > SQL Editor
-- Fixes: RLS infinite recursion, missing bank_info table
-- ============================================================

-- 1. Create SECURITY DEFINER function to check role (bypasses RLS, no recursion)
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.get_my_name()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT display_name FROM public.profiles WHERE id = auth.uid()
$$;

-- 2. Drop ALL existing problematic policies
DO $$
DECLARE
  r RECORD;
BEGIN
  -- Drop all policies on profiles
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'profiles' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', r.policyname);
  END LOOP;

  -- Drop all policies on claims
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'claims' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.claims', r.policyname);
  END LOOP;

  -- Drop all policies on bank_info
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'bank_info' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.bank_info', r.policyname);
  END LOOP;

  -- Drop all policies on claim_sequences
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'claim_sequences' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.claim_sequences', r.policyname);
  END LOOP;
END $$;

-- 3. Recreate RLS policies WITHOUT recursion (using security definer functions)

-- Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Claims
ALTER TABLE claims ENABLE ROW LEVEL SECURITY;
CREATE POLICY "claims_select_admin" ON claims FOR SELECT USING (
  public.get_my_role() = 'admin'
);
CREATE POLICY "claims_select_own" ON claims FOR SELECT USING (
  emp = public.get_my_name()
);
CREATE POLICY "claims_insert" ON claims FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "claims_update_admin" ON claims FOR UPDATE USING (
  public.get_my_role() = 'admin'
);
CREATE POLICY "claims_update_own" ON claims FOR UPDATE USING (
  emp = public.get_my_name() AND status IN ('Draft', 'Submitted', 'Auto-Approved')
);

-- 4. Create bank_info table (if not exists)
CREATE TABLE IF NOT EXISTS bank_info (
  employee_name text PRIMARY KEY,
  bank text DEFAULT '',
  acc text DEFAULT '',
  full_name text DEFAULT '',
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE bank_info ENABLE ROW LEVEL SECURITY;
CREATE POLICY "bank_info_select" ON bank_info FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "bank_info_insert" ON bank_info FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "bank_info_update" ON bank_info FOR UPDATE USING (auth.uid() IS NOT NULL);

-- 5. Fix claim_sequences policies
ALTER TABLE claim_sequences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "claim_seq_select" ON claim_sequences FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "claim_seq_insert" ON claim_sequences FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "claim_seq_update" ON claim_sequences FOR UPDATE USING (auth.uid() IS NOT NULL);

-- 6. Enable Realtime
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

-- 7. Seed bank_info data
INSERT INTO bank_info (employee_name, bank, acc, full_name) VALUES
  ('Ahmad Razif', 'Maybank', '1234 5678 9012', 'Ahmad Razif bin Abdullah'),
  ('Siti Aminah', 'CIMB Bank', '8001 2345 6789', 'Siti Aminah binti Yusof'),
  ('Lee Wei Jian', '', '', ''),
  ('Priya Nair', 'RHB Bank', '5566 7788 9900', 'Priya d/o Nair Kumar')
ON CONFLICT (employee_name) DO NOTHING;

-- 8. Clean up test data in claim_sequences (if any)
-- DELETE FROM claim_sequences WHERE last_number = 0 AND year = 2026;

-- DONE! Now test by signing up a user in the app.
