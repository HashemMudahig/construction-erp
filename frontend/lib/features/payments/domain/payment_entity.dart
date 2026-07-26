/// Payment domain entity with multi-currency snapshot fields.
///
/// Financial fields use scaled INTEGER (ADR-005):
/// - [originalAmountMinor]: in original currency minor units.
/// - [convertedYerAmount]: in YER minor units (scale 0).
/// - [exchangeRateScaled]: scale-6 INTEGER.
class PaymentEntity {
  PaymentEntity({
    required this.id,
    required this.projectId,
    this.paymentGroupId,
    required this.originalAmountMinor,
    required this.originalCurrency,
    required this.exchangeRateScaled,
    required this.convertedYerAmount,
    this.rateSource = 'identity',
    this.rateDate,
    required this.paymentDate,
    required this.method,
    this.notes,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String projectId;
  final String? paymentGroupId;
  final int originalAmountMinor;
  final String originalCurrency;
  final int exchangeRateScaled;
  final int convertedYerAmount;
  final String rateSource;
  final String? rateDate;
  final DateTime paymentDate;
  final String method;
  final String? notes;
  final DateTime createdAt;
  final bool isDeleted;
  final DateTime? deletedAt;
}
