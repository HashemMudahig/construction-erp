import 'package:dio/dio.dart';

import '../../../core/constants/endpoints.dart';
import '../domain/expense_entity.dart';
import '../domain/expense_repository_interface.dart';
import 'expense_dto.dart';

/// Preserved remote (FastAPI) expense repository — legacy class.
///
/// **Deprecated as runtime:** Use [LocalExpenseRepository] via
/// [localExpenseRepositoryProvider]. See [ApiExpenseRepository] for the
/// fully interface-conforming remote implementation.
class ExpenseRepository implements ExpenseRepositoryInterface {
  ExpenseRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<ExpenseEntity>> listByProject(String projectId) async {
    final res = await _dio.get(Endpoints.expenses, queryParameters: {
      'project_id': projectId,
      'skip': 0,
      'limit': 50,
    });
    final list = res.data as List;
    return list
        .map((e) => ExpenseDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<ExpenseEntity?> getById(String id) async {
    final res = await _dio.get(Endpoints.expense(id));
    return ExpenseDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<ExpenseEntity> create({
    required String projectId,
    String? expenseGroupId,
    required String category,
    required int originalAmountMinor,
    required String originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String rateSource = 'identity',
    String? rateDate,
    required String expenseDate,
    String? notes,
  }) async {
    final dto = ExpenseCreateDto(
        projectId: projectId,
        category: category,
        amount: originalAmountMinor.toString(),
        expenseDate: expenseDate,
        notes: notes);
    final res = await _dio.post(Endpoints.expenses, data: dto.toJson());
    return ExpenseDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<ExpenseEntity> update({
    required String id,
    String? category,
    int? originalAmountMinor,
    String? originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String? rateSource,
    String? rateDate,
    String? expenseDate,
    String? notes,
  }) async {
    final dto = ExpenseUpdateDto(
        category: category,
        amount: originalAmountMinor?.toString(),
        expenseDate: expenseDate,
        notes: notes);
    final res = await _dio.put(Endpoints.expense(id), data: dto.toJson());
    return ExpenseDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<void> softDelete(String id) async {
    await _dio.delete(Endpoints.expense(id));
  }

  @override
  Future<void> restore(String id) async {}

  @override
  Future<void> softDeleteGroup(String groupId) async {}

  @override
  Future<void> restoreGroup(String groupId) async {}

  @override
  Future<int> totalActiveExpensesYer(String projectId) async => 0;

  @override
  Future<int> countAllByProject(String projectId) async => 0;
}
