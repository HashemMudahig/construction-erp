import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup recovery runs before ProviderScope exposes repositories', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(
      main.indexOf('DatabaseStartupRecoveryService().recover'),
      lessThan(main.indexOf('runApp(')),
    );
  });

  test('release manifest has no network or broad storage permission', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final permission in const [
      'android.permission.INTERNET',
      'android.permission.ACCESS_NETWORK_STATE',
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.MANAGE_EXTERNAL_STORAGE',
    ]) {
      expect(manifest, isNot(contains(permission)));
    }
  });

  test('debug manifest owns the tooling-only Internet permission', () {
    final manifest =
        File('android/app/src/debug/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.INTERNET'));
  });

  test('schema and stable application metadata are explicit', () {
    final constants =
        File('lib/core/database/database_constants.dart').readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(constants, contains('kSchemaVersion = 5'));
    expect(gradle, contains('applicationId = "com.example.construction_erp"'));
    expect(pubspec, contains('version: 1.0.0+1'));
  });

  test('no production signing secret is committed', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, isNot(contains('storePassword')));
    expect(gradle, isNot(contains('keyPassword')));
    expect(gradle, contains('signingConfigs.getByName("debug")'));
  });
}
