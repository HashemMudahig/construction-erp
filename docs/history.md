# Project History

## Why the project started
The Construction ERP began as a need to replace fragmented spreadsheets, manual reporting, and scattered client/project tracking used by small construction companies.

## Initial idea
Build a modern ERP that centralizes clients, project delivery, finance, and reporting in a single platform with real-time visibility.

## Decisions made
- Backend-first implementation to establish stable data models and APIs.
- Feature-first architecture to build modules incrementally and keep scope manageable.
- Clean architecture to enforce separation between domain rules, data access, and presentation.
- Intentionally simple v1: a single administrative user, no multi-tenant or RBAC complexity.
- Money and budget values use `Decimal`/`Numeric`. Never `float`.
- Alembic migrations are the source of truth for schema; never hand-edit production tables.

## Sprint philosophy
Organize work into focused five-sprint iterations that deliver core modules first, then add reporting, exports, and polish. Each sprint has a 16-file developer specification folder under `backend/docs/Sprint_XX_<Name>/` with clear goals, API contracts, backlog tables, and completion criteria.

## Sprint summary
| Sprint | Name | Period | Goal |
| --- | --- | --- | --- |
| S01 | Foundation, Clients & Projects | 2026-07-06 to 2026-07-17 | FastAPI skeleton, PostgreSQL, JWT auth, client + project CRUD + Flutter screens |
| S02 | Financials — Payments, Expenses & Milestones | 2026-07-20 to 2026-07-31 | Milestone/payment/expense CRUD + project profitability service + Flutter screens |
| S03 | Dashboard | 2026-08-03 to 2026-08-14 | KPI summary cards, projects overview, monthly finance charts |
| S04 | Reports & Analysis | 2026-08-17 to 2026-08-28 | Project status, financial summary, expense analysis reports with filters |
| S05 | Files & Export | 2026-08-31 to 2026-09-11 | Project file attachments, CSV report export, PDF-ready project summary |

## 2026-06-28

### Workspace Reorganization

- Reorganized the workspace to mirror the D:\Gold reference structure.
- Created root `agent.md`, `HISTORY.md`, `.agents/`.
- Created per-package `AGENTS.md` and `HISTORY.md` for backend and frontend.
- Added backend infrastructure: `alembic.ini`, `alembic/`, `.env.example`, `.gitignore`, `docker-compose.yml`, `scripts/`, `tests/`.
- Filled the FastAPI skeleton: `core/config.py`, `database.py`, `security.py`, `response.py`, runnable `main.py` with health endpoints.
- Added Flutter feature-first `lib/` skeleton with `pubspec.yaml`, Dio provider, GoRouter, endpoints constants, theme, and feature folders for all 8 features.
- Wrote 80 developer spec files: 16-file folders for all 5 sprints under `backend/docs/Sprint_0X_<Name>/`.
- Retired the thin `docs/sprints/` and `docs/implementation/` summaries into `docs/archive/` since the 16-file sprint folders supersede them.

### Verification

- `python -c "import app.main"` succeeds.
- `pytest tests/test_health.py` passes (2 tests).
- Each sprint folder contains exactly 16 markdown files.