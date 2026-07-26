import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/projects_table.dart';

part 'projects_dao.g.dart';

/// Data Access Object for the [Projects] table.
///
/// Used by [LocalProjectRepository] — not accessed directly by screens.
@DriftAccessor(tables: [Projects])
class ProjectsDao extends DatabaseAccessor<AppDatabase>
    with _$ProjectsDaoMixin {
  ProjectsDao(super.db);

  Future<int> insertProject(ProjectsCompanion project) =>
      into(projects).insert(project);

  Future<ProjectRow?> getProjectById(String id) =>
      (select(projects)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// All projects ordered by name.
  Future<List<ProjectRow>> getAllProjects() =>
      (select(projects)..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .get();

  /// Filter by client_id.
  Future<List<ProjectRow>> getByClient(String clientId) => (select(projects)
        ..where((t) => t.clientId.equals(clientId))
        ..orderBy([(t) => OrderingTerm(expression: t.name)]))
      .get();

  /// Filter by status.
  Future<List<ProjectRow>> getByStatus(String status) => (select(projects)
        ..where((t) => t.status.equals(status))
        ..orderBy([(t) => OrderingTerm(expression: t.name)]))
      .get();

  /// Filter by client_id and status.
  Future<List<ProjectRow>> getByClientAndStatus(
          String clientId, String status) =>
      (select(projects)
            ..where(
                (t) => t.clientId.equals(clientId) & t.status.equals(status))
            ..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .get();

  /// Search by name (case-insensitive).
  Future<List<ProjectRow>> searchByName(String query) {
    final pattern = '%$query%';
    return (select(projects)
          ..where((t) => t.name.like(pattern))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Future<bool> updateProject(String id, ProjectsCompanion companion) =>
      (update(projects)..where((t) => t.id.equals(id)))
          .write(companion)
          .then((rows) => rows > 0);

  Future<int> deleteProject(String id) =>
      (delete(projects)..where((t) => t.id.equals(id))).go();

  /// Count milestones for a project.
  Future<int> countMilestones(String projectId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM milestones WHERE project_id = ?',
      variables: [Variable.withString(projectId)],
      readsFrom: {attachedDatabase.milestones},
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Count payments for a project.
  Future<int> countPayments(String projectId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM payments WHERE project_id = ?',
      variables: [Variable.withString(projectId)],
      readsFrom: {attachedDatabase.payments},
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Count expenses for a project.
  Future<int> countExpenses(String projectId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM expenses WHERE project_id = ?',
      variables: [Variable.withString(projectId)],
      readsFrom: {attachedDatabase.expenses},
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Sum of converted YER amounts for active (non-deleted) payments of a project.
  Future<int> sumPaymentsYer(String projectId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(converted_yer_amount), 0) AS total FROM payments WHERE project_id = ? AND is_deleted = 0',
      variables: [Variable.withString(projectId)],
      readsFrom: {attachedDatabase.payments},
    ).getSingle();
    return result.read<int>('total');
  }

  /// Sum of converted YER amounts for active (non-deleted) expenses of a project.
  Future<int> sumExpensesYer(String projectId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(converted_yer_amount), 0) AS total FROM expenses WHERE project_id = ? AND is_deleted = 0',
      variables: [Variable.withString(projectId)],
      readsFrom: {attachedDatabase.expenses},
    ).getSingle();
    return result.read<int>('total');
  }
}
