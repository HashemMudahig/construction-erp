import 'dart:io';

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/features/clients/data/local_client_repository.dart';
import 'package:construction_erp/features/dashboard/data/local_dashboard_repository.dart';
import 'package:construction_erp/features/expenses/data/local_expense_repository.dart';
import 'package:construction_erp/features/milestones/data/local_milestone_repository.dart';
import 'package:construction_erp/features/payments/data/local_payment_repository.dart';
import 'package:construction_erp/features/projects/data/local_project_repository.dart';
import 'package:construction_erp/features/reports/data/local_reports_repository.dart';
import 'package:construction_erp/features/settings/data/local_settings_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current;
  final lib = Directory('${root.path}${Platform.pathSeparator}lib');

  test('production Dart sources contain no network client import or URL', () {
    final violations = <String>[];
    for (final file in _dartFiles(lib)) {
      final source = file.readAsStringSync();
      for (final forbidden in const [
        'package:dio/',
        'dart:io\' show HttpClient',
        'HttpClient(',
        'WebSocket',
        'InternetAddress',
        'Authorization',
        'Bearer ',
        'http://',
        'https://',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${file.path}: $forbidden');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('production contains no auth, endpoint, or remote repository files', () {
    for (final path in const [
      'lib/core/network/dio_provider.dart',
      'lib/core/constants/endpoints.dart',
      'lib/core/config/app_config.dart',
      'lib/features/clients/data/api_client_repository.dart',
      'lib/features/projects/data/api_project_repository.dart',
      'lib/features/milestones/data/api_milestone_repository.dart',
      'lib/features/payments/data/api_payment_repository.dart',
      'lib/features/expenses/data/api_expense_repository.dart',
      'lib/features/dashboard/data/api_dashboard_repository.dart',
      'lib/features/reports/data/api_reports_repository.dart',
    ]) {
      expect(FileSystemEntity.typeSync('${root.path}/$path'),
          FileSystemEntityType.notFound,
          reason: path);
    }
    expect(_dartFiles(Directory('${root.path}/lib/features/auth')), isEmpty);
  });

  test('pubspec excludes network and token-storage dependencies', () {
    final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains(RegExp(r'^\s+dio:', multiLine: true))));
    expect(pubspec,
        isNot(contains(RegExp(r'^\s+shared_preferences:', multiLine: true))));
    expect(pubspec, isNot(contains('flutter_secure_storage')));
  });

  test('required local and backup dependencies remain', () {
    final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
    for (final dependency in const [
      'drift:',
      'sqlite3_flutter_libs:',
      'path_provider:',
      'archive:',
      'crypto:',
      'file_selector:',
    ]) {
      expect(pubspec, contains(dependency));
    }
  });

  test('router starts at Dashboard and has no login route or redirect', () {
    final router =
        File('${root.path}/lib/core/router/app_router.dart').readAsStringSync();
    expect(router, contains("initialLocation: '/'"));
    expect(router, contains('const DashboardScreen()'));
    expect(router, isNot(contains('/login')));
    expect(router, isNot(contains('redirect:')));
  });

  test('AppShell contains no session, logout, or auth provider', () {
    final shell =
        File('${root.path}/lib/core/router/app_shell.dart').readAsStringSync();
    expect(shell, isNot(contains('authSessionProvider')));
    expect(shell.toLowerCase(), isNot(contains('logout')));
    expect(shell.toLowerCase(), isNot(contains('local user')));
    expect(shell.toLowerCase(), isNot(contains('no login required')));
  });

  test('business feature data directories contain local implementations only',
      () {
    expect(LocalClientRepository, isNotNull);
    expect(LocalProjectRepository, isNotNull);
    expect(LocalMilestoneRepository, isNotNull);
    expect(LocalPaymentRepository, isNotNull);
    expect(LocalExpenseRepository, isNotNull);
    expect(LocalDashboardRepository, isNotNull);
    expect(LocalReportsRepository, isNotNull);
    expect(LocalSettingsRepository, isNotNull);
    final remoteNames = _dartFiles(lib)
        .where((file) =>
            file.path.contains('api_') ||
            file.path.endsWith('_repository.dart') &&
                !file.path.contains('local_') &&
                !file.path.contains('repository_interface'))
        .map((file) => file.path)
        .toList();
    expect(remoteNames, isEmpty);
  });

  test('production AppSettings contract contains no credential field', () {
    final sources = [
      File('${root.path}/lib/core/database/tables/app_settings_table.dart'),
      File('${root.path}/lib/features/settings/domain/app_settings.dart'),
    ].map((file) => file.readAsStringSync().toLowerCase()).join();
    for (final secret in const ['password', 'jwt', 'token', 'secret']) {
      expect(sources, isNot(contains(secret)));
    }
  });

  test('backup production path has no network or credential dependency', () {
    final source = _dartFiles(Directory('${root.path}/lib/features/backup'))
        .map((file) => file.readAsStringSync())
        .join();
    expect(source, isNot(contains('package:dio')));
    expect(source, isNot(contains('SharedPreferences')));
    expect(source, isNot(contains('Authorization')));
    expect(source, contains('VACUUM INTO'));
    expect(source, contains('databaseSha256'));
  });

  test('database remains schema version 4 and opens offline', () async {
    final database = AppDatabase(NativeDatabase.memory());
    expect(kSchemaVersion, 4);
    expect(database.schemaVersion, 4);
    expect(await database.customSelect('SELECT 1 AS value').getSingle(),
        isNotNull);
    await database.close();
  });
}

Iterable<File> _dartFiles(Directory directory) sync* {
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}
