import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/dio_provider.dart';
import 'expense_dto.dart';

class ExpenseRepository {
  ExpenseRepository(this._dio);
  final Dio _dio;

  Future<List<ExpenseDto>> list({String? projectId, String? category, int skip = 0, int limit = 50}) async {
    final res = await _dio.get(Endpoints.expenses, queryParameters: {
      if (projectId != null) 'project_id': projectId,
      if (category != null) 'category': category,
      'skip': skip,
      'limit': limit,
    });
    final list = res.data as List;
    return list.map((e) => ExpenseDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ExpenseDto> create(ExpenseCreateDto dto) async {
    final res = await _dio.post(Endpoints.expenses, data: dto.toJson());
    return ExpenseDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ExpenseDto> update(String id, ExpenseUpdateDto dto) async {
    final res = await _dio.put(Endpoints.expense(id), data: dto.toJson());
    return ExpenseDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(Endpoints.expense(id));
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(dioProvider));
});