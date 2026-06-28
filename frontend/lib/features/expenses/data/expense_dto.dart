import 'package:decimal/decimal.dart';

import '../domain/expense_entity.dart';

class ExpenseDto {
  ExpenseDto({
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
  final String amount;
  final String expenseDate;
  final String? notes;
  final String createdAt;

  factory ExpenseDto.fromJson(Map<String, dynamic> json) => ExpenseDto(
        id: json['id'] as String,
        projectId: json['project_id'] as String,
        category: json['category'] as String,
        amount: json['amount'] as String,
        expenseDate: json['expense_date'] as String,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] as String,
      );

  ExpenseEntity toEntity() => ExpenseEntity(
        id: id,
        projectId: projectId,
        category: category,
        amount: Decimal.parse(amount),
        expenseDate: DateTime.tryParse('${expenseDate}T00:00:00') ?? DateTime.now(),
        notes: notes,
        createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      );
}

class ExpenseCreateDto {
  ExpenseCreateDto({
    required this.projectId,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.notes,
  });
  final String projectId;
  final String category;
  final String amount;
  final String expenseDate;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'category': category,
        'amount': amount,
        'expense_date': expenseDate,
        if (notes != null) 'notes': notes,
      };
}

class ExpenseUpdateDto {
  ExpenseUpdateDto({this.category, this.amount, this.expenseDate, this.notes});
  final String? category;
  final String? amount;
  final String? expenseDate;
  final String? notes;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (category != null) m['category'] = category;
    if (amount != null) m['amount'] = amount;
    if (expenseDate != null) m['expense_date'] = expenseDate;
    if (notes != null) m['notes'] = notes;
    return m;
  }
}