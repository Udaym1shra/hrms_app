import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/employee_dashboard.dart';
import '../../core/constants/app_routes.dart';

// Router provider with refresh capability
final routerProvider = Provider<GoRouter>((ref) {
  final routerKey = GlobalKey<NavigatorState>();
  GoRouter? router;

  // Listen to auth state changes to trigger router refresh
  ref.listen(authProvider, (previous, next) {
    final wasLoggedIn = previous?.isAuthenticated ?? false;
    final isLoggedIn = next.isAuthenticated;

    // Only refresh if auth state actually changed
    if (wasLoggedIn != isLoggedIn && router != null) {
      // Small delay to ensure state is fully updated
      Future.microtask(() {
        router?.refresh();
      });
    }
  });

  router = GoRouter(
    navigatorKey: routerKey,
    initialLocation: AppRoutes.root,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !isLoggingIn) {
        return AppRoutes.login;
      }

      // If logged in and trying to access login page
      if (isLoggedIn && isLoggingIn) {
        return AppRoutes.dashboard;
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          if (authState.isAuthenticated) {
            return AppRoutes.dashboard;
          }
          return AppRoutes.login;
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) {
          // Get initial index from query parameter or default to 0
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '0') ?? 0;
          return EmployeeDashboard(initialIndex: index);
        },
        routes: [
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) =>
                const EmployeeDashboard(initialIndex: 11),
          ),
          GoRoute(
            path: 'attendance',
            name: 'attendance',
            builder: (context, state) =>
                const EmployeeDashboard(initialIndex: 6),
          ),
          GoRoute(
            path: 'leaves',
            name: 'leaves',
            builder: (context, state) =>
                const EmployeeDashboard(initialIndex: 7),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );

  return router;
});
