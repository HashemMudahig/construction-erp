# Backend History

This file records notable updates made to the Construction ERP backend.

## 2026-06-28

### Skeleton Stabilization

- Filled `app/core/config.py` with Pydantic Settings reading from `.env`.
- Filled `app/core/database.py` with a synchronous SQLAlchemy engine, session, and `Base`.
- Added `app/core/security.py` with JWT create/verify and bcrypt password hashing.
- Replaced the bare `app/main.py` stub with a runnable FastAPI app: CORS, health endpoints, `/api/v1` router mount, and standard response helpers.
- Added `app/utils/` package with pagination and date helpers.
- Added `app/db/` package with `seed.py` for the single admin account.
- Added `__init__.py` files to all `app/` subpackages.
- Added Alembic config and migration environment wired to `app.core.database.Base`.

### Infrastructure

- Added `.gitignore`, `.env.example`, `docker-compose.yml` for local PostgreSQL.
- Added `scripts/run_dev.bat` and `scripts/run_dev.sh`.
- Added `tests/` package skeleton.
- Updated `requirements.txt` with passlib[bcrypt], python-jose, python-multipart, and pytest.

### Verification

- `python -c "import app.main"` succeeds.
- `alembic check` validates the migration environment.

## 2026-06-28 (Sprint 01 backend pass)

### S01-T01 — FastAPI skeleton refined

- Added `app/core/exceptions.py` with `AppException` and FastAPI handlers mapping `AppException`, `RequestValidationError`, and unexpected exceptions to the standard error envelope.
- Wired exception handlers and CORS middleware in `app/main.py`.
- Registered `health`, `auth`, `clients`, `projects` routers under `/api/v1`.

### S01-T02 — PostgreSQL + first Alembic migration

- Created `app/models/mixins.py` (`TimestampMixin`, `UpdatedAtMixin`) to avoid circular imports.
- Created `app/models/user.py`, `client.py`, `project.py` with UUID PKs via `gen_random_uuid()`, `Numeric(14,2)` budget, status check constraint, and date-order check constraint.
- Created `alembic/versions/0001_initial.py`: `pgcrypto` extension, `users`/`clients`/`projects` tables, indexes (`idx_clients_name_lower`, `idx_projects_client_id`, `idx_projects_status`), `set_updated_at()` function + trigger on `clients`.
- Ran `alembic upgrade head` against local PostgreSQL 18: all 3 tables created, pgcrypto enabled.

### S01-T03 — JWT auth

- Added `OAuth2PasswordBearer` and `require_user` dependency in `app/core/security.py`.
- Protected routes reject missing tokens with `AUTH_TOKEN_MISSING` and invalid tokens with `AUTH_TOKEN_INVALID`.
- Created `app/services/auth_service.py` and `app/routers/auth.py` exposing `POST /api/v1/auth/login`.

### S01-T04 — Single admin seed

- Rewrote `app/db/seed.py` to be idempotent: inserts one admin row if no users exist, no-op otherwise.
- Seeded `admin@constructionerp.app` against the local database.

### S01-T05 — Client CRUD

- Created `app/schemas/client.py` (`ClientCreate`/`ClientRead`/`ClientUpdate` with `EmailStr` and length validation).
- Created `app/repositories/base.py` (generic CRUD) and `app/repositories/client_repo.py` (name/email/phone search + project count).
- Created `app/services/client_service.py` enforcing `CLIENT_NOT_FOUND` and `CLIENT_HAS_PROJECTS` rules.
- Created `app/routers/clients.py` with `GET/POST/GET/{id}/PUT/{id}/DELETE/{id}`.

### S01-T06 — Project CRUD

- Created `app/schemas/project.py` (`ProjectCreate`/`ProjectRead`/`ProjectUpdate` with `Decimal` budget and status literal).
- Created `app/repositories/project_repo.py` filtering by `client_id` and `status`.
- Created `app/services/project_service.py` enforcing `PROJECT_CLIENT_INVALID`, `PROJECT_DATE_INVALID`, and `PROJECT_NOT_FOUND`.
- Created `app/routers/projects.py` with full CRUD.

### S01-T09 — Tests

- Added `tests/test_sprint01_flow.py` covering: health, login success/failure, protected route without token, client CRUD + search, project create with valid/invalid client, project date validation, `CLIENT_HAS_PROJECTS` conflict, delete cascade, validation errors, and not-found paths.

### Configuration changes

- Added `email-validator==2.2.0` to `requirements.txt` (required for Pydantic `EmailStr`).
- Changed `cors_origins` from `List[str]` to `str` in `Settings` with a `cors_origins_list` property, because pydantic-settings 2.x tries to JSON-decode list fields from `.env`.
- Changed admin email in `.env.example` from `admin@construction.local` to `admin@constructionerp.app` because email-validator rejects `.local` as a reserved TLD.
- Disabled SQLAlchemy `echo` (was filling logs with SQL in debug mode).

### Verification

- `python -c "import app.main"` succeeds; `Base.metadata` lists `clients`, `expenses`, `milestones`, `payments`, `projects`, `users` (6 tables).
- `alembic upgrade head` applied `0002_financials` on top of `0001_initial`.
- `pytest tests/` → 10 passed (4 Sprint 01 + 6 Sprint 02): milestone CRUD + complete, payment CRUD + amount validation, expense CRUD + category validation, profitability math (0.75 margin), cascade delete, not-found paths.

## 2026-06-28 (Sprint 02 backend pass)

### S02-T01 — Milestones

- Created `app/models/milestone.py` (UUID PK, FK→projects CASCADE, status CHECK constraint, indexes on project_id + due_date).
- Created `app/schemas/milestone.py` (`MilestoneCreate`/`Read`/`Update` with status literal).
- Created `app/repositories/milestone_repo.py` (list by project_id/status, ordered by due_date).
- Created `app/services/milestone_service.py` (PROJECT_NOT_FOUND validation, `complete()` with transition guard).
- Created `app/routers/milestones.py` (CRUD + `POST /{id}/complete`).

### S02-T02 — Payments

- Created `app/models/payment.py` (UUID PK, FK→projects CASCADE, amount > 0 CHECK, method CHECK, indexes).
- Created `app/schemas/payment.py` (`PaymentCreate`/`Read`/`Update` with `Decimal` gt=0).
- Created `app/repositories/payment_repo.py` (list by project_id, `sum_amount_by_project`).
- Created `app/services/payment_service.py` (amount validation, project existence check).
- Created `app/routers/payments.py` (full CRUD).

### S02-T03 — Expenses

- Created `app/models/expense.py` (UUID PK, FK→projects CASCADE, amount > 0 CHECK, indexes).
- Created `app/schemas/expense.py` (`ExpenseCreate`/`Read`/`Update` with category literal).
- Created `app/repositories/expense_repo.py` (list by project_id/category, `sum_amount_by_project`).
- Created `app/services/expense_service.py` (category validation, project existence check).
- Created `app/routers/expenses.py` (full CRUD).

### S02-T04 — Profitability

- Created `app/schemas/profitability.py` (`ProjectProfitabilityResponse` with total_payments, total_expenses, balance, profit_margin).
- Created `app/services/profitability_service.py` (sums via repos, balance = payments - expenses, margin = balance/payments quantized to 0.01, 0 when no payments).
- Added `GET /api/v1/projects/{id}/profitability` to the projects router.

### Migration

- Created `alembic/versions/0002_financials.py`: milestones, payments, expenses tables with FK CASCADE, CHECK constraints, and indexes. Downgrade drops in reverse order.

## 2026-07-22 (Phase 01 — Baseline and Contracts)

### Phase 01 Completed

- Created `backend/tests/test_baseline_contracts.py` with 17 contract tests verifying:
  - Dashboard `outstanding_balances` is total net (R-023).
  - Dashboard `total_clients` includes archived clients (R-024).
  - Dashboard `projects_overview` balance formula and cartesian product defect (R-013).
  - Dashboard finance timeline months and missing-months defect (R-022).
  - Report `project_status` progress_pct, balance, and zero-milestone guard.
  - Report `project_status` uses subqueries (no cartesian product, unlike dashboard).
  - Profitability margin is ratio not percentage (R-025) and zero-payments guard.
  - Client delete restriction (CLIENT_HAS_PROJECTS 409).
  - Client archive behavior.
  - Project delete cascade to milestones, payments, expenses.
  - Expense analysis percentage formula and zero-total guard.
- No backend production source code was modified.
- `python -m pytest tests/test_baseline_contracts.py -v` → 17 passed.