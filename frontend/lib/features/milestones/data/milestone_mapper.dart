import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/milestone_entity.dart';

/// Maps between Drift [MilestoneRow]/[MilestonesCompanion] and domain [MilestoneEntity].
class MilestoneMapper {
  MilestoneMapper._();

  /// Converts a Drift [MilestoneRow] to a domain [MilestoneEntity].
  ///
  /// Throws [FormatException] if stored dates are invalid.
  static MilestoneEntity rowToEntity(MilestoneRow row) {
    final dueDate = DateTime.parse('${row.dueDate}T00:00:00');
    final createdAt = DateTime.parse(row.createdAt);
    return MilestoneEntity(
      id: row.id,
      projectId: row.projectId,
      title: row.title,
      description: row.description,
      dueDate: dueDate,
      status: row.status,
      createdAt: createdAt,
    );
  }

  /// Creates a [MilestonesCompanion] for inserting a new milestone.
  static MilestonesCompanion entityToInsertCompanion({
    required String id,
    required String projectId,
    required String title,
    String? description,
    required String dueDate,
    String status = 'pending',
    required String createdAt,
  }) {
    return MilestonesCompanion.insert(
      id: id,
      projectId: projectId,
      title: title,
      description: Value(description),
      dueDate: dueDate,
      status: Value(status),
      createdAt: createdAt,
    );
  }

  /// Creates a [MilestonesCompanion] for updating an existing milestone.
  static MilestonesCompanion entityToUpdateCompanion({
    String? title,
    String? description,
    String? dueDate,
    String? status,
  }) {
    return MilestonesCompanion(
      title: title != null ? Value(title) : const Value.absent(),
      description:
          description != null ? Value(description) : const Value.absent(),
      dueDate: dueDate != null ? Value(dueDate) : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
    );
  }
}
