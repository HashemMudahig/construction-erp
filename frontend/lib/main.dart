import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "core/router/app_router.dart";

void main() {
  runApp(const ProviderScope(child: ConstructionErpApp()));
}

class ConstructionErpApp extends ConsumerWidget {
  const ConstructionErpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: "Construction ERP",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1565C0),
      ),
      routerConfig: router,
    );
  }
}