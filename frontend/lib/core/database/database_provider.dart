import 'dart:io' as io;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'database_constants.dart';

/// Riverpod provider for the [AppDatabase] instance.
///
/// Creates a single managed, **file-backed** database instance per
/// [ProviderScope]. The database file persists across application restarts
/// in the platform's application documents directory.
///
/// The database is automatically closed via [ref.onDispose] when the
/// provider is disposed.
///
/// **Production:** Uses [LazyDatabase] with [NativeDatabase] pointing to a
/// file in the application documents directory. The database is created
/// lazily on first access and persists across restarts.
///
/// **Testing:** Override this provider with an in-memory database:
/// ```dart
/// providerContainer.overrideProvider(
///   databaseProvider,
///   AppDatabase.forTesting(NativeDatabase.memory()),
/// )
/// ```
///
/// No screen or feature provider accesses [AppDatabase] directly during
/// Phase 02. DAOs and local repositories (future phases) will consume
/// this provider.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(_openConnection());
  ref.onDispose(() => db.close());
  return db;
});

/// Creates a lazy, file-backed [QueryExecutor] for production use.
///
/// The database file is stored in the application documents directory,
/// which is private to the app, persists across restarts, and does not
/// require broad storage permissions.
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFile = await resolveDatabaseFile();
    return NativeDatabase.createInBackground(dbFile);
  });
}

/// Resolves the canonical production database file without opening it.
Future<io.File> resolveDatabaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return io.File(p.join(dir.path, kDatabaseFileName));
}
