import 'package:drift/drift.dart';

import '../app_database.dart';

class ReportsProjectStatusRow {
  const ReportsProjectStatusRow({
    required this.projectId,
    required this.name,
    required this.status,
    required this.budgetAmountMinor,
    required this.budgetCurrency,
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
    required this.milestoneCount,
    required this.completedMilestones,
  });

  final String projectId;
  final String name;
  final String status;
  final int budgetAmountMinor;
  final String budgetCurrency;
  final int totalPaymentsYer;
  final int totalExpensesYer;
  final int milestoneCount;
  final int completedMilestones;
}

class ReportsProjectFinanceRow {
  const ReportsProjectFinanceRow(
    this.projectId,
    this.name,
    this.paymentsYer,
    this.expensesYer, {
    required this.paymentsSar,
    required this.expensesSar,
    required this.transfersInSar,
    required this.transfersOutSar,
    required this.transfersInYer,
    required this.transfersOutYer,
  });
  final String projectId;
  final String name;
  final int paymentsYer;
  final int expensesYer;

  /// Actual payments received in SAR (original currency minor units).
  final int paymentsSar;

  /// Actual expenses in SAR (original currency minor units).
  final int expensesSar;

  /// Net transfers into the SAR wallet (credits − debits).
  final int transfersInSar;

  /// Net transfers out of the SAR wallet (debits). Kept separate so the
  /// report can show transfer flow detail.
  final int transfersOutSar;

  /// Net transfers into the YER wallet.
  final int transfersInYer;

  /// Net transfers out of the YER wallet.
  final int transfersOutYer;

  /// Actual SAR wallet balance = SAR payments − SAR expenses + transfers in
  /// − transfers out.
  int get sarWalletBalance =>
      paymentsSar - expensesSar + transfersInSar - transfersOutSar;

  /// Actual YER wallet balance = YER payments − YER expenses + transfers
  /// in − transfers out.
  int get yerWalletBalance =>
      paymentsYer - expensesYer + transfersInYer - transfersOutYer;
}

class ReportsCategoryRow {
  const ReportsCategoryRow(
    this.projectId,
    this.projectName,
    this.category,
    this.totalYer,
  );
  final String projectId;
  final String projectName;
  final String category;
  final int totalYer;
}

/// Read-only derived Reports queries. Report results are never persisted.
class ReportsDao {
  ReportsDao(this.db);
  final AppDatabase db;

  Future<bool> projectExists(String projectId) async {
    final row = await db.customSelect(
      'SELECT EXISTS(SELECT 1 FROM projects WHERE id = ?) AS found',
      variables: [Variable.withString(projectId)],
      readsFrom: {db.projects},
    ).getSingle();
    return row.read<int>('found') == 1;
  }

  Future<List<ReportsProjectStatusRow>> getProjectStatus({
    String? projectId,
    String? status,
  }) async {
    final predicates = <String>[];
    final variables = <Variable<Object>>[];
    if (projectId != null) {
      predicates.add('p.id = ?');
      variables.add(Variable.withString(projectId));
    }
    if (status != null) {
      predicates.add('p.status = ?');
      variables.add(Variable.withString(status));
    }
    final where = predicates.isEmpty ? '' : 'WHERE ${predicates.join(' AND ')}';
    final rows = await db
        .customSelect(
            '''
      SELECT p.id, p.name, p.status, p.budget_amount_minor, p.budget_currency,
        COALESCE(pay.total, 0) AS payments_yer,
        COALESCE(exp.total, 0) AS expenses_yer,
        COALESCE(ms.total, 0) AS milestone_count,
        COALESCE(ms.completed, 0) AS completed_milestones
      FROM projects p
      LEFT JOIN (
        SELECT project_id, SUM(converted_yer_amount) AS total
        FROM payments WHERE is_deleted = 0 GROUP BY project_id
      ) pay ON pay.project_id = p.id
      LEFT JOIN (
        SELECT project_id, SUM(converted_yer_amount) AS total
        FROM expenses WHERE is_deleted = 0 GROUP BY project_id
      ) exp ON exp.project_id = p.id
      LEFT JOIN (
        SELECT project_id, COUNT(*) AS total,
          SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed
        FROM milestones GROUP BY project_id
      ) ms ON ms.project_id = p.id
      $where
      ORDER BY p.name COLLATE NOCASE, p.id
    ''',
            variables: variables,
            readsFrom: {
              db.projects,
              db.payments,
              db.expenses,
              db.milestones,
            })
        .get();
    return rows
        .map((row) => ReportsProjectStatusRow(
              projectId: row.read<String>('id'),
              name: row.read<String>('name'),
              status: row.read<String>('status'),
              budgetAmountMinor: row.read<int>('budget_amount_minor'),
              budgetCurrency: row.read<String>('budget_currency'),
              totalPaymentsYer: row.read<int>('payments_yer'),
              totalExpensesYer: row.read<int>('expenses_yer'),
              milestoneCount: row.read<int>('milestone_count'),
              completedMilestones: row.read<int>('completed_milestones'),
            ))
        .toList();
  }

  Future<List<ReportsProjectFinanceRow>> getFinancialSummary({
    String? startDate,
    String? endDate,
    String? projectId,
  }) async {
    final pay =
        _financialPredicates('payment_date', startDate, endDate, projectId);
    final exp =
        _financialPredicates('expense_date', startDate, endDate, projectId);
    final trn = _financialPredicates('date', startDate, endDate, projectId,
        projectColumn: 'project_id');
    final rows = await db.customSelect('''
      SELECT p.id, p.name,
        COALESCE(pay_yer.total, 0) AS payments_yer,
        COALESCE(exp_yer.total, 0) AS expenses_yer,
        COALESCE(pay_sar.total, 0) AS payments_sar,
        COALESCE(exp_sar.total, 0) AS expenses_sar,
        COALESCE(trn_in_sar.total, 0) AS transfers_in_sar,
        COALESCE(trn_out_sar.total, 0) AS transfers_out_sar,
        COALESCE(trn_in_yer.total, 0) AS transfers_in_yer,
        COALESCE(trn_out_yer.total, 0) AS transfers_out_yer
      FROM projects p
      LEFT JOIN (
        SELECT project_id, SUM(converted_yer_amount) AS total
        FROM payments WHERE ${pay.sql} GROUP BY project_id
      ) pay_yer ON pay_yer.project_id = p.id
      LEFT JOIN (
        SELECT project_id, SUM(converted_yer_amount) AS total
        FROM expenses WHERE ${exp.sql} GROUP BY project_id
      ) exp_yer ON exp_yer.project_id = p.id
      LEFT JOIN (
        SELECT project_id, SUM(original_amount_minor) AS total
        FROM payments WHERE ${pay.sql} AND original_currency = 'SAR'
        GROUP BY project_id
      ) pay_sar ON pay_sar.project_id = p.id
      LEFT JOIN (
        SELECT project_id, SUM(original_amount_minor) AS total
        FROM expenses WHERE ${exp.sql} AND original_currency = 'SAR'
        GROUP BY project_id
      ) exp_sar ON exp_sar.project_id = p.id
      LEFT JOIN (
        SELECT project_id, SUM(target_amount_minor) AS total
        FROM currency_transfers WHERE ${trn.sql} AND target_currency = 'SAR'
        GROUP BY project_id
      ) trn_in_sar ON trn_in_sar.project_id = p.id
      LEFT JOIN (
        SELECT project_id, SUM(source_amount_minor) AS total
        FROM currency_transfers WHERE ${trn.sql} AND source_currency = 'SAR'
        GROUP BY project_id
      ) trn_out_sar ON trn_out_sar.project_id = p.id
      LEFT JOIN (
        SELECT project_id, SUM(target_amount_minor) AS total
        FROM currency_transfers WHERE ${trn.sql} AND target_currency = 'YER'
        GROUP BY project_id
      ) trn_in_yer ON trn_in_yer.project_id = p.id
      LEFT JOIN (
        SELECT project_id, SUM(source_amount_minor) AS total
        FROM currency_transfers WHERE ${trn.sql} AND source_currency = 'YER'
        GROUP BY project_id
      ) trn_out_yer ON trn_out_yer.project_id = p.id
      ${projectId == null ? '' : 'WHERE p.id = ?'}
      ORDER BY p.name COLLATE NOCASE, p.id
    ''', variables: [
      ...pay.variables,
      ...exp.variables,
      ...pay.variables,
      ...exp.variables,
      ...trn.variables,
      ...trn.variables,
      ...trn.variables,
      ...trn.variables,
      if (projectId != null) Variable.withString(projectId),
    ], readsFrom: {
      db.projects,
      db.payments,
      db.expenses,
      db.currencyTransfers,
    }).get();
    return rows
        .map((row) => ReportsProjectFinanceRow(
              row.read<String>('id'),
              row.read<String>('name'),
              row.read<int>('payments_yer'),
              row.read<int>('expenses_yer'),
              paymentsSar: row.read<int>('payments_sar'),
              expensesSar: row.read<int>('expenses_sar'),
              transfersInSar: row.read<int>('transfers_in_sar'),
              transfersOutSar: row.read<int>('transfers_out_sar'),
              transfersInYer: row.read<int>('transfers_in_yer'),
              transfersOutYer: row.read<int>('transfers_out_yer'),
            ))
        .toList();
  }

  Future<List<ReportsCategoryRow>> getExpenseAnalysis({
    String? startDate,
    String? endDate,
    String? projectId,
  }) async {
    final filter = _financialPredicates(
        'e.expense_date', startDate, endDate, projectId,
        projectColumn: 'e.project_id');
    final rows = await db
        .customSelect(
            '''
      SELECT e.project_id, p.name AS project_name, e.category,
        SUM(e.converted_yer_amount) AS total_yer
      FROM expenses e
      JOIN projects p ON p.id = e.project_id
      WHERE ${filter.sql}
      GROUP BY e.project_id, p.name, e.category
      ORDER BY p.name COLLATE NOCASE, e.project_id, e.category
    ''',
            variables: filter.variables,
            readsFrom: {
              db.expenses,
              db.projects,
            })
        .get();
    return rows
        .map((row) => ReportsCategoryRow(
              row.read<String>('project_id'),
              row.read<String>('project_name'),
              row.read<String>('category'),
              row.read<int>('total_yer'),
            ))
        .toList();
  }

  _SqlFilter _financialPredicates(
    String dateColumn,
    String? startDate,
    String? endDate,
    String? projectId, {
    String projectColumn = 'project_id',
  }) {
    final predicates = <String>['is_deleted = 0'];
    final variables = <Variable<Object>>[];
    if (startDate != null) {
      predicates.add('$dateColumn >= ?');
      variables.add(Variable.withString(startDate));
    }
    if (endDate != null) {
      predicates.add('$dateColumn <= ?');
      variables.add(Variable.withString(endDate));
    }
    if (projectId != null) {
      predicates.add('$projectColumn = ?');
      variables.add(Variable.withString(projectId));
    }
    return _SqlFilter(predicates.join(' AND '), variables);
  }
}

class _SqlFilter {
  const _SqlFilter(this.sql, this.variables);
  final String sql;
  final List<Variable<Object>> variables;
}
