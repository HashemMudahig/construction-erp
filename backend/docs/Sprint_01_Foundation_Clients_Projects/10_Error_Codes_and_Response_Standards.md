# 10 — Error Codes & Response Standards

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Standard Envelope

```json
// success
{ "success": true, "message": "Client created", "data": { "id": "uuid", "name": "..." } }

// error
{ "success": false, "message": "Validation failed", "errors": [
  { "code": "VALIDATION_ERROR", "field": "name", "detail": "String must have at least 1 character" }
] }
```

Every endpoint returns this envelope, including errors. HTTP status reflects the category; the body carries the specifics.

## 2. HTTP Status Mapping

| Status | Meaning | When |
| --- | --- | --- |
| 200 | OK | successful read/update/delete |
| 201 | Created | successful create |
| 400 | Bad Request | business rule violation (not validation) |
| 401 | Unauthorized | missing/invalid/expired token or bad login |
| 403 | Forbidden | reserved for future RBAC; not used in v1 |
| 404 | Not Found | entity not found by id |
| 409 | Conflict | client has linked projects |
| 422 | Unprocessable Entity | Pydantic validation failure |
| 500 | Internal Server Error | unhandled exception |

## 3. Error Code Table

| Code | HTTP | Field | Detail |
| --- | --- | --- | --- |
| `AUTH_INVALID_CREDENTIALS` | 401 | — | Invalid email or password |
| `AUTH_TOKEN_MISSING` | 401 | — | Authorization header absent |
| `AUTH_TOKEN_INVALID` | 401 | — | Token signature invalid |
| `AUTH_TOKEN_EXPIRED` | 401 | — | Token expired |
| `VALIDATION_ERROR` | 422 | <field> | Pydantic field violation |
| `CLIENT_NOT_FOUND` | 404 | id | No client with that id |
| `CLIENT_HAS_PROJECTS` | 409 | id | Cannot delete client with linked projects |
| `PROJECT_NOT_FOUND` | 404 | id | No project with that id |
| `PROJECT_CLIENT_INVALID` | 400 | client_id | Referenced client does not exist |
| `PROJECT_DATE_INVALID` | 400 | end_date | end_date before start_date |
| `INTERNAL_ERROR` | 500 | — | Unexpected server error |

## 4. Example Error Responses

Bad login:
```json
{ "success": false, "message": "Invalid email or password",
  "errors": [ { "code": "AUTH_INVALID_CREDENTIALS", "detail": "Invalid email or password" } ] }
```

Missing token:
```json
{ "success": false, "message": "Authentication required",
  "errors": [ { "code": "AUTH_TOKEN_MISSING", "detail": "Authorization header missing" } ] }
```

Validation error (POST /clients, empty name):
```json
{ "success": false, "message": "Validation failed",
  "errors": [ { "code": "VALIDATION_ERROR", "field": "name", "detail": "String must have at least 1 character" } ] }
```

Project with bad client_id:
```json
{ "success": false, "message": "Referenced client does not exist",
  "errors": [ { "code": "PROJECT_CLIENT_INVALID", "field": "client_id", "detail": "Client <uuid> not found" } ] }
```

Delete client with projects:
```json
{ "success": false, "message": "Client has linked projects",
  "errors": [ { "code": "CLIENT_HAS_PROJECTS", "field": "id", "detail": "3 projects attached" } ] }
```

Not found:
```json
{ "success": false, "message": "Project not found",
  "errors": [ { "code": "PROJECT_NOT_FOUND", "field": "id", "detail": "No project with id <uuid>" } ] }
```

## 5. Mapping Rules

- `AppException(code, http_status, message, field=None, detail=None)` is raised in services.
- A single FastAPI exception handler maps `AppException` → envelope.
- `RequestValidationError` (Pydantic) → 422 with one `VALIDATION_ERROR` entry per field.
- `HTTPException` (fallback) → wrapped in envelope with `INTERNAL_ERROR`.
- Stack traces never included in the response.

## 6. Frontend Handling

`ApiException` carries `success`, `message`, `errors`. The UI maps codes to user-facing text via a local error dictionary keyed by `code`. Unknown codes show `message`.