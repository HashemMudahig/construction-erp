# 02 — System Architecture (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Architecture Overview
Sprint 03 adds a **Dashboard** read module without introducing new persistence. All KPIs, overviews, and charts are computed on demand from the existing `clients`, `projects`, `payments`, and `expenses` tables.

```mermaid
flowchart LR
    subgraph FE[Flutter Frontend]
        UI[Dashboard Screen]
        Prov[DashboardProvider / Riverpod]
        Dio[Dio Client]
    end
    subgraph BE[FastAPI Backend]
        RTR[/api/v1/dashboard/* router]
        SVC[DashboardService]
        REP[DashboardRepository]
    end
    subgraph DB[(PostgreSQL)]
        C[clients]
        P[projects]
        PAY[payments]
        EXP[expenses]
    end
    UI --> Prov --> Dio -->|HTTPS GET| RTR
    RTR --> SVC --> REP
    REP -->|SQL aggregates| C
    REP -->|SQL aggregates| P
    REP -->|SQL aggregates| PAY
    REP -->|SQL aggregates| EXP
```

## 2. Layer Responsibilities
| Layer | Component | Responsibility |
| --- | --- | --- |
| Router | `app/routers/dashboard.py` | 3 GET endpoints, JWT dependency, response envelope |
| Service | `app/services/dashboard_service.py` | Orchestrate aggregations, format Decimal, assemble DTOs |
| Repository | `app/repositories/dashboard_repository.py` | SQLAlchemy aggregate queries (COUNT/SUM/GROUP BY) |
| Schemas | `app/schemas/dashboard.py` | Pydantic v2 response models |
| Models | (unchanged) | Reuse Client/Project/Payment/Expense from Sprint 02 |
| Core | `app/core/security.py` | JWT verification (unchanged) |

## 3. New Module — Dashboard
- Backend: `app/routers/dashboard.py`, `app/services/dashboard_service.py`, `app/repositories/dashboard_repository.py`, `app/schemas/dashboard.py`.
- Frontend: `lib/features/dashboard/{data,domain,presentation}` with a `DashboardProvider`.
- Endpoints registered in `app/main.py` under prefix `/api/v1/dashboard`.
- Frontend routes added via GoRouter (`/dashboard`).

## 4. Read-Model Approach
No new tables. Aggregations are computed live via SQL:
- **Counts:** `SELECT COUNT(*) FROM projects WHERE status = ...`.
- **Sums:** `SELECT COALESCE(SUM(amount),0) FROM payments` / `expenses`.
- **Outstanding balance:** per project `SUM(payments) - SUM(expenses)`, then totalled.
- **Monthly cash flow:** `DATE_TRUNC('month', paid_at)` grouping for last 12 months.

This keeps the source of truth in normalized tables and avoids sync overhead while volumes are moderate.

## 5. ADR — On-Demand Aggregation vs. Denormalized Summary Table
**Decision:** Compute dashboard metrics on demand from existing tables; do not introduce a denormalized summary/materialized view in S03.

**Rationale:**
- Current volumes (< 1 000 projects, < 10 000 transactions) keep aggregation queries well under 200 ms with proper indexes.
- Avoids refresh/sync logic and stale-data risk.
- Simpler Alembic surface (no new migration for tables).

**Consequences:**
- Query performance depends on indexes (see `06_Database_Schema_PostgreSQL.md`).
- If volumes grow > 50 000 transactions, revisit with a materialized view refreshed by a job (deferred).

**Status:** Accepted for S03. Revisit at Sprint 05 planning.

## 6. Component Interactions
1. Flutter `DashboardProvider` fires 3 GET requests in parallel.
2. FastAPI router verifies JWT, delegates to `DashboardService`.
3. Service calls repository methods; repository issues SQLAlchemy aggregate queries.
4. Sums are returned as `Decimal`; service rounds to 2 decimals for display DTOs.
5. Responses wrapped in the standard envelope `{success, message, data}`.

## 7. Non-Functional Requirements
- **Performance:** P95 < 500 ms per endpoint on reference dataset.
- **Security:** JWT required; no mutation endpoints exposed.
- **Observability:** structured logs + `dashboard_load_time` metric (see `09_Logging_Audit_Analytics.md`).
- **Compatibility:** no breaking change to S01/S02 endpoints.