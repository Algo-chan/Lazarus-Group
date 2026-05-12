import 'package:flutter/material.dart';
import '../../core/enums/user_role.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;
  final double size;

  const RoleBadge({
    super.key,
    required this.role,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label) = switch (role) {
      UserRole.admin => (Colors.red, Icons.shield, 'Admin'),
      UserRole.provider => (Colors.blue, Icons.verified, 'Provider'),
      UserRole.customer => (Colors.green, Icons.person, 'Customer'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
