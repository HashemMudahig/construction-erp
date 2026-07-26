# Phase 05 — Milestones Local Storage

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Migrate milestone data storage from the FastAPI backend to the local SQLite database. Implement the milestone repository interface, local repository implementation, and migrate the Riverpod providers.

## Current State

Milestone data is managed through:
- `frontend/lib/features/milestones/data/milestone_dto.dart` — `MilestoneDto`, `MilestoneCreateDto`, `MilestoneUpdateDto`.
- `frontend/lib/features/milestones/data/milestone_repository.dart` — `MilestoneRepository` using Dio.
- `frontend/lib/features/milestones/domain/milestone_entity.dart` — `MilestoneEntity` with `id`, `projectId`, `title`, `description?`, `dueDate`, `status`, `createdAt`.
- `frontend/lib/features/milestones/presentation/milestone_providers.dart` — `milestonesByProjectProvider` (FutureProvider.family), `milestoneActionsProvider` (Provider<MilestoneActions>).

Milestone fields:
| Field | Flutter Type | Backend Type |
|---|---|---|
| id | String | String(36) UUID |
| projectId | String | String(36) FK→projects.id CASCADE |
| title | String | String(255) NOT NULL |
| description | String? | Text NULL |
| dueDate | DateTime | Date NOT NULL |
| status | String | String(20) default "pending" |
| createdAt | DateTime | DateTime(timezone=True) |

Status enum: `pending`, `in_progress`, `completed`, `overdue`.

Business rules:
- `project_id` must reference an existing project.
- `complete()` action only allowed from `pending` or `in_progress` status (`MILESTONE_INVALID_TRANSITION` 400).
- Milestones are ordered by `due_date` ascending.
- List can be filtered by `project_id` and `status`.

Known issue: `MilestoneEntity` imports `decimal` but never uses it. This should be cleaned up during migration.

## Target State

- A `MilestoneRepositoryInterface` in the domain layer.
- A `LocalMilestoneRepository` using Drift DAOs.
- The existing `MilestoneRepository` (Dio-based) preserved.
- Providers use the local repository.
- Project FK validation enforced locally.
- Status transition validation enforced locally.
- Due date stored as TEXT (ISO date).
- Milestones ordered by due_date in local queries.

## Scope

- Milestone table (created in Phase 02).
- Repository interface and local implementation.
- Provider migration.
- Status transition validation.
- Due date handling.
- Progress calculations for project detail screen.

## Out of Scope

- Dashboard milestone aggregations (Phase 08).
- Reports milestone progress (Phase 09).
- Overdue calculation automation (may be a derived query, not stored).

## Prerequisites

- Phase 04 (Projects Local Storage) must be completed.

## Relevant Current Files

- `frontend/lib/features/milestones/data/milestone_dto.dart`
- `frontend/lib/features/milestones/data/milestone_repository.dart`
- `frontend/lib/features/milestones/domain/milestone_entity.dart`
- `frontend/lib/features/milestones/presentation/milestone_providers.dart`
- `frontend/lib/features/milestones/presentation/milestone_form_dialog.dart`
- `frontend/lib/features/projects/presentation/project_detail_screen.dart`

## Expected New Files

- `frontend/lib/features/milestones/domain/milestone_repository_interface.dart` (proposed)
- `frontend/lib/features/milestones/data/local_milestone_repository.dart` (proposed)

## Data Model Impact

See [data_model_mapping.md](data_model_mapping.md). Key points:
- `project_id`: TEXT, FK→projects.id, ON DELETE CASCADE.
- `due_date`: TEXT (ISO date `YYYY-MM-DD`), NOT NULL.
- `status`: TEXT, one of `pending`, `in_progress`, `completed`, `overdue`.

## Repository and Provider Impact

```
ProjectDetailScreen / MilestoneFormDialog
→ milestonesByProjectProvider / milestoneActionsProvider
→ MilestoneRepositoryInterface
→ LocalMilestoneRepository
→ MilestoneDao
→ AppDatabase
→ SQLite
```

## Implementation Tasks

- [ ] Define `MilestoneRepositoryInterface` abstract class.
- [ ] Implement `LocalMilestoneRepository` using `MilestoneDao`.
- [ ] Implement project existence validation.
- [ ] Implement status transition validation for `complete()`.
- [ ] Implement list query ordered by `due_date` ascending.
- [ ] Implement filter by `project_id` and `status`.
- [ ] Migrate `milestonesByProjectProvider` and `milestoneActionsProvider`.
- [ ] Fix auto-invalidation: ensure `milestonesByProjectProvider` is invalidated after mutations.
- [ ] Remove unused `decimal` import from `MilestoneEntity`.
- [ ] Write unit tests for local milestone repository.
- [ ] Write persistence tests.
- [ ] Run `flutter analyze`.
- [ ] Verify project detail screen integration.

## Validation Plan

- Static analysis: `flutter analyze`.
- Unit tests: CRUD, status transition, project FK validation, ordering, filters.
- Persistence after restart: Create milestone, close, reopen, verify.
- Offline behavior: All operations work offline.
- Regression checks: Project detail screen milestone section functions correctly.

## Acceptance Criteria

1. Milestones can be created, read, updated, completed, and deleted locally.
2. `complete()` rejects invalid status transitions.
3. Milestones are ordered by `due_date` ascending.
4. Filter by `project_id` and `status` works.
5. No HTTP calls for milestone operations.
6. `flutter analyze` reports zero errors.
7. All milestone tests pass.
8. Auto-invalidation works after mutations.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-014: Invalid date parsing for `due_date`. Mitigated by ISO date format.
- R-015: Timezone inconsistencies. Mitigated by storing dates without time components.

## Rollback Strategy

1. Revert `milestone_providers.dart` to use `MilestoneRepository` (Dio-based).
2. Delete `MilestoneRepositoryInterface` and `LocalMilestoneRepository`.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 05 status.
- `frontend/HISTORY.md` — Add entry for milestones local storage.
- `docs/history.md` — Add entry for milestones local storage.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent