# 16 — Acceptance Criteria

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Task Acceptance Table

| Task | Feature | Plan criteria | Evidence |
| --- | --- | --- | --- |
| S01-T01 | FastAPI skeleton | Health returns standard envelope | `GET /api/v1/health` body, unit test |
| S01-T02 | PostgreSQL + Alembic | `alembic upgrade head` clean on fresh DB | migration log, three tables present |
| S01-T03 | JWT auth | Protected routes reject missing/invalid token; login returns JWT | pytest auth tests |
| S01-T04 | Seed admin | Exactly one admin; login works with seeded creds | seed script run + login |
| S01-T05 | Clients API | CRUD + search by name; envelope | pytest + Postman/OpenAPI |
| S01-T06 | Projects API | Valid client_id required; budget Numeric | pytest + DB column check |
| S01-T07 | Client screens | Login + list + form + detail in Flutter | demo recording + screenshots |
| S01-T08 | Project screens | Create/edit project linked to client; detail | demo recording + screenshots |
| S01-T09 | QA tests | Report covers login + CRUD validation | `qa_report_s01.md` |

## 2. Given/When/Then Scenarios

### 2.1 Happy path — create project
- **Given** the admin is logged in and a client C exists
- **When** `POST /projects` with valid body `{client_id: C.id, name, budget:"1000.00", status:"planning"}`
- **Then** response 201 with `data.id` and `data.budget == "1000.00"`

### 2.2 Auth failure — missing token
- **Given** no `Authorization` header
- **When** `GET /clients`
- **Then** 401 with `errors[0].code == "AUTH_TOKEN_MISSING"`

### 2.3 Auth failure — expired token
- **Given** a token whose `exp` is in the past
- **When** `GET /clients`
- **Then** 401 with `AUTH_TOKEN_EXPIRED`

### 2.4 Validation failure — empty client name
- **Given** logged in
- **When** `POST /clients` with `{name:""}`
- **Then** 422 with `VALIDATION_ERROR` on `name`

### 2.5 Not found — project
- **Given** logged in
- **When** `GET /projects/{random-uuid}`
- **Then** 404 with `PROJECT_NOT_FOUND`

### 2.6 Business rule — bad client_id
- **Given** logged in
- **When** `POST /projects` with non-existent `client_id`
- **Then** 400 with `PROJECT_CLIENT_INVALID`

### 2.7 Business rule — delete client with projects
- **Given** client C has 1+ projects
- **When** `DELETE /clients/{C.id}`
- **Then** 409 with `CLIENT_HAS_PROJECTS`

### 2.8 Business rule — end_date before start_date
- **Given** logged in
- **When** `POST /projects` with `start_date=2026-08-01, end_date=2026-07-01`
- **Then** 400 with `PROJECT_DATE_INVALID`

### 2.9 Money integrity (accounting — note for this sprint)
> This sprint stores and returns project budget as `Numeric(14,2)`; no invoice/ledger modules yet. The acceptance is: budget round-trips exactly as a decimal string (no float drift). Test asserts `"1000.00" == response.budget`.

### 2.10 Frontend — full round trip
- **Given** app open
- **When** admin logs in, creates a client, creates a project for it, opens project detail
- **Then** all four screens show correct persisted data after refresh

## 3. Security Acceptance

- All write endpoints reject without valid JWT.
- Password never returned; token never logged.
- `.env` not in git; `.env.example` matches real keys.
- CORS limited to configured origins in prod.

## 4. Operations Acceptance

- `alembic upgrade head` and `alembic downgrade base` both clean.
- `docker compose up -d db` + uvicorn boots the API in < 2 minutes on a fresh machine.
- Logs contain audit events for login + create/update/delete.

## 5. Closure Decision Rule

Sprint is **accepted** when:
1. All Critical tasks (T01-T06) merged and green.
2. T07 and T08 demoed successfully.
3. T09 QA report attached with no P0 defects open.
4. Tech Lead sign-off recorded.

Any P0 defect blocks closure; P1 may close with a documented follow-up ticket for the next sprint.