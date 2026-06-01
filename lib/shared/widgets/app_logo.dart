import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 60,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.connect_without_contact,
            size: size * 0.6,
            color: Colors.white,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Local',
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                TextSpan(
                  text: 'Connect',
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
