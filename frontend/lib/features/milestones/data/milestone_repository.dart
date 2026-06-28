import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/dio_provider.dart';
import 'milestone_dto.dart';

class MilestoneRepository {
  MilestoneRepository(this._dio);
  final Dio _dio;

  Future<List<MilestoneDto>> list({String? projectId, String? status, int skip = 0, int limit = 50}) async {
    final res = await _dio.get(Endpoints.milestones, queryParameters: {
      if (projectId != null) 'project_id': projectId,
      if (status != null) 'status': status,
      'skip': skip,
      'limit': limit,
    });
    final list = res.data as List;
    return list.map((e) => MilestoneDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MilestoneDto> create(MilestoneCreateDto dto) async {
    final res = await _dio.post(Endpoints.milestones, data: dto.toJson());
    return MilestoneDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MilestoneDto> update(String id, MilestoneUpdateDto dto) async {
    final res = await _dio.put(Endpoints.milestone(id), data: dto.toJson());
    return MilestoneDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MilestoneDto> complete(String id) async {
    final res = await _dio.post('${Endpoints.milestone(id)}/complete');
    return MilestoneDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(Endpoints.milestone(id));
  }
}

final milestoneRepositoryProvider = Provider<MilestoneRepository>((ref) {
  return MilestoneRepository(ref.watch(dioProvider));
});