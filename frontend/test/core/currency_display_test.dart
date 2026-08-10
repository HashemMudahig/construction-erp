import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/core/database/finance/money_scale.dart';

void main() {
  group('formatCurrencyDisplay', () {
    test('YER has no decimal places and thousands separators', () {
      expect(formatCurrencyDisplay(400000, 'YER'), '400,000 YER');
    });

    test('SAR has two decimal places and thousands separators', () {
      expect(formatCurrencyDisplay(25000000, 'SAR'), '250,000.00 SAR');
    });

    test('Large YER amount is fully grouped', () {
      expect(formatCurrencyDisplay(150000000, 'YER'), '150,000,000 YER');
    });

    test('Zero renders without separators', () {
      expect(formatCurrencyDisplay(0, 'YER'), '0 YER');
      expect(formatCurrencyDisplay(0, 'SAR'), '0.00 SAR');
    });

    test('Negative keeps leading minus before the digits', () {
      expect(formatCurrencyDisplay(-307000, 'YER'), '-307,000 YER');
      expect(formatCurrencyDisplay(-25000000, 'SAR'), '-250,000.00 SAR');
    });

    test('Currency code is always the suffix, never the prefix', () {
      expect(formatCurrencyDisplay(1000, 'YER'), isNot(startsWith('YER')));
      expect(formatCurrencyDisplay(1000, 'SAR'), isNot(startsWith('SAR')));
    });

    test('Unsupported currency is rejected', () {
      expect(() => formatCurrencyDisplay(1, 'EUR'), throwsArgumentError);
    });
  });

  group('formatCurrencyCompact', () {
    test('SAR 250000 compacts to 250K SAR', () {
      expect(formatCurrencyCompact(25000000, 'SAR'), '250K SAR');
    });

    test('YER 1500000 compacts to 1.5M YER', () {
      expect(formatCurrencyCompact(1500000, 'YER'), '1.5M YER');
    });

    test('Small YER value stays as integer', () {
      expect(formatCurrencyCompact(999, 'YER'), '999 YER');
    });

    test('Small SAR value keeps two decimals', () {
      expect(formatCurrencyCompact(15050, 'SAR'), '150.50 SAR');
    });

    test('Negative compact keeps leading minus', () {
      expect(formatCurrencyCompact(-1500000, 'YER'), '-1.5M YER');
    });

    test('Unsupported currency is rejected', () {
      expect(() => formatCurrencyCompact(1, 'EUR'), throwsArgumentError);
    });
  });

  group('project details presentation regression', () {
    test('formatDisplayAmount still matches the unified formatter', () {
      // Imported via project_financial_presentation in its own test file; here
      // we assert the core formatter produces the same contract.
      expect(formatCurrencyDisplay(100000, 'YER'), '100,000 YER');
      expect(formatCurrencyDisplay(0, 'YER'), '0 YER');
      expect(formatCurrencyDisplay(-307000, 'YER'), '-307,000 YER');
    });
  });
}