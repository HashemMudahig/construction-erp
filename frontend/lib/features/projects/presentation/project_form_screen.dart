import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../clients/presentation/client_providers.dart';
import '../../clients/domain/client_entity.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/finance/exchange_rate.dart';
import '../../../core/database/finance/money_scale.dart';
import 'project_providers.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({this.id, this.clientId, super.key});
  final String? id;
  final String? clientId;

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _budget = TextEditingController();
  String? _clientId;
  String _status = 'planning';
  String _budgetCurrency = kCurrencyYer;
  String _exchangePolicy = kExchangePolicyPerTransaction;
  String _fixedRate = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;
  bool _loading = false;
  String? _error;
  List<ClientEntity> _clients = [];

  static const _statuses = [
    'planning',
    'active',
    'completed',
    'on_hold',
    'cancelled'
  ];

  bool get _isEdit => widget.id != null;
  bool get _isSarFixed =>
      _budgetCurrency == kCurrencySar &&
      _exchangePolicy == kExchangePolicyFixed;

  @override
  void initState() {
    super.initState();
    _clientId = widget.clientId;
    _loadClients();
    if (_isEdit) _loadExisting();
  }

  Future<void> _loadClients() async {
    try {
      final clients =
          await ref.read(clientRepositoryProvider).list(includeArchived: true);
      if (mounted) setState(() => _clients = clients);
    } catch (_) {}
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(projectRepositoryProvider);
      final p = await repo.getById(widget.id!);
      if (p == null) {
        if (mounted) setState(() => _error = 'Project not found');
        return;
      }
      _name.text = p.name;
      _description.text = p.description ?? '';
      _budgetCurrency = p.budgetCurrency;
      _exchangePolicy = p.exchangePolicy;
      _fixedRate = p.fixedExchangeRateScaled != null
          ? formatScaledExchangeRate(p.fixedExchangeRateScaled!)
          : '';
      _budget.text = formatMinorUnits(p.budgetAmountMinor, p.budgetCurrency);
      _clientId = p.clientId;
      _status = p.status;
      _startDate = p.startDate;
      _endDate = p.endDate;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null) {
      setState(() => _error = 'Please select a client');
      return;
    }
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'End date must be on or after start date');
      return;
    }

    // Parse budget
    final budgetDecimal =
        Decimal.parse(_budget.text.trim().isEmpty ? '0' : _budget.text.trim());
    int budgetMinor;
    try {
      budgetMinor = toMinorUnits(budgetDecimal, _budgetCurrency);
    } catch (e) {
      setState(() => _error = e.toString());
      return;
    }

    // Parse fixed rate if needed
    int? fixedRateScaled;
    if (_isSarFixed) {
      final rateStr = _fixedRate.trim();
      if (rateStr.isEmpty) {
        setState(() =>
            _error = 'Fixed exchange rate is required for SAR fixed policy');
        return;
      }
      try {
        fixedRateScaled = toScaledExchangeRateFromString(rateStr);
      } catch (e) {
        setState(() => _error = e.toString());
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final notifier = ref.read(projectsListProvider.notifier);
    String? fmt(DateTime? d) => d == null
        ? null
        : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    String? err;
    if (_isEdit) {
      err = await notifier.updateProject(
        widget.id!,
        clientId: _clientId,
        name: _name.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        budgetAmountMinor: budgetMinor,
        budgetCurrency: _budgetCurrency,
        exchangePolicy: _exchangePolicy,
        fixedExchangeRateScaled: fixedRateScaled,
        startDate: fmt(_startDate),
        endDate: fmt(_endDate),
        status: _status,
      );
    } else {
      err = await notifier.create(
        clientId: _clientId!,
        name: _name.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        budgetAmountMinor: budgetMinor,
        budgetCurrency: _budgetCurrency,
        exchangePolicy: _exchangePolicy,
        fixedExchangeRateScaled: fixedRateScaled,
        startDate: fmt(_startDate),
        endDate: fmt(_endDate),
        status: _status,
      );
    }

    setState(() => _saving = false);
    if (err == null) {
      if (mounted) context.go('/projects');
    } else {
      setState(() => _error = err);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete project'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final err =
        await ref.read(projectsListProvider.notifier).delete(widget.id!);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else if (mounted) {
      context.go('/projects');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit project' : 'New project'),
        actions: _isEdit
            ? [
                IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Client *'),
                initialValue: _clientId,
                items: _clients
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _clientId = v),
                validator: (v) => v == null ? 'Select a client' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _budget,
                      decoration: InputDecoration(
                        labelText: 'Budget *',
                        prefixText:
                            _budgetCurrency == kCurrencySar ? 'SAR ' : 'YER ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Budget is required';
                        final d = Decimal.tryParse(s);
                        if (d == null) return 'Enter a valid amount';
                        if (d < Decimal.zero) return 'Budget must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Currency'),
                      initialValue: _budgetCurrency,
                      items: const [
                        DropdownMenuItem(
                            value: kCurrencyYer, child: Text('YER')),
                        DropdownMenuItem(
                            value: kCurrencySar, child: Text('SAR')),
                      ],
                      onChanged: (v) => setState(() {
                        _budgetCurrency = v ?? kCurrencyYer;
                        if (_budgetCurrency == kCurrencyYer) {
                          _exchangePolicy = kExchangePolicyPerTransaction;
                          _fixedRate = '';
                        }
                      }),
                    ),
                  ),
                ],
              ),
              if (_budgetCurrency == kCurrencySar) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Exchange Policy'),
                  initialValue: _exchangePolicy,
                  items: const [
                    DropdownMenuItem(
                        value: kExchangePolicyFixed, child: Text('Fixed Rate')),
                    DropdownMenuItem(
                        value: kExchangePolicyPerTransaction,
                        child: Text('Per Transaction')),
                  ],
                  onChanged: (v) => setState(() =>
                      _exchangePolicy = v ?? kExchangePolicyPerTransaction),
                ),
                if (_isSarFixed) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: TextEditingController(text: _fixedRate),
                    decoration: const InputDecoration(
                      labelText: 'Fixed Exchange Rate (YER per SAR)',
                      hintText: 'e.g. 410.000000',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => _fixedRate = v,
                    validator: (v) {
                      if (!_isSarFixed) return null;
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) {
                        return 'Rate is required for fixed SAR policy';
                      }
                      final d = Decimal.tryParse(s);
                      if (d == null || d <= Decimal.zero) {
                        return 'Enter a positive rate';
                      }
                      return null;
                    },
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Start date'),
                        child: Text(_startDate == null
                            ? '—'
                            : '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'End date'),
                        child: Text(_endDate == null
                            ? '—'
                            : '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status'),
                initialValue: _status,
                items: _statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'planning'),
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
                    : Text(_isEdit ? 'Update' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
