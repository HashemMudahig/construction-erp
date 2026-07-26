import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/uuid/uuid_util.dart';
import 'package:construction_erp/features/clients/data/client_mapper.dart';
import 'package:construction_erp/features/clients/data/local_client_repository.dart';
import 'package:construction_erp/features/clients/domain/client_repository_interface.dart';

const _clientIdA = 'aaaaaaaa-0000-4000-8000-000000000001';
const _clientIdB = 'aaaaaaaa-0000-4000-8000-000000000002';
const _clientIdArchived = 'aaaaaaaa-0000-4000-8000-000000000003';
const _projectId = 'bbbbbbbb-0000-4000-8000-000000000001';
const _ts = '2026-01-15T10:00:00Z';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

LocalClientRepository _repo(AppDatabase db) =>
    LocalClientRepository(db.clientsDao);

Future<void> _seedClient(
  AppDatabase db, {
  required String id,
  required String name,
  bool archived = false,
  String? phone,
  String? email,
}) async {
  await db.into(db.clients).insert(ClientsCompanion.insert(
        id: id,
        name: name,
        phone: phone != null ? Value(phone) : const Value.absent(),
        email: email != null ? Value(email) : const Value.absent(),
        archived: Value(archived),
        createdAt: _ts,
        updatedAt: _ts,
      ));
}

void main() {
  // ===========================================================================
  // UUID utility
  // ===========================================================================
  group('UuidUtil', () {
    test('Generated local ID is valid UUID', () {
      final id = UuidUtil.generate();
      expect(UuidUtil.isValid(id), true);
    });

    test('Existing valid backend UUID is accepted', () {
      expect(UuidUtil.isValid(_clientIdA), true);
    });

    test('Invalid UUID is rejected', () {
      expect(UuidUtil.isValid('not-a-uuid'), false);
      expect(() => UuidUtil.validate('bad'), throwsArgumentError);
    });

    test('Short string is rejected', () {
      expect(UuidUtil.isValid('short'), false);
    });

    test('Duplicate UUID is rejected by database', () async {
      final db = _createDb();
      await _seedClient(db, id: _clientIdA, name: 'First');
      expect(
        () => db.into(db.clients).insert(ClientsCompanion.insert(
            id: _clientIdA, name: 'Duplicate', createdAt: _ts, updatedAt: _ts)),
        throwsA(isA<Object>()),
      );
      await db.close();
    });
  });

  // ===========================================================================
  // Repository and mapping
  // ===========================================================================
  group('LocalClientRepository', () {
    test('Create client', () async {
      final db = _createDb();
      final repo = _repo(db);
      final client =
          await repo.create(name: 'Test Client', phone: '+966500000001');
      expect(client.name, 'Test Client');
      expect(client.phone, '+966500000001');
      expect(client.archived, false);
      expect(UuidUtil.isValid(client.id), true);
      await db.close();
    });

    test('Get client by ID', () async {
      final db = _createDb();
      final repo = _repo(db);
      final created = await repo.create(name: 'Find Me');
      final found = await repo.getById(created.id);
      expect(found, isNotNull);
      expect(found!.name, 'Find Me');
      await db.close();
    });

    test('Get by ID returns null for non-existent', () async {
      final db = _createDb();
      final repo = _repo(db);
      final found = await repo.getById(_clientIdA);
      expect(found, isNull);
      await db.close();
    });

    test('List active clients', () async {
      final db = _createDb();
      final repo = _repo(db);
      await _seedClient(db, id: _clientIdA, name: 'Active Client');
      await _seedClient(db,
          id: _clientIdArchived, name: 'Archived Client', archived: true);
      final active = await repo.list();
      expect(active.length, 1);
      expect(active.first.name, 'Active Client');
      await db.close();
    });

    test('List includes archived when requested', () async {
      final db = _createDb();
      final repo = _repo(db);
      await _seedClient(db, id: _clientIdA, name: 'Active Client');
      await _seedClient(db,
          id: _clientIdArchived, name: 'Archived Client', archived: true);
      final all = await repo.list(includeArchived: true);
      expect(all.length, 2);
      await db.close();
    });

    test('Update client', () async {
      final db = _createDb();
      final repo = _repo(db);
      final created = await repo.create(name: 'Original');
      final updated = await repo.update(id: created.id, name: 'Updated');
      expect(updated.name, 'Updated');
      await db.close();
    });

    test('Archive client', () async {
      final db = _createDb();
      final repo = _repo(db);
      final created = await repo.create(name: 'To Archive');
      await repo.archive(created.id);
      final archived = await repo.getById(created.id);
      expect(archived!.archived, true);
      // Archived client should not appear in default active list
      final active = await repo.list();
      expect(active.where((c) => c.id == created.id), isEmpty);
      await db.close();
    });

    test('Archived client disappears from default active list', () async {
      final db = _createDb();
      final repo = _repo(db);
      final created = await repo.create(name: 'Will Archive');
      expect((await repo.list()).length, 1);
      await repo.archive(created.id);
      expect((await repo.list()).length, 0);
      await db.close();
    });

    test('Archived client appears when includeArchived is enabled', () async {
      final db = _createDb();
      final repo = _repo(db);
      final created = await repo.create(name: 'Will Archive');
      await repo.archive(created.id);
      final all = await repo.list(includeArchived: true);
      expect(all.where((c) => c.id == created.id).length, 1);
      await db.close();
    });

    test('Restore archived client', () async {
      final db = _createDb();
      final repo = _repo(db);
      final created = await repo.create(name: 'Archive Then Restore');
      await repo.archive(created.id);
      await repo.restore(created.id);
      final restored = await repo.getById(created.id);
      expect(restored!.archived, false);
      final active = await repo.list();
      expect(active.where((c) => c.id == created.id).length, 1);
      await db.close();
    });

    test('Hard-delete client with no Projects', () async {
      final db = _createDb();
      final repo = _repo(db);
      final created = await repo.create(name: 'Delete Me');
      await repo.deleteIfEligible(created.id);
      final found = await repo.getById(created.id);
      expect(found, isNull);
      await db.close();
    });

    test('Hard-delete client with Projects is rejected', () async {
      final db = _createDb();
      final repo = _repo(db);
      final created = await repo.create(name: 'Has Projects');
      // Insert a project linked to this client
      await db.into(db.projects).insert(ProjectsCompanion.insert(
          id: _projectId,
          clientId: created.id,
          name: 'Test Project',
          budgetAmountMinor: 100000,
          budgetCurrency: kCurrencyYer,
          createdAt: _ts));
      expect(
        () => repo.deleteIfEligible(created.id),
        throwsA(isA<StateError>()),
      );
      await db.close();
    });

    test('hasProjects returns true when projects exist', () async {
      final db = _createDb();
      final repo = _repo(db);
      final created = await repo.create(name: 'Has Projects');
      await db.into(db.projects).insert(ProjectsCompanion.insert(
          id: _projectId,
          clientId: created.id,
          name: 'Project',
          budgetAmountMinor: 100000,
          budgetCurrency: kCurrencyYer,
          createdAt: _ts));
      expect(await repo.hasProjects(created.id), true);
      await db.close();
    });

    test('hasProjects returns false when no projects', () async {
      final db = _createDb();
      final repo = _repo(db);
      final created = await repo.create(name: 'No Projects');
      expect(await repo.hasProjects(created.id), false);
      await db.close();
    });

    test('Blank name is rejected', () async {
      final db = _createDb();
      final repo = _repo(db);
      expect(() => repo.create(name: '  '), throwsArgumentError);
      await db.close();
    });

    test('Invalid UUID in getById is rejected', () async {
      final db = _createDb();
      final repo = _repo(db);
      expect(() => repo.getById('bad-uuid'), throwsArgumentError);
      await db.close();
    });

    test('Update non-existent client throws', () async {
      final db = _createDb();
      final repo = _repo(db);
      expect(
        () => repo.update(id: _clientIdA, name: 'New'),
        throwsArgumentError,
      );
      await db.close();
    });
  });

  // ===========================================================================
  // Mapping
  // ===========================================================================
  group('ClientMapper', () {
    test('Row maps exactly to entity', () async {
      final db = _createDb();
      await db.into(db.clients).insert(ClientsCompanion.insert(
          id: _clientIdA,
          name: 'Test',
          phone: const Value('+123'),
          email: const Value('test@test.com'),
          createdAt: _ts,
          updatedAt: _ts));
      final row = await db.clientsDao.getClientById(_clientIdA);
      final entity = ClientMapper.rowToEntity(row!);
      expect(entity.id, _clientIdA);
      expect(entity.name, 'Test');
      expect(entity.phone, '+123');
      expect(entity.email, 'test@test.com');
      expect(entity.archived, false);
      expect(entity.createdAt, DateTime.parse(_ts));
      expect(entity.updatedAt, DateTime.parse(_ts));
      await db.close();
    });

    test('Nullable fields round-trip', () async {
      final db = _createDb();
      await db.into(db.clients).insert(ClientsCompanion.insert(
          id: _clientIdA, name: 'Test', createdAt: _ts, updatedAt: _ts));
      final row = await db.clientsDao.getClientById(_clientIdA);
      final entity = ClientMapper.rowToEntity(row!);
      expect(entity.phone, isNull);
      expect(entity.email, isNull);
      expect(entity.address, isNull);
      expect(entity.notes, isNull);
      await db.close();
    });

    test('Archived state round-trips', () async {
      final db = _createDb();
      await db.into(db.clients).insert(ClientsCompanion.insert(
          id: _clientIdA,
          name: 'Archived',
          archived: const Value(true),
          createdAt: _ts,
          updatedAt: _ts));
      final row = await db.clientsDao.getClientById(_clientIdA);
      final entity = ClientMapper.rowToEntity(row!);
      expect(entity.archived, true);
      await db.close();
    });
  });

  // ===========================================================================
  // Search
  // ===========================================================================
  group('search', () {
    test('Search by name', () async {
      final db = _createDb();
      final repo = _repo(db);
      await _seedClient(db, id: _clientIdA, name: 'Alpha Construction');
      await _seedClient(db, id: _clientIdB, name: 'Beta Builders');
      final results = await repo.list(search: 'Alpha');
      expect(results.length, 1);
      expect(results.first.name, 'Alpha Construction');
      await db.close();
    });

    test('Search by phone', () async {
      final db = _createDb();
      final repo = _repo(db);
      await _seedClient(db,
          id: _clientIdA, name: 'Client A', phone: '+966500000001');
      await _seedClient(db,
          id: _clientIdB, name: 'Client B', phone: '+966500000002');
      final results = await repo.list(search: '500000001');
      expect(results.length, 1);
      expect(results.first.name, 'Client A');
      await db.close();
    });

    test('Search by email', () async {
      final db = _createDb();
      final repo = _repo(db);
      await _seedClient(db,
          id: _clientIdA, name: 'Client A', email: 'alpha@test.com');
      await _seedClient(db,
          id: _clientIdB, name: 'Client B', email: 'beta@test.com');
      final results = await repo.list(search: 'alpha@test.com');
      expect(results.length, 1);
      expect(results.first.name, 'Client A');
      await db.close();
    });

    test('Search excludes archived by default', () async {
      final db = _createDb();
      final repo = _repo(db);
      await _seedClient(db, id: _clientIdA, name: 'Active Match');
      await _seedClient(db,
          id: _clientIdArchived, name: 'Archived Match', archived: true);
      final results = await repo.list(search: 'Match');
      expect(results.length, 1);
      expect(results.first.name, 'Active Match');
      await db.close();
    });

    test('Search includes archived when requested', () async {
      final db = _createDb();
      final repo = _repo(db);
      await _seedClient(db, id: _clientIdA, name: 'Active Match');
      await _seedClient(db,
          id: _clientIdArchived, name: 'Archived Match', archived: true);
      final results = await repo.list(search: 'Match', includeArchived: true);
      expect(results.length, 2);
      await db.close();
    });

    test('Empty search returns active list', () async {
      final db = _createDb();
      final repo = _repo(db);
      await _seedClient(db, id: _clientIdA, name: 'Client A');
      await _seedClient(db, id: _clientIdB, name: 'Client B');
      await _seedClient(db,
          id: _clientIdArchived, name: 'Archived', archived: true);
      final results = await repo.list(search: '');
      expect(results.length, 2); // Only active
      await db.close();
    });

    test('Search is case-insensitive', () async {
      final db = _createDb();
      final repo = _repo(db);
      await _seedClient(db, id: _clientIdA, name: 'Alpha Construction');
      final results = await repo.list(search: 'alpha');
      expect(results.length, 1);
      await db.close();
    });
  });

  // ===========================================================================
  // Persistence after reopen
  // ===========================================================================
  group('persistence after reopen', () {
    test('Client persists after close and reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p03_test_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo1 = _repo(db1);
      final created = await repo1.create(name: 'Persistent Client');
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found, isNotNull);
      expect(found!.name, 'Persistent Client');
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Archive state remains after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p03_test_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo1 = _repo(db1);
      final created = await repo1.create(name: 'Will Archive');
      await repo1.archive(created.id);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found!.archived, true);
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Updated values remain after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p03_test_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo1 = _repo(db1);
      final created = await repo1.create(name: 'Original');
      await repo1.update(id: created.id, name: 'Updated Name', phone: '+123');
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found!.name, 'Updated Name');
      expect(found.phone, '+123');
      await db2.close();
      await tempDir.delete(recursive: true);
    });
  });

  // ===========================================================================
  // Interface compliance
  // ===========================================================================
  group('interface compliance', () {
    test('LocalClientRepository implements ClientRepositoryInterface', () {
      final db = _createDb();
      final repo = _repo(db);
      expect(repo, isA<ClientRepositoryInterface>());
      db.close();
    });
  });
}
