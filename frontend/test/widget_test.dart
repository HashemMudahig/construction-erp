import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ConstructionErpApp());
    // Allow async providers to settle.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Construction ERP'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}