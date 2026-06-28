import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../features/dashboard/presentation/dashboard_screen.dart";
import "../features/auth/presentation/login_screen.dart";

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: "/login",
    routes: [
      GoRoute(
        path: "/login",
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: "/dashboard",
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});