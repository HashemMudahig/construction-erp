import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/date_symbol_data_local.dart";

import "core/localization/app_localizations.dart";
import "core/database/database_provider.dart";
import "core/database/database_startup_recovery_service.dart";
import "core/router/app_router.dart";
import "core/theme/app_theme.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar_SA', null);
  await initializeDateFormatting('en', null);
  final databaseFile = await resolveDatabaseFile();
  try {
    await const DatabaseStartupRecoveryService().recover(databaseFile);
  } on DatabaseStartupRecoveryException {
    runApp(const DatabaseRecoveryErrorApp());
    return;
  }
  runApp(const ProviderScope(child: ConstructionErpApp()));
}

class DatabaseRecoveryErrorApp extends StatelessWidget {
  const DatabaseRecoveryErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Local data could not be opened safely. Restore a verified backup.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class ConstructionErpApp extends ConsumerWidget {
  const ConstructionErpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: "Construction ERP",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
