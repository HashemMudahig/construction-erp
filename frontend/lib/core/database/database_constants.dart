/// Centralized constants for the local SQLite database.
///
/// All scale values, currency codes, and schema constants are defined here
/// to avoid magic numbers scattered across the codebase.
library;

/// Current local database schema version.
///
/// Increment this when adding migrations. Each version must have a
/// corresponding migration step in [AppDatabase].
const int kSchemaVersion = 6;

/// SQLite database file name.
const String kDatabaseFileName = 'construction_erp.db';

// ---------------------------------------------------------------------------
// Currency constants
// ---------------------------------------------------------------------------

/// Yemeni Rial — base reporting currency.
const String kCurrencyYer = 'YER';

/// Saudi Riyal — secondary supported currency.
const String kCurrencySar = 'SAR';

/// All supported currency codes.
const List<String> kSupportedCurrencies = [kCurrencyYer, kCurrencySar];

/// YER decimal scale: 0 (no fractional digits).
const int kYerScale = 0;

/// SAR decimal scale: 2 (2 fractional digits).
const int kSarScale = 2;

/// YER minor-unit factor: 10^0 = 1.
const int kYerMinorFactor = 1;

/// SAR minor-unit factor: 10^2 = 100.
const int kSarMinorFactor = 100;

// ---------------------------------------------------------------------------
// Exchange-rate constants
// ---------------------------------------------------------------------------

/// Exchange-rate decimal scale: 6 fractional digits.
const int kExchangeRateScale = 6;

/// Exchange-rate scale factor: 10^6 = 1,000,000.
const int kExchangeRateFactor = 1000000;

/// Identity exchange rate for YER transactions (1.000000 → 1,000,000).
const int kIdentityExchangeRate = kExchangeRateFactor;

/// Default suggestion for new per-transaction SAR entries: 410 YER / SAR.
const int kDefaultSarToYerRateScaled = 410000000;

const String kDefaultLocaleCode = 'en';
const List<String> kSupportedLocaleCodes = ['en', 'ar'];

// ---------------------------------------------------------------------------
// Rate source constants
// ---------------------------------------------------------------------------

const String kRateSourceIdentity = 'identity';
const String kRateSourceDefault = 'default';
const String kRateSourceProject = 'project';
const String kRateSourceManual = 'manual';

const List<String> kValidRateSources = [
  kRateSourceIdentity,
  kRateSourceDefault,
  kRateSourceProject,
  kRateSourceManual,
];

// ---------------------------------------------------------------------------
// Exchange policy constants
// ---------------------------------------------------------------------------

const String kExchangePolicyFixed = 'fixed';
const String kExchangePolicyPerTransaction = 'per_transaction';

const List<String> kValidExchangePolicies = [
  kExchangePolicyFixed,
  kExchangePolicyPerTransaction,
];

// ---------------------------------------------------------------------------
// Verified business enum value constants.
// ---------------------------------------------------------------------------

const List<String> kProjectStatuses = [
  'planning',
  'active',
  'completed',
  'on_hold',
  'cancelled',
];

const List<String> kMilestoneStatuses = [
  'pending',
  'in_progress',
  'completed',
  'overdue',
];

const List<String> kPaymentMethods = [
  'cash',
  'bank_transfer',
  'cheque',
  'other',
];

const List<String> kExpenseCategories = [
  'materials',
  'labor',
  'equipment',
  'permits',
  'other',
];

// ---------------------------------------------------------------------------
// SQLite INTEGER range (signed 64-bit)
// ---------------------------------------------------------------------------

/// Minimum value for SQLite signed 64-bit INTEGER.
const int kSqliteIntMin = -9223372036854775808;

/// Maximum value for SQLite signed 64-bit INTEGER.
const int kSqliteIntMax = 9223372036854775807;
