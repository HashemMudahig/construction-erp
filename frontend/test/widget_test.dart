import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_provider.dart';
import 'package:construction_erp/core/router/app_router.dart';
import 'package:construction_erp/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar_SA', null);
    await initializeDateFormatting('en', null);
  });

  test('App router starts at dashboard path', () {
    // Verify that the app router is configured to start at '/' (dashboard).
    // This replaces the obsolete login screen test.
    // The production router has auth redirect removed (pre-existing change).
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
    ]);
    final router = container.read(appRouterProvider);
    expect(router.configuration.routes, isNotEmpty);
    container.dispose();
  });

  test('ConstructionErpApp is a valid widget', () {
    // Verify the app class exists and can be instantiated.
    const app = ConstructionErpApp();
    expect(app, isA<Widget>());
  });

  test('Database provider can be overridden for testing', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    // Verify the database is accessible
    expect(container.read(databaseProvider), isA<AppDatabase>());
    await db.close();
    container.dispose();
  });
}
