# Target Architecture

## Phase 08 active Dashboard adapter

Dashboard now resolves through `DashboardRepositoryInterface`,
`LocalDashboardRepository`, and the read-only `DashboardDao`. The preserved
`ApiDashboardRepository` is a future remote adapter and is not the runtime
default. All Dashboard results are derived and never persisted.

> **Status: Planned — Not yet implemented.**

This document describes the target architecture for the offline migration. It does not replace [../architecture.md](../architecture.md), which describes the current architecture. The two documents are linked.

## Current Architecture

```
Flutter UI (Screens)
→ Riverpod (Providers)
→ Dio Repository (data layer)
→ FastAPI (HTTP API)
→ SQLAlchemy (ORM)
→ PostgreSQL (Database)
```

### Current Flow

1. Flutter screen triggers a Riverpod provider action.
2. The provider calls a Dio-based repository (e.g., `ClientRepository`).
3. The repository makes an HTTP request to the FastAPI backend.
4. FastAPI validates input via Pydantic schemas.
5. Business logic executes in the service layer.
6. Data persists via SQLAlchemy to PostgreSQL.
7. FastAPI returns a JSON response (standard envelope `{ success, message, data }`).
8. The Dio envelope interceptor unwraps the response.
9. The provider updates state and the UI re-renders.

### Current Dependencies

- `dioProvider` — Central HTTP client with auth and envelope interceptors.
- `appConfig` — Backend base URL (`http://10.0.2.2:8000/api/v1`).
- `endpoints.dart` — All API endpoint path constants.
- `authSessionProvider` — JWT token management and login state.
- All feature `data/*_repository.dart` files depend on `Dio`.

## Target Architecture

```
Flutter UI (Screens)
→ Riverpod (Providers)
→ Domain Repository Interface
├── Local Drift Repository (active runtime path)
│   → DAO (Data Access Object)
│   → AppDatabase
│   → SQLite
└── Preserved FastAPI Repository (future remote path)
    → Dio
    → FastAPI
    → SQLAlchemy
    → PostgreSQL
```

### Active Local Runtime Path

```
Screen
→ Provider (Riverpod)
→ Repository Interface (domain layer, abstract)
→ Local Repository (data layer, concrete)
→ DAO (Drift)
→ AppDatabase (Drift)
→ SQLite (local file)
```

### Preserved Future Remote Path

```
Screen
→ Provider (Riverpod)
→ Repository Interface (domain layer, abstract)
→ Remote Repository (data layer, concrete, preserved)
→ Dio (HTTP client)
→ FastAPI (HTTP API)
→ SQLAlchemy (ORM)
→ PostgreSQL (Database)
```

The remote path is **not active** in the local runtime. It is preserved in the codebase for future use when synchronization or remote access is needed.

## Layer Responsibilities

### Presentation Layer (Screens)

- Renders UI based on provider state.
- Handles user interactions (tap, input, scroll).
- Shows loading, empty, and error states.
- Does NOT directly access Dio, AppDatabase, or DAOs.
- Does NOT implement business logic or SQL queries.

### Provider Layer (Riverpod)

- Manages reactive state.
- Calls repository interfaces to perform data operations.
- Does NOT directly access Dio, AppDatabase, or DAOs.
- Does NOT implement business logic.

### Domain Layer (Repository Interfaces, Entities)

- Defines abstract repository interfaces.
- Defines domain entities (immutable models).
- Contains no data source dependencies (no Dio, no Drift).
- Business logic that is data-source-independent lives here.

### Data Layer (Local Repositories, DAOs)

- Implements repository interfaces.
- Contains data source-specific logic (Drift queries, SQL).
- DAOs encapsulate table-level operations.
- Local repositories coordinate DAOs and handle transactions.

### Database Layer (AppDatabase, SQLite)

- Drift `AppDatabase` class manages the SQLite connection.
- Schema versioning and migrations.
- Foreign key enforcement.
- Transaction support.

## Allowed Dependency Direction

```
Presentation → Provider → Domain ← Data → Database
```

- Screens depend on providers.
- Providers depend on repository interfaces (domain).
- Local repositories depend on DAOs and implement repository interfaces.
- DAOs depend on AppDatabase.
- AppDatabase depends on SQLite.

## Prohibited Dependencies

- **Screen directly using Dio** — Screens must not import or call Dio.
- **Screen directly using AppDatabase** — Screens must not access the database directly.
- **Provider directly using Dio** — Providers must use repository interfaces, not Dio.
- **Provider directly using DAOs** — Providers must use repository interfaces, not DAOs.
- **Dashboard screen implementing SQL calculations** — Dashboard must use a query service, not inline SQL.
- **Financial values stored as double** — All money fields must use `Decimal` in Dart and TEXT in SQLite.
- **Domain layer importing Dio or Drift** — The domain layer must remain data-source-agnostic.

## Provider Lifecycle

- Providers are created and disposed by Riverpod.
- The `databaseProvider` (Provider<AppDatabase>) is created once and kept alive for the app lifetime.
- Repository interface providers are created on demand and disposed when no longer watched.
- List/detail providers (AsyncNotifierProvider, FutureProvider.family) are created per-feature and auto-disposed when appropriate.

## Database Lifecycle

- `AppDatabase` is opened when the app starts (via `databaseProvider`).
- `AppDatabase` is closed when the app is disposed (or when the OS reclaims resources).
- WAL (Write-Ahead Logging) mode is enabled for concurrent read/write.
- Foreign keys are enforced via `PRAGMA foreign_keys = ON` on every connection.

## Future Synchronization Boundary

> **Not part of current scope.**

A future synchronization layer would sit between the local repository and the remote repository:

```
Local Repository
→ Sync Manager (future)
→ Remote Repository
→ FastAPI
```

The sync manager would handle:
- Conflict resolution.
- Incremental sync (last-sync timestamp).
- Network state detection.
- Background sync scheduling.

This is explicitly out of scope for the first local release. The remote repository code is preserved to enable this future work without rebuilding from scratch.

## Related Documents

- [../architecture.md](../architecture.md) — Current architecture.
- [data_model_mapping.md](data_model_mapping.md) — Field-level data model mapping.
- [decision_log.md](decision_log.md) — Architecture Decision Records.
- [README.md](README.md) — Migration overview and phase list.
