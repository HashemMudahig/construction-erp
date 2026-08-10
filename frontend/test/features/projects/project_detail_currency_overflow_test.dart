import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/core/localization/app_localizations.dart';
import 'package:construction_erp/features/expenses/domain/expense_entity.dart';
import 'package:construction_erp/features/expenses/presentation/expense_providers.dart';
import 'package:construction_erp/features/milestones/domain/milestone_entity.dart';
import 'package:construction_erp/features/milestones/presentation/milestone_providers.dart';
import 'package:construction_erp/features/payments/domain/payment_entity.dart';
import 'package:construction_erp/features/payments/presentation/payment_providers.dart';
import 'package:construction_erp/features/projects/domain/project_entity.dart';
import 'package:construction_erp/features/projects/domain/project_repository_interface.dart';
import 'package:construction_erp/features/projects/presentation/project_detail_screen.dart';
import 'package:construction_erp/features/projects/presentation/project_providers.dart';

const _projectId = 'bbbbbbbb-0000-4000-8000-000000000001';

ProjectEntity _sarFixedProject() => ProjectEntity(
      id: _projectId,
      clientId: 'aaaaaaaa-0000-4000-8000-000000000001',
      name: 'SAR Tower',
      budgetAmountMinor: 25000000, // 250,000.00 SAR
      originalContractValueMinor: 25000000,
      budgetCurrency: 'SAR',
      exchangePolicy: 'fixed',
      fixedExchangeRateScaled: 410000000,
      status: 'active',
      createdAt: DateTime.utc(2026, 1, 1),
    );

ProjectEntity _yerProject() => ProjectEntity(
      id: _projectId,
      clientId: 'aaaaaaaa-0000-4000-8000-000000000001',
      name: 'YER Villas',
      budgetAmountMinor: 150000000, // 150,000,000 YER
      originalContractValueMinor: 150000000,
      budgetCurrency: 'YER',
      status: 'active',
      createdAt: DateTime.utc(2026, 1, 1),
    );

class _StubProjectRepository implements ProjectRepositoryInterface {
  _StubProjectRepository(this._project);
  final ProjectEntity _project;

  @override
  Future<ProjectEntity?> getById(String id) async =>
      id == _project.id ? _project : null;

  @override
  Future<ProjectFinancialSummary> getFinancialSummary(String projectId) async =>
      ProjectFinancialSummary(
        totalPaymentsYer: 100000000,
        totalExpensesYer: 40000000,
        balance: 60000000,
        profitMargin: 0.6,
        contractCurrency: _project.budgetCurrency,
        currentContractValue: _project.budgetAmountMinor,
        originalContractValue: _project.originalContractValueMinor,
        totalPaymentsContractCurrency: 100000000,
        totalExpensesContractCurrency: 40000000,
        remainingContractValue:
            _project.budgetAmountMinor - 100000000,
        netCashFlow: 60000000,
        paymentsByCurrency: const [
          CurrencyBreakdownEntry(currency: 'YER', amountMinor: 100000000),
        ],
        expensesByCurrency: const [
          CurrencyBreakdownEntry(currency: 'YER', amountMinor: 40000000),
        ],
      );

  @override
  Future<List<ProjectEntity>> list({
    String? clientId,
    String? status,
    String? search,
  }) async => const [];

  @override
  Future<ProjectEntity> create({
    required String clientId,
    required String name,
    String? description,
    required int budgetAmountMinor,
    required String budgetCurrency,
    String exchangePolicy = 'per_transaction',
    int? fixedExchangeRateScaled,
    String? startDate,
    String? endDate,
    String status = 'planning',
  }) async => throw UnimplementedError();

  @override
  Future<ProjectEntity> update({
    required String id,
    String? clientId,
    String? name,
    String? description,
    int? budgetAmountMinor,
    String? budgetCurrency,
    String? exchangePolicy,
    int? fixedExchangeRateScaled,
    String? startDate,
    String? endDate,
    String? status,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteIfEligible(String id) async => throw UnimplementedError();

  @override
  Future<bool> hasChildRecords(String id) async => false;

  @override
  Future<ProjectEntity> amendContract({
    required String id,
    required int newContractValueMinor,
  }) async => throw UnimplementedError();
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required Locale locale,
  required ProjectEntity project,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectRepositoryProvider
            .overrideWithValue(_StubProjectRepository(project)),
        paymentsByProjectProvider(_projectId)
            .overrideWith((ref) async => const <PaymentEntity>[]),
        expensesByProjectProvider(_projectId)
            .overrideWith((ref) async => const <ExpenseEntity>[]),
        milestonesByProjectProvider(_projectId)
            .overrideWith((ref) async => const <MilestoneEntity>[]),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const ProjectDetailScreen(id: _projectId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Redmi Note 8 Pro logical size at ~3.0 device pixel ratio: 1080x2310 / 3.
  const redmiSize = Size(360, 770);

  group('ProjectDetailScreen currency formatting (en)', () {
    testWidgets('SAR fixed contract renders as 250,000.00 SAR', (tester) async {
      await _pumpDetail(
        tester,
        locale: const Locale('en'),
        project: _sarFixedProject(),
        size: const Size(800, 1280),
      );
      // Appears in the header stat and the profitability contract card.
      expect(find.text('250,000.00 SAR'), findsNWidgets(2));
    });

    testWidgets('YER large contract renders as 150,000,000 YER', (tester) async {
      await _pumpDetail(
        tester,
        locale: const Locale('en'),
        project: _yerProject(),
        size: const Size(800, 1280),
      );
      expect(find.text('150,000,000 YER'), findsNWidgets(2));
    });
  });

  group('ProjectDetailScreen no overflow on small screen', () {
    testWidgets('SAR fixed value fits on small screen (en)',
        (tester) async {
      await _pumpDetail(
        tester,
        locale: const Locale('en'),
        project: _sarFixedProject(),
        size: redmiSize,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('250,000.00 SAR'), findsNWidgets(2));
    });

    testWidgets('Large YER value fits on small screen (en)',
        (tester) async {
      await _pumpDetail(
        tester,
        locale: const Locale('en'),
        project: _yerProject(),
        size: redmiSize,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('150,000,000 YER'), findsNWidgets(2));
    });

    testWidgets('SAR fixed value fits on small screen in RTL Arabic',
        (tester) async {
      await _pumpDetail(
        tester,
        locale: const Locale('ar'),
        project: _sarFixedProject(),
        size: redmiSize,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('250,000.00 SAR'), findsNWidgets(2));
    });

    testWidgets('Large YER value fits on small screen in RTL Arabic',
        (tester) async {
      await _pumpDetail(
        tester,
        locale: const Locale('ar'),
        project: _yerProject(),
        size: redmiSize,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('150,000,000 YER'), findsNWidgets(2));
    });

    testWidgets('Net cash flow large positive value fits (en)', (tester) async {
      // balance is 60,000,000 YER; formatDisplayAmount keeps the sign.
      await _pumpDetail(
        tester,
        locale: const Locale('en'),
        project: _yerProject(),
        size: redmiSize,
      );
      // The net cash flow card renders 60,000,000 YER (balance is positive).
      expect(find.text('60,000,000 YER'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ProjectDetailScreen Arabic financial labels', () {
    testWidgets('uses localized contract value label in Arabic',
        (tester) async {
      await _pumpDetail(
        tester,
        locale: const Locale('ar'),
        project: _sarFixedProject(),
        size: const Size(800, 1280),
      );
      expect(find.text('قيمة العقد'), findsWidgets);
      // English label must not leak.
      expect(find.text('Contract value'), findsNothing);
    });
  });
}