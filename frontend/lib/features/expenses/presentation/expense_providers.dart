import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/expense_dto.dart';
import '../data/expense_repository.dart';
import '../domain/expense_entity.dart';

final expensesByProjectProvider =
    FutureProvider.family<List<ExpenseEntity>, String>((ref, projectId) async {
  final repo = ref.read(expenseRepositoryProvider);
  final dtos = await repo.list(projectId: projectId);
  return dtos.map((d) => d.toEntity()).toList();
});

class ExpenseActions {
  ExpenseActions(this._ref);
  final Ref _ref;

  Future<String?> create(ExpenseCreateDto dto) async {
    try {
      await _ref.read(expenseRepositoryProvider).create(dto);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> update(String id, ExpenseUpdateDto dto) async {
    try {
      await _ref.read(expenseRepositoryProvider).update(id, dto);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _ref.read(expenseRepositoryProvider).delete(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final expenseActionsProvider = Provider<ExpenseActions>((ref) => ExpenseActions(ref));