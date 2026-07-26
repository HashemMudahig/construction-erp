# Phase 03 — Clients Local Storage

## Status

- Status: Draft
- Owner: Unassigned
- Created: 2026-07-22
- Last updated: 2026-07-22
- Implementation started: Not started
- Implementation completed: Not started

## Objective

Migrate client data storage from the FastAPI backend to the local SQLite database. Implement the client repository interface, local repository implementation, and migrate the Riverpod providers to use local storage instead of Dio.

## Current State

Client data is managed through:
- `frontend/lib/features/clients/data/client_dto.dart` — `ClientDto`, `ClientCreateDto`, `ClientUpdateDto`.
- `frontend/lib/features/clients/data/client_repository.dart` — `ClientRepository` using Dio with endpoints `GET /clients`, `POST /clients`, `GET /clients/{id}`, `PUT /clients/{id}`, `DELETE /clients/{id}`.
- `frontend/lib/features/clients/domain/client_entity.dart` — `ClientEntity` with `id`, `name`, `phone?`, `email?`, `address?`, `notes?`, `archived`, `createdAt`, `updatedAt`.
- `frontend/lib/features/clients/presentation/client_providers.dart` — `clientsListProvider` (AsyncNotifierProvider), `clientDetailProvider` (FutureProvider.family).

Client fields:
| Field | Flutter Type | Backend Type |
|---|---|---|
| id | String | String(36) UUID |
| name | String | String(200) NOT NULL |
| phone | String? | String(40) NULL |
| email | String? | String(255) NULL |
| address | String? | String(500) NULL |
| notes | String? | Text NULL |
| archived | bool (default false) | Boolean (default false) |
| createdAt | DateTime | DateTime(timezone=True) |
| updatedAt | DateTime | DateTime(timezone=True) |

Business rules:
- Clients can be archived (soft delete via `archived = true`).
- Clients cannot be hard-deleted if they have linked projects (`CLIENT_HAS_PROJECTS` 409).
- Search filters by name, email, or phone (case-insensitive `ILIKE`).

## Target State

- A `ClientRepositoryInterface` (abstract class) in the domain layer.
- A `LocalClientRepository` implementation using Drift DAOs.
- The existing `ClientRepository` (Dio-based) preserved as a future remote adapter.
- Riverpod providers (`clientsListProvider`, `clientDetailProvider`) use the local repository.
- UUIDs generated locally (UUID v4) instead of by PostgreSQL.
- Search performed via SQLite queries.
- Archive/unarchive via local update.
- Delete restriction (cannot delete client with projects) enforced locally.

## Scope

- Client table (already created in Phase 02).
- Client repository interface.
- Local client repository implementation.
- Provider migration.
- UUID generation strategy.
- Search implementation.
- Archive vs. delete behavior.
- Persistence tests.

## Out of Scope

- Projects, milestones, payments, expenses local storage (Phases 04–07).
- Dashboard and reports (Phases 08–09).
- Backup and restore (Phase 11).
- Removal of Dio provider (Phase 12).

## Prerequisites

- Phase 02 (Local Database Foundation) must be completed.
- ADR-004 (UUIDs remain primary identifiers) must be Accepted.
- ADR-006 (Repository interfaces separate UI from data source) must be Accepted.

## Relevant Current Files

- `frontend/lib/features/clients/data/client_dto.dart`
- `frontend/lib/features/clients/data/client_repository.dart`
- `frontend/lib/features/clients/domain/client_entity.dart`
- `frontend/lib/features/clients/presentation/client_providers.dart`
- `frontend/lib/features/clients/presentation/client_list_screen.dart`
- `frontend/lib/features/clients/presentation/client_detail_screen.dart`
- `frontend/lib/features/clients/presentation/client_form_screen.dart`

## Expected New Files

- `frontend/lib/features/clients/domain/client_repository_interface.dart` (proposed)
- `frontend/lib/features/clients/data/local_client_repository.dart` (proposed)

## Data Model Impact

See [data_model_mapping.md](data_model_mapping.md) for the Client entity mapping. Key points:
- `id`: TEXT, UUID v4 generated locally.
- `archived`: INTEGER (0/1) in SQLite, bool in Dart.
- `created_at`, `updated_at`: TEXT ISO 8601 timestamps.

## Repository and Provider Impact

```
ClientListScreen / ClientDetailScreen / ClientFormScreen
→ clientsListProvider / clientDetailProvider
→ ClientRepositoryInterface
→ LocalClientRepository
→ ClientDao
→ AppDatabase
→ SQLite
```

## Implementation Tasks

- [ ] Define `ClientRepositoryInterface` abstract class in domain layer.
- [ ] Implement `LocalClientRepository` using `ClientDao`.
- [ ] Implement local UUID generation (UUID v4).
- [ ] Implement search (name, email, phone) via SQLite LIKE queries.
- [ ] Implement archive/unarchive (update `archived` field).
- [ ] Implement delete with project count check (reject if projects exist).
- [ ] Migrate `clientsListProvider` to use `ClientRepositoryInterface`.
- [ ] Migrate `clientDetailProvider` to use `ClientRepositoryInterface`.
- [ ] Verify `client_providers.dart` no longer imports `dioProvider`.
- [ ] Write unit tests for local client repository.
- [ ] Write persistence tests (create, read, update, archive, delete, restart, verify).
- [ ] Run `flutter analyze` and ensure zero errors.
- [ ] Verify UI compatibility (screens render correctly with local data).

## Validation Plan

- Static analysis: `flutter analyze`.
- Unit tests: CRUD operations, search, archive, delete restriction.
- Persistence after restart: Create client, close app, reopen, verify data.
- Offline behavior: All operations work with no network.
- Regression checks: Client list, detail, and form screens function identically.

## Acceptance Criteria

1. Clients can be created, read, updated, archived, and deleted locally.
2. Search by name, email, or phone works locally.
3. Delete is rejected when the client has linked projects.
4. UUIDs are generated locally and are valid UUID v4 strings.
5. No HTTP calls are made for client operations.
6. `flutter analyze` reports zero errors.
7. All client tests pass.
8. Client screens render and function correctly with local data.

## Risks

See [risk_register.md](risk_register.md). Key risks:

- R-010: Duplicate UUID during import — mitigated by UUID v4 collision resistance.
- R-011: Orphan records — mitigated by foreign key enforcement.
- R-015: Timezone inconsistencies — mitigated by storing UTC timestamps.

## Rollback Strategy

1. Revert `client_providers.dart` to use `ClientRepository` (Dio-based).
2. Delete `ClientRepositoryInterface` and `LocalClientRepository`.
3. The application returns to fetching clients from the backend.

## Documentation Updates Required on Completion

- `docs/offline_migration/README.md` — Update phase 03 status.
- `frontend/HISTORY.md` — Add entry for clients local storage.
- `docs/history.md` — Add entry for clients local storage.

## Completion Record

- Completion date: Not completed
- Commands executed: None
- Tests passed: N/A
- Analyzer result: N/A
- Files created: None
- Files modified: None
- Remaining issues: None
- Git commit: Not created by agent