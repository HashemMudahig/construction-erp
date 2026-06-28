# 03 — Backend Developer Guide

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Folder Structure

```
backend/
  app/
    __init__.py
    main.py
    core/
      config.py          # pydantic-settings BaseSettings
      database.py        # engine, SessionLocal, get_db
      security.py        # jwt create/verify, bcrypt
      response.py        # success(), error() envelope helpers
    models/
      base.py            # DeclarativeBase
      user.py
      client.py
      project.py
    schemas/
      auth.py            # LoginRequest, TokenResponse
      client.py          # ClientCreate/Read/Update
      project.py         # ProjectCreate/Read/Update
    repositories/
      base.py
      client_repo.py
      project_repo.py
    services/
      auth_service.py
      client_service.py
      project_service.py
    routers/
      health.py
      auth.py
      clients.py
      projects.py
  alembic/
    versions/
  alembic.ini
  .env
  tests/
```

## 2. Models

### User
| Field | Type | Notes |
| --- | --- | --- |
| id | UUID PK | `gen_random_uuid()` |
| name | String(120) | |
| email | String(255) | unique, indexed |
| password_hash | String(255) | bcrypt |
| role | String(20) | default `'admin'` |
| created_at | TIMESTAMP TZ | UTC |

### Client
| Field | Type | Notes |
| --- | --- | --- |
| id | UUID PK | |
| name | String(200) | required |
| phone | String(40) | nullable |
| email | String(255) | nullable |
| address | String(500) | nullable |
| notes | Text | nullable |
| archived | Boolean | default false |
| created_at | TIMESTAMP TZ | |
| updated_at | TIMESTAMP TZ | |

### Project
| Field | Type | Notes |
| --- | --- | --- |
| id | UUID PK | |
| client_id | UUID FK -> clients.id | required, indexed |
| name | String(200) | required |
| description | Text | nullable |
| budget | Numeric(14,2) | required |
| start_date | Date | nullable |
| end_date | Date | nullable |
| status | Enum | planning/active/completed/on_hold/cancelled |
| created_at | TIMESTAMP TZ | |

## 3. Schemas (Pydantic v2)

```python
# schemas/auth.py
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

# schemas/client.py
class ClientBase(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    phone: str | None = None
    email: EmailStr | None = None
    address: str | None = None
    notes: str | None = None
    archived: bool = False

class ClientCreate(ClientBase): ...
class ClientUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    phone: str | None = None
    email: EmailStr | None = None
    address: str | None = None
    notes: str | None = None
    archived: bool | None = None
class ClientRead(ClientBase):
    id: UUID
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

# schemas/project.py
class ProjectBase(BaseModel):
    client_id: UUID
    name: str = Field(min_length=1, max_length=200)
    description: str | None = None
    budget: Decimal = Field(ge=0, max_digits=14, decimal_places=2)
    start_date: date | None = None
    end_date: date | None = None
    status: Literal["planning","active","completed","on_hold","cancelled"] = "planning"
class ProjectCreate(ProjectBase): ...
class ProjectUpdate(BaseModel):
    client_id: UUID | None = None
    name: str | None = None
    description: str | None = None
    budget: Decimal | None = Field(default=None, ge=0, max_digits=14, decimal_places=2)
    start_date: date | None = None
    end_date: date | None = None
    status: Literal["planning","active","completed","on_hold","cancelled"] | None = None
class ProjectRead(ProjectBase):
    id: UUID
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
```

## 4. Repositories

Repositories are thin SQLAlchemy wrappers. `BaseRepository` provides `get`, `list`, `create`, `update`, `delete`. `ClientRepository.list(search: str | None, skip, limit)` filters by `ilike(name)`. `ProjectRepository.list(client_id=None, status=None, skip, limit)`.

## 5. Services

- `AuthService.login(email, password)` → verifies bcrypt, issues JWT.
- `ClientService.create/update/delete` — enforces business rules; `delete` blocks when linked projects exist.
- `ProjectService.create/update` — verifies `client_id` exists (raises `PROJECT_CLIENT_INVALID`).

## 6. Routers

Routers are thin: parse body/path, call service, wrap result with `core.response.success(...)` or raise an `AppException` mapped to the error envelope.

## 7. Auth

- `OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")` dependency.
- `create_access_token(sub=email)` → JWT with `exp` from `ACCESS_TOKEN_EXPIRE_MINUTES`.
- `verify_token(token)` → returns email or raises `AUTH_TOKEN_EXPIRED`/`AUTH_TOKEN_INVALID`.
- Password hashing: `passlib[bcrypt]`, `CryptContext(schemes=["bcrypt"])`.

## 8. Endpoint List

| Method | Path | Auth | Request | Response (data) |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/auth/login` | no | `LoginRequest` | `TokenResponse` |
| GET | `/api/v1/clients` | yes | query: search, skip, limit | `list[ClientRead]` |
| POST | `/api/v1/clients` | yes | `ClientCreate` | `ClientRead` |
| GET | `/api/v1/clients/{id}` | yes | — | `ClientRead` |
| PUT | `/api/v1/clients/{id}` | yes | `ClientUpdate` | `ClientRead` |
| DELETE | `/api/v1/clients/{id}` | yes | — | `{"id": "..."}` |
| GET | `/api/v1/projects` | yes | query: client_id, status, skip, limit | `list[ProjectRead]` |
| POST | `/api/v1/projects` | yes | `ProjectCreate` | `ProjectRead` |
| GET | `/api/v1/projects/{id}` | yes | — | `ProjectRead` |
| PUT | `/api/v1/projects/{id}` | yes | `ProjectUpdate` | `ProjectRead` |
| DELETE | `/api/v1/projects/{id}` | yes | — | `{"id": "..."}` |

## 9. Validation Rules

- Email fields use Pydantic `EmailStr`.
- `budget >= 0`; `max_digits=14, decimal_places=2`.
- Project `status` constrained to enum; default `planning`.
- `end_date >= start_date` when both present.
- `name` non-empty on client and project create.