import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/project_entity.dart';

/// Maps between Drift [ProjectRow]/[ProjectsCompanion] and domain [ProjectEntity].
class ProjectMapper {
  ProjectMapper._();

  /// Converts a Drift [ProjectRow] to a domain [ProjectEntity].
  static ProjectEntity rowToEntity(ProjectRow row) {
    return ProjectEntity(
      id: row.id,
      clientId: row.clientId,
      name: row.name,
      description: row.description,
      budgetAmountMinor: row.budgetAmountMinor,
      budgetCurrency: row.budgetCurrency,
      exchangePolicy: row.exchangePolicy,
      fixedExchangeRateScaled: row.fixedExchangeRateScaled,
      startDate: row.startDate != null
          ? DateTime.parse('${row.startDate}T00:00:00')
          : null,
      endDate: row.endDate != null
          ? DateTime.parse('${row.endDate}T00:00:00')
          : null,
      status: row.status,
      createdAt: DateTime.parse(row.createdAt),
    );
  }

  /// Creates a [ProjectsCompanion] for inserting a new project.
  static ProjectsCompanion entityToInsertCompanion({
    required String id,
    required String clientId,
    required String name,
    String? description,
    required int budgetAmountMinor,
    required String budgetCurrency,
    String exchangePolicy = 'per_transaction',
    int? fixedExchangeRateScaled,
    String? startDate,
    String? endDate,
    String status = 'planning',
    required String createdAt,
  }) {
    return ProjectsCompanion.insert(
      id: id,
      clientId: clientId,
      name: name,
      description: Value(description),
      budgetAmountMinor: budgetAmountMinor,
      budgetCurrency: budgetCurrency,
      exchangePolicy: Value(exchangePolicy),
      fixedExchangeRateScaled: Value(fixedExchangeRateScaled),
      startDate: Value(startDate),
      endDate: Value(endDate),
      status: Value(status),
      createdAt: createdAt,
    );
  }

  /// Creates a [ProjectsCompanion] for updating an existing project.
  static ProjectsCompanion entityToUpdateCompanion({
    String? clientId,
    String? name,
    String? description,
    int? budgetAmountMinor,
    String? budgetCurrency,
    String? exchangePolicy,
    int? fixedExchangeRateScaled,
    String? startDate,
    String? endDate,
    String? status,
  }) {
    return ProjectsCompanion(
      clientId: clientId != null ? Value(clientId) : const Value.absent(),
      name: name != null ? Value(name) : const Value.absent(),
      description:
          description != null ? Value(description) : const Value.absent(),
      budgetAmountMinor: budgetAmountMinor != null
          ? Value(budgetAmountMinor)
          : const Value.absent(),
      budgetCurrency:
          budgetCurrency != null ? Value(budgetCurrency) : const Value.absent(),
      exchangePolicy:
          exchangePolicy != null ? Value(exchangePolicy) : const Value.absent(),
      fixedExchangeRateScaled: fixedExchangeRateScaled != null
          ? Value(fixedExchangeRateScaled)
          : const Value.absent(),
      startDate: startDate != null ? Value(startDate) : const Value.absent(),
      endDate: endDate != null ? Value(endDate) : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
    );
  }
}
