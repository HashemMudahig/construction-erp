import 'report_filters.dart';
import 'report_models.dart';

abstract interface class ReportsRepositoryInterface {
  Future<ReportResult> generate(ReportFilters filters);
}
