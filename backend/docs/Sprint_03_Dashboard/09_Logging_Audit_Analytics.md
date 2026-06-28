# 09 — Logging, Audit & Analytics (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Logging Strategy
Structured JSON logs via the existing `app.core.logging` setup from Sprint 01. Each dashboard request emits one INFO line at completion.

| Event | Level | Fields |
| --- | --- | --- |
| Request start | DEBUG | method, path, user_id, request_id |
| Request success | INFO | method, path, status, latency_ms, user_id |
| Aggregation slow (> 200 ms) | WARN | endpoint, latency_ms, rows_scanned |
| Aggregation failure | ERROR | endpoint, error_class, message, traceback |
| Auth failure | INFO | reason=auth_token_expired, path |

Example line:
```json
{"ts":"2026-08-10T14:22:01Z","level":"INFO","event":"http.request",
 "method":"GET","path":"/api/v1/dashboard/summary","status":200,
 "latency_ms":48,"user_id":"<uuid>","request_id":"..."}
```

## 2. Slow Query Warnings
The repository times each aggregation query. If elapsed > 200 ms, emit:
```json
{"level":"WARN","event":"dashboard.slow_query","endpoint":"dashboard.finance",
 "latency_ms":312,"rows_scanned":8421,"hint":"review indexes (06_Database_Schema_PostgreSQL.md)"}
```
Threshold is configurable via `settings.dashboard_slow_query_ms`.

## 3. Metrics
Prometheus-style counters/histograms exposed at `/metrics` (already provisioned in S01).

| Metric | Type | Labels | Description |
| --- | --- | --- | --- |
| `dashboard_requests_total` | counter | endpoint, status | total dashboard requests |
| `dashboard_load_time_seconds` | histogram | endpoint | P50/P95/P99 per endpoint |
| `aggregation_query_time_seconds` | histogram | query | per SQL aggregation |
| `dashboard_cache_hits_total` | counter | (reserved) | 0 in S03 (no cache) |

SLO: P95 of `dashboard_load_time_seconds{endpoint="summary"}` < 0.5 s.

## 4. Audit
- The dashboard performs **no mutation**, therefore **no audit records** are written (audit scope per S01 covers CUD operations only).
- Read access is still attributable via request logs (user_id + path + timestamp). This satisfies "who viewed the dashboard" traceability without bloating the audit table.

## 5. Tracing
- OpenTelemetry spans propagated from the router → service → repository.
- Span names: `dashboard.summary`, `dashboard.projects`, `dashboard.finance`; child spans for each SQL aggregation.
- Trace ID injected into log records via `request_id`.

## 6. Frontend Analytics
- The Flutter app emits a `dashboard_viewed` event on successful load (anonymous, internal only):
```dart
Analytics.track('dashboard_viewed', {'latency_ms': stopwatch.elapsedMilliseconds});
```
- Refresh action emits `dashboard_refreshed`.
- No personal data in analytics events.

## 7. Retention
- Application logs: 30 days hot, 90 days cold.
- Metrics: 14 days at 15 s resolution, 1 year at 1 h resolution.
- Audit table: not modified this sprint (read-only module).

## 8. Dashboards / Alerts
| Alert | Trigger | Action |
| --- | --- | --- |
| `DashboardLatencyHigh` | P95 > 1 s for 10 min | page on-call; check indexes |
| `DashboardErrorRateHigh` | 5xx ratio > 2 % for 5 min | page on-call |
| `AggregationSlowQuery` | slow_query log rate > 5/min | investigate query plan |