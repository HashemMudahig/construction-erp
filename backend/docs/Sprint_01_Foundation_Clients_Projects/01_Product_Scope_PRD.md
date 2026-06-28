# 01 — Product Scope & PRD

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Sprint Definition

Sprint S01 ("Foundation, Clients & Projects") is the first delivery sprint of the Construction ERP platform. It transforms the project skeleton approved in Sprint 00 into a runnable system: a FastAPI service backed by PostgreSQL, secured by JWT bearer auth for a single administrative user, and a Flutter client that can authenticate and manage clients and projects end to end. The sprint deliberately ships a narrow, vertically complete slice rather than a wide, half-finished surface.

The scope is intentionally small but real: one admin user, two business entities (clients, projects), full CRUD, and the supporting infrastructure (migrations, env config, health checks, tests). Everything built here becomes the contract that later sprints extend.

## 2. Problem Statement

Construction SMEs manage projects and clients through spreadsheets and chat, leading to lost records, inconsistent budgets, and no single source of truth. There is no system of record for who the client is, what the project scope/budget/status is, and who touched what. Sprint S01 establishes that system of record for clients and projects only; later sprints add financials, inventory, and labour.

## 3. Business Objectives

1. Provide a single, authenticated entry point for the admin to record and maintain clients.
2. Link projects to clients with a numeric budget, dates, and a constrained status lifecycle.
3. Make the data durable and auditable (PostgreSQL, migrations, structured logs).
4. Establish the API and UI patterns that every subsequent sprint reuses.

## 4. Functional Requirements

| ID | Requirement | Backlog Task | Acceptance Criteria |
| --- | --- | --- | --- |
| FR-01 | The system exposes a health endpoint returning the standard envelope. | S01-T01 | `GET /api/v1/health` returns `{"success": true, ...}`. |
| FR-02 | The system applies Alembic migrations to create users, clients, projects. | S01-T02 | `alembic upgrade head` runs cleanly on a fresh DB. |
| FR-03 | The system authenticates a single admin via email + password and returns a JWT. | S01-T03 | Valid creds return token; invalid creds return 401 envelope. |
| FR-04 | The system seeds exactly one admin user from env config. | S01-T04 | Seed is idempotent; login works with seeded credentials. |
| FR-05 | The system supports full CRUD for clients with name search. | S01-T05 | Create/read/update/delete/list+search all behave per contract. |
| FR-06 | The system supports full CRUD for projects linked to a valid client. | S01-T06 | Invalid `client_id` returns 400/422; budget stored as Numeric. |
| FR-07 | The Flutter app implements login, shell, client list/form/detail. | S01-T07 | Admin can log in and perform client CRUD from the UI. |
| FR-08 | The Flutter app implements project list/form/detail linked to a client. | S01-T08 | Admin can create/edit projects tied to a client from the UI. |
| FR-09 | Automated tests cover auth and client/project CRUD validation. | S01-T09 | Test report covers login success/failure and CRUD validation. |

## 5. Out of Scope

- Multi-tenant isolation, RBAC, multiple users, or roles beyond the single admin.
- Financial modules: invoices, payments, expenses, payroll.
- Inventory, labour, equipment, vendors, subcontracts.
- Reporting dashboards, charts, exports, audit-log persistence (log only to stdout this sprint).
- Notifications, email, file attachments.
- Mobile-specific packaging beyond the responsive Flutter build.

## 6. Users

There is exactly one user: the **administrator** (the business owner/manager). The admin authenticates with email + password and has full read/write access to every entity in this sprint. No self-service registration, no password reset flow, no profile editing in v1.

## 7. Business Rules

- A project cannot exist without a valid `client_id`.
- A client cannot be deleted while it has linked projects (the API blocks with 409).
- Project budget is monetary: stored and returned as `Numeric(14,2)`; never float.
- Project status is constrained to: `planning`, `active`, `completed`, `on_hold`, `cancelled`.
- `email` on users is unique; client email is optional and not unique.
- Timestamps are UTC.

## 8. Success Metrics

| Metric | Target |
| --- | --- |
| Migrations apply cleanly on fresh DB | 100% |
| Protected endpoints reject missing/invalid token | 100% |
| Client/Project CRUD tests pass | 100% |
| Admin can complete a client→project round trip in Flutter | Yes |
| P0 defects at sprint close | 0 |

## 9. Assumptions & Constraints

- Sprint 00 produced an approved skeleton repo; S01 builds on it.
- Single admin credentials are supplied via environment variables at startup.
- All endpoints are write-protected except login and health.

## 10. References

- Backlog: see `12_Implementation_Roadmap.md`.
- API contract: see `05_API_Contract_OpenAPI.md`.
- Database: see `06_Database_Schema_PostgreSQL.md`.