# Construction ERP Frontend Agent Guidelines

## Project Scope

- This is the Flutter frontend for the Construction ERP platform.
- Primary stack: Flutter, Riverpod, GoRouter, Dio.
- Targets: Android, iOS, Web (future).
- The app is intentionally simple: a single administrative user. No multi-tenant or RBAC complexity in v1.

## Source of Truth

- Treat `lib/` as the implementation source of truth.
- Treat `backend/docs/Sprint_XX_<Name>/04_Frontend_Developer_Guide.md` and `15_UI_UX_Screen_Specification.md` as the per-sprint frontend spec.
- Treat `HISTORY.md` as the running frontend change log.

## Architecture

- Feature-first structure: `lib/features/<feature>/{data,domain,presentation}`.
- `lib/core/`: app-wide config, constants, theme, router, network, error handling, utils.
- `lib/providers/`: Riverpod providers for app state and services.
- `lib/routes/`: GoRouter configuration.

## Data Layer

- API clients use Dio.
- DTOs and repositories live in `lib/features/<feature>/data/`.
- Endpoints are constants in `lib/core/constants/endpoints.dart`. Do not hardcode endpoint strings in screens or providers.

## Domain Layer

- Entities and use cases live in `lib/features/<feature>/domain/`.

## Presentation Layer

- Screens and widgets live in `lib/features/<feature>/presentation/`.
- State management uses Riverpod.
- Show loading, empty, and error states.
- Keep risky operations behind confirmation dialogs.

## Rules

- Screens consume providers and render UI. They should not own API contracts.
- Types live in `lib/features/<feature>/domain/entities/`, not inside screens or providers.
- Match backend response contracts exactly in DTO definitions.
- The backend uses the standard response envelope `{ success, message, data }`. Parse it in the Dio layer.

## Verification

- `flutter analyze` from `frontend/`.
- `flutter build` from `frontend/`.
- Update `HISTORY.md` after verification with what was checked.

## Change Guidance

- Prefer small, targeted changes.
- If a change touches DTOs, check the backend schemas for contract drift.
- If a change touches auth, verify login and protected-route access together.

## Offline Migration Implementation Rules

The Flutter frontend is planned to become a local-first, fully offline application using Drift and SQLite. The migration plan is documented in `docs/offline_migration/`.

### Before Starting Migration Work

1. Read `docs/offline_migration/README.md` for the phase list and status.
2. Read the document for the exact phase being implemented (e.g., `docs/offline_migration/03_clients_local_storage.md`).
3. Verify all prerequisite phases are completed.

### During Implementation

4. Implement only the requested phase. Do not skip ahead or edit unrelated phases.
5. Never store financial values as `double` or SQLite `REAL`. Use `Decimal` in Dart and TEXT in SQLite.
6. Preserve UUID compatibility — all primary keys remain UUID v4 stored as TEXT.
7. Foreign keys are mandatory (`PRAGMA foreign_keys = ON`).
8. Keep the FastAPI backend preserved. Do not delete or break backend code.
9. Add and run phase-specific tests before marking a phase as complete.
10. Leave changes uncommitted unless explicitly instructed otherwise.

### After Implementation

11. Update the phase document status and completion record.
12. Update `docs/offline_migration/README.md` status table.
13. Update `frontend/HISTORY.md` with a summary of changes.
14. Update `docs/history.md` with a summary of changes.
15. Never claim a phase is complete if tests or acceptance criteria fail.
16. Record unresolved decisions in `docs/offline_migration/decision_log.md`.