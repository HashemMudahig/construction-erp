import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/expense_dto.dart';
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
  DateTime? _expenseDate;
  String _category = 'materials';
  bool _saving = false;

  bool get _isEdit => widget.expense != null;
  static const _categories = ['materials', 'labor', 'equipment', 'permits', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final e = widget.expense!;
      _amount.text = e.amount.toString();
      _notes.text = e.notes ?? '';
      _expenseDate = e.expenseDate;
      _category = e.category;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _expenseDate == null) return;
    setState(() => _saving = true);
    final actions = ref.read(expenseActionsProvider);
    final fmt = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    String? err;
    if (_isEdit) {
      err = await actions.update(
        widget.expense!.id,
        ExpenseUpdateDto(
          category: _category,
          amount: _amount.text.trim(),
          expenseDate: fmt(_expenseDate!),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ),
      );
    } else {
      err = await actions.create(ExpenseCreateDto(
        projectId: widget.projectId,
        category: _category,
        amount: _amount.text.trim(),
        expenseDate: fmt(_expenseDate!),
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
      title: Text(_isEdit ? 'Edit expense' : 'New expense'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? 'materials'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                decoration: const InputDecoration(labelText: 'Amount *'),
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
                    initialDate: _expenseDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _expenseDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Expense date *'),
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