import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_service_app/core/enums/user_role.dart';
import 'package:local_service_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:local_service_app/features/auth/presentation/screens/login_screen.dart';
import 'package:local_service_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:local_service_app/features/admin/presentation/screens/admin_dashboard.dart';
import 'package:local_service_app/features/provider/presentation/screens/provider_dashboard.dart';
import 'package:local_service_app/features/customer/presentation/screens/customer_dashboard.dart';
import 'package:local_service_app/shared/widgets/unauthorized_screen.dart';

class AppRouter {
  final GoRouter router;

  AppRouter(AuthProvider authProvider)
      : router = _createRouter(authProvider);

  static GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: true,
      refreshListenable: authProvider,
      redirect: (context, state) => _handleRedirect(context, state, authProvider),
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const _SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/unauthorized',
          builder: (context, state) => const UnauthorizedScreen(),
        ),
        GoRoute(
          path: '/customer',
          builder: (context, state) => const CustomerDashboard(),
        ),
        GoRoute(
          path: '/provider',
          builder: (context, state) => const ProviderDashboard(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboard(),
        ),
      ],
    );
  }

  static Future<String?> _handleRedirect(
      BuildContext context, GoRouterState state, AuthProvider auth) async {
    final isOnAuthPage =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    final isOnSplash = state.matchedLocation == '/splash';

    if (isOnSplash && auth.status == AuthStatus.uninitialized) {
      await auth.initialize();
    }

    switch (auth.status) {
      case AuthStatus.uninitialized:
      case AuthStatus.loading:
        return null;
      case AuthStatus.unauthenticated:
        if (isOnAuthPage) return null;
        return '/login';
      case AuthStatus.authenticated:
        if (isOnAuthPage) {
          return _routeForRole(auth.role);
        }
        final roleRoute = _routeForRole(auth.role);
        if (!state.matchedLocation.startsWith(roleRoute)) {
          return roleRoute;
        }
        return null;
    }
  }

  static String _routeForRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return '/admin';
      case UserRole.provider:
        return '/provider';
      case UserRole.customer:
        return '/customer';
      default:
        return '/login';
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_rounded, size: 80, color: Color(0xFF007BFF)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
