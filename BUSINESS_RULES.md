# Business Rules

## Core Rules
- Do not invent missing business logic.
- Do not remove validation unless the user explicitly approves.
- Prefer minimal safe changes that fit the existing single-file app pattern.
- If code conflicts with these rules, stop and explain the conflict before changing behavior.

## Environment Rules
- Testing app must use `homestayERP-test`.
- Live app must use `homestay-expenses`.
- `homestayERP-prod` is obsolete and must not be used as the live repo.
- Test Supabase project ref: `afcifzghlkxvnpulahub`.
- Live Supabase project ref: `skwogboredsczcyhlqgn`.
- Missing deployment config must not silently fall back to the test Supabase project.
- If Supabase config is missing, the app should fail clearly instead of showing mixed-environment data.
- Test-only UI, including the `TESTING` watermark, must be based on the test Pages path and not on Supabase URL alone.
- Do not push test changes to live unless explicitly requested.
- A live push means code, workflow, Edge Functions, and required idempotent DB structure only; do not copy or sync table data between test and live.
- Do not expose secret values in chat or committed files.
- Default deployment target is test, not live.
- Live deployment requires explicit user approval in that turn.
- When a change affects business logic, environment handling, release flow, or current priorities, update the memory files before finishing.

## Project Memory Rules
- Before making changes, read:
  `PROJECT_OVERVIEW.md`, `BUSINESS_RULES.md`, `DECISIONS_LOG.md`, `TASK_CONTEXT.md`, `AI_INSTRUCTIONS.md`, `RELEASE_PROCESS.md`
- After making meaningful changes, update the relevant memory files in the same turn.
- Do not leave business-rule changes only inside chat history.
- If code behavior and memory files conflict, stop and surface the conflict before continuing.

## Unit And Mapping Rules
- HostPlatform records must not be treated as permanent internal naming source.
- HostPlatform property alone is not enough for mapping because one property may contain several units.
- Correct mapping key is:
  `HostPlatform property + HostPlatform unit -> Internal Unit`
- Internal unit naming remains controlled by this system.
- Property short code is only a display/report helper, not the full mapping.
- Manual units are internal units.
- HostPlatform synced units should be mapped to internal units through Unit Mapping.
- One internal unit can only be paired to one active HostPlatform property + unit row at a time.
- Once an internal unit is paired, it must be hidden from other mapping dropdowns until that mapping is cleared.

## Reporting Rules
- Manager report page should show reservation details for the selected unit/month.
- Reservation detail fields should include guest name, check-in date, check-out date, nights, and total. Total is rental + extra guest.
- Report sales are assigned by reservation checkout date (`end_date`), not check-in date.
- Report PDF title should use the property + unit name when HostPlatform mapping is available.
- Report PDF booking detail fields should include guest name, check-in date, check-out date, nights, and total. Do not show rental and extra guest as separate columns.
- Report PDF cleaning fee is calculated as `(unit cleaning fee + unit laundry fee) x checkout-month reservation count`.
- Report PDF should show `Cleaning fee` under the shared expenses/expense details area, not under Owner Expenses.
- Report page should show `Cleaning fee` in the `Expenses` section, not in Owner Expenses.
- Report page `Expenses` details should include the calculated `Cleaning fee` row.
- Report page booking summary should not show a separate `Cleaning fee` row because that category is already listed in `Expenses`.
- Report page should label shared expense section as `Expenses`, not `Shared Expenses (Both)`.
- Report page Owner Expenses should show only expenses charged to Owner.
- Homestay profit is calculated as sales minus Subtotal Expenses, where Subtotal Expenses is sharing expenses charged to Both plus calculated Cleaning fee.
- Report PDF homestay management fee is calculated from the unit `Profit Sharing %` against homestay profit.
- Owner expenses should include only expenses charged to Owner, and exclude Cleaning fee and Homestay Management Fee.
- Report page and PDF should show Homestay Management Fee and Owner Profit instead of focusing on Total Expenses.

## Unit Configuration Rules
- Cleaning and laundry rates are unit-level settings.
- Do not rely on unit type for cleaning/laundry rates because the same property and same unit type may still have different rates.
- `Service Fee %` wording must be shown as `Profit Sharing %`.
- Existing database column `service_fee_pct` may remain as implementation detail unless a migration is explicitly approved.

## Logs Rules
- Logs page must show useful operational logs, not only error logs.
- Sync success/failure should be visible in the app.
- Admin changes such as unit mapping, unit activation, and unit configuration should be logged.

## Claims List Rules
- `My Claims` and `All Claims` are claim-review queues for claimable expenses and should not list `Company-Paid` rows.
- `Company-Paid` expenses should still remain visible in dashboard and reporting totals where company spending is summarized.
- Employee and manager/admin claim-list screens should paginate results at 5 rows per page with `Back` and `Next` controls.
- Claim receipt attachments and payout bank slips must not share the same database field.
- `receipt_refs` stores original claim receipts and `payment_slip_refs` stores payout bank slips; `slip_ref` is legacy fallback only during migration.
- The `receipts` bucket stays private. Claim attachments and payout slips must use signed upload/read flows instead of direct browser uploads.
- If the user selected files and upload fails, the claim save/update/mark-claimed action must stop instead of silently continuing.

## Sync Rules
- `sync-units` imports HostPlatform unit records.
- `sync-reservations` imports HostPlatform reservation records.
- Sync errors must be actionable. Avoid vague `Failed to fetch` messages when possible.
- If sync fails with 401 in test, first check deployed GitHub/Supabase key configuration and function JWT/auth behavior.
- Frontend manual sync calls may use the Supabase anon key for Edge Function authorization to avoid stale user-session JWT failures. UI role checks still control who can trigger sync.

## OCR / Invoice Input Rules
- Expense invoice automation must run through Supabase Edge Functions, not directly from the browser to AI providers.
- `analyze-receipt` extracts OCR/AI fields from the uploaded invoice or receipt.
- `process-invoice` applies business rules after AI extraction, including duplicate checks, unit matching, expense month, and final description format.
- OpenAI should be preferred when `OPENAI_API_KEY` is configured. Current selected OpenAI OCR model: `gpt-4o-mini`, because it supports text + image input and is low-cost enough for invoice extraction.
- If `OPENAI_API_KEY` is missing, the app must return a clear configuration error or use an explicitly configured fallback provider.
- Fixed utility/internet invoice descriptions must use:
  - Water Bill: `[WB] UNIT Mon YY`
  - Electricity Bill: `[EB] UNIT Mon YY`
  - Internet Bill: `[INT] UNIT Mon YY`
- For water/electricity/internet bills, if the bill date is in March and no explicit service period is found, the expense/bill period belongs to February. Example: March 2026 bill date -> `Feb 26` in the description and `2026-02` as expense month.
- Do not let AI usage quantities such as kWh, m3, litres, or meter readings become the claim amount. The amount must be the payable/paid RM value.
