import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:construction_erp/core/localization/app_localizations.dart';
import 'package:construction_erp/features/dashboard/domain/dashboard_models.dart';
import 'package:construction_erp/features/dashboard/presentation/dashboard_providers.dart';
import 'package:construction_erp/features/dashboard/presentation/dashboard_screen.dart';

class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(Locale locale) {
    state = locale;
  }
}

const _summary = DashboardSummary(
  activeClientCount: 2,
  activeProjectCount: 1,
  completedProjectCount: 1,
  totalPaymentsYer: 1000,
  totalExpensesYer: 2500,
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
        dashboardProjectsProvider
            .overrideWith((ref) => projects ?? Future.value([_project])),
        dashboardFinanceProvider
            .overrideWith((ref) => finance ?? Future.value(_timeline)),
      ],
      child: MaterialApp(
        locale: locale,
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
        expect(
          find.byWidgetPredicate((widget) =>
              widget is Text &&
              (widget.data == 'Net cash flow' ||
                  widget.data == 'صافي التدفق النقدي')),
          findsWidgets,
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
}
