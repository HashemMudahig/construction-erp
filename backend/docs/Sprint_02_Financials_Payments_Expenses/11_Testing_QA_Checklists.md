# 11 — Testing & QA Checklists — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Test Pyramid

| Layer | Tool | Scope |
| --- | --- | --- |
| Unit | pytest | services (profitability math, validation, status transitions) |
| Integration | pytest + TestClient + PG (docker) | repository queries, endpoint flows |
| QA Checklist | manual | end-to-end admin flows in Flutter |

## 2. Unit Tests

### 2.1 Profitability math — `tests/services/test_project_profitability_service.py`
- `test_balance_positive`: total_payments=15000, total_expenses=3200 → balance=11799.50.
- `test_balance_negative`: payments=1000, expenses=3000 → balance=-2000.00.
- `test_margin_zero_payments`: total_payments=0 → profit_margin=0 (no division by zero).
- `test_margin_rounded`: margin quantized to 2 decimals.
- `test_project_not_found`: unknown project_id raises PROJECT_NOT_FOUND.

### 2.2 Validation
- `test_amount_zero_rejected`, `test_amount_negative_rejected`.
- `test_invalid_method_rejected`, `test_invalid_category_rejected`.
- `test_milestone_invalid_transition`: completed → pending refused.

## 3. Integration Tests

### 3.1 Milestone CRUD — `tests/routers/test_milestones.py`
1. POST milestone with valid project_id → 201, row exists.
2. POST with unknown project_id → 404 PROJECT_NOT_FOUND.
3. GET list filtered by project_id returns only that project's milestones.
4. PUT status pending → in_progress → completed (200 each).
5. DELETE → 200, subsequent GET → 404.

### 3.2 Payment CRUD — `tests/routers/test_payments.py`
1. POST with amount 15000.00 → 201.
2. POST with amount 0 → 400 INVALID_AMOUNT.
3. POST with amount -10 → 400 INVALID_AMOUNT.
4. POST with method="paypal" → 400 INVALID_METHOD.
5. PUT update amount → 200, GET reflects new amount.
6. DELETE → 200.

### 3.3 Expense CRUD — `tests/routers/test_expenses.py`
1. POST with category="materials" → 201.
2. POST with category="unknown" → 400 INVALID_CATEGORY.
3. List filter by project_id returns paginated expenses.
4. DELETE orphan check: deleting project cascades to expenses.

### 3.4 Profitability endpoint — `tests/routers/test_profitability.py`
- Seed payments and expenses, assert `balance` and `profit_margin` match Decimal sum.
- Assert 404 for unknown project.

### 3.5 Auth
- All endpoints without `Authorization` header → 401.

## 4. QA Checklist (S02-T08)

- [ ] Admin can add a milestone from project detail and it appears in the list.
- [ ] Milestone status can move pending → in_progress → completed.
- [ ] Overdue milestone shows `overdue` status automatically.
- [ ] Admin can record a payment; profitability card total updates.
- [ ] Zero/negative amount is rejected with a clear message.
- [ ] Invalid method/category dropdown option is rejected.
- [ ] Admin can record an expense; profitability balance decreases.
- [ ] Profitability card shows total payments, total expenses, balance, margin %.
- [ ] Deleting a project removes its milestones, payments, expenses.
- [ ] All financial endpoints require login (401 without token).
- [ ] QA report delivered covering CRUD validation and profitability math.

## 5. Definition of Done (QA gate)

QA signs off only when: unit + integration suites green, coverage on new services ≥ 90%, the checklist above is fully ticked, and the profitability values match a manual Decimal recalculation for at least two seeded projects.