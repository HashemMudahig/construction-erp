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
    int section;
    if (location.startsWith('/projects')) {
      section = 2;
    } else if (location.startsWith('/clients')) {
      section = 1;
    } else if (location.startsWith('/reports')) {
      section = 3;
    } else {
      section = 0; // dashboard
    }

    final body = Row(
      children: [
        NavigationRail(
          selectedIndex: section,
          onDestinationSelected: (i) {
            if (i == 0) context.go('/');
            if (i == 1) context.go('/clients');
            if (i == 2) context.go('/projects');
            if (i == 3) context.go('/reports');
          },
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            ),
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
            NavigationRailDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment),
              label: Text('Reports'),
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
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: section == 0,
            onTap: () { context.go('/'); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Clients'),
            selected: section == 1,
            onTap: () { context.go('/clients'); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Projects'),
            selected: section == 2,
            onTap: () { context.go('/projects'); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.assessment_outlined),
            title: const Text('Reports'),
            selected: section == 3,
            onTap: () { context.go('/reports'); Navigator.pop(context); },
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