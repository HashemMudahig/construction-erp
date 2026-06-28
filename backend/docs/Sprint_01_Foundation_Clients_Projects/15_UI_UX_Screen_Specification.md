# 15 — UI/UX Screen Specification

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Design System

- **Material 3**, single color seed, light default (dark supported).
- Spacing tokens: 4/8/12/16/24/32 dp. Radius: 12 dp cards, 8 dp inputs.
- Typography: M3 `Typography`.
- Every list/form/detail must handle `loading`, `empty`, `error`, `data` states explicitly.

## 2. Login Screen (`/login`)

| Element | Spec |
| --- | --- |
| Title | "Construction ERP" |
| Email field | `TextFormField`, keyboard email, validator non-empty + email |
| Password field | `TextFormField`, obscure, toggle visibility |
| Submit button | `FilledButton`, disabled while submitting |
| Error | inline banner / red text under button |
| On success | route to `/` |
| On 401 | show "Invalid email or password" |
| Loading | button shows spinner, inputs disabled |

## 3. App Shell

- `NavigationRail` (wide) / `Drawer` (narrow) with sections: **Clients**, **Projects**.
- Top bar: app title + admin email + logout icon.
- Content area hosts the routed screen.

## 4. Client List (`/`)

| Column | Field | Notes |
| --- | --- | --- |
| Name | name | bold |
| Phone | phone | muted |
| Email | email | muted |
| Status | archived | "Active"/"Archived" chip |

- Toolbar: search field (debounced 300ms), `+ Add` button, refresh.
- Row tap → `/clients/{id}`. Edit icon → `/clients/{id}/edit`.
- Empty: "No clients yet. Add your first client." + CTA.
- Error: message + Retry.

## 5. Client Form (`/clients/new`, `/clients/{id}/edit`)

Fields: name (required), phone, email, address (multiline), notes (multiline), archived switch. Save → on success pop back to list and refresh. Delete (edit only) → confirm dialog; on 409 show "Client has linked projects".

## 6. Client Detail (`/clients/{id}`)

- Card with all client fields.
- Section "Linked Projects" listing name, budget, status with tap → `/projects/{id}`.
- FAB "Add project for this client" → `/projects/new?client_id={id}`.

## 7. Project List (`/projects`)

| Column | Field | Notes |
| --- | --- | --- |
| Name | name | bold |
| Client | client name | resolved via providers |
| Budget | budget | formatted with 2 decimals + currency |
| Status | status | colored chip per status |

- Filters: client dropdown, status dropdown, search by name, `+ Add`.
- Empty/error/loading handled.

## 8. Project Form (`/projects/new`, `/projects/{id}/edit`)

Fields:
- Client dropdown (required) — preselected when `client_id` query passed.
- Name (required).
- Description (multiline).
- Budget (numeric, 2 decimals, ≥0).
- Start date / end date (date pickers; validate end ≥ start).
- Status dropdown (5 enum values).
- Save / Delete (edit). On `PROJECT_CLIENT_INVALID` show inline error on dropdown.

## 9. Project Detail (`/projects/{id}`)

- Card with all fields, client name as a link → client detail.
- Budget shown formatted.
- Status chip.
- Edit / Delete actions.

## 10. State Matrix (every screen)

| State | Presentation |
| --- | --- |
| loading | centered `CircularProgressIndicator` (or shimmer on lists) |
| empty | illustration + helpful text + primary CTA |
| error | `Text(message)` + Retry button |
| data | full content |
| submitting | button spinner, inputs read-only |

## 11. Accessibility & Responsiveness

- Min tap target 48 dp. Semantic labels on icon-only buttons.
- Layout adapts from < 600 dp (single column, drawer) to ≥ 1024 dp (rail + two-pane detail).

## 12. Theme

```dart
ThemeData.light(useMaterial3: true).copyWith(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6F8B)),
);
```