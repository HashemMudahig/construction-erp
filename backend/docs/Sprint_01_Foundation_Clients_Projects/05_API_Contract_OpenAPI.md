# 05 — API Contract (OpenAPI)

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Conventions

- Base URL: `https://<host>/api/v1`.
- Auth: `Authorization: Bearer <jwt>` on all endpoints except `POST /auth/login` and health.
- Pagination: query params `skip` (default 0) and `limit` (default 20, max 100).
- Money: `budget` is a string-encoded decimal in JSON (e.g. `"15000.00"`) to preserve precision.

## 2. Standard Envelope

```json
{ "success": true,  "message": "ok",  "data": <T> }
{ "success": false, "message": "Validation error", "errors": [ {"code":"VALIDATION_ERROR","field":"name","detail":"must not be empty"} ] }
```

## 3. Endpoints

### 3.1 POST /auth/login
- Auth: none
- Request: `LoginRequest { email: string, password: string }`
- Responses: 200 → `TokenResponse { access_token, token_type: "bearer" }`; 401 → `AUTH_INVALID_CREDENTIALS`.

Request example:
```json
{ "email": "admin@example.com", "password": "S3cret!" }
```
Response example:
```json
{ "success": true, "message": "Login successful",
  "data": { "access_token": "eyJhbGciOi...", "token_type": "bearer" } }
```

### 3.2 GET /clients
- Auth: yes
- Query: `search` (string, optional), `skip`, `limit`
- 200 → `[ClientRead]`

### 3.3 POST /clients
- Auth: yes
- Request: `ClientCreate`
```json
{ "name": "Acme Builders", "phone": "+971501234567", "email": "acme@x.com", "address": "Dubai", "notes": "VIP", "archived": false }
```
- 201 → `ClientRead`; 400/422 → `VALIDATION_ERROR`.

### 3.4 GET /clients/{id}
- 200 → `ClientRead`; 404 → `CLIENT_NOT_FOUND`.

### 3.5 PUT /clients/{id}
- Request: `ClientUpdate` (all fields optional)
- 200 → `ClientRead`; 404 → `CLIENT_NOT_FOUND`.

### 3.6 DELETE /clients/{id}
- 200 → `{ "id": "uuid" }`; 404 → `CLIENT_NOT_FOUND`; 409 → `CLIENT_HAS_PROJECTS`.

### 3.7 GET /projects
- Auth: yes
- Query: `client_id` (uuid, optional), `status` (enum, optional), `skip`, `limit`
- 200 → `[ProjectRead]`

### 3.8 POST /projects
- Request: `ProjectCreate`
```json
{ "client_id": "8f1a...-...-...", "name": "Tower A", "description": "Shell & core",
  "budget": "1500000.00", "start_date": "2026-08-01", "end_date": "2027-06-30", "status": "planning" }
```
- 201 → `ProjectRead`; 400 → `PROJECT_CLIENT_INVALID`; 422 → `VALIDATION_ERROR`.

### 3.9 GET /projects/{id}
- 200 → `ProjectRead`; 404 → `PROJECT_NOT_FOUND`.

### 3.10 PUT /projects/{id}
- Request: `ProjectUpdate` (optional fields)
- 200 → `ProjectRead`; 404 → `PROJECT_NOT_FOUND`; 400 → `PROJECT_CLIENT_INVALID`.

### 3.11 DELETE /projects/{id}
- 200 → `{ "id": "uuid" }`; 404 → `PROJECT_NOT_FOUND`.

## 4. Schemas

### ClientRead
```json
{ "id": "uuid", "name": "str", "phone": "str|null", "email": "str|null",
  "address": "str|null", "notes": "str|null", "archived": false,
  "created_at": "2026-07-10T08:00:00Z", "updated_at": "2026-07-10T08:00:00Z" }
```

### ProjectRead
```json
{ "id": "uuid", "client_id": "uuid", "name": "str", "description": "str|null",
  "budget": "1500000.00", "start_date": "2026-08-01", "end_date": "2027-06-30",
  "status": "planning", "created_at": "2026-07-10T08:00:00Z" }
```

## 5. Status Code Matrix

| Code | Meaning | Example code |
| --- | --- | --- |
| 200 | OK | — |
| 201 | Created | — |
| 400 | Business rule violation | `PROJECT_CLIENT_INVALID`, `CLIENT_HAS_PROJECTS` |
| 401 | Unauthenticated | `AUTH_INVALID_CREDENTIALS`, `AUTH_TOKEN_MISSING` |
| 403 | Forbidden (future) | n/a in v1 |
| 404 | Not found | `CLIENT_NOT_FOUND`, `PROJECT_NOT_FOUND` |
| 409 | Conflict | `CLIENT_HAS_PROJECTS` |
| 422 | Validation | `VALIDATION_ERROR` |
| 500 | Server error | `INTERNAL_ERROR` |