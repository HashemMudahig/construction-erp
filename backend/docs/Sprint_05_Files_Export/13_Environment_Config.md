# Sprint 05 — Environment Configuration

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. New Environment Variables

Add to `app/core/config.py` (Pydantic Settings) and to `.env`:

| Variable | Default | Description |
| --- | --- | --- |
| `UPLOAD_DIR` | `./uploads` | Absolute or relative path to the root upload directory. Resolved at startup. |
| `MAX_FILE_SIZE_MB` | `25` | Maximum upload size in megabytes. Enforced in `FileService` + ASGI body limit. |
| `ALLOWED_FILE_TYPES` | `pdf,png,jpg,jpeg,xlsx,docx,csv` | Comma-separated allowed extensions. |

```python
# app/core/config.py
class Settings(BaseSettings):
    # ... existing ...
    UPLOAD_DIR: Path = Path("./uploads")
    MAX_FILE_SIZE_MB: int = 25
    ALLOWED_FILE_TYPES: str = "pdf,png,jpg,jpeg,xlsx,docx,csv"

    @property
    def allowed_types(self) -> set[str]:
        return {t.strip().lower() for t in self.ALLOWED_FILE_TYPES.split(",")}

    @property
    def max_file_size_bytes(self) -> int:
        return self.MAX_FILE_SIZE_MB * 1024 * 1024
```

`.env` example:

```
UPLOAD_DIR=/var/lib/construction-erp/uploads
MAX_FILE_SIZE_MB=25
ALLOWED_FILE_TYPES=pdf,png,jpg,jpeg,xlsx,docx,csv
```

## 2. Disk Storage Layout

```
{UPLOAD_DIR}/
  {project_id}/
    {file_id}-{sanitized_filename}
```

- `UPLOAD_DIR` is created on application startup if it does not exist (`mkdir -p`).
- Per-project subdirectories are created on first upload for that project.
- Permissions: `750` (owner rwx, group r-x, others none). Backend process owns the directory.
- Do **not** place `UPLOAD_DIR` inside the application source tree or static assets folder.

## 3. ASGI / Reverse Proxy Configuration

| Layer | Setting | Value |
| --- | --- | --- |
| uvicorn / gunicorn | `--limit-max-requests` | optional |
| ASGI body limit | configure slightly above `MAX_FILE_SIZE_MB` | e.g. 30 MB |
| nginx | `client_max_body_size` | `30m;` |
| nginx | `proxy_read_timeout` | `120s;` (large uploads) |
| nginx | static mount for `UPLOAD_DIR` | **none** (files served only via API) |

## 4. Backup Considerations

The `UPLOAD_DIR` is part of the system's persistent data and must be backed up alongside the PostgreSQL database.

| Item | Strategy |
| --- | --- |
| Database | nightly pg_dump (existing) |
| `UPLOAD_DIR` | nightly rsync to backup volume; retain 7 daily + 4 weekly snapshots |
| Restore test | quarterly restore test of DB + uploads |

Because `file_path` in DB stores absolute paths, the backup/restore target must keep the same `UPLOAD_DIR` path, or a migration script must rewrite `file_path` values after restore. Alternative: store `file_path` as project-relative and join with `UPLOAD_DIR` at read time (recommended for portability — note for v1.1).

## 5. Logging Configuration

No new log sinks; Sprint 05 events flow through the existing logger. Ensure:
- JSON structured output to stdout (container-friendly).
- Audit events routed to the audit sink (file or audit table) configured in Sprint 01.
- Alert channel (email/Slack) configured for `PATH_TRAVERSAL_BLOCKED` and `DiskUsageHigh`.

## 6. Environment Matrix

| Env | UPLOAD_DIR | MAX_FILE_SIZE_MB | Notes |
| --- | --- | --- | --- |
| Local dev | `./uploads` | 25 | gitignored |
| CI | `tmp/` per test run | 5 | tests create/teardown |
| Staging | `/var/lib/erp/uploads` | 25 | backed up nightly |
| Production | `/var/lib/erp/uploads` | 25 | backed up nightly + monitored |

## 7. Startup Validation

On application startup, `FileService.__init__` should:
1. Resolve `UPLOAD_DIR` and ensure it exists (create if missing).
2. Ensure the process has write permission (fail fast otherwise).
3. Log the resolved path and size limit.

```python
def ensure_upload_dir():
    settings.UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    if not os.access(settings.UPLOAD_DIR, os.W_OK):
        raise RuntimeError(f"UPLOAD_DIR not writable: {settings.UPLOAD_DIR}")
```

## 8. Frontend Constants

The Flutter app does not need `UPLOAD_DIR` (downloads are saved via `path_provider`). It only needs:
- `Endpoints` (see `04_Frontend_Developer_Guide.md`).
- The max file size (to show a client-side hint before upload) — read from a `/meta` endpoint or hardcoded as 25 MB with a comment to keep in sync.

## 9. Secrets

No new secrets in this sprint. JWT signing key already managed in Sprint 01. `UPLOAD_DIR` is a path, not a secret.