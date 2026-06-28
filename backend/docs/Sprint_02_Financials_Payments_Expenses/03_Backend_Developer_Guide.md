# 03 — Backend Developer Guide — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. New Models

### 1.1 Milestone — `app/models/milestone.py`

| Field | Type | Notes |
| --- | --- | --- |
| id | UUID PK | `gen_random_uuid()` |
| project_id | UUID FK → projects | `ON DELETE CASCADE`, not null |
| title | String(255) | not null |
| description | Text | nullable |
| due_date | Date | not null |
| status | Enum(String) | `pending`, `in_progress`, `completed`, `overdue` |
| created_at | DateTime(timezone=True) | server default `now()` |

### 1.2 Payment — `app/models/payment.py`

| Field | Type | Notes |
| --- | --- | --- |
| id | UUID PK | `gen_random_uuid()` |
| project_id | UUID FK → projects | `ON DELETE CASCADE`, not null |
| amount | Numeric(14,2) | not null, > 0 |
| payment_date | Date | not null |
| method | Enum(String) | `cash`, `bank_transfer`, `cheque`, `other` |
| notes | Text | nullable |
| created_at | DateTime(timezone=True) | server default `now()` |

### 1.3 Expense — `app/models/expense.py`

| Field | Type | Notes |
| --- | --- | --- |
| id | UUID PK | `gen_random_uuid()` |
| project_id | UUID FK → projects | `ON DELETE CASCADE`, not null |
| category | String(100) | not null (materials, labor, equipment, permits, other) |
| amount | Numeric(14,2) | not null, > 0 |
| expense_date | Date | not null |
| notes | Text | nullable |
| created_at | DateTime(timezone=True) | server default `now()` |

## 2. Schemas (Pydantic v2)

```python
# app/schemas/milestone.py
class MilestoneCreate(BaseModel):
    project_id: UUID
    title: constr(max_length=255)
    description: str | None = None
    due_date: date
    status: Literal["pending","in_progress","completed","overdue"] = "pending"

class MilestoneRead(BaseModel):
    id: UUID; project_id: UUID; title: str; description: str | None
    due_date: date; status: str; created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class MilestoneUpdate(BaseModel):
    title: str | None = None; description: str | None = None
    due_date: date | None = None; status: str | None = None

# app/schemas/payment.py
class PaymentCreate(BaseModel):
    project_id: UUID
    amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)
    payment_date: date
    method: Literal["cash","bank_transfer","cheque","other"]
    notes: str | None = None
class PaymentRead(BaseModel): ...  # mirrors PaymentCreate + id, created_at
class PaymentUpdate(BaseModel):
    amount: Decimal | None = Field(default=None, gt=0, max_digits=14, decimal_places=2)
    payment_date: date | None = None
    method: Literal[...] | None = None
    notes: str | None = None

# app/schemas/expense.py  (same shape, with category + expense_date)

# app/schemas/profitability.py
class ProjectProfitabilityResponse(BaseModel):
    project_id: UUID
    total_payments: Decimal
    total_expenses: Decimal
    balance: Decimal            # total_payments - total_expenses
    profit_margin: Decimal      # balance / total_payments (0 if total_payments == 0)
```

## 3. Repositories

Each repository (`milestone_repository.py`, `payment_repository.py`, `expense_repository.py`) exposes: `create`, `get_by_id`, `list(filters, page, size)`, `update`, `delete`, and `sum_amount_by_project(project_id)`. List endpoints accept `project_id` optional filter and pagination (`page`, `size`).

## 4. Services

```python
# app/services/project_profitability_service.py
def calculate_profit(project_id: UUID, session: Session) -> ProjectProfitabilityResponse:
    project = session.get(Project, project_id) or raise NotFound(PROJECT_NOT_FOUND)
    total_payments = payment_repo.sum_amount_by_project(project_id)  # Decimal
    total_expenses = expense_repo.sum_amount_by_project(project_id)  # Decimal
    balance = total_payments - total_expenses
    profit_margin = (balance / total_payments) if total_payments > 0 else Decimal("0")
    return ProjectProfitabilityResponse(project_id, total_payments, total_expenses,
                                        balance, profit_margin.quantize(Decimal("0.01")))
```

`MilestoneService.complete_milestone(id)` transitions `pending|in_progress → completed` and refuses invalid transitions. `PaymentService` / `ExpenseService` enforce `amount > 0` and `project_id` existence before delegating to the repository inside a single transaction.

## 5. Routers & Auth

All financial routers use `Depends(get_current_user)` (JWT bearer from Sprint 01). Routers are thin: validate the path/body, call the service, wrap with `success_response(data)` / `error_response(...)`.

## 6. Endpoint List

| Method | Path | Task |
| --- | --- | --- |
| GET | `/api/v1/milestones` | S02-T01 |
| POST | `/api/v1/milestones` | S02-T01 |
| GET/PUT/DELETE | `/api/v1/milestones/{id}` | S02-T01 |
| GET | `/api/v1/payments` | S02-T02 |
| POST | `/api/v1/payments` | S02-T02 |
| GET/PUT/DELETE | `/api/v1/payments/{id}` | S02-T02 |
| GET | `/api/v1/expenses` | S02-T02 |
| POST | `/api/v1/expenses` | S02-T03 |
| GET/PUT/DELETE | `/api/v1/expenses/{id}` | S02-T03 |
| GET | `/api/v1/projects/{id}/profitability` | S02-T04 |

## 7. Validation Rules

- `amount > 0` (Pydantic `Field(gt=0)` + service re-check).
- `project_id` must exist → else `PROJECT_NOT_FOUND` (404).
- `method` ∈ {cash, bank_transfer, cheque, other}; `category` ∈ {materials, labor, equipment, permits, other}; `status` ∈ the milestone enum.
- `due_date`, `payment_date`, `expense_date` are required `date` values.
- Pagination defaults: `page=1`, `size=20`, `size ≤ 100`.