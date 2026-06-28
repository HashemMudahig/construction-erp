# Sprint 05 — Database Schema (PostgreSQL)

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. New Table — `files`

Stores metadata for project file attachments. Actual file bytes live on disk.

```sql
CREATE TYPE file_category AS ENUM ('contract', 'drawing', 'invoice', 'document', 'other');

CREATE TABLE files (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id    UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    file_name     VARCHAR(255) NOT NULL,
    file_path     VARCHAR(512) NOT NULL,        -- absolute on-disk path
    file_size     BIGINT NOT NULL,               -- bytes
    content_type  VARCHAR(128) NOT NULL,
    category      file_category NOT NULL,
    uploaded_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_files_project_id ON files(project_id);
CREATE INDEX idx_files_uploaded_at ON files(uploaded_at DESC);
```

## 2. Column Notes

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID PK | `gen_random_uuid()` default; returned as `file_id` in API. |
| `project_id` | UUID FK | `ON DELETE CASCADE` so deleting a project removes file metadata. Disk files are removed by the service via cascade hook or async cleanup. |
| `file_name` | VARCHAR(255) | Sanitized original filename as provided by the user. |
| `file_path` | VARCHAR(512) | Absolute on-disk path: `{UPLOAD_DIR}/{project_id}/{file_id}-{safe_name}`. |
| `file_size` | BIGINT | Bytes; supports files up to ~9 EB. |
| `content_type` | VARCHAR(128) | MIME type from upload; validated against allowlist. |
| `category` | enum | Business classification of the attachment. |
| `uploaded_at` | TIMESTAMPTZ | UTC; defaults to `now()`. |

## 3. Index Strategy

| Index | Purpose |
| --- | --- |
| `idx_files_project_id` | Fast lookup of files for a project (used by `GET /files?project_id=`). |
| `idx_files_uploaded_at` | Chronological listing / cleanup queries. |

The primary key on `id` is indexed automatically.

## 4. Disk Storage Layout

```
{UPLOAD_DIR}/                      # e.g. ./uploads
  {project_id}/                    # one folder per project
    {file_id}-{sanitized_name}     # UUID prefix guarantees uniqueness + path safety
```

Example:
```
uploads/b2a4-...-0c11/9d1c-...-e7f3-contract_v3.pdf
```

Rules:
- `project_id` folder is created on first upload for that project.
- UUID prefix in filename prevents collisions even if the same original name is uploaded twice.
- Sanitized name strips path separators (`/`, `\`) and control characters.

## 5. Alembic Migration Plan

Create a new revision:

```bash
alembic revision -m "s05_create_files_table"
```

Migration body (sketch):

```python
def upgrade():
    op.execute("CREATE TYPE file_category AS ENUM ('contract','drawing','invoice','document','other')")
    op.create_table(
        "files",
        sa.Column("id", PG_UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("project_id", PG_UUID(as_uuid=True), sa.ForeignKey("projects.id", ondelete="CASCADE"), nullable=False),
        sa.Column("file_name", sa.String(255), nullable=False),
        sa.Column("file_path", sa.String(512), nullable=False),
        sa.Column("file_size", sa.BigInteger, nullable=False),
        sa.Column("content_type", sa.String(128), nullable=False),
        sa.Column("category", sa.Enum("contract","drawing","invoice","document","other", name="file_category"), nullable=False),
        sa.Column("uploaded_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("idx_files_project_id", "files", ["project_id"])
    op.create_index("idx_files_uploaded_at", "files", [sa.text("uploaded_at DESC")])

def downgrade():
    op.drop_index("idx_files_uploaded_at", table_name="files")
    op.drop_index("idx_files_project_id", table_name="files")
    op.drop_table("files")
    op.execute("DROP TYPE file_category")
```

Apply:

```bash
alembic upgrade head
```

## 6. Data Integrity Rules

| Rule | Enforcement |
| --- | --- |
| `project_id` must exist | FK constraint; upload service also validates before disk write. |
| File size > 0 | Service check (zero-byte files rejected). |
| `file_path` unique | UUID prefix guarantees uniqueness; no DB unique constraint needed. |
| Delete cascade | FK `ON DELETE CASCADE`; service also removes disk file. |

## 7. Cleanup Considerations

- On project deletion, the DB cascade removes metadata; disk files should be removed by a post-delete hook or scheduled cleanup job comparing `files` table to the `UPLOAD_DIR`.
- Orphaned disk files (from failed transactions) are detected by a weekly reconciliation job — out of scope for v1 but noted for Phase 2.