# Sprint 04 — UI/UX Screen Specification

> **Project:** Construction ERP  
> **Sprint:** S04  
> **Period:** 2026-08-17 to 2026-08-28  
> **Lead:** Tech Lead  
> **Goal:** Add reporting capabilities — project status, financial summary, and expense analysis reports — filterable by date range and project, export-ready.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Screen: Reports

Route: `/reports`. Accessible from the dashboard drawer ("Reports"). Requires auth.

## 2. Layout

```
┌──────────────────────────────────────────────┐
│  AppBar: "Reports"        [Export] (disabled) │
├──────────────────────────────────────────────┤
│  Report type: ( ) Project Status              │
│              ( ) Financial Summary             │
│              (•) Expense Analysis             │
│                                              │
│  Date range: [Start ▼]  [End ▼]              │
│  Project:    [All projects ▼]                │
│  Status:     [All ▼]   (only for Project      │
│                          Status report)       │
│                                              │
│            [ Generate ]                       │
├──────────────────────────────────────────────┤
│  Results area                                 │
│  (table + optional chart)                    │
└──────────────────────────────────────────────┘
```

## 3. Controls

### 3.1 Report Type Selector
Segmented control (Material 3 `SegmentedButton`) with three options:
- Project Status
- Financial Summary
- Expense Analysis

Changing type resets results to the initial hint and shows/hides the Status filter (only for Project Status).

### 3.2 Date-Range Picker
Two date pickers (Start, End). Optional. If both empty, report covers all dates. Validate client-side: start <= end; show inline error otherwise.

### 3.3 Project Dropdown
Lists all projects (`name` — `status`). "All projects" default. Loaded once on screen open via existing projects provider.

### 3.4 Status Filter
Visible only for Project Status report. Options: All, active, completed, on_hold, cancelled.

### 3.5 Generate Button
Filled button. Disabled until a report type is selected. On tap: calls `reportsController.generate(filters, type)`.

### 3.6 Export Button (placeholder)
Outlined, disabled, tooltip "Available in Sprint 05". Wired in S05.

## 4. Results Area

### 4.1 Project Status Table
| Project | Status | Budget | Payments | Expenses | Balance | Milestones | Progress |
Columns: text + money (2 dp) + progress as `3/6 (50%)`.

### 4.2 Financial Summary
Top summary cards: Income, Expenses, Net (color: net green if >= 0 else red).
Below: per-project table (Project, Income, Expenses, Net).

### 4.3 Expense Analysis
- Summary card: Grand Total.
- Category breakdown table: Category, Total, Percentage.
- Simple bar chart (or pie) of category totals using `fl_chart`. Percentages labeled.
- Optional per-project expansion rows.

## 5. States

| State | Display |
| --- | --- |
| Initial | Hint: "Select a report type and filters, then Generate." |
| Loading | Centered `CircularProgressIndicator` over results area; Generate disabled. |
| Empty | "No data for the selected filters." with the table headers hidden. |
| Error | Error text from code mapping + "Retry" button (re-runs last generate). |
| Data | Table + (optional) chart. |

## 6. Formatting Rules

- Money: `#,##0.00` with currency symbol from settings.
- Percentages: `0.00%` (already 2 dp from API).
- Dates in pickers: short locale format; sent to API as `yyyy-MM-dd`.

## 7. Accessibility & Responsiveness

- Min tap target 48dp.
- Tables horizontally scroll on narrow screens.
- Charts collapse to a stacked list on very small widths.
- Semantic labels on icon-only buttons.

## 8. Material 3

Use `ColorScheme.fromSeed`. Cards for summary metrics. `SegmentedButton` for type selector. `FilledButton` for Generate. Consistent with the rest of the app (Sprints 01–03).

## 9. Navigation

Back button returns to dashboard. Drawer "Reports" item highlights when active. Deep link `/reports` works with auth redirect.