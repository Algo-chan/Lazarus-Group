import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/theme_provider.dart';
import 'providers/service_provider.dart';
import 'providers/other_providers.dart';
import 'shared/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppRouter.authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const LocalServiceApp(),
    ),
  );
}

class LocalServiceApp extends StatelessWidget {
  const LocalServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'LocalConnect',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      routerConfig: AppRouter.router,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: const Color(0xFF007BFF),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007BFF),
        brightness: brightness,
        primary: const Color(0xFF007BFF),
        secondary: const Color(0xFFF47E20),
        error: const Color(0xFFDC3545),
        surface: brightness == Brightness.light 
          ? const Color(0xFFFFFFFF) 
          : const Color(0xFF1A1A2E),
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.displayLarge,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.displayMedium,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.displaySmall,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.headlineMedium,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
