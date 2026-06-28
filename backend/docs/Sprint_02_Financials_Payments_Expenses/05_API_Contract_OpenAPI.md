# 05 — API Contract / OpenAPI — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Conventions

- Base URL: `https://<host>/api/v1`
- Auth: `Authorization: Bearer <jwt>` required on **all** endpoints below.
- Money fields: JSON string or number representing a `Decimal`; backend enforces 2-decimal precision.
- Response envelope (success): `{ "success": true, "message": "...", "data": <T> }`
- Response envelope (error): `{ "success": false, "message": "...", "errors": [ {"code":"...","detail":"..."} ] }`
- Pagination query params on list endpoints: `page` (1-based), `size` (≤100, default 20), `project_id` (optional filter).

## 2. Milestones

### POST /api/v1/milestones
Request body:
```json
{ "project_id": "uuid", "title": "Foundation complete", "description": "...",
  "due_date": "2026-08-15", "status": "pending" }
```
Status codes: `201` (created), `400` (validation), `401` (no token), `404` (PROJECT_NOT_FOUND).

### GET /api/v1/milestones?project_id=<uuid>&page=1&size=20
Response data: `{ "items": [MilestoneRead], "page": 1, "size": 20, "total": 7 }`
Status: `200`, `401`.

### GET /api/v1/milestones/{id} → 200 | 404 (MILESTONE_NOT_FOUND)
### PUT /api/v1/milestones/{id} → 200 | 400 | 404
### DELETE /api/v1/milestones/{id} → 200 | 404

## 3. Payments

### POST /api/v1/payments
```json
{ "project_id": "uuid", "amount": "15000.00", "payment_date": "2026-07-25",
  "method": "bank_transfer", "notes": "First installment" }
```
Status: `201`, `400` (INVALID_AMOUNT / INVALID_METHOD), `404` (PROJECT_NOT_FOUND).

### GET /api/v1/payments?project_id=<uuid>&page=1&size=20
Response: paginated list of `PaymentRead`.
Status: `200`, `401`.

### GET /api/v1/payments/{id} → 200 | 404 (PAYMENT_NOT_FOUND)
### PUT /api/v1/payments/{id} → 200 | 400 | 404
### DELETE /api/v1/payments/{id} → 200 | 404

## 4. Expenses

### POST /api/v1/expenses
```json
{ "project_id": "uuid", "category": "materials", "amount": "3200.50",
  "expense_date": "2026-07-26", "notes": "Cement + rebar" }
```
Status: `201`, `400` (INVALID_AMOUNT / INVALID_CATEGORY), `404` (PROJECT_NOT_FOUND).

### GET /api/v1/expenses?project_id=<uuid>&page=1&size=20
### GET /api/v1/expenses/{id} → 200 | 404 (EXPENSE_NOT_FOUND)
### PUT /api/v1/expenses/{id} → 200 | 400 | 404
### DELETE /api/v1/expenses/{id} → 200 | 404

## 5. Profitability

### GET /api/v1/projects/{id}/profitability
Response data:
```json
{
  "project_id": "uuid",
  "total_payments": "15000.00",
  "total_expenses": "3200.50",
  "balance": "11799.50",
  "profit_margin": "0.79"
}
```
Status: `200`, `401`, `404` (PROJECT_NOT_FOUND).

## 6. Example Error Envelopes

```json
// 400 INVALID_AMOUNT
{ "success": false, "message": "Validation failed",
  "errors": [ { "code": "INVALID_AMOUNT", "detail": "amount must be > 0" } ] }

// 404 PROJECT_NOT_FOUND
{ "success": false, "message": "Project not found",
  "errors": [ { "code": "PROJECT_NOT_FOUND", "detail": "project_id does not exist" } ] }

// 400 INVALID_METHOD
{ "success": false, "message": "Validation failed",
  "errors": [ { "code": "INVALID_METHOD", "detail": "method must be one of cash,bank_transfer,cheque,other" } ] }
```

## 7. Status Code Summary

| Code | Meaning |
| --- | --- |
| 200 | OK (read/update/delete success) |
| 201 | Created (POST) |
| 400 | Validation error (INVALID_*, VALIDATION_ERROR) |
| 401 | Missing/invalid JWT |
| 404 | Resource or referenced project not found |
| 422 | Pydantic body parse error |
| 500 | Unexpected server error |