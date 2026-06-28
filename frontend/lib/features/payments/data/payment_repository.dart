import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/dio_provider.dart';
import 'payment_dto.dart';

class PaymentRepository {
  PaymentRepository(this._dio);
  final Dio _dio;

  Future<List<PaymentDto>> list({String? projectId, int skip = 0, int limit = 50}) async {
    final res = await _dio.get(Endpoints.payments, queryParameters: {
      if (projectId != null) 'project_id': projectId,
      'skip': skip,
      'limit': limit,
    });
    final list = res.data as List;
    return list.map((e) => PaymentDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaymentDto> create(PaymentCreateDto dto) async {
    final res = await _dio.post(Endpoints.payments, data: dto.toJson());
    return PaymentDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaymentDto> update(String id, PaymentUpdateDto dto) async {
    final res = await _dio.put(Endpoints.payment(id), data: dto.toJson());
    return PaymentDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(Endpoints.payment(id));
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});