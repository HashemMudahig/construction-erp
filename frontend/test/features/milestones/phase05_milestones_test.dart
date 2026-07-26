import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_constants.dart';
import 'package:construction_erp/core/uuid/uuid_util.dart';
import 'package:construction_erp/features/milestones/data/local_milestone_repository.dart';
import 'package:construction_erp/features/milestones/data/milestone_mapper.dart';
import 'package:construction_erp/features/milestones/domain/milestone_entity.dart';
import 'package:construction_erp/features/milestones/domain/milestone_repository_interface.dart';
import 'package:construction_erp/features/projects/data/local_project_repository.dart';

const _clientId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _projectId = 'bbbbbbbb-0000-4000-8000-000000000001';
const _milestoneId = 'cccccccc-0000-4000-8000-000000000001';
const _ts = '2026-01-15T10:00:00Z';
const _dueDate = '2026-06-15';
const _dueDatePast = '2026-01-01';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

Future<void> _seedClientAndProject(AppDatabase db) async {
  await db.into(db.clients).insert(ClientsCompanion.insert(
      id: _clientId, name: 'Test Client', createdAt: _ts, updatedAt: _ts));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
      id: _projectId,
      clientId: _clientId,
      name: 'Test Project',
      budgetAmountMinor: 1000000,
      budgetCurrency: kCurrencyYer,
      createdAt: _ts));
}

LocalMilestoneRepository _repo(AppDatabase db) =>
    LocalMilestoneRepository(db.milestonesDao, db.projectsDao);

void main() {
  group('LocalMilestoneRepository CRUD', () {
    test('Create milestone', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final ms = await repo.create(
          projectId: _projectId, title: 'Foundation', dueDate: _dueDate);
      expect(ms.title, 'Foundation');
      expect(ms.projectId, _projectId);
      expect(ms.status, 'pending');
      expect(UuidUtil.isValid(ms.id), true);
      await db.close();
    });

    test('Get milestone by ID', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId, title: 'Find Me', dueDate: _dueDate);
      final found = await repo.getById(created.id);
      expect(found, isNotNull);
      expect(found!.title, 'Find Me');
      await db.close();
    });

    test('List milestones by project', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      await repo.create(
          projectId: _projectId, title: 'M1', dueDate: '2026-06-01');
      await repo.create(
          projectId: _projectId, title: 'M2', dueDate: '2026-05-01');
      final list = await repo.listByProject(_projectId);
      expect(list.length, 2);
      // Ordered by due date ascending
      expect(list.first.title, 'M2');
      expect(list.last.title, 'M1');
      await db.close();
    });

    test('Update milestone', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId, title: 'Original', dueDate: _dueDate);
      final updated = await repo.update(id: created.id, title: 'Updated');
      expect(updated.title, 'Updated');
      await db.close();
    });

    test('Complete milestone', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId, title: 'To Complete', dueDate: _dueDate);
      final completed = await repo.complete(created.id);
      expect(completed.status, 'completed');
      await db.close();
    });

    test('Repeated complete is deterministic', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId, title: 'Complete Twice', dueDate: _dueDate);
      await repo.complete(created.id);
      final second = await repo.complete(created.id);
      expect(second.status, 'completed');
      await db.close();
    });

    test('Delete milestone', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId, title: 'Delete Me', dueDate: _dueDate);
      await repo.delete(created.id);
      final found = await repo.getById(created.id);
      expect(found, isNull);
      await db.close();
    });

    test('Deleting milestone does not delete project', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId, title: 'Delete Me', dueDate: _dueDate);
      await repo.delete(created.id);
      final project = await db.projectsDao.getProjectById(_projectId);
      expect(project, isNotNull);
      await db.close();
    });

    test('Project with milestones cannot be hard-deleted', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      await repo.create(
          projectId: _projectId, title: 'Blocker', dueDate: _dueDate);
      final projectRepo =
          LocalProjectRepository(db.projectsDao, db.clientsDao, db);
      expect(
        () => projectRepo.deleteIfEligible(_projectId),
        throwsA(isA<StateError>()),
      );
      await db.close();
    });
  });

  group('validation', () {
    test('Blank title rejected', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      expect(
          () => repo.create(
              projectId: _projectId, title: '  ', dueDate: _dueDate),
          throwsArgumentError);
      await db.close();
    });

    test('Invalid status rejected', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      expect(
          () => repo.create(
              projectId: _projectId,
              title: 'Test',
              dueDate: _dueDate,
              status: 'invalid'),
          throwsArgumentError);
      await db.close();
    });

    test('Invalid UUID rejected', () async {
      final db = _createDb();
      final repo = _repo(db);
      expect(() => repo.getById('bad-uuid'), throwsArgumentError);
      await db.close();
    });

    test('Orphan milestone rejected (non-existent project)', () async {
      final db = _createDb();
      final repo = _repo(db);
      expect(
        () => repo.create(
            projectId: 'nonexistent-0000-4000-8000-000000000000',
            title: 'Orphan',
            dueDate: _dueDate),
        throwsArgumentError,
      );
      await db.close();
    });
  });

  group('overdue', () {
    test('Pending before due date is not overdue', () {
      final ms = MilestoneEntity(
          id: 'x',
          projectId: 'y',
          title: 'Test',
          dueDate: DateTime.parse('2026-12-31T00:00:00'),
          status: 'pending',
          createdAt: DateTime.parse(_ts));
      expect(ms.effectiveStatus(DateTime(2026, 6, 1)), 'pending');
    });

    test('Due today is not overdue', () {
      final ms = MilestoneEntity(
          id: 'x',
          projectId: 'y',
          title: 'Test',
          dueDate: DateTime.parse('2026-06-15T00:00:00'),
          status: 'pending',
          createdAt: DateTime.parse(_ts));
      expect(ms.effectiveStatus(DateTime(2026, 6, 15)), 'pending');
    });

    test('Pending after due date is effectively overdue', () {
      final ms = MilestoneEntity(
          id: 'x',
          projectId: 'y',
          title: 'Test',
          dueDate: DateTime.parse('2026-01-01T00:00:00'),
          status: 'pending',
          createdAt: DateTime.parse(_ts));
      expect(ms.effectiveStatus(DateTime(2026, 7, 25)), 'overdue');
    });

    test('In-progress after due date is effectively overdue', () {
      final ms = MilestoneEntity(
          id: 'x',
          projectId: 'y',
          title: 'Test',
          dueDate: DateTime.parse('2026-01-01T00:00:00'),
          status: 'in_progress',
          createdAt: DateTime.parse(_ts));
      expect(ms.effectiveStatus(DateTime(2026, 7, 25)), 'overdue');
    });

    test('Completed after due date remains completed', () {
      final ms = MilestoneEntity(
          id: 'x',
          projectId: 'y',
          title: 'Test',
          dueDate: DateTime.parse('2026-01-01T00:00:00'),
          status: 'completed',
          createdAt: DateTime.parse(_ts));
      expect(ms.effectiveStatus(DateTime(2026, 7, 25)), 'completed');
    });

    test(
        'Reopening on later date derives overdue without rewriting stored status',
        () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId, title: 'Past Due', dueDate: _dueDatePast);
      // On 2026-01-02, it's overdue
      final ms1 = await repo.getById(created.id);
      expect(ms1!.effectiveStatus(DateTime(2026, 1, 2)), 'overdue');
      // On 2025-12-31, it's not overdue
      final ms2 = await repo.getById(created.id);
      expect(ms2!.effectiveStatus(DateTime(2025, 12, 31)), 'pending');
      // Stored status unchanged
      expect(ms2.status, 'pending');
      await db.close();
    });
  });

  group('progress', () {
    test('No milestones returns zero progress', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final total = await repo.countByProject(_projectId);
      final completed = await repo.countCompletedByProject(_projectId);
      final progress = total > 0 ? completed / total * 100 : 0.0;
      expect(progress, 0.0);
      await db.close();
    });

    test('One of two completed returns exactly 50%', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final m1 = await repo.create(
          projectId: _projectId, title: 'M1', dueDate: _dueDate);
      await repo.create(projectId: _projectId, title: 'M2', dueDate: _dueDate);
      await repo.complete(m1.id);
      final total = await repo.countByProject(_projectId);
      final completed = await repo.countCompletedByProject(_projectId);
      expect(total, 2);
      expect(completed, 1);
      final progress = completed / total * 100;
      expect(progress, 50.0);
      await db.close();
    });

    test('All completed returns exactly 100%', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final m1 = await repo.create(
          projectId: _projectId, title: 'M1', dueDate: _dueDate);
      final m2 = await repo.create(
          projectId: _projectId, title: 'M2', dueDate: _dueDate);
      await repo.complete(m1.id);
      await repo.complete(m2.id);
      final total = await repo.countByProject(_projectId);
      final completed = await repo.countCompletedByProject(_projectId);
      expect(total, 2);
      expect(completed, 2);
      expect(completed / total * 100, 100.0);
      await db.close();
    });
  });

  group('persistence', () {
    test('Milestone persists after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p05_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          projectId: _projectId, title: 'Persistent', dueDate: _dueDate);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found, isNotNull);
      expect(found!.title, 'Persistent');
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Complete status persists after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p05_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          projectId: _projectId, title: 'Complete', dueDate: _dueDate);
      await repo1.complete(created.id);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found!.status, 'completed');
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Project relationship persists after reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p05_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          projectId: _projectId, title: 'Rel Test', dueDate: _dueDate);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      expect(found!.projectId, _projectId);
      final project = await db2.projectsDao.getProjectById(_projectId);
      expect(project, isNotNull);
      await db2.close();
      await tempDir.delete(recursive: true);
    });

    test('Stored status unchanged when only effective overdue changes',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('erp_p05_');
      final file = File(p.join(tempDir.path, kDatabaseFileName));

      final db1 = AppDatabase(NativeDatabase.createInBackground(file));
      await _seedClientAndProject(db1);
      final repo1 = _repo(db1);
      final created = await repo1.create(
          projectId: _projectId, title: 'Past', dueDate: _dueDatePast);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase.createInBackground(file));
      final repo2 = _repo(db2);
      final found = await repo2.getById(created.id);
      // Stored status is still 'pending', not 'overdue'
      expect(found!.status, 'pending');
      // But effective status is 'overdue' for a later reference date
      expect(found.effectiveStatus(DateTime(2026, 7, 25)), 'overdue');
      await db2.close();
      await tempDir.delete(recursive: true);
    });
  });

  group('mapping', () {
    test('Row maps exactly to entity', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      await db.into(db.milestones).insert(MilestonesCompanion.insert(
          id: _milestoneId,
          projectId: _projectId,
          title: 'Test',
          description: const Value('Desc'),
          dueDate: _dueDate,
          status: const Value('pending'),
          createdAt: _ts));
      final row = await db.milestonesDao.getMilestoneById(_milestoneId);
      final entity = MilestoneMapper.rowToEntity(row!);
      expect(entity.id, _milestoneId);
      expect(entity.projectId, _projectId);
      expect(entity.title, 'Test');
      expect(entity.description, 'Desc');
      expect(entity.dueDate, DateTime.parse('${_dueDate}T00:00:00'));
      expect(entity.status, 'pending');
      expect(entity.createdAt, DateTime.parse(_ts));
      await db.close();
    });

    test('Nullable description round-trips', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final created = await repo.create(
          projectId: _projectId, title: 'No Desc', dueDate: _dueDate);
      final found = await repo.getById(created.id);
      expect(found!.description, isNull);
      await db.close();
    });
  });

  group('interface compliance', () {
    test('LocalMilestoneRepository implements MilestoneRepositoryInterface',
        () {
      final db = _createDb();
      final repo = _repo(db);
      expect(repo, isA<MilestoneRepositoryInterface>());
      db.close();
    });
  });

  group('transitional regression: local project creates local milestone', () {
    test('Local Client → Local Project → Local Milestone flow', () async {
      final db = _createDb();
      await _seedClientAndProject(db);
      final repo = _repo(db);
      final ms = await repo.create(
          projectId: _projectId, title: 'E2E Milestone', dueDate: _dueDate);
      expect(ms.projectId, _projectId);
      final found = await repo.getById(ms.id);
      expect(found, isNotNull);
      expect(found!.title, 'E2E Milestone');
      await db.close();
    });
  });
}
