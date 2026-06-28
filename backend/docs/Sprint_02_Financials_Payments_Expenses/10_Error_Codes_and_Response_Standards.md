# 10 — Error Codes & Response Standards — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Standard Envelope

All Sprint S02 endpoints use the Sprint 01 envelope:

```json
// success
{ "success": true, "message": "...", "data": <T> }

// error
{ "success": false, "message": "...", "errors": [ { "code": "...", "detail": "..." } ] }
```

## 2. Error Code Registry

| Code | HTTP | Meaning |
| --- | --- | --- |
| `MILESTONE_NOT_FOUND` | 404 | No milestone with given id. |
| `PAYMENT_NOT_FOUND` | 404 | No payment with given id. |
| `EXPENSE_NOT_FOUND` | 404 | No expense with given id. |
| `PROJECT_NOT_FOUND` | 404 | Referenced `project_id` does not exist (used by all financial creates and profitability). |
| `INVALID_AMOUNT` | 400 | amount <= 0 or wrong precision. |
| `INVALID_METHOD` | 400 | payment method not in {cash, bank_transfer, cheque, other}. |
| `INVALID_CATEGORY` | 400 | expense category not in allowlist {materials, labor, equipment, permits, other}. |
| `INVALID_STATUS` | 400 | milestone status not in enum or illegal transition. |
| `VALIDATION_ERROR` | 400 | Generic field validation failure (missing required, bad date, etc.). |
| `UNAUTHORIZED` | 401 | Missing/invalid JWT. |
| `INTERNAL_ERROR` | 500 | Unexpected server failure. |

## 3. Status Code Mapping

| HTTP | When |
| --- | --- |
| 200 | Successful GET, PUT, DELETE. |
| 201 | Successful POST (create). |
| 400 | Any `INVALID_*` or `VALIDATION_ERROR`. |
| 401 | Missing/expired JWT. |
| 404 | `*_NOT_FOUND` or `PROJECT_NOT_FOUND`. |
| 422 | Pydantic could not parse the JSON body into the schema. |
| 500 | Unhandled exception (`INTERNAL_ERROR`). |

## 4. Example Error Envelopes

```json
// 404 PROJECT_NOT_FOUND
{
  "success": false,
  "message": "Project not found",
  "errors": [ { "code": "PROJECT_NOT_FOUND", "detail": "project_id 9c2f... does not exist" } ]
}

// 400 INVALID_AMOUNT
{
  "success": false,
  "message": "Validation failed",
  "errors": [ { "code": "INVALID_AMOUNT", "detail": "amount must be greater than 0" } ]
}

// 400 INVALID_METHOD
{
  "success": false,
  "message": "Validation failed",
  "errors": [ { "code": "INVALID_METHOD", "detail": "method must be one of cash, bank_transfer, cheque, other" } ]
}

// 400 INVALID_CATEGORY
{
  "success": false,
  "message": "Validation failed",
  "errors": [ { "code": "INVALID_CATEGORY", "detail": "category must be one of materials, labor, equipment, permits, other" } ]
}

// 404 MILESTONE_NOT_FOUND
{
  "success": false,
  "message": "Milestone not found",
  "errors": [ { "code": "MILESTONE_NOT_FOUND", "detail": "no milestone with id ..." } ]
}

// 401 UNAUTHORIZED
{
  "success": false,
  "message": "Authentication required",
  "errors": [ { "code": "UNAUTHORIZED", "detail": "missing or invalid bearer token" } ]
}
```

## 5. Multiple-Error Responses

A single request may surface multiple validation errors in `errors[]`, each with its own code, e.g. a payment with both a bad method and a zero amount:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "code": "INVALID_METHOD", "detail": "method must be one of ..." },
    { "code": "INVALID_AMOUNT", "detail": "amount must be greater than 0" }
  ]
}
```

## 6. Frontend Mapping

The Flutter layer maps codes to user-facing messages via a `ErrorCodeMapper`:
- `PROJECT_NOT_FOUND` → "Select a valid project."
- `INVALID_AMOUNT` → "Enter an amount greater than 0."
- `INVALID_METHOD` / `INVALID_CATEGORY` → "Choose a valid option from the list."
- `*_NOT_FOUND` → "Record no longer exists."
- `UNAUTHORIZED` → redirect to login.