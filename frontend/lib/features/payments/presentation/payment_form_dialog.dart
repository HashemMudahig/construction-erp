import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_constants.dart';
import '../../../core/database/finance/exchange_rate.dart';
import '../../../core/database/finance/money_scale.dart';
import '../../settings/presentation/settings_provider.dart';
import '../domain/payment_entity.dart';
import 'payment_providers.dart';

class PaymentFormDialog extends ConsumerStatefulWidget {
  const PaymentFormDialog({required this.projectId, this.payment, super.key});
  final String projectId;
  final PaymentEntity? payment;

  @override
  ConsumerState<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _rate = TextEditingController();
  DateTime? _paymentDate;
  String _method = 'cash';
  String _currency = kCurrencyYer;
  bool _saving = false;

  bool get _isEdit => widget.payment != null;
  static const _methods = ['cash', 'bank_transfer', 'cheque', 'other'];
  bool get _isSar => _currency == kCurrencySar;

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      final p = widget.payment!;
      _currency = p.originalCurrency;
      _amount.text =
          formatMinorUnits(p.originalAmountMinor, p.originalCurrency);
      _notes.text = p.notes ?? '';
      _paymentDate = p.paymentDate;
      _method = p.method;
      if (_isSar) {
        _rate.text = formatScaledExchangeRate(p.exchangeRateScaled);
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
    if (!_formKey.currentState!.validate() || _paymentDate == null) return;
    setState(() => _saving = true);
    final actions = ref.read(paymentActionsProvider);
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // Parse amount to minor units
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
        id: widget.payment!.id,
        projectId: widget.projectId,
        originalAmountMinor: amountMinor,
        originalCurrency: _currency,
        exchangeRateScaled: rateScaled,
        rateSource: rateSource,
        rateDate: _isSar ? fmt(_paymentDate!) : null,
        paymentDate: fmt(_paymentDate!),
        method: _method,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    } else {
      err = await actions.create(
        projectId: widget.projectId,
        originalAmountMinor: amountMinor,
        originalCurrency: _currency,
        exchangeRateScaled: rateScaled,
        rateSource: rateSource,
        rateDate: _isSar ? fmt(_paymentDate!) : null,
        paymentDate: fmt(_paymentDate!),
        method: _method,
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
      title: Text(_isEdit ? 'Edit payment' : 'New payment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                        if (_currency == kCurrencyYer) {
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
                    initialDate: _paymentDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _paymentDate = picked);
                },
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Payment date *'),
                  child: Text(_paymentDate == null
                      ? 'Select date'
                      : '${_paymentDate!.year}-${_paymentDate!.month.toString().padLeft(2, '0')}-${_paymentDate!.day.toString().padLeft(2, '0')}'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: _methods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _method = v ?? 'cash'),
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
