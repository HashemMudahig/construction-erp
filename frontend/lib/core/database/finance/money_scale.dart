/// Scaled-INTEGER money utilities for multi-currency storage.
///
/// All monetary values are stored as SQLite INTEGER using per-currency
/// minor-unit scaling. This module provides exact conversion between
/// domain [Decimal] values and storage INTEGER values.
///
/// Rules (ADR-005):
/// - YER scale: 0 → minor factor 1.
/// - SAR scale: 2 → minor factor 100.
/// - Never use [double] for authoritative money.
/// - Reject excess decimal places.
/// - Reject negative amounts where the domain requires positive.
library;

import 'package:decimal/decimal.dart';

import '../database_constants.dart';

/// Returns the minor-unit factor for [currencyCode].
///
/// Throws [ArgumentError] for unsupported currencies.
int minorUnitFactor(String currencyCode) {
  switch (currencyCode) {
    case kCurrencyYer:
      return kYerMinorFactor;
    case kCurrencySar:
      return kSarMinorFactor;
    default:
      throw ArgumentError('Unsupported currency code: $currencyCode');
  }
}

/// Returns the decimal scale for [currencyCode].
///
/// Throws [ArgumentError] for unsupported currencies.
int currencyScale(String currencyCode) {
  switch (currencyCode) {
    case kCurrencyYer:
      return kYerScale;
    case kCurrencySar:
      return kSarScale;
    default:
      throw ArgumentError('Unsupported currency code: $currencyCode');
  }
}

/// Validates that [currencyCode] is a supported currency.
void validateCurrencyCode(String currencyCode) {
  if (!kSupportedCurrencies.contains(currencyCode)) {
    throw ArgumentError('Unsupported currency code: $currencyCode');
  }
}

/// Converts a [Decimal] amount to scaled INTEGER minor units.
///
/// Throws [ArgumentError] if:
/// - The currency is unsupported.
/// - The amount has more fractional digits than the currency allows.
/// - [requirePositive] is true and the amount is zero or negative.
/// - The resulting integer overflows SQLite signed 64-bit range.
int toMinorUnits(Decimal amount, String currencyCode,
    {bool requirePositive = false}) {
  validateCurrencyCode(currencyCode);

  if (requirePositive && amount <= Decimal.zero) {
    throw ArgumentError('Amount must be positive: $amount');
  }

  final scale = currencyScale(currencyCode);
  final factor = minorUnitFactor(currencyCode);

  // Multiply by factor using exact Decimal arithmetic.
  final scaled = amount * Decimal.fromInt(factor);

  // The scaled value must be a whole number (no fractional part).
  // Decimal.parse of a value with excess decimals will have a non-zero
  // fractional component after multiplication.
  final scaledString = scaled.toString();
  final dotIndex = scaledString.indexOf('.');
  if (dotIndex != -1) {
    final fractional = scaledString.substring(dotIndex + 1);
    final hasNonZeroFraction = fractional.split('').any((c) => c != '0');
    if (hasNonZeroFraction) {
      throw ArgumentError(
        'Amount $amount has more decimal places than currency $currencyCode allows (scale $scale)',
      );
    }
  }

  // Parse as integer.
  final intValue = int.parse(scaledString.split('.').first);

  if (intValue < kSqliteIntMin || intValue > kSqliteIntMax) {
    throw ArgumentError('Amount overflows SQLite INTEGER range: $intValue');
  }

  return intValue;
}

/// Converts a [String] amount to scaled INTEGER minor units.
///
/// Throws [ArgumentError] for invalid decimal strings or unsupported currencies.
int toMinorUnitsFromString(String amount, String currencyCode,
    {bool requirePositive = false}) {
  final decimal = Decimal.parse(amount);
  return toMinorUnits(decimal, currencyCode, requirePositive: requirePositive);
}

/// Converts scaled INTEGER minor units back to a display [Decimal].
///
/// Throws [ArgumentError] for unsupported currencies.
Decimal fromMinorUnits(int minorUnits, String currencyCode) {
  validateCurrencyCode(currencyCode);
  final factor = minorUnitFactor(currencyCode);
  // Division returns Rational; convert to Decimal via toRational and then parse.
  final rational = Decimal.fromInt(minorUnits) / Decimal.fromInt(factor);
  return Decimal.parse(rational.toDecimal().toString());
}

/// Converts scaled INTEGER minor units to a display string.
///
/// The string will have the correct number of decimal places for the currency.
String formatMinorUnits(int minorUnits, String currencyCode) {
  validateCurrencyCode(currencyCode);
  final scale = currencyScale(currencyCode);
  final factor = minorUnitFactor(currencyCode);

  if (scale == 0) {
    return minorUnits.toString();
  }

  final isNegative = minorUnits < 0;
  final absValue = isNegative ? -minorUnits : minorUnits;
  final intPart = absValue ~/ factor;
  final fracPart = absValue % factor;
  final fracStr = fracPart.toString().padLeft(scale, '0');
  final result = '$intPart.$fracStr';
  return isNegative ? '-$result' : result;
}

/// Adds thousands separators (`,`) to the integer part of [digits].
///
/// [digits] must be a string of decimal digits, optionally with a leading
/// `-`. Used by the currency display formatters.
String _groupThousands(String digits) {
  final isNegative = digits.startsWith('-');
  final abs = isNegative ? digits.substring(1) : digits;
  final grouped = abs.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return isNegative ? '-$grouped' : grouped;
}

/// Unified currency display formatter.
///
/// Formats [minorUnits] for [currencyCode] with:
/// - The correct number of decimal places (YER: 0, SAR: 2).
/// - Thousands separators (`,`).
/// - A leading `-` for negative values.
/// - The currency code as a suffix, separated by a single space.
///
/// Examples:
///   `formatCurrencyDisplay(400000, 'YER')` → `'400,000 YER'`
///   `formatCurrencyDisplay(25000000, 'SAR')` → `'250,000.00 SAR'`
///   `formatCurrencyDisplay(-307000, 'YER')` → `'-307,000 YER'`
///   `formatCurrencyDisplay(150000000, 'YER')` → `'150,000,000 YER'`
///
/// This is a presentation-only formatter. It never touches financial
/// calculations, exchange logic, or stored values. It uses Western digits
/// in both UI locales to match the established accounting display contract.
String formatCurrencyDisplay(int minorUnits, String currencyCode) {
  validateCurrencyCode(currencyCode);
  final raw = formatMinorUnits(minorUnits.abs(), currencyCode);
  final parts = raw.split('.');
  final grouped = _groupThousands(parts.first);
  final decimals = parts.length > 1 ? '.${parts[1]}' : '';
  final sign = minorUnits < 0 ? '-' : '';
  return '$sign$grouped$decimals $currencyCode';
}

/// Compact currency display formatter for space-constrained cards.
///
/// Returns a short form using K (thousands) or M (millions) with the
/// currency code suffix. Examples:
///   `formatCurrencyCompact(250000, 'SAR')` → `'250K SAR'`
///   `formatCurrencyCompact(1500000, 'YER')` → `'1.5M YER'`
///   `formatCurrencyDisplay` should be used wherever space allows; this
///   helper is only for small cards that would otherwise clip.
String formatCurrencyCompact(int minorUnits, String currencyCode) {
  validateCurrencyCode(currencyCode);
  final scale = currencyScale(currencyCode);
  final factor = minorUnitFactor(currencyCode);
  final isNegative = minorUnits < 0;
  final absMinor = isNegative ? -minorUnits : minorUnits;
  // Convert to major units as a double only for compact scaling. This is
  // display-only; no financial calculation uses this value.
  final major = absMinor / factor;
  String compact;
  if (major >= 1000000) {
    compact = '${(major / 1000000).toStringAsFixed(1)}M';
  } else if (major >= 1000) {
    final thousands = major / 1000;
    compact = thousands == thousands.roundToDouble()
        ? '${thousands.round()}K'
        : '${thousands.toStringAsFixed(1)}K';
  } else if (scale == 2) {
    final intPart = absMinor ~/ factor;
    final fracPart = absMinor % factor;
    compact = '$intPart.${fracPart.toString().padLeft(scale, '0')}';
  } else {
    compact = '$absMinor';
  }
  return '${isNegative ? '-' : ''}$compact $currencyCode';
}
