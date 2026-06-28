# 08 — Security & Access Control (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Authentication
- All three dashboard endpoints require a valid **JWT bearer token** (`Authorization: Bearer <jwt>`).
- Verification is delegated to `app.core.security.get_current_admin`, the same dependency used by Sprint 02 write endpoints.
- No anonymous/public access. No separate "read-only" token type — the single admin token authorizes all actions.

```python
router = APIRouter(dependencies=[Depends(get_current_admin)])
```

## 2. Authorization
- Single-admin model: there is **no RBAC** and no per-user data scoping.
- The admin can view all clients/projects/payments/expenses; the dashboard exposes the same scope as the existing CRUD APIs.
- No tenant filter is applied (single tenant).

## 3. Read-Only Surface
- The dashboard module exposes **only GET** endpoints.
- `DashboardRepository` contains no `add`/`commit`/`flush`/`delete` calls; a code review check must confirm no `db.commit()` path exists in the dashboard module.
- This limits blast radius: even if a token is leaked, the dashboard cannot mutate data.

## 4. Data Exposure
- Aggregated totals (counts, sums, balances) are considered admin-scoped and are safe to return to the authenticated admin.
- No personally identifiable information beyond client names (already visible in Sprint 02 client API).
- No password hashes, tokens, or secrets are surfaced in any DTO.

## 5. Transport & CORS
- HTTPS required in production; HTTP redirected by the reverse proxy.
- CORS allow-list (set in `app.core.config.settings.cors_origins`) is restricted to the Flutter web origin and the desktop app's localhost dev origin. Wildcard `*` is **not** permitted.
- Preflight `OPTIONS` handled by FastAPI middleware; dashboard GET is cacheable only by the browser short-term.

## 6. Rate Limiting
- Apply a per-token rate limit on dashboard endpoints (recommended 60 req/min) to prevent abuse of expensive aggregations.
- Implemented via `slowapi` limiter registered on the router.

## 7. Input Validation
- No path/body parameters on dashboard endpoints; query params are not accepted (no filtering yet).
- Pydantic response models enforce output shape; oversized arrays are not possible (max 12 months, projects count bounded by data).

## 8. Threat Model Summary
| Threat | Mitigation |
| --- | --- |
| Unauthenticated access | JWT dependency on router |
| Token theft | short TTL + HTTPS; no refresh token in URL |
| Data exfiltration | admin-only scope; no extra PII |
| Aggregation DoS | rate limit + indexes (see 06) |
| SQL injection | SQLAlchemy ORM / parameterized queries; no raw string interpolation |

## 9. Audit
- Dashboard reads are **not** written to any audit log (read-only surface; audit scope defined in S01 applies only to mutations).
- Access is still logged at INFO level with endpoint + user id + latency (see `09_Logging_Audit_Analytics.md`).

## 10. Configuration
| Setting | Value |
| --- | --- |
| `jwt_algorithm` | HS256 (from S01) |
| `jwt_access_ttl_minutes` | 60 |
| `cors_origins` | `["https://app.example.com","http://localhost:5432"]` |
| `dashboard_rate_limit` | `60/minute` |