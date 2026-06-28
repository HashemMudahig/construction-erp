import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/client_dto.dart';
import '../data/client_repository.dart';
import '../domain/client_entity.dart';

/// Clients list async provider. Refreshable via ref.invalidate.
final clientsListProvider =
    AsyncNotifierProvider<ClientsListNotifier, List<ClientEntity>>(
  ClientsListNotifier.new,
);

class ClientsListNotifier extends AsyncNotifier<List<ClientEntity>> {
  String _search = '';
  String get search => _search;

  @override
  Future<List<ClientEntity>> build() => _fetch();

  Future<List<ClientEntity>> _fetch() async {
    final repo = ref.read(clientRepositoryProvider);
    final dtos = await repo.list(search: _search);
    return dtos.map((d) => d.toEntity()).toList();
  }

  Future<void> setSearch(String s) async {
    _search = s;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> create(ClientCreateDto dto) async {
    try {
      await ref.read(clientRepositoryProvider).create(dto);
      await refresh();
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      return false;
    }
  }

  Future<bool> updateClient(String id, ClientUpdateDto dto) async {
    try {
      await ref.read(clientRepositoryProvider).update(id, dto);
      await refresh();
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      return false;
    }
  }

  Future<String?> delete(String id) async {
    try {
      await ref.read(clientRepositoryProvider).delete(id);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  String? _lastError;
  String? lastError() => _lastError;
}

/// Single client detail provider (family).
final clientDetailProvider =
    FutureProvider.family<ClientEntity, String>((ref, id) async {
  final repo = ref.read(clientRepositoryProvider);
  final dto = await repo.get(id);
  return dto.toEntity();
});