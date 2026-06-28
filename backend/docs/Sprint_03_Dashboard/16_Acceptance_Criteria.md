# 16 — Acceptance Criteria (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Task Acceptance Table
| ID | Epic/Module | Task | Owner | Priority | SP | Dependency | Acceptance Criteria | Deliverable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S03-T01 | Dashboard / Backend | Summary endpoint (counts, totals, balances) | Backend Developer | Critical | 8 | Sprint 02 | Returns active_projects, completed_projects, total_clients, outstanding_balances, total_payments, total_expenses. | Summary API |
| S03-T02 | Dashboard / Backend | Projects overview endpoint (list with financials) | Backend Developer | High | 5 | Sprint 02 | Returns projects with client name, status, budget, payments_sum, expenses_sum, balance. | Projects Overview API |
| S03-T03 | Dashboard / Backend | Finance overview endpoint (monthly cash flow) | Backend Developer | High | 8 | Sprint 02 | Returns monthly income (payments) and expense totals for the last 12 months. | Finance Overview API |
| S03-T04 | Dashboard / Frontend | Dashboard screen with KPI summary cards | Frontend Developer | Critical | 5 | S03-T01 | Renders active/completed projects, clients, outstanding balances cards. | KPI Cards |
| S03-T05 | Dashboard / Frontend | Projects overview table + finance charts | Frontend Developer | High | 8 | S03-T02, S03-T03 | Renders project health table and monthly cash-flow chart. | Dashboard Widgets |
| S03-T06 | QA / Tests | Dashboard endpoint aggregation tests | QA Tester | High | 3 | S03-T01, S03-T02, S03-T03 | Test report verifying aggregation accuracy. | QA Report |

## 2. Given/When/Then — Summary accuracy (S03-T01)
- **Given** seeded data: 3 clients, 4 projects (2 ACTIVE, 1 COMPLETED, 1 ON_HOLD), payments Σ = 1000.00, expenses Σ = 700.00.
- **When** `GET /api/v1/dashboard/summary` with valid JWT.
- **Then** response `data` equals:
```json
{
  "active_projects": 2,
  "completed_projects": 1,
  "total_clients": 3,
  "outstanding_balances": "300.00",
  "total_payments": "1000.00",
  "total_expenses": "700.00"
}
```
- **And** money fields are JSON strings. **And** status 200.

## 3. Given/When/Then — Projects overview correctness (S03-T02)
- **Given** 1 project `Riverside Tower` for `Acme`, budget 450000.00, payments Σ 210000.00, expenses Σ 180000.00.
- **When** `GET /api/v1/dashboard/projects`.
- **Then** `data[0]` has `client_name == "Acme Holdings"`, `status == "ACTIVE"`, `payments_sum == "210000.00"`, `expenses_sum == "180000.00"`, `balance == "30000.00"`.
- **And** array ordered by `name` ascending. **And** empty DB → `data: []`.

## 4. Given/When/Then — Finance monthly grouping (S03-T03)
- **Given** one payment of 100.00 on `2026-07-15T12:00:00Z` and one expense of 40.00 on `2026-07-20T09:00:00Z`.
- **When** `GET /api/v1/dashboard/finance`.
- **Then** `months` has exactly 12 entries; the entry with `month == "2026-07"` has `income == "100.00"` and `expense == "40.00"`; all other entries have `0.00`.
- **And** grouping uses UTC (`date_trunc('month', paid_at)`). **And** `currency == "USD"`.

## 5. Given/When/Then — Frontend KPI cards (S03-T04)
- **Given** summary endpoint returns seeded values above.
- **When** user opens `/dashboard`.
- **Then** four KPI cards render with values `2`, `1`, `3`, `$300.00`; outstanding balance card is green (positive).
- **And** loading shimmer shows before data arrives.

## 6. Given/When/Then — Projects table + chart (S03-T05)
- **Given** projects + finance endpoints return seeded data.
- **When** dashboard renders.
- **Then** table row shows `Riverside Tower | Acme Holdings | ACTIVE | $450,000.00 | $30,000.00`; cash-flow chart has 12 grouped bars; tapping the `2026-07` bar tooltip shows income $100.00 / expense $40.00.

## 7. Given/When/Then — Read-only business rule
- **Given** the dashboard module source code.
- **When** static review (grep) runs on `app/repositories/dashboard_repository.py` and `app/services/dashboard_service.py`.
- **Then** no `INSERT`, `UPDATE`, `DELETE`, `db.commit()`, `db.flush()` calls exist.
- **And** OpenAPI shows only GET paths under `/api/v1/dashboard/*`.

## 8. Given/When/Then — Auth gate
- **Given** no `Authorization` header.
- **When** `GET /api/v1/dashboard/summary`.
- **Then** status 401 with `AUTH_TOKEN_EXPIRED` code.

## 9. Given/When/Then — Empty data
- **Given** truncated DB (no clients/projects/payments/expenses).
- **When** all three endpoints called.
- **Then** summary returns zeros, projects returns `[]`, finance returns 12 months all `0.00` — all status 200.

## 10. QA Report (S03-T06)
- All §2–§9 scenarios green in CI.
- Coverage ≥ 90 % on dashboard module.
- QA checklist (11_Testing_QA_Checklists §6) fully signed.
- Performance: P95 < 500 ms per endpoint on staging with seeded 1 000 projects / 10 000 transactions.

## 11. Closure Decision Rule
Sprint 03 is **accepted** when:
1. All 6 backlog items are Done (DoD met per `12_Implementation_Roadmap.md` §7).
2. §2–§10 acceptance scenarios pass in CI/staging.
3. QA report shows 0 Critical / 0 High defects open.
4. Demo delivered to Tech Lead and approved.

Otherwise the sprint is **not closed**; remaining items roll to a follow-up mini-sprint with re-evaluation of the on-demand aggregation ADR (`02_System_Architecture.md` §5).