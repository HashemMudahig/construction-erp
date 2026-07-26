# Architecture

## System Architecture

The system uses a clean architecture approach with a separation between presentation, domain, data, and infrastructure layers.

- Backend: organized as feature-based FastAPI modules with routers, services, repositories, schemas, and models.
- Frontend: organized as Flutter feature modules using Riverpod for state management and GoRouter for navigation.
- API communication: REST API endpoints between Flutter and FastAPI.
- Database: PostgreSQL accessed through SQLAlchemy ORM with Alembic migrations.

## Backend Structure

The backend is designed around feature boundaries.

- `app/main.py`: application entry point and FastAPI initialization.
- `app/routers/`: route definitions per feature.
- `app/services/`: business logic services.
- `app/repositories/`: database access abstractions.
- `app/schemas/`: request and response DTOs.
- `app/models/`: SQLAlchemy ORM models.
- `app/core/`: application configuration and database session utilities.

## Frontend Structure

The frontend uses a feature-based Flutter architecture.

- `lib/features/`: one folder per feature such as clients, projects, payments, expenses, reports.
- `lib/shared/`: shared widgets, utilities, and theme definitions.
- `lib/routes/`: GoRouter configuration.
- `lib/providers/`: Riverpod providers for app state and services.

## API Communication Flow

1. Flutter screen triggers a Riverpod action.
2. The provider calls a repository or service to perform a REST request.
3. FastAPI endpoint validates input using Pydantic schemas.
4. Business logic executes in service layer and persists changes using SQLAlchemy.
5. FastAPI returns JSON response to Flutter.
6. Flutter state updates and UI rerenders.

## Database Layer

- PostgreSQL stores clients, projects, payments, expenses, and reports data.
- SQLAlchemy provides ORM mapping for models and relationships.
- Alembic manages schema migrations and versioning.
- Repository layer isolates SQLAlchemy session usage from business logic.

## Planned Offline Architecture

> **Status: Planned — Not yet implemented. See [offline_migration/architecture_target.md](offline_migration/architecture_target.md) for full details.**

The Flutter frontend is planned to become a local-first, fully offline application. The target architecture introduces a local SQLite database via the Drift ORM, with repository interfaces separating the UI from the data source.

### Target Flow

```
Flutter UI (Screens)
→ Riverpod (Providers)
→ Domain Repository Interface
├── Local Drift Repository (active runtime path)
│   → DAO
│   → AppDatabase
│   → SQLite
└── Preserved FastAPI Repository (future remote path)
    → Dio
    → FastAPI
    → SQLAlchemy
    → PostgreSQL
```

### Key Principles

- No HTTP calls during local runtime.
- Financial values stored as TEXT (Decimal strings), never as REAL.
- UUIDs remain primary identifiers, stored as TEXT.
- Foreign keys are mandatory (PRAGMA foreign_keys = ON).
- Dashboard and reports are derived queries, not stored tables.
- The FastAPI backend remains preserved and buildable.

See:
- [Target Architecture](offline_migration/architecture_target.md)
- [Data Model Mapping](offline_migration/data_model_mapping.md)
- [Offline Migration README](offline_migration/README.md)
