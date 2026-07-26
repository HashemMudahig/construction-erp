import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_providers.dart';
import '../data/local_payment_repository.dart';
import '../domain/payment_entity.dart';
import '../domain/payment_repository_interface.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../reports/presentation/report_providers.dart';

/// Active runtime payment repository provider.
///
/// Uses [LocalPaymentRepository] (Drift/SQLite). The remote
/// [ApiPaymentRepository] remains preserved as `apiPaymentRepositoryProvider`.
final paymentRepositoryProvider = Provider<PaymentRepositoryInterface>((ref) {
  return ref.watch(localPaymentRepositoryProvider);
});

/// List active payments by project — local, no Dio.
final paymentsByProjectProvider =
    FutureProvider.family<List<PaymentEntity>, String>((ref, projectId) async {
  final repo = ref.read(paymentRepositoryProvider);
  return repo.listByProject(projectId);
});

class PaymentActions {
  PaymentActions(this._ref);
  final Ref _ref;

  Future<String?> create({
    required String projectId,
    String? paymentGroupId,
    required int originalAmountMinor,
    required String originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String rateSource = 'identity',
    String? rateDate,
    required String paymentDate,
    required String method,
    String? notes,
  }) async {
    try {
      await _ref.read(paymentRepositoryProvider).create(
            projectId: projectId,
            paymentGroupId: paymentGroupId,
            originalAmountMinor: originalAmountMinor,
            originalCurrency: originalCurrency,
            exchangeRateScaled: exchangeRateScaled,
            convertedYerAmount: convertedYerAmount,
            rateSource: rateSource,
            rateDate: rateDate,
            paymentDate: paymentDate,
            method: method,
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
    int? originalAmountMinor,
    String? originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String? rateSource,
    String? rateDate,
    String? paymentDate,
    String? method,
    String? notes,
  }) async {
    try {
      await _ref.read(paymentRepositoryProvider).update(
            id: id,
            originalAmountMinor: originalAmountMinor,
            originalCurrency: originalCurrency,
            exchangeRateScaled: exchangeRateScaled,
            convertedYerAmount: convertedYerAmount,
            rateSource: rateSource,
            rateDate: rateDate,
            paymentDate: paymentDate,
            method: method,
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
      await _ref.read(paymentRepositoryProvider).softDelete(id);
      if (projectId != null) _invalidate(_ref, projectId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> restore(String id, {String? projectId}) async {
    try {
      await _ref.read(paymentRepositoryProvider).restore(id);
      if (projectId != null) _invalidate(_ref, projectId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void _invalidate(Ref ref, String projectId) {
    ref.invalidate(paymentsByProjectProvider(projectId));
    // Also invalidate project financial summary
    ref.invalidate(projectFinancialSummaryProvider(projectId));
    invalidateDashboard(ref);
    invalidateReports(ref);
  }
}

final paymentActionsProvider =
    Provider<PaymentActions>((ref) => PaymentActions(ref));
