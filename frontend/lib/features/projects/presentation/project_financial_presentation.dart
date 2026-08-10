import '../../../core/database/finance/money_scale.dart';

class CashFlowPresentation {
  const CashFlowPresentation({
    required this.statusKey,
    required this.detailKey,
  });

  final String statusKey;
  final String detailKey;
}

CashFlowPresentation cashFlowPresentation(int netCashFlow) {
  if (netCashFlow > 0) {
    return const CashFlowPresentation(
      statusKey: 'cash_surplus',
      detailKey: 'cash_surplus_detail',
    );
  }
  if (netCashFlow < 0) {
    return const CashFlowPresentation(
      statusKey: 'cash_deficit',
      detailKey: 'cash_deficit_detail',
    );
  }
  return const CashFlowPresentation(
    statusKey: 'cash_balanced',
    detailKey: 'cash_balanced_detail',
  );
}

int? calculateCostOverrun({
  required int? contractValueYer,
  required int? totalExpensesYer,
}) {
  if (contractValueYer == null || totalExpensesYer == null) return null;
  final difference = totalExpensesYer - contractValueYer;
  return difference > 0 ? difference : null;
}

String formatDisplayAmount(int minorUnits, String currency) {
  // Delegate to the unified core formatter so all screens present
  // currency identically. Kept for backward compatibility with existing
  // callers and tests.
  return formatCurrencyDisplay(minorUnits, currency);
}
