# Sprint 04 — API Contract (OpenAPI)

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Common

- Base path: `/api/v1/reports`
- Auth: `Authorization: Bearer <JWT>` (required on all 3 endpoints)
- Response envelope (success): `{"success": true, "message": "...", "data": <report>}`
- Response envelope (error): `{"success": false, "message": "...", "errors": [...]}`
- Money fields: string-encoded Decimal (2 dp), e.g. `"12500.00"`.
- Dates: `YYYY-MM-DD`; inclusive bounds.

## 2. GET /api/v1/reports/project-status

### Query Parameters

| Name | In | Type | Required | Description |
| --- | --- | --- | --- | --- |
| project_id | query | UUID | false | Filter to a single project |
| status | query | string | false | Filter by project status (e.g. `active`, `completed`, `on_hold`) |

### 200 Response — data: `ProjectStatusReportItem[]`

```json
{
  "success": true,
  "message": "Project status report generated",
  "data": [
    {
      "project_id": "11111111-1111-1111-1111-111111111111",
      "name": "Riverside Tower",
      "status": "active",
      "budget": "500000.00",
      "total_payments": "320000.00",
      "total_expenses": "180000.00",
      "balance": "140000.00",
      "milestone_count": 6,
      "completed_milestones": 3,
      "progress_pct": "50.00"
    }
  ]
}
```

### Status Codes

| Code | Meaning |
| --- | --- |
| 200 | Report generated |
| 401 | Missing/invalid JWT |
| 404 | PROJECT_NOT_FOUND (project_id not found) |
| 422 | VALIDATION_ERROR |

## 3. GET /api/v1/reports/financial-summary

### Query Parameters

| Name | In | Type | Required | Description |
| --- | --- | --- | --- | --- |
| start_date | query | date | false | Inclusive lower bound (payment_date / expense_date) |
| end_date | query | date | false | Inclusive upper bound |

### 200 Response — data: `FinancialSummaryReport`

```json
{
  "success": true,
  "message": "Financial summary generated",
  "data": {
    "start_date": "2026-01-01",
    "end_date": "2026-08-31",
    "total_income": "450000.00",
    "total_expenses": "312000.00",
    "net": "138000.00",
    "per_project": [
      {
        "project_id": "11111111-1111-1111-1111-111111111111",
        "name": "Riverside Tower",
        "income": "320000.00",
        "expenses": "180000.00",
        "net": "140000.00"
      }
    ]
  }
}
```

### Status Codes

| Code | Meaning |
| --- | --- |
| 200 | Report generated |
| 401 | Missing/invalid JWT |
| 422 | INVALID_DATE_RANGE (start > end), VALIDATION_ERROR |

## 4. GET /api/v1/reports/expense-analysis

### Query Parameters

| Name | In | Type | Required | Description |
| --- | --- | --- | --- | --- |
| start_date | query | date | false | Inclusive lower bound on expense_date |
| end_date | query | date | false | Inclusive upper bound |
| project_id | query | UUID | false | Filter to a single project |

### 200 Response — data: `ExpenseAnalysisReport`

```json
{
  "success": true,
  "message": "Expense analysis generated",
  "data": {
    "start_date": "2026-01-01",
    "end_date": "2026-08-31",
    "project_id": null,
    "grand_total": "312000.00",
    "by_category": [
      { "category": "Materials", "total": "156000.00", "percentage": "50.00" },
      { "category": "Labor",      "total": "93600.00",  "percentage": "30.00" },
      { "category": "Equipment",   "total": "62400.00",  "percentage": "20.00" }
    ],
    "by_project": [
      {
        "project_id": "11111111-1111-1111-1111-111111111111",
        "name": "Riverside Tower",
        "total": "180000.00",
        "by_category": [
          { "category": "Materials", "total": "90000.00", "percentage": "50.00" }
        ]
      }
    ]
  }
}
```

### Status Codes

| Code | Meaning |
| --- | --- |
| 200 | Report generated |
| 401 | Missing/invalid JWT |
| 404 | PROJECT_NOT_FOUND |
| 422 | INVALID_DATE_RANGE, VALIDATION_ERROR |

## 5. Error Examples

```json
{ "success": false, "message": "start_date cannot be after end_date", "errors": ["INVALID_DATE_RANGE"] }
{ "success": false, "message": "Project not found", "errors": ["PROJECT_NOT_FOUND"] }
{ "success": false, "message": "REPORT_UNAVAILABLE", "errors": ["REPORT_UNAVAILABLE"] }
```