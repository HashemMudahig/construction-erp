import 'package:construction_erp/features/projects/presentation/project_financial_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('amount formatting keeps a leading minus and exact separators', () {
    expect(formatDisplayAmount(100000, 'YER'), '100,000 YER');
    expect(formatDisplayAmount(0, 'YER'), '0 YER');
    expect(formatDisplayAmount(-307000, 'YER'), '-307,000 YER');
    expect(formatDisplayAmount(-307000, 'YER'), isNot('YER 307000-'));
  });

  test('cash-flow status is derived without profit terminology', () {
    expect(cashFlowPresentation(1).statusKey, 'cash_surplus');
    expect(cashFlowPresentation(0).statusKey, 'cash_balanced');
    expect(cashFlowPresentation(-1).statusKey, 'cash_deficit');
    expect(cashFlowPresentation(-1).statusKey, isNot(contains('profit')));
  });

  test('cost overrun compares only a reliable YER contract basis', () {
    expect(
      calculateCostOverrun(
        contractValueYer: 400000,
        totalExpensesYer: 407000,
      ),
      7000,
    );
    expect(
      calculateCostOverrun(
        contractValueYer: 400000,
        totalExpensesYer: 400000,
      ),
      isNull,
    );
    expect(
      calculateCostOverrun(
        contractValueYer: null,
        totalExpensesYer: 407000,
      ),
      isNull,
    );
  });
}
