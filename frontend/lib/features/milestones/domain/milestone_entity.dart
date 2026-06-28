import 'package:decimal/decimal.dart';

class MilestoneEntity {
  MilestoneEntity({
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
  final DateTime dueDate;
  final String status;
  final DateTime createdAt;
}