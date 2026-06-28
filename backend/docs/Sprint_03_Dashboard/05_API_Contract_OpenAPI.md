# 05 — API Contract / OpenAPI (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Common
- Base URL: `/api/v1`
- Auth: `Authorization: Bearer <JWT>` (required on all 3 endpoints)
- Envelope: `{ "success": true, "message": "...", "data": <payload> }`
- Money fields are JSON strings (2-decimal). Dates use `YYYY-MM` strings for monthly series.

## 2. GET /api/v1/dashboard/summary
KPI counts and totals.

**200 OK**
```json
{
  "success": true,
  "message": "dashboard.summary",
  "data": {
    "active_projects": 12,
    "completed_projects": 8,
    "total_clients": 23,
    "outstanding_balances": "125400.00",
    "total_payments": "980000.00",
    "total_expenses": "854600.00"
  }
}
```

| Field | Type | Notes |
| --- | --- | --- |
| active_projects | integer | projects where status = ACTIVE |
| completed_projects | integer | projects where status = COMPLETED |
| total_clients | integer | count of all clients |
| outstanding_balances | string(decimal) | total_payments − total_expenses |
| total_payments | string(decimal) | Σ payments.amount |
| total_expenses | string(decimal) | Σ expenses.amount |

**401** — token missing/expired. **500** — aggregation error.

## 3. GET /api/v1/dashboard/projects
Per-project financial overview.

**200 OK**
```json
{
  "success": true,
  "message": "dashboard.projects",
  "data": [
    {
      "project_id": "6f0c...e1",
      "name": "Riverside Tower",
      "client_name": "Acme Holdings",
      "status": "ACTIVE",
      "budget": "450000.00",
      "payments_sum": "210000.00",
      "expenses_sum": "180000.00",
      "balance": "30000.00"
    }
  ]
}
```

| Field | Type | Notes |
| --- | --- | --- |
| project_id | uuid | PK |
| name | string | project name |
| client_name | string | joined from clients |
| status | enum | ACTIVE / COMPLETED / ON_HOLD / CANCELLED |
| budget | string(decimal) | project budget |
| payments_sum | string(decimal) | Σ payments for project |
| expenses_sum | string(decimal) | Σ expenses for project |
| balance | string(decimal) | payments_sum − expenses_sum |

Returns array (may be empty). Ordered by project name.

## 4. GET /api/v1/dashboard/finance
Monthly cash flow for the last 12 months.

**200 OK**
```json
{
  "success": true,
  "message": "dashboard.finance",
  "data": {
    "currency": "USD",
    "months": [
      { "month": "2025-09", "income": "78000.00", "expense": "61000.00" },
      { "month": "2025-10", "income": "92000.00", "expense": "73000.00" }
    ]
  }
}
```

| Field | Type | Notes |
| --- | --- | --- |
| currency | string | ISO 4217 code |
| months[].month | string | YYYY-MM, chronological |
| months[].income | string(decimal) | Σ payments in month |
| months[].expense | string(decimal) | Σ expenses in month |

Always returns 12 entries (months with no activity return `0.00`). Grouping uses UTC `date_trunc('month', ...)`.

## 5. OpenAPI snippet
```yaml
openapi: 3.1.0
paths:
  /api/v1/dashboard/summary:
    get:
      security: [{ bearerAuth: [] }]
      responses:
        '200': { description: Summary KPIs, content: { application/json: { schema: { $ref: '#/components/schemas/SummaryEnvelope' } } } }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '500': { $ref: '#/components/responses/ServerError' }
  /api/v1/dashboard/projects:
    get:
      security: [{ bearerAuth: [] }]
      responses:
        '200': { description: Projects overview, content: { application/json: { schema: { $ref: '#/components/schemas/ProjectsEnvelope' } } } }
  /api/v1/dashboard/finance:
    get:
      security: [{ bearerAuth: [] }]
      responses:
        '200': { description: Finance overview, content: { application/json: { schema: { $ref: '#/components/schemas/FinanceEnvelope' } } } }
components:
  securitySchemes:
    bearerAuth: { type: http, scheme: bearer, bearerFormat: JWT }
```

## 6. Status code mapping
| Code | Meaning |
| --- | --- |
| 200 | Success |
| 401 | Token missing/expired → `AUTH_TOKEN_EXPIRED` |
| 500 | Aggregation failure → `AGGREGATION_ERROR` / `DASHBOARD_UNAVAILABLE` |