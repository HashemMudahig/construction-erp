# Sprint 04 — Environment Config

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. No New Required Env Vars

Sprint 04 reads existing data using the existing DB connection and JWT settings. No new mandatory environment variables are introduced.

## 2. Optional New Vars

| Var | Default | Purpose |
| --- | --- | --- |
| `SLOW_REPORT_MS` | `1500` | Threshold to log a slow report warning |
| `MAX_REPORT_RANGE_DAYS` | `366` | Optional soft cap on date span; 0 disables |
| `REPORT_RATE_LIMIT_PER_MIN` | `30` | Optional light rate limit per token (0 disables) |

These are read through the existing `Settings` (`app/core/config.py`). Add them with sensible defaults so the app runs unchanged.

```python
class Settings(BaseSettings):
    ...
    slow_report_ms: int = 1500
    max_report_range_days: int = 366
    report_rate_limit_per_min: int = 30
```

## 3. Database

- No new tables; no migration required for schema.
- A migration **may** be added to create indexes if absent (see `06_Database_Schema_PostgreSQL.md` §4). Verify in dev before applying.

```bash
alembic upgrade head
```

## 4. Index Readiness Check

Before sprint demo, confirm indexes exist:

```sql
SELECT indexname FROM pg_indexes
WHERE tablename IN ('payments','expenses','projects')
  AND indexname LIKE 'idx_%';
```

If missing, apply the index migration.

## 5. Date Handling

- DB stores `payment_date` / `expense_date` as `date` (UTC-aware semantics).
- API accepts `YYYY-MM-DD` only (no time, no tz).
- Frontend sends local date picked by user; interpret as-is (no tz shift).

## 6. Max Date-Range Guard

When `MAX_REPORT_RANGE_DAYS > 0`, the service validates:
```python
if start_date and end_date:
    span = (end_date - start_date).days
    if span > settings.max_report_range_days:
        raise ApiError("REPORT_RANGE_TOO_LARGE", f"Range exceeds {settings.max_report_range_days} days")
```

Set to `0` to disable. Keep default at ~1 year to protect typical usage.

## 7. Logging

- Ensure log level configurable via existing `LOG_LEVEL`.
- `DEBUG` prints full SQL (dev only).

## 8. Frontend

- No new env vars on the Flutter side.
- `endpoints.dart` gets three new path constants (no base URL change).
- Dio baseURL already configured via `API_BASE_URL`.

## 9. Deployment Notes

- Reports reuse the same FastAPI process / Postgres connection pool.
- No additional services or containers needed.
- Confirm pool size handles concurrent report queries (default pool adequate for single admin).