# Sprint 05 — Logging, Audit & Analytics

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Logging Approach

Structured JSON logs at the service boundary, using the existing logger configured in Sprint 01. Each log entry includes `timestamp`, `level`, `event`, `actor` (admin user id from JWT), `project_id`, `file_id`, and relevant metrics.

## 2. File Operation Logs

| Event | Level | Key Fields |
| --- | --- | --- |
| `file.upload.started` | INFO | `project_id`, `filename`, `content_type`, `category` |
| `file.uploaded` | INFO | `file_id`, `project_id`, `size_bytes`, `content_type`, `duration_ms` |
| `file.upload.rejected` | WARN | `project_id`, `reason` (`too_large` / `invalid_type` / `path_traversal`), `filename` |
| `file.downloaded` | INFO | `file_id`, `project_id`, `size_bytes`, `duration_ms` |
| `file.deleted` | INFO | `file_id`, `project_id`, `size_bytes` |
| `file.not_found` | WARN | `file_id` (on download/delete attempt) |
| `file.upload.failed` | ERROR | `project_id`, `error`, `stage` (`disk` / `db`) |

### Example log line

```json
{
  "timestamp": "2026-09-02T10:15:30.221Z",
  "level": "INFO",
  "event": "file.uploaded",
  "actor": "admin",
  "file_id": "9d1c-...-e7f3",
  "project_id": "b2a4-...-0c11",
  "size_bytes": 1048576,
  "content_type": "application/pdf",
  "category": "contract",
  "duration_ms": 312
}
```

## 3. Audit Events

Audit events are a subset of logs, written to an append-only audit trail (or audit table) for compliance traceability.

| Audit Event | Trigger | Payload |
| --- | --- | --- |
| `file_uploaded` | successful upload | `file_id`, `project_id`, `file_name`, `size`, `category`, `actor`, `ts` |
| `file_downloaded` | successful download | `file_id`, `project_id`, `actor`, `ts` |
| `file_deleted` | successful delete | `file_id`, `project_id`, `actor`, `ts` |
| `report_exported` | CSV export | `report_type`, `format`, `row_count`, `actor`, `ts` |
| `project_exported` | project payload export | `project_id`, `actor`, `ts` |

Audit entries are immutable; retention policy aligns with the ERP data retention policy (default 1 year, configurable).

## 4. Metrics

Counters and gauges exposed via the existing metrics endpoint (Prometheus-compatible if Sprint 01 enabled it; otherwise logged periodically).

| Metric | Type | Labels | Description |
| --- | --- | --- | --- |
| `uploads_total` | counter | `category`, `content_type` | Number of successful uploads |
| `upload_bytes_total` | counter | — | Total bytes uploaded |
| `upload_rejected_total` | counter | `reason` | Rejected uploads (`too_large`, `invalid_type`, `path_traversal`) |
| `downloads_total` | counter | — | Number of downloads |
| `deletes_total` | counter | — | Number of deletes |
| `exports_total` | counter | `report_type`, `format` | Number of exports |
| `upload_duration_ms` | histogram | — | Upload latency distribution |
| `download_duration_ms` | histogram | — | Download latency distribution |
| `disk_usage_bytes` | gauge | `project_id` (optional) | Current `UPLOAD_DIR` usage |

## 5. Alerts

| Alert | Condition | Severity |
| --- | --- | --- |
| `PathTraversalAttempt` | any `PATH_TRAVERSAL_BLOCKED` event | High — potential attack |
| `OversizedUploadSpike` | `upload_rejected_total{reason="too_large"}` rate > 5/min | Medium |
| `UploadFailureRate` | upload errors / attempts > 5% over 10 min | High |
| `DiskUsageHigh` | `disk_usage_bytes` > 80% of volume | High |
| `OrphanedFiles` | weekly reconciliation finds disk files not in DB | Low (cleanup) |

Alerts are emitted via the existing alerting channel (Sprint 01 logging pipeline). Path traversal attempts should be investigated immediately.

## 6. Reconciliation Job (Out of Scope for v1, Noted)

A weekly job scans `UPLOAD_DIR` and the `files` table to detect orphaned disk files (present on disk, missing in DB) or orphaned metadata (present in DB, missing on disk). Orphans are logged and, in a future phase, auto-cleaned. For Sprint 05, the job only logs discrepancies.

## 7. Privacy & Data Handling

- File contents are **not** logged. Only metadata (name, size, type, ids).
- Export payloads are not logged in full (may contain financial data). Only the event + id is recorded.
- Audit trail is access-restricted (single admin; no separate auditor role in v1).

## 8. Log Retention

| Log Type | Retention |
| --- | --- |
| Operational logs | 30 days hot, 90 days cold |
| Audit events | 1 year (configurable) |
| Metrics | 14 days at 1-min resolution, 1 year at 1-hour resolution |