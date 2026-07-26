import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_constants.dart';
import '../../../core/database/finance/exchange_rate.dart';
import '../../../core/database/finance/money_scale.dart';
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
  bool _saving = false;

  bool get _isEdit => widget.expense != null;
  static const _categories = [
    'materials',
    'labor',
    'equipment',
    'permits',
    'other'
  ];
  bool get _isSar => _currency == kCurrencySar;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final e = widget.expense!;
      _currency = e.originalCurrency;
      _category = e.category;
      _amount.text =
          formatMinorUnits(e.originalAmountMinor, e.originalCurrency);
      _notes.text = e.notes ?? '';
      _expenseDate = e.expenseDate;
      if (_isSar) {
        _rate.text = formatScaledExchangeRate(e.exchangeRateScaled);
      }
    }
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
    if (_isSar) {
      final rateStr = _rate.text.trim();
      if (rateStr.isEmpty) {
        setState(() => _saving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exchange rate required for SAR')));
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
        rateDate: _isSar ? fmt(_expenseDate!) : null,
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
        rateDate: _isSar ? fmt(_expenseDate!) : null,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit expense' : 'New expense'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'materials'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amount,
                      decoration: InputDecoration(
                        labelText: 'Amount *',
                        prefixText: _isSar ? 'SAR ' : 'YER ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Amount is required';
                        final d = Decimal.tryParse(s);
                        if (d == null || d <= Decimal.zero) {
                          return 'Amount must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Currency'),
                      initialValue: _currency,
                      items: const [
                        DropdownMenuItem(
                            value: kCurrencyYer, child: Text('YER')),
                        DropdownMenuItem(
                            value: kCurrencySar, child: Text('SAR')),
                      ],
                      onChanged: (v) => setState(() {
                        _currency = v ?? kCurrencyYer;
                        if (_currency == kCurrencyYer) _rate.clear();
                      }),
                    ),
                  ),
                ],
              ),
              if (_isSar) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rate,
                  decoration: const InputDecoration(
                    labelText: 'Exchange Rate (YER per SAR)',
                    hintText: 'e.g. 410.000000',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (!_isSar) return null;
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Rate is required for SAR';
                    final d = Decimal.tryParse(s);
                    if (d == null || d <= Decimal.zero) {
                      return 'Enter a positive rate';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
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
                  decoration:
                      const InputDecoration(labelText: 'Expense date *'),
                  child: Text(_expenseDate == null
                      ? 'Select date'
                      : '${_expenseDate!.year}-${_expenseDate!.month.toString().padLeft(2, '0')}-${_expenseDate!.day.toString().padLeft(2, '0')}'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
