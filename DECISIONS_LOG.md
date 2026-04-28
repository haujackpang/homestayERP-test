# Decisions Log

## 2026-04-28: Show Existing Claim For Exact Duplicate Expense
Decision: Keep the DB duplicate guard for exact active duplicates, but add a frontend pre-check that finds the matching loaded claim and shows the existing claim ID before upload/insert.

Reason:
The live AR C3706 retry was an actual duplicate of `MGR-2026-04-00024`, so allowing another insert would create duplicate accounting data. The user-facing fix is to explain the existing claim clearly instead of exposing the raw `claims_dup_check` database error.

## 2026-04-28: Use Functions Domain For Live Scheduled Reservation Import
Decision: Call the live `sync-reservations` Edge Function through `https://skwogboredsczcyhlqgn.functions.supabase.co/sync-reservations` in the GitHub scheduled workflow, after normalizing the Supabase origin with shell parameter expansion.

Reason:
The workflow first failed because the `sed` backreference was escaped as literal `\1`, producing a bad hostname. After that was fixed, GitHub Actions still received 404 from the `/functions/v1` gateway even though direct live calls worked. The functions-domain URL succeeded in manual workflow runs and keeps the schedule independent from path suffixes in `SUPABASE_URL`.

## 2026-04-28: Promote Expense Submit Diagnostics To Test And Live
Decision: Keep test and live at the same schema/app level for claim submission by applying the attachment refs, invoice automation, and error-log migrations to both environments, then deploying paged admin logs and detailed submit-failure logging to both Pages apps.

Reason:
The same AR C3706 scenario worked in test but failed in live, pointing to environment drift rather than form logic. The frontend now records the real Supabase insert/upload error in `error_logs`, and admins can page through logs instead of being limited to the latest 100 rows.

## 2026-04-28: Report Sales And Profit Formula
Decision: Assign report sales by reservation checkout date (`end_date`) and calculate Homestay Profit as `Sales - Subtotal Expenses`, where Subtotal Expenses includes shared expenses charged to Both plus calculated Cleaning fee.

Reason:
The business wants March sales to include reservations that check out in March. Cleaning fee already appears in Expenses, so it should be included in Subtotal Expenses and omitted from the booking summary to keep Homestay Management Fee and Owner Profit consistent.

## 2026-04-26: Reconfirm Test And Live Supabase Mapping
Decision: Treat `afcifzghlkxvnpulahub` as the test Supabase project for `homestayERP-test`, and `skwogboredsczcyhlqgn` as the live Supabase project for `homestay-expenses`.

Reason:
The user explicitly re-confirmed this mapping during the claims attachment and pagination work. Repo docs, release notes, and deployment checks must follow the same ownership so Pages secrets and smoke tests do not drift again.

## 2026-04-26: Split Claim Receipts From Payout Slips
Decision: Store original claim receipts in `claims.receipt_refs` and payout bank slips in `claims.payment_slip_refs`, while keeping `slip_ref` as legacy fallback only during migration.

Reason:
Using one field for both flows caused `Mark as claimed` to overwrite receipt attachments and made claim detail screens ambiguous. Separate fields preserve both document sets and match the actual business workflow.

## 2026-04-26: Keep Claim Attachments On Signed Private-Bucket Flow
Decision: Reuse `process-invoice` signed upload/read helpers for normal claim receipts and payout slips instead of direct browser uploads.

Reason:
The `receipts` bucket is private, and direct browser uploads were failing while the claim mutation still continued. Signed uploads keep the bucket private and let the UI fail closed when a selected attachment cannot be stored.

## 2026-04-26: Bring Test `claims` Schema Up To Current Frontend Expectation
Decision: Apply the existing idempotent script `supabase-invoice-automation.sql` to test `afcifzghlkxvnpulahub` before validating the attachment fix.

Reason:
During end-to-end verification, manual claim submit still failed at `dbInsertClaim()` because the test `claims` table was missing OCR/import metadata columns such as `ai_confidence`, even though the current frontend already sends them. Running the existing migration was required to make attachment verification meaningful.

## 2026-04-26: Keep `Company-Paid` Out Of Claim Queues
Decision: Hide `Company-Paid` rows from the employee and manager/admin `Claims` lists while keeping company-paid totals in dashboard and report summaries.

Reason:
`Company-Paid` records are tracking-only and do not belong in the claim approval/rejection queue. Mixing them into the claim lists makes pending claimable expenses harder to review and led to confusion about which records should appear there.

## 2026-04-26: Paginate Claim Lists At 5 Rows
Decision: Paginate both `My Claims` and `All Claims` at 5 rows per page with `Back` and `Next` controls, resetting to page 1 when filters change.

Reason:
Long claim lists are hard to scan on the single-file mobile-style UI. A small fixed page size keeps the queue readable without changing the existing filter model.

## 2026-04-26: Prepare Focused Manager Claims Policy SQL
Decision: Add a narrow SQL remediation script for environments where manager claim visibility still depends on admin-only `claims` or `bank_info` policies.

Reason:
The repo already contains broad legacy SQL scripts, but this issue only needs manager role support and claim-queue visibility. A focused idempotent script is safer to run in test first and easier to promote to live if policy drift is confirmed.
## 2026-04-25: Schedule Reservation Imports Per Environment
Decision: Add repo-specific GitHub Actions cron workflows so live calls `sync-reservations` every 5 minutes and test calls it daily at 12:00 AM.

Reason:
The live app already had a manual reservation sync button, but no automatic import cadence. Separate repo-level schedules keep live and test behavior aligned with their own environments without mixing cadence or secrets.
## 2026-04-25: Canonicalize HostPlatform Unit Rows Before Pairing
Decision: Repair `units` so active HostPlatform rows use the canonical `source='hostplatform'` plus real `hp_unit_id`, while internal/manual rows carry no HP identity fields and matched legacy HP duplicates are deactivated.

Reason:
The pairing UI depends on canonical HostPlatform rows. Legacy `auto_synced` rows, fake/random `hp_unit_id` values on internal rows, and a global unique-name constraint caused sync drift and blank pairing results even after a successful HP sync.

## 2026-04-25: Separate Internal Units From HostPlatform Pairing
Decision: Split the admin unit UX into distinct `Internal Units` and `HostPlatform Pairing` flows, while keeping the existing storage fields and pairing logic unchanged.

Reason:
Users were reading `Property short code` as if it were the pairing key. The real rule is `HostPlatform property + unit -> internal unit`, so the UI should present that pairing decision directly instead of mixing it with internal-unit maintenance.

## 2026-04-25: Demote `property_short` To Display Helper In The UI
Decision: Present `property_short` as `Display code (optional)` for internal units and show it as read-only in HostPlatform pairing/edit flows.

Reason:
`property_short` still matters for display/report compatibility, but it should not compete with the actual pairing choice or imply that short code creates the HostPlatform mapping.

## 2026-04-23: Fixed Short Code Dropdown
Decision: Property short code should use a predefined dropdown list instead of free text.

Reason:
Free typing caused human error, inconsistent codes, and downstream reporting problems.

## 2026-04-23: Property-Level Mapping Was Not Enough
Decision: Replace property-only mapping with HostPlatform property + unit mapping.

Reason:
One HostPlatform property can contain several units. Mapping at property level can assign the wrong unit or make several units indistinguishable.

## 2026-04-23: Unit-Level Rates
Decision: Cleaning and laundry rates belong to unit configuration, not unit type.

Reason:
The same property and unit type may still have different cleaning/laundry rates.

## 2026-04-23: Rename Service Fee Wording
Decision: Display `service_fee_pct` as `Profit Sharing %`.

Reason:
The business meaning is the percentage shared/charged against owner profit, not a generic service fee.

## 2026-04-23: Logs Must Include Operations
Decision: Logs page should include sync logs and admin action logs, not only frontend/backend errors.

Reason:
Testing and troubleshooting need visibility into sync success/failure and admin configuration changes.

## 2026-04-23: Test Sync Credentials
Decision: Copy HostPlatform reservation credentials from live Supabase to test Supabase.

Reason:
Test sync functions were deployed but failed login until test received the same HostPlatform credentials.

## 2026-04-23: Project Memory Files
Decision: Maintain project memory files in the repo so AI assistants must read stable business context before changing code.

Reason:
Important business rules were discussed over multiple turns and can be lost across sessions or model changes.

## 2026-04-23: Remove Separate Cleaning/Laundry Page
Decision: Remove the visible standalone `Cleaning & Laundry Rates` entry and route old access to `Unit Configuration`.

Reason:
Cleaning/laundry rates are unit-level configuration. Keeping a separate rates page duplicates the workflow and makes users think rates are managed somewhere else.

## 2026-04-23: Add `mapped_unit_name`
Decision: Store HostPlatform unit mapping in `units.mapped_unit_name`.

Reason:
HostPlatform unit names remain synced source data, while internal unit names remain controlled by this system. The mapping is explicit: HostPlatform property + HostPlatform unit -> internal unit.

## 2026-04-23: Repair Test Frontend 401
Decision: Refresh `homestayERP-test` GitHub Actions secrets for Supabase URL/key/service key.

Reason:
Direct test Edge Function calls succeeded, but the deployed frontend showed HTTP 401. That points to the deployed page using an invalid or stale Supabase key.

## 2026-04-23: Persistent Release Memory
Decision: Add a dedicated release-process file and require future updates to memory files whenever project logic or release status changes.

Reason:
Important deployment and environment decisions should not depend on session memory. They must live in the repo so future work stays aligned.

## 2026-04-23: OpenAI OCR Pipeline
Decision: Keep invoice OCR behind Supabase Edge Functions and prefer OpenAI `gpt-4o-mini` when `OPENAI_API_KEY` is configured.

Reason:
The browser must not hold AI provider secrets. `gpt-4o-mini` supports image input and structured text output at low cost, which fits invoice/receipt extraction better than a large reasoning model. Business formatting still belongs in `process-invoice` so the final description is consistent.

## 2026-04-23: Fixed Utility Description Format
Decision: Utility/internet OCR descriptions must be normalized server-side to `[WB] UNIT Mon YY`, `[EB] UNIT Mon YY`, or `[INT] UNIT Mon YY`.

Reason:
AI extraction can vary. The accounting/reporting description must be stable, and utility bills received in the following month normally belong to the previous month unless the invoice explicitly states a different service period.

## 2026-04-25: Test OCR Uses OpenRouter Qwen-First
Decision: The current test receipt-scanning experiment should prefer OpenRouter with a configurable Qwen-VL primary model, plus a vision-only OpenRouter fallback list.

Reason:
The user wants to validate receipt scanning specifically against the previously chosen OpenRouter vision path in test. Keeping model choice in Supabase secrets makes it easier to switch Qwen variants or fallback models without changing browser code.

## 2026-04-25: Duplicate Receipt Hits Block Final Submit In Test
Decision: In the current test OCR flow, duplicate matches returned by `find_possible_duplicate_claims` must block final submit, but draft save remains allowed.

Reason:
The database-side duplicate function is the canonical source of truth. Blocking final submit reduces accidental double-claiming while still letting staff keep work-in-progress receipts as drafts.

## 2026-04-23: Reservation Details In Manager Report
Decision: Add reservation detail cards to the report page for the selected unit/month.

Reason:
Managers need to verify booking income context directly in the report, not only see booking count and revenue summary.

## 2026-04-23: One Active HP Mapping Per Internal Unit
Decision: Hide already-paired internal units from other HostPlatform mapping dropdowns and allow unmapping to release them.

Reason:
Duplicate mappings can cause reservations and expenses to attach to the wrong internal unit. The UI should prevent accidental double pairing.

## 2026-04-23: Refresh Function Token On 401
Decision: Refresh the Supabase session token before Edge Function calls when it is near expiry, and retry once on HTTP 401.

Reason:
The test Edge Function works from direct calls, but the browser can keep an expired session token and receive 401 before the function runs.

## 2026-04-23: Owner Statement PDF Layout
Decision: Update report PDF export into an owner-statement layout with property + unit title, booking details, cleaning fee, expense details, homestay management fee, owner expenses, and owner net amount.

Reason:
The owner PDF needs to show how the final owner amount is derived, not only summarize expense categories.

## 2026-04-23: Owner Profit Reporting Formula
Decision: Report owner profit from sales after Subtotal Expenses, management fee, and owner-charged expenses.

Reason:
The business wants reports to emphasize Homestay Management Fee and Owner Profit. Homestay profit is sales minus Subtotal Expenses, including shared expenses charged to Both plus calculated Cleaning fee; management fee is calculated from that homestay profit, while owner expenses exclude the management fee.

## 2026-04-23: Cleaning Fee Display In PDF
Decision: Show PDF `Cleaning fee` in the shared expenses/expense details area and exclude it from Owner Expenses.

Reason:
The PDF should present Cleaning fee as part of shared operating expenses, while Owner Expenses should only list expenses directly charged to Owner.

## 2026-04-23: Report Page Expenses Section
Decision: On the report page, rename `Shared Expenses (Both)` to `Expenses`, show `Total Cleaning Fee` in that section, and keep Owner Expenses limited to owner-charged claims.

Reason:
The report page should match the owner-report structure: cleaning fee is not an owner-expense line, while Owner Expenses are only claims charged to Owner.

## 2026-04-23: Manual Sync Uses Anon Function Token
Decision: Browser-triggered manual sync calls should authorize Edge Functions with the Supabase anon key instead of the current user session token.

Reason:
Direct test calls succeed, but a manager browser can send a stale or function-rejected session JWT and receive HTTP 401 before the function runs. The UI still limits sync access by role.

## 2026-04-23: Promote Tested Changes To Live
Decision: After explicit user approval, create/use `homestayERP-prod`, enable GitHub Pages workflow deployment, push tested `main`, configure prod repo Supabase secrets, deploy live Edge Functions, and apply required idempotent SQL upgrades to live Supabase.

Reason:
Live must run the same tested frontend, sync endpoints, OCR backend, unit mapping schema, and report-supporting schema as the test environment. A repo-only push is not enough when the feature depends on Supabase Functions and database columns.

## 2026-04-24: Fail Closed On Missing Deployment Config
Decision: Do not allow the deployed page to silently fall back to the test Supabase project when GitHub Pages secrets are missing or placeholders are not replaced.

Reason:
Test and live data must stay isolated. Missing deployment config should show a clear error, not connect to the wrong database or show a test watermark/data mix in live.

## 2026-04-24: Cleaning Fee In Expenses Details
Decision: On the report page and owner PDF, include the calculated cleaning fee inside the Expenses details list/table.

Reason:
The user wants Cleaning fee treated as part of the Expenses detail presentation, with clearer wording and without implying test-only totals or a separate hidden bucket. The booking summary should not repeat the Cleaning fee row because the category already appears below.

## 2026-04-24: Promote Environment Separation And Report Label Fixes To Live
Decision: After test verification, promote the environment-isolation fix and report wording/detail fixes to `homestayERP-prod`.

Reason:
These changes correct live-visible behavior: live must stay on the live database without a hidden fallback to test, and the report page wording/details must match the approved business presentation.

## 2026-04-24: Correct Canonical Repo And Supabase Mapping
Decision: Use `haujackpang/homestay-expenses` as the canonical live repo, `haujackpang/homestayERP-test` as the test repo, `afcifzghlkxvnpulahub` as the test Supabase project, and `skwogboredsczcyhlqgn` as the live Supabase project.

Reason:
The earlier repo/project mapping was wrong. Future deployments, Pages secrets, and verification must follow the user's corrected environment ownership so test and live stay properly separated.

## 2026-04-24: Keep `homestayERP-prod` As Legacy Live Alias
Decision: Maintain `haujackpang/homestayERP-prod` as a compatibility URL for existing bookmarks, and point it to the live Supabase environment.

Reason:
The user still opens the old `homestayERP-prod` GitHub Pages URL. Keeping it functional avoids access disruption while `haujackpang/homestay-expenses` remains the canonical live repo.

Status:
Superseded on 2026-04-25. Do not use `homestayERP-prod` as a live alias anymore.

## 2026-04-24: Placeholder Detection Must Not Use Replaceable Literals
Decision: Detect missing Supabase deployment config by validating URL/key shape, not by comparing against placeholder literals that GitHub Actions also replaces.

Reason:
The build step replaces `__SUPABASE_URL__` and `__SUPABASE_KEY__` everywhere in the file. A literal-placeholder comparison inside runtime code becomes a self-fulfilling true condition and incorrectly shows the missing-config error even when secrets were injected correctly.

## 2026-04-24: Cross-Environment Audit Result
Decision: Record the audit finding that test and live currently contain mirrored `profiles` and mirrored `claims` rows for the common audited fields.

Reason:
Future cleanup work should start from the confirmed state, not assumptions. The current issue is not a simple one-sided contamination; both environments now hold the same user and claim rows, while live still runs an older `claims` schema.

## 2026-04-24: Reservations And Units Are Not Fully Mirrored
Decision: Treat `reservations`, `units`, and the environment settings/log tables as divergent until a source-of-truth decision is made.

Reason:
CLI-backed comparison showed `reservations` differ in count by 2 with shared rows diverging mainly on `hp_unit_id`, `extra_guest`, `rental`, and `total_charges`. `units` differ in count by 14, with one shared row differing in `property_short`, and the settings/log tables (`unit_config`, `unit_types`, `sync_logs`, `error_logs`) also differ. A blind delete or rewrite would risk removing valid operational data.

## 2026-04-24: Admin Password Reset Support
Decision: Add an explicit admin password reset action in the user management flow, backed by the existing Supabase service-role update path.

Reason:
Support staff need a direct way to help users who forget their passwords without manual database edits or exposing secrets. The admin list now offers a reset-password action, and the backend updates the auth user password through the service role.

## 2026-04-24: Admin User List Fallback
Decision: When `auth.admin.listUsers()` is incomplete or unavailable, fall back to `profiles` rows so system admin can still see users and reach password reset actions.

Reason:
The Manage Users screen was showing `0 login user(s)` even though valid users existed. In practice the browser session, auth listing, or function env could fail before the admin reset flow became usable. Using `profiles` as a fallback keeps user management available while still preserving auth-based data when it is present.

## 2026-04-24: Admin Users Redeployed To Test And Live
Decision: Promote the updated `admin-users` Edge Function to both test and live after the user verified the test flow.

Reason:
The fix was validated in test, then deployed to the canonical live repo and live Supabase project so both environments share the same user-management behavior.

## 2026-04-25: `homestayERP-prod` Is Obsolete
Decision: Stop treating `haujackpang/homestayERP-prod` as a live alias. The active environments are now test repo `haujackpang/homestayERP-test` with Supabase `afcifzghlkxvnpulahub`, and live repo `haujackpang/homestay-expenses` with Supabase `skwogboredsczcyhlqgn`.

## 2026-04-26: Reconfirm Test And Live Supabase Mapping
Decision: Treat `afcifzghlkxvnpulahub` as the test Supabase project for `homestayERP-test`, and `skwogboredsczcyhlqgn` as the live Supabase project for `homestay-expenses`.

Reason:
The user explicitly re-confirmed this mapping during the claims attachment and pagination work. Repo docs, release notes, and deployment checks must follow the same ownership so Pages secrets and smoke tests do not drift again.

## 2026-04-25: Watermark Must Follow Repo Path
Decision: Show the `TESTING` watermark only when the app is served from the test Pages path, not when a Supabase project ref appears in runtime config.

Reason:
Supabase URL controls data access, but it should not decide whether live UI shows test-only branding. This prevents a live deployment from displaying a testing watermark because of a misconfigured secret.

## 2026-04-25: Live Promotion Does Not Move Data
Decision: A live promotion may include code, workflow config, Edge Functions, and required idempotent DB structure changes, but must not copy, mirror, or sync table data between test and live unless the user gives a separate explicit data-migration instruction.

Reason:
The user wants test and live deployment separated. Promoting tested code must not imply data synchronization between environments.

## 2026-04-26: Verify Claims Visibility Through Supabase Management API
Decision: When `supabase db query --linked` is blocked by temporary login-role authentication failures, use the Supabase Management API to verify policy state and pending claim data on the target project before changing rollout plans.

Reason:
On 2026-04-26, the linked test project still had the required manager-readable `claims` and `bank_info` policies, and it still contained a pending `Submitted` employee-paid claim. That means the visibility problem is not caused by missing pending data in test, and the local frontend queue changes remain the primary fix path.
