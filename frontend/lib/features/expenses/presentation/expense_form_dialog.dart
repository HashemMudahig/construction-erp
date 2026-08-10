import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/localized_business_labels.dart';

import '../../../core/database/database_constants.dart';
import '../../../core/database/finance/currency_conversion.dart';
import '../../../core/database/finance/exchange_rate.dart';
import '../../../core/database/finance/money_scale.dart';
import '../../projects/presentation/project_providers.dart';
import '../../settings/presentation/settings_provider.dart';
import '../domain/expense_entity.dart';
import 'expense_providers.dart';

class ExpenseFormDialog extends ConsumerStatefulWidget {
  const ExpenseFormDialog({required this.projectId, this.expense, super.key});
  final String projectId;
  final ExpenseEntity? expense;

  @override
  ConsumerState<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _rate = TextEditingController();
  DateTime? _expenseDate;
  String _category = 'materials';
  String _currency = kCurrencyYer;
  String _contractCurrency = kCurrencyYer;
  bool _saving = false;

  bool get _isEdit => widget.expense != null;
  static const _categories = [
    'materials',
    'labor',
    'equipment',
    'permits',
    'other'
  ];
  bool get _needsRate => _currency != _contractCurrency;

  @override
  void initState() {
    super.initState();
    _loadContractCurrency();
    if (widget.expense != null) {
      final e = widget.expense!;
      _currency = e.originalCurrency;
      _category = e.category;
      _amount.text =
          formatMinorUnits(e.originalAmountMinor, e.originalCurrency);
      _notes.text = e.notes ?? '';
      _expenseDate = e.expenseDate;
      if (_needsRate) {
        _rate.text = formatScaledExchangeRate(e.exchangeRateScaled);
      }
    }
  }

  Future<void> _loadContractCurrency() async {
    try {
      final project =
          await ref.read(projectRepositoryProvider).getById(widget.projectId);
      if (mounted && project != null) {
        setState(() => _contractCurrency = project.budgetCurrency);
        if (_needsRate && _rate.text.isEmpty) {
          final settings = ref.read(settingsProvider).valueOrNull;
          if (settings != null) {
            _rate.text =
                formatScaledExchangeRate(settings.defaultSarToYerRateScaled);
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _expenseDate == null) return;
    // Over-cash warning: if adding this expense will make total expenses
    // exceed received payments, warn the user (non-blocking — they may
    // continue because the contractor may finance the project).
    if (!_isEdit) {
      final overCash = await _checkExpenseOverCash();
      if (overCash != null) {
        final confirmed = await _showOverCashWarning(overCash);
        if (confirmed != true) return;
      }
    }
    setState(() => _saving = true);
    final actions = ref.read(expenseActionsProvider);
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final amountDecimal = Decimal.parse(_amount.text.trim());
    int amountMinor;
    try {
      amountMinor = toMinorUnits(amountDecimal, _currency);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    int? rateScaled;
    String rateSource = kRateSourceIdentity;
    if (_needsRate) {
      final rateStr = _rate.text.trim();
      if (rateStr.isEmpty) {
        setState(() => _saving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('err_exchange_rate_gt_zero'))));
        }
        return;
      }
      try {
        rateScaled = toScaledExchangeRateFromString(rateStr);
        rateSource = kRateSourceManual;
      } catch (e) {
        setState(() => _saving = false);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
        return;
      }
    }

    String? err;
    if (_isEdit) {
      err = await actions.update(
        id: widget.expense!.id,
        projectId: widget.projectId,
        category: _category,
        originalAmountMinor: amountMinor,
        originalCurrency: _currency,
        exchangeRateScaled: rateScaled,
        rateSource: rateSource,
        rateDate: _needsRate ? fmt(_expenseDate!) : null,
        expenseDate: fmt(_expenseDate!),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    } else {
      err = await actions.create(
        projectId: widget.projectId,
        category: _category,
        originalAmountMinor: amountMinor,
        originalCurrency: _currency,
        exchangeRateScaled: rateScaled,
        rateSource: rateSource,
        rateDate: _needsRate ? fmt(_expenseDate!) : null,
        expenseDate: fmt(_expenseDate!),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    }
    setState(() => _saving = false);
    if (err == null && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err!)));
    }
  }

  /// Returns the over-cash breakdown if adding this expense would make total
  /// expenses exceed received payments, or `null` if there is no over-cash
  /// situation or the inputs are invalid.
  Future<_OverCashInfo?> _checkExpenseOverCash() async {
    final amountStr = _amount.text.trim();
    final rateStr = _rate.text.trim();
    final amountDec = Decimal.tryParse(amountStr);
    if (amountDec == null || amountDec <= Decimal.zero) return null;
    int amountMinor;
    int? rateScaled;
    try {
      amountMinor = toMinorUnits(amountDec, _currency);
      if (_needsRate) {
        final rateDec = Decimal.tryParse(rateStr);
        if (rateDec == null || rateDec <= Decimal.zero) return null;
        rateScaled = toScaledExchangeRate(rateDec);
      }
    } catch (_) {
      return null;
    }
    try {
      final summary = await ref
          .read(projectRepositoryProvider)
          .getFinancialSummary(widget.projectId);
      // Compare in YER (the canonical converted snapshot) for consistency.
      final newExpenseYer = _currency == kCurrencyYer
          ? amountMinor
          : convertToYer(amountMinor, kCurrencySar, rateScaled!);
      final totalExpensesAfter = summary.totalExpensesYer + newExpenseYer;
      if (totalExpensesAfter > summary.totalPaymentsYer) {
        return _OverCashInfo(
          receivedPayments: summary.totalPaymentsYer,
          totalExpensesAfter: totalExpensesAfter,
          deficit: totalExpensesAfter - summary.totalPaymentsYer,
        );
      }
    } catch (_) {
      // If the summary cannot be read, do not block the expense.
    }
    return null;
  }

  /// Shows the over-cash warning dialog. Returns `true` if the user chooses to
  /// continue, `false` otherwise.
  Future<bool?> _showOverCashWarning(_OverCashInfo info) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Theme.of(ctx).colorScheme.error),
            const SizedBox(width: 8),
            Text(context.tr('financial_alert')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('expense_overcash_warning')),
              const SizedBox(height: 16),
              _ConfirmationRow(
                label: context.tr('received_payments_label'),
                value: formatCurrencyDisplay(info.receivedPayments, 'YER'),
              ),
              _ConfirmationRow(
                label: context.tr('total_expenses_after_adding'),
                value: formatCurrencyDisplay(info.totalExpensesAfter, 'YER'),
              ),
              _ConfirmationRow(
                label: context.tr('expected_deficit'),
                value: formatCurrencyDisplay(info.deficit, 'YER'),
                bold: true,
              ),
              const SizedBox(height: 16),
              Text(context.tr('continue_question'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('proceed')),
          ),
        ],
      ),
    );
  }

  /// Live converted-value preview for cross-currency expenses.
  Widget _buildConvertedPreview() {
    final amountStr = _amount.text.trim();
    final rateStr = _rate.text.trim();
    final amountDec = Decimal.tryParse(amountStr);
    final rateDec = Decimal.tryParse(rateStr);
    if (amountDec == null || amountDec <= Decimal.zero) {
      return const SizedBox.shrink();
    }
    if (rateDec == null || rateDec <= Decimal.zero) {
      return const SizedBox.shrink();
    }
    int amountMinor;
    int rateScaled;
    try {
      amountMinor = toMinorUnits(amountDec, _currency);
      rateScaled = toScaledExchangeRate(rateDec);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final convertedMinor = convertToCurrency(
        amountMinor, _currency, _contractCurrency, rateScaled);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${context.tr('equivalent')}: ${formatCurrencyDisplay(convertedMinor, _contractCurrency)}',
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          context.tr(_isEdit ? 'edit_expense_title' : 'new_expense_title')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration:
                    InputDecoration(labelText: context.tr('expense_category')),
                items: _categories
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(localizedExpenseCategory(context, c))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'materials'),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amount,
                      decoration: InputDecoration(
                        labelText: context.tr('expense_amount_required'),
                        prefixText: '$_currency ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) {
                          return context.tr('err_expense_amount_required');
                        }
                        final d = Decimal.tryParse(s);
                        if (d == null || d <= Decimal.zero) {
                          return context.tr('err_expense_amount_positive');
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('currency_label'),
                      ),
                      initialValue: _currency,
                      items: [
                        DropdownMenuItem(
                            value: kCurrencyYer,
                            child: Text(context.tr('yer'))),
                        DropdownMenuItem(
                            value: kCurrencySar,
                            child: Text(context.tr('sar'))),
                      ],
                      selectedItemBuilder: (context) => const [
                        Text(
                          kCurrencyYer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          kCurrencySar,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _currency = v ?? kCurrencyYer;
                        if (!_needsRate) {
                          _rate.clear();
                        } else if (_rate.text.isEmpty) {
                          final settings =
                              ref.read(settingsProvider).valueOrNull;
                          if (settings != null) {
                            _rate.text = formatScaledExchangeRate(
                              settings.defaultSarToYerRateScaled,
                            );
                          }
                        }
                      }),
                    ),
                  ),
                ],
              ),
              if (_needsRate) ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: _rate,
                  decoration: InputDecoration(
                    labelText: context.tr('exchange_rate_yer_sar'),
                    hintText: 'e.g. 410.000000',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (!_needsRate) return null;
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) {
                      return context.tr('err_rate_required_sar');
                    }
                    final d = Decimal.tryParse(s);
                    if (d == null || d <= Decimal.zero) {
                      return context.tr('err_exchange_rate_gt_zero');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                _buildConvertedPreview(),
              ],
              SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expenseDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _expenseDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: context.tr('expense_date_required')),
                  child: Text(_expenseDate == null
                      ? context.tr('select_date')
                      : '${_expenseDate!.year}-${_expenseDate!.month.toString().padLeft(2, '0')}-${_expenseDate!.day.toString().padLeft(2, '0')}'),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: InputDecoration(labelText: context.tr('notes')),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel'))),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit
                  ? context.tr('save_expense')
                  : context.tr('save_expense')),
        ),
      ],
    );
  }
}

/// Over-cash warning breakdown (all in YER minor units).
class _OverCashInfo {
  const _OverCashInfo({
    required this.receivedPayments,
    required this.totalExpensesAfter,
    required this.deficit,
  });
  final int receivedPayments;
  final int totalExpensesAfter;
  final int deficit;
}

/// A labeled value row used inside confirmation dialogs.
class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
