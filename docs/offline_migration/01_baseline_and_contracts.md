# Phase 01 — Baseline and Contracts

## Status

- Status: Completed
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: 2026-07-22
- Implementation completed: 2026-07-22

## Objective

Document the exact current data contracts (Flutter DTOs, entities, FastAPI schemas, SQLAlchemy models), enum values, Decimal/money behavior, dashboard and report formulas, delete behavior, and known inconsistencies. Establish baseline tests that must pass before any storage changes begin.

## Current State

### Flutter DTOs and Entities

The Flutter frontend uses a feature-first architecture with DTOs in `data/` layers and entities in `domain/` layers. Key contracts:

**Clients** (`frontend/lib/features/clients/`):
- `ClientDto`: `id`, `name`, `phone?`, `email?`, `address?`, `notes?`, `archived` (default `false`), `createdAt`, `updatedAt` — all strings except `archived` (bool).
- `ClientEntity`: `id` (String), `name` (String), `phone?` (String), `email?` (String), `address?` (String), `notes?` (String), `archived` (bool), `createdAt` (DateTime), `updatedAt` (DateTime).
- `ClientCreateDto`: `name` (required), `phone?`, `email?`, `address?`, `notes?`, `archived` (default `false`).
- `ClientUpdateDto`: all fields nullable.

**Projects** (`frontend/lib/features/projects/`):
- `ProjectDto`: `id`, `clientId`, `name`, `description?`, `budget` (String), `startDate?`, `endDate?`, `status`, `createdAt`.
- `ProjectEntity`: `budget` is `Decimal` (from `decimal` package), `startDate`/`endDate` are `DateTime?`, `createdAt` is `DateTime`.
- `ProjectCreateDto`: `status` defaults to `'planning'`.

**Milestones** (`frontend/lib/features/milestones/`):
- `MilestoneDto`: `id`, `projectId`, `title`, `description?`, `dueDate`, `status`, `createdAt`.
- `MilestoneEntity`: `dueDate` is `DateTime`, `createdAt` is `DateTime`.
- `MilestoneCreateDto`: `status` defaults to `'pending'`.

**Payments** (`frontend/lib/features/payments/`):
- `PaymentDto`: `id`, `projectId`, `amount` (String), `paymentDate`, `method`, `notes?`, `createdAt`.
- `PaymentEntity`: `amount` is `Decimal`, `paymentDate` is `DateTime`.

**Expenses** (`frontend/lib/features/expenses/`):
- `ExpenseDto`: `id`, `projectId`, `category`, `amount` (String), `expenseDate`, `notes?`, `createdAt`.
- `ExpenseEntity`: `amount` is `Decimal`, `expenseDate` is `DateTime`.

**Dashboard** (`frontend/lib/features/dashboard/presentation/dashboard_providers.dart`):
- `DashboardSummary`: `activeProjects` (int), `completedProjects` (int), `totalClients` (int), `outstandingBalances` (Decimal), `totalPayments` (Decimal), `totalExpenses` (Decimal).
- `ProjectOverview`: `projectId`, `name`, `clientName`, `status`, `budget` (Decimal), `paymentsSum` (Decimal), `expensesSum` (Decimal), `balance` (Decimal).
- `MonthlyPoint`: `month` (String), `income` (Decimal), `expense` (Decimal).
- `FinanceOverview`: `months` (List<MonthlyPoint>).

**Reports** (`frontend/lib/features/reports/presentation/report_providers.dart`):
- `ProjectStatusItem`: `projectId`, `name`, `status`, `budget` (Decimal), `totalPayments` (Decimal), `totalExpenses` (Decimal), `balance` (Decimal), `milestoneCount` (int), `completedMilestones` (int), `progressPct` (Decimal).
- `FinancialSummary`: `startDate?`, `endDate?`, `totalIncome` (Decimal), `totalExpenses` (Decimal), `net` (Decimal), `perProject` (List<ProjectFinancial>).
- `ExpenseAnalysis`: `startDate?`, `endDate?`, `projectId?`, `grandTotal` (Decimal), `byCategory` (List<CategoryBreakdown>), `byProject` (List<ProjectExpense>).

### FastAPI Schemas and SQLAlchemy Models

**Enum values:**
- Project status: `planning`, `active`, `completed`, `on_hold`, `cancelled`.
- Milestone status: `pending`, `in_progress`, `completed`, `overdue`.
- Payment method: `cash`, `bank_transfer`, `cheque`, `other`.
- Expense category: `materials`, `labor`, `equipment`, `permits`, `other`.

**Decimal and money behavior:**
- Backend stores money as `Numeric(14, 2)` in PostgreSQL.
- Backend serializes Decimal as string in JSON responses.
- Frontend parses money via `Decimal.parse(String)` from the `decimal` package.
- Profitability margin: `(balance / total_payments).quantize(Decimal("0.01"))` if `total_payments > 0`, else `Decimal("0.00")`.

**Dashboard and report formulas:**
- `outstanding_balances` = sum of project balances where balance < 0 (or total outstanding).
- `balance` (per project) = `payments_sum - expenses_sum`.
- `progress_pct` = `completed_milestones / milestone_count * 100` (quantized to 0.01).
- `net` (financial summary) = `total_income - total_expenses`.
- Expense `percentage` = `total / grand_total * 100` (quantized to 0.01).

**Delete behavior:**
- Client delete: `RESTRICT` — cannot delete a client with linked projects (`CLIENT_HAS_PROJECTS` 409).
- Project delete: `CASCADE` — deleting a project deletes its milestones, payments, and expenses.
- Milestone/Payment/Expense delete: direct delete (FK CASCADE from project).

### Known Inconsistencies

1. `MilestoneEntity` imports `decimal` but never uses it — unused import.
2. `reportResultProvider` returns raw `Map<String, dynamic>` rather than typed DTOs — DTOs are defined but unused by the provider.
3. Dashboard and reports providers call `dioProvider` directly, bypassing the repository abstraction used by CRUD features.
4. `settings` feature is scaffolded only (empty `.gitkeep` files, no implementation, no route).
5. `MilestoneActions`, `PaymentActions`, `ExpenseActions` do not auto-invalidate their respective family providers after mutations — screens must manually call `ref.invalidate(...)`.
6. `AuthSession.copyWith` replaces `error` rather than coalescing — passing `null` clears the error.
7. Expense category has no DB-level CHECK constraint in PostgreSQL — enforced only at the Pydantic layer.
8. Project status has no DB-level CHECK constraint — enforced only at the Pydantic Literal.
9. Date parsing in Flutter falls back to `DateTime.now()` on parse failure, which could silently mask bad data.

## Target State

A documented baseline of all contracts, formulas, and behaviors that the local storage implementation must preserve. Baseline tests are defined (not yet implemented) to verify contract fidelity before and after migration.

## Scope

- Document all Flutter DTOs, entities, and their field types.
- Document all FastAPI Pydantic schemas and SQLAlchemy models.
- Document all enum values.
- Document all Decimal/money handling.
- Document all dashboard and report formulas.
- Document all delete and cascade behaviors.
- Document all known inconsistencies.
- Define the baseline test fixtures and test cases required before changing storage.

## Out of Scope

- Implementing Drift or SQLite.
- Modifying any application source code.
- Modifying any backend source code.

## Prerequisites

- Phase 00 (Migration Overview) should be reviewed.

## Relevant Current Files

- `frontend/lib/features/clients/data/client_dto.dart`
- `frontend/lib/features/clients/domain/client_entity.dart`
- `frontend/lib/features/projects/data/project_dto.dart`
- `frontend/lib/features/projects/domain/project_entity.dart`
- `frontend/lib/features/milestones/data/milestone_dto.dart`
- `frontend/lib/features/milestones/domain/milestone_entity.dart`
- `frontend/lib/features/payments/data/payment_dto.dart`
- `frontend/lib/features/payments/domain/payment_entity.dart`
- `frontend/lib/features/expenses/data/expense_dto.dart`
- `frontend/lib/features/expenses/domain/expense_entity.dart`
- `frontend/lib/features/dashboard/presentation/dashboard_providers.dart`
- `frontend/lib/features/reports/presentation/report_providers.dart`
- `backend/app/models/client.py`, `project.py`, `milestone.py`, `payment.py`, `expense.py`, `user.py`
- `backend/app/schemas/client.py`, `project.py`, `milestone.py`, `payment.py`, `expense.py`, `dashboard.py`, `reports.py`, `profitability.py`
- `backend/app/services/profitability_service.py`
- `backend/app/repositories/dashboard_repository.py`, `report_repository.py`

## Expected New Files

No new files are expected in this phase. This phase produces documentation only.

## Data Model Impact

No data model changes. This phase documents the existing data model.

## Repository and Provider Impact

No repository or provider changes. This phase documents existing contracts.

## Implementation Tasks

- [x] Verify all Flutter DTO field names and types against the actual source code.
- [x] Verify all FastAPI schema field names and types against the actual source code.
- [x] Verify all enum values against the actual source code.
- [x] Document the exact profitability formula from `profitability_service.py`.
- [x] Document the exact dashboard aggregation queries from `dashboard_repository.py`.
- [x] Document the exact report queries from `report_repository.py`.
- [x] Document the delete cascade behavior for each entity.
- [x] List all known inconsistencies and mark each as "preserve" or "fix during migration".
- [x] Define baseline test fixtures (sample clients, projects, milestones, payments, expenses).
- [x] Define baseline test cases that verify contract fidelity.
- [x] Create Flutter contract tests (`frontend/test/contract/baseline_contracts_test.dart`).
- [x] Create backend contract tests (`backend/tests/test_baseline_contracts.py`).
- [x] Verify all tests pass.
- [x] Document known defects (R-013, R-022, R-023, R-024, R-025).

## Validation Plan

- Static analysis: N/A (documentation-only).
- Unit tests: Define test cases but do not implement them.
- Database tests: N/A.
- Integration tests: N/A.
- Persistence after restart: N/A.
- Offline behavior: N/A.
- Regression checks: N/A.

## Acceptance Criteria

1. All Flutter DTOs and entities are documented with exact field names and types.
2. All FastAPI schemas and SQLAlchemy models are documented with exact column names and types.
3. All enum values are listed.
4. All Decimal/money handling is documented.
5. All dashboard and report formulas are documented.
6. All delete and cascade behaviors are documented.
7. All known inconsistencies are listed with a disposition (preserve or fix).
8. Baseline test fixtures and test cases are defined.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-008: Financial precision loss — baseline tests must verify Decimal fidelity.
- R-014: Invalid date parsing — baseline tests must verify date parsing behavior.
- R-020: Accidental continued HTTP calls — baseline must document all current HTTP call sites.

## Rollback Strategy

This phase is documentation-only. No rollback is needed.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 01 status.
- `docs/offline_migration/data_model_mapping.md` — Ensure mapping is consistent with baseline.
- `docs/history.md` — Add entry for baseline documentation completion.

## Completion Record

- Completion date: 2026-07-22
- Commands executed:
  - `flutter analyze` (0 errors)
  - `flutter test test/contract/baseline_contracts_test.dart` (50 tests passed)
  - `python -m pytest tests/test_baseline_contracts.py -v` (17 tests passed)
- Tests passed: 50 Flutter + 17 backend = 67 total
- Analyzer result: 0 errors
- Files created:
  - `frontend/test/contract/baseline_contracts_test.dart`
  - `backend/tests/test_baseline_contracts.py`
- Files modified:
  - `docs/offline_migration/decision_log.md` (ADR statuses updated, ADR-005 revised)
  - `docs/offline_migration/data_model_mapping.md` (verified contracts, enum matrix, date policy, financial formulas, delete matrix)
  - `docs/offline_migration/risk_register.md` (R-008 updated, R-013/R-022/R-023/R-024/R-025 added)
  - `docs/offline_migration/README.md` (Phase 01 status → In Progress, Phase 00 → Ready)
  - `docs/offline_migration/01_baseline_and_contracts.md` (this document)
  - `docs/history.md`
  - `HISTORY.md`
  - `frontend/HISTORY.md`
  - `backend/HISTORY.md`
- Remaining issues:
  - ADR-005 remains Proposed (monetary representation blocked until currency/scale confirmed)
  - 8 decisions remain "Decision Required" (see data_model_mapping.md)
  - 5 verified defects documented (R-013, R-022, R-023, R-024, R-025) — not fixed, only documented
- Git commit: Not created by agent