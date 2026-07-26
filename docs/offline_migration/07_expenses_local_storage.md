# Phase 07 — Expenses Local Storage

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Migrate expense data storage from the FastAPI backend to the local SQLite database. Implement the expense repository interface, local repository implementation, and migrate the Riverpod providers.

## Current State

Expense data is managed through:
- `frontend/lib/features/expenses/data/expense_dto.dart` — `ExpenseDto`, `ExpenseCreateDto`, `ExpenseUpdateDto`.
- `frontend/lib/features/expenses/data/expense_repository.dart` — `ExpenseRepository` using Dio.
- `frontend/lib/features/expenses/domain/expense_entity.dart` — `ExpenseEntity` with `id`, `projectId`, `category`, `amount` (Decimal), `expenseDate` (DateTime), `notes?`, `createdAt`.
- `frontend/lib/features/expenses/presentation/expense_providers.dart` — `expensesByProjectProvider`, `expenseActionsProvider`.

Expense fields:
| Field | Flutter Type | Backend Type |
|---|---|---|
| id | String | String(36) UUID |
| projectId | String | String(36) FK→projects.id CASCADE |
| category | String | String(100) NOT NULL |
| amount | Decimal | Numeric(14,2) NOT NULL CHECK(>0) |
| expenseDate | DateTime | Date NOT NULL |
| notes | String? | Text NULL |
| createdAt | DateTime | DateTime(timezone=True) |

Category enum: `materials`, `labor`, `equipment`, `permits`, `other`.

Business rules:
- `project_id` must reference an existing project.
- `amount` must be > 0.
- `category` must be one of the allowed values (enforced at Pydantic layer only; no DB CHECK constraint in PostgreSQL).
- `project_id` is not updatable after creation.
- Expenses are ordered by `expense_date` descending in list queries.
- `sum_amount_by_project` is used for profitability calculations.
- Expenses feed into dashboard and report aggregations.

Known inconsistency: The backend has no DB-level CHECK constraint for expense categories. The local database should add one for data integrity.

## Target State

- An `ExpenseRepositoryInterface` in the domain layer.
- A `LocalExpenseRepository` using Drift DAOs.
- The existing `ExpenseRepository` (Dio-based) preserved.
- Providers use the local repository.
- Amount stored as TEXT (Decimal string), never REAL.
- Category validation enforced locally (and optionally via SQLite CHECK constraint).
- Sum aggregation for profitability computed locally.

## Scope

- Expense table (created in Phase 02).
- Repository interface and local implementation.
- Provider migration.
- Amount precision preservation.
- Category enum validation.
- Sum aggregation for profitability.
- Optional: SQLite CHECK constraint for category (improvement over backend).

## Out of Scope

- Dashboard expense aggregations (Phase 08).
- Reports expense analysis (Phase 09).
- Receipt/attachment storage (not currently implemented in the app).

## Prerequisites

- Phase 04 (Projects Local Storage) must be completed.
- ADR-005 (Never use SQLite REAL for financial values) must be Accepted.

## Relevant Current Files

- `frontend/lib/features/expenses/data/expense_dto.dart`
- `frontend/lib/features/expenses/data/expense_repository.dart`
- `frontend/lib/features/expenses/domain/expense_entity.dart`
- `frontend/lib/features/expenses/presentation/expense_providers.dart`
- `frontend/lib/features/expenses/presentation/expense_form_dialog.dart`
- `frontend/lib/features/projects/presentation/project_detail_screen.dart`

## Expected New Files

- `frontend/lib/features/expenses/domain/expense_repository_interface.dart` (proposed)
- `frontend/lib/features/expenses/data/local_expense_repository.dart` (proposed)

## Data Model Impact

See [data_model_mapping.md](data_model_mapping.md). Key points:
- `amount`: TEXT (Decimal string), NOT NULL, must be > 0.
- `expense_date`: TEXT (ISO date `YYYY-MM-DD`), NOT NULL.
- `category`: TEXT, one of `materials`, `labor`, `equipment`, `permits`, `other`.
- Consider adding a CHECK constraint for category in SQLite (improvement over backend).

## Repository and Provider Impact

```
ProjectDetailScreen / ExpenseFormDialog
→ expensesByProjectProvider / expenseActionsProvider
→ ExpenseRepositoryInterface
→ LocalExpenseRepository
→ ExpenseDao
→ AppDatabase
→ SQLite
```

## Implementation Tasks

- [ ] Define `ExpenseRepositoryInterface` abstract class.
- [ ] Implement `LocalExpenseRepository` using `ExpenseDao`.
- [ ] Implement project existence validation.
- [ ] Implement amount > 0 validation.
- [ ] Implement category enum validation.
- [ ] Implement list query ordered by `expense_date` descending.
- [ ] Implement filter by `project_id` and `category`.
- [ ] Implement `sumAmountByProject` aggregation returning Decimal.
- [ ] Migrate `expensesByProjectProvider` and `expenseActionsProvider`.
- [ ] Fix auto-invalidation after mutations.
- [ ] Write unit tests for local expense repository.
- [ ] Write financial precision tests.
- [ ] Write persistence tests.
- [ ] Run `flutter analyze`.
- [ ] Verify project detail screen integration.

## Validation Plan

- Static analysis: `flutter analyze`.
- Unit tests: CRUD, amount validation, category validation, sum aggregation, filters.
- Financial precision: Insert and retrieve exact Decimal values.
- Persistence after restart: Create expense, close, reopen, verify.
- Offline behavior: All operations work offline.
- Regression checks: Project detail screen expense section functions correctly.

## Acceptance Criteria

1. Expenses can be created, read, updated, and deleted locally.
2. Amount > 0 validation works.
3. Category enum validation works.
4. `sumAmountByProject` returns correct Decimal values.
5. No financial precision loss.
6. Filter by `project_id` and `category` works.
7. No HTTP calls for expense operations.
8. `flutter analyze` reports zero errors.
9. All expense tests pass.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-008: Financial precision loss. Mitigated by TEXT storage.
- R-018: Attachment path invalidation — not applicable yet (attachments not implemented).

## Rollback Strategy

1. Revert `expense_providers.dart` to use `ExpenseRepository` (Dio-based).
2. Delete `ExpenseRepositoryInterface` and `LocalExpenseRepository`.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 07 status.
- `frontend/HISTORY.md` — Add entry for expenses local storage.
- `docs/history.md` — Add entry for expenses local storage.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent