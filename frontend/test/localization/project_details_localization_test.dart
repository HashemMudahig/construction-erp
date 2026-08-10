import 'package:construction_erp/core/localization/app_localizations.dart';
import 'package:construction_erp/core/localization/localized_business_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('expense categories localize without changing canonical values',
      (tester) async {
    await _pump(
      tester,
      locale: const Locale('ar'),
      child: Builder(
        builder: (context) => Column(
          children:
              const ['materials', 'labor', 'equipment', 'permits', 'other']
                  .map((value) => Text(
                        '$value:${localizedExpenseCategory(context, value)}',
                      ))
                  .toList(),
        ),
      ),
    );
    expect(find.text('materials:مواد'), findsOneWidget);
    expect(find.text('labor:أجور العمال'), findsOneWidget);
    expect(find.text('equipment:معدات'), findsOneWidget);
    expect(find.text('permits:تصاريح'), findsOneWidget);
    expect(find.text('other:أخرى'), findsOneWidget);
  });

  testWidgets('English category and payment labels remain English',
      (tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      child: Builder(
        builder: (context) => Column(
          children: [
            Text(localizedExpenseCategory(context, 'materials')),
            Text(localizedExpenseCategory(context, 'labor')),
            Text(localizedPaymentMethod(context, 'bank_transfer')),
            Text(localizedMilestoneStatus(context, 'in_progress')),
          ],
        ),
      ),
    );
    expect(find.text('Materials'), findsOneWidget);
    expect(find.text('Labor'), findsOneWidget);
    expect(find.text('Bank transfer'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });

  test('financial terminology has matching Arabic and English keys', () {
    final en = AppLocalizations(const Locale('en'));
    final ar = AppLocalizations(const Locale('ar'));
    expect(en.translate('financial_summary_tab'), 'Financial summary');
    expect(ar.translate('financial_summary_tab'), 'الملخص المالي');
    expect(en.translate('cash_deficit'), 'Cash deficit');
    expect(ar.translate('cash_deficit'), 'عجز نقدي');
    expect(en.translate('cost_overrun'), 'Project cost overrun');
    expect(ar.translate('cost_overrun'), 'تجاوز في تكلفة المشروع');
    expect(en.translate('welcome_engineer'), 'Eng. Omar Badhman');
    expect(ar.translate('welcome_engineer'), 'م. عمر بادحمان');
  });
}
