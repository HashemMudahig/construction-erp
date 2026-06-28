# Sprint 05 — Product Scope & PRD

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Problem Statement

Construction projects generate a large volume of supporting documents — contracts, drawings, invoices, compliance documents — that are currently scattered across email threads, local folders, and messaging apps. Sprints 01–04 delivered CRUD, profitability, dashboard, and reporting, but there is no way to attach documents to a project record, and no way to export reports or summaries for sharing with stakeholders.

This sprint closes two gaps:

1. **Document centralization** — attach files to a project so that all related artifacts are retrievable from the ERP itself.
2. **Export-ready outputs** — produce CSV streams of existing reports and a structured PDF-ready payload for project summaries, so finance and management can consume data outside the application.

## 2. Business Objectives

| # | Objective | Metric |
| --- | --- | --- |
| O1 | Centralize project documents in the ERP | 100% of uploaded files linked to a project |
| O2 | Enable offline report consumption | CSV export available for all three report types |
| O3 | Enable external project summary sharing | PDF-ready payload endpoint returns complete project data |
| O4 | Maintain security on file operations | JWT required; path traversal blocked; no public file URLs |
| O5 | Keep the system simple | Single admin user; no file-level ACLs |

## 3. Functional Requirements (Backlog)

| ID | Epic/Module | Task | Owner | Priority | SP | Dependency | Acceptance Criteria | Deliverable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S05-T01 | Files / Backend | File model + upload endpoint (multipart, stored to disk) | Backend Developer | Critical | 8 | Sprint 01 | Upload stores file to disk + metadata in DB; returns file_id; linked to project. | File Upload API |
| S05-T02 | Files / Backend | File download + delete endpoints | Backend Developer | High | 5 | S05-T01 | Download streams file bytes; delete removes file + metadata. | File Download/Delete API |
| S05-T03 | Export / Backend | Export reports as CSV endpoint | Backend Developer | High | 5 | Sprint 04 | Returns CSV stream for project-status, financial-summary, expense-analysis reports. | CSV Export API |
| S05-T04 | Export / Backend | Export project summary as PDF-ready payload endpoint | Backend Developer | Medium | 5 | Sprint 04 | Returns structured project summary payload (project, milestones, payments, expenses) suitable for PDF rendering. | Project Export API |
| S05-T05 | Files+Export / Frontend | File management screen + export buttons | Frontend Developer | High | 8 | S05-T01, S05-T03 | Admin can upload/download/delete project files and trigger CSV/PDF export from reports. | File + Export Screens |
| S05-T06 | QA / Tests | File upload/download + export tests | QA Tester | High | 3 | S05-T01, S05-T02, S05-T03, S05-T04 | Test report covering file storage, download, delete, and export content. | QA Report |

## 4. Out of Scope

- **PDF rendering** — server-side or client-side PDF generation is not part of this sprint. The export endpoint returns a structured JSON payload that a future rendering layer (Phase 2) can convert to PDF.
- **Multi-file or batch upload** — one file per request in v1.
- **Versioning or file locking** — overwritten only by explicit delete + re-upload.
- **Object storage (S3 / Azure Blob)** — v1 uses local disk under `UPLOAD_DIR`. A storage abstraction is noted in the ADR but not implemented.
- **Full-text search / OCR** of uploaded documents.
- **Role-based file access** — single admin user; all files visible to the authenticated user.

## 5. Users

| Persona | Description | Permissions |
| --- | --- | --- |
| Admin | Single administrative user (no RBAC, no multi-tenant) | Full CRUD on projects + files; trigger exports |

## 6. Business Rules

| # | Rule |
| --- | --- |
| BR1 | Every uploaded file must be linked to an existing `project_id`. |
| BR2 | Maximum file size is governed by `MAX_FILE_SIZE_MB` (default 25 MB). Oversized uploads return `413`. |
| BR3 | Allowed content types are governed by `ALLOWED_FILE_TYPES` (default: pdf, png, jpg, jpeg, xlsx, docx, csv). |
| BR4 | File name is sanitized; on-disk path is UUID-based (`uploads/{project_id}/{file_id}-{original_name}`) to prevent path traversal. |
| BR5 | CSV export reuses Sprint 04 report aggregation logic — no parallel data path. |
| BR6 | Deleting a project cascades to its files (FK `ON DELETE CASCADE`), removing metadata and disk files. |
| BR7 | All file and export endpoints require a valid JWT bearer token. |

## 7. Success Metrics

| Metric | Target |
| --- | --- |
| Upload success rate | ≥ 99% for valid files under size limit |
| Download latency (10 MB file) | < 500 ms to first byte |
| CSV export latency (largest report) | < 2 s |
| Path traversal attempts blocked | 100% |
| Post-deployment critical defects | 0 |

## 8. Assumptions

- Disk volume available to the backend is sufficient for expected file volume (estimated < 50 GB for v1).
- Frontend has access to a writable directory via `path_provider` for downloaded files.
- Network allows multipart uploads of up to 25 MB within reasonable timeouts.