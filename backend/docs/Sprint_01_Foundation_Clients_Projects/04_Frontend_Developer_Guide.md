# 04 — Frontend Developer Guide

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Feature-First Structure

```
lib/
  core/
    config/app_config.dart
    constants/endpoints.dart
    network/dio_provider.dart
    router/app_router.dart
    theme/app_theme.dart
  features/
    auth/
      data/auth_repository.dart, auth_dto.dart
      domain/user_entity.dart, auth_state.dart
      presentation/login_screen.dart, auth_provider.dart
    clients/
      data/client_repository.dart, client_dto.dart
      domain/client_entity.dart
      presentation/client_list_screen.dart
      presentation/client_form_screen.dart
      presentation/client_detail_screen.dart
      presentation/client_providers.dart
    projects/
      data/project_repository.dart, project_dto.dart
      domain/project_entity.dart
      presentation/project_list_screen.dart
      presentation/project_form_screen.dart
      presentation/project_detail_screen.dart
      presentation/project_providers.dart
  main.dart
```

## 2. Data Layer

- **Dio client** is provided by `core/network/dio_provider.dart` as a Riverpod `Provider<Dio>`. Base URL comes from `app_config.dart`. Two interceptors: request (injects `Authorization: Bearer <token>` from `shared_preferences`), response (unwraps `success.data` and throws an `ApiException(success=false, message, errors)` on `success=false`).
- **Repositories** wrap Dio calls per feature: `AuthRepository.login(dto)`, `ClientRepository.list/search/create/update/delete`, `ProjectRepository.list/create/update/delete`.
- **DTOs** are plain Dart classes generated/mirroring backend schemas; mapping to domain entities happens in the repository.

## 3. Domain Layer

Plain immutable entities (`UserEntity`, `ClientEntity`, `ProjectEntity`) with `==`/`hashCode` and `copyWith`. No Dio, no Flutter imports. The repository converts DTO → entity.

## 4. Presentation Layer

- **Screens** are `ConsumerWidget`/`ConsumerStatefulWidget`. They read providers and dispatch actions.
- **Providers** are `AsyncNotifierProvider` for lists and detail, `StateNotifierProvider` for the auth session.
- States explicitly model `loading`, `empty`, `error`, `data` (use `AsyncValue` pattern).

## 5. endpoints.dart Usage

All paths centralized in `lib/core/constants/endpoints.dart`. No string literals for URLs in features.

```dart
class Endpoints {
  static const health = '/api/v1/health';
  static const login = '/api/v1/auth/login';
  static const clients = '/api/v1/clients';
  static String client(String id) => '/api/v1/clients/$id';
  static const projects = '/api/v1/projects';
  static String project(String id) => '/api/v1/projects/$id';
}
```

## 6. Riverpod Provider Patterns

- `authSessionProvider` (StateNotifier) holds `UserEntity?` + token; persists token via `shared_preferences`.
- `clientsListProvider` (AsyncNotifier) exposes `build()` → `ClientRepository.list`.
- `clientDetailProvider(id)` (family AsyncNotifier).
- Mutations: `ref.read(clientsListProvider.notifier).create(dto)`.

## 7. GoRouter Routes

```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (ctx, state) {
    final auth = ref.read(authSessionProvider);
    final isLoggedIn = auth.token != null;
    if (!isLoggedIn && state.path != '/login') return '/login';
    if (isLoggedIn && state.path == '/login') return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(builder: (_, __, child) => AppShell(child: child), routes: [
      GoRoute(path: '/', builder: (_, __) => const ClientListScreen()),
      GoRoute(path: '/clients/:id', builder: (_, s) => ClientDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/clients/new', builder: (_, __) => const ClientFormScreen()),
      GoRoute(path: '/clients/:id/edit', builder: (_, s) => ClientFormScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/projects', builder: (_, __) => const ProjectListScreen()),
      GoRoute(path: '/projects/new', builder: (_, __) => const ProjectFormScreen()),
      GoRoute(path: '/projects/:id', builder: (_, s) => ProjectDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/projects/:id/edit', builder: (_, s) => ProjectFormScreen(id: s.pathParameters['id']!)),
    ]),
  ],
);
```

## 8. State Conventions

| State | UI |
| --- | --- |
| loading | `CircularProgressIndicator` centered |
| empty | `Text('No records yet')` + primary CTA |
| error | `Text(message)` + retry button |
| data | list/form/detail widgets |

## 9. Theme

Material 3 with a single color seed; consistent spacing tokens; light + dark supported but light default.