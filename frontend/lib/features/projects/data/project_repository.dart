import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/dio_provider.dart';
import 'project_dto.dart';

class ProjectRepository {
  ProjectRepository(this._dio);
  final Dio _dio;

  Future<List<ProjectDto>> list({
    String? clientId,
    String? status,
    int skip = 0,
    int limit = 50,
  }) async {
    final res = await _dio.get(Endpoints.projects, queryParameters: {
      if (clientId != null) 'client_id': clientId,
      if (status != null) 'status': status,
      'skip': skip,
      'limit': limit,
    });
    final list = res.data as List;
    return list.map((e) => ProjectDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProjectDto> get(String id) async {
    final res = await _dio.get(Endpoints.project(id));
    return ProjectDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ProjectDto> create(ProjectCreateDto dto) async {
    final res = await _dio.post(Endpoints.projects, data: dto.toJson());
    return ProjectDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ProjectDto> update(String id, ProjectUpdateDto dto) async {
    final res = await _dio.put(Endpoints.project(id), data: dto.toJson());
    return ProjectDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(Endpoints.project(id));
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(dioProvider));
});