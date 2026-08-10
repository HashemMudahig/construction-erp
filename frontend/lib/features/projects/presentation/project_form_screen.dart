import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../clients/presentation/client_providers.dart';
import '../../clients/presentation/add_client_dialog.dart';
import '../../clients/domain/client_entity.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/finance/exchange_rate.dart';
import '../../../core/database/finance/money_scale.dart';
import 'project_providers.dart';
import '../../../core/localization/app_localizations.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({this.id, this.clientId, super.key});
  final String? id;
  final String? clientId;

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  /// Sentinel dropdown value representing the "add new client" action.
  static const _kAddNewClientValue = '__add_new_client__';

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
  bool _contractLocked = false;
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

  Future<void> _onClientChanged(String? value) async {
    if (value == _kAddNewClientValue) {
      // Reset dropdown selection before opening the dialog so the form
      // does not visually stick to the "+ add new client" entry.
      setState(() => _clientId = null);
      final created = await AddClientDialog.show(context);
      if (created == null) return;
      // Refresh the local cache (the dialog already invalidated the
      // clientsListProvider, but we keep our own copy in sync too).
      await _loadClients();
      if (!mounted) return;
      setState(() => _clientId = created.id);
      return;
    }
    setState(() => _clientId = value);
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(projectRepositoryProvider);
      final p = await repo.getById(widget.id!);
      if (p == null) {
        if (mounted)
          setState(() => _error = context.tr('err_project_not_found'));
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
      // Lock the contract value once any financial transaction exists.
      _contractLocked = await repo.hasChildRecords(widget.id!);
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
      setState(() => _error = context.tr('err_select_project_owner'));
      return;
    }
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      setState(() => _error = context.tr('err_end_date_before_start'));
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
        setState(() => _error = context.tr('err_fixed_rate_required'));
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
        budgetAmountMinor: _contractLocked ? null : budgetMinor,
        budgetCurrency: _contractLocked ? null : _budgetCurrency,
        exchangePolicy: _contractLocked ? null : _exchangePolicy,
        fixedExchangeRateScaled:
            _contractLocked ? null : fixedRateScaled,
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
        title: Text(context.tr('delete_project_title')),
        content: Text(context.tr('delete_project_content')),
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
        title: Text(
            _isEdit ? context.tr('edit_project') : context.tr('new_project')),
        actions: _isEdit
            ? [
                IconButton(
                    icon: Icon(Icons.delete),
                    tooltip: context.tr('delete'),
                    onPressed: _delete)
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                    labelText: context.tr('project_owner_required')),
                initialValue: _clientId,
                items: [
                  ..._clients.map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name))),
                  DropdownMenuItem(
                    value: _kAddNewClientValue,
                    child: Text(context.tr('add_new_client')),
                  ),
                ],
                onChanged: _onClientChanged,
                validator: (v) => (v == null || v == _kAddNewClientValue)
                    ? context.tr('err_select_project_owner')
                    : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                    labelText: context.tr('project_name_required')),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.tr('err_enter_project_name')
                    : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: InputDecoration(
                    labelText: context.tr('project_description')),
                maxLines: 2,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _budget,
                      enabled: !_contractLocked,
                      decoration: InputDecoration(
                        labelText: context.tr('contract_value_required'),
                        prefixText:
                            _budgetCurrency == kCurrencySar ? 'SAR ' : 'YER ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (_contractLocked) return null;
                        final s = v?.trim() ?? '';
                        if (s.isEmpty)
                          return context.tr('err_valid_contract_value');
                        final d = Decimal.tryParse(s);
                        if (d == null)
                          return context.tr('err_valid_contract_value');
                        if (d < Decimal.zero)
                          return context.tr('err_contract_value_gt_zero');
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
                      initialValue: _budgetCurrency,
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
                      onChanged: _contractLocked
                          ? null
                          : (v) => setState(() {
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
              if (_contractLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.tr('contract_value_locked'),
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_budgetCurrency == kCurrencySar) ...[
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration:
                      InputDecoration(labelText: context.tr('exchange_policy')),
                  initialValue: _exchangePolicy,
                  items: [
                    DropdownMenuItem(
                        value: kExchangePolicyFixed,
                        child: Text(context.tr('fixed_rate'))),
                    DropdownMenuItem(
                        value: kExchangePolicyPerTransaction,
                        child: Text(context.tr('per_transaction'))),
                  ],
                  onChanged: (v) => setState(() =>
                      _exchangePolicy = v ?? kExchangePolicyPerTransaction),
                ),
                if (_isSarFixed) ...[
                  SizedBox(height: 12),
                  TextFormField(
                    controller: TextEditingController(text: _fixedRate),
                    decoration: InputDecoration(
                      labelText: context.tr('yemeni_rials_per_1_saudi_riyal'),
                      hintText: context.tr('fixed_exchange_rate_hint'),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => _fixedRate = v,
                    validator: (v) {
                      if (!_isSarFixed) return null;
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) {
                        return context.tr('err_fixed_rate_required');
                      }
                      final d = Decimal.tryParse(s);
                      if (d == null || d <= Decimal.zero) {
                        return context.tr('err_enter_positive_rate');
                      }
                      return null;
                    },
                  ),
                ],
              ],
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                            labelText: context.tr('start_date')),
                        child: Text(_startDate == null
                            ? '—'
                            : '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration:
                            InputDecoration(labelText: context.tr('end_date')),
                        child: Text(_endDate == null
                            ? '—'
                            : '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration:
                    InputDecoration(labelText: context.tr('project_status')),
                initialValue: _status,
                items: _statuses
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text(context.tr('status_${s}'))))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'planning'),
              ),
              SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEdit
                        ? context.tr('save_changes')
                        : context.tr('create_project')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
