import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/payment_dto.dart';
import '../data/payment_repository.dart';
import '../domain/payment_entity.dart';

final paymentsByProjectProvider =
    FutureProvider.family<List<PaymentEntity>, String>((ref, projectId) async {
  final repo = ref.read(paymentRepositoryProvider);
  final dtos = await repo.list(projectId: projectId);
  return dtos.map((d) => d.toEntity()).toList();
});

class PaymentActions {
  PaymentActions(this._ref);
  final Ref _ref;

  Future<String?> create(PaymentCreateDto dto) async {
    try {
      await _ref.read(paymentRepositoryProvider).create(dto);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> update(String id, PaymentUpdateDto dto) async {
    try {
      await _ref.read(paymentRepositoryProvider).update(id, dto);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _ref.read(paymentRepositoryProvider).delete(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final paymentActionsProvider = Provider<PaymentActions>((ref) => PaymentActions(ref));