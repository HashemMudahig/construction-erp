# 07 — Service Workflows

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Login Flow

```mermaid
sequenceDiagram
  participant U as Flutter
  participant R as auth router
  participant S as AuthService
  participant RE as UserRepository
  participant SEC as core.security
  U->>R: POST /auth/login {email,password}
  R->>S: login(email,password)
  S->>RE: get_by_email(email)
  RE-->>S: User | None
  alt no user
    S-->>R: raise AUTH_INVALID_CREDENTIALS
    R-->>U: 401 envelope
  else user exists
    S->>SEC: verify_password(password, hash)
    alt mismatch
      S-->>R: raise AUTH_INVALID_CREDENTIALS
      R-->>U: 401
    else ok
      S->>SEC: create_access_token(sub=email)
      S-->>R: TokenResponse
      R-->>U: 200 envelope {access_token}
    end
  end
```

**Rules:** constant-time compare (bcrypt). Never reveal whether email exists vs password wrong — same 401 code/message.

## 2. Create Client

```mermaid
sequenceDiagram
  participant U as Flutter
  participant R as clients router
  participant S as ClientService
  participant RE as ClientRepository
  U->>R: POST /clients {ClientCreate}
  R->>S: create(dto)
  S->>S: validate business rules (name non-empty)
  S->>RE: create(dto)
  RE->>RE: session.add + commit
  RE-->>S: Client model
  S-->>R: ClientRead
  R-->>U: 201 envelope
```

**Rules:** `name` min 1 char; `email` (if present) must be valid email; `archived` defaults false. No uniqueness on client email.

## 3. Create Project (validate client_id)

```mermaid
sequenceDiagram
  participant U as Flutter
  participant R as projects router
  participant S as ProjectService
  participant PRE as ProjectRepository
  participant CRE as ClientRepository
  U->>R: POST /projects {ProjectCreate}
  R->>S: create(dto)
  S->>CRE: get(dto.client_id)
  alt client missing
    S-->>R: raise PROJECT_CLIENT_INVALID
    R-->>U: 400 envelope
  else client exists
    S->>S: validate budget>=0, dates, status enum
    S->>PRE: create(dto)
    PRE-->>S: Project model
    S-->>R: ProjectRead
    R-->>U: 201 envelope
  end
```

**Rules:** `client_id` must resolve to a non-archived or archived (any) existing client; `budget` non-negative; `end_date >= start_date` if both set.

## 4. Update Project

```mermaid
sequenceDiagram
  participant U as Flutter
  participant R as projects router
  participant S as ProjectService
  participant PRE as ProjectRepository
  participant CRE as ClientRepository
  U->>R: PUT /projects/{id} {ClientUpdate-like}
  R->>S: update(id, dto)
  S->>PRE: get(id)
  alt missing
    S-->>R: raise PROJECT_NOT_FOUND
    R-->>U: 404
  else found
    opt client_id provided
      S->>CRE: get(dto.client_id)
      alt missing
        S-->>R: raise PROJECT_CLIENT_INVALID
        R-->>U: 400
      end
    end
    S->>PRE: apply changes + commit
    PRE-->>S: updated Project
    S-->>R: ProjectRead
    R-->>U: 200 envelope
  end
```

## 5. Delete Client (block if projects exist)

```mermaid
sequenceDiagram
  participant U as Flutter
  participant R as clients router
  participant S as ClientService
  participant CRE as ClientRepository
  participant PRE as ProjectRepository
  U->>R: DELETE /clients/{id}
  R->>S: delete(id)
  S->>CRE: get(id)
  alt missing
    S-->>R: raise CLIENT_NOT_FOUND
    R-->>U: 404
  else found
    S->>PRE: count_by_client(id)
    alt count > 0
      S-->>R: raise CLIENT_HAS_PROJECTS
      R-->>U: 409
    else no projects
      S->>CRE: delete(id) + commit
      S-->>R: {"id": id}
      R-->>U: 200 envelope
    end
  end
```

**Rules:** Deletion of a client with linked projects is **blocked** (no cascade) to preserve project history. The admin must reassign or delete projects first.

## 6. Cross-cutting Business Rules

- All mutations require a valid JWT (router dependency).
- Every service method runs inside the request DB session and commits on success.
- On any raised `AppException`, the global exception handler maps it to the error envelope with the correct HTTP code.
- `updated_at` maintained by DB trigger on `clients`.