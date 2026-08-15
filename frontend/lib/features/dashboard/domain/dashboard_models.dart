class DashboardSummary {
  const DashboardSummary({
    required this.activeClientCount,
    required this.totalProjectCount,
    required this.planningProjectCount,
    required this.activeProjectCount,
    required this.completedProjectCount,
    required this.onHoldProjectCount,
    required this.cancelledProjectCount,
    required this.totalPaymentsYer,
    required this.totalExpensesYer,
  });

  final int activeClientCount;
  final int totalProjectCount;
  final int planningProjectCount;
  final int activeProjectCount;
  final int completedProjectCount;
  final int onHoldProjectCount;
  final int cancelledProjectCount;
  final int totalPaymentsYer;
  final int totalExpensesYer;

  int get netCashFlowYer => totalPaymentsYer - totalExpensesYer;

  /// Invariant: the sum of all project status counters must equal the total
  /// number of projects. Each project has exactly one persisted status, so the
  /// mutually-exclusive buckets must never overlap or omit a project.
  int get statusCountsSum =>
      planningProjectCount +
      activeProjectCount +
      completedProjectCount +
      onHoldProjectCount +
      cancelledProjectCount;

  bool get statusCountsConsistent => statusCountsSum == totalProjectCount;
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
