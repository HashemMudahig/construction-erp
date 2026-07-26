enum ReportType { projectStatus, financialSummary, expenseAnalysis }

class ReportFilters {
  const ReportFilters({
    this.type = ReportType.projectStatus,
    this.startDate,
    this.endDate,
    this.projectId,
    this.status,
  });

  final ReportType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? projectId;
  final String? status;

  static const validStatuses = {
    'planning',
    'active',
    'completed',
    'on_hold',
    'cancelled',
  };

  void validate() {
    if (startDate != null && endDate != null) {
      if (_dateOnly(startDate!).isAfter(_dateOnly(endDate!))) {
        throw const ReportFilterException(
          'Start date cannot be after end date.',
        );
      }
    }
    if (projectId != null && !_uuidPattern.hasMatch(projectId!)) {
      throw const ReportFilterException('Invalid project ID.');
    }
    if (status != null && !validStatuses.contains(status)) {
      throw const ReportFilterException('Invalid project status.');
    }
  }

  String? get startDateIso =>
      startDate == null ? null : _formatDate(_dateOnly(startDate!));
  String? get endDateIso =>
      endDate == null ? null : _formatDate(_dateOnly(endDate!));

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  @override
  bool operator ==(Object other) =>
      other is ReportFilters &&
      other.type == type &&
      other.startDateIso == startDateIso &&
      other.endDateIso == endDateIso &&
      other.projectId == projectId &&
      other.status == status;

  @override
  int get hashCode =>
      Object.hash(type, startDateIso, endDateIso, projectId, status);
}

class ReportFilterException implements Exception {
  const ReportFilterException(this.message);
  final String message;

  @override
  String toString() => message;
}
