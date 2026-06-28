# Construction ERP Backend Agent Guidelines

## Project Scope

- This repository is the FastAPI backend for the Construction ERP platform.
- Primary stack: FastAPI, SQLAlchemy 2.x, Alembic, PostgreSQL, Pydantic v2, python-jose, passlib[bcrypt].
- The app entry point is `app/main.py`.
- Versioned APIs are mounted under `/api/v1`.
- The system is intentionally simple: a single administrative user. There is no multi-tenant or RBAC complexity in v1.

## Source of Truth

- Treat `app/` and `alembic/` as the implementation source of truth.
- Treat `docs/Sprint_XX_<Name>/` as the per-sprint developer specification source of truth.
- Treat `HISTORY.md` as the running change log.

## Architecture

- Keep route handlers thin and focused on HTTP concerns.
- Put business logic in `app/services/`.
- Reuse the repository pattern in `app/repositories/` for transactional flows.
- Prefer reusable query logic in repositories instead of duplicating ORM access in routes or services.
- `app/core/` holds config, database session, security, and response helpers.
- `app/utils/` holds shared helpers (dates, money, pagination).

## Database Rules

- SQLAlchemy models live in `app/models/`. One file per entity.
- PostgreSQL is the primary database.
- UUID primary keys use `gen_random_uuid()`, so `pgcrypto` must remain available.
- Prefer Alembic migrations for schema changes. Do not use `Base.metadata.create_all()` outside local setup.
- Keep `app/db/seed.py` idempotent.
- Money and budget values use `Numeric`/`Decimal`. Never `float`.
- Index foreign keys, status fields, and frequently filtered date columns.
- All timestamps are UTC.

## API Conventions

- Keep request and response models in `app/schemas/`.
- This codebase uses synchronous FastAPI endpoints and synchronous SQLAlchemy sessions.
- Register new API routers in `app/main.py`.
- Preserve explicit response models on routes.
- For ORM-backed Pydantic responses, follow the existing `from_attributes` pattern.
- All versioned routes use the `/api/v1` prefix.
- Standard response envelope: `{ "success": bool, "message": str, "data": ... }` or `{ "success": false, "message": str, "errors": [...] }`.
- Health endpoints: `GET /api/v1/health` and `GET /api/v1/health/db`.

## Auth And Middleware

- JWT creation and verification live in `app/core/security.py`.
- Password hashing uses bcrypt via passlib. Never store plain-text passwords.
- A single admin account is seeded by `app/db/seed.py`.
- Protected routes require a valid JWT bearer token.
- There are no roles or per-action permissions in v1. Do not add permission tables unless a future phase explicitly requires it.

## Business Rules

- The system serves one administrative user in v1.
- Clients can be created, updated, archived, and searched.
- Projects are assigned to clients and carry a budget, status, and milestones.
- Payments and expenses are tied to projects.
- Dashboard aggregates active/completed projects, outstanding balances, and financial overview.
- Reports cover project, client, financial, and expense views.
- File attachments are tied to projects.

## Build And Run

- Copy `.env.example` to `.env` before local development.
- Normal local flow:
  - `docker compose up -d postgres`
  - `alembic upgrade head`
  - `python -m app.db.seed`
  - `uvicorn app.main:app --reload`
- Quick-start scripts exist at `scripts/run_dev.bat` and `scripts/run_dev.sh`.

## Change Guidance

- Prefer small, targeted changes that fit the existing service and repository structure.
- Avoid broad refactors unless explicitly requested.
- If a change touches models, also check adjacent schemas, services, and routes for contract drift.
- If a change touches auth, verify login and protected-route access together.
- Update `HISTORY.md` and the relevant `docs/Sprint_XX_<Name>/12_Implementation_Roadmap.md` and `16_Acceptance_Criteria.md` when implementation changes the plan or completion state.