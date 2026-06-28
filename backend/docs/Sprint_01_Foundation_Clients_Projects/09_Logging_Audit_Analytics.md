# 09 — Logging, Audit & Analytics

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Goals

- Observable request flow for debugging.
- Audit trail of auth events and mutations on clients/projects.
- Lightweight metrics for sprint review.
- v1 logs to stdout (and optionally a file); a persistent audit table is planned for a later sprint.

## 2. Logging Library

`structlog` configured with JSON renderer in production, console renderer in dev. Log level from env `LOG_LEVEL` (default `INFO`). Common keys: `event`, `method`, `path`, `status`, `user_email`, `entity`, `entity_id`, `duration_ms`, `request_id`.

## 3. Request Logging

Middleware binds `request_id` (UUID4) and logs:

```
event=request.start method=POST path=/api/v1/clients request_id=...
event=request.end   method=POST path=/api/v1/clients status=201 duration_ms=12 request_id=...
```

Errors are logged at `WARNING` for 4xx and `ERROR` for 5xx with `exc_info=True`.

## 4. Error Logging

Global exception handler catches `AppException` (expected → WARNING) and uncaught `Exception` (→ ERROR + 500 `INTERNAL_ERROR`). Stack traces never returned to the client; they appear only in logs.

## 5. Audit Events (v1)

Logged to stdout with `event=audit.*`. No DB table in S01, but the schema is designed to add `audit_logs` later (id, user_email, action, entity, entity_id, payload jsonb, created_at).

| Event | When | Extra fields |
| --- | --- | --- |
| `audit.auth.login_success` | login OK | `user_email` |
| `audit.auth.login_failed` | login fail | `attempted_email`, reason |
| `audit.client.create` | client created | `entity_id`, `name` |
| `audit.client.update` | client updated | `entity_id`, changed_fields[] |
| `audit.client.delete` | client deleted | `entity_id` |
| `audit.client.delete_blocked` | 409 | `entity_id`, `project_count` |
| `audit.project.create` | project created | `entity_id`, `client_id` |
| `audit.project.update` | project updated | `entity_id`, changed_fields[] |
| `audit.project.delete` | project deleted | `entity_id` |

Passwords and tokens are **never** logged.

## 6. Planned Audit Table (post-S01)

```sql
CREATE TABLE audit_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_email VARCHAR(255),
  action     VARCHAR(60)  NOT NULL,
  entity     VARCHAR(40)  NOT NULL,
  entity_id  UUID,
  payload    JSONB,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
```

## 7. Metrics (collected for sprint review)

| Metric | Type | Source |
| --- | --- | --- |
| `login_success_total` | counter | audit.auth.login_success |
| `login_failed_total`  | counter | audit.auth.login_failed |
| `client_changes_total`| counter | client create/update/delete |
| `project_changes_total`| counter | project create/update/delete |
| `request_duration_ms` | histogram | request.end logs |
| `http_5xx_total`      | counter | error handler |

v1: metrics are derived by parsing logs (simple grep/awk) for the sprint review; a Prometheus exporter is out of scope.

## 8. Log Levels

| Level | Use |
| --- | --- |
| DEBUG | dev only; query SQL |
| INFO | normal ops, audit |
| WARNING | 4xx, expected business errors |
| ERROR | 5xx, unhandled exceptions |

## 9. Frontend Logging

Flutter uses `logging` package; Dio errors are logged at `WARNING` with status + message; no PII (token/password) logged.

## 10. Retention

Container stdout captured by the platform logger (rotated there). File output (if enabled) rotated at 100 MB × 7 files. Audit retention target: 90 days minimum.