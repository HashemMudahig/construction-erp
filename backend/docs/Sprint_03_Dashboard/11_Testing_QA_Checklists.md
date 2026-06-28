# 11 — Testing & QA Checklists (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Test Pyramid
| Level | Tool | Target | Coverage goal |
| --- | --- | --- | --- |
| Unit | pytest | DashboardService math | 100% of methods |
| Integration | pytest + TestClient | endpoints return correct aggregations | 3 endpoints |
| Repository | pytest + SQLite/PG fixtures | SQL correctness | all repo methods |
| Frontend widget | flutter test | KPI cards, table, chart | smoke + golden |
| QA manual | checklist | visual + numbers | sprint close |

## 2. Unit Tests — Service math (seeded data)
```python
def test_summary_with_seed_data(db_session, seed_projects_payments_expenses):
    svc = DashboardService(db_session)
    s = svc.get_summary()
    assert s.active_projects == 2
    assert s.completed_projects == 1
    assert s.total_clients == 3
    assert s.total_payments == Decimal("1000.00")
    assert s.total_expenses == Decimal("700.00")
    assert s.outstanding_balances == Decimal("300.00")

def test_summary_empty(db_session):
    s = DashboardService(db_session).get_summary()
    assert s.active_projects == 0
    assert s.outstanding_balances == Decimal("0.00")
```

## 3. Integration Tests — Endpoints
```python
def test_summary_endpoint(client, auth_header, seed):
    r = client.get("/api/v1/dashboard/summary", headers=auth_header)
    assert r.status_code == 200
    body = r.json()
    assert body["success"] is True
    assert body["data"]["active_projects"] == 2
    assert body["data"]["outstanding_balances"] == "300.00"

def test_projects_endpoint_ordering(client, auth_header, seed):
    r = client.get("/api/v1/dashboard/projects", headers=auth_header)
    names = [p["name"] for p in r.json()["data"]]
    assert names == sorted(names)

def test_finance_endpoint_returns_12_months(client, auth_header, seed):
    r = client.get("/api/v1/dashboard/finance", headers=auth_header)
    months = r.json()["data"]["months"]
    assert len(months) == 12
    assert all("income" in m and "expense" in m for m in months)

def test_unauthenticated(client):
    assert client.get("/api/v1/dashboard/summary").status_code == 401
```

## 4. Repository Tests
- `test_counts_status_filter` — only ACTIVE/COMPLETED counted.
- `test_totals_returns_decimal` — type is `Decimal`, not float.
- `test_projects_overview_balance` — balance = payments_sum − expenses_sum per row.
- `test_finance_overview_pads_missing_months` — 12 entries even if data sparse.
- `test_finance_overview_uses_utc` — month key matches UTC `YYYY-MM`.

## 5. Frontend Tests
- `dashboard_screen_golden_test` — golden image of KPI grid.
- `kpi_card_displays_value` — label + value rendered.
- `cash_flow_chart_renders_12_bars` — bar count matches months length.
- `dashboard_error_state_renders_retry` — when provider error, retry visible.
- `dashboard_empty_state` — projects empty → "No projects yet" message.

## 6. QA Manual Checklist
| # | Check | Pass criteria |
| --- | --- | --- |
| 1 | Login → dashboard loads < 2 s | stopwatch |
| 2 | KPI cards show seeded values | match DB query |
| 3 | Pull-to-refresh updates values | refresh icon visible |
| 4 | Projects table sorted by name | visual |
| 5 | Negative balance shows red | visual |
| 6 | Cash-flow chart 12 bars | visual |
| 7 | Logout → endpoints 401 | curl without token |
| 8 | Empty DB → zeros + empty array | truncate fixtures |
| 9 | Mobile layout 2 columns | device/preview |
| 10 | Desktop layout 4 columns | browser wide |
| 11 | Error banner retry works | stop DB, retry |
| 12 | No mutation endpoints in OpenAPI | grep schema |

## 7. Test Data Fixtures
`tests/conftest.py` exposes:
- `seed_projects_payments_expenses` — 3 clients, 3 projects (2 ACTIVE, 1 COMPLETED), 5 payments, 4 expenses.
- `seed_finance_12_months` — one payment and one expense per month for 12 months.
- `empty_db` — no rows; verifies zero/empty responses.

## 8. Definition of Done (testing)
- All unit/integration tests green in CI.
- QA checklist 1–12 signed off.
- Coverage report: dashboard module ≥ 90 %.
- No Critical/High defects open.