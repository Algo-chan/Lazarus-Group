import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool filled;

  const StatusChip({
    super.key,
    required this.status,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = _statusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? data.color : data.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.color.withValues(alpha: filled ? 0.0 : 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.icon,
            size: 16,
            color: filled ? Colors.white : data.color,
          ),
          const SizedBox(width: 5),
          Text(
            _formatLabel(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : data.color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String s) {
    return s
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  _StatusData _statusData(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusData(
          color: const Color(0xFFFFC107),
          icon: Icons.schedule,
        );
      case 'confirmed':
        return _StatusData(
          color: const Color(0xFF007BFF),
          icon: Icons.check_circle,
        );
      case 'in_progress':
        return _StatusData(
          color: const Color(0xFF20c997),
          icon: Icons.engineering,
        );
      case 'completed':
        return _StatusData(
          color: const Color(0xFF28A745),
          icon: Icons.verified,
        );
      case 'cancelled':
        return _StatusData(
          color: const Color(0xFFDC3545),
          icon: Icons.cancel,
        );
      default:
        return _StatusData(
          color: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }
}

class _StatusData {
  final Color color;
  final IconData icon;

  const _StatusData({required this.color, required this.icon});
}
