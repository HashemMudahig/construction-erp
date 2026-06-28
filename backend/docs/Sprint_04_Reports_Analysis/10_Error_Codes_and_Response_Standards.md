# Sprint 04 — Error Codes & Response Standards

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Standard Envelope

Success:
```json
{ "success": true, "message": "Project status report generated", "data": { ... } }
```

Error:
```json
{ "success": false, "message": "Human-readable message", "errors": ["CODE1", "CODE2"] }
```

`data` is omitted on error. `errors` is an array of machine-readable codes.

## 2. Report Error Codes

| Code | HTTP | Meaning | Trigger |
| --- | --- | --- | --- |
| `UNAUTHORIZED` | 401 | Missing/invalid JWT | No Bearer token, expired/invalid token |
| `VALIDATION_ERROR` | 422 | Generic param validation failure | Malformed UUID, bad date format, unknown status |
| `INVALID_DATE_RANGE` | 422 | start_date > end_date | Date-range validation fails |
| `REPORT_RANGE_TOO_LARGE` | 422 | Date span exceeds configured max | Range guard tripped (optional, env-configurable) |
| `PROJECT_NOT_FOUND` | 404 | project_id does not exist | project_id filter references missing project |
| `REPORT_UNAVAILABLE` | 500/503 | Unexpected failure generating report | DB error, unhandled exception |
| `FORBIDDEN` | 403 | Authenticated but not allowed | Reserved (single admin — not expected to fire) |

## 3. Status Code Mapping

| HTTP | When |
| --- | --- |
| 200 | Report generated (including empty result) |
| 401 | Auth failure |
| 403 | Authorization failure |
| 404 | Referenced project not found |
| 422 | Validation / date range / range too large |
| 500 | Unhandled server error |
| 503 | Dependency (DB) unavailable |

## 4. Validation Order

1. JWT (401 if missing).
2. Param type validation (422 VALIDATION_ERROR on malformed input).
3. Date range check (422 INVALID_DATE_RANGE).
4. Range span guard (422 REPORT_RANGE_TOO_LARGE) — optional.
5. project_id existence (404 PROJECT_NOT_FOUND).
6. Execute aggregation.

This ordering ensures the most specific, actionable error is returned first.

## 5. Example Error Envelopes

### 5.1 Invalid date range
```json
{
  "success": false,
  "message": "start_date cannot be after end_date",
  "errors": ["INVALID_DATE_RANGE"]
}
```

### 5.2 Project not found
```json
{
  "success": false,
  "message": "Project not found",
  "errors": ["PROJECT_NOT_FOUND"]
}
```

### 5.3 Validation error
```json
{
  "success": false,
  "message": "project_id is not a valid UUID",
  "errors": ["VALIDATION_ERROR"]
}
```

### 5.4 Unauthorized
```json
{
  "success": false,
  "message": "Not authenticated",
  "errors": ["UNAUTHORIZED"]
}
```

### 5.5 Report unavailable
```json
{
  "success": false,
  "message": "Unable to generate report; please retry",
  "errors": ["REPORT_UNAVAILABLE"]
}
```

## 6. Empty Results

Empty result is NOT an error. Return `200` with empty arrays / zero totals:
```json
{ "success": true, "message": "Financial summary generated", "data": { "total_income": "0.00", "total_expenses": "0.00", "net": "0.00", "per_project": [] } }
```

## 7. Frontend Handling

The Flutter client inspects `success`. On `false`, read `errors[0]` to map to a user-facing message; on `true`, map `data` to the domain entity. See `14_Integration_With_Core_APIs.md`.