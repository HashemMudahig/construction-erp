# 15 — UI/UX Screen Specification (Sprint 03 Dashboard)

> **Project:** Construction ERP  
> **Sprint:** S03  
> **Period:** 2026-08-03 to 2026-08-14  
> **Lead:** Tech Lead  
> **Goal:** Deliver a management dashboard with KPIs, summary cards, and charts aggregating active/completed projects, outstanding balances, and financial overview.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Screen
`DashboardScreen` — route `/dashboard`, initial location after login. Material 3, responsive. AppBar title "Dashboard" with a refresh `IconButton`.

## 2. Layout
```
┌─────────────────────────────────────────────────────────┐
│  AppBar: "Dashboard"                       [refresh]      │
├─────────────────────────────────────────────────────────┤
│  KPI grid (2 cols mobile / 4 cols desktop)                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │ Active   │ │Completed │ │ Clients  │ │Outstand- │     │
│  │ Projects │ │ Projects │ │          │ │ Balances │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
├─────────────────────────────────────────────────────────┤
│  Projects Overview (DataTable / ListView)                 │
│  Name | Client | Status | Budget | Balance                │
│  ...                                                      │
├─────────────────────────────────────────────────────────┤
│  Cash-Flow (last 12 months) — grouped bars               │
│  income (green) vs expense (red)                          │
└─────────────────────────────────────────────────────────┘
```

## 3. KPI Cards
| Card | Value source | Icon | Color |
| --- | --- | --- | --- |
| Active Projects | summary.active_projects | `icons.work` | primary |
| Completed Projects | summary.completed_projects | `icons.task_alt` | tertiary |
| Total Clients | summary.total_clients | `icons.people` | secondary |
| Outstanding Balances | summary.outstanding_balances | `icons.account_balance_wallet` | red if < 0 else green |

- Value formatted with `NumberFormat.currency(symbol: "\$")` for money; `NumberFormat.decimalPattern` for counts.

## 4. Projects Overview Table
Columns: `Name | Client | Status | Budget | Balance`.
- `Status` shown as colored chip (Active=green, Completed=blue, On hold=amber, Cancelled=grey).
- `Balance` red text when negative; tap row → `/projects/{id}` (Sprint 02 detail).
- Sortable by Name (default) and Balance.
- Empty state: centered "No projects yet" with illustration.
- Pagination: client-side for S03 (expected < 1 000 rows); virtual list if > 100.

## 5. Cash-Flow Chart
- Grouped vertical bars per month; 12 months on X-axis (`mm`), currency on Y-axis.
- Tooltip on tap shows month + income + expense + net.
- Legend: green = income, red = expense.
- Loading: skeleton bars; error: retry button overlay.

## 6. States
| State | Visual |
| --- | --- |
| Loading | shimmer cards + skeleton table rows + chart spinner |
| Empty | zeros + "No projects yet" + flat chart line at 0 |
| Error | red banner "Couldn't load dashboard" with Retry; partial state kept |
| Refreshing | AppBar refresh icon spins; existing values stay until new arrive |

## 7. Responsive Breakpoints
| Width | KPI grid | Table | Chart height |
| --- | --- | --- | --- |
| < 600 | 2 cols | ListView | 200 px |
| 600–900 | 3 cols | DataTable | 260 px |
| > 900 | 4 cols | DataTable | 320 px |

## 8. Accessibility
- All cards `Semantics(label: ...)`; chart has `Semantics` summary "Cash flow for last 12 months".
- Minimum tap target 48 dp; color contrast AA.
- Status chips have text (not color-only).
- Keyboard: tab order cards → table → chart.

## 9. Refresh Action
- AppBar `IconButton` calls `ref.read(dashboardProvider.notifier).refresh()`.
- Pull-to-refresh on the scroll view triggers the same.
- Last refresh timestamp shown in small text under AppBar trailing.

## 10. Theming
- Material 3 `ColorScheme.fromSeed(seedColor: Colors.blue)`.
- Cards: surface container low; chart background transparent.
- Dark mode supported via `MediaQuery.platformBrightness`.