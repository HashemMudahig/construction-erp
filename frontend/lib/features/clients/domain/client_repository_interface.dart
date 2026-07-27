import 'client_entity.dart';

/// Contract for client data access operations.
///
/// Implemented in production by the local Drift/SQLite repository.
///
/// The interface returns domain entities, not Drift rows or DTOs.
/// Screens and providers depend on this abstraction, not on a specific
/// implementation.
abstract class ClientRepositoryInterface {
  /// Lists clients. By default returns active (non-archived) clients only.
  ///
  /// When [includeArchived] is true, returns all clients including archived.
  /// When [search] is non-empty, filters by name, phone, or email
  /// (case-insensitive).
  Future<List<ClientEntity>> list({
    String? search,
    bool includeArchived = false,
  });

  /// Returns the client with the given [id], or null if not found.
  Future<ClientEntity?> getById(String id);

  /// Creates a new client. Returns the created entity with generated ID.
  ///
  /// Throws [ArgumentError] if [name] is empty.
  Future<ClientEntity> create({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  });

  /// Updates an existing client. Returns the updated entity.
  ///
  /// Only non-null fields are updated.
  /// Throws [ArgumentError] if the client does not exist.
  Future<ClientEntity> update({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? archived,
  });

  /// Archives a client by setting archived = true.
  ///
  /// Does not delete the client or modify related projects.
  /// Throws [ArgumentError] if the client does not exist.
  Future<void> archive(String id);

  /// Restores an archived client by setting archived = false.
  ///
  /// Throws [ArgumentError] if the client does not exist.
  Future<void> restore(String id);

  /// Hard-deletes a client if it has no linked projects.
  ///
  /// Throws [StateError] if the client has one or more projects.
  /// Throws [ArgumentError] if the client does not exist.
  Future<void> deleteIfEligible(String id);

  /// Returns true if the client has one or more linked projects.
  Future<bool> hasProjects(String id);
}
