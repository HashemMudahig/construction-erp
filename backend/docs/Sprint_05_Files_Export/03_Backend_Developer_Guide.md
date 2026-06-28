# Sprint 05 — Backend Developer Guide

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Module Layout

```
app/
  routers/
    files.py          # NEW
    export.py         # NEW
  services/
    file_service.py   # NEW
    export_service.py # NEW
  repositories/
    file_repository.py # NEW
  models/
    file_model.py     # NEW
  schemas/
    file_schema.py    # NEW
    export_schema.py  # NEW
  core/
    config.py         # ADD: UPLOAD_DIR, MAX_FILE_SIZE_MB, ALLOWED_FILE_TYPES
```

## 2. Data Model — `FileModel`

```python
# app/models/file_model.py
class FileModel(Base):
    __tablename__ = "files"
    id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), primary_key=True, default=uuid4)
    project_id: Mapped[UUID] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"), index=True)
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_path: Mapped[str] = mapped_column(String(512), nullable=False)  # on-disk absolute path
    file_size: Mapped[int] = mapped_column(BigInteger, nullable=False)
    content_type: Mapped[str] = mapped_column(String(128), nullable=False)
    category: Mapped[FileCategory] = mapped_column(Enum(FileCategory), nullable=False)
    uploaded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
```

`FileCategory` enum: `contract`, `drawing`, `invoice`, `document`, `other`.

## 3. Schemas — `app/schemas/file_schema.py`

```python
class UploadResponse(BaseModel):
    file_id: UUID
    project_id: UUID
    file_name: str
    file_size: int
    content_type: str
    category: FileCategory
    uploaded_at: datetime

class FileMetadata(UploadResponse):
    pass  # same fields; used for list/download metadata
```

`app/schemas/export_schema.py` defines `ProjectExportPayload` (project + milestones + payments + expenses) reusing Sprint 04 schemas.

## 4. FileService — `app/services/file_service.py`

Responsibilities:
- `save_upload(file: UploadFile, project_id, category) -> UploadResponse`
  - Validate size (`<= MAX_FILE_SIZE_MB * 1024 * 1024`).
  - Validate content type / extension against `ALLOWED_FILE_TYPES`.
  - Sanitize `file.filename` (strip path components, control chars).
  - Build on-disk path: `{UPLOAD_DIR}/{project_id}/{file_id}-{safe_name}`.
  - Ensure parent dir exists; write bytes (streamed, not full buffer).
  - Insert `FileModel` row; commit; return `UploadResponse`.
- `get_file_path(file_id) -> Path` — returns on-disk path; raises `FILE_NOT_FOUND` if missing.
- `stream_download(file_id) -> FileResponse` — returns `FileResponse(path, media_type=content_type, filename=file_name)`.
- `delete_file(file_id)` — delete disk file, then DB row in a transaction; rollback re-uploads on DB failure (best-effort; see ADR-S05-05).

### Path Safety

```python
safe_name = secure_filename(file.filename)  # strip ../, \, control chars
disk_path = (UPLOAD_DIR / str(project_id) / f"{file_id}-{safe_name}").resolve()
if not str(disk_path).startswith(str(UPLOAD_DIR.resolve())):
    raise PathTraversalBlocked()
```

## 5. ExportService — `app/services/export_service.py`

- `export_report_csv(report_type: str) -> StreamingResponse`
  - Calls `ReportRepository` aggregation (same as Sprint 04 `/reports/{type}`).
  - Builds CSV header + rows via generator; yields chunks.
  - Returns `StreamingResponse(generator, media_type="text/csv", headers={"Content-Disposition": f"attachment; filename={report_type}.csv"})`.
- `export_project_payload(project_id) -> ProjectExportPayload`
  - Fetches project, milestones, payments, expenses (Sprint 01-03 repositories).
  - Returns a single nested structure suitable for client-side PDF rendering.

## 6. Routers

### `app/routers/files.py`

```python
@router.post("/upload", response_model=Envelope[UploadResponse], status_code=201)
async def upload_file(
    file: UploadFile = File(...),
    project_id: UUID = Form(...),
    category: FileCategory = Form(...),
    _: dict = Depends(require_admin),  # JWT
) -> dict:
    result = await file_service.save_upload(file, project_id, category)
    return {"success": True, "message": "File uploaded", "data": result}

@router.get("/{file_id}")
async def download_file(file_id: UUID, _: dict = Depends(require_admin)):
    return await file_service.stream_download(file_id)

@router.delete("/{file_id}", status_code=204)
async def delete_file(file_id: UUID, _: dict = Depends(require_admin)):
    await file_service.delete_file(file_id)

@router.get("/", response_model=Envelope[List[FileMetadata]])
async def list_files(project_id: UUID = Query(...), _: dict = Depends(require_admin)):
    ...
```

### `app/routers/export.py`

```python
@router.get("/reports")
async def export_reports(type: str, format: str = "csv", _: dict = Depends(require_admin)):
    if format != "csv":
        raise ExportUnavailable()
    return await export_service.export_report_csv(type)

@router.get("/projects/{project_id}", response_model=Envelope[ProjectExportPayload])
async def export_project(project_id: UUID, _: dict = Depends(require_admin)):
    payload = await export_service.export_project_payload(project_id)
    return {"success": True, "message": "Project export payload", "data": payload}
```

## 7. Validation Rules

| Rule | Implementation |
| --- | --- |
| Max size | `len(await file.read())` not used (memory); instead stream to disk with running counter; abort if exceeds `MAX_FILE_SIZE_MB`. |
| Allowed types | Compare `file.content_type` and extension against `ALLOWED_FILE_TYPES`. |
| Project exists | `project_repository.get(project_id)`; raise `PROJECT_NOT_FOUND` if missing. |
| Path safety | `secure_filename` + prefix check on resolved path. |
| JWT | `require_admin` dependency on every endpoint. |

## 8. Error Mapping

See `10_Error_Codes_and_Response_Standards.md` for the full table. Key points:
- `413` for oversized uploads.
- `400` for invalid type / missing project.
- `404` for missing file or project.
- `401` for missing/invalid JWT.

## 9. Notes

- Use `UploadFile` from `fastapi` (SpooledTemporaryFile). For very large files, configure `app.max_request_size` at the ASGI server (uvicorn/gunicorn) to reject early.
- `FileResponse` streams the file from disk without loading it into memory.
- CSV must include a UTF-8 BOM (`\ufeff`) at the start so Excel detects encoding correctly.