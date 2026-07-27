import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_milestone_repository.dart';
import '../domain/milestone_entity.dart';
import '../domain/milestone_repository_interface.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../reports/presentation/report_providers.dart';

/// Active runtime milestone repository provider.
///
/// Uses the sole production implementation: [LocalMilestoneRepository].
final milestoneRepositoryProvider =
    Provider<MilestoneRepositoryInterface>((ref) {
  return ref.watch(localMilestoneRepositoryProvider);
});

/// List milestones by project from local storage.
final milestonesByProjectProvider =
    FutureProvider.family<List<MilestoneEntity>, String>(
        (ref, projectId) async {
  final repo = ref.read(milestoneRepositoryProvider);
  return repo.listByProject(projectId);
});

class MilestoneActions {
  MilestoneActions(this._ref);
  final Ref _ref;

  Future<String?> create({
    required String projectId,
    required String title,
    String? description,
    required String dueDate,
    String status = 'pending',
  }) async {
    try {
      await _ref.read(milestoneRepositoryProvider).create(
            projectId: projectId,
            title: title,
            description: description,
            dueDate: dueDate,
            status: status,
          );
      _ref.invalidate(milestonesByProjectProvider(projectId));
      invalidateDashboard(_ref);
      invalidateReports(_ref);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> update({
    required String id,
    String? title,
    String? description,
    String? dueDate,
    String? status,
    String? projectId,
  }) async {
    try {
      await _ref.read(milestoneRepositoryProvider).update(
            id: id,
            title: title,
            description: description,
            dueDate: dueDate,
            status: status,
          );
      if (projectId != null) {
        _ref.invalidate(milestonesByProjectProvider(projectId));
      }
      invalidateDashboard(_ref);
      invalidateReports(_ref);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> complete(String id, {String? projectId}) async {
    try {
      await _ref.read(milestoneRepositoryProvider).complete(id);
      if (projectId != null) {
        _ref.invalidate(milestonesByProjectProvider(projectId));
      }
      invalidateDashboard(_ref);
      invalidateReports(_ref);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> delete(String id, {String? projectId}) async {
    try {
      await _ref.read(milestoneRepositoryProvider).delete(id);
      if (projectId != null) {
        _ref.invalidate(milestonesByProjectProvider(projectId));
      }
      invalidateDashboard(_ref);
      invalidateReports(_ref);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final milestoneActionsProvider =
    Provider<MilestoneActions>((ref) => MilestoneActions(ref));
