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
  String _contractCurrency = kCurrencyYer;
  bool _saving = false;

  bool get _isEdit => widget.payment != null;
  static const _methods = ['cash', 'bank_transfer', 'cheque', 'other'];
  /// A rate is required only when the payment currency differs from the
  /// contract (budget) currency.
  bool get _needsRate => _currency != _contractCurrency;

  @override
  void initState() {
    super.initState();
    _loadContractCurrency();
    if (widget.payment != null) {
      final p = widget.payment!;
      _currency = p.originalCurrency;
      _amount.text =
          formatMinorUnits(p.originalAmountMinor, p.originalCurrency);
      _notes.text = p.notes ?? '';
      _paymentDate = p.paymentDate;
      _method = p.method;
      if (_needsRate) {
        _rate.text = formatScaledExchangeRate(p.exchangeRateScaled);
      }
    }
  }

  Future<void> _loadContractCurrency() async {
    try {
      final project =
          await ref.read(projectRepositoryProvider).getById(widget.projectId);
      if (mounted && project != null) {
        setState(() => _contractCurrency = project.budgetCurrency);
        // Re-evaluate rate prefill after the contract currency is known.
        if (_needsRate && _rate.text.isEmpty) {
          final settings = ref.read(settingsProvider).valueOrNull;
          if (settings != null) {
            _rate.text =
                formatScaledExchangeRate(settings.defaultSarToYerRateScaled);
          }
        }
      }
    } catch (_) {
      // Keep the default YER contract currency; the repository will validate.
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
    // Cross-currency confirmation: when the payment currency differs from the
    // contract currency, show a clear financial warning before recording.
    if (_needsRate && !_isEdit) {
      final confirmed = await _showCrossCurrencyConfirmation();
      if (confirmed != true) return;
    }
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
        id: widget.payment!.id,
        projectId: widget.projectId,
        originalAmountMinor: amountMinor,
        originalCurrency: _currency,
        exchangeRateScaled: rateScaled,
        rateSource: rateSource,
        rateDate: _needsRate ? fmt(_paymentDate!) : null,
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
        rateDate: _needsRate ? fmt(_paymentDate!) : null,
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

  /// Live converted-value preview, shown only when a cross-currency rate is
  /// required and both the amount and rate are valid. Uses exact integer
  /// arithmetic via [convertToCurrency].
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

  /// Builds the cross-currency confirmation dialog showing the original
  /// currency, amount, exchange rate, and the converted value before the
  /// user confirms recording the payment.
  Future<bool?> _showCrossCurrencyConfirmation() {
    final amountStr = _amount.text.trim();
    final rateStr = _rate.text.trim();
    final amountDec = Decimal.tryParse(amountStr);
    final rateDec = Decimal.tryParse(rateStr);
    if (amountDec == null || rateDec == null) return Future.value(false);
    int amountMinor;
    int rateScaled;
    try {
      amountMinor = toMinorUnits(amountDec, _currency);
      rateScaled = toScaledExchangeRate(rateDec);
    } catch (_) {
      return Future.value(false);
    }
    final convertedMinor = convertToCurrency(
        amountMinor, _currency, _contractCurrency, rateScaled);
    final rateDisplay =
        '1 ${_currency} = ${formatScaledExchangeRate(rateScaled)} $_contractCurrency';
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
              Text(context.tr('cross_currency_payment_warning')),
              const SizedBox(height: 16),
              _ConfirmationRow(
                label: context.tr('original_currency'),
                value: _currency,
              ),
              _ConfirmationRow(
                label: context.tr('amount_label'),
                value: formatCurrencyDisplay(amountMinor, _currency),
              ),
              _ConfirmationRow(
                label: context.tr('exchange_rate_label'),
                value: rateDisplay,
              ),
              _ConfirmationRow(
                label: context.tr('value_after_conversion'),
                value: formatCurrencyDisplay(convertedMinor, _contractCurrency),
                bold: true,
              ),
              const SizedBox(height: 16),
              Text(context.tr('record_payment_question'),
                  style: TextStyle(fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          context.tr(_isEdit ? 'edit_payment_title' : 'new_payment_title')),
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
                        labelText: context.tr('payment_amount_required'),
                        prefixText: '$_currency ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) {
                          return context.tr('err_payment_amount_required');
                        }
                        final d = Decimal.tryParse(s);
                        if (d == null || d <= Decimal.zero) {
                          return context.tr('err_payment_amount_positive');
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
                    initialDate: _paymentDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _paymentDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: context.tr('payment_date_required')),
                  child: Text(_paymentDate == null
                      ? context.tr('select_date')
                      : '${_paymentDate!.year}-${_paymentDate!.month.toString().padLeft(2, '0')}-${_paymentDate!.day.toString().padLeft(2, '0')}'),
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: InputDecoration(labelText: context.tr('method')),
                items: _methods
                    .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(localizedPaymentMethod(context, m))))
                    .toList(),
                onChanged: (v) => setState(() => _method = v ?? 'cash'),
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
                  ? context.tr('save_payment')
                  : context.tr('save_payment')),
        ),
      ],
    );
  }
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
