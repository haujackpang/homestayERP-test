-- Focused unpaid-claim delete policies.
-- Run in TEST first. Promote to live only after explicit approval.
-- Safe to run multiple times.

begin;

drop policy if exists "Employee can delete own claims" on public.claims;
drop policy if exists "Admin can delete any claim" on public.claims;
drop policy if exists "claims_delete_employee_unpaid" on public.claims;
drop policy if exists "claims_delete_manager_unpaid" on public.claims;

create policy "claims_delete_employee_unpaid" on public.claims
  for delete using (
    emp = public.get_my_name()
    and coalesce(status, '') not in ('Claimed', 'Company-Paid')
  );

create policy "claims_delete_manager_unpaid" on public.claims
  for delete using (
    public.get_my_role() in ('admin', 'manager')
    and coalesce(status, '') <> 'Claimed'
  );

commit;
