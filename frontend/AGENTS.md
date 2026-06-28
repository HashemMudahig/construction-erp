# Construction ERP Frontend Agent Guidelines

## Project Scope

- This is the Flutter frontend for the Construction ERP platform.
- Primary stack: Flutter, Riverpod, GoRouter, Dio.
- Targets: Android, iOS, Web (future).
- The app is intentionally simple: a single administrative user. No multi-tenant or RBAC complexity in v1.

## Source of Truth

- Treat `lib/` as the implementation source of truth.
- Treat `backend/docs/Sprint_XX_<Name>/04_Frontend_Developer_Guide.md` and `15_UI_UX_Screen_Specification.md` as the per-sprint frontend spec.
- Treat `HISTORY.md` as the running frontend change log.

## Architecture

- Feature-first structure: `lib/features/<feature>/{data,domain,presentation}`.
- `lib/core/`: app-wide config, constants, theme, router, network, error handling, utils.
- `lib/providers/`: Riverpod providers for app state and services.
- `lib/routes/`: GoRouter configuration.

## Data Layer

- API clients use Dio.
- DTOs and repositories live in `lib/features/<feature>/data/`.
- Endpoints are constants in `lib/core/constants/endpoints.dart`. Do not hardcode endpoint strings in screens or providers.

## Domain Layer

- Entities and use cases live in `lib/features/<feature>/domain/`.

## Presentation Layer

- Screens and widgets live in `lib/features/<feature>/presentation/`.
- State management uses Riverpod.
- Show loading, empty, and error states.
- Keep risky operations behind confirmation dialogs.

## Rules

- Screens consume providers and render UI. They should not own API contracts.
- Types live in `lib/features/<feature>/domain/entities/`, not inside screens or providers.
- Match backend response contracts exactly in DTO definitions.
- The backend uses the standard response envelope `{ success, message, data }`. Parse it in the Dio layer.

## Verification

- `flutter analyze` from `frontend/`.
- `flutter build` from `frontend/`.
- Update `HISTORY.md` after verification with what was checked.

## Change Guidance

- Prefer small, targeted changes.
- If a change touches DTOs, check the backend schemas for contract drift.
- If a change touches auth, verify login and protected-route access together.