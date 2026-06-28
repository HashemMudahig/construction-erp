# 12 — Implementation Roadmap (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Sprint Summary
| Item | Value |
| --- | --- |
| Sprint ID | S03 |
| Name | Dashboard |
| Period | 2026-08-03 → 2026-08-14 (10 working days) |
| Story points (total) | 37 |
| Lead | Tech Lead |
| Review gate | Sprint demo + QA report sign-off |
| Source | Construction ERP SRS v1.0 |
| Status | Developer Specification |

## 2. Backlog
| ID | Epic/Module | Task | Owner | Priority | SP | Dependency | Acceptance Criteria | Deliverable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S03-T01 | Dashboard / Backend | Summary endpoint (counts, totals, balances) | Backend Developer | Critical | 8 | Sprint 02 | Returns active_projects, completed_projects, total_clients, outstanding_balances, total_payments, total_expenses. | Summary API |
| S03-T02 | Dashboard / Backend | Projects overview endpoint (list with financials) | Backend Developer | High | 5 | Sprint 02 | Returns projects with client name, status, budget, payments_sum, expenses_sum, balance. | Projects Overview API |
| S03-T03 | Dashboard / Backend | Finance overview endpoint (monthly cash flow) | Backend Developer | High | 8 | Sprint 02 | Returns monthly income (payments) and expense totals for the last 12 months. | Finance Overview API |
| S03-T04 | Dashboard / Frontend | Dashboard screen with KPI summary cards | Frontend Developer | Critical | 5 | S03-T01 | Renders active/completed projects, clients, outstanding balances cards. | KPI Cards |
| S03-T05 | Dashboard / Frontend | Projects overview table + finance charts | Frontend Developer | High | 8 | S03-T02, S03-T03 | Renders project health table and monthly cash-flow chart. | Dashboard Widgets |
| S03-T06 | QA / Tests | Dashboard endpoint aggregation tests | QA Tester | High | 3 | S03-T01, S03-T02, S03-T03 | Test report verifying aggregation accuracy. | QA Report |

## 3. Phases
| Phase | Days | Tasks | Output |
| --- | --- | --- | --- |
| Phase 1 — Backend endpoints | D1–D6 | T01, T02, T03 + index migration | 3 endpoints green |
| Phase 2 — Frontend widgets | D5–D11 | T04, T05 (overlap with backend stabilisation) | Dashboard screen |
| Phase 3 — QA & hardening | D10–D14 | T06, perf check, bugfix | QA report |

## 4. Critical Path
T01 → T04 (cards need summary). T02 + T03 → T05 (table + chart). T01+T02+T03 → T06 (QA). Backend endpoints are the gating item; frontend Phase 2 starts on stubbed data D5 while endpoints stabilise.

## 5. Delivery Style
- Trunk-based; small PRs per task; pair review mandatory for service & repository.
- Backend merged first behind feature flags if needed; frontend behind a route guard until QA passes.
- Daily 15 min sync; mid-sprint demo D7; sprint demo D14.

## 6. Risks & Mitigations
| Risk | Impact | Mitigation |
| --- | --- | --- |
| Aggregation performance at scale | slow dashboard | indexes (06), on-demand decision revisited at S05 |
| Timezone drift in monthly grouping | wrong month buckets | UTC `date_trunc` enforced; unit test `test_finance_overview_uses_utc` |
| Decimal precision loss in JSON | rounding errors | serialize money as string; parse with Decimal |
| Frontend chart library size | bundle bloat | evaluate `fl_chart` vs `CustomPaint`; tree-shake |
| Concurrent load on endpoints | DB pressure | rate limit (08) + indexes |

## 7. Definition of Done (per task)
- Code merged to main; CI green (lint + typecheck + tests).
- Endpoint/feature exercised on staging with seeded fixtures.
- Docs updated (this folder + OpenAPI export).
- Acceptance criteria in §2 satisfied and verified by QA.
- No TODO/FIXME left in touched files.

## 8. Sprint Exit
- All 6 backlog items Done.
- QA report (T06) signed with 0 Critical/High open.
- Demo delivered to Tech Lead.
- Retrospective actions captured.