/// Centralized API endpoint paths.
///
/// Treat this as the single source of truth for frontend API paths.
/// Do not hardcode endpoint strings in screens or providers.
class Endpoints {
  Endpoints._();

  // Health
  static const String health = '/health';
  static const String healthDb = '/health/db';

  // Auth
  static const String login = '/auth/login';

  // Clients
  static const String clients = '/clients';
  static String client(String id) => '/clients/$id';

  // Projects
  static const String projects = '/projects';
  static String project(String id) => '/projects/$id';

  // Milestones
  static const String milestones = '/milestones';
  static String milestone(String id) => '/milestones/$id';

  // Payments
  static const String payments = '/payments';
  static String payment(String id) => '/payments/$id';

  // Expenses
  static const String expenses = '/expenses';
  static String expense(String id) => '/expenses/$id';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';
  static const String dashboardProjects = '/dashboard/projects';
  static const String dashboardFinance = '/dashboard/finance';

  // Reports
  static const String reportProjectStatus = '/reports/project-status';
  static const String reportFinancialSummary = '/reports/financial-summary';
  static const String reportExpenseAnalysis = '/reports/expense-analysis';

  // Files & Export
  static const String filesUpload = '/files/upload';
  static String file(String id) => '/files/$id';
  static const String exportReports = '/export/reports';
  static String exportProject(String id) => '/export/projects/$id';
}
