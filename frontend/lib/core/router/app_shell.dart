import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';

/// App shell hosting the NavigationRail/Drawer + top bar + content area.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final location = GoRouterState.of(context).uri.path;
    // Determine the active section from the path.
    final section = location.startsWith('/projects') ? 1 : 0;

    final body = Row(
      children: [
        NavigationRail(
          selectedIndex: section,
          onDestinationSelected: (i) {
            if (i == 0) context.go('/');
            if (i == 1) context.go('/projects');
          },
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: Text('Clients'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: Text('Projects'),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: child),
      ],
    );

    final drawer = Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
            child: Text(
              'Construction ERP',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Clients'),
            selected: section == 0,
            onTap: () { context.go('/'); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Projects'),
            selected: section == 1,
            onTap: () { context.go('/projects'); Navigator.pop(context); },
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Construction ERP'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text(session.user?.email ?? '')),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authSessionProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      drawer: drawer,
      body: MediaQuery.of(context).size.width >= 600
          ? body
          : child,
    );
  }
}