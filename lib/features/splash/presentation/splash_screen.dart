import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for animation to finish or at least some time for brand exposure
    await Future.delayed(const Duration(milliseconds: 2500));
    // AuthProvider will handle the redirection via GoRouter's refreshListenable
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Lottie or simple loader
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 120)
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 24),
                Text(
                  'LocalConnect',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Ethiopia\'s Trusted Marketplace',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
              ],
            ),
          ),
          
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Lottie.network(
                'https://assets9.lottiefiles.com/packages/lf20_st7re96h.json', // Simple dots loader
                width: 60,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
