# 13 — Environment Configuration (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. No New Environment Variables
Sprint 03 reads only from existing tables and reuses Sprint 01/02 configuration. **No new mandatory env vars** are introduced.

## 2. Reused Settings
| Variable | Purpose | Example |
| --- | --- | --- |
| `DATABASE_URL` | SQLAlchemy connection | `postgresql+psycopg://user:pwd@db:5432/erp` |
| `JWT_SECRET_KEY` | token signing | (from S01) |
| `JWT_ALGORITHM` | HS256 | `HS256` |
| `JWT_ACCESS_TTL_MINUTES` | token TTL | `60` |
| `CORS_ORIGINS` | allowed origins | `https://app.example.com,http://localhost:5432` |

## 3. Optional Tunables (dashboard-specific)
These are **optional** and have safe defaults; add only if tuning is needed.

| Variable | Default | Description |
| --- | --- | --- |
| `DASHBOARD_SLOW_QUERY_MS` | `200` | threshold for slow-query WARN log |
| `DASHBOARD_RATE_LIMIT` | `60/minute` | per-token rate limit |
| `DASHBOARD_FINANCE_MONTHS` | `12` | months returned by finance endpoint |

Add to `app/core/config.py` with defaults so the app starts without them set:
```python
dashboard_slow_query_ms: int = 200
dashboard_rate_limit: str = "60/minute"
dashboard_finance_months: int = 12
```

## 4. Index Migrations (env-agnostic)
The only deployable change is an Alembic migration adding optional indexes (see `06_Database_Schema_PostgreSQL.md` §4). It is idempotent (`CREATE INDEX IF NOT EXISTS`) and safe in all environments.

```bash
alembic upgrade head
```

## 5. Frontend Configuration
- Endpoints already defined in `lib/core/constants/endpoints.dart` (see 04).
- Base URL comes from `lib/core/constants/env.dart` (`API_BASE_URL`) — unchanged.
- No new feature flags.

## 6. Environment Matrix
| Env | DB | Notes |
| --- | --- | --- |
| local | docker-compose Postgres | seed with fixtures |
| CI | ephemeral PG | run aggregation tests |
| staging | managed RDS | verify indexes via `EXPLAIN ANALYZE` |
| prod | managed RDS | enable slow-query log + metrics |

## 7. Pre-flight Checklist
- [ ] `alembic upgrade head` applied
- [ ] indexes verified via `\di` in psql
- [ ] `CORS_ORIGINS` includes the dashboard origin
- [ ] rate limit middleware enabled
- [ ] `/metrics` endpoint reachable
- [ ] seed fixtures loaded on staging for QA

## 8. Rollback
- Drop optional indexes: `alembic downgrade -1`.
- Disable dashboard route by commenting `include_router(dashboard.router)` — no data dependency.
- Frontend: revert GoRouter `/dashboard` entry; no DB effect.