import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/client_entity.dart';

/// Maps between Drift [ClientRow]/[ClientsCompanion] and domain [ClientEntity].
///
/// This mapper ensures that Drift-generated types never leak into the
/// presentation or domain layers.
class ClientMapper {
  ClientMapper._();

  /// Converts a Drift [ClientRow] to a domain [ClientEntity].
  ///
  /// Throws [FormatException] if stored timestamps are invalid, rather
  /// than silently falling back to DateTime.now().
  static ClientEntity rowToEntity(ClientRow row) {
    final createdAt = DateTime.parse(row.createdAt);
    final updatedAt = DateTime.parse(row.updatedAt);
    return ClientEntity(
      id: row.id,
      name: row.name,
      phone: row.phone,
      email: row.email,
      address: row.address,
      notes: row.notes,
      archived: row.archived,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a [ClientsCompanion] for inserting a new client.
  static ClientsCompanion entityToInsertCompanion({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool archived = false,
    required String createdAt,
    required String updatedAt,
  }) {
    return ClientsCompanion.insert(
      id: id,
      name: name,
      phone: Value(phone),
      email: Value(email),
      address: Value(address),
      notes: Value(notes),
      archived: Value(archived),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a [ClientsCompanion] for updating an existing client.
  ///
  /// Only non-null fields are included in the update.
  static ClientsCompanion entityToUpdateCompanion({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? archived,
    required String updatedAt,
  }) {
    return ClientsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      phone: phone != null ? Value(phone) : const Value.absent(),
      email: email != null ? Value(email) : const Value.absent(),
      address: address != null ? Value(address) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      archived: archived != null ? Value(archived) : const Value.absent(),
      updatedAt: Value(updatedAt),
    );
  }
}
