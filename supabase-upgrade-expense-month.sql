-- ============================================================
-- Upgrade: Add expense_month + duplicate prevention + GL code mapping
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. Add expense_month column (format: 'YYYY-MM')
ALTER TABLE claims ADD COLUMN IF NOT EXISTS expense_month text;

-- 2. Backfill existing data: use date to populate expense_month
UPDATE claims SET expense_month = to_char(date, 'YYYY-MM') WHERE expense_month IS NULL;

-- 3. Duplicate prevention index
-- Prevents same employee/company submitting same amount+description for the same expense month
-- (excludes Rejected and Draft claims)
DROP INDEX IF EXISTS claims_dup_check;
CREATE UNIQUE INDEX IF NOT EXISTS claims_dup_check
  ON claims (emp, expense_month, amount, description)
  WHERE status NOT IN ('Rejected', 'Draft');

-- 4. GL Code mapping table for P/L integration
CREATE TABLE IF NOT EXISTS gl_codes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  category text NOT NULL UNIQUE,
  gl_code text NOT NULL,
  gl_name text NOT NULL DEFAULT '',
  created_at timestamptz DEFAULT now()
);

-- 5. Seed default GL codes (adjust codes to match your P/L system)
INSERT INTO gl_codes (category, gl_code, gl_name) VALUES
  ('Utilities', '5100', 'Utilities Expense'),
  ('Maintenance & Repair', '5200', 'Maintenance & Repair Expense'),
  ('Housekeeping & Cleaning', '5300', 'Housekeeping Expense'),
  ('Laundry', '5310', 'Laundry Expense'),
  ('Daily Products', '5400', 'Daily Products Expense'),
  ('Hospitality Items', '5410', 'Hospitality Items Expense'),
  ('Electrical & Unit Setup', '5500', 'Electrical & Setup Expense'),
  ('Office Expenses', '5600', 'Office Expense'),
  ('Employee Welfare', '5700', 'Employee Welfare Expense'),
  ('Outsource Cleaning Staff', '5800', 'Outsource Cleaning Expense'),
  ('Unit Renovation', '5900', 'Renovation Expense'),
  ('Other', '5999', 'Other Expense')
ON CONFLICT (category) DO NOTHING;

-- 6. Enable RLS on gl_codes
ALTER TABLE gl_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone authenticated can read gl_codes" ON gl_codes FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Admin can manage gl_codes" ON gl_codes FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- 7. P/L summary view (for future integration)
CREATE OR REPLACE VIEW pl_expense_summary AS
SELECT
  c.expense_month,
  c.unit,
  c.category,
  COALESCE(g.gl_code, '5999') AS gl_code,
  COALESCE(g.gl_name, 'Other Expense') AS gl_name,
  c.pay_type,
  COUNT(*) AS claim_count,
  SUM(c.amount) AS total_amount
FROM claims c
LEFT JOIN gl_codes g ON g.category = c.category
WHERE c.status IN ('Approved', 'Claimed', 'Auto-Approved', 'Company-Paid')
GROUP BY c.expense_month, c.unit, c.category, g.gl_code, g.gl_name, c.pay_type
ORDER BY c.expense_month DESC, c.unit, g.gl_code;
