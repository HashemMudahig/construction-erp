import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/clients/presentation/client_form_screen.dart';
import '../../features/clients/presentation/client_list_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/projects/presentation/project_detail_screen.dart';
import '../../features/projects/presentation/project_form_screen.dart';
import '../../features/projects/presentation/project_list_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final isLoggedIn = session.isLoggedIn;
      final isLoginRoute = state.path == '/login';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/clients', builder: (_, __) => const ClientListScreen()),
          GoRoute(path: '/clients/new', builder: (_, __) => const ClientFormScreen()),
          GoRoute(
            path: '/clients/:id',
            builder: (_, s) => ClientDetailScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/clients/:id/edit',
            builder: (_, s) => ClientFormScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(path: '/projects', builder: (_, __) => const ProjectListScreen()),
          GoRoute(path: '/projects/new', builder: (_, s) {
            final clientId = s.uri.queryParameters['client_id'];
            return ProjectFormScreen(clientId: clientId);
          }),
          GoRoute(
            path: '/projects/:id',
            builder: (_, s) => ProjectDetailScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/projects/:id/edit',
            builder: (_, s) => ProjectFormScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
        ],
      ),
    ],
  );
});

/// A [Listenable] that notifies the router when auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AuthSession>(authSessionProvider, (_, __) => notifyListeners());
  }
}