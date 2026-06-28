# Sprint 02 Implementation: Payments & Expenses

## 1. Backend implementation details

### Folder structure
- `app/models/`: add payment and expense ORM models.
- `app/schemas/`: add Pydantic request and response schemas for payments and expenses.
- `app/routers/`: add payments and expenses routers.
- `app/services/`: add business logic for payment and expense flows.
- `app/repositories/`: add database operations for payments and expenses.

### Models
- `Payment`: stores amount, date, payment method, status, client and optional project relationship.
- `Expense`: stores amount, category, description, vendor, date, and project relationship.

### Schemas
- `PaymentCreate`, `PaymentRead`, `PaymentUpdate`
- `ExpenseCreate`, `ExpenseRead`, `ExpenseUpdate`

### Routers
- `payments` router for CRUD endpoints.
- `expenses` router for CRUD endpoints.

## 2. API endpoints implemented
- `POST /payments`
- `GET /payments`
- `GET /payments/{payment_id}`
- `PUT /payments/{payment_id}`
- `DELETE /payments/{payment_id}`
- `POST /expenses`
- `GET /expenses`
- `GET /expenses/{expense_id}`
- `PUT /expenses/{expense_id}`
- `DELETE /expenses/{expense_id}`

## 3. Database schema changes
- Add `payments` table with payment date, amount, method, status, client_id, and project_id.
- Add `expenses` table with expense date, amount, category, vendor, description, and project_id.

## 4. Flutter screens
- Payments list and payment entry screen.
- Expenses list and expense entry screen.
- Filters for payment status and expense category.

## 5. Testing notes
- Validate creation and update of payments and expenses.
- Test relational integrity for client/project linkage.
- Test edge cases such as missing project or invalid amounts.

## 6. Completed vs not completed
- Completed: payment and expense backend models and endpoints.
- Not completed: dashboard aggregation, report exports, and file attachments.
