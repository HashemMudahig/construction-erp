import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/core/database/app_database.dart';
import 'package:construction_erp/core/database/database_provider.dart';
import 'package:construction_erp/core/localization/app_localizations.dart';
import 'package:construction_erp/features/clients/domain/client_entity.dart';
import 'package:construction_erp/features/clients/domain/client_repository_interface.dart';
import 'package:construction_erp/features/clients/presentation/client_providers.dart';
import 'package:construction_erp/features/clients/presentation/add_client_dialog.dart';
import 'package:construction_erp/features/projects/presentation/project_form_screen.dart';

/// Minimal in-memory [ClientRepositoryInterface] used to assert the dialog
/// flow without depending on Drift internals.
class _FakeClientRepository implements ClientRepositoryInterface {
  final List<ClientEntity> _clients = [];
  int createCalls = 0;

  /// When true, [create] throws a simulated database error.
  bool createThrows = false;

  /// Seeds a client without incrementing [createCalls].
  void seed(ClientEntity client) => _clients.add(client);

  @override
  Future<ClientEntity> create({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    createCalls++;
    if (createThrows) {
      throw StateError('Simulated database failure');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Client name is required');
    }
    final now = DateTime.utc(2026, 1, 1);
    final client = ClientEntity(
      id: 'fake-${_clients.length + 1}',
      name: name.trim(),
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      archived: false,
      createdAt: now,
      updatedAt: now,
    );
    _clients.add(client);
    return client;
  }

  @override
  Future<List<ClientEntity>> list({
    String? search,
    bool includeArchived = false,
  }) async => List.unmodifiable(_clients);

  @override
  Future<ClientEntity?> getById(String id) async {
    for (final c in _clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<ClientEntity> update({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? archived,
  }) async {
    for (final c in _clients) {
      if (c.id == id) return c;
    }
    throw ArgumentError('Client not found: $id');
  }

  @override
  Future<void> archive(String id) async {}

  @override
  Future<void> restore(String id) async {}

  @override
  Future<void> deleteIfEligible(String id) async {
    _clients.removeWhere((c) => c.id == id);
  }

  @override
  Future<bool> hasProjects(String id) async => false;
}

AppLocalizations _appLoc(BuildContext context) => AppLocalizations.of(context);

Future<void> _pumpForm(
  WidgetTester tester, {
  required Locale locale,
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const ProjectFormScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the client dropdown and taps the item matching [itemText].
Future<void> _tapDropdownItem(
  WidgetTester tester,
  String itemText,
) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(itemText).last);
  await tester.pumpAndSettle();
}

ClientEntity _seedClient(String name, {String id = 'seed-1'}) {
  final now = DateTime.utc(2026, 1, 1);
  return ClientEntity(
    id: id,
    name: name,
    archived: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ProjectFormScreen client field', () {
    testWidgets('existing client selection still works', (tester) async {
      final repo = _FakeClientRepository()..seed(_seedClient('Existing Owner'));

      await _pumpForm(
        tester,
        locale: const Locale('en'),
        overrides: [clientRepositoryProvider.overrideWithValue(repo)],
      );

      await _tapDropdownItem(tester, 'Existing Owner');
      expect(repo.createCalls, 0);
    });

    testWidgets('creating a client from the project form creates a record '
        'and auto-selects it', (tester) async {
      final repo = _FakeClientRepository()..seed(_seedClient('Seed Owner'));

      await _pumpForm(
        tester,
        locale: const Locale('en'),
        overrides: [clientRepositoryProvider.overrideWithValue(repo)],
      );

      // Open the dropdown and pick "+ add new client".
      await _tapDropdownItem(tester, '+ Add new client');

      // Dialog is open.
      expect(find.byType(AddClientDialog), findsOneWidget);
      expect(find.text('Client name *'), findsOneWidget);

      // Enter the name and save. The dialog is in an overlay on top of the
      // form, so scope the finder to the dialog widget.
      final dialogNameField = find.descendant(
        of: find.byType(AddClientDialog),
        matching: find.byType(TextField),
        matchRoot: false,
      ).first;
      await tester.enterText(dialogNameField, 'New Owner');
      await tester.tap(find.widgetWithText(FilledButton, 'Save client'));
      await tester.pumpAndSettle();

      // A new client record was created via the repository.
      expect(repo.createCalls, 1);
      // The dialog closed.
      expect(find.byType(AddClientDialog), findsNothing);
      // The newly created client is now selected (dropdown shows its name).
      expect(find.text('New Owner'), findsOneWidget);
    });

    testWidgets('canceling the dialog does not create a client and keeps '
        'the project form intact', (tester) async {
      final repo = _FakeClientRepository()..seed(_seedClient('Seed Owner'));

      await _pumpForm(
        tester,
        locale: const Locale('en'),
        overrides: [clientRepositoryProvider.overrideWithValue(repo)],
      );

      await _tapDropdownItem(tester, '+ Add new client');
      expect(find.byType(AddClientDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(repo.createCalls, 0);
      expect(find.byType(AddClientDialog), findsNothing);
      expect(find.byType(ProjectFormScreen), findsOneWidget);
    });

    testWidgets('validation prevents empty client name in the dialog',
        (tester) async {
      final repo = _FakeClientRepository()..seed(_seedClient('Seed Owner'));

      await _pumpForm(
        tester,
        locale: const Locale('en'),
        overrides: [clientRepositoryProvider.overrideWithValue(repo)],
      );

      await _tapDropdownItem(tester, '+ Add new client');

      // Tap Save without entering a name.
      await tester.tap(find.widgetWithText(FilledButton, 'Save client'));
      await tester.pumpAndSettle();

      expect(find.text('Client name is required'), findsOneWidget);
      expect(repo.createCalls, 0);
      // The dialog is still open.
      expect(find.byType(AddClientDialog), findsOneWidget);
    });

    testWidgets('database failure shows a friendly Arabic message and does '
        'not expose the technical exception', (tester) async {
      final repo = _FakeClientRepository()
        ..seed(_seedClient('Seed Owner'))
        ..createThrows = true;

      await _pumpForm(
        tester,
        locale: const Locale('ar'),
        overrides: [clientRepositoryProvider.overrideWithValue(repo)],
      );

      await _tapDropdownItem(tester, '+ إضافة عميل جديد');
      await tester.enterText(
        find.descendant(
          of: find.byType(AddClientDialog),
          matching: find.byType(TextField),
        ).first,
        'فاشل',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ العميل'));
      await tester.pumpAndSettle();

      // A create attempt was made.
      expect(repo.createCalls, 1);
      // The dialog stays open with the friendly localized message.
      expect(find.byType(AddClientDialog), findsOneWidget);
      expect(find.text('فشل إنشاء العميل. يرجى المحاولة مرة أخرى.'),
          findsOneWidget);
      // The raw technical exception is never shown to the user.
      expect(find.textContaining('StateError'), findsNothing);
      expect(find.textContaining('Simulated database failure'), findsNothing);
    });

    testWidgets('Arabic labels render for the add-client workflow without '
        'mixing English', (tester) async {
      final repo = _FakeClientRepository()..seed(_seedClient('Seed Owner'));

      await _pumpForm(
        tester,
        locale: const Locale('ar'),
        overrides: [clientRepositoryProvider.overrideWithValue(repo)],
      );

      // Project form uses Arabic labels.
      expect(find.text('مشروع جديد'), findsOneWidget);
      expect(find.text('صاحب المشروع *'), findsOneWidget);

      // Open the dropdown and pick the Arabic "+ add new client" entry.
      await _tapDropdownItem(tester, '+ إضافة عميل جديد');

      // Dialog is fully Arabic.
      expect(find.byType(AddClientDialog), findsOneWidget);
      expect(find.text('إضافة عميل جديد'), findsWidgets);
      expect(find.text('اسم العميل *'), findsOneWidget);
      expect(find.text('حفظ العميل'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      // No raw English fallbacks for our keys.
      expect(find.text('Add new client'), findsNothing);
      expect(find.text('Client name *'), findsNothing);
      expect(find.text('Save client'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('project cannot be created without a client (validator)',
        (tester) async {
      final repo = _FakeClientRepository();

      await _pumpForm(
        tester,
        locale: const Locale('en'),
        overrides: [clientRepositoryProvider.overrideWithValue(repo)],
      );

      // Fill the required project name so only the client validator can fail.
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Some Project',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        '1000',
      );

      await tester.tap(find.text('Create project'));
      await tester.pumpAndSettle();

      // The localized "select a project owner" error appears.
      expect(find.text('Select a project owner.'), findsOneWidget);
      expect(repo.createCalls, 0);
    });
  });

  group('AddClientDialog standalone', () {
    Future<void> _pumpLauncher(
      WidgetTester tester, {
      required ClientRepositoryInterface repo,
      required Locale locale,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clientRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => AddClientDialog.show(context),
                    child: const Text('launch'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('returns null when cancelled', (tester) async {
      final repo = _FakeClientRepository();
      await _pumpLauncher(
        tester,
        repo: repo,
        locale: const Locale('en'),
      );
      await tester.tap(find.text('launch'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AddClientDialog), findsNothing);
      expect(repo.createCalls, 0);
    });

    testWidgets('returns created client when saved', (tester) async {
      final repo = _FakeClientRepository();
      await _pumpLauncher(
        tester,
        repo: repo,
        locale: const Locale('en'),
      );
      await tester.tap(find.text('launch'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Standalone Owner');
      await tester.tap(find.widgetWithText(FilledButton, 'Save client'));
      await tester.pumpAndSettle();

      expect(find.byType(AddClientDialog), findsNothing);
      expect(repo.createCalls, 1);
    });
  });

  group('regression: local DB still backs the form', () {
    testWidgets('ProjectFormScreen renders with the real local repository',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const ProjectFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProjectFormScreen), findsOneWidget);
      expect(find.text('New project'), findsOneWidget);
    });
  });
}