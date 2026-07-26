# Construction ERP Documentation

This documentation system describes a production-grade Construction ERP built with FastAPI, PostgreSQL, SQLAlchemy, Alembic, and a Flutter frontend using Riverpod and GoRouter.

## Purpose

The project provides a unified platform for managing construction clients, projects, financials, and reporting workflows through a clean architecture approach. The system is intentionally simple in v1: a single administrative user, no multi-tenant or RBAC complexity.

## Repository Layout

```
construction-erp/
├── agent.md            # Cross-workspace agent guide (how we work)
├── HISTORY.md          # Running workspace history
├── .agents/
├── backend/
│   ├── AGENTS.md       # Backend agent guidelines
│   ├── HISTORY.md      # Backend history
│   ├── alembic.ini, alembic/
│   ├── docker-compose.yml
│   ├── .env.example, .gitignore
│   ├── scripts/        # run_dev.bat / run_dev.sh
│   ├── tests/
│   ├── requirements.txt
│   ├── app/
│   │   ├── main.py
│   │   ├── core/ (config, database, security, response)
│   │   ├── models/  schemas/  repositories/  services/  routers/
│   │   ├── utils/  db/
│   │   └── tests/
│   └── docs/
│       ├── Sprint_01_Foundation_Clients_Projects/   # 16 developer spec files
│       ├── Sprint_02_Financials_Payments_Expenses/  # 16 developer spec files
│       ├── Sprint_03_Dashboard/                    # 16 developer spec files
│       ├── Sprint_04_Reports_Analysis/             # 16 developer spec files
│       └── Sprint_05_Files_Export/                  # 16 developer spec files
├── frontend/
│   ├── AGENTS.md       # Frontend agent guidelines
│   ├── HISTORY.md      # Frontend history
│   ├── pubspec.yaml, .gitignore
│   └── lib/
│       ├── main.dart
│       ├── core/ (config, constants, network, router, theme)
│       └── features/ (auth, clients, projects, payments, expenses, dashboard, reports, settings)
└── docs/
    ├── README.md       # This file (workspace overview)
    ├── architecture.md, project_overview.md, tech_stack.md, skills.md, history.md
    └── archive/        # Retired thin sprint summaries
```

## High-level modules

- `backend/`: FastAPI API, business logic, persistence, and database migration support.
- `frontend/`: Flutter application built with feature-based and clean architecture patterns.
- `docs/`: Workspace-level documentation. Per-sprint developer specifications live under `backend/docs/Sprint_XX_<Name>/`.

## Per-Sprint Developer Specifications

Each sprint folder under `backend/docs/Sprint_XX_<Name>/` contains the 16 canonical developer docs:

1. Product Scope PRD
2. System Architecture
3. Backend Developer Guide
4. Frontend Developer Guide
5. API Contract (OpenAPI)
6. Database Schema (PostgreSQL)
7. Service Workflows
8. Security and Access Control
9. Logging, Audit, Analytics
10. Error Codes and Response Standards
11. Testing & QA Checklists
12. Implementation Roadmap
13. Environment Config
14. Integration with Core APIs
15. UI/UX Screen Specification
16. Acceptance Criteria

## Where to look first

- New to the project? Read `agent.md` (workspace root) then `backend/AGENTS.md`.
- Implementing a sprint? Open the matching `backend/docs/Sprint_XX_<Name>/` folder, starting with `01_Product_Scope_PRD.md` and `12_Implementation_Roadmap.md`.
- Tracking change history? Read `HISTORY.md` (workspace root) and the per-package `HISTORY.md` files.

## Offline Migration

> **Status: Planned — Implementation has not started.**

The Flutter frontend is planned to become a single-user, single-device, fully offline application using a local SQLite database via the Drift ORM. The FastAPI backend will be preserved as a possible future remote adapter.

- [Offline Migration Documentation](offline_migration/README.md) — Master index and phase list.
- [Migration Overview](offline_migration/00_migration_overview.md) — Business rationale and scope.
- [Target Architecture](offline_migration/architecture_target.md) — Planned local-first architecture.
- [Data Model Mapping](offline_migration/data_model_mapping.md) — Field-level mapping across all storage layers.
- [Decision Log](offline_migration/decision_log.md) — Architecture Decision Records.
- [Risk Register](offline_migration/risk_register.md) — Identified risks and mitigations.

### Documentation Navigation

1. Start with [Offline Migration README](offline_migration/README.md).
2. Read [Migration Overview](offline_migration/00_migration_overview.md).
3. Review [Target Architecture](offline_migration/architecture_target.md) and [Data Model Mapping](offline_migration/data_model_mapping.md).
4. Check [Decision Log](offline_migration/decision_log.md) for approved and proposed decisions.
5. Review [Risk Register](offline_migration/risk_register.md) for identified risks.
6. Follow the phase list in order (Phase 00 through Phase 13).