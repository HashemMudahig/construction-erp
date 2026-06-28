# 14 — Integration with Core APIs — Sprint S02

> **Project:** Construction ERP  
> **Sprint:** S02  
> **Period:** 2026-07-20 to 2026-07-31  
> **Lead:** Tech Lead  
> **Goal:** Add financial tracking — milestones, payments, and expenses linked to projects — with CRUD APIs, Flutter screens, and a project profitability service.  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Frontend Integration Overview

The Flutter app integrates the Sprint S02 financial endpoints through the same Dio + envelope pattern used in Sprint 01. Three new feature folders (`milestones`, `payments`, `expenses`) and a profitability provider are wired into the existing project detail screen.

## 2. Dio Calls & Envelope Unwrapping

`RemoteDataSource` calls Dio and unwraps the standard envelope:

```dart
Future<List<PaymentDto>> fetchPayments(String projectId) async {
  final res = await _dio.get(Endpoints.payments, queryParameters: {'project_id': projectId});
  final body = res.data as Map<String, dynamic>;
  if (body['success'] != true) {
    throw ApiException(body['message'], codes: _codes(body['errors']));
  }
  final page = body['data'] as Map<String, dynamic>;
  return (page['items'] as List).map((e) => PaymentDto.fromJson(e)).toList();
}
```

`ApiException` carries the list of error codes so the presentation layer can map `INVALID_AMOUNT`, `PROJECT_NOT_FOUND`, etc. to user-facing messages.

## 3. DTO Mapping

Each feature defines a DTO (`freezed`) mirroring the backend schema:
- `PaymentDto` ↔ PaymentRead
- `ExpenseDto` ↔ ExpenseRead
- `MilestoneDto` ↔ MilestoneRead
- `ProjectProfitabilityDto` ↔ ProjectProfitabilityResponse

A `Mapper` converts DTO ↔ domain Entity. The domain `Payment`/`Expense` entity exposes `amount` as `double` for display, but the form sends the raw string back so the backend retains Decimal precision.

## 4. Embedding in Project Detail

The Sprint 01 `ProjectDetailScreen` is extended with a `DefaultTabController`:

| Tab | Provider | Widget |
| --- | --- | --- |
| Overview | `projectProfitabilityProvider(projectId)` | Profitability card + project meta |
| Milestones | `milestonesListProvider(projectId)` | `MilestoneListWidget` |
| Payments | `paymentsListProvider(projectId)` | `PaymentListWidget` |
| Expenses | `expensesListProvider(projectId)` | `ExpenseListWidget` |

`projectId` comes from the GoRouter path parameter. Switching tabs lazily initializes each `AsyncNotifier`.

## 5. Providers per Feature

```dart
final paymentsListProvider = FutureProvider.family<List<Payment>, String>((ref, projectId) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.fetchByProject(projectId);
});

final paymentFormProvider = NotifierProvider<PaymentFormNotifier, PaymentFormState>(
  PaymentFormNotifier.new,
);
```

On submit, the form notifier calls `repo.save(payment)`; on success it invalidates `paymentsListProvider(projectId)` and `projectProfitabilityProvider(projectId)` so the card total refreshes.

## 6. Error Handling

| Backend code | Flutter action |
| --- | --- |
| `INVALID_AMOUNT` | Inline field error on amount field: "Enter an amount greater than 0." |
| `INVALID_METHOD` / `INVALID_CATEGORY` | Inline error on dropdown: "Choose a valid option." |
| `PROJECT_NOT_FOUND` | SnackBar + navigate back to project list. |
| `*_NOT_FOUND` | SnackBar "Record no longer exists" + refresh list. |
| `UNAUTHORIZED` | Clear session, redirect to login. |
| `VALIDATION_ERROR` | Map `detail` to the relevant field. |

## 7. Optimistic vs Pessimistic

S02 uses pessimistic updates: the UI awaits the backend response before reflecting changes, ensuring the profitability card always matches the DB. Given the single-admin, low-volume context, the extra round-trip is acceptable and avoids reconciliation complexity.

## 8. Endpoints Reference

See `lib/core/constants/endpoints.dart` (Sprint 01) for the S02 additions documented in `04_Frontend_Developer_Guide.md`. All calls include the `Authorization: Bearer <token>` header injected by the Sprint 01 Dio interceptor.