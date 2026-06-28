import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/project_dto.dart';
import '../data/project_repository.dart';
import '../domain/project_entity.dart';

final projectsListProvider =
    AsyncNotifierProvider<ProjectsListNotifier, List<ProjectEntity>>(
  ProjectsListNotifier.new,
);

class ProjectsListNotifier extends AsyncNotifier<List<ProjectEntity>> {
  String? _clientId;
  String? _status;

  @override
  Future<List<ProjectEntity>> build() => _fetch();

  Future<List<ProjectEntity>> _fetch() async {
    final repo = ref.read(projectRepositoryProvider);
    final dtos = await repo.list(clientId: _clientId, status: _status);
    return dtos.map((d) => d.toEntity()).toList();
  }

  Future<void> setFilters({String? clientId, String? status}) async {
    _clientId = clientId;
    _status = status;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<String?> create(ProjectCreateDto dto) async {
    try {
      await ref.read(projectRepositoryProvider).create(dto);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateProject(String id, ProjectUpdateDto dto) async {
    try {
      await ref.read(projectRepositoryProvider).update(id, dto);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> delete(String id) async {
    try {
      await ref.read(projectRepositoryProvider).delete(id);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final projectDetailProvider =
    FutureProvider.family<ProjectEntity, String>((ref, id) async {
  final repo = ref.read(projectRepositoryProvider);
  final dto = await repo.get(id);
  return dto.toEntity();
});