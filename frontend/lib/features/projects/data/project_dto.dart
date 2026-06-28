import 'package:decimal/decimal.dart';

import '../domain/project_entity.dart';

class ProjectDto {
  ProjectDto({
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
  final String budget;
  final String? startDate;
  final String? endDate;
  final String status;
  final String createdAt;

  factory ProjectDto.fromJson(Map<String, dynamic> json) => ProjectDto(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        budget: json['budget'] as String,
        startDate: json['start_date'] as String?,
        endDate: json['end_date'] as String?,
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
      );

  ProjectEntity toEntity() => ProjectEntity(
        id: id,
        clientId: clientId,
        name: name,
        description: description,
        budget: Decimal.parse(budget),
        startDate: startDate != null ? DateTime.tryParse('${startDate}T00:00:00') : null,
        endDate: endDate != null ? DateTime.tryParse('${endDate}T00:00:00') : null,
        status: status,
        createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      );
}

class ProjectCreateDto {
  ProjectCreateDto({
    required this.clientId,
    required this.name,
    this.description,
    required this.budget,
    this.startDate,
    this.endDate,
    this.status = 'planning',
  });
  final String clientId;
  final String name;
  final String? description;
  final String budget;
  final String? startDate;
  final String? endDate;
  final String status;

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'name': name,
        if (description != null) 'description': description,
        'budget': budget,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        'status': status,
      };
}

class ProjectUpdateDto {
  ProjectUpdateDto({
    this.clientId,
    this.name,
    this.description,
    this.budget,
    this.startDate,
    this.endDate,
    this.status,
  });
  final String? clientId;
  final String? name;
  final String? description;
  final String? budget;
  final String? startDate;
  final String? endDate;
  final String? status;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (clientId != null) m['client_id'] = clientId;
    if (name != null) m['name'] = name;
    if (description != null) m['description'] = description;
    if (budget != null) m['budget'] = budget;
    if (startDate != null) m['start_date'] = startDate;
    if (endDate != null) m['end_date'] = endDate;
    if (status != null) m['status'] = status;
    return m;
  }
}