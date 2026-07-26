import 'package:drift/drift.dart';

/// Milestones table — preserves verified Milestone fields.
///
/// Fields match `backend/app/models/milestone.py` and
/// `frontend/lib/features/milestones/domain/milestone_entity.dart`.
///
/// Status "overdue" may be a derived effective status rather than a stored
/// value. This table allows storing it but does not automatically compute it.
@DataClassName('MilestoneRow')
class Milestones extends Table {
  /// UUID v4 primary key.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// FK to projects.id. ON DELETE CASCADE (milestones are progress indicators,
  /// not financial records — safe to cascade).
  TextColumn get projectId => text()
      .withLength(min: 36, max: 36)
      .customConstraint('NOT NULL REFERENCES projects(id) ON DELETE CASCADE')();

  /// Milestone title. Required, max 255 chars.
  TextColumn get title => text().withLength(min: 1, max: 255)();

  /// Optional description.
  TextColumn get description => text().nullable()();

  /// Due date, ISO 8601 date-only (YYYY-MM-DD). Required.
  TextColumn get dueDate => text()();

  /// Milestone status: pending, in_progress, completed, overdue.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Creation timestamp, ISO 8601 UTC string.
  TextColumn get createdAt => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {id},
      ];
}
