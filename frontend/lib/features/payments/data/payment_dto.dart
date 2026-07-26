import 'package:decimal/decimal.dart';

import '../../../core/database/database_constants.dart';
import '../domain/payment_entity.dart';

class PaymentDto {
  PaymentDto({
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
  final String amount;
  final String paymentDate;
  final String method;
  final String? notes;
  final String createdAt;

  factory PaymentDto.fromJson(Map<String, dynamic> json) => PaymentDto(
        id: json['id'] as String,
        projectId: json['project_id'] as String,
        amount: json['amount'] as String,
        paymentDate: json['payment_date'] as String,
        method: json['method'] as String,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] as String,
      );

  PaymentEntity toEntity() {
    final amountDecimal = Decimal.parse(amount);
    // Remote DTO assumes YER (scale 0) — convert to minor units
    final minor = amountDecimal.toBigInt().toInt();
    return PaymentEntity(
      id: id,
      projectId: projectId,
      originalAmountMinor: minor,
      originalCurrency: kCurrencyYer,
      exchangeRateScaled: kIdentityExchangeRate,
      convertedYerAmount: minor,
      rateSource: kRateSourceIdentity,
      paymentDate: DateTime.parse('${paymentDate}T00:00:00'),
      method: method,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

class PaymentCreateDto {
  PaymentCreateDto({
    required this.projectId,
    required this.amount,
    required this.paymentDate,
    required this.method,
    this.notes,
  });
  final String projectId;
  final String amount;
  final String paymentDate;
  final String method;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'amount': amount,
        'payment_date': paymentDate,
        'method': method,
        if (notes != null) 'notes': notes,
      };
}

class PaymentUpdateDto {
  PaymentUpdateDto({this.amount, this.paymentDate, this.method, this.notes});
  final String? amount;
  final String? paymentDate;
  final String? method;
  final String? notes;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (amount != null) m['amount'] = amount;
    if (paymentDate != null) m['payment_date'] = paymentDate;
    if (method != null) m['method'] = method;
    if (notes != null) m['notes'] = notes;
    return m;
  }
}
