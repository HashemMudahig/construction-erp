import 'package:decimal/decimal.dart';

class PaymentEntity {
  PaymentEntity({
    required this.id,
    required this.projectId,
    required this.amount,
    required this.paymentDate,
    required this.method,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final Decimal amount;
  final DateTime paymentDate;
  final String method;
  final String? notes;
  final DateTime createdAt;
}