import 'package:construction_erp/features/milestones/domain/milestone_entity.dart';

class MilestoneDto {
  MilestoneDto({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String dueDate;
  final String status;
  final String createdAt;

  factory MilestoneDto.fromJson(Map<String, dynamic> json) => MilestoneDto(
        id: json['id'] as String,
        projectId: json['project_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        dueDate: json['due_date'] as String,
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
      );

  MilestoneEntity toEntity() => MilestoneEntity(
        id: id,
        projectId: projectId,
        title: title,
        description: description,
        dueDate: DateTime.tryParse('${dueDate}T00:00:00') ?? DateTime.now(),
        status: status,
        createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      );
}

class MilestoneCreateDto {
  MilestoneCreateDto({
    required this.projectId,
    required this.title,
    this.description,
    required this.dueDate,
    this.status = 'pending',
  });
  final String projectId;
  final String title;
  final String? description;
  final String dueDate;
  final String status;

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'title': title,
        if (description != null) 'description': description,
        'due_date': dueDate,
        'status': status,
      };
}

class MilestoneUpdateDto {
  MilestoneUpdateDto({this.title, this.description, this.dueDate, this.status});
  final String? title;
  final String? description;
  final String? dueDate;
  final String? status;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (title != null) m['title'] = title;
    if (description != null) m['description'] = description;
    if (dueDate != null) m['due_date'] = dueDate;
    if (status != null) m['status'] = status;
    return m;
  }
}
