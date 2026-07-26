/// Milestone domain entity.
///
/// [status] is the stored workflow status: pending, in_progress, completed,
/// or overdue (per the accepted Phase 01 enum contract).
///
/// [effectiveStatus] computes the effective status at read time:
/// - If stored status is 'completed', effective status is always 'completed'.
/// - If stored status is not 'completed' and [dueDate] is before [referenceDate],
///   effective status is 'overdue'.
/// - Otherwise, effective status equals the stored status.
class MilestoneEntity {
  MilestoneEntity({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String status;
  final DateTime createdAt;

  /// Returns the effective status at the given [referenceDate].
  ///
  /// A non-completed milestone with a due date before [referenceDate]
  /// is effectively overdue. Completed milestones are never overdue.
  String effectiveStatus(DateTime referenceDate) {
    if (status == 'completed') return 'completed';
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final refDateOnly =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    if (dueDateOnly.isBefore(refDateOnly)) return 'overdue';
    return status;
  }
}
