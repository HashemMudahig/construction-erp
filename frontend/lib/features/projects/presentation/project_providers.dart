import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_project_repository.dart';
import '../domain/project_entity.dart';
import '../domain/project_repository_interface.dart';
import '../../dashboard/presentation/dashboard_providers.dart';

/// Active runtime project repository provider.
///
/// Uses [LocalProjectRepository] (Drift/SQLite). The remote
/// [ApiProjectRepository] remains preserved as `apiProjectRepositoryProvider`.
final projectRepositoryProvider = Provider<ProjectRepositoryInterface>((ref) {
  return ref.watch(localProjectRepositoryProvider);
});

final projectsListProvider =
    AsyncNotifierProvider<ProjectsListNotifier, List<ProjectEntity>>(
  ProjectsListNotifier.new,
);

class ProjectsListNotifier extends AsyncNotifier<List<ProjectEntity>> {
  String? _clientId;
  String? _status;
  String? _search;

  @override
  Future<List<ProjectEntity>> build() => _fetch();

  Future<List<ProjectEntity>> _fetch() async {
    final repo = ref.read(projectRepositoryProvider);
    return repo.list(clientId: _clientId, status: _status, search: _search);
  }

  Future<void> setFilters({String? clientId, String? status}) async {
    _clientId = clientId;
    _status = status;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setSearch(String s) async {
    _search = s;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<String?> create({
    required String clientId,
    required String name,
    String? description,
    required int budgetAmountMinor,
    required String budgetCurrency,
    String exchangePolicy = 'per_transaction',
    int? fixedExchangeRateScaled,
    String? startDate,
    String? endDate,
    String status = 'planning',
  }) async {
    try {
      await ref.read(projectRepositoryProvider).create(
            clientId: clientId,
            name: name,
            description: description,
            budgetAmountMinor: budgetAmountMinor,
            budgetCurrency: budgetCurrency,
            exchangePolicy: exchangePolicy,
            fixedExchangeRateScaled: fixedExchangeRateScaled,
            startDate: startDate,
            endDate: endDate,
            status: status,
          );
      await refresh();
      invalidateDashboard(ref);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProject(
    String id, {
    String? clientId,
    String? name,
    String? description,
    int? budgetAmountMinor,
    String? budgetCurrency,
    String? exchangePolicy,
    int? fixedExchangeRateScaled,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    try {
      await ref.read(projectRepositoryProvider).update(
            id: id,
            clientId: clientId,
            name: name,
            description: description,
            budgetAmountMinor: budgetAmountMinor,
            budgetCurrency: budgetCurrency,
            exchangePolicy: exchangePolicy,
            fixedExchangeRateScaled: fixedExchangeRateScaled,
            startDate: startDate,
            endDate: endDate,
            status: status,
          );
      await refresh();
      invalidateDashboard(ref);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> delete(String id) async {
    try {
      await ref.read(projectRepositoryProvider).deleteIfEligible(id);
      await refresh();
      invalidateDashboard(ref);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final projectDetailProvider =
    FutureProvider.family<ProjectEntity, String>((ref, id) async {
  final repo = ref.read(projectRepositoryProvider);
  final project = await repo.getById(id);
  if (project == null) {
    throw StateError('Project not found: $id');
  }
  return project;
});

/// Local profitability provider — does not call Dio.
final projectFinancialSummaryProvider =
    FutureProvider.family<ProjectFinancialSummary, String>(
        (ref, projectId) async {
  final repo = ref.read(projectRepositoryProvider);
  return repo.getFinancialSummary(projectId);
});
