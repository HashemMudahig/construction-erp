# 07 — Service Workflows — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Create Payment

```mermaid
sequenceDiagram
    participant FL as Flutter
    participant API as FastAPI Router
    participant SVC as PaymentService
    participant REPO as PaymentRepository
    participant DB as PostgreSQL
    FL->>API: POST /api/v1/payments {project_id, amount, method, date}
    API->>SVC: create(dto)
    SVC->>DB: SELECT project WHERE id = project_id
    DB-->>SVC: project or None
    alt no project
        SVC-->>API: raise PROJECT_NOT_FOUND
        API-->>FL: 404 envelope
    else amount <= 0
        SVC-->>API: raise INVALID_AMOUNT
        API-->>FL: 400 envelope
    else
        SVC->>REPO: insert(payment) inside transaction
        REPO->>DB: INSERT INTO payments ...
        DB-->>REPO: row
        REPO-->>SVC: Payment
        SVC-->>API: PaymentRead
        API-->>FL: 201 success envelope
    end
```

**Business rules:** `project_id` must exist; `amount > 0`; `method` ∈ enum; the insert is atomic (single transaction).

## 2. Create Expense

Identical sequence to Create Payment, swapping `ExpenseService` / `ExpenseRepository` / `expenses` table and validating `category` against the allowlist. Same atomic insert, same `PROJECT_NOT_FOUND` / `INVALID_AMOUNT` / `INVALID_CATEGORY` outcomes.

## 3. Complete Milestone (status transition)

```mermaid
sequenceDiagram
    participant FL as Flutter
    participant API as FastAPI Router
    participant SVC as MilestoneService
    participant DB as PostgreSQL
    FL->>API: PUT /api/v1/milestones/{id} {status:"completed"}
    API->>SVC: update(id, dto)
    SVC->>DB: SELECT milestone WHERE id
    DB-->>SVC: milestone
    alt not found
        SVC-->>API: raise MILESTONE_NOT_FOUND
    else current status not in (pending, in_progress)
        SVC-->>API: raise VALIDATION_ERROR (invalid transition)
    else
        SVC->>DB: UPDATE milestones SET status='completed'
        DB-->>SVC: ok
        SVC-->>API: MilestoneRead
        API-->>FL: 200 success envelope
    end
```

**Status machine:** `pending → in_progress → completed`. `overdue` is derived on read when `due_date < today` and `status != completed`. A completed milestone cannot be re-opened (VALIDATION_ERROR).

## 4. Calculate Profitability

```mermaid
sequenceDiagram
    participant FL as Flutter
    participant API as FastAPI Router
    participant SVC as ProjectProfitabilityService
    participant DB as PostgreSQL
    FL->>API: GET /api/v1/projects/{id}/profitability
    API->>SVC: calculate_profit(id)
    SVC->>DB: SELECT project WHERE id
    DB-->>SVC: project or None
    alt no project
        SVC-->>API: raise PROJECT_NOT_FOUND
    else
        SVC->>DB: SELECT SUM(amount) FROM payments WHERE project_id
        DB-->>SVC: total_payments (Decimal)
        SVC->>DB: SELECT SUM(amount) FROM expenses WHERE project_id
        DB-->>SVC: total_expenses (Decimal)
        SVC->>SVC: balance = total_payments - total_expenses
        SVC->>SVC: profit_margin = balance/total_payments if >0 else 0
        SVC-->>API: ProjectProfitabilityResponse
        API-->>FL: 200 success envelope
    end
```

**Business rules:** both `SUM` queries run in one transaction for a consistent snapshot; `profit_margin` is rounded to 2 decimals; result is read-only, no row is mutated.

## 5. Overdue Detection (read-time)

When listing/reading milestones, the service checks `due_date < date.today()` and `status` ∈ {pending, in_progress}; if so, the returned `status` is `overdue` without writing to the DB. This keeps the source of truth intact and avoids background jobs in v1.