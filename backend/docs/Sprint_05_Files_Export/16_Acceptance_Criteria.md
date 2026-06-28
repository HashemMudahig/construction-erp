# Sprint 05 — Acceptance Criteria

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Backlog Acceptance Table

| ID | Epic/Module | Task | Owner | Priority | SP | Dependency | Acceptance Criteria | Deliverable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S05-T01 | Files / Backend | File model + upload endpoint (multipart, stored to disk) | Backend Developer | Critical | 8 | Sprint 01 | Upload stores file to disk + metadata in DB; returns file_id; linked to project. | File Upload API |
| S05-T02 | Files / Backend | File download + delete endpoints | Backend Developer | High | 5 | S05-T01 | Download streams file bytes; delete removes file + metadata. | File Download/Delete API |
| S05-T03 | Export / Backend | Export reports as CSV endpoint | Backend Developer | High | 5 | Sprint 04 | Returns CSV stream for project-status, financial-summary, expense-analysis reports. | CSV Export API |
| S05-T04 | Export / Backend | Export project summary as PDF-ready payload endpoint | Backend Developer | Medium | 5 | Sprint 04 | Returns structured project summary payload (project, milestones, payments, expenses) suitable for PDF rendering. | Project Export API |
| S05-T05 | Files+Export / Frontend | File management screen + export buttons | Frontend Developer | High | 8 | S05-T01, S05-T03 | Admin can upload/download/delete project files and trigger CSV/PDF export from reports. | File + Export Screens |
| S05-T06 | QA / Tests | File upload/download + export tests | QA Tester | High | 3 | S05-T01, S05-T02, S05-T03, S05-T04 | Test report covering file storage, download, delete, and export content. | QA Report |

## 2. Given/When/Then — Upload Success (S05-T01)

- **Given** an authenticated admin and an existing project.
- **When** the admin uploads a 1 MB PDF with category `contract` to `POST /files/upload`.
- **Then** the response is `201`, `data.file_id` is a UUID, the file exists at `{UPLOAD_DIR}/{project_id}/{file_id}-sample.pdf`, and a `files` row exists with matching metadata.

## 3. Given/When/Then — Upload Too Large (S05-T01)

- **Given** an authenticated admin.
- **When** the admin uploads a 26 MB file (limit 25 MB).
- **Then** the response is `413` with `errors[0].code == "FILE_TOO_LARGE"`, no `files` row is inserted, and no partial file remains on disk.

## 4. Given/When/Then — Invalid File Type (S05-T01)

- **Given** an authenticated admin and existing project.
- **When** the admin uploads a `.exe` file.
- **Then** the response is `400` with `errors[0].code == "INVALID_FILE_TYPE"`, and no file is written.

## 5. Given/When/Then — Download Returns Bytes (S05-T02)

- **Given** a previously uploaded file with `file_id` F.
- **When** the admin calls `GET /files/{F}`.
- **Then** the response is `200`, `Content-Type` matches the stored `content_type`, `Content-Disposition` is `attachment; filename="{file_name}"`, and the streamed bytes match the original file (checksum equal).

## 6. Given/When/Then — Delete Removes File + Metadata (S05-T02)

- **Given** a previously uploaded file F.
- **When** the admin calls `DELETE /files/{F}`.
- **Then** the response is `204`, the disk file is removed, the `files` row is deleted, and a subsequent `GET /files/{F}` returns `404 FILE_NOT_FOUND`.

## 7. Given/When/Then — CSV Export Matches Report Data (S05-T03)

- **Given** seeded report data.
- **When** the admin calls `GET /export/reports?type=project_status&format=csv`.
- **Then** the response is `200 text/csv`, the CSV starts with the UTF-8 BOM, the header row matches the report columns, and the row count equals the JSON `/reports/project_status` data length; numeric cells match.

## 8. Given/When/Then — Project Export Payload Completeness (S05-T04)

- **Given** a project P with at least one milestone, one payment, one expense.
- **When** the admin calls `GET /export/projects/{P}`.
- **Then** the response is `200`, `data` contains `project`, `milestones`, `payments`, `expenses`, and `summary`, where `summary.total_paid == sum(payments.amount)`, `summary.total_expenses == sum(expenses.amount)`, and `summary.remaining_budget == project.budget - total_expenses`.

## 9. Given/When/Then — Path Safety (S05-T01)

- **Given** an authenticated admin.
- **When** the admin uploads a file named `../../etc/passwd`.
- **Then** the response is `400` with `errors[0].code == "PATH_TRAVERSAL_BLOCKED"`, no file is written outside `UPLOAD_DIR`, and an alert is logged.

## 10. Given/When/Then — Frontend File Management (S05-T05)

- **Given** the Flutter app authenticated as admin and an open project detail screen.
- **When** the admin opens the Files tab, uploads a file, taps download, then deletes with confirmation.
- **Then** the list updates after each action, the downloaded file is saved to the device documents directory, and the deleted row disappears with a confirmation SnackBar.

## 11. Given/When/Then — Frontend Export Buttons (S05-T05)

- **Given** the Flutter app on the Reports screen.
- **When** the admin taps "Export CSV" on the financial summary card.
- **Then** a CSV file is downloaded and saved, and a SnackBar shows the saved path with an "Open" action.

## 12. Given/When/Then — Cascade Delete (Business Rule)

- **Given** a project P with uploaded files.
- **When** the admin deletes project P via `DELETE /projects/{P}` (Sprint 01).
- **Then** all `files` rows with `project_id == P` are removed (FK `ON DELETE CASCADE`), and the corresponding disk files are removed by the service cascade hook.

## 13. Given/When/Then — Unauthenticated Access

- **Given** no JWT provided.
- **When** any Sprint 05 endpoint is called.
- **Then** the response is `401 UNAUTHENTICATED`.

## 14. Closure Decision Rule

Sprint 05 is accepted for release when:
1. All 6 backlog tasks meet their acceptance criteria (above).
2. Unit + integration test suites are green on CI.
3. The QA report (S05-T06) is signed by QA Tester and Tech Lead.
4. No open Critical or High severity defects remain.
5. Demo at Sprint Review covers: upload, download, delete, CSV export, project export payload — end to end.
6. Documentation in this folder reflects the shipped implementation.

| Gate | Owner | Sign-off |
| --- | --- | --- |
| Code merged + CI green | Tech Lead | ☐ |
| QA report signed | QA Tester | ☐ |
| Demo completed | Tech Lead | ☐ |
| Release tag cut | Tech Lead | ☐ |