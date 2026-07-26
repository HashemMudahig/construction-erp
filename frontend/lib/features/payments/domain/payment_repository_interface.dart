import 'payment_entity.dart';

/// Contract for payment data access operations.
abstract class PaymentRepositoryInterface {
  /// Lists active (non-deleted) payments for the given [projectId].
  Future<List<PaymentEntity>> listByProject(String projectId);

  /// Returns the active payment with the given [id], or null.
  Future<PaymentEntity?> getById(String id);

  /// Creates a single payment. Returns the created entity.
  Future<PaymentEntity> create({
    required String projectId,
    String? paymentGroupId,
    required int originalAmountMinor,
    required String originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String rateSource = 'identity',
    String? rateDate,
    required String paymentDate,
    required String method,
    String? notes,
  });

  /// Updates a payment. Only non-null fields are updated.
  Future<PaymentEntity> update({
    required String id,
    int? originalAmountMinor,
    String? originalCurrency,
    int? exchangeRateScaled,
    int? convertedYerAmount,
    String? rateSource,
    String? rateDate,
    String? paymentDate,
    String? method,
    String? notes,
  });

  /// Soft-deletes a payment. Sets is_deleted = true and deleted_at.
  Future<void> softDelete(String id);

  /// Restores a soft-deleted payment.
  Future<void> restore(String id);

  /// Soft-deletes all active payments in a group atomically.
  Future<void> softDeleteGroup(String groupId);

  /// Restores all soft-deleted payments in a group atomically.
  Future<void> restoreGroup(String groupId);

  /// Returns the sum of converted YER amounts for active payments of [projectId].
  Future<int> totalActivePaymentsYer(String projectId);

  /// Returns the count of all payments (including soft-deleted) for [projectId].
  Future<int> countAllByProject(String projectId);
}
