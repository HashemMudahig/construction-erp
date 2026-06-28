# Sprint 05 Implementation: File Attachments & Export

## 1. Backend implementation details

### Folder structure
- `app/routers/files.py`: file upload and download endpoints.
- `app/routers/export.py`: export endpoints.
- `app/services/file_service.py`: handles file storage abstractions.
- `app/services/export_service.py`: exports data into CSV or PDF-ready payloads.
- `app/models/`: add file metadata model.

### Models
- `FileAttachment`: stores file name, type, size, project relationship, uploaded timestamp, and storage path.
- Optional `ExportJob`: stores metadata for export requests.

### Schemas
- `FileAttachmentRead`
- `ExportRequestRead`
- `ExportResponseRead`

### Routers
- `files` router for upload/download/delete operations.
- `export` router for report and project exports.

## 2. API endpoints implemented
- `POST /files/upload`
- `GET /files/{file_id}`
- `DELETE /files/{file_id}`
- `GET /export/reports`
- `GET /export/projects/{project_id}`

## 3. Database schema changes
- Add `files` table for attachment metadata.
- Add `exports` table if tracking export requests is required.

## 4. Flutter screens
- File attachment list and upload UI.
- Export options screen for reports and project data.
- Download progress and status details.

## 5. Testing notes
- Validate file upload and retrieval workflows.
- Confirm file metadata persistence and cleanup on delete.
- Test CSV/PDF export payloads and download links.

## 6. Completed vs not completed
- Completed: backend metadata and API contract for attachments and exports.
- Not completed: full production-ready file storage, export generation engine, and frontend integration for downloads.
