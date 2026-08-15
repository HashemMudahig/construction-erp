import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/database/finance/money_scale.dart';

/// The action the user chose when presented with an insufficient currency
/// balance.
enum InsufficientBalanceChoice {
  /// User chose to perform a currency transfer to top up the wallet.
  convertCurrency,

  /// User chose to record external funding (continue with the expense
  /// anyway, because the contractor will finance it externally).
  externalFunding,

  /// User chose to cancel the expense.
  cancel,
}

/// Shows the insufficient-currency-balance warning dialog.
///
/// The dialog displays the current wallet balance, the expense value, and
/// the deficit, all in the expense's original currency. It offers three
/// options:
/// - تحويل عملة (convert currency)
/// - تمويل خارجي (external funding)
/// - إلغاء (cancel)
///
/// Returns the user's [InsufficientBalanceChoice]. Never automatically
/// deducts from another currency.
Future<InsufficientBalanceChoice> showInsufficientBalanceDialog(
  BuildContext context, {
  required String currency,
  required int currentBalanceMinor,
  required int expenseAmountMinor,
}) {
  final deficitMinor = expenseAmountMinor - currentBalanceMinor;
  return showDialog<InsufficientBalanceChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Theme.of(ctx).colorScheme.error),
          const SizedBox(width: 8),
          Text(context.tr('insufficient_balance_title')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('insufficient_balance_body')),
            const SizedBox(height: 16),
            _BalanceRow(
              label: context.tr('current_balance_label'),
              value: formatCurrencyDisplay(currentBalanceMinor, currency),
            ),
            _BalanceRow(
              label: context.tr('expense_value_label'),
              value: formatCurrencyDisplay(expenseAmountMinor, currency),
            ),
            _BalanceRow(
              label: context.tr('deficit_label'),
              value: formatCurrencyDisplay(deficitMinor, currency),
              bold: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(ctx, InsufficientBalanceChoice.cancel),
          child: Text(context.tr('cancel_option')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
              ctx, InsufficientBalanceChoice.externalFunding),
          child: Text(context.tr('external_funding_option')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
              ctx, InsufficientBalanceChoice.convertCurrency),
          child: Text(context.tr('convert_currency_option')),
        ),
      ],
    ),
  ).then((value) => value ?? InsufficientBalanceChoice.cancel);
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}