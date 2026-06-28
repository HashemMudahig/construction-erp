# Sprint 04 — Implementation Roadmap

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Summary

| Field | Value |
| --- | --- |
| Sprint ID | S04 |
| Name | Reports & Analysis |
| Period | 2026-08-17 to 2026-08-28 |
| Lead | Tech Lead |
| Total Story Points | 37 |
| Review Gate | Sprint demo + QA sign-off (S04-T06) |

## 2. Backlog

| ID | Epic/Module | Task | Owner | Priority | SP | Dependency | Acceptance Criteria | Deliverable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S04-T01 | Reports / Backend | Project status report endpoint | Backend Developer | Critical | 8 | Sprint 03 | Returns per-project status, budget, payments, expenses, balance, milestones progress; filterable by status. | Project Status Report API |
| S04-T02 | Reports / Backend | Financial summary report endpoint | Backend Developer | Critical | 8 | Sprint 03 | Returns income, expenses, net, and per-project totals within a date range. | Financial Summary Report API |
| S04-T03 | Reports / Backend | Expense analysis report endpoint | Backend Developer | High | 5 | Sprint 03 | Returns expenses grouped by category and project with totals and percentages. | Expense Analysis Report API |
| S04-T04 | Reports / Frontend | Reports screen with selector + filters | Frontend Developer | High | 8 | S04-T01, T02, T03 | Admin can select report type, set date range/project, view results table. | Reports Screen |
| S04-T05 | Reports / Frontend | Report rendering with breakdown tables | Frontend Developer | Medium | 5 | S04-T04 | Each report renders a formatted table with totals; expense analysis shows category pie/bar. | Report Widgets |
| S04-T06 | QA / Tests | Report endpoint accuracy + filter tests | QA Tester | High | 3 | S04-T01, T02, T03 | Test report verifying filters and aggregation correctness. | QA Report |

## 3. Phases

### Phase 1 — Backend (T01–T03), Days 1–6
- Define schemas (`app/schemas/reports.py`).
- Implement `ReportService` with three methods.
- Add aggregation query methods to repositories.
- Wire routers with JWT + validation.
- Backend unit + integration tests.

### Phase 2 — Frontend (T04–T05), Days 5–9 (overlaps once API contract frozen)
- Build `lib/features/reports/` feature module.
- ReportsProvider, filters UI, tables, category chart.
- Widget tests.

### Phase 3 — QA (T06), Days 9–10
- Run full QA checklist against staging.
- Verify filters, aggregations, percentages, empty/error states.
- Sign off QA report.

## 4. Critical Path

```
T01 -> T02 -> T03 -> T04 -> T05 -> T06
```

Backend tasks T01–T03 can be developed in parallel by one backend dev (sequential commits). T04 cannot start until API contract is frozen (after T01–T03 schema review). T06 depends on all three endpoints.

## 5. Delivery Style

- Trunk-based; small PRs per task.
- Each backend task: schema + service + router + tests in one PR.
- Frontend tasks split by widget where useful.
- API contract frozen after T03 merge; frontend consumes stubs until then.

## 6. Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Large date ranges slow | High latency | Indexes on payment_date/expense_date; range guard; warn > 1.5s |
| Timezone in date filters | Wrong rows included | Store/compare UTC; frontend sends date only (no tz) |
| Cartesian join double-counting | Wrong sums | Use subquery aggregation form (see DB doc §3.1) |
| Decimal/float mismatch | Rounding errors | Decimal everywhere; never cast money to float |
| Empty result treated as error | Bad UX | Return 200 with zeros/empty arrays |

## 7. Definition of Done

- Code merged, lint + typecheck green.
- Unit + integration tests pass.
- QA checklist signed.
- API contract doc matches implementation.
- No regressions in Sprints 01–03.
- Sprint demo delivered.