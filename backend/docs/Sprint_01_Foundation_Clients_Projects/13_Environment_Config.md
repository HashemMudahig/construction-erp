# 13 — Environment Configuration

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. .env Variables

`backend/.env` (git-ignored). `backend/.env.example` committed with placeholders.

| Variable | Required | Default | Example | Used by |
| --- | --- | --- | --- | --- |
| `DATABASE_URL` | yes | — | `postgresql+psycopg://erp:erp@localhost:5432/erp` | core.database |
| `JWT_SECRET` | yes | — | ≥32 random chars | core.security |
| `JWT_ALGORITHM` | no | `HS256` | `HS256` | core.security |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | no | `60` | `60` | core.security |
| `ADMIN_NAME` | yes | — | `Site Admin` | seed script |
| `ADMIN_EMAIL` | yes | — | `admin@example.com` | seed script |
| `ADMIN_PASSWORD` | yes | — | `S3cret!` | seed script |
| `CORS_ORIGINS` | no | `*` | `http://localhost:5173,https://erp.app` | main CORS |
| `LOG_LEVEL` | no | `INFO` | `DEBUG` | structlog |
| `APP_ENV` | no | `dev` | `prod` | toggles JSON logs |

`.env.example`:
```ini
DATABASE_URL=postgresql+psycopg://erp:erp@localhost:5432/erp
JWT_SECRET=change-me-please-32-chars-min
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
ADMIN_NAME=Site Admin
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=ChangeMe!
CORS_ORIGINS=http://localhost:5173
LOG_LEVEL=INFO
APP_ENV=dev
```

## 2. Settings loader (`core/config.py`)

```python
class Settings(BaseSettings):
    database_url: str
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    admin_name: str
    admin_email: EmailStr
    admin_password: str
    cors_origins: list[str] | str = "*"
    log_level: str = "INFO"
    app_env: str = "dev"
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False)

settings = Settings()
# validate JWT_SECRET length at import
assert len(settings.jwt_secret) >= 32, "JWT_SECRET too short"
```

## 3. docker-compose for PostgreSQL

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: erp
      POSTGRES_PASSWORD: erp
      POSTGRES_DB: erp
    ports: ["5432:5432"]
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U erp"]
      interval: 5s
      timeout: 3s
      retries: 10
volumes:
  pgdata:
```

Run: `docker compose up -d db`.

## 4. alembic.ini (key entries)

```ini
[alembic]
script_location = alembic
sqlalchemy.url = postgresql+psycopg://erp:erp@localhost:5432/erp
# overridden at runtime by env.py from settings.database_url
```

`alembic/env.py` imports `app.core.config.settings` and sets `config.set_main_option("sqlalchemy.url", settings.database_url)` so the live DB comes from `.env`, not the ini.

## 5. Local Run Steps (backend)

```bash
# 1. start DB
docker compose up -d db
# 2. create venv
python -m venv .venv
.venv\Scripts\activate            # Windows
pip install -r requirements.txt
# 3. configure env
copy .env.example .env            # then edit .env
# 4. apply schema
alembic upgrade head
# 5. seed admin
python scripts/seed_admin.py
# 6. run server
uvicorn app.main:app --reload --port 8000
```

Open `http://localhost:8000/api/v1/health` and `http://localhost:8000/docs` for OpenAPI.

## 6. Local Run Steps (Flutter)

```bash
cd frontend
flutter pub get
# set API base URL in lib/core/config/app_config.dart (dev = http://localhost:8000)
flutter run -d windows
```

## 7. Quick-Start Scripts

- `scripts/dev.bat` — start db, apply migrations, seed, run uvicorn.
- `scripts/seed_admin.py` — idempotent admin insert.
- `scripts/reset_db.py` — `alembic downgrade base && alembic upgrade head && seed`.

## 8. CI Notes

CI loads the same `.env` from repo secrets, runs `alembic upgrade head`, then `pytest`. Frontend build runs `flutter analyze` + `flutter test` on the widget smoke set.