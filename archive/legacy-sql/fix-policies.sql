-- Run this in Supabase SQL Editor
-- Adds DELETE policies for claims table

DROP POLICY IF EXISTS "Employee can delete own claims" ON claims;
DROP POLICY IF EXISTS "Admin can delete any claim" ON claims;

CREATE POLICY "Employee can delete own claims" ON claims
  FOR DELETE USING (
    emp = public.get_my_name()
    AND status IN ('Draft', 'Submitted')
  );

CREATE POLICY "Admin can delete any claim" ON claims
  FOR DELETE USING (
    public.get_my_role() = 'admin'
  );

-- error_logs policies (safe to re-run)
DROP POLICY IF EXISTS "Service role can read error logs" ON error_logs;
DROP POLICY IF EXISTS "Anon can insert error logs" ON error_logs;
DROP POLICY IF EXISTS "Anon can read error logs" ON error_logs;
DROP POLICY IF EXISTS "Service role can update error logs" ON error_logs;
DROP POLICY IF EXISTS "Anon can update error logs" ON error_logs;
DROP POLICY IF EXISTS "Anon can delete error logs" ON error_logs;

CREATE POLICY "Service role can read error logs" ON error_logs FOR SELECT TO service_role USING (true);
CREATE POLICY "Anon can insert error logs" ON error_logs FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Anon can read error logs" ON error_logs FOR SELECT TO anon USING (true);
CREATE POLICY "Service role can update error logs" ON error_logs FOR UPDATE TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Anon can update error logs" ON error_logs FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Anon can delete error logs" ON error_logs FOR DELETE TO anon USING (true);

