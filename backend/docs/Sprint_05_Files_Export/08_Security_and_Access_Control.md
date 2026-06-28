# Sprint 05 — Security & Access Control

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Authentication

All file and export endpoints require a valid JWT bearer token via the existing `require_admin` dependency introduced in Sprint 01.

| Endpoint | Auth |
| --- | --- |
| `POST /files/upload` | JWT required |
| `GET /files/{id}` | JWT required |
| `DELETE /files/{id}` | JWT required |
| `GET /files?project_id=` | JWT required |
| `GET /export/reports` | JWT required |
| `GET /export/projects/{id}` | JWT required |

Tokens are issued by `POST /auth/login` (bcrypt-hashed password check). No anonymous access. No file-level ACLs (single admin user).

## 2. Path Traversal Prevention

The single highest-risk vector in a file-upload system is path traversal (`../../etc/passwd`). Mitigations:

1. **Sanitize filename** — use a `secure_filename()` helper that strips:
   - Path separators (`/`, `\`).
   - Leading dots / `..` segments.
   - Control characters (`\x00`–`\x1f`).
   - Reserved names on Windows (`CON`, `PRN`, `AUX`, `NUL`, `COM1`…).
2. **UUID-based on-disk path** — the actual stored filename is `{file_id}-{safe_name}`, where `file_id` is a server-generated UUID. Even if the user-supplied name is malicious, the UUID prefix keeps the file inside the project folder.
3. **Resolved-path prefix check** — after building the path, resolve it and verify it starts with `UPLOAD_DIR.resolve()`. If not, raise `PATH_TRAVERSAL_BLOCKED` and log an alert.

```python
disk_path = (UPLOAD_DIR / str(project_id) / f"{file_id}-{safe_name}").resolve()
if not disk_path.is_relative_to(UPLOAD_DIR.resolve()):
    log_alert("path_traversal_blocked", filename=file.filename)
    raise PathTraversalBlocked()
```

## 3. File Size Enforcement

- Configured via `MAX_FILE_SIZE_MB` (default 25).
- Enforced in `FileService` by streaming bytes to disk with a running counter. If the counter exceeds the limit, the partial file is removed and `FILE_TOO_LARGE (413)` is returned.
- Additionally, the ASGI server (uvicorn/gunicorn) is configured with a request body size limit slightly above `MAX_FILE_SIZE_MB` to reject pathological uploads early.

## 4. Allowed Content-Type Whitelist

Configured via `ALLOWED_FILE_TYPES` (default: `pdf,png,jpg,jpeg,xlsx,docx,csv`).

Validation logic:
- Extract extension from `file.filename`.
- Check both extension and `file.content_type` against the allowlist.
- Reject if either is missing or not in the list → `INVALID_FILE_TYPE (400)`.

Rationale: validating both prevents MIME-spoofing of the extension while keeping the UX friendly.

## 5. No Execution of Uploaded Files

- `UPLOAD_DIR` is **outside** the FastAPI static file path. Files are never served as static assets.
- The only way to retrieve a file is through `GET /files/{id}`, which requires JWT and streams via `FileResponse` with the stored `content_type`.
- The uploads directory must not be executable and should not be inside the application's source tree.
- Recommended: configure the deployment web server (nginx/caddy) to never serve `UPLOAD_DIR` directly.

## 6. Authenticated File Serving

| Concern | Mitigation |
| --- | --- |
| Public URL access | None. No static mount for `UPLOAD_DIR`. |
| Direct disk access | Only backend process has filesystem permissions. |
| Guessing file IDs | UUID v4 — 122 bits of entropy; not enumerable. |
| Download by unauthenticated user | `require_admin` dependency on `GET /files/{id}`. |
| IDOR (insecure direct object reference) | Not applicable — single admin user sees all files. |

## 7. Export Endpoints

CSV and project payload endpoints reuse the standard JWT dependency. No additional restrictions beyond authentication; the single admin may export any project's data.

## 8. Input Validation Summary

| Input | Validation |
| --- | --- |
| `project_id` | must be a UUID and reference an existing project |
| `category` | must be one of the enum values |
| `file.filename` | sanitized; length ≤ 255 after sanitization |
| `file.content_type` | in allowlist |
| `file` bytes | size ≤ `MAX_FILE_SIZE_MB` |
| `report type` | in `{project_status, financial_summary, expense_analysis}` |
| `format` | must be `csv` (only supported value in v1) |

## 9. Threat Model (Simplified)

| Threat | Likelihood | Impact | Control |
| --- | --- | --- | --- |
| Path traversal upload | Medium | Critical | Sanitize + UUID path + prefix check |
| Oversized upload DoS | Medium | High | Size limit at service + ASGI |
| Malicious file type execution | Low | High | Whitelist + no static serving |
| Unauthenticated download | Low | High | JWT on endpoint |
| CSRF on delete | Low | Medium | JWT in Authorization header (not cookie) |
| Information leak via error | Low | Medium | Standard error envelope, no stack traces in prod |

## 10. Operational Hardening (Deployment)

- Run the backend process as a non-root user.
- Set `UPLOAD_DIR` permissions to `750` (owner read/write, group read).
- Back up `UPLOAD_DIR` alongside the database (see `13_Environment_Config.md`).
- Enable request body size limit at the reverse proxy (`client_max_body_size 30m;` in nginx).