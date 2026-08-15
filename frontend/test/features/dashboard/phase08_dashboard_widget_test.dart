import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:construction_erp/core/localization/app_localizations.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/features/dashboard/domain/dashboard_models.dart';
import 'package:construction_erp/features/dashboard/presentation/dashboard_providers.dart';
import 'package:construction_erp/features/dashboard/presentation/dashboard_screen.dart';
import 'package:construction_erp/features/transfers/domain/wallet_balance_service.dart';

class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(Locale locale) {
    state = locale;
  }
}

const _summary = DashboardSummary(
  activeClientCount: 2,
  totalProjectCount: 2,
  planningProjectCount: 0,
  activeProjectCount: 1,
  completedProjectCount: 1,
  onHoldProjectCount: 0,
  cancelledProjectCount: 0,
  totalPaymentsYer: 1000,
  totalExpensesYer: 2500,
);

final _walletBalances = ProjectWalletBalances(
  balances: [
    WalletBalanceEntry(currency: kCurrencySar, amountMinor: 100000),
    WalletBalanceEntry(currency: kCurrencyYer, amountMinor: -1500),
  ],
  paymentsByCurrency: {kCurrencySar: 100000, kCurrencyYer: 1000},
  expensesByCurrency: {kCurrencyYer: 2500},
  transfersByCurrency: {},
);

const _project = DashboardProjectOverview(
  projectId: 'bbbbbbbb-0000-4000-8000-000000000001',
  projectName: 'Narrow viewport project with a long name',
  projectStatus: 'active',
  clientName: 'Client name',
  totalPaymentsYer: 1000,
  totalExpensesYer: 2500,
  completedMilestones: 1,
  totalMilestones: 2,
);

List<DashboardFinanceMonth> get _timeline => List.generate(12, (index) {
      final date = DateTime(2025, 8 + index);
      return DashboardFinanceMonth(
        year: date.year,
        month: date.month,
        totalPaymentsYer: index == 11 ? 1000 : 0,
        totalExpensesYer: index == 11 ? 2500 : 0,
      );
    });

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
  Future<DashboardSummary>? summary,
  Future<ProjectWalletBalances>? wallet,
  Future<List<DashboardProjectOverview>>? projects,
  Future<List<DashboardFinanceMonth>>? finance,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => _FixedLocaleNotifier(locale)),
        dashboardSummaryProvider
            .overrideWith((ref) => summary ?? Future.value(_summary)),
        dashboardGlobalWalletProvider
            .overrideWith((ref) => wallet ?? Future.value(_walletBalances)),
        dashboardProjectsProvider
            .overrideWith((ref) => projects ?? Future.value([_project])),
        dashboardFinanceProvider
            .overrideWith((ref) => finance ?? Future.value(_timeline)),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: const DashboardScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar_SA', null);
    await initializeDateFormatting('en_US', null);
  });

  const sizes = <Size>[
    Size(320, 640),
    Size(390, 844),
    Size(600, 900),
    Size(800, 1280),
    Size(1440, 900),
  ];

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final size in sizes) {
      testWidgets(
          '${locale.languageCode} ${size.width.toInt()}x${size.height.toInt()} has no overflow',
          (tester) async {
        await _pumpDashboard(tester, size: size, locale: locale);
        expect(tester.takeException(), isNull);
        expect(find.text('YER'), findsWidgets);
        expect(find.text('-1,500'), findsWidgets);
        // The global wallet hero card must render its title.
        expect(
          find.byWidgetPredicate((widget) =>
              widget is Text &&
              (widget.data == 'Current cash balance' ||
                  widget.data == 'الرصيد النقدي الحالي')),
          findsOneWidget,
        );
      });
    }
  }

  testWidgets('empty Dashboard renders truthful unavailable state',
      (tester) async {
    await _pumpDashboard(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
      projects: Future.value([]),
      finance: Future.value([]),
    );
    expect(find.textContaining('Activity history is not currently available'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading state renders without framework exception',
      (tester) async {
    final pendingSummary = Completer<DashboardSummary>();
    final pendingProjects = Completer<List<DashboardProjectOverview>>();
    final pendingFinance = Completer<List<DashboardFinanceMonth>>();
    await _pumpDashboard(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
      summary: pendingSummary.future,
      projects: pendingProjects.future,
      finance: pendingFinance.future,
    );
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local error state renders without framework exception',
      (tester) async {
    final error = StateError('local read failed');
    final summaryError = Completer<DashboardSummary>();
    final projectsError = Completer<List<DashboardProjectOverview>>();
    final financeError = Completer<List<DashboardFinanceMonth>>();
    await _pumpDashboard(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
      summary: summaryError.future,
      projects: projectsError.future,
      finance: financeError.future,
    );
    summaryError.completeError(error);
    projectsError.completeError(error);
    financeError.completeError(error);
    await tester.pump();
    expect(find.textContaining('Unable to read local data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Raw localization keys / internal identifiers that must never be rendered
  // to the end user in any locale.
  const _forbiddenRawKeys = <String>[
    'project_overview',
    'monthly_performance',
    'revenue',
    'expenses',
    'profit',
    'payment',
    'expense',
    'reports',
    'status_active',
    'status_completed',
    'status_on_hold',
    'status_planning',
    'status_cancelled',
    'STATUS_ACTIVE',
    'STATUS_COMPLETED',
    'STATUS_PAUSED',
    'STATUS_PLANNING',
    'STATUS_CANCELLED',
  ];

  testWidgets('Arabic Dashboard exposes no raw localization keys or status tokens',
      (tester) async {
    await _pumpDashboard(
      tester,
      size: const Size(800, 1280),
      locale: const Locale('ar'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final raw in _forbiddenRawKeys) {
      expect(
        find.text(raw),
        findsNothing,
        reason: 'Raw key/token "$raw" must not be rendered in Arabic mode.',
      );
    }
    // Localized Arabic labels must be present.
    expect(find.text('الرصيد النقدي الحالي'), findsOneWidget);
    expect(find.text('نظرة عامة على المشاريع'), findsOneWidget);
    expect(find.text('الأداء الشهري'), findsOneWidget);
    expect(find.text('الإيرادات'), findsOneWidget);
    expect(find.text('المصروفات'), findsWidgets);
    expect(find.text('الربح'), findsOneWidget);
    expect(find.text('التقارير', skipOffstage: false), findsOneWidget);
    expect(find.text('دفعة جديدة', skipOffstage: false), findsOneWidget);
    expect(find.text('مصروف جديد', skipOffstage: false), findsOneWidget);
  });

  testWidgets('English Dashboard exposes no raw localization keys or status tokens',
      (tester) async {
    await _pumpDashboard(
      tester,
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final raw in _forbiddenRawKeys) {
      expect(
        find.text(raw),
        findsNothing,
        reason: 'Raw key/token "$raw" must not be rendered in English mode.',
      );
    }
    // Localized English labels must be present.
    expect(find.text('Current cash balance'), findsOneWidget);
    expect(find.text('Project Overview'), findsOneWidget);
    expect(find.text('Monthly Performance'), findsOneWidget);
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('Expenses'), findsWidgets);
    expect(find.text('Profit'), findsOneWidget);
    expect(find.text('Reports', skipOffstage: false), findsOneWidget);
    expect(find.text('New Payment', skipOffstage: false), findsOneWidget);
    expect(find.text('New Expense', skipOffstage: false), findsOneWidget);
  });
}
