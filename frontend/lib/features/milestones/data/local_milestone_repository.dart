import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_constants.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/milestones_dao.dart';
import '../../../core/database/daos/projects_dao.dart';
import '../../../core/uuid/uuid_util.dart';
import '../domain/milestone_entity.dart';
import '../domain/milestone_repository_interface.dart';
import 'milestone_mapper.dart';

/// Local (Drift/SQLite) implementation of [MilestoneRepositoryInterface].
class LocalMilestoneRepository implements MilestoneRepositoryInterface {
  LocalMilestoneRepository(this._dao, this._projectsDao);

  final MilestonesDao _dao;
  final ProjectsDao _projectsDao;

  @override
  Future<List<MilestoneEntity>> listByProject(String projectId) async {
    UuidUtil.validate(projectId);
    final rows = await _dao.getMilestonesByProject(projectId);
    return rows.map(MilestoneMapper.rowToEntity).toList();
  }

  @override
  Future<MilestoneEntity?> getById(String id) async {
    UuidUtil.validate(id);
    final row = await _dao.getMilestoneById(id);
    if (row == null) return null;
    return MilestoneMapper.rowToEntity(row);
  }

  @override
  Future<MilestoneEntity> create({
    required String projectId,
    required String title,
    String? description,
    required String dueDate,
    String status = 'pending',
  }) async {
    UuidUtil.validate(projectId);
    _validateTitle(title);
    _validateStatus(status);
    _validateDueDate(dueDate);

    // Verify project exists
    final project = await _projectsDao.getProjectById(projectId);
    if (project == null) {
      throw ArgumentError('Project not found: $projectId');
    }

    final id = UuidUtil.generate();
    final now = _utcNowIso();

    await _dao.insertMilestone(MilestoneMapper.entityToInsertCompanion(
      id: id,
      projectId: projectId,
      title: title.trim(),
      description:
          description?.trim().isEmpty == true ? null : description?.trim(),
      dueDate: dueDate,
      status: status,
      createdAt: now,
    ));

    final row = await _dao.getMilestoneById(id);
    return MilestoneMapper.rowToEntity(row!);
  }

  @override
  Future<MilestoneEntity> update({
    required String id,
    String? title,
    String? description,
    String? dueDate,
    String? status,
  }) async {
    UuidUtil.validate(id);

    final existing = await _dao.getMilestoneById(id);
    if (existing == null) {
      throw ArgumentError('Milestone not found: $id');
    }

    if (title != null) _validateTitle(title);
    if (status != null) _validateStatus(status);
    if (dueDate != null) _validateDueDate(dueDate);

    await _dao.updateMilestone(
      id,
      MilestoneMapper.entityToUpdateCompanion(
        title: title?.trim(),
        description:
            description?.trim().isEmpty == true ? null : description?.trim(),
        dueDate: dueDate,
        status: status,
      ),
    );

    final row = await _dao.getMilestoneById(id);
    return MilestoneMapper.rowToEntity(row!);
  }

  @override
  Future<MilestoneEntity> complete(String id) async {
    UuidUtil.validate(id);

    final existing = await _dao.getMilestoneById(id);
    if (existing == null) {
      throw ArgumentError('Milestone not found: $id');
    }

    // Idempotent: if already completed, just return it
    if (existing.status == 'completed') {
      return MilestoneMapper.rowToEntity(existing);
    }

    await _dao.updateMilestone(
      id,
      MilestoneMapper.entityToUpdateCompanion(status: 'completed'),
    );

    final row = await _dao.getMilestoneById(id);
    return MilestoneMapper.rowToEntity(row!);
  }

  @override
  Future<void> delete(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getMilestoneById(id);
    if (existing == null) {
      throw ArgumentError('Milestone not found: $id');
    }
    await _dao.deleteMilestone(id);
  }

  @override
  Future<int> countByProject(String projectId) async {
    UuidUtil.validate(projectId);
    return _dao.countByProject(projectId);
  }

  @override
  Future<int> countCompletedByProject(String projectId) async {
    UuidUtil.validate(projectId);
    return _dao.countCompletedByProject(projectId);
  }

  // ── Validation helpers ──

  void _validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Milestone title is required');
    }
  }

  void _validateStatus(String status) {
    if (!kMilestoneStatuses.contains(status)) {
      throw ArgumentError('Invalid milestone status: $status');
    }
  }

  void _validateDueDate(String dueDate) {
    // Expecting YYYY-MM-DD format
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dueDate)) {
      throw ArgumentError(
          'Invalid due date format: $dueDate (expected YYYY-MM-DD)');
    }
    try {
      DateTime.parse('${dueDate}T00:00:00');
    } catch (e) {
      throw ArgumentError('Invalid due date: $dueDate');
    }
  }

  String _utcNowIso() => DateTime.now().toUtc().toIso8601String();
}

/// Active runtime provider for the local milestone repository.
final localMilestoneRepositoryProvider =
    Provider<MilestoneRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalMilestoneRepository(db.milestonesDao, db.projectsDao);
});
