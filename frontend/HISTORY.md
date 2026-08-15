# Frontend History

## 2026-08-15 — Dashboard Global Multi-Currency Wallet

- **Replaced the misleading hero "Net Cash Flow" card** (which displayed a
  currency-mixed `SUM(converted_yer_amount) − SUM(converted_yer_amount)`)
  with a **"الرصيد النقدي الحالي / Current Cash Balance"** card showing the
  **global wallet balance across ALL projects**, with **SAR and YER displayed
  separately and never added together**.
- **Reused the existing `WalletBalanceService`** as the single financial truth.
  Added `WalletBalanceService.computeGlobalBalances()` which aggregates every
  active payment, expense, and currency transfer across all projects using the
  same per-currency formula (`payments − expenses + transfers in − transfers
  out`, per currency, never mixed). No second wallet engine was created.
- **Architecture:** DAO global queries → `WalletBalanceService` →
  `LocalDashboardRepository.getGlobalWalletBalances` →
  `dashboardGlobalWalletProvider` → Dashboard UI. Follows the existing
  DAO → Repository → Domain → Provider → UI layering.
- **UI:** The hero card now shows the wallet icon + "الرصيد النقدي الحالي" +
  "جميع المشاريع" subtitle, then two side-by-side tiles: "محفظة الريال
  اليمني / YER" and "محفظة الريال السعودي / SAR". Negative balances are
  shown clearly in a soft red (`0xFFFCA5A5`); positive in white. Zero state
  renders `0` for both currencies. Both currencies are always shown even when
  one is zero. Uses the existing gradient, radius, shadow, and typography.
- **Currency transfers** are now reflected on the Dashboard through the wallet
  engine (a transfer debits the source wallet and credits the target wallet).
  Transfers are never counted as income or expenses.
- **Legacy `converted_yer_amount` anomaly**: the Dashboard wallet no longer
  uses `converted_yer_amount` for the balance. Historical malformed rows do
  not affect the wallet (Test 9 confirms). The old `DashboardSummary` fields
  (`totalPaymentsYer`/`totalExpensesYer`/`netCashFlowYer`) remain for the
  analytical financial-overview cards below, which are clearly labelled as
  expenses/payments/net-cash-flow (flow metrics, not balance).
- **No schema changes.** No changes to payment, expense, transfer,
  exchange-rate, contract-value, or project-status logic. The three financial
  overview cards, KPI row, activity section, monthly chart, and quick actions
  are unchanged.
- **Tests:** Added `dashboard_global_wallet_test.dart` with 11 tests covering:
  zero-state, SAR-only, YER-only, mixed currencies (not added), expense,
  currency transfer, multi-project aggregation, negative wallet, legacy
  `converted_yer_amount` anomaly exclusion, soft-delete exclusion, and a
  currency-independence invariant. Updated existing dashboard widget tests for
  the new `dashboardGlobalWalletProvider` and hero card labels.
- **Verification:** `flutter analyze --no-pub` — 0 errors.
  `flutter test --no-pub` — 537 tests pass (includes 320x640 narrow viewport
  overflow checks for the Dashboard in Arabic and English).

## 2026-08-15 — Financial Card Title Colors Match Semantic Card Color

- **UI-only change:** The operation title in each Dashboard
  `_FinancialCard` now uses the same semantic `color` passed to the card
  instead of the fixed gray `0xFF64748B`. "المصروفات" renders red,
  "الدفعات المستلمة" renders green, and "صافي التدفق النقدي" renders
  teal (`Colors.teal`) to match the "الرصيد النقدي الحالي" wallet
  color used in the project detail and reports screens (red when
  negative).
- No financial calculations, card layout, icons, trend indicators,
  financial values, typography sizes, localization, spacing, or
  business logic were changed.
- **Verification:** `flutter analyze --no-pub` — 0 errors.
  `flutter test --no-pub` — 526 tests pass (includes 320x640 narrow
  viewport overflow checks for the Dashboard in Arabic and English).

## 2026-08-15 — Financial Summary Card Layout Reverted

- **Reverted** the previous financial-card header repositioning that
  incorrectly moved the operation icon + label group. Restored the
  previously-approved layout: a single header `Row` of
  `[icon] [label (Expanded)] [trend badge (Flexible)]`. Under the
  ambient RTL `Directionality` this places the operation icon + label
  on the **right** and the small trend/direction indicator on the
  **left**, with the financial value remaining the dominant element
  below — exactly the requested structure.
- No colors, typography, card dimensions, icons, financial values,
  business logic, or localization keys were changed.
- **Verification:** `flutter analyze --no-pub` — 0 errors.
  `flutter test --no-pub` — 526 tests pass (includes 320x640 narrow
  viewport overflow checks for the Dashboard in Arabic and English).

## 2026-08-15 — Financial Summary Card Trend Indicator Repositioned

- **UI-only change:** Moved the small trend/direction indicator chip in
  each Dashboard `_FinancialCard` to the start of the header row, with
  the operation icon + localized name grouped at the end (right in LTR,
  left in RTL via the ambient `Directionality`). The financial value
  remains the dominant element below the header.
- The trend badge, icon, color, and financial logic are unchanged — only
  the horizontal ordering within the header `Row` changed. A `Spacer`
  keeps the two groups apart, and both groups use `Flexible`/`mainAxisSize:
  min` so long Arabic labels (الدفعات المستلمة / صافي التدفق النقدي)
  do not overflow on narrow phones.
- No financial/business logic, schema, providers, repositories, or
  localization keys were touched.
- **Verification:** `flutter analyze --no-pub` — 0 errors.
  `flutter test --no-pub` — 526 tests pass (includes 320x640 narrow
  viewport overflow checks for the Dashboard in Arabic and English).

## 2026-08-15 — Financial Summary Card Header Refinement

- **UI-only change:** Restructured the `_FinancialCard` header on the
  Dashboard so the operation label sits beside its icon as a single
  visual header group (`[icon] [label] … [trend badge]`), instead of the
  icon sitting alone in a row with the trend badge and the label being
  merged with the currency at the bottom.
- The financial value remains the dominant element below the header, with
  the currency shown beneath it. The label uses `Expanded` + ellipsis and
  the trend badge uses `Flexible` so long Arabic labels
  (الدفعات المستلمة / صافي التدفق النقدي) render without RenderFlex
  overflow on narrow phones.
- RTL is handled by the existing `Directionality` (the `Row` follows the
  ambient text direction), so the icon/label group stays coherent in
  Arabic and English.
- No financial/business logic, calculations, schema, providers, or
  repositories were touched. Localization keys unchanged.
- **Verification:** `flutter analyze --no-pub` — 0 errors.
  `flutter test --no-pub` — 526 tests pass (includes 320x640 narrow
  viewport overflow checks for the Dashboard).

## 2026-08-15 — Dashboard UI Localization Cleanup

- **Localization leaks fixed:** The Dashboard rendered raw localization keys
  (`project_overview`, `monthly_performance`) and English-only quick-action
  labels (`payment`, `expense`) because the Arabic entries for
  `project_overview`, `monthly_performance`, `revenue`, `profit`, `expense`,
  and `payment` were missing from `AppLocalizations`, so `translate()`
  fell back to the raw key. Added the missing Arabic keys and aligned the
  English values to the spec (`Project Overview`, `Monthly Performance`).
- **Quick actions:** Switched the Payment/Expense quick-action buttons to
  the existing action-oriented `new_payment` / `new_expense` keys
  (en "New Payment" / "New Expense", ar "دفعة جديدة" / "مصروف جديد")
  and capitalized the English values. The `reports` quick action already
  localized correctly.
- **Chart month labels:** Replaced the hardcoded Arabic month-name array
  in `_MultiLineChartPainter` with localized `month_jan`…`month_dec` keys
  passed in from the widget, and the text direction is now derived from
  the current locale instead of being forced to RTL — so English mode
  shows English month abbreviations and Arabic mode shows Arabic names.
- **No business logic changed:** Financial calculations, project status
  counting, multi-currency, schema, and repository architecture are
  untouched. This phase is strictly Dashboard presentation/localization.
- **Tests:** Added two widget tests verifying the Arabic and English
  Dashboard render no raw keys/tokens (`project_overview`,
  `monthly_performance`, `revenue`, `expenses`, `profit`, `payment`,
  `expense`, `reports`, `status_*`, `STATUS_*`) and that the localized
  labels are present. Wired `localizationsDelegates` into the dashboard
  widget test harness so `context.tr` resolves under test.
- **Verification:** `flutter analyze --no-pub` — 0 errors.
  `flutter test --no-pub` — 526 tests pass.

## 2026-08-15 — Dashboard Status Counting & Status Localization Fix

- **Root cause:** The Dashboard "Pending/Paused" KPI card displayed
  `activeClientCount` (active clients) instead of a project status count,
  causing the same number to appear beside Active/Completed when the client
  and project counts coincided. The "Total Projects" card derived the total
  as `activeProjectCount + completedProjectCount`, omitting projects in other
  statuses (planning/on_hold/cancelled). The Projects screen also leaked the
  raw internal key `status_active` because the `status_active` localization
  entry was missing, so `AppLocalizations.translate` fell back to the key.
- **Status counts (data layer):** Extended `DashboardDao.getSummary`,
  `DashboardSummaryRow`, `DashboardSummary`, and `LocalDashboardRepository`
  to expose mutually-exclusive per-status project counts
  (`planning/active/completed/on_hold/cancelled`) plus a real
  `totalProjectCount`, each computed as
  `SELECT COUNT(*) FROM projects WHERE status = ?` directly from the
  persisted `status` column. No status is inferred from milestones,
  payments, expenses, dates, or progress.
- **Invariant:** `DashboardSummary.statusCountsSum == totalProjectCount`
  (`statusCountsConsistent`) — a defensive check that no project is counted
  in more than one bucket or omitted.
- **Dashboard UI:** The KPI row now shows `totalProjectCount` for "Projects",
  `completedProjectCount` for "Completed", `activeProjectCount` for
  "Active", and `onHoldProjectCount` (localized `status_on_hold`) for the
  paused card — never the client count. The activity card now renders the
  project's actual localized status instead of a hardcoded
  `status_completed` chip for every project.
- **Localization:** Added the missing `status_active` key (en "Active" /
  ar "نشط") and aligned `status_on_hold` to "معلّق". Replaced hardcoded
  status labels in `project_detail_screen.dart` and `reports_screen.dart`
  with `context.tr('status_$status')` so the UI never exposes raw tokens
  like `STATUS_ACTIVE` / `STATUS_COMPLETED`.
- **No schema change required.** The project `status` column already
  existed; only queries/DTOs/UI were corrected.
- **Tests:** Added `dashboard_status_counts_test.dart` covering scenarios
  1–8 (three-active, mixed-status, active→completed, completed→active,
  persistence after reopen, localization, zero-state, mixed-status invariant)
  plus an explicit invariant test. Strengthened `phase08_dashboard_test.dart`
  and `baseline_contracts_test.dart` for the new summary fields.
- **Verification:** `flutter analyze --no-pub` — 0 errors, no new warnings.
  `flutter test --no-pub` — 524 tests pass.

## 2026-08-13 — Multi-Currency Wallet Workflow (schema v6)

- **Independent currency wallets:** Added `WalletBalanceService` computing
  per-currency balances (SAR wallet, YER wallet) as
  `payments − expenses + transfers in − transfers out` per currency.
  Different currencies are never mixed or added together.
- **Currency transfers table (schema v6):** Added `currency_transfers` table
  storing `id`, `projectId`, `sourceCurrency`, `targetCurrency`,
  `sourceAmountMinor`, `targetAmountMinor`, `exchangeRateScaled`, `date`,
  with soft-delete. The exchange rate is an immutable snapshot preserved on
  every transfer; historical rates are never recalculated.
- **Insufficient balance handling:** The expense form now checks the
  matching-currency wallet before recording. If the wallet has insufficient
  balance, an Arabic warning dialog (تنبيه مالي) shows the current balance,
  expense value, and deficit, with three options: تحويل عملة / تمويل خارجي /
  إلغاء. Never auto-deducts from another currency.
- **Currency transfer UI:** Added a transfers tab and `CurrencyTransferDialog`
  with source/target currency selectors, amount, exchange rate, live result
  preview, and date.
- **Financial summary UI:** Replaced the mixed "Net cash flow: X YER" card
  with a per-currency wallet balances card (محفظة الريال السعودي /
  محفظة الريال اليمني) plus an optional analytical converted value
  (القيمة المحولة للتقارير) clearly marked as analytical only.
- **Reports:** The financial summary report now distinguishes actual wallet
  balances (SAR/YER) from analytical converted values, and never merges
  currencies without conversion information.
- **Localization:** Added Arabic keys for all new UI text.
- **Tests:** Added 23 tests covering SAR/YER payments, SAR/YER expenses,
  insufficient currency balance, currency transfer, exchange rate
  preservation, restart persistence, and financial summary correctness.
  Full suite: 514 passed. Analyzer: no errors (124 info/warnings).

## 2026-08-09 — Financial Validation, Contract Safety, and Amendment Architecture

- **Contract amendment architecture (schema v5):** Added
  `originalContractValueMinor` to the projects table (additive migration with
  backfill). `ProjectEntity` now exposes both `budgetAmountMinor` (current)
  and `originalContractValueMinor` (immutable original). `getFinancialSummary`
  reports `currentContractValue` and `originalContractValue` separately. A new
  `amendContract` repository method changes the current value while preserving
  the original.
- **Contract value locking:** The project form disables the contract value
  and currency fields once any payment, expense, or milestone exists, and
  shows a localized lock notice. The repository enforces the lock server-side
  by throwing `StateError` on direct budget updates when transactions exist.
- **Cross-currency payment confirmation:** The payment form now shows a
  financial alert dialog before recording a cross-currency payment, displaying
  the original currency, amount, exchange rate, and the exact converted value
  (integer arithmetic via `convertToCurrency`).
- **Expense over-cash warning:** The expense form warns (non-blocking) when
  adding an expense would make total expenses exceed received payments,
  showing the received payments, projected total expenses, and expected
  deficit. The user may continue because the contractor may finance the
  project independently.
- **Currency conversion fix:** Corrected `convertToCurrency` (YER→SAR) to use
  the exact inverse of the SAR→YER formula
  (`amount × sarFactor × rateFactor ÷ rate`), with round-half-up.
- Validation: `flutter analyze --no-pub` reports no errors. Full suite
  `flutter test --no-pub` — 491 tests passed (15 new). Schema v5 migration is
  idempotent and backfills existing rows.

## 2026-08-08 — Phase 2: Inline Client Creation from Project Form (UX)

- Aligned the inline "add client" dialog to the client-terminology labels
  (`إضافة عميل جديد`, `اسم العميل *`, `حفظ العميل`, `إلغاء`, validation
  `اسم العميل مطلوب`) and added matching English keys. The dialog opens from
  the project form's client dropdown; saving creates a client through the
  existing `ClientRepositoryInterface` and auto-selects it.
- Improved error handling: database/input failures now show a friendly
  localized message (`فشل إنشاء العميل. يرجى المحاولة مرة أخرى.`) instead of
  exposing raw exceptions to the user. No technical error text is rendered.
- No schema, repository, routing, or backend changes. No Dio/API calls.
  Validation: `flutter analyze --no-pub` clean of errors; full
  `flutter test --no-pub --concurrency=1` suite passed (476 tests, +1 new
  error-handling widget test). Existing clients/projects persistence tests
  remain green.

## 2026-08-08 — Unified Currency Display Formatting and Responsive Financial Rows

- Added a unified presentation formatter `formatCurrencyDisplay` (and a
  compact `formatCurrencyCompact`) in `core/database/finance/money_scale.dart`.
  YER renders with no decimals and thousands separators (e.g. `400,000 YER`),
  SAR with two decimals (e.g. `250,000.00 SAR`). Currency code is always a
  suffix. Formatting is display-only; no `double` is used for money and no
  exchange/calculation logic was touched.
- Replaced four competing per-screen formatters (`formatDisplayAmount` in
  project presentation, `_formatYer` in dashboard, `_formatYer`/`_formatMoney`
  in reports, and manual `'... ${currency}'` interpolations in project
  detail/list) with the unified formatter. `formatDisplayAmount` now
  delegates to `formatCurrencyDisplay` for backward compatibility.
- Fixed RenderFlex overflow in `project_detail_screen.dart`: wrapped the
  `_ProfitCard` value `Text` in `Flexible` (maxLines 2, end-aligned, ellipsis
  fallback), wrapped `_TotalBanner` label/value in `Flexible`, and made the
  `_HeaderStat` label Row use `Expanded`+ellipsis. Verified at Redmi Note 8
  Pro logical size (360x770) for both YER and SAR large values, in EN and
  RTL Arabic, with no overflow exceptions.
- Localized the dashboard monthly chart tooltip labels (ايرادات/مصروفات/
  صافي التدفق → `context.tr` of `payments_received`/`expenses`/`net_cash_flow`)
  and made the tooltip Row responsive. Reports `_FinancialProjectRow` switched
  from a fixed `Row` to a `Wrap` so long names and currency values reflow.
- Validation: `flutter analyze` reports no new errors (only pre-existing
  info/warnings). Added 14 formatter unit tests and 8 detail-screen widget
  tests covering the spec's four scenarios (400,000 YER; 250,000.00 SAR;
  150,000,000 YER; small-screen RTL). Full suite: 475 tests passed.

## 2026-08-08 — Inline Client Creation from Project Form

- Added an "Add new project owner" option to the project form's client
  dropdown. Selecting it opens an inline dialog (no navigation away) that
  creates a client through the existing `ClientRepositoryInterface` and
  auto-selects the new client in the project form.
- New `AddClientDialog` widget under clients/presentation uses the existing
  repository/provider pattern; UI never touches Drift/AppDatabase directly.
  Validation (name required, email format) and UUID generation are preserved
  by reusing the local repository.
- Removed hardcoded English/Arabic strings from this workflow and added
  localized keys for both locales (dialog title, buttons, fields, validation
  messages). No schema, routing, backend, or package changes.
- Validation: `flutter analyze` reports no new errors (only pre-existing
  info/warnings). Added 9 widget tests covering existing selection, create +
  auto-select, cancel, empty-name validation, Arabic rendering without
  English mix, project validator, standalone dialog, and a local-DB render
  regression. Full suite: 453 tests passed.

## 2026-07-27 — Project Details Financial Summary and Localization

- Corrected the tab terminology and negative net-cash-flow formatting.
- Added textual cash-flow status and a separate safe cost-overrun warning.
- Localized expense categories, transaction rows, payment methods, milestone
  statuses, and create/edit dialogs while retaining canonical stored values.
- Added reusable localization/presentation helpers and focused tests.
- Validation: 444 Flutter tests and debug APK passed. Analyzer has no compile
  errors but reports existing UI lint info/warnings.

## 2026-07-26 (Phase 13 — Release Validation)

- Added deterministic startup recovery for canonical, rollback, and incoming
  SQLite files with quarantine and controlled failure.
- Removed INTERNET from the release manifest while retaining debug tooling
  permission.
- Added 13 release/recovery tests; full Flutter 435 passed.
- Built release APK/AAB. Production signing, permanent package ID, and physical
  update validation remain manual.

## 2026-07-26 (Phase 12 — Runtime API/Auth Removal)

### Phase 12 Completed

- Deleted production Dio/network configuration, endpoints, remote repositories,
  and obsolete authentication/session/login runtime.
- Moved five historical HTTP DTO contracts to test-only fixtures and removed
  `dio` plus `shared_preferences`.
- Retained Drift/SQLite, exact finance, Riverpod, localization, archive, crypto,
  and file selection. Router startup remains Dashboard-first.
- Backup/Restore remains functional and carries no token or password.
- Validation: analyzer clean; architecture 10; full Flutter 422; debug APK
  built; FastAPI baseline 17. Phase 13 was not started.

## 2026-07-26 (Phase 11 — Backup and Restore)

### Phase 11 Completed

- Added typed Backup manifest/preview/results and repository boundary with
  isolated snapshot, archive, checksum, and restore orchestration services.
- Created consistent SQLite snapshots with `VACUUM INTO`, exact record counts,
  streaming SHA-256, strict two-entry `.cerpbackup` archives, traversal and
  size defenses, staging migration, and integrity/foreign-key validation.
- Added close/replace/recreate lifecycle and `.pre_restore` rollback until
  post-reopen validation succeeds.
- Integrated accessible Backup/Restore controls into local Settings with
  system file selection, explicit replacement confirmation, progress states,
  and truthful unencrypted-file notice.
- No API/Auth removal, cloud operation, broad storage permission, attachment
  claim, router change, or backend production change was introduced.
- Validation: analyzer clean; Backup/Restore 42; database 75; contract 49;
  full Flutter 412; FastAPI baseline 17.

## 2026-07-26 (Phase 10 — Settings and Local Security)

### Phase 10 Completed

- Added typed settings domain/repository/provider/UI layers backed by the
  singleton Drift `app_settings` row.
- Persisted an exact scale-6 default SAR→YER rate and `en`/`ar` locale via
  schema version 4, including non-destructive migration and safe fallbacks.
- Applied the default only to newly created SAR payments/expenses after
  project-fixed and manual-rate precedence; historical snapshots are immutable.
- Replaced local shell auth-session/login/logout presentation with truthful
  offline single-device state. Preserved remote auth/Dio code is inactive.
- Added 27 Settings tests across persistence, migration, finance integration,
  validation, loading/error, and ten responsive RTL/LTR viewports.
- Validation: analyzer clean; database 75; contract 49; full Flutter 370;
  FastAPI baseline 17.
- Phase 11 is Ready and was not started.

## 2026-07-26 (Phase 09 — Reports Local Queries)

### Phase 09 Completed

- Added exact typed Reports domain models and filters, repository interface,
  local repository, preserved API repository, and read-only Reports DAO.
- Switched the runtime Reports provider from Dio/JWT to local Drift queries.
- Implemented Project Status, Financial Summary, and Expense Analysis only.
- Added inclusive dates, stored converted-YER totals, soft-delete exclusion,
  independent financial aggregation, basis-point ratios, and mutation invalidation.
- Updated Reports UI for typed local results, truthful local states, responsive
  RTL/LTR rendering, SAR budget formatting, and Net cash flow terminology.
- Tests: Reports 27; full Flutter 343; FastAPI baseline 17; analyzer 0 findings.
- Export remains disabled. Phase 10 was not started.

This file records notable updates made to the Construction ERP frontend.

## 2026-07-26 (Phase 08 — Dashboard Local Queries)

### Phase 08 Completed

- Activated the local Dashboard repository backed by Drift/SQLite; the preserved
  API adapter is not part of the active provider path.
- Added exact summary/project/timeline aggregation, zero-filled months,
  refresh/invalidation behavior, and responsive LTR/RTL coverage.
- Resolved all Flutter analyzer findings without suppressions, including
  repository-wide safe cleanup and analysis-only Reports compatibility edits.
- `flutter analyze --no-pub`: 0 findings.
- Tests: Dashboard 18; Clients 36; Projects 30; Milestones 30; Payments 35;
  Expenses 40; database 75; contract 49; full Flutter 316.
- Phase 09 is Ready; no Reports migration or behavior change was started.

## 2026-06-28

### Skeleton Stabilization

- Added `AGENTS.md` with Flutter/Riverpod/GoRouter/Dio conventions.
- Added `pubspec.yaml` with pinned dependencies: flutter, flutter_riverpod, go_router, dio, intl.
- Added feature-first `lib/` skeleton:
  - `lib/main.dart` entry point with `ProviderScope`.
  - `lib/core/`: config, constants, theme, network (Dio), router.
  - `lib/features/`: auth, clients, projects, payments, expenses, dashboard, reports, settings.
  - Each feature has `data/`, `domain/`, `presentation/` subfolders with `.gitkeep` placeholders.
- Added `.gitignore` for Flutter/Dart.

### Verification

- Pending `flutter pub get` and `flutter analyze` once Flutter SDK is installed on this machine.

## 2026-07-22

### Offline Migration Documentation

- Added offline migration governance rules to `frontend/AGENTS.md` for future agents implementing the local-first migration.
- Created `docs/offline_migration/` documentation set with 14 phase documents covering the full migration from Dio/FastAPI to Drift/SQLite.
- No Flutter source code was modified. No package was added. No implementation phase started.
- All phases remain in `Draft` status pending user confirmation of decisions (ADR-001 through ADR-010).

## 2026-07-22 (Phase 01 — Baseline and Contracts)

### Phase 01 Completed

- Created `frontend/test/contract/baseline_contracts_test.dart` with 50 contract tests verifying:
  - Client, Project, Milestone, Payment, Expense DTO fromJson/toJson/toEntity parsing.
  - Decimal round-trip precision (including trailing-zero stripping behavior).
  - Enum value verification (project status, milestone status, payment method, expense category).
  - Date parsing patterns (T00:00:00 append, DateTime.now() fallback).
  - Dashboard and report DTO parsing.
  - UUID compatibility.
  - 5 documented defects (R-013, R-022, R-023, R-024, R-025).
- No Flutter production source code was modified. No package was added.
- `flutter analyze` → 0 errors. `flutter test` → 50 passed.

## 2026-07-23 (Phase 02 — Local Database Foundation)

### Phase 02 Completed

- Added Drift dependencies to `pubspec.yaml`: drift, sqlite3_flutter_libs, path_provider, path, drift_dev.
- Created `frontend/lib/core/database/` with:
  - `app_database.dart` — Drift AppDatabase with schema version 1, FK activation, migration foundation.
  - `database_provider.dart` — Riverpod provider for AppDatabase.
  - `database_constants.dart` — Centralized constants (currencies, scales, enums, schema version).
  - `finance/` — money_scale.dart, exchange_rate.dart, currency_conversion.dart (scaled INTEGER, no double).
  - `tables/` — 6 Drift tables: clients, projects, milestones, payments, expenses, app_settings.
  - `daos/` — 6 DAOs with basic CRUD: clients, projects, milestones, payments, expenses, app_settings.
  - Generated files: `app_database.g.dart`, 6 `*_dao.g.dart` files.
- Created `frontend/test/database/phase02_database_test.dart` with 51 tests covering:
  - Money scale, exchange rate, currency conversion (including round-half-up, overflow, exactness).
  - Database lifecycle, FK enforcement, UUID round-trip, duplicate PK rejection.
  - All FK relationships (valid and orphan rejection).
  - Mixed-currency group IDs (expense_group_id, payment_group_id).
  - Historical exchange-rate immutability.
  - Date round-trip, transactions (commit and rollback), deletion safety.
  - DAO CRUD operations.
- `flutter analyze` → 0 errors. Phase 02 tests → 51 passed. Baseline tests → 50 passed.
- No existing feature repository or screen was modified or connected to the database.

## 2026-07-23 (Phase 02 — Corrective: Persistent Database)

### Phase 02 Corrective Completion

- `database_provider.dart` changed from `NativeDatabase.memory()` to `LazyDatabase` with `getApplicationDocumentsDirectory()` + `NativeDatabase.createInBackground(file)`.
- In-memory SQLite is now test-only (via `AppDatabase.forTesting()` or direct `NativeDatabase.memory()` in tests).
- Added `finance/snapshot_validation.dart` — YER identity and SAR snapshot validation.
- Added `test/database/phase02_persistence_test.dart` — 24 tests:
  - File creation, client/project/settings/payment/expense persistence after close/reopen.
  - FK active after reopen, schema version correct, no data loss on reopen, multiple instances on same file.
  - UUID: Drift enforces min TEXT(36) at Dart layer (not SQLite). Documented.
  - YER identity: rate=1,000,000, source=identity, converted=original. SAR: exact round-half-up.
- Total: 51 + 24 + 50 + 17 = 142 tests, all pass. `flutter analyze` → 0 errors.
- No feature repository migrated. No screen connected. FastAPI unchanged.

## 2026-07-23 (Phase 03 — Clients Local Storage)

### Phase 03 Completed

- Added `uuid: ^4.5.1` to `pubspec.yaml`.
- Created `lib/core/uuid/uuid_util.dart` — UUID v4 generation and validation.
- Created `lib/features/clients/domain/client_repository_interface.dart` — abstract interface returning entities.
- Created `lib/features/clients/data/local_client_repository.dart` — Drift/SQLite implementation.
- Created `lib/features/clients/data/api_client_repository.dart` — preserved remote adapter implementing interface.
- Created `lib/features/clients/data/client_mapper.dart` — Drift row <-> entity mapping.
- Updated `lib/features/clients/data/client_repository.dart` — preserved old class, implements interface.
- Updated `lib/features/clients/presentation/client_providers.dart` — uses `localClientRepositoryProvider`.
- Updated `client_form_screen.dart` — uses interface methods (no DTO classes).
- Updated `client_detail_screen.dart` — removed direct repository list call.
- Updated `project_form_screen.dart` — imports `client_providers.dart` for `clientRepositoryProvider`.
- Extended `lib/core/database/daos/clients_dao.dart` — active/archived filter, search, project count.
- Created `test/features/clients/phase03_clients_test.dart` — 36 tests (UUID, CRUD, search, mapping, persistence, interface).
- Client policies: active by default, archived excluded, archive/restore, hard-delete only when no projects.
- `flutter analyze` → 0 errors. Total: 36 + 51 + 24 + 50 + 17 = 178 tests pass.
- Remote FastAPI adapter preserved. No other feature migrated. No screen accesses AppDatabase directly.

## 2026-07-23 (Phase 04 — Projects Local Storage)

### Phase 04 Completed

- Updated `ProjectEntity` with multi-currency fields (budgetAmountMinor, budgetCurrency, exchangePolicy, fixedExchangeRateScaled).
- Created `domain/project_repository_interface.dart` — abstract interface with `ProjectFinancialSummary`.
- Created `data/local_project_repository.dart` — Drift implementation with validation, UUID check, client FK check.
- Created `data/api_project_repository.dart` — preserved remote adapter implementing interface.
- Created `data/project_mapper.dart` — Drift row <-> entity mapping.
- Updated `data/project_repository.dart` — legacy class preserved, implements interface.
- Updated `data/project_dto.dart` — `toEntity()` now returns multi-currency entity.
- Extended `core/database/daos/projects_dao.dart` — search, filters, child counts, YER sums.
- Updated `presentation/project_providers.dart` — uses `localProjectRepositoryProvider`, added `projectFinancialSummaryProvider`.
- Updated `presentation/project_form_screen.dart` — currency dropdown, exchange policy, fixed rate field.
- Updated `presentation/project_detail_screen.dart` — local profitability provider (removed Dio).
- Updated `features/reports/presentation/reports_screen.dart` — imports from `project_providers.dart`.
- Corrected `test/widget_test.dart` — replaced obsolete login test with router/database verification.
- Created `test/features/projects/phase04_projects_test.dart` — 30 tests.
- Local profitability: SUM queries (no Cartesian multiplication), zero-denominator guard, ratio not percentage.
- Transitional: child tabs (milestones/payments/expenses) remain remote but don't trigger Dio for local projects.
- `flutter analyze` → 0 errors. `flutter test` → 194 passed. `pytest` → 17 passed. Total 211, all pass.

## 2026-07-23 (Phase 05 — Milestones Local Storage)

### Phase 05 Completed

- Created `domain/milestone_repository_interface.dart` — abstract interface.
- Created `data/local_milestone_repository.dart` — Drift implementation with UUID/project validation.
- Created `data/api_milestone_repository.dart` — preserved remote adapter.
- Created `data/milestone_mapper.dart` — Drift row <-> entity mapping.
- Updated `data/milestone_repository.dart` — legacy class preserved, implements interface.
- Updated `domain/milestone_entity.dart` — added `effectiveStatus(referenceDate)` for overdue derivation.
- Extended `core/database/daos/milestones_dao.dart` — countByProject, countCompletedByProject.
- Updated `presentation/milestone_providers.dart` — uses `localMilestoneRepositoryProvider`, auto-invalidation.
- Updated `presentation/milestone_form_dialog.dart` — uses interface methods, passes projectId for invalidation.
- Overdue: stored status preserved, effective overdue derived at read time. Complete: idempotent.
- Created `test/features/milestones/phase05_milestones_test.dart` — 30 tests.
- `flutter analyze` → 0 errors. `flutter test` → 224 passed. `pytest` → 17 passed. Total 241, all pass.

## 2026-07-23 (Phase 06 — Payments Local Storage)

### Phase 06 Completed

- Schema migration v1 → v2: added `is_deleted` and `deleted_at` to payments table.
- Created `domain/payment_repository_interface.dart`, `data/local_payment_repository.dart`, `data/api_payment_repository.dart`, `data/payment_mapper.dart`.
- Updated `domain/payment_entity.dart` — multi-currency snapshot fields, soft-delete fields.
- Updated `data/payment_dto.dart` — `toEntity()` returns multi-currency entity.
- Updated `data/payment_repository.dart` — legacy class preserved, implements interface.
- Extended `core/database/daos/payments_dao.dart` — active/deleted queries, group ops, financial totals.
- Updated `core/database/daos/projects_dao.dart` — `sumPaymentsYer` excludes soft-deleted.
- Updated `presentation/payment_providers.dart` — local provider, auto-invalidation.
- Updated `presentation/payment_form_dialog.dart` — currency dropdown, SAR rate field.
- Updated `features/projects/presentation/project_detail_screen.dart` — payments tab uses new entity fields.
- Updated `core/database/database_constants.dart` — schema version 2.
- Updated `core/database/app_database.dart` — v1→v2 migration for soft-delete columns.
- Created `test/features/payments/phase06_payments_test.dart` — 35 tests.
- `flutter analyze` → 0 errors. `flutter test` → 259 passed. `pytest` → 17 passed. Total 276, all pass.

## 2026-07-23 (Phase 07 — Expenses Local Storage)

### Phase 07 Completed

- Schema migration v2 → v3: added `is_deleted` and `deleted_at` to expenses table.
- Created `domain/expense_repository_interface.dart`, `data/local_expense_repository.dart`, `data/api_expense_repository.dart`, `data/expense_mapper.dart`.
- Updated `domain/expense_entity.dart` — multi-currency snapshot fields, soft-delete fields.
- Updated `data/expense_dto.dart` — `toEntity()` returns multi-currency entity.
- Updated `data/expense_repository.dart` — legacy class preserved, implements interface.
- Extended `core/database/daos/expenses_dao.dart` — active/deleted queries, group ops, financial totals.
- Updated `core/database/daos/projects_dao.dart` — `sumExpensesYer` excludes soft-deleted.
- Updated `presentation/expense_providers.dart` — local provider, auto-invalidation.
- Updated `presentation/expense_form_dialog.dart` — currency dropdown, SAR rate field, category dropdown.
- Updated `features/projects/presentation/project_detail_screen.dart` — expenses tab uses new entity fields.
- Updated `core/database/database_constants.dart` — schema version 3.
- Updated `core/database/app_database.dart` — v2→v3 migration for expense soft-delete columns.
- Created `test/features/expenses/phase07_expenses_test.dart` — 40 tests.
- `flutter analyze` → 0 errors. `flutter test` → 299 passed. `pytest` → 17 passed. Total 316, all pass.
- All Project child features now local. No Project child requires FastAPI.
# 2026-07-26 — Phase 08 Dashboard local queries (In Progress)

- Dashboard runtime providers now use local Drift-derived queries through a domain interface.
- Added exact integer YER metrics, safe project aggregation, milestone progress,
  deterministic zero filling, mutation invalidation, truthful activity wording,
  and responsive financial-card wrapping.
- Preserved the remote adapter; Reports remain remote. Validation timed out.

### Validation continuation

- Added a local-provider selection test and a 10-viewport RTL/LTR Dashboard
  widget matrix with empty, loading, and local-error coverage.
- Fixed overflow in the Dashboard financial header, project-overview header,
  and quick-action cards; removed fabricated trends and corrected YER display.
- Focused Dashboard tests (18), full Flutter tests (316), and all feature
  regression suites pass.
- The phase remains In Progress because the mandatory analyzer command exits 1
  on existing repository-wide warnings/info outside the scoped correction.
