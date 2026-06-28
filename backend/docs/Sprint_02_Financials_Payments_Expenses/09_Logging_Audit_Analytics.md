# 09 — Logging, Audit & Analytics — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Logging Strategy

Sprint S02 extends the Sprint 01 structured logger (JSON to stdout) with financial-domain fields. Every mutating service call logs an entry tagged with `module`, `action`, `project_id`, `record_id`, and `amount` (as a string to preserve precision).

```json
{"ts":"2026-07-25T10:00:00Z","level":"INFO","module":"payments","action":"payment_created",
 "actor":"<admin-uuid>","project_id":"<uuid>","payment_id":"<uuid>","amount":"15000.00","method":"bank_transfer"}
```

## 2. Audit Events

| Event code | Trigger | Key fields |
| --- | --- | --- |
| `payment_created` | POST /payments success | project_id, amount, method, payment_date |
| `payment_updated` | PUT /payments/{id} success | payment_id, project_id, changed fields |
| `payment_deleted` | DELETE /payments/{id} success | payment_id, project_id |
| `expense_created` | POST /expenses success | project_id, category, amount, expense_date |
| `expense_updated` | PUT /expenses/{id} success | expense_id, project_id, changed fields |
| `expense_deleted` | DELETE /expenses/{id} success | expense_id, project_id |
| `milestone_completed` | status → completed | milestone_id, project_id, previous_status |

Audit entries are emitted at INFO level; no separate audit table in v1 (deferred to S03). The logs are retained per the platform's log retention policy.

## 3. Metrics

| Metric | Type | Source |
| --- | --- | --- |
| `payments_total` | counter | POST /payments 201 |
| `expenses_total` | counter | POST /expenses 201 |
| `milestone_completion_rate` | gauge | completed / total milestones |
| `negative_amount_attempts` | counter | INVALID_AMOUNT rejections |
| `profitability_requests` | counter | GET /projects/{id}/profitability |
| `financial_request_latency_ms` | histogram | per-endpoint timing |

Metrics are exposed via the existing `/metrics` integration (Prometheus-style) inherited from Sprint 01.

## 4. Alerting

| Alert | Condition | Severity |
| --- | --- | --- |
| `NegativeAmountAttempt` | `negative_amount_attempts` increments in 1 min | Warning |
| `OrphanProjectReference` | service raises PROJECT_NOT_FOUND | Warning |
| `ProfitabilityLatencyHigh` | p95 of profitability endpoint > 500 ms | Warning |
| `FinancialCreateFailureSpike` | 5xx rate on POST /payments or /expenses > 5% | Critical |

## 5. Sensitive-Data Handling

- Amounts are logged but are operational data, not PII; acceptable in application logs.
- `notes` fields are **not** logged (may contain free-text client info); only their presence/length is logged.
- JWT tokens are never logged; only the resolved `actor` user id.
- No financial data is sent to third-party analytics in v1.

## 6. Correlation

Each request carries the Sprint 01 `X-Request-ID` header, propagated into log entries, so a payment creation can be traced from Flutter → API → service → DB. This is essential for diagnosing profitability mismatches reported by the admin.