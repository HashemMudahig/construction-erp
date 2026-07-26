import 'package:dio/dio.dart';

import '../../../core/constants/endpoints.dart';
import '../domain/milestone_entity.dart';
import '../domain/milestone_repository_interface.dart';
import 'milestone_dto.dart';

/// Preserved remote (FastAPI) milestone repository — legacy class.
///
/// **Deprecated as runtime:** Use [LocalMilestoneRepository] via
/// [localMilestoneRepositoryProvider]. See [ApiMilestoneRepository] for the
/// fully interface-conforming remote implementation.
class MilestoneRepository implements MilestoneRepositoryInterface {
  MilestoneRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<MilestoneEntity>> listByProject(String projectId) async {
    final res = await _dio.get(Endpoints.milestones, queryParameters: {
      'project_id': projectId,
      'skip': 0,
      'limit': 50,
    });
    final list = res.data as List;
    return list
        .map((e) => MilestoneDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<MilestoneEntity?> getById(String id) async {
    final res = await _dio.get(Endpoints.milestone(id));
    return MilestoneDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<MilestoneEntity> create({
    required String projectId,
    required String title,
    String? description,
    required String dueDate,
    String status = 'pending',
  }) async {
    final dto = MilestoneCreateDto(
        projectId: projectId,
        title: title,
        description: description,
        dueDate: dueDate,
        status: status);
    final res = await _dio.post(Endpoints.milestones, data: dto.toJson());
    return MilestoneDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<MilestoneEntity> update({
    required String id,
    String? title,
    String? description,
    String? dueDate,
    String? status,
  }) async {
    final dto = MilestoneUpdateDto(
        title: title,
        description: description,
        dueDate: dueDate,
        status: status);
    final res = await _dio.put(Endpoints.milestone(id), data: dto.toJson());
    return MilestoneDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<MilestoneEntity> complete(String id) async {
    final res = await _dio.post('${Endpoints.milestone(id)}/complete');
    return MilestoneDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete(Endpoints.milestone(id));
  }

  @override
  Future<int> countByProject(String projectId) async {
    final entities = await listByProject(projectId);
    return entities.length;
  }

  @override
  Future<int> countCompletedByProject(String projectId) async {
    final entities = await listByProject(projectId);
    return entities.where((e) => e.status == 'completed').length;
  }
}
