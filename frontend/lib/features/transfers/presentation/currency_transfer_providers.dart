import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../reports/presentation/report_providers.dart';
import '../../projects/presentation/project_providers.dart';
import '../data/local_currency_transfer_repository.dart';
import '../domain/currency_transfer_entity.dart';
import '../domain/currency_transfer_repository_interface.dart';
import '../domain/wallet_balance_service.dart';

export '../domain/wallet_balance_service.dart'
    show ProjectWalletBalances, WalletBalanceEntry;

/// Active runtime currency transfer repository provider.
final currencyTransferRepositoryProvider =
    Provider<CurrencyTransferRepositoryInterface>((ref) {
  return ref.watch(localCurrencyTransferRepositoryProvider);
});

/// List active transfers by project from local storage.
final transfersByProjectProvider =
    FutureProvider.family<List<CurrencyTransferEntity>, String>(
        (ref, projectId) async {
  final repo = ref.read(currencyTransferRepositoryProvider);
  return repo.listByProject(projectId);
});

/// Wallet balance service provider.
final walletBalanceServiceProvider = Provider<WalletBalanceService>((ref) {
  final db = ref.watch(databaseProvider);
  return WalletBalanceService(
    db.paymentsDao,
    db.expensesDao,
    db.currencyTransfersDao,
  );
});

/// Per-currency wallet balances for a project.
final projectWalletBalancesProvider =
    FutureProvider.family<ProjectWalletBalances, String>(
        (ref, projectId) async {
  final service = ref.read(walletBalanceServiceProvider);
  return service.computeBalances(projectId);
});

/// Per-currency wallet balances for a project with an analytical conversion
/// rate applied (YER per 1 SAR, scale-6 INTEGER). Used for reporting views.
final projectWalletBalancesAnalyticalProvider = FutureProvider.family<
    ProjectWalletBalances,
    ({String projectId, int analyticalRateScaled})>((ref, params) async {
  final service = ref.read(walletBalanceServiceProvider);
  return service.computeBalances(
    params.projectId,
    analyticalRateScaled: params.analyticalRateScaled,
  );
});

class CurrencyTransferActions {
  CurrencyTransferActions(this._ref);
  final Ref _ref;

  Future<String?> create({
    required String projectId,
    required String sourceCurrency,
    required String targetCurrency,
    required int sourceAmountMinor,
    required int exchangeRateScaled,
    required String date,
    String? notes,
  }) async {
    try {
      await _ref.read(currencyTransferRepositoryProvider).create(
            projectId: projectId,
            sourceCurrency: sourceCurrency,
            targetCurrency: targetCurrency,
            sourceAmountMinor: sourceAmountMinor,
            exchangeRateScaled: exchangeRateScaled,
            date: date,
            notes: notes,
          );
      _invalidate(_ref, projectId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> softDelete(String id, {String? projectId}) async {
    try {
      await _ref.read(currencyTransferRepositoryProvider).softDelete(id);
      if (projectId != null) _invalidate(_ref, projectId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void _invalidate(Ref ref, String projectId) {
    ref.invalidate(transfersByProjectProvider(projectId));
    ref.invalidate(projectWalletBalancesProvider(projectId));
    ref.invalidate(projectFinancialSummaryProvider(projectId));
    invalidateDashboard(ref);
    invalidateReports(ref);
  }
}

final currencyTransferActionsProvider =
    Provider<CurrencyTransferActions>((ref) => CurrencyTransferActions(ref));