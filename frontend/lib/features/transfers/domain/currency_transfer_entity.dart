/// Currency transfer domain entity with immutable exchange-rate snapshot
/// and soft-delete support.
///
/// Financial fields use scaled INTEGER (ADR-005):
/// - [sourceAmountMinor]: in source currency minor units.
/// - [targetAmountMinor]: in target currency minor units.
/// - [exchangeRateScaled]: scale-6 INTEGER (YER per 1 SAR canonical rate).
class CurrencyTransferEntity {
  CurrencyTransferEntity({
    required this.id,
    required this.projectId,
    required this.sourceCurrency,
    required this.targetCurrency,
    required this.sourceAmountMinor,
    required this.targetAmountMinor,
    required this.exchangeRateScaled,
    required this.date,
    this.notes,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String projectId;
  final String sourceCurrency;
  final String targetCurrency;
  final int sourceAmountMinor;
  final int targetAmountMinor;
  final int exchangeRateScaled;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final bool isDeleted;
  final DateTime? deletedAt;
}