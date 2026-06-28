# 16 — Acceptance Criteria — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Task Acceptance Table

| ID | Task | Acceptance Criteria | Deliverable |
| --- | --- | --- | --- |
| S02-T01 | Milestone model + CRUD API | Milestones require valid project_id; CRUD works; due_date validated. | Milestones API |
| S02-T02 | Payment model + CRUD API | Payments require valid project_id; amount stored as Numeric; CRUD works. | Payments API |
| S02-T03 | Expense model + CRUD API | Expenses require valid project_id; category required; amount Numeric; CRUD works. | Expenses API |
| S02-T04 | Project profitability service | Service returns total_payments, total_expenses, balance, profit_margin for a project. | Profitability Service |
| S02-T05 | Flutter milestone screens | Admin can add/edit/complete milestones from project detail. | Milestone Screens |
| S02-T06 | Flutter payment screens | Admin can record, list, and edit payments per project. | Payment Screens |
| S02-T07 | Flutter expense screens | Admin can record, list, and edit expenses per project. | Expense Screens |
| S02-T08 | QA tests | Test report covering CRUD validation and profitability math. | QA Report |

## 2. Given/When/Then — Happy Path: Create Payment

```gherkin
Given an authenticated admin and an existing project P
When the admin POSTs /api/v1/payments with {project_id: P, amount: "15000.00", payment_date: "2026-07-25", method: "bank_transfer"}
Then the response status is 201
And the success envelope data contains the new payment with id, amount "15000.00", method "bank_transfer"
And a row exists in payments where project_id = P and amount = 15000.00
```

## 3. Invalid project_id

```gherkin
Given an authenticated admin
When the admin POSTs /api/v1/payments with project_id = <non-existent uuid>
Then the response status is 404
And the error envelope contains code "PROJECT_NOT_FOUND"
And no row is inserted in payments
```

## 4. Invalid Amount (zero / negative)

```gherkin
Given an authenticated admin and a valid project P
When the admin POSTs /api/v1/payments with amount = 0
Then the response status is 400
And the error envelope contains code "INVALID_AMOUNT"

Given an authenticated admin and a valid project P
When the admin POSTs /api/v1/payments with amount = -50.00
Then the response status is 400
And the error envelope contains code "INVALID_AMOUNT"
And no row is inserted in payments
```

## 5. Milestone Status Transition

```gherkin
Given a milestone M with status "pending"
When the admin PUTs /api/v1/milestones/{M} with status "in_progress"
Then the response status is 200 and status == "in_progress"

Given a milestone M with status "completed"
When the admin PUTs /api/v1/milestones/{M} with status "pending"
Then the response status is 400 with code "INVALID_STATUS" (illegal transition)

Given a milestone M with due_date in the past and status "pending"
When the admin GETs /api/v1/milestones/{M}
Then the returned status is "overdue" (derived, not stored)
```

## 6. Profitability Calculation Correctness

```gherkin
Given project P with payments summing to 15000.00 and expenses summing to 3200.50
When the admin GETs /api/v1/projects/{P}/profitability
Then the response status is 200
And data.total_payments == "15000.00"
And data.total_expenses == "3200.50"
And data.balance == "11799.50"
And data.profit_margin == "0.79"  # 11799.50 / 15000.00 rounded to 2 decimals
```

```gherkin
Given project P with no payments and expenses summing to 1000.00
When the admin GETs /api/v1/projects/{P}/profitability
Then data.total_payments == "0.00", data.balance == "-1000.00", data.profit_margin == "0.00"
```

## 7. Business Rules Acceptance

| Rule | Acceptance |
| --- | --- |
| Money is Decimal | All amounts stored as NUMERIC(14,2); no float column exists. |
| Profitability = payments − expenses | balance equals `SUM(payments) − SUM(expenses)` for every tested project. |
| Always tied to a project | Every create with missing/unknown project_id is rejected (404). |
| Amount > 0 | Zero/negative rejected at schema, service, and DB CHECK. |
| Computed, not stored | No `balance` column on projects; profitability endpoint recomputes each call. |

## 8. Accounting Acceptance

- A manual Decimal recalculation of `SUM(payments) − SUM(expenses)` for two seeded projects must match the API `balance` exactly to the cent.
- Rounding is applied only to `profit_margin` (2 decimals); `total_payments`, `total_expenses`, `balance` are exact Decimal sums.

## 9. Closure Decision Rule

A task is **accepted** only when:
1. All Given/When/Then scenarios above pass in CI.
2. The QA checklist (`11_Testing_QA_Checklists.md` §4) is fully ticked.
3. The deliverable is demo-able in the running app.
4. QA Tester signs the QA report (S02-T08).

The sprint is **closed** when all 8 tasks are accepted and the Definition of Done in `12_Implementation_Roadmap.md` §7 is met.