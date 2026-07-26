import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'client_providers.dart';
import '../../../core/localization/app_localizations.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({this.id, super.key});
  final String? id;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  bool _archived = false;
  bool _saving = false;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final c = await ref.read(clientRepositoryProvider).getById(widget.id!);
      if (c == null) {
        if (mounted) setState(() => _error = 'Client not found');
        return;
      }
      _name.text = c.name;
      _phone.text = c.phone ?? '';
      _email.text = c.email ?? '';
      _address.text = c.address ?? '';
      _notes.text = c.notes ?? '';
      _archived = c.archived;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
    final notifier = ref.read(clientsListProvider.notifier);
    bool ok;
    if (_isEdit) {
      ok = await notifier.updateClient(
        widget.id!,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        archived: _archived,
      );
    } else {
      ok = await notifier.create(
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.go('/');
    } else {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      setState(() => _error =
          notifier.lastError() ?? (isAr ? 'فشل الحفظ' : 'Save failed'));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('delete_client')),
        content: Text(context.tr('confirm_delete_client')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.tr('delete'))),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await ref.read(clientsListProvider.notifier).delete(widget.id!);
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    } else {
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEdit ? context.tr('edit_client') : context.tr('new_client')),
        actions: _isEdit
            ? [
                IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: context.tr('delete'),
                    onPressed: _delete)
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                    labelText: '${context.tr('client_name')} *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (Localizations.localeOf(context).languageCode == 'ar'
                        ? 'الاسم مطلوب'
                        : 'Name is required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: InputDecoration(labelText: context.tr('phone')),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: context.tr('email')),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return null;
                  final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  return re.hasMatch(s)
                      ? null
                      : (Localizations.localeOf(context).languageCode == 'ar'
                          ? 'أدخل بريداً إلكترونياً صحيحاً'
                          : 'Enter a valid email');
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: InputDecoration(
                    labelText:
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'العنوان'
                            : 'Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: InputDecoration(
                    labelText:
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'ملاحظات'
                            : 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(Localizations.localeOf(context).languageCode == 'ar'
                    ? 'مؤرشف'
                    : 'Archived'),
                value: _archived,
                onChanged: (v) => setState(() => _archived = v),
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEdit
                        ? (Localizations.localeOf(context).languageCode == 'ar'
                            ? 'تحديث'
                            : 'Update')
                        : (Localizations.localeOf(context).languageCode == 'ar'
                            ? 'إنشاء'
                            : 'Create')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
