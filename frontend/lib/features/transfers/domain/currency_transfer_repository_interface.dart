import 'currency_transfer_entity.dart';

/// Contract for currency transfer data access operations.
abstract class CurrencyTransferRepositoryInterface {
  /// Lists active (non-deleted) transfers for the given [projectId].
  Future<List<CurrencyTransferEntity>> listByProject(String projectId);

  /// Returns the active transfer with the given [id], or null.
  Future<CurrencyTransferEntity?> getById(String id);

  /// Creates a currency transfer. Returns the created entity.
  ///
  /// The transfer records a movement from [sourceCurrency] to
  /// [targetCurrency] using [exchangeRateScaled] (scale-6 INTEGER, YER per
  /// 1 SAR). The repository computes [targetAmountMinor] from the source
  /// amount and the rate when not supplied, applying exact integer
  /// round-half-up arithmetic.
  Future<CurrencyTransferEntity> create({
    required String projectId,
    required String sourceCurrency,
    required String targetCurrency,
    required int sourceAmountMinor,
    int? targetAmountMinor,
    required int exchangeRateScaled,
    required String date,
    String? notes,
  });

  /// Soft-deletes a transfer.
  Future<void> softDelete(String id);

  /// Restores a soft-deleted transfer.
  Future<void> restore(String id);

  /// Returns the count of all transfers (including soft-deleted) for
  /// [projectId].
  Future<int> countAllByProject(String projectId);
}