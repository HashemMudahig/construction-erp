# Tech Stack

## Currently Implemented

### Backend Technologies

- FastAPI: Python web framework for high-performance APIs.
- SQLAlchemy: ORM for Python used to model database tables and relationships.
- Alembic: Database migration tool for SQLAlchemy-managed schema changes.
- Pydantic: Data validation and serialization for request/response schemas.
- PostgreSQL: Reliable relational database for production ERP storage.

### Frontend Technologies

- Flutter: Cross-platform UI framework for mobile and desktop.
- Riverpod: State management library for predictable dependency injection and reactive state.
- GoRouter: Declarative routing for Flutter navigation.
- Dio: HTTP client for backend communication.

### Tools

- Docker: Containerize backend, frontend, and database environments.
- Git: Version control for code and documentation.
- VS Code: Development environment.
- CI/CD: Pipeline integration for automated tests and deployment.

## Planned

> **Status: Planned — Not yet installed or implemented. See [offline_migration/](offline_migration/README.md) for details.**

- Drift: Type-safe SQLite ORM for Flutter with code generation and migration support.
- SQLite: Local relational database for offline data storage.
- sqlite3_flutter_libs: SQLite native libraries for Flutter.
- build_runner: Code generation runner for Drift.
- local_auth: Biometric authentication (optional, if approved).
- Backup and restore support: ZIP-based database export/import.

## Preserved for Future Use

- FastAPI remote adapter: The FastAPI backend and Dio-based repositories remain in the codebase, preserved and buildable, for future remote access or synchronization.
- PostgreSQL: Remains the database for the preserved backend.
