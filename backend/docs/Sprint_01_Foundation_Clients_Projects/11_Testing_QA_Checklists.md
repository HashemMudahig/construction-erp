# 11 — Testing & QA Checklists

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Strategy

- **Unit tests** for services and repositories (pure, DB via in-memory SQLite or PG test container).
- **Integration tests** via FastAPI `TestClient` against a throwaway PostgreSQL schema.
- **Frontend smoke** (manual) covering login and client/project round trip.
- Tests live in `backend/tests/` mirroring the app tree. Run with `pytest -q`.

## 2. Fixtures

- `db_session` — creates schema per test, rolls back at teardown.
- `client` — `TestClient(app)` with dependency overrides for `get_db`.
- `admin_token` — logs in the seeded admin and returns a bearer token.
- `auth_headers` — `{"Authorization": f"Bearer {admin_token}"}`.

## 3. Unit Test Cases

### Auth
| Test | Expected |
| --- | --- |
| `login_success` | 200 + `access_token` present |
| `login_wrong_password` | 401 `AUTH_INVALID_CREDENTIALS` |
| `login_unknown_email` | 401 `AUTH_INVALID_CREDENTIALS` (same message) |
| `login_invalid_email_format` | 422 `VALIDATION_ERROR` |

### Clients
| Test | Expected |
| --- | --- |
| `create_client_ok` | 201 + returned id |
| `create_client_empty_name` | 422 on `name` |
| `list_clients_search` | only matching `ilike` rows returned |
| `get_client_not_found` | 404 `CLIENT_NOT_FOUND` |
| `update_client_partial` | only sent fields change |
| `delete_client_ok` | 200 + id returned |
| `delete_client_with_projects` | 409 `CLIENT_HAS_PROJECTS` |
| `clients_requires_token` | 401 without auth header |

### Projects
| Test | Expected |
| --- | --- |
| `create_project_ok` | 201 |
| `create_project_bad_client` | 400 `PROJECT_CLIENT_INVALID` |
| `create_project_negative_budget` | 422 on `budget` |
| `create_project_bad_status` | 422 on `status` |
| `create_project_end_before_start` | 400 `PROJECT_DATE_INVALID` |
| `list_projects_filter_by_client` | only that client's projects |
| `list_projects_filter_by_status` | only that status |
| `update_project_ok` | 200 |
| `delete_project_ok` | 200 |
| `get_project_not_found` | 404 `PROJECT_NOT_FOUND` |

## 4. Integration Flows

1. **login → create client → create project → list projects filtered by client → delete project → delete client.** Verifies the full happy path with real DB.
2. **login → create project with bad client_id → expect 400.**
3. **no token → GET /clients → 401.**

## 5. Manual QA Scripts (Flutter)

| Step | Expected |
| --- | --- |
| Open app | redirected to /login |
| Wrong password | error banner, stays on /login |
| Correct login | lands on client list |
| Tap + on client list | opens empty client form |
| Submit empty name | inline validation error |
| Submit valid | returns to list with new row |
| Tap row | detail screen with linked projects |
| Add project from detail | project form with client preselected |
| Submit project | detail updates with new project |
| Delete client with project | error toast "client has projects" |

## 6. QA Checklist (sprint closure)

- [ ] `alembic upgrade head` on fresh DB succeeds
- [ ] `alembic downgrade base` succeeds
- [ ] `pytest` green; coverage ≥ 70% on services
- [ ] Health endpoints return envelope
- [ ] All protected routes reject missing token (401)
- [ ] Login returns JWT; expired token rejected
- [ ] Client CRUD + search working
- [ ] Project CRUD + client_id validation working
- [ ] Money displayed and stored as decimal
- [ ] Flutter login + client/project screens work end to end
- [ ] No P0/P1 defects open
- [ ] Logs show audit events
- [ ] `.env.example` complete; `.env` not committed

## 7. Test Report Deliverable

A short markdown `qa_report_s01.md` summarising: environment, test counts, pass/fail, defects found, and the manual QA checklist result. Owned by QA Tester (S01-T09).