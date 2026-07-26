/// Project domain entity.
///
/// Multi-currency fields (ADR-005):
/// - [budgetAmountMinor]: budget in minor units (scaled INTEGER).
/// - [budgetCurrency]: "YER" (scale 0) or "SAR" (scale 2).
/// - [exchangePolicy]: "fixed" or "per_transaction".
/// - [fixedExchangeRateScaled]: scale-6 INTEGER, null when not applicable.
class ProjectEntity {
  ProjectEntity({
    required this.id,
    required this.clientId,
    required this.name,
    this.description,
    required this.budgetAmountMinor,
    required this.budgetCurrency,
    this.exchangePolicy = 'per_transaction',
    this.fixedExchangeRateScaled,
    this.startDate,
    this.endDate,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String name;
  final String? description;
  final int budgetAmountMinor;
  final String budgetCurrency;
  final String exchangePolicy;
  final int? fixedExchangeRateScaled;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final DateTime createdAt;

  ProjectEntity copyWith({
    String? clientId,
    String? name,
    String? description,
    int? budgetAmountMinor,
    String? budgetCurrency,
    String? exchangePolicy,
    int? fixedExchangeRateScaled,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) =>
      ProjectEntity(
        id: id,
        clientId: clientId ?? this.clientId,
        name: name ?? this.name,
        description: description ?? this.description,
        budgetAmountMinor: budgetAmountMinor ?? this.budgetAmountMinor,
        budgetCurrency: budgetCurrency ?? this.budgetCurrency,
        exchangePolicy: exchangePolicy ?? this.exchangePolicy,
        fixedExchangeRateScaled:
            fixedExchangeRateScaled ?? this.fixedExchangeRateScaled,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
