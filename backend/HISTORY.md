# Backend History

This file records notable updates made to the Construction ERP backend.

## 2026-06-28

### Skeleton Stabilization

- Filled `app/core/config.py` with Pydantic Settings reading from `.env`.
- Filled `app/core/database.py` with a synchronous SQLAlchemy engine, session, and `Base`.
- Added `app/core/security.py` with JWT create/verify and bcrypt password hashing.
- Replaced the bare `app/main.py` stub with a runnable FastAPI app: CORS, health endpoints, `/api/v1` router mount, and standard response helpers.
- Added `app/utils/` package with pagination and date helpers.
- Added `app/db/` package with `seed.py` for the single admin account.
- Added `__init__.py` files to all `app/` subpackages.
- Added Alembic config and migration environment wired to `app.core.database.Base`.

### Infrastructure

- Added `.gitignore`, `.env.example`, `docker-compose.yml` for local PostgreSQL.
- Added `scripts/run_dev.bat` and `scripts/run_dev.sh`.
- Added `tests/` package skeleton.
- Updated `requirements.txt` with passlib[bcrypt], python-jose, python-multipart, and pytest.

### Verification

- `python -c "import app.main"` succeeds.
- `alembic check` validates the migration environment.