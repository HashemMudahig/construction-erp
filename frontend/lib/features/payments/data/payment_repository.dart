import 'package:dio/dio.dart';

import '../../../core/constants/endpoints.dart';
import '../domain/payment_entity.dart';
import '../domain/payment_repository_interface.dart';
import 'payment_dto.dart';

/// Preserved remote (FastAPI) payment repository — legacy class.
///
/// **Deprecated as runtime:** Use [LocalPaymentRepository] via
/// [localPaymentRepositoryProvider]. See [ApiPaymentRepository] for the
/// fully interface-conforming remote implementation.
class PaymentRepository implements PaymentRepositoryInterface {
  PaymentRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<PaymentEntity>> listByProject(String projectId) async {
    final res = await _dio.get(Endpoints.payments, queryParameters: {
      'project_id': projectId,
      'skip': 0,
      'limit': 50,
    });
    final list = res.data as List;
    return list
        .map((e) => PaymentDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<PaymentEntity?> getById(String id) async {
    final res = await _dio.get(Endpoints.payment(id));
    return PaymentDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<PaymentEntity> create({
    required String projectId,
    String? paymentGroupId,
    required int originalAmountMinor,
    required String originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String rateSource = 'identity',
    String? rateDate,
    required String paymentDate,
    required String method,
    String? notes,
  }) async {
    final dto = PaymentCreateDto(
        projectId: projectId,
        amount: originalAmountMinor.toString(),
        paymentDate: paymentDate,
        method: method,
        notes: notes);
    final res = await _dio.post(Endpoints.payments, data: dto.toJson());
    return PaymentDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<PaymentEntity> update({
    required String id,
    int? originalAmountMinor,
    String? originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String? rateSource,
    String? rateDate,
    String? paymentDate,
    String? method,
    String? notes,
  }) async {
    final dto = PaymentUpdateDto(
        amount: originalAmountMinor?.toString(),
        paymentDate: paymentDate,
        method: method,
        notes: notes);
    final res = await _dio.put(Endpoints.payment(id), data: dto.toJson());
    return PaymentDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<void> softDelete(String id) async {
    await _dio.delete(Endpoints.payment(id));
  }

  @override
  Future<void> restore(String id) async {}

  @override
  Future<void> softDeleteGroup(String groupId) async {}

  @override
  Future<void> restoreGroup(String groupId) async {}

  @override
  Future<int> totalActivePaymentsYer(String projectId) async => 0;

  @override
  Future<int> countAllByProject(String projectId) async => 0;
}
