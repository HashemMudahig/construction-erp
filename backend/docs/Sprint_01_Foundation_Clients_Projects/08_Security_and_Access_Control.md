# 08 — Security & Access Control

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Auth Model

- **Single administrative user.** No registration, no roles, no RBAC in v1.
- Auth = email + password → JWT access token (HS256).
- Token is supplied as `Authorization: Bearer <token>`.
- `OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")` is the FastAPI dependency applied to protected routers.
- No refresh tokens in S01; client re-logs on expiry.

## 2. Password Hashing

- bcrypt via `passlib[bcrypt]` (`CryptContext(schemes=["bcrypt"], deprecated="auto")`).
- Hash stored in `users.password_hash`. Plaintext password **never** logged, never returned, never persisted.
- Verification uses constant-time bcrypt compare.

## 3. Token Lifecycle

| Property | Source |
| --- | --- |
| Algorithm | `JWT_ALGORITHM` (default HS256) |
| Secret | `JWT_SECRET` (env, ≥32 chars) |
| TTL | `ACCESS_TOKEN_EXPIRE_MINUTES` (default 60) |
| Claim `sub` | user email |
| Claim `exp` | now + TTL |

`verify_token` raises `AUTH_TOKEN_EXPIRED` on `ExpSignatureError`/expired, `AUTH_TOKEN_INVALID` on `DecodeError`/bad signature.

## 4. Public vs Protected Endpoints

| Endpoint | Auth |
| --- | --- |
| `GET /api/v1/health`, `/health/db` | public |
| `POST /api/v1/auth/login` | public |
| All `/clients` and `/projects` routes | **protected** |

Missing token → 401 `AUTH_TOKEN_MISSING`; invalid/expired → 401 `AUTH_TOKEN_EXPIRED`/`AUTH_TOKEN_INVALID`.

## 5. CORS

`CORSMiddleware` configured from env `CORS_ORIGINS` (comma-separated allow-list). In production, only the Flutter app origin(s) are listed. Credentials not needed (bearer in header, not cookie). Preflight allowed for `/api/v1/*`.

```python
app.add_middleware(CORSMiddleware,
  allow_origins=settings.cors_origins,
  allow_methods=["GET","POST","PUT","DELETE","OPTIONS"],
  allow_headers=["Authorization","Content-Type"],
  allow_credentials=False)
```

## 6. Input Validation

- Pydantic v2 schemas validate body, query, and path params.
- `EmailStr` for emails; `Decimal` with `ge=0` for budget; enum for status.
- Route handlers receive already-validated DTOs; unprocessable → 422 `VALIDATION_ERROR`.

## 7. SQL Injection Prevention

- All data access via SQLAlchemy ORM with bound parameters. **No raw f-string SQL.**
- Search uses `Client.name.ilike(:pattern)` with bound param, never string interpolation.
- The only `op.execute` calls are for the extension and `updated_at` trigger (static DDL).

## 8. Secret Management

| Secret | Where | Notes |
| --- | --- | --- |
| `JWT_SECRET` | `.env` | generated, ≥32 chars, rotated out of band |
| `DATABASE_URL` | `.env` | includes password |
| `ADMIN_PASSWORD` | `.env` | used once by seed script |
| `CORS_ORIGINS` | `.env` | |

`.env` is git-ignored; `.env.example` committed with placeholders. In prod, secrets come from the hosting secret store, not files.

## 9. Other Hardening

- HTTPS terminated at reverse proxy; app behind it sets `X-Forwarded-Proto`.
- `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` added by middleware.
- Error responses never include stack traces (handled centrally).
- No password reset in v1 (out of scope).

## 10. Threats Considered (v1)

| Threat | Mitigation |
| --- | --- |
| Credential stuffing | Single account; bcrypt; consider rate-limit later |
| Token theft | Short TTL; HTTPS; no cookie storage |
| SQL injection | ORM only |
| Mass assignment | Explicit `*Update` schemas, no `__dict__` merge |
| IDOR | UUID PKs; single admin means all objects are theirs |