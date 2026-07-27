import 'dart:async';

import 'package:construction_erp/features/backup/domain/backup_manifest.dart';
import 'package:construction_erp/features/backup/domain/backup_models.dart';
import 'package:construction_erp/features/backup/domain/backup_repository_interface.dart';
import 'package:construction_erp/features/backup/presentation/backup_restore_provider.dart';
import 'package:construction_erp/features/backup/presentation/backup_restore_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final size in const [
      Size(320, 640),
      Size(390, 844),
      Size(600, 900),
      Size(800, 1280),
      Size(1440, 900),
    ]) {
      testWidgets(
          '${locale.languageCode} ${size.width}x${size.height} no overflow',
          (tester) async {
        await _pump(
          tester,
          locale: locale,
          size: size,
          repository: _FakeRepository(),
          selector: const _FakeSelector(),
        );
        expect(tester.takeException(), isNull);
        expect(
            find.textContaining(
                locale.languageCode == 'ar' ? 'غير مشفرة' : 'not encrypted'),
            findsOneWidget);
      });
    }
  }

  testWidgets('restore validation renders preview and replacement warning',
      (tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      size: const Size(390, 844),
      repository: _FakeRepository(),
      selector: const _FakeSelector(source: 'valid.cerpbackup'),
    );
    await tester.tap(find.text('Select backup'));
    await tester.pumpAndSettle();
    expect(find.text('Backup preview'), findsOneWidget);
    expect(
        find.textContaining('replace all current local data'), findsOneWidget);
    expect(find.textContaining('Clients: 1'), findsOneWidget);
    expect(find.text('Replace local data'), findsOneWidget);
  });

  testWidgets('restore requires explicit confirmation', (tester) async {
    final repository = _FakeRepository();
    await _pump(
      tester,
      locale: const Locale('en'),
      size: const Size(600, 900),
      repository: repository,
      selector: const _FakeSelector(source: 'valid.cerpbackup'),
    );
    await tester.tap(find.text('Select backup'));
    await tester.pumpAndSettle();
    expect(repository.restoreCalls, 0);
    await tester.tap(find.text('Replace local data'));
    await tester.pumpAndSettle();
    expect(repository.restoreCalls, 1);
    expect(find.text('Restore completed successfully.'), findsOneWidget);
  });

  testWidgets('file selection cancellation returns to idle', (tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      size: const Size(390, 844),
      repository: _FakeRepository(),
      selector: const _FakeSelector(),
    );
    await tester.tap(find.text('Create backup'));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Create backup'), findsOneWidget);
  });

  testWidgets('buttons disable while backup is running', (tester) async {
    final completer = Completer<BackupOperationResult>();
    await _pump(
      tester,
      locale: const Locale('en'),
      size: const Size(390, 844),
      repository: _FakeRepository(createFuture: completer.future),
      selector: const _FakeSelector(destination: 'backup.cerpbackup'),
    );
    await tester.tap(find.text('Create backup'));
    await tester.pump();
    expect(find.text('Creating backup…'), findsOneWidget);
    final createButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create backup'));
    final restoreButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Select backup'));
    expect(createButton.onPressed, isNull);
    expect(restoreButton.onPressed, isNull);
    completer.complete(BackupOperationResult(
      displayPath: 'backup.cerpbackup',
      manifest: _manifest,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Backup created successfully.'), findsOneWidget);
  });

  testWidgets('long local error wraps without network wording', (tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      size: const Size(320, 640),
      repository: _FakeRepository(
          createError: StateError(
              'A long local file validation error that must wrap safely.')),
      selector: const _FakeSelector(destination: 'backup.cerpbackup'),
    );
    await tester.tap(find.text('Create backup'));
    await tester.pumpAndSettle();
    expect(find.textContaining('local file validation'), findsOneWidget);
    expect(find.textContaining('HTTP'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final _manifest = BackupManifest(
  backupFormatVersion: kBackupFormatVersion,
  applicationId: kBackupApplicationId,
  createdAtUtc: DateTime.utc(2026, 7, 26, 11, 30),
  databaseEntryName: kBackupDatabaseEntryName,
  databaseSchemaVersion: 4,
  databaseSizeBytes: 100,
  databaseSha256: 'a' * 64,
  recordCounts: const BackupRecordCounts(
    clients: 1,
    projects: 2,
    milestones: 3,
    payments: 4,
    expenses: 5,
    appSettings: 1,
  ),
);

class _FakeRepository implements BackupRepositoryInterface {
  _FakeRepository({this.createFuture, this.createError});

  final Future<BackupOperationResult>? createFuture;
  final Object? createError;
  int restoreCalls = 0;

  @override
  Future<BackupOperationResult> createBackup(String destinationPath) async {
    if (createError != null) throw createError!;
    return createFuture ??
        BackupOperationResult(
          displayPath: destinationPath,
          manifest: _manifest,
        );
  }

  @override
  Future<BackupPreview> inspectBackup(String sourcePath) async => BackupPreview(
        validationToken: 'validated',
        displayName: sourcePath,
        manifest: _manifest,
        isMigrationRequired: false,
      );

  @override
  Future<BackupOperationResult> restoreBackup(BackupPreview preview) async {
    restoreCalls++;
    return BackupOperationResult(
      displayPath: preview.displayName,
      manifest: preview.manifest,
    );
  }

  @override
  Future<void> cancelPendingRestore() async {}

  @override
  Future<void> cleanTemporaryFiles() async {}
}

class _FakeSelector implements BackupFileSelectionService {
  const _FakeSelector({this.destination, this.source});

  final String? destination;
  final String? source;

  @override
  Future<String?> selectBackupDestination(String suggestedName) async =>
      destination;

  @override
  Future<String?> selectBackupSource() async => source;
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required Size size,
  required BackupRepositoryInterface repository,
  required BackupFileSelectionService selector,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backupRepositoryProvider.overrideWithValue(repository),
        backupFileSelectionProvider.overrideWithValue(selector),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: BackupRestoreSection(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
