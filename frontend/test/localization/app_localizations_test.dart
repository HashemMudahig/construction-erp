import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_erp/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations Tests', () {
    testWidgets('Translates to English correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              return Text(context.tr('app_title'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Construction ERP'), findsOneWidget);
    });

    testWidgets('Translates to Arabic correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: Builder(
            builder: (context) {
              return Text(context.tr('app_title'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('نظام إدارة المقاولات'), findsOneWidget);
    });

    testWidgets('Falls back to key if translation is missing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              return Text(context.tr('missing_key_123'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('missing_key_123'), findsOneWidget);
    });
  });
}
