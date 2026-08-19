# Project Overview

## System Name
Homestay Expense System / Homestay ERP Test

## System Goal
This system helps a homestay operator record expenses, review claims, reimburse staff, sync HostPlatform reservations/units, and generate owner-facing monthly expense reports.

## Users
- System Admin: manages users, units, mappings, settings, logs, and system sync.
- Manager: submits/approves operational expenses and uses AI receipt scanning.
- Employee/Staff: submits expense claims and tracks claim status.
- Owner: not a direct system user yet, but receives reports and pays/receives profit sharing based on configured rules.

## Current Modules
- Authentication and role-based views.
- Staff/user management.
- Expense submission and approval.
- Payout tracking.
- Unit management.
- HostPlatform unit/reservation sync.
- Unit mapping.
- Unit configuration: owner, cleaning fee, laundry fee, profit sharing percentage.
- OCR/AI receipt extraction.
- Error/admin/sync logs.
- Monthly expense reporting and PDF export.
- Reservation-level completed extra cleaning service recording, shown in reports as `Other -> Extra cleaning`.

## Current Stage
Testing environment remains the default working target in `homestayERP-test`.

Canonical live environment is `homestay-expenses`.

Current in-progress/local implementation on 2026-04-26:
- Claims list screens are being refined so `Company-Paid` does not appear in claim-review queues, while dashboard/report totals still include company-paid spending.
- Employee and manager/admin claim lists now target 5-row pagination with `Back` and `Next`.
- A focused remediation script `supabase-claims-manager-access.sql` is prepared for environments where manager claim visibility is still blocked by older policies.

Recent completed work:
- Reservation import now has repo-specific GitHub Actions schedules:
  - Live `Scheduled Reservation Import` runs every 5 minutes in `haujackpang/homestay-expenses` and calls the live `sync-reservations` Edge Function.
  - Test `Scheduled Reservation Import (Test)` runs daily at 12:00 AM in `haujackpang/homestayERP-test` and calls the test `sync-reservations` Edge Function.
- HostPlatform unit pairing data was repaired in test:
  - `units.hp_unit_id` is now treated as nullable for internal units and protected by a unique non-null index for synced HP rows.
  - Legacy `auto_synced` rows are normalized into the canonical `source='hostplatform'` model.
  - Legacy HP duplicates that already have a canonical `property_name + unit` replacement are deactivated instead of continuing to clutter pairing.
  - The pairing screen now shows active HostPlatform rows only, while the Units summary still reports how many inactive HP rows are hidden.
  - `sync-units` and `sync-reservations` now fail closed when required env/config is missing instead of returning a misleading success.
- Environment separation was tightened:
  - Test remains `homestayERP-test` with Supabase `afcifzghlkxvnpulahub`.
  - Live remains `homestay-expenses` with Supabase `skwogboredsczcyhlqgn`.
  - `homestayERP-prod` is obsolete and must not be used as the live repo.
  - The `TESTING` watermark is tied to the test Pages path, not Supabase URL alone.
  - Live promotion must not copy or sync database table data between test and live.
  - Claim attachments now split original receipts from payout slips, while `slip_ref` remains legacy fallback only during migration.
  - Normal claim attachments and payout slips should use signed upload/read helpers against the private `receipts` bucket.
- Unit pairing UX was clarified in the admin frontend:
  - `Units` now separates `Internal Units` from `HostPlatform Pairing`.
  - HostPlatform pairing uses pairing-first wording, search, and `All / Unmapped / Paired` filters.
  - `Property short code` is presented as `Display code (optional)` for internal units and read-only in pairing flows.
  - Editing a HostPlatform row now routes to a pairing-focused form instead of the generic internal-unit form.
- Admin user management was fixed and promoted to both environments:
  - `admin-users` now lists users with a `profiles` fallback when auth listing is incomplete.
  - System admin password reset works again for test and live.
  - The updated Edge Function was deployed to `afcifzghlkxvnpulahub` and `skwogboredsczcyhlqgn`.
- Test Supabase Edge Functions `sync-units` and `sync-reservations` were deployed.
- HostPlatform sync credentials were copied from live to test Supabase.
- Test sync was verified successfully:
  - Units: 16 synced.
  - Reservations: 4376 fetched, 4373 upserted.
- Unit-level cleaning/laundry/profit sharing configuration was added.
- Property-level mapping is being replaced by HostPlatform property + unit mapping.
- OCR/AI invoice extraction now runs through Supabase Edge Functions:
  - `process-invoice` handles auth, duplicate checks, unit matching, expense month, and final description formatting.
  - `analyze-receipt` currently uses OpenRouter, requires `OPENROUTER_API_KEY`, reads its primary model from `OPENROUTER_OCR_PRIMARY_MODEL`, and can use `OPENROUTER_OCR_FALLBACK_MODELS` as a fallback chain.
  - OCR availability is gated by `AI_RECEIPT_SCAN_ENABLED`.
  - Non-utility OCR descriptions are normalized server-side to include invoice/reference details and key item names, while `Water Bill`, `Electricity Bill`, and `Internet Bill` remain standardized as `[WB]/[EB]/[INT] UNIT Mon YY`.
  - Test duplicate handling now blocks final submit when `find_possible_duplicate_claims` returns a match, while still allowing draft save.
- Repo/environment mapping was re-confirmed on 2026-04-26:
  - Test repo `homestayERP-test` -> Supabase `afcifzghlkxvnpulahub`
  - Live repo `homestay-expenses` -> Supabase `skwogboredsczcyhlqgn`
- Follow-up CLI audit on 2026-04-24 found:
  - `profiles` and `claims` are mirrored on the audited business fields.
  - `reservations`, `units`, `unit_config`, `unit_types`, and log tables are not fully mirrored.
  - Cleanup should not delete rows until a row-by-row source-of-truth decision is made.

## Project Memory Files
These files are part of the working system and must be kept updated when relevant changes happen:
- `PROJECT_OVERVIEW.md`
- `BUSINESS_RULES.md`
- `DECISIONS_LOG.md`
- `TASK_CONTEXT.md`
- `AI_INSTRUCTIONS.md`
- `RELEASE_PROCESS.md`
