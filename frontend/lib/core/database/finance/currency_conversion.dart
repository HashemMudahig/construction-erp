/// Currency conversion utilities using exact integer arithmetic.
///
/// Converts non-YER amounts to the base reporting currency (YER) using
/// scaled-INTEGER arithmetic. No [double] is used at any stage.
///
/// Conversion formula (ADR-005):
///
/// For YER:
///   converted_yer_amount = original_amount_minor
///
/// For SAR:
///   converted_yer_amount =
///     roundHalfUp(
///       original_amount_minor × exchange_rate_scaled
///       ÷ (SAR_minor_factor × exchange_rate_factor)
///     )
///
/// Example:
///   Original: 1,000.50 SAR → minor = 100050
///   Rate: 410.000000 → scaled = 410000000
///   Result: roundHalfUp(100050 × 410000000 ÷ (100 × 1000000))
///         = roundHalfUp(41020500000000 ÷ 100000000)
///         = roundHalfUp(410205.0)
///         = 410205 YER
library;

import 'package:decimal/decimal.dart';

import '../database_constants.dart';
import 'exchange_rate.dart';
import 'money_scale.dart';

/// Converts a minor-unit amount in [originalCurrency] to YER minor units
/// using [exchangeRateScaled] (scale-6 INTEGER).
///
/// For YER: returns [originalAmountMinor] unchanged.
/// For SAR: applies the conversion formula with round-half-up.
///
/// Throws [ArgumentError] if:
/// - The currency is unsupported.
/// - The exchange rate is not positive for non-YER currencies.
/// - The result overflows SQLite signed 64-bit range.
int convertToYer(
  int originalAmountMinor,
  String originalCurrency,
  int exchangeRateScaled,
) {
  validateCurrencyCode(originalCurrency);

  if (originalCurrency == kCurrencyYer) {
    return originalAmountMinor;
  }

  if (exchangeRateScaled <= 0) {
    throw ArgumentError(
        'Exchange rate must be positive for non-YER currencies');
  }

  // Use BigInt for intermediate multiplication to avoid overflow.
  final amountBig = BigInt.from(originalAmountMinor);
  final rateBig = BigInt.from(exchangeRateScaled);

  // Divisor = minor_factor × exchange_rate_factor
  // For SAR: 100 × 1,000,000 = 100,000,000
  final minorFactor = BigInt.from(minorUnitFactor(originalCurrency));
  final rateFactor = BigInt.from(kExchangeRateFactor);
  final divisor = minorFactor * rateFactor;

  // numerator = original_amount_minor × exchange_rate_scaled
  final numerator = amountBig * rateBig;

  // Round half up: (numerator + divisor/2) / divisor
  final halfDivisor = divisor ~/ BigInt.two;
  final rounded = (numerator + halfDivisor) ~/ divisor;

  // Check overflow
  if (rounded > BigInt.from(kSqliteIntMax) ||
      rounded < BigInt.from(kSqliteIntMin)) {
    throw ArgumentError(
        'Converted amount overflows SQLite INTEGER range: $rounded');
  }

  return rounded.toInt();
}

/// Converts a [Decimal] amount in [originalCurrency] to YER minor units
/// using a [Decimal] exchange rate.
///
/// This is a convenience method for domain-layer use. The canonical storage
/// path uses [convertToYer] with pre-scaled INTEGER values.
int convertDecimalToYer(
  Decimal originalAmount,
  String originalCurrency,
  Decimal exchangeRate,
) {
  final minorUnits = toMinorUnits(originalAmount, originalCurrency);
  final scaledRate = toScaledExchangeRate(exchangeRate);
  return convertToYer(minorUnits, originalCurrency, scaledRate);
}

/// Rounds a [Decimal] half-up to the nearest integer.
///
/// Example: 410.5 → 411, 410.4 → 410, 410.0 → 410.
int roundHalfUp(Decimal value) {
  final truncated = value.truncate();
  final truncatedInt = truncated.toBigInt().toInt();
  final remainder = value - truncated;
  if (remainder >= Decimal.parse('0.5')) {
    return truncatedInt + 1;
  }
  return truncatedInt;
}

/// Returns the YER identity exchange rate for YER transactions.
int yerIdentityRate() => identityExchangeRate;
