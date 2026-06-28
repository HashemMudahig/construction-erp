import 'package:decimal/decimal.dart';

/// Project domain entity.
class ProjectEntity {
  ProjectEntity({
    required this.id,
    required this.clientId,
    required this.name,
    this.description,
    required this.budget,
    this.startDate,
    this.endDate,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String name;
  final String? description;
  final Decimal budget;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final DateTime createdAt;

  ProjectEntity copyWith({
    String? clientId,
    String? name,
    String? description,
    Decimal? budget,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) =>
      ProjectEntity(
        id: id,
        clientId: clientId ?? this.clientId,
        name: name ?? this.name,
        description: description ?? this.description,
        budget: budget ?? this.budget,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}