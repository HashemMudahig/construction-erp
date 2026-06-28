import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/milestone_dto.dart';
import '../data/milestone_repository.dart';
import '../domain/milestone_entity.dart';

final milestonesByProjectProvider =
    FutureProvider.family<List<MilestoneEntity>, String>((ref, projectId) async {
  final repo = ref.read(milestoneRepositoryProvider);
  final dtos = await repo.list(projectId: projectId);
  return dtos.map((d) => d.toEntity()).toList();
});

class MilestoneActions {
  MilestoneActions(this._ref);
  final Ref _ref;

  Future<String?> create(MilestoneCreateDto dto) async {
    try {
      await _ref.read(milestoneRepositoryProvider).create(dto);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> update(String id, MilestoneUpdateDto dto) async {
    try {
      await _ref.read(milestoneRepositoryProvider).update(id, dto);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> complete(String id) async {
    try {
      await _ref.read(milestoneRepositoryProvider).complete(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _ref.read(milestoneRepositoryProvider).delete(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final milestoneActionsProvider = Provider<MilestoneActions>((ref) => MilestoneActions(ref));