import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/client_entity.dart';
import 'client_providers.dart';

/// Dialog that creates a new client (project owner) without leaving the
/// project form.
///
/// Uses [clientRepositoryProvider] (a [ClientRepositoryInterface]) so no
/// Drift/AppDatabase dependency is introduced in the UI. On success it
/// refreshes [clientsListProvider] and returns the created [ClientEntity]
/// via [Navigator.pop]. On cancel it pops with `null`.
class AddClientDialog extends ConsumerStatefulWidget {
  const AddClientDialog({super.key});

  /// Convenience launcher. Returns the created [ClientEntity] or `null`
  /// when the user cancels.
  static Future<ClientEntity?> show(BuildContext context) {
    return showDialog<ClientEntity>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddClientDialog(),
    );
  }

  @override
  ConsumerState<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends ConsumerState<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;
  String? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(clientRepositoryProvider);
    try {
      final created = await repo.create(
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        address:
            _address.text.trim().isEmpty ? null : _address.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      // Refresh the clients list so the new client appears everywhere.
      ref.invalidate(clientsListProvider);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (_) {
      // Never expose technical exceptions to the user. Show a friendly
      // localized message instead.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = context.tr('err_client_create_failed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('add_new_client_title')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                    labelText: context.tr('client_name_required')),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.tr('err_client_name_required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: InputDecoration(labelText: context.tr('phone')),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration:
                    InputDecoration(labelText: context.tr('email_label')),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return null;
                  return _emailRegex.hasMatch(s)
                      ? null
                      : context.tr('err_invalid_email');
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration:
                    InputDecoration(labelText: context.tr('address_label')),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: InputDecoration(labelText: context.tr('notes')),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.of(context).pop(null),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('save_client')),
        ),
      ],
    );
  }
}