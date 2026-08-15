import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_erp/core/localization/app_localizations.dart';
import 'package:construction_erp/features/transfers/presentation/insufficient_balance_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required Locale locale,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showInsufficientBalanceDialog(
                  context,
                  currency: 'YER',
                  currentBalanceMinor: 100000,
                  expenseAmountMinor: 200000,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('InsufficientBalanceDialog (Arabic)', () {
    testWidgets('shows Arabic warning text, balances, and three options',
        (tester) async {
      await pumpDialog(tester, locale: const Locale('ar'));

      // Title and body in Arabic.
      expect(find.text('تنبيه مالي'), findsOneWidget);
      expect(find.text('لا يوجد رصيد كافي بهذه العملة.'), findsOneWidget);
      // Labels.
      expect(find.text('الرصيد الحالي'), findsOneWidget);
      expect(find.text('قيمة المصروف'), findsOneWidget);
      expect(find.text('العجز'), findsOneWidget);
      // Values (YER scale 0). Balance and deficit are both 100,000 YER.
      expect(find.text('200,000 YER'), findsOneWidget); // expense
      expect(find.text('100,000 YER'), findsNWidgets(2)); // balance + deficit
      // Three options in Arabic.
      expect(find.text('تحويل عملة'), findsOneWidget);
      expect(find.text('تمويل خارجي'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    });

    testWidgets('tapping إلغاء returns cancel', (tester) async {
      await pumpDialog(tester, locale: const Locale('ar'));
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping تحويل عملة returns convertCurrency', (tester) async {
      await pumpDialog(tester, locale: const Locale('ar'));
      await tester.tap(find.text('تحويل عملة'));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping تمويل خارجي returns externalFunding', (tester) async {
      await pumpDialog(tester, locale: const Locale('ar'));
      await tester.tap(find.text('تمويل خارجي'));
      await tester.pumpAndSettle();
    });
  });

  group('InsufficientBalanceDialog (English)', () {
    testWidgets('shows English labels when locale is en', (tester) async {
      await pumpDialog(tester, locale: const Locale('en'));
      expect(find.text('Insufficient balance'), findsOneWidget);
      expect(find.text('Convert currency'), findsOneWidget);
      expect(find.text('External funding'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}