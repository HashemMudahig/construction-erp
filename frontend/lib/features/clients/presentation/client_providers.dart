import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_client_repository.dart';
import '../domain/client_entity.dart';
import '../domain/client_repository_interface.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../reports/presentation/report_providers.dart';

/// Active runtime client repository provider.
///
/// Uses the sole production implementation: [LocalClientRepository].
final clientRepositoryProvider = Provider<ClientRepositoryInterface>((ref) {
  return ref.watch(localClientRepositoryProvider);
});

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
    return repo.list(search: _search);
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

  Future<bool> create({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      await ref.read(clientRepositoryProvider).create(
            name: name,
            phone: phone,
            email: email,
            address: address,
            notes: notes,
          );
      await refresh();
      invalidateDashboard(ref);
      invalidateReports(ref);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> updateClient(
    String id, {
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? archived,
  }) async {
    try {
      await ref.read(clientRepositoryProvider).update(
            id: id,
            name: name,
            phone: phone,
            email: email,
            address: address,
            notes: notes,
            archived: archived,
          );
      await refresh();
      invalidateDashboard(ref);
      invalidateReports(ref);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<String?> delete(String id) async {
    try {
      await ref.read(clientRepositoryProvider).deleteIfEligible(id);
      await refresh();
      invalidateDashboard(ref);
      invalidateReports(ref);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  String? _lastError;
  String? lastError() => _lastError;
}

/// Single client detail provider (family).
final clientDetailProvider =
    FutureProvider.family<ClientEntity, String>((ref, id) async {
  final repo = ref.read(clientRepositoryProvider);
  final client = await repo.getById(id);
  if (client == null) {
    throw StateError('Client not found: $id');
  }
  return client;
});
