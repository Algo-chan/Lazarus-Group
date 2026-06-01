import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/enums/user_role.dart';
import '../../providers/auth_provider.dart';

class RouteGuards {
  static bool canAccess(UserRole requiredRole, BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return false;
    return _roleLevel(auth.role) >= _roleLevel(requiredRole);
  }

  static int _roleLevel(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 3;
      case UserRole.provider:
        return 2;
      case UserRole.customer:
        return 1;
      default:
        return 0;
    }
  }

  static void redirectIfNot({
    required BuildContext context,
    required UserRole role,
    String fallbackRoute = '/login',
  }) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      context.go(fallbackRoute);
      return;
    }
    if (_roleLevel(auth.role) < _roleLevel(role)) {
      context.go('/unauthorized');
    }
  }
}

class RoleGuard extends StatelessWidget {
  final UserRole requiredRole;
  final Widget child;
  final Widget? unauthorized;

  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
    this.unauthorized,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasAccess = _roleLevel(auth.role) >= _roleLevel(requiredRole);

    if (!hasAccess) {
      return unauthorized ??
          Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('You do not have permission to access this page.',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Required role: ${requiredRole.value}',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
    }

    return child;
  }

  int _roleLevel(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 3;
      case UserRole.provider:
        return 2;
      case UserRole.customer:
        return 1;
      default:
        return 0;
    }
  }
}
