# 14 — Integration with Core APIs

> **Project:** Construction ERP  
> **Sprint:** S01  
> **Period:** 2026-07-06 to 2026-07-17  
> **Lead:** Tech Lead  
> **Goal:** Establish the system foundation (FastAPI, PostgreSQL, JWT auth for a single admin) and deliver core Client and Project management with full CRUD on backend and Flutter screens.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Overview

The Flutter app talks to FastAPI exclusively over `/api/v1`. All HTTP goes through one configured `Dio` instance provided by Riverpod. Features never construct `Dio` directly; they call feature repositories which depend on the shared client.

## 2. Dio Setup (`core/network/dio_provider.dart`)

```dart
final dioProvider = Provider<Dio>((ref) {
  final cfg = ref.watch(appConfigProvider);
  final dio = Dio(BaseOptions(
    baseUrl: cfg.apiBaseUrl,           // e.g. http://localhost:8000
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(EnvelopeInterceptor());
  if (cfg.isDev) dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  return dio;
});
```

## 3. Base URL

`app_config.dart` exposes `apiBaseUrl` per flavour. Dev: `http://localhost:8000`; Android emulator: `http://10.0.2.2:8000`; prod: from `--dart-define=API_BASE_URL`. Endpoints are appended via `Endpoints` constants.

## 4. Auth Token Storage

- On successful login, `AuthRepository` receives `TokenResponse`; `authSessionProvider` stores `access_token` in `shared_preferences` (`auth_token` key) and in memory.
- On logout/expiry, the key is removed and in-memory state cleared.
- Tokens are **never** logged and never embedded in URLs.

## 5. Interceptors

### AuthInterceptor (request)
```dart
class AuthInterceptor extends Interceptor {
  final Ref ref;
  AuthInterceptor(this.ref);
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    if (Endpoints.isPublic(o.path)) return h.next(o);
    final token = ref.read(authTokenProvider);
    if (token != null) o.headers['Authorization'] = 'Bearer $token';
    h.next(o);
  }
}
```

### EnvelopeInterceptor (response)
Unwraps `success.data` on success; throws `ApiException` on `success=false`.

```dart
class EnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    final body = r.data;
    if (body is Map && body['success'] == true) {
      r.data = body['data'];            // unwrap
      return h.next(r);
    }
    if (body is Map && body['success'] == false) {
      h.reject(DioException(
        requestOptions: r.requestOptions,
        response: r,
        type: DioExceptionType.badResponse,
        error: ApiException(
          message: body['message'] ?? 'Request failed',
          errors: EnvelopeErrors.fromJson(body['errors'] ?? []),
        ),
      ));
    }
    h.next(r);
  }
}
```

## 6. Error Handling

`ApiException` carries `message` and a list of `{code, field, detail}`. Widgets map codes via an error dictionary. On 401 `AUTH_TOKEN_EXPIRED`/`AUTH_TOKEN_MISSING`, the app clears the session and routes to `/login`.

## 7. Endpoint Constants

`lib/core/constants/endpoints.dart` is the single source of paths. Example:
```dart
class Endpoints {
  static const login = '/api/v1/auth/login';
  static const health = '/api/v1/health';
  static const clients = '/api/v1/clients';
  static String client(String id) => '/api/v1/clients/$id';
  static const projects = '/api/v1/projects';
  static String project(String id) => '/api/v1/projects/$id';
  static bool isPublic(String path) =>
    path == health || path == login;
}
```

## 8. DTO Mapping

- JSON → DTO (`ClientDto.fromJson`), DTO → domain `ClientEntity` (`toEntity()`).
- Domain entities are used by providers/UI; DTOs never leak into presentation.
- `Decimal` (budget) handled via `decimal` package; serialised as string to preserve precision.

```dart
final clientDto = ClientDto.fromJson(json);
final client = clientDto.toEntity();
```

## 9. Example Call (clients list)

```dart
Future<List<ClientEntity>> list({String? search, int skip=0, int limit=20}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get(Endpoints.clients, queryParameters: {
    if (search != null) 'search': search, 'skip': skip, 'limit': limit,
  });
  return (res.data as List).map((j) => ClientDto.fromJson(j).toEntity()).toList();
}
```

## 10. Conventions

- One repository per feature, all methods return domain entities.
- No business logic in repositories — only mapping and HTTP.
- All status/errors surfaced through `AsyncValue.error`/`ApiException`.