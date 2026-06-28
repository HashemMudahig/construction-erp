# Sprint 05: File Attachments & Export

## Goal
Add file attachments and export support for reports and project documents.

## Scope
- Files
- Export

## API Endpoints
- `POST /files/upload`
- `GET /files/{file_id}`
- `DELETE /files/{file_id}`
- `GET /export/reports`
- `GET /export/projects/{project_id}`

## Database Tables
- `files`
- `exports` (or export metadata)

## Success Criteria
- File upload and retrieval are supported for projects and reports.
- Export endpoints generate CSV/PDF-ready payloads.
- The system preserves file metadata and project attachments.
