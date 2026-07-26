import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_provider.dart';
import 'package:construction_erp/features/reports/presentation/report_providers.dart';
import 'package:construction_erp/features/reports/presentation/reports_screen.dart';

const _projectReport = ProjectStatusReport([
  ProjectStatusReportRow(
    projectId: 'bbbbbbbb-0000-4000-8000-000000000001',
    name: 'A very long construction project name that must remain responsive',
    status: 'active',
    budgetAmountMinor: 12345,
    budgetCurrency: 'SAR',
    totalPaymentsYer: 1000,
    totalExpensesYer: 2500,
    milestoneCount: 2,
    completedMilestones: 1,
  ),
]);

Future<void> _pumpReports(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
  Future<ReportResult>? result,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        reportResultProvider.overrideWith(
          (ref, filters) => result ?? Future.value(_projectReport),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: const ReportsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const sizes = [
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
          await _pumpReports(tester, size: size, locale: locale);
          await tester.tap(find.byType(FilledButton).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('SAR'), findsOneWidget);
          expect(
            find.textContaining(
              locale.languageCode == 'ar'
                  ? 'صافي التدفق النقدي'
                  : 'Net cash flow',
            ),
            findsOneWidget,
          );
        },
      );
    }
  }

  testWidgets('loading state renders locally', (tester) async {
    final completer = Completer<ReportResult>();
    await _pumpReports(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
      result: completer.future,
    );
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty state renders', (tester) async {
    await _pumpReports(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
      result: Future.value(const ProjectStatusReport([])),
    );
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    expect(find.text('No data for the selected filters.'), findsOneWidget);
  });

  testWidgets('local error and retry render without network wording',
      (tester) async {
    final completer = Completer<ReportResult>();
    await _pumpReports(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
      result: completer.future,
    );
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    completer.completeError(StateError('Local report query failed'));
    await tester.pump();
    expect(find.textContaining('Local report query failed'), findsOneWidget);
    expect(find.textContaining('HTTP'), findsNothing);
  });
}
