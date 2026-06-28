import 'package:decimal/decimal.dart';

class ExpenseEntity {
  ExpenseEntity({
    required this.id,
    required this.projectId,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String category;
  final Decimal amount;
  final DateTime expenseDate;
  final String? notes;
  final DateTime createdAt;
}