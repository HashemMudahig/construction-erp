# 01 — Product Scope & PRD (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Sprint Definition
Sprint 03 delivers the **management dashboard** for the Construction ERP — the first consolidated view of business status across all clients, projects, and finances. Building on the data and CRUD foundations of Sprints 01 and 02, this sprint aggregates existing records into KPIs, overview tables, and cash-flow charts without introducing new persistence tables.

## 2. Problem Statement
After Sprints 01–02, the administrator can manage clients, projects, milestones, payments, and expenses individually, but there is **no consolidated visibility** into the overall state of the business. The admin must open each project to compute balances and has no way to see cash-flow trends. This makes day-to-day decisions slow and error-prone.

## 3. Business Objectives
- **O1 — Real-time overview:** provide an always-current snapshot of active/completed projects, clients, and outstanding balances.
- **O2 — Decision support:** expose a 12-month cash-flow view so the admin can spot income/expense trends.
- **O3 — Operational efficiency:** reduce manual aggregation time to a single screen load (< 2 s on typical data volumes).

## 4. Functional Requirements
The sprint is decomposed into six backlog items, each tied to measurable acceptance criteria.

| ID | Epic/Module | Task | Owner | Priority | SP | Dependency | Acceptance Criteria | Deliverable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S03-T01 | Dashboard / Backend | Summary endpoint (counts, totals, balances) | Backend Developer | Critical | 8 | Sprint 02 | Returns active_projects, completed_projects, total_clients, outstanding_balances, total_payments, total_expenses. | Summary API |
| S03-T02 | Dashboard / Backend | Projects overview endpoint (list with financials) | Backend Developer | High | 5 | Sprint 02 | Returns projects with client name, status, budget, payments_sum, expenses_sum, balance. | Projects Overview API |
| S03-T03 | Dashboard / Backend | Finance overview endpoint (monthly cash flow) | Backend Developer | High | 8 | Sprint 02 | Returns monthly income (payments) and expense totals for the last 12 months. | Finance Overview API |
| S03-T04 | Dashboard / Frontend | Dashboard screen with KPI summary cards | Frontend Developer | Critical | 5 | S03-T01 | Renders active/completed projects, clients, outstanding balances cards. | KPI Cards |
| S03-T05 | Dashboard / Frontend | Projects overview table + finance charts | Frontend Developer | High | 8 | S03-T02, S03-T03 | Renders project health table and monthly cash-flow chart. | Dashboard Widgets |
| S03-T06 | QA / Tests | Dashboard endpoint aggregation tests | QA Tester | High | 3 | S03-T01, S03-T02, S03-T03 | Test report verifying aggregation accuracy. | QA Report |

## 5. Out of Scope
- Detailed per-project financial reports, tax breakdowns, and PDF/Excel export — deferred to **Sprint 04 (Reports)**.
- Multi-currency consolidation (system uses a single currency).
- Role-based dashboard variants (single-admin model; no RBAC).
- Real-time push/WebSocket updates (pull-based refresh only this sprint).
- Forecasting, budgets vs. actuals variance analysis beyond simple balances.

## 6. Users
The system has exactly **one administrative user** (single-tenant, no RBAC). All dashboard endpoints are authenticated via JWT bearer token. There are no per-role dashboard variants.

## 7. Business Rules
- **Read-only:** dashboard endpoints never mutate data; no INSERT/UPDATE/DELETE issued by the dashboard service.
- **UTC consistency:** all monetary aggregations and monthly grouping use UTC timestamps stored on records.
- **Decimal money:** all sums use `Numeric`/`Decimal`; no floating-point arithmetic.
- **Scope:** aggregations span **all** clients and projects owned by the single admin; no tenant filtering needed.
- **Freshness:** data is computed on demand from existing tables (no cached/denormalized summary table in this sprint).

## 8. Success Metrics
| Metric | Target |
| --- | --- |
| Dashboard full load time (summary + projects + finance) | < 2 s on 1 000 projects / 10 000 transactions |
| Aggregation query accuracy | 100% match against seeded fixture values (QA) |
| KPI coverage | 4 summary cards + projects table + 12-month chart delivered |
| Endpoint test coverage | ≥ 90% on dashboard service & router |
| Defects at sprint close | 0 Critical / High open |

## 9. Assumptions
- Sprint 02 models (Client, Project, Milestone, Payment, Expense) and their CRUD APIs are stable.
- PostgreSQL indexes introduced in Sprint 02 suffice for current volumes; additional indexes documented in `06_Database_Schema_PostgreSQL.md`.
- Frontend Riverpod + Dio infrastructure from Sprint 02 is reused.