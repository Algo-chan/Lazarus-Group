import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'shared/router/app_router.dart';
import 'theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const LocalServiceApp(),
    ),
  );
}

class LocalServiceApp extends StatelessWidget {
  const LocalServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appRouter = AppRouter(authProvider);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, __) {
        return MaterialApp.router(
          title: 'LocalConnect',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          routerConfig: appRouter.router,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFF007BFF),
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF007BFF),
              primary: const Color(0xFF007BFF),
              secondary: const Color(0xFFF47E20),
              brightness: Brightness.light,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
              bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF2D3436)),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF007BFF),
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF007BFF),
              primary: const Color(0xFF007BFF),
              secondary: const Color(0xFFF47E20),
              brightness: Brightness.dark,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
