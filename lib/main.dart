import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'api_service.dart';
import 'theme_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    bool loggedIn = false;
    try {
      loggedIn = await ApiService.isLoggedIn();
    } catch (e) {
      debugPrint('Error checking login status: $e');
    }
    runApp(LocalServiceApp(isLoggedIn: loggedIn));
  } catch (e) {
    debugPrint('Fatal error in main: $e');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Error starting app: $e')))));
  }
}

class LocalServiceApp extends StatelessWidget {
  final bool isLoggedIn;
  const LocalServiceApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'LocalConnect',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF6C63FF),
            scaffoldBackgroundColor: const Color(0xFFFBFBFD),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              primary: const Color(0xFF6C63FF),
              secondary: const Color(0xFF2D3436),
              surface: Colors.white,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF2D3436),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
              displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
              bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF2D3436)),
              bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF636E72)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF2D3436),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF1F2F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              hintStyle: const TextStyle(color: Color(0xFFB2BEC3)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              margin: const EdgeInsets.only(bottom: 16),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF6C63FF),
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Brightness.dark,
              primary: const Color(0xFF6C63FF),
              secondary: const Color(0xFFE1E1E1),
              surface: const Color(0xFF1E1E1E),
              onPrimary: Colors.white,
              onSurface: const Color(0xFFE1E1E1),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE1E1E1)),
              displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE1E1E1)),
              bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE1E1E1)),
              bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFB2BEC3)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Color(0xFFE1E1E1),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE1E1E1),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              hintStyle: const TextStyle(color: Color(0xFF757575)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              margin: const EdgeInsets.only(bottom: 16),
            ),
          ),
          home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}
