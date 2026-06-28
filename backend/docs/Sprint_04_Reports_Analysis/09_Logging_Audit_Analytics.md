# Sprint 04 — Logging, Audit & Analytics

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Logging Strategy

Reports are read-only, so logging is diagnostic only (no audit trail). Each report request emits a structured log line with context.

### 1.1 Request Log

```json
{
  "event": "report.request",
  "report": "project_status",
  "project_id": "11111111-1111-1111-1111-111111111111",
  "status": "active",
  "start_date": null,
  "end_date": null,
  "admin_id": "admin-uuid"
}
```

### 1.2 Result Log

```json
{
  "event": "report.result",
  "report": "financial_summary",
  "row_count": 12,
  "duration_ms": 87,
  "admin_id": "admin-uuid"
}
```

### 1.3 Slow Query Warning

When `duration_ms > SLOW_REPORT_MS` (default 1500):

```json
{
  "level": "WARN",
  "event": "report.slow",
  "report": "expense_analysis",
  "duration_ms": 2300,
  "filters": {"start_date": "2024-01-01", "end_date": "2026-08-28"}
}
```

## 2. What NOT to Log

- JWT tokens, passwords — never.
- Full result payloads (could be large / sensitive) — log only `row_count` and aggregate counters.
- PII beyond admin_id and project_id.

## 3. Metrics

Expose metrics (logger or a metrics backend if present):

| Metric | Type | Labels | Description |
| --- | --- | --- | --- |
| `report_generation_time_ms` | histogram | report | Wall time per report call |
| `report_row_count` | gauge | report | Rows returned |
| `report_errors_total` | counter | report, code | Count of failed report generations |
| `report_slow_total` | counter | report | Count of slow (>threshold) generations |

## 4. Audit

- No audit records written — reports are read-only and do not change system state.
- If a future compliance requirement asks "who viewed which report", an audit-read log table can be added in S05+; out of scope here.

## 5. Analytics Hooks

Optional product analytics (anonymized):

- Which report type is most used.
- Median filter span (days between start/end).
- Most common project filter.

Sent as aggregate counters, no row-level data.

## 6. Log Levels

| Level | Use |
| --- | --- |
| INFO | request received, result returned |
| WARN | slow report, large row count (>5000) |
| ERROR | exception, invalid filter that escaped validation, DB error |
| DEBUG | full SQL text (dev only; off in prod) |

## 7. Correlation

Each request gets a `request_id` (from middleware) propagated into logs so a frontend error report can be matched to backend logs.