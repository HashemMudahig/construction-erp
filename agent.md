# Construction ERP Agent Guide

This file records how we work in this project so future implementation stays consistent.

## Workspace

- Backend: `C:\Users\pc\construction-erp\backend`
- Frontend: `C:\Users\pc\construction-erp\frontend`
- Planning/spec files: `C:\Users\pc\construction-erp\backend\docs\Sprint_XX_<Name>\`
- Root history: `C:\Users\pc\construction-erp\HISTORY.md`
- Per-package history: `C:\Users\pc\construction-erp\backend\HISTORY.md`, `C:\Users\pc\construction-erp\frontend\HISTORY.md`

## Working Style

- Read the existing code and the relevant sprint folder under `backend/docs/Sprint_XX_<Name>/` before changing it.
- Follow the project pattern already used in nearby files.
- Keep changes scoped to the requested workflow.
- Update `backend/docs/Sprint_XX_<Name>/12_Implementation_Roadmap.md` and `16_Acceptance_Criteria.md` when implementation changes the plan or completion state.
- Do not leave generated files changed unless they are intentionally part of the task.
- Ensure `HISTORY.md` exists at root, `backend/`, and `frontend/` and update the affected one with a summary after implementing any task.

## Backend Architecture Pattern

### Layers

- `app/main.py`: FastAPI app factory, middleware, and router registration.
- `app/core/`: config, database session, security (JWT, password hashing), response helpers.
- `app/models/`: SQLAlchemy ORM models. One module per entity.
- `app/schemas/`: Pydantic v2 request/response models. One module per entity.
- `app/repositories/`: SQLAlchemy data access. One repository per entity.
- `app/services/`: Business logic. One service per entity or workflow.
- `app/routers/`: Thin HTTP handlers. One router per entity.
- `app/utils/`: Shared helpers (dates, money, pagination).
- `app/tests/`: Backend tests.

### Rules

- Keep route handlers thin. No business logic in routers.
- Business logic lives in services.
- Database access goes through repositories, never directly in routers or services via raw SQL.
- All money and budget values use `Numeric`/`Decimal`. Never use `float` for money.
- All dates are stored as UTC and rendered in the user's timezone.
- Soft-delete where applicable; hard delete only when explicitly required.
- Every create/update/delete on a sensitive entity writes an audit record (when audit is enabled).
- All API responses follow the standard envelope: `{ "success": bool, "message": str, "data": ... }` (or `"errors": [...]` on failure).

### Authentication Model (Simple)

- This project is intentionally simple: a single administrative user.
- No multi-tenant, no roles, no per-action RBAC.
- JWT bearer auth protects all write endpoints and any read endpoint marked protected.
- Passwords are hashed with bcrypt. Never store plain-text passwords.
- A seeded admin account is created by `app/db/seed.py`.
- Future phases may extend to roles; until then, do not add permission tables.

### Database Rules

- SQLAlchemy models live in `app/models/`. One file per entity.
- PostgreSQL is the primary database.
- Prefer Alembic migrations for schema changes. Do not use `Base.metadata.create_all()` outside local setup.
- Keep `app/db/seed.py` idempotent.
- Use `UUID` primary keys with `gen_random_uuid()` (requires `pgcrypto`).
- Index foreign keys, status fields, and frequently filtered date columns.

### API Conventions

- Schemas (request/response) live in `app/schemas/`.
- Register new routers in `app/main.py`.
- Preserve explicit response models on routes.
- For ORM-backed Pydantic responses, use `from_attributes = True`.
- Use `/api/v1` prefix for all versioned routes.
- Health endpoints: `GET /api/v1/health` and `GET /api/v1/health/db`.

## Frontend Architecture Pattern

### Feature-First Structure

- `lib/features/<feature>/`: one folder per feature (auth, clients, projects, payments, expenses, dashboard, reports, settings).
- Each feature folder is split into `data/`, `domain/`, `presentation/`.
- `lib/core/`: app-wide config, constants, theme, router, network, error handling, utils.
- `lib/providers/`: Riverpod providers for app state and services.
- `lib/routes/`: GoRouter configuration.

### Data Layer

- API clients use Dio.
- DTOs and repositories live in `lib/features/<feature>/data/`.
- Endpoints are constants in `lib/core/constants/endpoints.dart`. Do not hardcode endpoint strings in screens or providers.

### Domain Layer

- Entities and use cases live in `lib/features/<feature>/domain/`.

### Presentation Layer

- Screens and widgets live in `lib/features/<feature>/presentation/`.
- State management uses Riverpod.
- Show loading, empty, and error states.
- Keep risky operations behind confirmation dialogs.

### Rules

- Screens consume providers and render UI. They should not own API contracts.
- Types live in `lib/features/<feature>/domain/entities/`, not inside screens or providers.
- Match backend response contracts exactly in DTO definitions.

## Verification

- Backend: `python -m pytest` from `backend/` when tests exist.
- Backend syntax: `python -c "import app.main"` from `backend/`.
- Alembic: `alembic upgrade head` then `alembic downgrade base` on a disposable DB before merging migrations.
- Frontend: `flutter analyze` and `flutter build` from `frontend/` when Flutter is installed.
- Always update `HISTORY.md` after verification with what was checked.

## Important Lessons

- This is a simple, single-admin ERP. Do not introduce multi-tenant, RBAC, or vendor portal complexity unless a future phase explicitly requires it.
- Money uses `Decimal`. Never `float`.
- Migrations are the source of truth for schema. Never hand-edit production tables.
- Documentation lives in the relevant sprint folder under `backend/docs/Sprint_XX_<Name>/`. Update those files when implementation changes scope or completion state.

## Offline Migration Governance

The Flutter frontend is planned to become a local-first, fully offline application. The migration plan is documented in `docs/offline_migration/`.

### Rules for Future Agents

1. Read `docs/offline_migration/README.md` before starting any migration work.
2. Read the document for the exact phase being implemented.
3. Implement only the requested phase. Do not skip ahead.
4. Never skip prerequisites (earlier phases must be completed first).
5. Update the phase status and completion record after implementation.
6. Update `docs/offline_migration/README.md` status table after any status change.
7. Update the relevant history file (`docs/history.md`, `frontend/HISTORY.md`) after completing a phase.
8. Keep the FastAPI backend preserved unless the user explicitly requests removal.
9. Never store financial values as `double` or SQLite `REAL`. Use `Decimal` in Dart and TEXT in SQLite.
10. Preserve UUID compatibility — all primary keys remain UUID v4 stored as TEXT.
11. Add and run phase-specific tests before marking a phase as complete.
12. Leave changes uncommitted unless explicitly instructed otherwise.
13. Never claim a phase is complete if tests or acceptance criteria fail.
14. Record unresolved decisions and blockers in `docs/offline_migration/decision_log.md`.
15. Avoid editing unrelated phases. Each phase document is independent.