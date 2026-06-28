# 01 — Product Scope (PRD) — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Sprint Definition

Sprint S02 (*Financials — Payments, Expenses & Milestones*) introduces the first financial layer of the Construction ERP. Building on the Sprint 01 foundation (auth, User, Client, Project), this sprint adds three new domain aggregates — **milestones**, **payments**, and **expenses** — each scoped to an existing project, plus a derived **project profitability** service. All financial data is persisted in PostgreSQL and surfaced through FastAPI REST endpoints and Flutter admin screens.

## 2. Problem Statement

After Sprint 01 the system can model administrative users, clients, and projects, but it cannot yet record *any* financial event tied to a project. Specifically:

- There is no way to capture **incoming cash** (client payments) against a project.
- There is no way to capture **outgoing costs** (materials, labor, equipment, permits) against a project.
- There is no way to track project **milestones** (contractual checkpoints) and their lifecycle.
- Consequently, there is no way to compute whether a project is **profitable** at a glance.

Without these capabilities the ERP cannot answer the most basic commercial question for a construction project: *is this project making or losing money?*

## 3. Business Objectives

1. Enable the admin to record every monetary inflow (payment) and outflow (expense) per project.
2. Enable the admin to define and progress milestones per project (pending → in_progress → completed).
3. Provide an always-correct, on-demand profitability computation (payments − expenses) per project.
4. Keep money representation lossless (Decimal/Numeric, never float).
5. Maintain the single-admin, no-RBAC simplicity established in Sprint 01.

## 4. Functional Requirements

| ID | Requirement | Backlog Task |
| --- | --- | --- |
| FR-01 | Admin can create/read/update/delete a milestone for a project, with a due date and status. | S02-T01 |
| FR-02 | Admin can create/read/update/delete a payment for a project, with amount (Numeric), method, date, notes. | S02-T02 |
| FR-03 | Admin can create/read/update/delete an expense for a project, with category, amount (Numeric), date, notes. | S02-T03 |
| FR-04 | System computes project profitability: total_payments, total_expenses, balance, profit_margin. | S02-T04 |
| FR-05 | Admin can manage milestones from the project detail screen in Flutter. | S02-T05 |
| FR-06 | Admin can record, list, and edit payments per project in Flutter. | S02-T06 |
| FR-07 | Admin can record, list, and edit expenses per project in Flutter. | S02-T07 |
| FR-08 | QA confirms CRUD validation and profitability math via automated tests. | S02-T08 |

## 5. Acceptance Criteria Mapping

Each functional requirement inherits its acceptance criteria directly from the Sprint 02 backlog table (see `12_Implementation_Roadmap.md` and `16_Acceptance_Criteria.md`). In summary: a financial record always requires a valid `project_id`; amounts are `Numeric(14,2)` and must be > 0; milestone status follows the enum `pending|in_progress|completed|overdue`; profitability returns the four required fields.

## 6. Out of Scope

The following are intentionally deferred to later sprints and must **not** be built in S02:

- **Reporting & dashboards** (Sprint S03) — no charts, no cross-project rollups, no PDF export.
- **Invoicing & tax/VAT handling** (Sprint S03) — payments are raw inflows, no invoice linkage, no tax lines.
- **Vendor/supplier management** (Sprint S04) — expenses are free-text category, no vendor FK.
- **Multi-currency** — all amounts assumed single currency (project currency).
- **Recurring/automatic payment schedules**.
- **Attachments/receipts upload** for expenses or payments.
- **Approval workflow / RBAC** — single admin, no approvals.

## 7. Users

The system remains a **single-admin** application. The one authenticated user can perform all CRUD operations on milestones, payments, and expenses. There are no roles, no permissions, and no multi-tenant partitioning in v1. JWT bearer auth (from Sprint 01) protects every write endpoint and the read endpoints for financial resources.

## 8. Business Rules

1. **Money is Decimal.** Every amount is stored as PostgreSQL `NUMERIC(14,2)` and modeled in Python as `Decimal`. Floats are prohibited for monetary values.
2. **Payments and expenses are always tied to a project.** A `project_id` is required and must reference an existing project; orphan financial records are rejected.
3. **Profitability is computed, not stored.** `balance = total_payments − total_expenses`; `profit_margin = balance / total_payments` (0 when total_payments is 0). No running balance column is persisted.
4. **Amounts must be positive.** `amount > 0` enforced at schema and service layer.
5. **Milestone status transitions** are constrained to the enum; `overdue` is set by the service when `due_date < today` and status is not `completed`.
6. **Cascade policy:** deleting a project cascades to its financial records (see `06_Database_Schema_PostgreSQL.md`).

## 9. Success Metrics

| Metric | Target |
| --- | --- |
| Financial endpoints implemented & passing | 16 endpoints (3×5 CRUD + profitability) |
| QA test coverage on financial flows | ≥ 90% on new services |
| Profitability computation accuracy | 100% (matches Decimal sum) |
| Flutter screens delivered | 3 features (milestones, payments, expenses) + profitability card |
| Story points completed | 49 / 49 |
| Sprint review gate | All Critical/High tasks closed |