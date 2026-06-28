# 04 — Frontend Developer Guide — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. New Features

Sprint S02 introduces three feature folders under `lib/features/`, each following the feature-first split established in Sprint 01, plus a profitability card widget embedded in the project detail screen.

```
lib/features/
  milestones/
    data/        (dto, datasource, repository)
    domain/      (entity, repository interface, usecase)
    presentation/ (list, form, providers)
  payments/
    data/ domain/ presentation/
  expenses/
    data/ domain/ presentation/
```

## 2. Data / Domain / Presentation Split

- **data/** — `Dto` (freezed/json_serializable) mirrors the API schema; `RemoteDataSource` uses `Dio` and the central `endpoints.dart`; `RepositoryImpl` calls the datasource and unwraps the standard envelope.
- **domain/** — `Entity` (freezed), `Repository` abstract interface, `UseCase` classes (`GetMilestones`, `SaveMilestone`, `DeleteMilestone`).
- **presentation/** — Riverpod `Notifier`/`AsyncNotifier` providers, list & form widgets, loading/empty/error states.

## 3. DTOs

```dart
// lib/features/payments/data/payment_dto.dart
@freezed
class PaymentDto with _$PaymentDto {
  const factory PaymentDto({
    required String id,
    required String projectId,
    required double amount, // displayed only; backend stores Decimal
    required DateTime paymentDate,
    required String method,
    String? notes,
    DateTime? createdAt,
  }) = _PaymentDto;

  factory PaymentDto.fromJson(Map<String, dynamic> json) => _$PaymentDtoFromJson(json);
}
```

The domain `Payment` entity uses `double` for display but the app always sends the raw value back; the backend remains the source of precision.

## 4. Riverpod Providers

Each feature exposes a family of providers:

- `milestonesListProvider(projectId)` — `AsyncNotifier<List<Milestone>>`
- `milestoneFormProvider` — `Notifier<MilestoneFormState>` for create/edit
- `paymentListProvider(projectId)`, `paymentFormProvider`
- `expenseListProvider(projectId)`, `expenseFormProvider`
- `projectProfitabilityProvider(projectId)` — `AsyncNotifier<ProjectProfitability>`

Providers call the repository, unwrap the envelope, and expose `AsyncValue` consumed by the UI.

## 5. Endpoints Additions — `lib/core/constants/endpoints.dart`

```dart
class Endpoints {
  // ... Sprint 01 ...
  static const milestones   = '/api/v1/milestones';
  static String milestone(String id) => '/api/v1/milestones/$id';
  static const payments     = '/api/v1/payments';
  static String payment(String id)   => '/api/v1/payments/$id';
  static const expenses     = '/api/v1/expenses';
  static String expense(String id)   => '/api/v1/expenses/$id';
  static String profitability(String projectId) => '/api/v1/projects/$projectId/profitability';
}
```

## 6. Embedding in Project Detail

The Sprint 01 `ProjectDetailScreen` gains a `TabBar` with four tabs: **Overview**, **Milestones**, **Payments**, **Expenses**. The Overview tab renders the **Profitability card** (total payments, total expenses, balance, margin %). Each tab lazily loads its list provider scoped by `projectId` from the route parameter.

## 7. Loading / Empty / Error States

Every list widget follows the Sprint 01 pattern:

| AsyncValue state | UI |
| --- | --- |
| `loading` | Centered `CircularProgressIndicator`. |
| `data([])` | Empty-state illustration + "Add first record" button. |
| `error` | Retry button + message from the envelope `errors[]`. |
| `data([...])` | List or DataTable with add FAB. |

Form widgets show inline field errors mapped from backend codes (`INVALID_AMOUNT`, `PROJECT_NOT_FOUND`, `INVALID_METHOD`, `INVALID_CATEGORY`) and a top-level `SnackBar` for fatal errors.