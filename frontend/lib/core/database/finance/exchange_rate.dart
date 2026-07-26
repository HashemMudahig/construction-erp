/// Exchange-rate utilities for scaled-INTEGER storage.
///
/// Exchange rates are stored as SQLite INTEGER with scale 6.
/// The rate means the number of YER for one whole unit of the original currency.
/// Example: 1 SAR = 410 YER → rate = 410.000000 → stored as 410000000.
///
/// Rules (ADR-005):
/// - Never use [double] for exchange rates.
/// - Reject rates with more than 6 fractional digits.
/// - Reject zero or negative rates.
/// - Identity rate for YER: 1.000000 → 1,000,000.
library;

import 'package:decimal/decimal.dart';

import '../database_constants.dart';

/// Converts a [Decimal] exchange rate to scaled INTEGER (scale 6).
///
/// Throws [ArgumentError] if:
/// - The rate has more than 6 fractional digits.
/// - The rate is zero or negative.
/// - The resulting integer overflows SQLite signed 64-bit range.
int toScaledExchangeRate(Decimal rate) {
  if (rate <= Decimal.zero) {
    throw ArgumentError('Exchange rate must be positive: $rate');
  }

  final scaled = rate * Decimal.fromInt(kExchangeRateFactor);
  final scaledString = scaled.toString();
  final dotIndex = scaledString.indexOf('.');

  if (dotIndex != -1) {
    final fractional = scaledString.substring(dotIndex + 1);
    final hasNonZeroFraction = fractional.split('').any((c) => c != '0');
    if (hasNonZeroFraction) {
      throw ArgumentError(
        'Exchange rate $rate has more than $kExchangeRateScale fractional digits',
      );
    }
  }

  final intValue = int.parse(scaledString.split('.').first);

  if (intValue < kSqliteIntMin || intValue > kSqliteIntMax) {
    throw ArgumentError(
        'Exchange rate overflows SQLite INTEGER range: $intValue');
  }

  return intValue;
}

/// Converts a [String] exchange rate to scaled INTEGER (scale 6).
int toScaledExchangeRateFromString(String rate) {
  return toScaledExchangeRate(Decimal.parse(rate));
}

/// Converts scaled INTEGER exchange rate back to a display [Decimal].
Decimal fromScaledExchangeRate(int scaledRate) {
  final rational =
      Decimal.fromInt(scaledRate) / Decimal.fromInt(kExchangeRateFactor);
  return Decimal.parse(rational.toDecimal().toString());
}

/// Converts scaled INTEGER exchange rate to a display string with 6 decimals.
String formatScaledExchangeRate(int scaledRate) {
  final isNegative = scaledRate < 0;
  final absValue = isNegative ? -scaledRate : scaledRate;
  final intPart = absValue ~/ kExchangeRateFactor;
  final fracPart = absValue % kExchangeRateFactor;
  final fracStr = fracPart.toString().padLeft(kExchangeRateScale, '0');
  final result = '$intPart.$fracStr';
  return isNegative ? '-$result' : result;
}

/// Returns the identity exchange rate for YER transactions.
int get identityExchangeRate => kIdentityExchangeRate;
