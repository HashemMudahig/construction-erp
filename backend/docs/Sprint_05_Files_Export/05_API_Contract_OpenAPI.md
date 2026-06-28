# Sprint 05 — API Contract / OpenAPI

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

All endpoints are prefixed with `/api/v1`. All require `Authorization: Bearer <JWT>`.

## 1. POST /files/upload

Multipart form upload. Stores file to disk + metadata in DB.

**Request** — `multipart/form-data`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `file` | binary | yes | the file bytes |
| `project_id` | UUID | yes | must reference an existing project |
| `category` | enum | yes | `contract \| drawing \| invoice \| document \| other` |

**Headers**

```
Authorization: Bearer <jwt>
Content-Type: multipart/form-data; boundary=...
```

**Response 201**

```json
{
  "success": true,
  "message": "File uploaded",
  "data": {
    "file_id": "9d1c...e7f3",
    "project_id": "b2a4...0c11",
    "file_name": "contract_v3.pdf",
    "file_size": 1048576,
    "content_type": "application/pdf",
    "category": "contract",
    "uploaded_at": "2026-09-02T10:15:30Z"
  }
}
```

**Errors**

| Status | Code | Condition |
| --- | --- | --- |
| 400 | `INVALID_FILE_TYPE` | extension/content-type not in allowlist |
| 400 | `PROJECT_NOT_FOUND` | `project_id` does not exist |
| 401 | `UNAUTHENTICATED` | missing/invalid JWT |
| 413 | `FILE_TOO_LARGE` | size > `MAX_FILE_SIZE_MB` |
| 400 | `PATH_TRAVERSAL_BLOCKED` | sanitized filename escapes UPLOAD_DIR |
| 500 | `UPLOAD_FAILED` | disk write or DB insert failed |

## 2. GET /files/{file_id}

Streams file bytes.

**Response 200**

```
Content-Type: application/pdf
Content-Disposition: attachment; filename="contract_v3.pdf"
<binary stream>
```

**Errors**: 404 `FILE_NOT_FOUND`, 401 `UNAUTHENTICATED`.

## 3. DELETE /files/{file_id}

Removes disk file + metadata.

**Response 204** — no body.

**Errors**: 404 `FILE_NOT_FOUND`, 401 `UNAUTHENTICATED`, 500 `UPLOAD_FAILED` (delete error).

## 4. GET /files

List metadata for a project (no bytes).

**Query**

| Param | Type | Required | Default |
| --- | --- | --- | --- |
| `project_id` | UUID | yes | — |

**Response 200**

```json
{
  "success": true,
  "message": "Files",
  "data": [
    { "file_id": "...", "file_name": "drawing.dwg", "file_size": 524288, "content_type": "application/acad", "category": "drawing", "uploaded_at": "..." }
  ]
}
```

**Errors**: 401, 404 `PROJECT_NOT_FOUND`.

## 5. GET /export/reports

CSV stream of a report.

**Query**

| Param | Type | Required | Values |
| --- | --- | --- | --- |
| `type` | string | yes | `project_status \| financial_summary \| expense_analysis` |
| `format` | string | no (default `csv`) | `csv` |

**Response 200**

```
Content-Type: text/csv; charset=utf-8
Content-Disposition: attachment; filename="project_status.csv"

project_id,name,status,start_date,end_date,progress_pct
b2a4-...,Site A,active,2026-01-01,2026-12-31,45
...
```

CSV starts with UTF-8 BOM (`\ufeff`) for Excel compatibility.

**Errors**: 400 `EXPORT_UNAVAILABLE` (invalid type/format), 401.

## 6. GET /export/projects/{project_id}

PDF-ready structured payload.

**Response 200**

```json
{
  "success": true,
  "message": "Project export payload",
  "data": {
    "project": { "id": "...", "name": "Site A", "status": "active", "budget": 1500000.00, "start_date": "2026-01-01", "end_date": "2026-12-31" },
    "milestones": [ { "id": "...", "name": "Foundation", "due_date": "2026-03-01", "completed": true } ],
    "payments":   [ { "id": "...", "amount": 250000.00, "date": "2026-02-15", "status": "received" } ],
    "expenses":   [ { "id": "...", "category": "materials", "amount": 80000.00, "date": "2026-02-20" } ],
    "summary": { "total_paid": 250000.00, "total_expenses": 80000.00, "remaining_budget": 1420000.00 }
  }
}
```

**Errors**: 404 `PROJECT_NOT_FOUND`, 401.

## 7. Status Code Summary

| Code | Meaning |
| --- | --- |
| 200 | OK (download, list, CSV, export payload) |
| 201 | Created (upload) |
| 204 | No Content (delete) |
| 400 | Bad Request (invalid type, project missing, path traversal) |
| 401 | Unauthenticated |
| 404 | File/Project not found |
| 413 | Payload too large |
| 500 | Server error (disk/DB failure) |