import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_reports_repository.dart';
import '../domain/report_filters.dart';
import '../domain/report_models.dart';
import '../domain/reports_repository_interface.dart';

export '../domain/report_filters.dart';
export '../domain/report_models.dart';

/// Active runtime Reports repository. This path never reads Dio or JWT.
final reportsRepositoryProvider = Provider<ReportsRepositoryInterface>(
  (ref) => ref.watch(localReportsRepositoryProvider),
);

final reportResultProvider =
    FutureProvider.family<ReportResult, ReportFilters>((ref, filters) {
  return ref.watch(reportsRepositoryProvider).generate(filters);
});

void invalidateReports(Ref ref) {
  ref.invalidate(reportResultProvider);
}
