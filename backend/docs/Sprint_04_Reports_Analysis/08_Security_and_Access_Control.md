# Sprint 04 — Security & Access Control

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Authentication

All three report endpoints require a valid JWT bearer token:

```
Authorization: Bearer <jwt>
```

Implementation: `Depends(get_current_admin)` resolves the token, verifies signature/expiry, and injects the `Admin` principal. Missing/invalid token -> `401 Unauthorized` with envelope:

```json
{ "success": false, "message": "Not authenticated", "errors": ["UNAUTHORIZED"] }
```

There is a single admin (no RBAC, no tenants), so the JWT is sufficient authorization for all report reads.

## 2. Read-Only Constraint

- Report endpoints are GET only.
- The reports service and repositories must not expose or call any mutation method.
- No ORM `add`, `update`, `flush`, `commit` in the reports path.
- Database role used by the app may keep full privileges for other modules, but the reports code path is strictly read.

## 3. Input Validation

### 3.1 Date Range

```python
if start_date is not None and end_date is not None and start_date > end_date:
    raise ApiError("INVALID_DATE_RANGE", "start_date cannot be after end_date")
```

Dates parsed as `date`; reject malformed -> `422 VALIDATION_ERROR`.

### 3.2 Project ID

```python
if project_id is not None and not await project_repo.exists(project_id):
    raise ApiError("PROJECT_NOT_FOUND", "Project not found")
```

### 3.3 Status

For project status report, `status` must be one of the allowed enum values; otherwise `422 VALIDATION_ERROR`.

### 3.4 Range Guard

Optional soft cap on span (e.g. 1 year) to prevent unbounded scans. If exceeded return `422` with `REPORT_RANGE_TOO_LARGE` (configurable, see env doc).

## 4. Authorization Boundary

- A single admin sees all data; no per-project scoping.
- No multi-tenant filters; the system has no `tenant_id`.

## 5. CORS

Frontend origin allow-list applied via `CORSMiddleware`. Report endpoints inherit the same policy as the rest of `/api/v1`. No wildcard in production.

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
```

## 6. Transport

- HTTPS required in production.
- JWT never logged.
- Query params (project_id, status, dates) may be logged for diagnostics but contain no secrets.

## 7. Rate Limiting

Reports can be expensive; consider a light per-token rate limit on report endpoints (e.g. 30 req/min) to avoid accidental abuse from a stuck frontend loop. Not required for S04 but noted.

## 8. No Side Effects

Because reports are read-only:
- No audit log writes are created for report generation (see Logging doc — only application logs, not audit records).
- No cache invalidation needed; results are always fresh from DB.