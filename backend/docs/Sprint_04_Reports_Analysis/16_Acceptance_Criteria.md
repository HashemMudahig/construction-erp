# Sprint 04 — Acceptance Criteria

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Task Acceptance Table

| ID | Task | Priority | SP | Acceptance Criteria | Deliverable |
| --- | --- | --- | --- | --- | --- |
| S04-T01 | Project status report endpoint | Critical | 8 | Returns per-project status, budget, payments, expenses, balance, milestones progress; filterable by status. | Project Status Report API |
| S04-T02 | Financial summary report endpoint | Critical | 8 | Returns income, expenses, net, and per-project totals within a date range. | Financial Summary Report API |
| S04-T03 | Expense analysis report endpoint | High | 5 | Returns expenses grouped by category and project with totals and percentages. | Expense Analysis Report API |
| S04-T04 | Reports screen with selector + filters | High | 8 | Admin can select report type, set date range/project, view results table. | Reports Screen |
| S04-T05 | Report rendering with breakdown tables | Medium | 5 | Each report renders a formatted table with totals; expense analysis shows category pie/bar. | Report Widgets |
| S04-T06 | Report endpoint accuracy + filter tests | High | 3 | Test report verifying filters and aggregation correctness. | QA Report |

## 2. Given/When/Then — Project Status Report Accuracy

**Scenario: project status aggregates match seeded data**
- Given projects P1 (active, budget 500000), P2 (completed, budget 300000) with known payments, expenses, milestones
- When `GET /reports/project-status` is called with a valid JWT
- Then each row returns `budget`, `total_payments`, `total_expenses`, `balance`, `milestone_count`, `completed_milestones`, `progress_pct` matching seeded totals computed by Decimal arithmetic
- And `progress_pct == completed_milestones / milestone_count * 100` (2 dp)

**Scenario: status filter**
- Given mixed-status projects
- When `GET /reports/project-status?status=active`
- Then only rows with `status == "active"` are returned

## 3. Given/When/Then — Financial Summary Date-Range Filter

**Scenario: date range restricts both income and expenses**
- Given payments on 2026-01-15 and 2026-07-10; expenses on 2026-03-01 and 2026-09-05
- When `GET /reports/financial-summary?start_date=2026-01-01&end_date=2026-06-30`
- Then `total_income` sums only the January payment, `total_expenses` sums only the March expense
- And `net == total_income - total_expenses` (Decimal)
- And `per_project` nets are consistent with the same date bounds

**Scenario: invalid range**
- When `GET /reports/financial-summary?start_date=2026-06-30&end_date=2026-01-01`
- Then response is `422` with `errors: ["INVALID_DATE_RANGE"]`

## 4. Given/When/Then — Expense Analysis Category Percentages

**Scenario: category percentages sum to 100**
- Given expenses Materials 150000, Labor 90000, Equipment 60000 (grand total 300000)
- When `GET /reports/expense-analysis` with a valid JWT
- Then `by_category` totals are Materials 150000.00, Labor 90000.00, Equipment 60000.00
- And `percentage` values are 50.00, 30.00, 20.00 respectively
- And percentages sum to 100.00 (±0.01 rounding tolerance)

**Scenario: project filter**
- When `GET /reports/expense-analysis?project_id=P1`
- Then only P1's expenses are included in `grand_total` and `by_category`

**Scenario: empty data**
- Given no expenses in range
- When the endpoint is called
- Then `200` with `grand_total: "0.00"`, `by_category: []` (no division-by-zero error)

## 5. Business Rule Acceptance

| Rule | Given/Then |
| --- | --- |
| Read-only | Calling any report endpoint never mutates any table; DB has no INSERT/UPDATE/DELETE from the reports path |
| Decimal money | All money fields are returned as string Decimal with 2 dp; no float in service math |
| UTC | Date comparisons use UTC; frontend sends `yyyy-MM-dd` |
| JWT required | Request without Bearer token returns `401` |
| Empty = success | Empty filtered result returns `200` with zero totals / empty arrays |

## 6. Frontend Acceptance

- Admin selects report type, date range, and project from the UI and sees the correct table.
- Expense analysis renders a category table + chart whose proportions match the data.
- Loading, empty, and error states all render correctly.
- Money displays with 2 decimals; percentages with 2 decimals.

## 7. Closure Decision Rule

A task is accepted when:
1. Its Given/When/Then scenarios pass in automated tests (where applicable) AND
2. The QA checklist item(s) for that task are signed AND
3. No Severity-1 or Severity-2 defect remains open against it.

The sprint closes when all six tasks are accepted and the demo runs end-to-end without blocking issues.