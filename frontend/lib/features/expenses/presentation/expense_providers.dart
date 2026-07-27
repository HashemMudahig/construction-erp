import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_providers.dart';
import '../data/local_expense_repository.dart';
import '../domain/expense_entity.dart';
import '../domain/expense_repository_interface.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../reports/presentation/report_providers.dart';

/// Active runtime expense repository provider.
///
/// Uses the sole production implementation: [LocalExpenseRepository].
final expenseRepositoryProvider = Provider<ExpenseRepositoryInterface>((ref) {
  return ref.watch(localExpenseRepositoryProvider);
});

/// List active expenses by project from local storage.
final expensesByProjectProvider =
    FutureProvider.family<List<ExpenseEntity>, String>((ref, projectId) async {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.listByProject(projectId);
});

class ExpenseActions {
  ExpenseActions(this._ref);
  final Ref _ref;

  Future<String?> create({
    required String projectId,
    String? expenseGroupId,
    required String category,
    required int originalAmountMinor,
    required String originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String rateSource = 'identity',
    String? rateDate,
    required String expenseDate,
    String? notes,
  }) async {
    try {
      await _ref.read(expenseRepositoryProvider).create(
            projectId: projectId,
            expenseGroupId: expenseGroupId,
            category: category,
            originalAmountMinor: originalAmountMinor,
            originalCurrency: originalCurrency,
            exchangeRateScaled: exchangeRateScaled,
            convertedYerAmount: convertedYerAmount,
            rateSource: rateSource,
            rateDate: rateDate,
            expenseDate: expenseDate,
            notes: notes,
          );
      _invalidate(_ref, projectId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> update({
    required String id,
    String? projectId,
    String? category,
    int? originalAmountMinor,
    String? originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String? rateSource,
    String? rateDate,
    String? expenseDate,
    String? notes,
  }) async {
    try {
      await _ref.read(expenseRepositoryProvider).update(
            id: id,
            category: category,
            originalAmountMinor: originalAmountMinor,
            originalCurrency: originalCurrency,
            exchangeRateScaled: exchangeRateScaled,
            convertedYerAmount: convertedYerAmount,
            rateSource: rateSource,
            rateDate: rateDate,
            expenseDate: expenseDate,
            notes: notes,
          );
      if (projectId != null) _invalidate(_ref, projectId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> softDelete(String id, {String? projectId}) async {
    try {
      await _ref.read(expenseRepositoryProvider).softDelete(id);
      if (projectId != null) _invalidate(_ref, projectId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> restore(String id, {String? projectId}) async {
    try {
      await _ref.read(expenseRepositoryProvider).restore(id);
      if (projectId != null) _invalidate(_ref, projectId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void _invalidate(Ref ref, String projectId) {
    ref.invalidate(expensesByProjectProvider(projectId));
    ref.invalidate(projectFinancialSummaryProvider(projectId));
    invalidateDashboard(ref);
    invalidateReports(ref);
  }
}

final expenseActionsProvider =
    Provider<ExpenseActions>((ref) => ExpenseActions(ref));
