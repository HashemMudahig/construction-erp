# Sprint 04 — Product Scope & PRD (Reports & Analysis)

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Sprint Definition

Sprint S04 introduces a reporting layer over the data captured in Sprints 01–03 (clients, projects, milestones, payments, expenses). The system gains three read-only report endpoints and a frontend Reports screen with a report type selector, filters, and result rendering. This sprint returns structured JSON only; file export (CSV/PDF) is deferred to S05.

## 2. Problem Statement

After Sprints 01–03, the admin can record and visualize operations through the dashboard, but lacks structured, filterable summaries for decision-making: per-project status, income vs expense over a period, and expense distribution by category. Without these, the admin must manually export or sum data, which is error-prone and slow.

## 3. Business Objectives

- Enable better decision-making through structured, filterable reports.
- Provide per-project status summaries (budget, payments, expenses, balance, milestone progress).
- Provide financial summaries over a configurable date range (income, expenses, net, per-project totals).
- Provide expense analysis by category with totals and percentages.
- Return export-ready structured data so S05 can layer CSV/PDF export on top.

## 4. Functional Requirements

| ID | Task | Acceptance Criteria |
| --- | --- | --- |
| S04-T01 | Project status report endpoint | Returns per-project status, budget, payments, expenses, balance, milestones progress; filterable by status. |
| S04-T02 | Financial summary report endpoint | Returns income, expenses, net, and per-project totals within a date range. |
| S04-T03 | Expense analysis report endpoint | Returns expenses grouped by category and project with totals and percentages. |
| S04-T04 | Reports screen with selector + filters | Admin can select report type, set date range/project, view results table. |
| S04-T05 | Report rendering with breakdown tables | Each report renders a formatted table with totals; expense analysis shows category pie/bar. |
| S04-T06 | Report endpoint accuracy + filter tests | Tests verify filters and aggregation correctness. |

## 5. Out of Scope

- File export (CSV/PDF/Excel) — deferred to Sprint 05.
- Scheduled / emailed reports — deferred.
- Report templating / branding — not in this sprint.
- This sprint returns structured JSON only.

## 6. Users

A single administrative user authenticated via JWT bearer token. No multi-tenant, no RBAC. All report endpoints require a valid token.

## 7. Business Rules

- Reports are read-only; no mutation of any entity.
- Date-range filters are inclusive and validated (start_date <= end_date).
- Money values use `Numeric`/`Decimal`; never float.
- Timestamps are UTC.
- Percentages in expense analysis are computed from Decimal totals.
- Optional filters: project_id, status, start_date, end_date. When omitted, the report covers all applicable records.

## 8. Success Metrics

- All 3 report endpoints return correct aggregations against seeded data (QA pass S04-T06).
- Admin can generate any of the 3 reports from the UI with filters in < 2s for typical ranges.
- Zero regressions in Sprints 01–03 functionality.
- Structured data shape is stable and ready for S05 export consumers.