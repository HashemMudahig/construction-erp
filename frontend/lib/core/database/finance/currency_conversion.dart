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

/// Converts a minor-unit amount in [fromCurrency] to [toCurrency] minor units
/// using the immutable per-transaction exchange rate [exchangeRateScaled]
/// (scale-6 INTEGER, expressed as YER per 1 SAR).
///
/// This is the canonical multi-currency conversion used to aggregate
/// payments and expenses into the **contract currency**. It uses each
/// row's own historical rate snapshot, so historical exchange rates are
/// preserved and never recalculated against the current rate.
///
/// Conversion rules:
/// - [fromCurrency] == [toCurrency]: identity (returns [amount] unchanged).
/// - YER → SAR: `roundHalfUp(amount × sarMinorFactor × exchangeRateFactor ÷ rate)`
///   where `rate` is the scale-6 YER/SAR rate. This is the exact inverse of
///   the SAR → YER formula in [convertToYer].
/// - SAR → YER: delegates to [convertToYer].
///
/// Throws [ArgumentError] if:
/// - Either currency is unsupported.
/// - The currencies differ and [exchangeRateScaled] is not positive.
/// - The result overflows SQLite signed 64-bit range.
///
/// Example (YER → SAR at rate 420.000000):
///   amount = 100,000,000 YER, rate = 420000000
///   result = roundHalfUp(100000000 × 100 × 1000000 ÷ 420000000)
///         = roundHalfUp(23809523.8) = 23809524 SAR minor
int convertToCurrency(
  int amount,
  String fromCurrency,
  String toCurrency,
  int exchangeRateScaled,
) {
  validateCurrencyCode(fromCurrency);
  validateCurrencyCode(toCurrency);

  if (fromCurrency == toCurrency) {
    return amount;
  }

  if (exchangeRateScaled <= 0) {
    throw ArgumentError(
        'Exchange rate must be positive when converting between currencies');
  }

  if (fromCurrency == kCurrencyYer && toCurrency == kCurrencySar) {
    // YER → SAR: amount × sarMinorFactor × exchangeRateFactor ÷ rate
    // This is the exact inverse of convertToYer's SAR → YER formula:
    //   YER = SAR × rate ÷ (sarFactor × rateFactor)
    //   SAR = YER × sarFactor × rateFactor ÷ rate
    final amountBig = BigInt.from(amount);
    final sarFactor = BigInt.from(kSarMinorFactor);
    final rateFactor = BigInt.from(kExchangeRateFactor);
    final rateBig = BigInt.from(exchangeRateScaled);
    final numerator = amountBig * sarFactor * rateFactor;
    final halfRate = rateBig ~/ BigInt.two;
    final rounded = (numerator + halfRate) ~/ rateBig;
    if (rounded > BigInt.from(kSqliteIntMax) ||
        rounded < BigInt.from(kSqliteIntMin)) {
      throw ArgumentError(
          'Converted amount overflows SQLite INTEGER range: $rounded');
    }
    return rounded.toInt();
  }

  // SAR → YER
  return convertToYer(amount, fromCurrency, exchangeRateScaled);
}
