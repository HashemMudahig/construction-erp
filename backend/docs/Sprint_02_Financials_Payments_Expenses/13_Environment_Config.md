# 13 — Environment Configuration — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Environment Variables

Sprint S02 introduces **no new environment variables**. The application continues to use the Sprint 01 configuration (`app/core/config.py`):

| Variable | Purpose | Default |
| --- | --- | --- |
| `DATABASE_URL` | PostgreSQL DSN | `postgresql+psycopg://erp:erp@localhost:5432/erp` |
| `JWT_SECRET` | JWT signing key | *(required, no default)* |
| `JWT_ALGORITHM` | JWT algorithm | `HS256` |
| `JWT_EXP_MINUTES` | Token lifetime | `60` |
| `ADMIN_EMAIL` | Seed admin email | `admin@erp.local` |
| `ADMIN_PASSWORD` | Seed admin password | *(required)* |
| `API_PREFIX` | Route prefix | `/api/v1` |

No financial-specific toggles, feature flags, or currency settings are added in v1.

## 2. Database State After Sprint S02

The PostgreSQL schema grows from **3 tables** (Sprint 01: `users`, `clients`, `projects`) to **6 tables**:

| # | Table | Sprint |
| --- | --- | --- |
| 1 | users | S01 |
| 2 | clients | S01 |
| 3 | projects | S01 |
| 4 | milestones | S02 |
| 5 | payments | S02 |
| 6 | expenses | S02 |

No existing Sprint 01 table is altered (no new columns on `projects`, no balance column). The new tables only add FKs pointing to `projects(id)` with `ON DELETE CASCADE`.

## 3. Migration Step

A single Alembic revision is created on top of the Sprint 01 head:

```bash
# from backend/
alembic revision -m "s02_milestones_payments_expenses"
# implement upgrade() / downgrade() per 06_Database_Schema_PostgreSQL.md
alembic upgrade head
```

After `upgrade head`:
- `alembic current` shows the new S02 revision.
- `milestones`, `payments`, `expenses` tables exist with their indexes and CHECK constraints.
- Existing projects from Sprint 01 are immediately eligible to receive financial records.

## 4. Seed Data

The seed routine is unchanged from Sprint 01:
- One admin user (`ADMIN_EMAIL` / `ADMIN_PASSWORD`, bcrypt-hashed).
- No financial seed data is required for v1; the admin creates milestones, payments, and expenses through the UI.

Optional dev-only seed (disabled in production): a sample project with one payment and one expense so the profitability card is non-empty on first load. This is gated behind a `SEED_SAMPLE_DATA=false` flag.

## 5. Backend Start

```bash
# from backend/
. .venv/bin/activate        # or venv\Scripts\Activate.ps1 on Windows
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
# health check
curl http://localhost:8000/api/v1/health
```

## 6. Frontend Start

```bash
# from frontend/
flutter pub get
flutter run -d chrome
# login with ADMIN_EMAIL / ADMIN_PASSWORD
```

## 7. CI/CD Notes

- CI pipeline runs `alembic upgrade head` against a fresh ephemeral Postgres before the pytest suite.
- The S02 migration must be applied in staging before the frontend build is promoted.
- Rollback (`alembic downgrade -1`) drops the three S02 tables cleanly; Sprint 01 data is untouched.