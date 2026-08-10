# Project Details Financial Summary and Localization

## Final terminology

The first Project Details tab is **Financial summary / الملخص المالي**, not
profitability. It reports:

1. Contract value
2. Payments received
3. Expenses
4. Remaining contract value
5. Net cash flow

`remainingContractValue = contractValue - paymentsReceived`

`netCashFlow = paymentsReceived - expenses`

Amounts use exact stored integers and conventional sign/group formatting, for
example `-307,000 YER`. Negative cash flow is never called profit.

## Presentation-only statuses

- Positive: Cash surplus / فائض نقدي.
- Zero: Cash balanced / متعادل نقديًا.
- Negative: Cash deficit / عجز نقدي.

The supporting sentence uses the absolute difference, while the displayed net
cash flow retains its negative sign.

## Cost overrun

`costOverrun = expenses - contractValue`

The warning appears only when expenses exceed a contract value that already has
a reliable YER comparison basis. YER contracts compare directly; fixed-rate SAR
contracts use the existing fixed project rate. Per-transaction SAR contracts
are not compared, so no historical conversion is invented.

Cash deficit compares received payments with expenses. Cost overrun compares
contract value with expenses; both may appear independently.

## Canonical localization mappings

Expense values remain `materials`, `labor`, `equipment`, `permits`, and `other`
in SQLite, domain models, reports, and backups. Presentation maps them to:

| Canonical | English | Arabic |
|---|---|---|
| materials | Materials | مواد |
| labor | Labor | أجور العمال |
| equipment | Equipment | معدات |
| permits | Permits | تصاريح |
| other | Other | أخرى |

The same presentation-only mapping pattern is used for existing payment methods
and milestone statuses. Dialog titles, fields, dates, validation, actions,
selected values, and transaction rows follow the active locale.

## Screens audited

- Project Details header and tabs
- Financial cards, cash-flow status, and cost warning
- Milestone list/dialog
- Payment list/dialog
- Expense list/dialog
- Empty/error states and narrow dropdown behavior

## Validation

- Focused financial/localization tests: 9 passed.
- Full Flutter suite: 444 passed.
- Debug APK: built successfully.
- Analyzer: no compilation errors; exit 1 with 103 existing lint
  info/warnings, primarily const suggestions in broader UI files.
- Schema remains v4; no networking/auth/backend/Backup behavior changed.

## Remaining product decisions

- Decide whether a future product version should define a report-basis contract
  conversion for per-transaction SAR projects. The current UI correctly avoids
  an unsupported cost-overrun comparison.
- Existing repository-wide UI lint debt may be handled in a separate,
  deliberately scoped cleanup.
