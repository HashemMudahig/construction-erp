class DashboardSummary {
  const DashboardSummary({
    required this.activeClientCount,
    required this.activeProjectCount,
    required this.completedProjectCount,
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
  });

  final int activeClientCount;
  final int activeProjectCount;
  final int completedProjectCount;
  final int totalPaymentsYer;
  final int totalExpensesYer;

  int get netCashFlowYer => totalPaymentsYer - totalExpensesYer;
}

class DashboardProjectOverview {
  const DashboardProjectOverview({
    required this.projectId,
    required this.projectName,
    required this.projectStatus,
    required this.clientName,
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
    required this.completedMilestones,
    required this.totalMilestones,
  });

  final String projectId;
  final String projectName;
  final String projectStatus;
  final String clientName;
  final int totalPaymentsYer;
  final int totalExpensesYer;
  final int completedMilestones;
  final int totalMilestones;

  int get netCashFlowYer => totalPaymentsYer - totalExpensesYer;
  int get milestoneProgressPercent =>
      totalMilestones == 0 ? 0 : (completedMilestones * 100) ~/ totalMilestones;
}

class DashboardFinanceMonth {
  const DashboardFinanceMonth({
    required this.year,
    required this.month,
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
  });

  final int year;
  final int month;
  final int totalPaymentsYer;
  final int totalExpensesYer;

  int get netCashFlowYer => totalPaymentsYer - totalExpensesYer;
  String get canonicalKey => '$year-${month.toString().padLeft(2, '0')}';
}
