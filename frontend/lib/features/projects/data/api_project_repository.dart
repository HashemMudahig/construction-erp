import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/project_entity.dart';
import '../domain/project_repository_interface.dart';
import 'project_dto.dart';

/// Preserved remote (FastAPI) project repository.
///
/// **Deprecated as runtime:** The active runtime uses [LocalProjectRepository].
/// This adapter remains for future remote access or synchronization.
class ApiProjectRepository implements ProjectRepositoryInterface {
  ApiProjectRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<ProjectEntity>> list({
    String? clientId,
    String? status,
    String? search,
  }) async {
    final res = await _dio.get(Endpoints.projects, queryParameters: {
      if (clientId != null) 'client_id': clientId,
      if (status != null) 'status': status,
      'skip': 0,
      'limit': 50,
    });
    final list = res.data as List;
    return list
        .map((e) => ProjectDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<ProjectEntity?> getById(String id) async {
    final res = await _dio.get(Endpoints.project(id));
    return ProjectDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<ProjectEntity> create({
    required String clientId,
    required String name,
    String? description,
    required int budgetAmountMinor,
    required String budgetCurrency,
    String exchangePolicy = 'per_transaction',
    int? fixedExchangeRateScaled,
    String? startDate,
    String? endDate,
    String status = 'planning',
  }) async {
    // Convert minor units back to string for the remote API
    final budgetStr = budgetCurrency == kCurrencyYer
        ? budgetAmountMinor.toString()
        : (budgetAmountMinor / 100).toStringAsFixed(2);
    final dto = ProjectCreateDto(
      clientId: clientId,
      name: name,
      description: description,
      budget: budgetStr,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
    final res = await _dio.post(Endpoints.projects, data: dto.toJson());
    return ProjectDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<ProjectEntity> update({
    required String id,
    String? clientId,
    String? name,
    String? description,
    int? budgetAmountMinor,
    String? budgetCurrency,
    String? exchangePolicy,
    int? fixedExchangeRateScaled,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    String? budgetStr;
    if (budgetAmountMinor != null && budgetCurrency != null) {
      budgetStr = budgetCurrency == 'YER'
          ? budgetAmountMinor.toString()
          : (budgetAmountMinor / 100).toStringAsFixed(2);
    }
    final dto = ProjectUpdateDto(
      clientId: clientId,
      name: name,
      description: description,
      budget: budgetStr,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
    final res = await _dio.put(Endpoints.project(id), data: dto.toJson());
    return ProjectDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<void> deleteIfEligible(String id) async {
    await _dio.delete(Endpoints.project(id));
  }

  @override
  Future<bool> hasChildRecords(String id) async => false;

  @override
  Future<ProjectFinancialSummary> getFinancialSummary(String id) async {
    final res = await _dio.get('${Endpoints.project(id)}/profitability');
    final data = res.data as Map<String, dynamic>;
    return ProjectFinancialSummary(
      totalPaymentsYer:
          int.tryParse(data['total_payments'] as String? ?? '0') ?? 0,
      totalExpensesYer:
          int.tryParse(data['total_expenses'] as String? ?? '0') ?? 0,
      balance: int.tryParse(data['balance'] as String? ?? '0') ?? 0,
      profitMargin:
          double.tryParse(data['profit_margin'] as String? ?? '0') ?? 0.0,
    );
  }
}

/// Preserved remote provider — not used in local runtime.
final apiProjectRepositoryProvider = Provider<ApiProjectRepository>((ref) {
  return ApiProjectRepository(ref.watch(dioProvider));
});
