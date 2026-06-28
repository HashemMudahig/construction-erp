# Sprint 05 — Error Codes & Response Standards

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Error Envelope

All non-2xx responses use the standard envelope introduced in Sprint 01:

```json
{
  "success": false,
  "message": "Human-readable summary",
  "errors": [
    { "code": "FILE_TOO_LARGE", "field": "file", "detail": "Size 30MB exceeds limit 25MB" }
  ]
}
```

Binary endpoints (`GET /files/{id}` download, `GET /export/reports` CSV) cannot return this envelope on error after headers are sent; therefore size/type validation happens **before** the streaming response starts, and errors are returned as JSON with the appropriate status code.

## 2. Error Codes

| Code | HTTP | Meaning |
| --- | --- | --- |
| `FILE_NOT_FOUND` | 404 | No file with the given `file_id` exists (or its disk file is missing). |
| `PROJECT_NOT_FOUND` | 400 / 404 | `project_id` does not reference an existing project. (400 when supplied as form/query param; 404 when in URL path for export.) |
| `FILE_TOO_LARGE` | 413 | Uploaded file exceeds `MAX_FILE_SIZE_MB`. |
| `INVALID_FILE_TYPE` | 400 | Extension or content-type not in `ALLOWED_FILE_TYPES`. |
| `UPLOAD_FAILED` | 500 | Disk write failed, DB insert failed, or delete failed. |
| `EXPORT_UNAVAILABLE` | 400 | Invalid `type` or unsupported `format` requested. |
| `PATH_TRAVERSAL_BLOCKED` | 400 | Sanitized filename resolves outside `UPLOAD_DIR`. |
| `UNAUTHENTICATED` | 401 | Missing/invalid JWT. |
| `VALIDATION_ERROR` | 400 | Missing required form field, invalid UUID, invalid category enum. |

## 3. Status Code Mapping

| Status | Used For |
| --- | --- |
| 200 | Download, list, CSV export, project export payload |
| 201 | Upload created |
| 204 | Delete success (no body) |
| 400 | Validation error, invalid type, path traversal, project not found (form) |
| 401 | Missing/invalid JWT |
| 404 | File not found, project not found (path) |
| 413 | File too large |
| 500 | Disk/DB failure |

## 4. Example Error Envelopes

### 413 — File Too Large

```json
{
  "success": false,
  "message": "File too large",
  "errors": [
    { "code": "FILE_TOO_LARGE", "field": "file", "detail": "Size 30MB exceeds limit 25MB" }
  ]
}
```

### 400 — Invalid File Type

```json
{
  "success": false,
  "message": "Unsupported file type",
  "errors": [
    { "code": "INVALID_FILE_TYPE", "field": "file", "detail": "Extension 'exe' not allowed. Allowed: pdf, png, jpg, jpeg, xlsx, docx, csv" }
  ]
}
```

### 404 — File Not Found

```json
{
  "success": false,
  "message": "File not found",
  "errors": [
    { "code": "FILE_NOT_FOUND", "field": "file_id", "detail": "No file with id 9d1c-...-e7f3" }
  ]
}
```

### 400 — Path Traversal Blocked

```json
{
  "success": false,
  "message": "Path traversal blocked",
  "errors": [
    { "code": "PATH_TRAVERSAL_BLOCKED", "field": "file", "detail": "Filename resolves outside upload directory" }
  ]
}
```

### 400 — Export Unavailable

```json
{
  "success": false,
  "message": "Export unavailable",
  "errors": [
    { "code": "EXPORT_UNAVAILABLE", "field": "type", "detail": "Unknown report type 'xyz'. Allowed: project_status, financial_summary, expense_analysis" }
  ]
}
```

### 500 — Upload Failed

```json
{
  "success": false,
  "message": "Upload failed",
  "errors": [
    { "code": "UPLOAD_FAILED", "detail": "Disk write error: No space left on device" }
  ]
}
```

## 5. Field-Level Validation Errors

Multiple validation issues are returned together:

```json
{
  "success": false,
  "message": "Validation error",
  "errors": [
    { "code": "VALIDATION_ERROR", "field": "project_id", "detail": "Field required" },
    { "code": "VALIDATION_ERROR", "field": "category", "detail": "Value is not a valid enum member" }
  ]
}
```

## 6. Streaming Errors

Once a streaming response (download or CSV) has started sending bytes, the server cannot switch to a JSON error. Mitigations:

- All checks (file exists, type valid, project exists) run **before** the first byte is streamed.
- If a disk error occurs mid-stream, the connection is closed; the client sees a truncated download. Such failures are logged at ERROR level and counted in `upload_failed` / metrics.

## 7. Idempotency

- Uploads are **not** idempotent (same file twice creates two records).
- Deletes are effectively idempotent: deleting a non-existent file returns `404 FILE_NOT_FOUND`; re-deleting is not a 204. (Consistent with REST semantics.)

## 8. Localization

Error `message` is English in v1. Error `code` is stable and machine-readable; the frontend maps codes to localized strings if needed.