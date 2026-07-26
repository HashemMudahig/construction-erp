/// Currency snapshot validation utilities.
///
/// Ensures that transaction rows comply with the accepted multi-currency
/// contract (ADR-005) at the utility level. These validations are not
/// connected to feature repositories during Phase 02.
///
/// YER identity policy:
/// - exchange_rate_scaled = 1,000,000 (identity rate)
/// - rate_source = "identity"
/// - converted_yer_amount = original_amount_minor
///
/// SAR conversion policy:
/// - exchange_rate_scaled > 0
/// - converted_yer_amount = roundHalfUp(original_amount_minor × exchange_rate_scaled ÷ (100 × 1,000,000))
library;

import '../database_constants.dart';
import 'currency_conversion.dart';
import 'money_scale.dart';

/// Validates a YER transaction snapshot.
///
/// Throws [ArgumentError] if:
/// - The currency is not YER.
/// - The exchange rate is not the identity rate (1,000,000).
/// - The converted amount does not equal the original amount.
void validateYerSnapshot({
  required int originalAmountMinor,
  required String originalCurrency,
  required int exchangeRateScaled,
  required int convertedYerAmount,
  required String rateSource,
}) {
  if (originalCurrency != kCurrencyYer) {
    throw ArgumentError(
        'YER snapshot requires currency=YER, got: $originalCurrency');
  }
  if (exchangeRateScaled != kIdentityExchangeRate) {
    throw ArgumentError(
      'YER snapshot requires exchange_rate_scaled=$kIdentityExchangeRate, got: $exchangeRateScaled',
    );
  }
  if (rateSource != kRateSourceIdentity) {
    throw ArgumentError(
      'YER snapshot requires rate_source="$kRateSourceIdentity", got: $rateSource',
    );
  }
  if (convertedYerAmount != originalAmountMinor) {
    throw ArgumentError(
      'YER snapshot requires converted_yer_amount=$originalAmountMinor, got: $convertedYerAmount',
    );
  }
}

/// Validates a SAR transaction snapshot.
///
/// Throws [ArgumentError] if:
/// - The currency is not SAR.
/// - The exchange rate is not positive.
/// - The converted amount does not match the exact round-half-up calculation.
void validateSarSnapshot({
  required int originalAmountMinor,
  required String originalCurrency,
  required int exchangeRateScaled,
  required int convertedYerAmount,
}) {
  if (originalCurrency != kCurrencySar) {
    throw ArgumentError(
        'SAR snapshot requires currency=SAR, got: $originalCurrency');
  }
  if (exchangeRateScaled <= 0) {
    throw ArgumentError(
        'SAR snapshot requires positive exchange rate, got: $exchangeRateScaled');
  }
  final expected =
      convertToYer(originalAmountMinor, kCurrencySar, exchangeRateScaled);
  if (convertedYerAmount != expected) {
    throw ArgumentError(
      'SAR snapshot: converted_yer_amount=$convertedYerAmount does not match '
      'expected=$expected (roundHalfUp($originalAmountMinor * $exchangeRateScaled / '
      '${kSarMinorFactor * kExchangeRateFactor}))',
    );
  }
}

/// Validates any transaction snapshot based on its currency.
///
/// Dispatches to [validateYerSnapshot] or [validateSarSnapshot].
void validateSnapshot({
  required int originalAmountMinor,
  required String originalCurrency,
  required int exchangeRateScaled,
  required int convertedYerAmount,
  required String rateSource,
}) {
  validateCurrencyCode(originalCurrency);
  switch (originalCurrency) {
    case kCurrencyYer:
      validateYerSnapshot(
        originalAmountMinor: originalAmountMinor,
        originalCurrency: originalCurrency,
        exchangeRateScaled: exchangeRateScaled,
        convertedYerAmount: convertedYerAmount,
        rateSource: rateSource,
      );
    case kCurrencySar:
      validateSarSnapshot(
        originalAmountMinor: originalAmountMinor,
        originalCurrency: originalCurrency,
        exchangeRateScaled: exchangeRateScaled,
        convertedYerAmount: convertedYerAmount,
      );
    default:
      throw ArgumentError('Unsupported currency: $originalCurrency');
  }
}
