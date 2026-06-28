# Sprint 05 — UI/UX Screen Specification

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Screen Inventory

| Screen | Location | Sprint 05 Addition |
| --- | --- | --- |
| Project Detail | `lib/features/projects/presentation/screens/project_detail_screen.dart` | new "Files" tab |
| Reports | `lib/features/reports/presentation/screens/reports_screen.dart` | export buttons per report type |
| Project Summary Preview | `lib/features/files/presentation/screens/project_export_preview_screen.dart` | new (payload viewer) |

## 2. Project Detail — Files Tab

Embedded as a tab in the existing project detail screen.

### Layout

```
[Project Detail]
  Overview | Milestones | Payments | Expenses | Files | [Export Summary]
                                                      ─────
  [Upload File ▲]
  ┌──────────────────────────────┬────────────┬──────────┬───────────┬──────────────┐
  │ Name                         │ Category   │ Size      │ Uploaded   │ Actions      │
  ├──────────────────────────────┼────────────┼──────────┼───────────┼──────────────┤
  │ contract_v3.pdf               │ contract   │ 1.0 MB   │ 02 Sep     │ ⬇  🗑          │
  │ drawing_r1.dwg                │ drawing    │ 512 KB   │ 01 Sep     │ ⬇  🗑          │
  └──────────────────────────────┴────────────┴──────────┴───────────┴──────────────┘
```

### Upload Button

- Tapping "Upload File" opens a bottom sheet:
  - File picker (`file_picker` package) — accepts allowed types only.
  - Category dropdown: `contract | drawing | invoice | document | other`.
  - "Upload" button — disabled while uploading; shows progress % for files > 1 MB.
- On success: SnackBar "File uploaded", list refreshes.
- On `413`: SnackBar "File too large (max 25 MB)".
- On `400 INVALID_FILE_TYPE`: SnackBar "Unsupported file type. Allowed: …".

### Download Button (⬇)

- Calls `downloadFile(fileId, fileName)`.
- On success: SnackBar "Saved to {path}" with an "Open" action.
- On `404`: SnackBar "File no longer exists".

### Delete Button (🗑)

- Long-press row OR tap delete icon → confirmation dialog:
  > "Delete {file_name}? This cannot be undone."
- Buttons: "Cancel" / "Delete" (destructive).
- On success: row removed with a fade animation; SnackBar "File deleted".

### States

| State | UI |
| --- | --- |
| Loading | shimmer rows |
| Empty | centered illustration + "No files attached yet" + Upload button |
| Error | error banner with "Retry" |

## 3. Reports Screen — Export Buttons

For each report type card (project_status, financial_summary, expense_analysis), add an "Export CSV" action.

```
[Reports Screen]
  Project Status
    [View Details]   [Export CSV ⬇]
  Financial Summary
    [View Details]   [Export CSV ⬇]
  Expense Analysis
    [View Details]   [Export CSV ⬇]
```

- Tapping "Export CSV" calls `exportReportCsv(type)`.
- Progress indicator while downloading (CSV is fast; a simple indeterminate spinner suffices).
- On success: SnackBar "CSV saved: {path}" + "Open" action.
- On `400 EXPORT_UNAVAILABLE`: SnackBar "Export unavailable for this report".

## 4. Project Summary Export

On the project detail screen, an "Export Summary" button (top-right of the detail screen).

- Tapping calls `exportProject(projectId)`.
- Opens `ProjectExportPreviewScreen` showing a read-only card:
  - Project name, status, budget, dates.
  - Milestones list (name, due date, completed).
  - Payments list (amount, date, status).
  - Expenses list (category, amount, date).
  - Summary card: total paid, total expenses, remaining budget.
- "Close" button returns to project detail.
- Note: "PDF generation coming in Phase 2" hint at the bottom.

## 5. Material 3 Guidelines

| Element | Spec |
| --- | --- |
| Theme | existing Construction ERP Material 3 theme (Sprint 01) |
| Upload button | `FilledButton.tonalIcon` with upload icon |
| Delete icon | `IconButton` with `Icons.delete_outline`, color `error` |
| Download icon | `IconButton` with `Icons.download_outlined` |
| Confirmation dialog | `AlertDialog` with destructive action in `error` color |
| Progress | `LinearProgressIndicator` for upload, `CircularProgressIndicator` for export |
| SnackBar | `SnackBar` with `action` for "Open" / "Retry" |

## 6. File Size Formatting

```dart
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
```

Dates formatted per existing locale settings (Sprint 01).

## 7. Accessibility

| Concern | Approach |
| --- | --- |
| Tap targets | ≥ 48 dp |
| Row actions | semantic labels for screen readers ("Download {name}", "Delete {name}") |
| Color contrast | follow Material 3 defaults |
| Keyboard nav | tab order: upload → table rows → export buttons |
| Loading announcements | `SemanticsService.announce` for upload completion |

## 8. Error / Empty / Loading Summary

| State | Files tab | Reports export | Project export |
| --- | --- | --- | --- |
| Loading | shimmer | spinner on button | spinner on button |
| Empty | "No files yet" + upload | n/a (report has data) | n/a |
| Error | banner + retry | SnackBar error | SnackBar error |
| Success | list refresh / row animation | SnackBar with path | preview screen opens |

## 9. Responsive Behavior

- Phone: table is horizontally scrollable; file name column pinned.
- Tablet/desktop: table expands; action buttons inline.

## 10. Internationalization

All strings via `AppLocalizations` (existing). New keys: `files_title`, `upload_file`, `download`, `delete`, `delete_confirm`, `export_csv`, `export_summary`, `files_empty`, `file_too_large`, `invalid_file_type`, `csv_saved`, `file_saved`.