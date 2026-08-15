import '../../../core/database/database_constants.dart';
import '../../../core/database/daos/currency_transfers_dao.dart';
import '../../../core/database/daos/expenses_dao.dart';
import '../../../core/database/daos/payments_dao.dart';
import '../../../core/database/finance/currency_conversion.dart';

/// A single currency wallet balance entry.
///
/// [amountMinor] is expressed in [currency] minor units and may be negative
/// (when expenses exceed received payments in that currency, before any
/// transfers are considered).
class WalletBalanceEntry {
  const WalletBalanceEntry({
    required this.currency,
    required this.amountMinor,
  });

  final String currency;

  /// Net balance in [currency] minor units:
  /// payments received − expenses + transfers in − transfers out.
  final int amountMinor;
}

/// The complete multi-currency wallet state for a project.
///
/// Wallets are independent per currency. They are never mixed or added
/// together. The optional [analyticalConvertedYer] value is a presentation
/// aid only — it converts every wallet into YER using a single selected
/// exchange rate for reporting purposes. It is never used for financial
/// calculations or stored.
class ProjectWalletBalances {
  ProjectWalletBalances({
    required this.balances,
    required this.paymentsByCurrency,
    required this.expensesByCurrency,
    required this.transfersByCurrency,
    this.analyticalConvertedYer,
    this.analyticalRateScaled,
  });

  /// Per-currency wallet balances, sorted by currency code. Always contains
  /// an entry for every supported currency (SAR and YER), even when the
  /// balance is zero.
  final List<WalletBalanceEntry> balances;

  /// Total payments received grouped by original currency.
  final Map<String, int> paymentsByCurrency;

  /// Total expenses grouped by original currency.
  final Map<String, int> expensesByCurrency;

  /// Net transfer effect grouped by currency (credits − debits).
  final Map<String, int> transfersByCurrency;

  /// Optional analytical YER-equivalent total, computed by converting each
  /// wallet balance into YER using [analyticalRateScaled]. Null when no
  /// reporting rate has been selected. Clearly an analytical value only.
  final int? analyticalConvertedYer;

  /// The exchange rate used to compute [analyticalConvertedYer]
  /// (scale-6 INTEGER, YER per 1 SAR). Null when no analytical conversion
  /// was requested.
  final int? analyticalRateScaled;

  /// Returns the balance for [currency], or 0 when absent.
  int balanceFor(String currency) {
    for (final entry in balances) {
      if (entry.currency == currency) return entry.amountMinor;
    }
    return 0;
  }
}

/// Computes independent per-currency wallet balances for a project.
///
/// Wallets are calculated as:
///
///   SAR wallet = SAR payments − SAR expenses
///               + SAR-target transfers − SAR-source transfers
///
///   YER wallet = YER payments − YER expenses
///               + YER-target transfers − YER-source transfers
///
/// Different currencies are never added together. Historical exchange-rate
/// snapshots on payments, expenses, and transfers are preserved and never
/// recalculated.
class WalletBalanceService {
  WalletBalanceService(this._paymentsDao, this._expensesDao, this._transfersDao);

  final PaymentsDao _paymentsDao;
  final ExpensesDao _expensesDao;
  final CurrencyTransfersDao _transfersDao;

  /// Computes the wallet balances for [projectId].
  ///
  /// When [analyticalRateScaled] is provided (scale-6 INTEGER, YER per 1
  /// SAR), each wallet balance is converted into YER for an analytical
  /// reporting total. The rate is a presentation choice and does not affect
  /// stored values or actual wallet balances.
  Future<ProjectWalletBalances> computeBalances(
    String projectId, {
    int? analyticalRateScaled,
  }) async {
    final payments = await _paymentsDao.getActivePaymentsByProject(projectId);
    final expenses = await _expensesDao.getActiveExpensesByProject(projectId);
    final transfers =
        await _transfersDao.getActiveTransfersByProject(projectId);

    final Map<String, int> paymentsByCurrency = {};
    final Map<String, int> expensesByCurrency = {};
    final Map<String, int> transfersByCurrency = {};

    for (final p in payments) {
      paymentsByCurrency.update(
        p.originalCurrency,
        (v) => v + p.originalAmountMinor,
        ifAbsent: () => p.originalAmountMinor,
      );
    }
    for (final e in expenses) {
      expensesByCurrency.update(
        e.originalCurrency,
        (v) => v + e.originalAmountMinor,
        ifAbsent: () => e.originalAmountMinor,
      );
    }
    for (final t in transfers) {
      transfersByCurrency.update(
        t.sourceCurrency,
        (v) => v - t.sourceAmountMinor,
        ifAbsent: () => -t.sourceAmountMinor,
      );
      transfersByCurrency.update(
        t.targetCurrency,
        (v) => v + t.targetAmountMinor,
        ifAbsent: () => t.targetAmountMinor,
      );
    }

    final balances = <WalletBalanceEntry>[];
    final int? analyticalRate = analyticalRateScaled;
    final bool hasAnalyticalRate = analyticalRate != null && analyticalRate > 0;
    int analyticalTotal = 0;
    for (final currency in kSupportedCurrencies) {
      final paymentsAmount = paymentsByCurrency[currency] ?? 0;
      final expensesAmount = expensesByCurrency[currency] ?? 0;
      final transfersAmount = transfersByCurrency[currency] ?? 0;
      final balance = paymentsAmount - expensesAmount + transfersAmount;
      balances.add(WalletBalanceEntry(
        currency: currency,
        amountMinor: balance,
      ));
      if (hasAnalyticalRate) {
        if (currency == kCurrencyYer) {
          analyticalTotal += balance;
        } else {
          // Convert SAR wallet balance into YER using the analytical rate.
          analyticalTotal += convertToYer(
              balance, kCurrencySar, analyticalRate);
        }
      }
    }
    balances.sort((a, b) => a.currency.compareTo(b.currency));

    return ProjectWalletBalances(
      balances: balances,
      paymentsByCurrency: paymentsByCurrency,
      expensesByCurrency: expensesByCurrency,
      transfersByCurrency: transfersByCurrency,
      analyticalConvertedYer: hasAnalyticalRate ? analyticalTotal : null,
      analyticalRateScaled: analyticalRate,
    );
  }

  /// Computes the GLOBAL wallet balances across ALL projects.
  ///
  /// Uses the same per-currency formula as [computeBalances] but aggregates
  /// every active payment, expense, and transfer in the database (no project
  /// filter). Currencies are never mixed. This is the financial truth shared
  /// by the Dashboard, Project Details, and Reports.
  Future<ProjectWalletBalances> computeGlobalBalances() async {
    final payments = await _paymentsDao.getAllActivePayments();
    final expenses = await _expensesDao.getAllActiveExpenses();
    final transfers = await _transfersDao.getAllActiveTransfers();

    final Map<String, int> paymentsByCurrency = {};
    final Map<String, int> expensesByCurrency = {};
    final Map<String, int> transfersByCurrency = {};

    for (final p in payments) {
      paymentsByCurrency.update(
        p.originalCurrency,
        (v) => v + p.originalAmountMinor,
        ifAbsent: () => p.originalAmountMinor,
      );
    }
    for (final e in expenses) {
      expensesByCurrency.update(
        e.originalCurrency,
        (v) => v + e.originalAmountMinor,
        ifAbsent: () => e.originalAmountMinor,
      );
    }
    for (final t in transfers) {
      transfersByCurrency.update(
        t.sourceCurrency,
        (v) => v - t.sourceAmountMinor,
        ifAbsent: () => -t.sourceAmountMinor,
      );
      transfersByCurrency.update(
        t.targetCurrency,
        (v) => v + t.targetAmountMinor,
        ifAbsent: () => t.targetAmountMinor,
      );
    }

    final balances = <WalletBalanceEntry>[];
    for (final currency in kSupportedCurrencies) {
      final paymentsAmount = paymentsByCurrency[currency] ?? 0;
      final expensesAmount = expensesByCurrency[currency] ?? 0;
      final transfersAmount = transfersByCurrency[currency] ?? 0;
      final balance = paymentsAmount - expensesAmount + transfersAmount;
      balances.add(WalletBalanceEntry(
        currency: currency,
        amountMinor: balance,
      ));
    }
    balances.sort((a, b) => a.currency.compareTo(b.currency));

    return ProjectWalletBalances(
      balances: balances,
      paymentsByCurrency: paymentsByCurrency,
      expensesByCurrency: expensesByCurrency,
      transfersByCurrency: transfersByCurrency,
    );
  }
}