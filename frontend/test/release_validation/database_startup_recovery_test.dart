import 'dart:io';

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_startup_recovery_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<File> _validDatabase(Directory directory, String name) async {
  final file = File(p.join(directory.path, name));
  final database = AppDatabase(NativeDatabase(file));
  await database.customSelect('SELECT COUNT(*) FROM clients').getSingle();
  await database.close();
  return file;
}

void main() {
  late Directory directory;
  late File canonical;
  const service = DatabaseStartupRecoveryService();

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cerp_recovery_');
    canonical = File(p.join(directory.path, 'construction_erp.db'));
  });

  tearDown(() => directory.delete(recursive: true));

  test('clean install leaves canonical creation to normal database startup',
      () async {
    final result = await service.recover(canonical);
    expect(result.kind, DatabaseStartupRecoveryKind.noRecoveryNeeded);
    expect(await canonical.exists(), isFalse);
  });

  test('valid canonical is retained and recovery is idempotent', () async {
    await _validDatabase(directory, 'construction_erp.db');
    final originalLength = await canonical.length();
    expect(
      (await service.recover(canonical)).kind,
      DatabaseStartupRecoveryKind.noRecoveryNeeded,
    );
    expect(await canonical.length(), originalLength);
    expect(
      (await service.recover(canonical)).kind,
      DatabaseStartupRecoveryKind.noRecoveryNeeded,
    );
  });

  test('valid canonical cleans stale incoming only after validation', () async {
    await _validDatabase(directory, 'construction_erp.db');
    final incoming = await _validDatabase(
      directory,
      'construction_erp.db.incoming',
    );
    expect(
      (await service.recover(canonical)).kind,
      DatabaseStartupRecoveryKind.staleIncomingCleaned,
    );
    expect(await canonical.exists(), isTrue);
    expect(await incoming.exists(), isFalse);
  });

  test('valid canonical cleans stale rollback only after validation', () async {
    await _validDatabase(directory, 'construction_erp.db');
    final rollback = await _validDatabase(
      directory,
      'construction_erp.db.pre_restore',
    );
    expect(
      (await service.recover(canonical)).kind,
      DatabaseStartupRecoveryKind.staleRollbackCleaned,
    );
    expect(await canonical.exists(), isTrue);
    expect(await rollback.exists(), isFalse);
  });

  test('missing canonical restores valid rollback', () async {
    await _validDatabase(directory, 'construction_erp.db.pre_restore');
    expect(
      (await service.recover(canonical)).kind,
      DatabaseStartupRecoveryKind.rollbackRestored,
    );
    expect(await canonical.exists(), isTrue);
  });

  test('corrupt canonical is quarantined before rollback restoration',
      () async {
    await canonical.writeAsString('not sqlite');
    await _validDatabase(directory, 'construction_erp.db.pre_restore');
    expect(
      (await service.recover(canonical)).kind,
      DatabaseStartupRecoveryKind.rollbackRestored,
    );
    expect(await canonical.exists(), isTrue);
    expect(
      directory.listSync().where(
            (entry) => p.basename(entry.path).startsWith(
                  'construction_erp.db.corrupt_',
                ),
          ),
      hasLength(1),
    );
  });

  test('valid incoming is promoted only when no valid rollback exists',
      () async {
    await _validDatabase(directory, 'construction_erp.db.incoming');
    expect(
      (await service.recover(canonical)).kind,
      DatabaseStartupRecoveryKind.incomingPromoted,
    );
    expect(await canonical.exists(), isTrue);
  });

  test('invalid candidates remain available on controlled failure', () async {
    final rollback = File('${canonical.path}.pre_restore');
    await canonical.writeAsString('corrupt canonical');
    await rollback.writeAsString('corrupt rollback');
    await expectLater(
      service.recover(canonical),
      throwsA(isA<DatabaseStartupRecoveryException>()),
    );
    expect(await canonical.exists(), isTrue);
    expect(await rollback.exists(), isTrue);
  });
}
