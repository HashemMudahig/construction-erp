# 15 — UI/UX Screen Specification — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Design System

- Material 3, light/dark theme inherited from Sprint 01.
- Money formatted with `NumberFormat.simpleCurrency(decimalDigits: 2)`.
- Color tokens: positive balance = green, negative = red.
- Loading: centered `CircularProgressIndicator`; empty: illustration + CTA; error: retry button + message.

## 2. Project Detail Screen (extended)

`DefaultTabController(length: 4)`:
1. **Overview** — project metadata + Profitability card.
2. **Milestones** — `MilestoneListWidget`.
3. **Payments** — `PaymentListWidget`.
4. **Expenses** — `ExpenseListWidget`.

### 2.1 Profitability Card (Overview tab)
| Field | Display |
| --- | --- |
| Total Payments | currency, green |
| Total Expenses | currency, red |
| Balance | currency; green if ≥ 0 else red |
| Profit Margin | percentage, e.g. "79%" |

A tap on the card re-fetches `projectProfitabilityProvider(projectId)`.

## 3. Milestone List

- DataTable columns: **Title**, **Due Date**, **Status** (chip).
- Status chips: pending=grey, in_progress=blue, completed=green, overdue=red.
- FAB "+ Add Milestone" → `MilestoneFormSheet`.
- Row tap → edit form; swipe/delete → confirm dialog → DELETE.
- Empty state: "No milestones yet. Add the first one."

### Milestone Form
- Fields: Title (text, required), Description (multiline, optional), Due Date (date picker, required), Status (dropdown: pending/in_progress/completed).
- Save disabled until Title + Due Date valid.
- On success: pop sheet, refresh list, SnackBar "Milestone saved".

## 4. Payment List

- DataTable columns: **Amount**, **Date**, **Method** (chip), **Notes** (truncated).
- Summary header: "Total: {currency}" summing visible page.
- FAB "+ Record Payment" → `PaymentFormSheet`.
- Row tap → edit; swipe → delete with confirm.

### Payment Form
- Amount: numeric keyboard, decimal allowed, validated `> 0` (client + server).
- Payment Date: date picker (defaults to today).
- Method: dropdown {Cash, Bank Transfer, Cheque, Other}.
- Notes: multiline, optional.
- Inline error mapping: `INVALID_AMOUNT`, `INVALID_METHOD`, `PROJECT_NOT_FOUND`.

## 5. Expense List

- DataTable columns: **Category**, **Amount**, **Date**, **Notes**.
- Summary header: "Total: {currency}".
- FAB "+ Record Expense" → `ExpenseFormSheet`.

### Expense Form
- Category: dropdown {Materials, Labor, Equipment, Permits, Other}.
- Amount: numeric keyboard, decimal, `> 0`.
- Expense Date: date picker (defaults to today).
- Notes: multiline, optional.
- Inline error mapping: `INVALID_CATEGORY`, `INVALID_AMOUNT`, `PROJECT_NOT_FOUND`.

## 6. States per Screen

| State | Milestones | Payments | Expenses |
| --- | --- | --- | --- |
| Loading | spinner | spinner | spinner |
| Empty | illustration + CTA | illustration + CTA | illustration + CTA |
| Error | retry + message | retry + message | retry + message |
| Data | DataTable | DataTable + total | DataTable + total |

## 7. Accessibility & Responsiveness

- All forms reachable by keyboard; date pickers use Material 3 default a11y.
- DataTables collapse to a single-column card list on narrow widths (<600px).
- Money labels include currency symbol; color is never the only signal (icons accompany red/green).

## 8. Copy

| Context | Copy |
| --- | --- |
| Add payment button | "Record Payment" |
| Add expense button | "Record Expense" |
| Add milestone button | "Add Milestone" |
| Save success | "Saved" |
| Delete confirm | "Delete this record? This cannot be undone." |
| Invalid amount | "Enter an amount greater than 0." |