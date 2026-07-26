import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/clients_dao.dart';
import '../../../core/uuid/uuid_util.dart';
import '../domain/client_entity.dart';
import '../domain/client_repository_interface.dart';
import 'client_mapper.dart';

/// Local (Drift/SQLite) implementation of [ClientRepositoryInterface].
///
/// This is the active runtime implementation for the Clients feature.
/// It uses [ClientsDao] to access the persistent SQLite database.
///
/// The remote [ApiClientRepository] remains preserved for future use.
class LocalClientRepository implements ClientRepositoryInterface {
  LocalClientRepository(this._dao);

  final ClientsDao _dao;

  @override
  Future<List<ClientEntity>> list({
    String? search,
    bool includeArchived = false,
  }) async {
    final hasSearch = search != null && search.trim().isNotEmpty;
    final List<ClientRow> rows;
    if (hasSearch) {
      final query = search.trim();
      rows = includeArchived
          ? await _dao.searchAllClients(query)
          : await _dao.searchActiveClients(query);
    } else {
      rows = includeArchived
          ? await _dao.getAllClients()
          : await _dao.getActiveClients();
    }
    return rows.map(ClientMapper.rowToEntity).toList();
  }

  @override
  Future<ClientEntity?> getById(String id) async {
    UuidUtil.validate(id);
    final row = await _dao.getClientById(id);
    if (row == null) return null;
    return ClientMapper.rowToEntity(row);
  }

  @override
  Future<ClientEntity> create({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Client name is required');
    }

    final id = UuidUtil.generate();
    final now = _utcNowIso();

    await _dao.insertClient(ClientMapper.entityToInsertCompanion(
      id: id,
      name: trimmedName,
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      email: email?.trim().isEmpty == true ? null : email?.trim(),
      address: address?.trim().isEmpty == true ? null : address?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      archived: false,
      createdAt: now,
      updatedAt: now,
    ));

    final row = await _dao.getClientById(id);
    return ClientMapper.rowToEntity(row!);
  }

  @override
  Future<ClientEntity> update({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? archived,
  }) async {
    UuidUtil.validate(id);

    final existing = await _dao.getClientById(id);
    if (existing == null) {
      throw ArgumentError('Client not found: $id');
    }

    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Client name cannot be empty');
    }

    final now = _utcNowIso();
    await _dao.updateClient(
      id,
      ClientMapper.entityToUpdateCompanion(
        name: name?.trim(),
        phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        address: address?.trim().isEmpty == true ? null : address?.trim(),
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        archived: archived,
        updatedAt: now,
      ),
    );

    final row = await _dao.getClientById(id);
    return ClientMapper.rowToEntity(row!);
  }

  @override
  Future<void> archive(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getClientById(id);
    if (existing == null) {
      throw ArgumentError('Client not found: $id');
    }
    await _dao.updateClient(
      id,
      ClientsCompanion(
        archived: const Value(true),
        updatedAt: Value(_utcNowIso()),
      ),
    );
  }

  @override
  Future<void> restore(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getClientById(id);
    if (existing == null) {
      throw ArgumentError('Client not found: $id');
    }
    await _dao.updateClient(
      id,
      ClientsCompanion(
        archived: const Value(false),
        updatedAt: Value(_utcNowIso()),
      ),
    );
  }

  @override
  Future<void> deleteIfEligible(String id) async {
    UuidUtil.validate(id);
    final existing = await _dao.getClientById(id);
    if (existing == null) {
      throw ArgumentError('Client not found: $id');
    }
    final projectCount = await _dao.countProjects(id);
    if (projectCount > 0) {
      throw StateError(
        'Cannot delete client: $projectCount project(s) are linked. '
        'Archive the client instead.',
      );
    }
    await _dao.deleteClient(id);
  }

  @override
  Future<bool> hasProjects(String id) async {
    UuidUtil.validate(id);
    final count = await _dao.countProjects(id);
    return count > 0;
  }

  /// Returns the current UTC time as an ISO 8601 string.
  ///
  /// Used for createdAt and updatedAt timestamps.
  /// Tests inject a fixed time via the repository's test constructor
  /// or by overriding this method.
  String _utcNowIso() => DateTime.now().toUtc().toIso8601String();
}

/// Active runtime provider for the local client repository.
///
/// Resolves to [LocalClientRepository] using the [databaseProvider]'s
/// [AppDatabase] instance.
final localClientRepositoryProvider =
    Provider<ClientRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalClientRepository(db.clientsDao);
});
