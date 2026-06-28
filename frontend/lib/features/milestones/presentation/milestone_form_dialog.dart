import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/milestone_dto.dart';
import '../domain/milestone_entity.dart';
import 'milestone_providers.dart';

/// Dialog for creating/editing a milestone.
class MilestoneFormDialog extends ConsumerStatefulWidget {
  const MilestoneFormDialog({this.projectId, this.milestone, super.key});
  final String? projectId;
  final MilestoneEntity? milestone;

  @override
  ConsumerState<MilestoneFormDialog> createState() => _MilestoneFormDialogState();
}

class _MilestoneFormDialogState extends ConsumerState<MilestoneFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime? _dueDate;
  String _status = 'pending';
  bool _saving = false;

  bool get _isEdit => widget.milestone != null;

  @override
  void initState() {
    super.initState();
    if (widget.milestone != null) {
      final m = widget.milestone!;
      _title.text = m.title;
      _description.text = m.description ?? '';
      _dueDate = m.dueDate;
      _status = m.status;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      setState(() {});
      return;
    }
    setState(() => _saving = true);
    final actions = ref.read(milestoneActionsProvider);
    final fmt = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    String? err;
    if (_isEdit) {
      err = await actions.update(
        widget.milestone!.id,
        MilestoneUpdateDto(
          title: _title.text.trim(),
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          dueDate: fmt(_dueDate!),
          status: _status,
        ),
      );
    } else {
      err = await actions.create(MilestoneCreateDto(
        projectId: widget.projectId!,
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        dueDate: fmt(_dueDate!),
        status: _status,
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
      title: Text(_isEdit ? 'Edit milestone' : 'New milestone'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Due date *'),
                  child: Text(_dueDate == null
                      ? 'Select date'
                      : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'),
                ),
              ),
              if (_dueDate == null)
                const Padding(padding: EdgeInsets.only(top: 4), child: Text('Due date is required', style: TextStyle(color: Colors.red, fontSize: 12))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In progress')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'pending'),
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