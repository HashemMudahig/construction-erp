import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/milestones_table.dart';

part 'milestones_dao.g.dart';

/// Data Access Object for the [Milestones] table.
///
/// Used by [LocalMilestoneRepository] — not accessed directly by screens.
@DriftAccessor(tables: [Milestones])
class MilestonesDao extends DatabaseAccessor<AppDatabase>
    with _$MilestonesDaoMixin {
  MilestonesDao(super.db);

  Future<int> insertMilestone(MilestonesCompanion milestone) =>
      into(milestones).insert(milestone);

  Future<MilestoneRow?> getMilestoneById(String id) =>
      (select(milestones)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// List milestones by project, ordered by due date ascending.
  Future<List<MilestoneRow>> getMilestonesByProject(String projectId) =>
      (select(milestones)
            ..where((t) => t.projectId.equals(projectId))
            ..orderBy([(t) => OrderingTerm(expression: t.dueDate)]))
          .get();

  Future<bool> updateMilestone(String id, MilestonesCompanion companion) =>
      (update(milestones)..where((t) => t.id.equals(id)))
          .write(companion)
          .then((rows) => rows > 0);

  Future<int> deleteMilestone(String id) =>
      (delete(milestones)..where((t) => t.id.equals(id))).go();

  /// Count total milestones for a project.
  Future<int> countByProject(String projectId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM milestones WHERE project_id = ?',
      variables: [Variable.withString(projectId)],
      readsFrom: {milestones},
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Count completed milestones for a project.
  Future<int> countCompletedByProject(String projectId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM milestones WHERE project_id = ? AND status = ?',
      variables: [
        Variable.withString(projectId),
        Variable.withString('completed')
      ],
      readsFrom: {milestones},
    ).getSingle();
    return result.read<int>('cnt');
  }
}
