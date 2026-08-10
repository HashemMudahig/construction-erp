import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/localized_business_labels.dart';
import '../domain/milestone_entity.dart';
import 'milestone_providers.dart';

/// Dialog for creating/editing a milestone.
class MilestoneFormDialog extends ConsumerStatefulWidget {
  const MilestoneFormDialog({this.projectId, this.milestone, super.key});
  final String? projectId;
  final MilestoneEntity? milestone;

  @override
  ConsumerState<MilestoneFormDialog> createState() =>
      _MilestoneFormDialogState();
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
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    String? err;
    if (_isEdit) {
      err = await actions.update(
        id: widget.milestone!.id,
        title: _title.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        dueDate: fmt(_dueDate!),
        status: _status,
        projectId: widget.projectId,
      );
    } else {
      err = await actions.create(
        projectId: widget.projectId!,
        title: _title.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        dueDate: fmt(_dueDate!),
        status: _status,
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
      title: Text(
          context.tr(_isEdit ? 'edit_milestone_title' : 'new_milestone_title')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: InputDecoration(
                    labelText: context.tr('milestone_title_required')),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.tr('err_milestone_title_required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: InputDecoration(
                    labelText: context.tr('milestone_description')),
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
                  decoration: InputDecoration(
                      labelText: context.tr('milestone_due_date')),
                  child: Text(_dueDate == null
                      ? context.tr('select_date')
                      : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'),
                ),
              ),
              if (_dueDate == null)
                Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(context.tr('due_date_required'),
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration:
                    InputDecoration(labelText: context.tr('milestone_status')),
                items: const ['pending', 'in_progress', 'completed', 'overdue']
                    .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(localizedMilestoneStatus(context, status))))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'pending'),
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
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.tr(_isEdit ? 'update' : 'create_milestone')),
        ),
      ],
    );
  }
}
