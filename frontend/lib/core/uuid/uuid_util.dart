import 'package:uuid/uuid.dart';

/// Reusable UUID utility for local identifier generation and validation.
///
/// Enforcement layers for UUID integrity:
/// 1. **Application/Repository validation** — [validateUuid] rejects
///    malformed IDs before database insertion.
/// 2. **Drift length constraint** — `withLength(min: 36, max: 36)` on
///    TEXT columns enforces minimum length at the Dart layer.
/// 3. **Primary-key uniqueness** — SQLite PRIMARY KEY rejects duplicates.
class UuidUtil {
  UuidUtil._();

  static const _uuid = Uuid();

  /// Generates a new UUID v4 string.
  static String generate() => _uuid.v4();

  /// Validates that [id] is a well-formed UUID string.
  ///
  /// Accepts both uppercase and lowercase hex digits.
  /// Returns `true` if the format matches the standard UUID pattern:
  /// `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (36 characters).
  static bool isValid(String id) {
    if (id.length != 36) return false;
    final regex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return regex.hasMatch(id);
  }

  /// Validates that [id] is a well-formed UUID string.
  ///
  /// Throws [ArgumentError] if the format is invalid.
  static void validate(String id) {
    if (!isValid(id)) {
      throw ArgumentError('Invalid UUID format: $id');
    }
  }
}
