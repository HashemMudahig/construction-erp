# Phase 04 — Projects Local Storage

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Migrate project data storage from the FastAPI backend to the local SQLite database. Implement the project repository interface, local repository implementation, and migrate the Riverpod providers.

## Current State

Project data is managed through:
- `frontend/lib/features/projects/data/project_dto.dart` — `ProjectDto`, `ProjectCreateDto`, `ProjectUpdateDto`.
- `frontend/lib/features/projects/data/project_repository.dart` — `ProjectRepository` using Dio.
- `frontend/lib/features/projects/domain/project_entity.dart` — `ProjectEntity` with `id`, `clientId`, `name`, `description?`, `budget` (Decimal), `startDate?`, `endDate?`, `status`, `createdAt`.
- `frontend/lib/features/projects/presentation/project_providers.dart` — `projectsListProvider`, `projectDetailProvider`.

Project fields:
| Field | Flutter Type | Backend Type |
|---|---|---|
| id | String | String(36) UUID |
| clientId | String | String(36) FK→clients.id RESTRICT |
| name | String | String(200) NOT NULL |
| description | String? | Text NULL |
| budget | Decimal | Numeric(14,2) NOT NULL CHECK(>=0) |
| startDate | DateTime? | Date NULL |
| endDate | DateTime? | Date NULL CHECK(end>=start) |
| status | String | String(20) default "planning" |
| createdAt | DateTime | DateTime(timezone=True) |

Status enum: `planning`, `active`, `completed`, `on_hold`, `cancelled`.

Business rules:
- `client_id` must reference an existing client (`PROJECT_CLIENT_INVALID` 400).
- `end_date` must be >= `start_date` if both are set (`PROJECT_DATE_INVALID` 400).
- `budget` must be >= 0.
- Deleting a project cascades to milestones, payments, and expenses.

## Target State

- A `ProjectRepositoryInterface` in the domain layer.
- A `LocalProjectRepository` using Drift DAOs.
- The existing `ProjectRepository` (Dio-based) preserved.
- Providers use the local repository.
- Foreign key to clients enforced locally.
- Date validation enforced locally.
- Budget validation (>= 0) enforced locally.
- Delete cascades to milestones, payments, expenses (FK CASCADE).

## Scope

- Project table (created in Phase 02).
- Project repository interface and local implementation.
- Provider migration.
- Foreign key validation.
- Date and budget validation.
- Delete cascade behavior.

## Out of Scope

- Milestones, payments, expenses local storage (Phases 05–07).
- Dashboard and reports (Phases 08–09).
- Profitability calculation (depends on payments and expenses).

## Prerequisites

- Phase 03 (Clients Local Storage) must be completed.
- ADR-008 (Foreign keys are mandatory) must be Accepted.

## Relevant Current Files

- `frontend/lib/features/projects/data/project_dto.dart`
- `frontend/lib/features/projects/data/project_repository.dart`
- `frontend/lib/features/projects/domain/project_entity.dart`
- `frontend/lib/features/projects/presentation/project_providers.dart`
- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/features/projects/presentation/project_detail_screen.dart`
- `frontend/lib/features/projects/presentation/project_form_screen.dart`

## Expected New Files

- `frontend/lib/features/projects/domain/project_repository_interface.dart` (proposed)
- `frontend/lib/features/projects/data/local_project_repository.dart` (proposed)

## Data Model Impact

See [data_model_mapping.md](data_model_mapping.md). Key points:
- `client_id`: TEXT, FK→clients.id, ON DELETE RESTRICT.
- `budget`: TEXT (Decimal string), not REAL.
- `start_date`, `end_date`: TEXT (ISO date `YYYY-MM-DD`), nullable.
- `status`: TEXT, one of the 5 enum values.

## Repository and Provider Impact

```
ProjectListScreen / ProjectDetailScreen / ProjectFormScreen
→ projectsListProvider / projectDetailProvider
→ ProjectRepositoryInterface
→ LocalProjectRepository
→ ProjectDao
→ AppDatabase
→ SQLite
```

## Implementation Tasks

- [ ] Define `ProjectRepositoryInterface` abstract class.
- [ ] Implement `LocalProjectRepository` using `ProjectDao`.
- [ ] Implement client existence validation (FK check).
- [ ] Implement date validation (end_date >= start_date).
- [ ] Implement budget validation (>= 0).
- [ ] Implement status filter and client_id filter in list query.
- [ ] Implement delete with cascade (FK CASCADE handles milestones, payments, expenses).
- [ ] Migrate `projectsListProvider` and `projectDetailProvider`.
- [ ] Write unit tests for local project repository.
- [ ] Write persistence tests.
- [ ] Run `flutter analyze`.
- [ ] Verify UI compatibility.

## Validation Plan

- Static analysis: `flutter analyze`.
- Unit tests: CRUD, validation rules, filters, cascade delete.
- Persistence after restart: Create project, close, reopen, verify.
- Offline behavior: All operations work offline.
- Regression checks: Project list, detail, and form screens function correctly.
- Foreign key enforcement: Creating a project with a non-existent client fails.

## Acceptance Criteria

1. Projects can be created, read, updated, and deleted locally.
2. Client FK validation works (rejects non-existent client).
3. Date validation works (rejects end_date < start_date).
4. Budget validation works (rejects negative budget).
5. Status and client_id filters work in list queries.
6. Delete cascades to milestones, payments, and expenses.
7. No HTTP calls for project operations.
8. `flutter analyze` reports zero errors.
9. All project tests pass.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-009: Cascade deletion — unintended data loss when deleting a project. Mitigated by confirmation dialogs and cascade being intentional.
- R-008: Financial precision loss for budget field. Mitigated by TEXT storage.

## Rollback Strategy

1. Revert `project_providers.dart` to use `ProjectRepository` (Dio-based).
2. Delete `ProjectRepositoryInterface` and `LocalProjectRepository`.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 04 status.
- `frontend/HISTORY.md` — Add entry for projects local storage.
- `docs/history.md` — Add entry for projects local storage.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent