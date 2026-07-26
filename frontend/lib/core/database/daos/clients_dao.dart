import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/clients_table.dart';

part 'clients_dao.g.dart';

/// Data Access Object for the [Clients] table.
///
/// Provides CRUD and query operations for the Clients feature.
/// Used by [LocalClientRepository] — not accessed directly by screens.
@DriftAccessor(tables: [Clients])
class ClientsDao extends DatabaseAccessor<AppDatabase> with _$ClientsDaoMixin {
  ClientsDao(super.db);

  /// Inserts a client row. Returns the inserted row's ID.
  Future<int> insertClient(ClientsCompanion client) =>
      into(clients).insert(client);

  /// Returns the client with the given [id], or null.
  Future<ClientRow?> getClientById(String id) =>
      (select(clients)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Returns all active (non-archived) clients, ordered by name.
  Future<List<ClientRow>> getActiveClients() => (select(clients)
        ..where((t) => t.archived.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.name)]))
      .get();

  /// Returns all clients including archived, ordered by name.
  Future<List<ClientRow>> getAllClients() =>
      (select(clients)..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .get();

  /// Searches active clients by name, phone, or email (case-insensitive).
  ///
  /// Uses SQL LIKE with wildcards. SQLite LIKE is case-insensitive for
  /// ASCII characters by default.
  Future<List<ClientRow>> searchActiveClients(String query) {
    final pattern = '%$query%';
    return (select(clients)
          ..where((t) =>
              t.archived.equals(false) &
              (t.name.like(pattern) |
                  t.phone.like(pattern) |
                  t.email.like(pattern)))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  /// Searches all clients (including archived) by name, phone, or email.
  Future<List<ClientRow>> searchAllClients(String query) {
    final pattern = '%$query%';
    return (select(clients)
          ..where((t) =>
              t.name.like(pattern) |
              t.phone.like(pattern) |
              t.email.like(pattern))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  /// Updates a client. Returns true if a row was updated.
  Future<bool> updateClient(String id, ClientsCompanion companion) =>
      (update(clients)..where((t) => t.id.equals(id)))
          .write(companion)
          .then((rows) => rows > 0);

  /// Deletes a client. Returns the number of deleted rows.
  Future<int> deleteClient(String id) =>
      (delete(clients)..where((t) => t.id.equals(id))).go();

  /// Counts the number of projects linked to [clientId].
  ///
  /// Used by [LocalClientRepository] to check delete eligibility.
  /// This is a safe cross-table count that does not migrate the Projects
  /// feature.
  Future<int> countProjects(String clientId) async {
    final countQuery = customSelect(
      'SELECT COUNT(*) AS cnt FROM projects WHERE client_id = ?',
      variables: [Variable.withString(clientId)],
      readsFrom: {attachedDatabase.projects},
    );
    final result = await countQuery.getSingle();
    return result.read<int>('cnt');
  }
}
