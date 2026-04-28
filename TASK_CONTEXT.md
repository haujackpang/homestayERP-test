# Task Context

## Current Task
Current focus:
1. Fix manager/admin claim visibility so pending `Submitted` claimable expenses appear in the `Claims` page.
2. Keep claim-review queues claimable-only by excluding `Company-Paid` from `My Claims` and `All Claims`, while preserving company-paid totals in dashboard/report views.
3. Add 5-row pagination with `Back` and `Next` to both employee and manager/admin claim lists.
4. Split original claim receipts from payout bank slips so attachments do not disappear and `Mark as claimed` does not overwrite claim receipts.
5. Move normal claim attachments to signed upload/read helpers because the `receipts` bucket is private.
6. Keep the rollout test-first; use the focused script `supabase-claims-manager-access.sql` only in environments where manager claim access still follows admin-only policies.

2026-04-27 update (implemented in test first):
1. Claims cleanup: normal Claims pages now hide paid-out (`Claimed`, `Company-Paid`) and keep them out of the active queue.
2. History: employee can review own payout history (`Claimed`); manager can review all payout history (`Claimed`).
3. Unit expenses: manager can review all non-draft expenses per unit via Reporting -> Unit Expenses (includes `Claimed` and `Company-Paid`).
4. Delete: confirmed delete for unpaid claims (employee: own only, manager/admin: any unpaid) with focused test DB policies in `supabase-claim-delete-policies.sql`.
5. AI scan off: disabled in UI and blocked at Edge Functions unless `AI_RECEIPT_SCAN_ENABLED=true` is set later in Supabase secrets.
6. Submit speed: successful submit inserts into local state immediately, then refreshes claims in the background.

2026-04-28 update (implemented in test and live):
1. Expense submit diagnostics now preserve Supabase insert errors and write submit/upload failures into `error_logs`.
2. Admin `System Logs` now loads `error_logs` in 50-row pages with Back/Next controls.
3. `supabase-add-claim-attachment-refs.sql`, `supabase-invoice-automation.sql`, and `supabase-error-logs.sql` were applied to both test and live.
4. Test Pages deployment `25061045338` and live Pages deployment `25061116883` completed successfully.
5. Public API verification confirmed both environments expose the current claim attachment/OCR columns and accept client-side error-log inserts.

Environment guardrails that still apply:
1. Test is `homestayERP-test` / `afcifzghlkxvnpulahub`, live is `homestay-expenses` / `skwogboredsczcyhlqgn`, and `homestayERP-prod` is obsolete.
2. The `TESTING` watermark should be controlled by the test Pages path only, not by Supabase URL alone.
3. Pushing to live means code/workflow/functions/required idempotent DB structure only; do not copy or sync table data between environments.

Recent unit-pairing context:
1. `Units` now acts as a landing page with separate entry points for `Internal Units`, `HostPlatform Pairing`, and `Unit Configuration`.
2. HostPlatform pairing remains `HostPlatform property + unit -> internal unit`, with clearer wording, search, and `All / Unmapped / Paired` filtering.
3. `property_short` is now presented in the UI as `Display code (optional)` and should be treated as a display/report helper, not the pairing key.

## Current Working Assumptions
- Test `profiles.role` already accepts `manager`.
- Direct CLI inspection of further test DB policies is currently blocked because temp-role login is circuit-breaking and `SUPABASE_DB_PASSWORD` is not available in this shell.
- Follow-up verification on 2026-04-26 used the Supabase Management API instead of `supabase db query --linked`:
  - test `claims_select_admin` and `claims_update_admin` already allow `get_my_role() in ('admin','manager')`
  - test `bank_info_insert` and `bank_info_update` already allow `get_my_role() in ('admin','manager')`
  - test still contains at least one pending claimable row: `HE-2026-04-00012` for `Azizul`, status `Submitted`, `pay_type='employee'`
- `supabase-claims-manager-access.sql` is the focused remediation path if test or live still uses admin-only claim visibility policies.
- `supabase-add-claim-attachment-refs.sql` is the focused schema/backfill script for splitting claim receipts from payout bank slips.
- Current attachment model:
  - `claims.receipt_refs` stores original claim receipts
  - `claims.payment_slip_refs` stores payout bank slips
  - `claims.slip_ref` is legacy fallback only
- Because the `receipts` bucket is private, normal claim attachments must use `process-invoice` signed upload/read helpers instead of direct browser storage writes.
- On 2026-04-26, test `afcifzghlkxvnpulahub` also needed the existing idempotent script `supabase-invoice-automation.sql` before manual claim submit worked again:
  - `claims` was still missing `invoice_number`, `merchant_name`, `ai_raw`, `ai_confidence`, `source_type`, `external_id`, and `external_source`
  - the frontend was already inserting those fields, so PostgREST rejected `dbInsertClaim()` until that script was applied
- User has already executed the test Supabase script that adds unit-level cleaning/laundry columns.
- Test and live Supabase functions are deployed and direct function calls succeeded after secrets were copied/configured.
- `admin-users` now supports user listing fallback and password reset updates for system admin accounts.
- The same `admin-users` fix was deployed to both test project `afcifzghlkxvnpulahub` and live project `skwogboredsczcyhlqgn`.
- Live repo and live Supabase remain separate from test; app code must not contain runtime fallback behavior that reconnects live pages to test data.
- Previous `homestayERP-prod` repo should be treated as obsolete and not used for deployment.
- Runtime config validation must not compare against placeholder literals that the deploy workflow replaces globally.
- Audit completed on 2026-04-24:
  - `profiles` are mirrored across test and live: 4 matching rows.
  - `claims` are mirrored across test and live for common fields: 31 matching rows.
  - Live `claims` schema is older than test and lacks newer OCR/import metadata columns.
- Follow-up audit on 2026-04-24:
  - `reservations` are not a perfect mirror: counts differ by 2, and shared rows diverge mainly on `hp_unit_id`, `extra_guest`, `rental`, and `total_charges`.
  - `units` are not a perfect mirror: counts differ by 14 and one shared unit row differs in `property_short`.
  - `unit_config`, `unit_types`, `sync_logs`, and `error_logs` also differ between the two projects.
- Test database now has `units.mapped_unit_name`.
- Test database repair on 2026-04-25 confirmed:
  - internal/manual rows no longer carry HP identity fields
  - `units_hp_unit_id_idx` now protects non-null `hp_unit_id`
  - matched legacy HP duplicates were deactivated
  - two unmatched legacy HP rows (`KT 150A`, `SG 34F`) remain active until HP returns canonical replacements
- Live reservation import now runs every 5 minutes in `haujackpang/homestay-expenses`, while test runs daily at 12:00 AM in `haujackpang/homestayERP-test`.
- OpenAI API usage requires an API key in Supabase secrets. Codex itself is not an app-callable OCR backend.
- Test Supabase now has `OPENROUTER_API_KEY`, and the current test experiment should prefer OpenRouter receipt OCR rather than OpenAI.
- Test OCR should use `OPENROUTER_OCR_PRIMARY_MODEL` first, with optional `OPENROUTER_OCR_FALLBACK_MODELS` as a vision-only fallback chain.
- Default test OCR primary model is `qwen/qwen2.5-vl-32b-instruct:free` unless the secret is changed later.
- Non-utility OCR descriptions should include invoice/reference details and key item names; `[WB]`, `[EB]`, and `[INT]` bill descriptions stay standardized.
- Duplicate hits from `find_possible_duplicate_claims` should hard-block final submit in test, but still allow draft save.
- Direct call to test `sync-units` returned HTTP 200 and synced 16 units, so the screenshot 401 is likely caused by stale browser auth token, not missing function deployment.
- Direct call to test `sync-reservations` returned HTTP 200 and upserted records, so browser 401 is likely caused by stale/rejected user-session JWT before the function runs.
- Manage Users 401/Unauthorized issues were traced to the admin-users backend permission check and function secret/env mismatch, then fixed by updating the function and redeploying.
- End-to-end verification on 2026-04-26 after applying `supabase-add-claim-attachment-refs.sql`, `supabase-invoice-automation.sql`, redeploying `process-invoice`, and pushing the frontend to `homestayERP-test` confirmed:
  - employee claim submit with attachment now persists `receipt_refs`
  - manager `Mark as Claimed` now persists `payment_slip_refs` without overwriting `receipt_refs`
  - manager `All Claims` pagination `Next` moves from page 1 to page 2 on the deployed test Pages app
- Report sales are assigned by checkout date (`end_date`), so a month includes reservations checking out in that month.
- Report PDF cleaning fee uses `(cleaning_fee + laundry_fee) x checkout-month reservation count`, displayed as `Cleaning fee` in the shared expenses/expense details area.
- Report page should include calculated `Cleaning fee` in the visible Expenses detail list, but not repeat it in the booking summary.
- Homestay profit = sales - Subtotal Expenses, where Subtotal Expenses = expenses charged to Both + calculated Cleaning fee.
- Homestay Management Fee = homestay profit x `service_fee_pct` / 100.
- Owner Expenses = expenses charged to Owner, excluding Cleaning fee and Homestay Management Fee.
- Owner Profit = homestay profit - Homestay Management Fee - Owner Expenses.
- Report page Expenses section includes shared claims and calculated Cleaning fee.
- The admin user-management flow now uses `profiles` fallback when auth user listing is incomplete, so the UI can still show users and allow password resets.
- Internal units and HostPlatform rows should not share the same primary edit workflow in the admin UI.
- Editing a `source='hostplatform'` row should open a pairing-focused form, while editing a non-HP row should open the internal-unit form.
- The pairing screen should be the primary place where admins pair HostPlatform rows to internal units.
- `Display code (optional)` is editable only for internal units and read-only when shown in HostPlatform pairing.

## Do Not Do
- Do not move future changes to live unless explicitly requested again after this promotion is finished.
- Do not copy, mirror, or sync business data between test and live as part of a code or DB-structure push.
- Do not reintroduce `homestayERP-prod` as a live repo target.
- Do not trigger the testing watermark from Supabase URL alone.
- Do not remove unit configuration fields.
- Do not reintroduce unit-type-based rate logic.
- Do not expose secret values in final messages.
- Do not route the current test OCR experiment back to OpenAI-first behavior unless explicitly requested.
- Do not allow duplicate active HP mappings to the same internal unit.
- Do not treat inactive legacy HP rows as valid pairing rows in the UI.

## Memory Update Requirement
- When business rules, release targets, deployment state, or current priorities change, update the relevant memory files before ending the turn.
