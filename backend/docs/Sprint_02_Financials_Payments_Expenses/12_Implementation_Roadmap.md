# 12 — Implementation Roadmap — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Sprint Summary

| Field | Value |
| --- | --- |
| Sprint ID | S02 |
| Period | 2026-07-20 → 2026-07-31 |
| Lead | Tech Lead |
| Story points total | **49** |
| Review gate | Sprint review + QA report sign-off |

## 2. Backlog

| ID | Epic/Module | Task | Owner | Priority | SP | Dependency | Acceptance Criteria | Deliverable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S02-T01 | Milestones / Backend | Milestone model + CRUD API linked to project | Backend Developer | Critical | 8 | Sprint 01 | Milestones require valid project_id; CRUD works; due_date validated. | Milestones API |
| S02-T02 | Payments / Backend | Payment model + CRUD API (amount Numeric, method, date) | Backend Developer | Critical | 8 | Sprint 01 | Payments require valid project_id; amount stored as Numeric; CRUD works. | Payments API |
| S02-T03 | Expenses / Backend | Expense model + CRUD API (category, amount, date) | Backend Developer | Critical | 8 | Sprint 01 | Expenses require valid project_id; category required; amount Numeric; CRUD works. | Expenses API |
| S02-T04 | Profitability / Backend | Project profitability service (income − expenses) | Backend Developer | High | 5 | S02-T02, S02-T03 | Service returns total_payments, total_expenses, balance, profit_margin for a project. | Profitability Service |
| S02-T05 | Milestones / Frontend | Flutter milestone list/form screens under project detail | Frontend Developer | High | 5 | S02-T01, Sprint 01 | Admin can add/edit/complete milestones from project detail. | Milestone Screens |
| S02-T06 | Payments / Frontend | Flutter payment list/form screens | Frontend Developer | High | 5 | S02-T02 | Admin can record, list, and edit payments per project. | Payment Screens |
| S02-T07 | Expenses / Frontend | Flutter expense list/form screens | Frontend Developer | High | 5 | S02-T03 | Admin can record, list, and edit expenses per project. | Expense Screens |
| S02-T08 | QA / Tests | Milestone/Payment/Expense endpoint + profitability tests | QA Tester | High | 5 | S02-T01, S02-T02, S02-T03, S02-T04 | Test report covering CRUD validation and profitability math. | QA Report |

## 3. Phases

### Phase 1 — Backend financial models & CRUD (Days 1-6)
S02-T01, S02-T02, S02-T03 in parallel. Each delivers model + Alembic migration + repository + service + router + schemas + unit tests. The single Alembic revision covers all three tables.

### Phase 2 — Profitability service (Day 7-8)
S02-T04 depends on T02/T03 repositories. Implement `ProjectProfitabilityService.calculate_profit`, wire the `/projects/{id}/profitability` endpoint, add profitability unit tests.

### Phase 3 — Frontend financial features (Days 8-11)
S02-T05, S02-T06, S02-T07 in parallel once their backend tasks are stable. Each feature adds data/domain/presentation folders and embeds into the project detail tabs.

### Phase 4 — QA & closure (Days 12-13)
S02-T08 runs the integration suite, executes the QA checklist, and produces the QA report. Sprint review gate is the QA sign-off + demo of the profitability card.

## 4. Critical Path

T01 → T05, T02 → T04 → T06, T03 → T04 → T07, (T04 ∧ T05 ∧ T06 ∧ T07) → T08.

The profitability service (T04) is the convergence point: it requires both payment and expense repositories. The QA report (T08) is the final gate and depends on every prior task.

## 5. Delivery Style

- Trunk-based: small PRs per task, review by Tech Lead.
- Backend tasks ship with their Alembic revision + pytest suite in the same PR.
- Frontend tasks ship feature folders + widget tests.
- Definition of Done per task: code reviewed, tests green, docs updated, demo-able.

## 6. Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Money precision bugs (float misuse) | High | Enforce Decimal end-to-end; add precision unit tests; DB CHECK. |
| Orphan records on project delete | High | project_id existence check + ON DELETE CASCADE + integration test. |
| Profitability drift vs stored value | Medium | ADR-S02-02: compute on demand, never store balance. |
| Scope creep into reporting/dashboard | Medium | Out-of-scope list in PRD; defer to S03/S04. |
| Alembic migration conflicts | Low | Single coordinated revision; run `upgrade head` in CI. |

## 7. Definition of Done (Sprint)

1. All 8 backlog tasks closed (49 SP delivered).
2. Alembic migration applied; DB has 6 tables.
3. 16 endpoints live and documented in OpenAPI.
4. Flutter project detail shows Milestones/Payments/Expenses tabs + Profitability card.
5. QA report approved; unit + integration suites green; coverage ≥ 90% on new services.