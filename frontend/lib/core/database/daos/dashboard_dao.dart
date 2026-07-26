import 'package:drift/drift.dart';

import '../app_database.dart';

class DashboardSummaryRow {
  const DashboardSummaryRow({
    required this.activeClients,
    required this.activeProjects,
    required this.completedProjects,
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
  });
  final int activeClients;
  final int activeProjects;
  final int completedProjects;
  final int totalPaymentsYer;
  final int totalExpensesYer;
}

class DashboardProjectRow {
  const DashboardProjectRow({
    required this.id,
    required this.name,
    required this.status,
    required this.clientName,
    required this.paymentsYer,
    required this.expensesYer,
    required this.completedMilestones,
    required this.totalMilestones,
  });
  final String id;
  final String name;
  final String status;
  final String clientName;
  final int paymentsYer;
  final int expensesYer;
  final int completedMilestones;
  final int totalMilestones;
}

class DashboardMonthAggregateRow {
  const DashboardMonthAggregateRow(this.year, this.month, this.totalYer);
  final int year;
  final int month;
  final int totalYer;
}

/// Read-only derived Dashboard queries. No Dashboard totals are persisted.
class DashboardDao {
  DashboardDao(this.db);
  final AppDatabase db;

  Future<DashboardSummaryRow> getSummary() async {
    final row = await db.customSelect('''
      SELECT
        (SELECT COUNT(*) FROM clients WHERE archived = 0) AS active_clients,
        (SELECT COUNT(*) FROM projects WHERE status = 'active') AS active_projects,
        (SELECT COUNT(*) FROM projects WHERE status = 'completed') AS completed_projects,
        (SELECT COALESCE(SUM(converted_yer_amount), 0) FROM payments WHERE is_deleted = 0) AS payments_yer,
        (SELECT COALESCE(SUM(converted_yer_amount), 0) FROM expenses WHERE is_deleted = 0) AS expenses_yer
    ''', readsFrom: {
      db.clients,
      db.projects,
      db.payments,
      db.expenses,
    }).getSingle();
    return DashboardSummaryRow(
      activeClients: row.read<int>('active_clients'),
      activeProjects: row.read<int>('active_projects'),
      completedProjects: row.read<int>('completed_projects'),
      totalPaymentsYer: row.read<int>('payments_yer'),
      totalExpensesYer: row.read<int>('expenses_yer'),
    );
  }

  Future<List<DashboardProjectRow>> getProjectsOverview() async {
    final rows = await db.customSelect('''
      SELECT p.id, p.name, p.status, c.name AS client_name,
        COALESCE(pay.total, 0) AS payments_yer,
        COALESCE(exp.total, 0) AS expenses_yer,
        COALESCE(ms.completed, 0) AS completed_milestones,
        COALESCE(ms.total, 0) AS total_milestones
      FROM projects p
      JOIN clients c ON c.id = p.client_id
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
      ORDER BY p.name COLLATE NOCASE, p.id
    ''', readsFrom: {
      db.projects,
      db.clients,
      db.payments,
      db.expenses,
      db.milestones,
    }).get();
    return rows
        .map((row) => DashboardProjectRow(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              status: row.read<String>('status'),
              clientName: row.read<String>('client_name'),
              paymentsYer: row.read<int>('payments_yer'),
              expensesYer: row.read<int>('expenses_yer'),
              completedMilestones: row.read<int>('completed_milestones'),
              totalMilestones: row.read<int>('total_milestones'),
            ))
        .toList();
  }

  Future<List<DashboardMonthAggregateRow>> getPaymentMonths(
          String firstMonth, String monthAfterLast) =>
      _getMonths('payments', 'payment_date', firstMonth, monthAfterLast);

  Future<List<DashboardMonthAggregateRow>> getExpenseMonths(
          String firstMonth, String monthAfterLast) =>
      _getMonths('expenses', 'expense_date', firstMonth, monthAfterLast);

  Future<List<DashboardMonthAggregateRow>> _getMonths(
    String table,
    String dateColumn,
    String firstMonth,
    String monthAfterLast,
  ) async {
    final rows = await db.customSelect('''
      SELECT CAST(substr($dateColumn, 1, 4) AS INTEGER) AS year,
        CAST(substr($dateColumn, 6, 2) AS INTEGER) AS month,
        COALESCE(SUM(converted_yer_amount), 0) AS total
      FROM $table
      WHERE is_deleted = 0 AND $dateColumn >= ? AND $dateColumn < ?
      GROUP BY substr($dateColumn, 1, 7)
      ORDER BY year, month
    ''', variables: [
      Variable.withString(firstMonth),
      Variable.withString(monthAfterLast),
    ], readsFrom: {
      if (table == 'payments') db.payments else db.expenses,
    }).get();
    return rows
        .map((r) => DashboardMonthAggregateRow(
              r.read<int>('year'),
              r.read<int>('month'),
              r.read<int>('total'),
            ))
        .toList();
  }
}
