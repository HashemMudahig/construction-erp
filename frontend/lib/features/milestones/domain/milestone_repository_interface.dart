import 'milestone_entity.dart';

/// Contract for milestone data access operations.
///
/// Implementations:
/// - [LocalMilestoneRepository] — active runtime, uses Drift/SQLite.
/// - [ApiMilestoneRepository] — preserved remote adapter, uses Dio/FastAPI.
abstract class MilestoneRepositoryInterface {
  /// Lists milestones for the given [projectId], ordered by due date ascending.
  Future<List<MilestoneEntity>> listByProject(String projectId);

  /// Returns the milestone with the given [id], or null.
  Future<MilestoneEntity?> getById(String id);

  /// Creates a new milestone. Returns the created entity.
  Future<MilestoneEntity> create({
    required String projectId,
    required String title,
    String? description,
    required String dueDate,
    String status = 'pending',
  });

  /// Updates an existing milestone. Only non-null fields are updated.
  Future<MilestoneEntity> update({
    required String id,
    String? title,
    String? description,
    String? dueDate,
    String? status,
  });

  /// Completes a milestone. Sets stored status to 'completed'.
  /// Idempotent: completing an already-completed milestone is safe.
  Future<MilestoneEntity> complete(String id);

  /// Deletes a milestone. Does not affect the parent project.
  Future<void> delete(String id);

  /// Returns the count of milestones for the given [projectId].
  Future<int> countByProject(String projectId);

  /// Returns the count of completed milestones for the given [projectId].
  Future<int> countCompletedByProject(String projectId);
}
