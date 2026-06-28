# 10 — Error Codes & Response Standards (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Envelope
Success: `{ "success": true, "message": "<code>", "data": <payload> }`
Failure: `{ "success": false, "message": "<human text>", "errors": [ { "code": "...", "message": "...", "field": null } ] }`

## 2. Error Codes
| Code | HTTP | Meaning | Retry? |
| --- | --- | --- | --- |
| `AUTH_TOKEN_EXPIRED` | 401 | JWT missing, malformed, or expired | re-login |
| `AUTH_FORBIDDEN` | 403 | token valid but not admin (future) | no |
| `DASHBOARD_UNAVAILABLE` | 503 | transient infra issue (DB unreachable) | yes, backoff |
| `AGGREGATION_ERROR` | 500 | repository query failed | yes, after fix |
| `RATE_LIMIT_EXCEEDED` | 429 | client over dashboard rate limit | yes, after window |
| `VALIDATION_ERROR` | 422 | (not expected; reserved) | no |

## 3. Status Code Mapping
| Status | When |
| --- | --- |
| 200 | successful aggregation (incl. empty result — zeros/empty array) |
| 401 | JWT invalid → `AUTH_TOKEN_EXPIRED` |
| 429 | rate limit hit → `RATE_LIMIT_EXCEEDED` |
| 500 | unhandled exception in service/repo → `AGGREGATION_ERROR` |
| 503 | DB connection down → `DASHBOARD_UNAVAILABLE` |

## 4. Example Error Envelopes

### 401 — token expired
```json
{
  "success": false,
  "message": "Authentication required.",
  "errors": [
    { "code": "AUTH_TOKEN_EXPIRED", "message": "JWT expired at 2026-08-10T15:00:00Z", "field": null }
  ]
}
```

### 429 — rate limit
```json
{
  "success": false,
  "message": "Too many dashboard requests.",
  "errors": [
    { "code": "RATE_LIMIT_EXCEEDED", "message": "Limit 60/min exceeded; retry after 42s", "field": null }
  ]
}
```

### 500 — aggregation error
```json
{
  "success": false,
  "message": "Failed to compute dashboard aggregations.",
  "errors": [
    { "code": "AGGREGATION_ERROR", "message": "relation payments not reachable", "field": null }
  ]
}
```

### 503 — infra
```json
{
  "success": false,
  "message": "Dashboard temporarily unavailable.",
  "errors": [
    { "code": "DASHBOARD_UNAVAILABLE", "message": "database connection timeout", "field": null }
  ]
}
```

## 5. Empty vs Error
- Empty data is **success** (200), not an error:
  - summary → all counts `0`, all sums `"0.00"`.
  - projects → `data: []`.
  - finance → `months` array still has 12 entries, each `income/expense = "0.00"`.

## 6. Error Mapping in Code
```python
from fastapi import Request
from fastapi.responses import JSONResponse
from app.core.errors import AggregationError, AuthError

@app.exception_handler(AggregationError)
async def agg(req: Request, exc: AggregationError):
    return JSONResponse(status_code=500, content={
        "success": False, "message": "Failed to compute dashboard aggregations.",
        "errors": [{"code": "AGGREGATION_ERROR", "message": str(exc), "field": None}],
    })
```

## 7. Frontend Handling
- `401` → navigate to login, clear token.
- `429` → show toast "Rate limited; retrying in N s", auto-retry after `Retry-After`.
- `500/503` → red error banner with manual **Retry** button.
- Network/timeout → `DASHBOARD_UNAVAILABLE` synthesized client-side.

## 8. Idempotency
All endpoints are GET and inherently idempotent; no idempotency keys required.