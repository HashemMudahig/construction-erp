# Phase 06 — Payments Local Storage

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Migrate payment data storage from the FastAPI backend to the local SQLite database. Implement the payment repository interface, local repository implementation, and migrate the Riverpod providers.

## Current State

Payment data is managed through:
- `frontend/lib/features/payments/data/payment_dto.dart` — `PaymentDto`, `PaymentCreateDto`, `PaymentUpdateDto`.
- `frontend/lib/features/payments/data/payment_repository.dart` — `PaymentRepository` using Dio.
- `frontend/lib/features/payments/domain/payment_entity.dart` — `PaymentEntity` with `id`, `projectId`, `amount` (Decimal), `paymentDate` (DateTime), `method`, `notes?`, `createdAt`.
- `frontend/lib/features/payments/presentation/payment_providers.dart` — `paymentsByProjectProvider`, `paymentActionsProvider`.

Payment fields:
| Field | Flutter Type | Backend Type |
|---|---|---|
| id | String | String(36) UUID |
| projectId | String | String(36) FK→projects.id CASCADE |
| amount | Decimal | Numeric(14,2) NOT NULL CHECK(>0) |
| paymentDate | DateTime | Date NOT NULL |
| method | String | String(20) NOT NULL CHECK IN(...) |
| notes | String? | Text NULL |
| createdAt | DateTime | DateTime(timezone=True) |

Method enum: `cash`, `bank_transfer`, `cheque`, `other`.

Business rules:
- `project_id` must reference an existing project.
- `amount` must be > 0.
- `method` must be one of the allowed values.
- `project_id` is not updatable after creation.
- Payments are ordered by `payment_date` descending in list queries.
- `sum_amount_by_project` is used for profitability calculations.

## Target State

- A `PaymentRepositoryInterface` in the domain layer.
- A `LocalPaymentRepository` using Drift DAOs.
- The existing `PaymentRepository` (Dio-based) preserved.
- Providers use the local repository.
- Amount stored as TEXT (Decimal string), never REAL.
- Method validation enforced locally.
- Amount > 0 validation enforced locally.
- Sum aggregation for profitability computed locally.

## Scope

- Payment table (created in Phase 02).
- Repository interface and local implementation.
- Provider migration.
- Amount precision preservation.
- Method enum validation.
- Sum aggregation for profitability.

## Out of Scope

- Dashboard payment aggregations (Phase 08).
- Reports financial summary (Phase 09).
- Profitability endpoint migration (depends on Phase 07).

## Prerequisites

- Phase 04 (Projects Local Storage) must be completed.
- ADR-005 (Never use SQLite REAL for financial values) must be Accepted.

## Relevant Current Files

- `frontend/lib/features/payments/data/payment_dto.dart`
- `frontend/lib/features/payments/data/payment_repository.dart`
- `frontend/lib/features/payments/domain/payment_entity.dart`
- `frontend/lib/features/payments/presentation/payment_providers.dart`
- `frontend/lib/features/payments/presentation/payment_form_dialog.dart`
- `frontend/lib/features/projects/presentation/project_detail_screen.dart`

## Expected New Files

- `frontend/lib/features/payments/domain/payment_repository_interface.dart` (proposed)
- `frontend/lib/features/payments/data/local_payment_repository.dart` (proposed)

## Data Model Impact

See [data_model_mapping.md](data_model_mapping.md). Key points:
- `amount`: TEXT (Decimal string like `"1250.00"`), NOT NULL, must be > 0.
- `payment_date`: TEXT (ISO date `YYYY-MM-DD`), NOT NULL.
- `method`: TEXT, one of `cash`, `bank_transfer`, `cheque`, `other`.

## Repository and Provider Impact

```
ProjectDetailScreen / PaymentFormDialog
→ paymentsByProjectProvider / paymentActionsProvider
→ PaymentRepositoryInterface
→ LocalPaymentRepository
→ PaymentDao
→ AppDatabase
→ SQLite
```

## Implementation Tasks

- [ ] Define `PaymentRepositoryInterface` abstract class.
- [ ] Implement `LocalPaymentRepository` using `PaymentDao`.
- [ ] Implement project existence validation.
- [ ] Implement amount > 0 validation.
- [ ] Implement method enum validation.
- [ ] Implement list query ordered by `payment_date` descending.
- [ ] Implement `sumAmountByProject` aggregation returning Decimal.
- [ ] Migrate `paymentsByProjectProvider` and `paymentActionsProvider`.
- [ ] Fix auto-invalidation after mutations.
- [ ] Write unit tests for local payment repository.
- [ ] Write financial precision tests (insert and retrieve exact Decimal values).
- [ ] Write persistence tests.
- [ ] Run `flutter analyze`.
- [ ] Verify project detail screen integration.

## Validation Plan

- Static analysis: `flutter analyze`.
- Unit tests: CRUD, amount validation, method validation, sum aggregation.
- Financial precision: Insert `"0.01"`, `"9999999999.99"`, verify exact retrieval.
- Persistence after restart: Create payment, close, reopen, verify.
- Offline behavior: All operations work offline.
- Regression checks: Project detail screen payment section functions correctly.

## Acceptance Criteria

1. Payments can be created, read, updated, and deleted locally.
2. Amount > 0 validation works.
3. Method enum validation works.
4. `sumAmountByProject` returns correct Decimal values.
5. No financial precision loss.
6. No HTTP calls for payment operations.
7. `flutter analyze` reports zero errors.
8. All payment tests pass.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-008: Financial precision loss. Mitigated by TEXT storage and Decimal parsing.
- R-006: Failed restore could corrupt payment data. Mitigated by backup validation (Phase 11).

## Rollback Strategy

1. Revert `payment_providers.dart` to use `PaymentRepository` (Dio-based).
2. Delete `PaymentRepositoryInterface` and `LocalPaymentRepository`.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 06 status.
- `frontend/HISTORY.md` — Add entry for payments local storage.
- `docs/history.md` — Add entry for payments local storage.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent