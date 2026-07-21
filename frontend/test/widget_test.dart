import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:construction_erp/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar_SA', null);
  });

  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ConstructionErpApp()));
    // Allow async providers to settle.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Welcome Back'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}