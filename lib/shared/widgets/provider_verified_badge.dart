import 'package:flutter/material.dart';

class ProviderVerifiedBadge extends StatelessWidget {
  final bool showLabel;
  final double size;

  const ProviderVerifiedBadge({
    super.key,
    this.showLabel = true,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return Icon(
        Icons.verified,
        size: size,
        color: const Color(0xFF28A745),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF28A745).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF28A745).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: size - 2,
            color: const Color(0xFF28A745),
          ),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: size - 6,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF28A745),
            ),
          ),
        ],
      ),
    );
  }
}
