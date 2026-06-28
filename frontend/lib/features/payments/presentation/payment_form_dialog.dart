import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payment_dto.dart';
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
  DateTime? _paymentDate;
  String _method = 'cash';
  bool _saving = false;

  bool get _isEdit => widget.payment != null;
  static const _methods = ['cash', 'bank_transfer', 'cheque', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      final p = widget.payment!;
      _amount.text = p.amount.toString();
      _notes.text = p.notes ?? '';
      _paymentDate = p.paymentDate;
      _method = p.method;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _paymentDate == null) return;
    setState(() => _saving = true);
    final actions = ref.read(paymentActionsProvider);
    final fmt = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    String? err;
    if (_isEdit) {
      err = await actions.update(
        widget.payment!.id,
        PaymentUpdateDto(
          amount: _amount.text.trim(),
          paymentDate: fmt(_paymentDate!),
          method: _method,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ),
      );
    } else {
      err = await actions.create(PaymentCreateDto(
        projectId: widget.projectId,
        amount: _amount.text.trim(),
        paymentDate: fmt(_paymentDate!),
        method: _method,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ));
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
              TextFormField(
                controller: _amount,
                decoration: const InputDecoration(labelText: 'Amount *', prefixText: ''),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Amount is required';
                  final d = Decimal.tryParse(s);
                  if (d == null || d <= Decimal.zero) return 'Amount must be > 0';
                  return null;
                },
              ),
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
                  decoration: const InputDecoration(labelText: 'Payment date *'),
                  child: Text(_paymentDate == null
                      ? 'Select date'
                      : '${_paymentDate!.year}-${_paymentDate!.month.toString().padLeft(2, '0')}-${_paymentDate!.day.toString().padLeft(2, '0')}'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
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
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}