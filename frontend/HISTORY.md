# Frontend History

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
