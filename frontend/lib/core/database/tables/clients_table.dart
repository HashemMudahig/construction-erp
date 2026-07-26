import 'package:drift/drift.dart';

/// Clients table — mirrors the verified Client contract from Phase 01.
///
/// Fields match `backend/app/models/client.py` and
/// `frontend/lib/features/clients/domain/client_entity.dart`.
///
/// UUIDs are stored as TEXT(36). Timestamps are stored as TEXT ISO 8601 UTC.
@DataClassName('ClientRow')
class Clients extends Table {
  /// UUID v4 primary key, stored as TEXT(36).
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// Client display name. Required, max 200 chars.
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Optional phone number.
  TextColumn get phone => text().nullable()();

  /// Optional email address.
  TextColumn get email => text().nullable()();

  /// Optional postal address.
  TextColumn get address => text().nullable()();

  /// Optional free-text notes.
  TextColumn get notes => text().nullable()();

  /// Soft-delete / archive flag. Defaults to false (0).
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// Creation timestamp, ISO 8601 UTC string.
  TextColumn get createdAt => text()();

  /// Last update timestamp, ISO 8601 UTC string.
  TextColumn get updatedAt => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {id},
      ];
}
