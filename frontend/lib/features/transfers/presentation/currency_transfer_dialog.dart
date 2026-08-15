import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/finance/currency_conversion.dart';
import '../../../core/database/finance/exchange_rate.dart';
import '../../../core/database/finance/money_scale.dart';
import '../../settings/presentation/settings_provider.dart';
import 'currency_transfer_providers.dart';

class CurrencyTransferDialog extends ConsumerStatefulWidget {
  const CurrencyTransferDialog({required this.projectId, super.key});
  final String projectId;

  @override
  ConsumerState<CurrencyTransferDialog> createState() =>
      _CurrencyTransferDialogState();
}

class _CurrencyTransferDialogState
    extends ConsumerState<CurrencyTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _rate = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _transferDate;
  String _sourceCurrency = kCurrencySar;
  String _targetCurrency = kCurrencyYer;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings != null) {
      _rate.text =
          formatScaledExchangeRate(settings.defaultSarToYerRateScaled);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _transferDate == null) return;
    setState(() => _saving = true);
    final actions = ref.read(currencyTransferActionsProvider);

    final amountDecimal = Decimal.parse(_amount.text.trim());
    int sourceAmountMinor;
    try {
      sourceAmountMinor = toMinorUnits(amountDecimal, _sourceCurrency);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    int rateScaled;
    try {
      rateScaled = toScaledExchangeRateFromString(_rate.text.trim());
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    final err = await actions.create(
      projectId: widget.projectId,
      sourceCurrency: _sourceCurrency,
      targetCurrency: _targetCurrency,
      sourceAmountMinor: sourceAmountMinor,
      exchangeRateScaled: rateScaled,
      date: _fmt(_transferDate!),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    setState(() => _saving = false);
    if (err == null && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err!)));
    }
  }

  Widget _buildResultPreview() {
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
    int sourceAmountMinor;
    int rateScaled;
    try {
      sourceAmountMinor = toMinorUnits(amountDec, _sourceCurrency);
      rateScaled = toScaledExchangeRate(rateDec);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final targetMinor = convertToCurrency(
        sourceAmountMinor, _sourceCurrency, _targetCurrency, rateScaled);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${context.tr('transfer_result_preview')}: ${formatCurrencyDisplay(targetMinor, _targetCurrency)}',
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
      title: Text(context.tr('new_transfer_title')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                          labelText: context.tr('transfer_from')),
                      initialValue: _sourceCurrency,
                      items: kSupportedCurrencies
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                          .toList(),
                      selectedItemBuilder: (context) => kSupportedCurrencies
                          .map((c) => Text(c,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _sourceCurrency = v ?? kCurrencySar;
                        if (_sourceCurrency == _targetCurrency) {
                          _targetCurrency = _sourceCurrency == kCurrencyYer
                              ? kCurrencySar
                              : kCurrencyYer;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                          labelText: context.tr('transfer_to')),
                      initialValue: _targetCurrency,
                      items: kSupportedCurrencies
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                          .toList(),
                      selectedItemBuilder: (context) => kSupportedCurrencies
                          .map((c) => Text(c,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _targetCurrency = v ?? kCurrencyYer;
                        if (_sourceCurrency == _targetCurrency) {
                          _sourceCurrency = _targetCurrency == kCurrencyYer
                              ? kCurrencySar
                              : kCurrencyYer;
                        }
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                decoration: InputDecoration(
                  labelText: context.tr('transfer_amount'),
                  prefixText: '$_sourceCurrency ',
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _rate,
                decoration: InputDecoration(
                  labelText: context.tr('transfer_exchange_rate'),
                  hintText: 'e.g. 410.000000',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                validator: (v) {
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
              const SizedBox(height: 8),
              _buildResultPreview(),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _transferDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _transferDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: context.tr('transfer_date')),
                  child: Text(_transferDate == null
                      ? context.tr('select_date')
                      : _fmt(_transferDate!)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration:
                    InputDecoration(labelText: context.tr('notes')),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.tr('save_transfer')),
        ),
      ],
    );
  }
}