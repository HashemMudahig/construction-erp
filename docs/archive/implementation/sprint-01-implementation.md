# Sprint 01 Implementation: Client & Project Management

## 1. Backend implementation details

### Folder structure
- `app/models/`: ORM models for clients and projects.
- `app/schemas/`: Pydantic request/response models.
- `app/routers/`: endpoint definitions for client and project routes.
- `app/services/`: business logic for create/read/update/delete operations.
- `app/repositories/`: database access methods using SQLAlchemy.

### Models
- `Client`: stores client name, contact details, and billing metadata.
- `Project`: stores project title, description, client relationship, start/end dates, and budget.

### Schemas
- `ClientCreate`, `ClientRead`, `ClientUpdate`
- `ProjectCreate`, `ProjectRead`, `ProjectUpdate`

### Routers
- `clients` router with CRUD endpoints.
- `projects` router with CRUD endpoints.

## 2. API endpoints implemented
- `POST /clients`
- `GET /clients`
- `GET /clients/{client_id}`
- `PUT /clients/{client_id}`
- `DELETE /clients/{client_id}`
- `POST /projects`
- `GET /projects`
- `GET /projects/{project_id}`
- `PUT /projects/{project_id}`
- `DELETE /projects/{project_id}`

## 3. Database schema changes
- Add `clients` table with primary key, name, email, phone, and created timestamp.
- Add `projects` table with foreign key to `clients`, name, description, budget, status, start and end dates.

## 4. Flutter screens
- Client list and detail screens.
- Project list and detail screens.
- Forms for create/update operations.

## 5. Testing notes
- Unit tests for repository methods and schema validation.
- Integration tests for client/project endpoint flows.
- Validate foreign key constraints and error handling.

## 6. Completed vs not completed
- Completed: core CRUD for clients and projects, backend models, and API contracts.
- Not completed: project dashboard, payments, expenses, report data, and file export.
