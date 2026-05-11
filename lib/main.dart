import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'api_service.dart';
import 'theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocalServiceApp());
}

class LocalServiceApp extends StatefulWidget {
  const LocalServiceApp({super.key});

  @override
  State<LocalServiceApp> createState() => _LocalServiceAppState();
}

class _LocalServiceAppState extends State<LocalServiceApp> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final loggedIn = await ApiService.isLoggedIn().timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, __) {
        return MaterialApp(
          title: 'LocalConnect',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF007BFF),
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF007BFF),
              primary: const Color(0xFF007BFF),
              secondary: const Color(0xFFF47E20),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
              bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF2D3436)),
            ),
          ),
          home: _isLoggedIn == null 
            ? const Scaffold(body: Center(child: CircularProgressIndicator())) 
            : (_isLoggedIn! ? const HomeScreen() : const LoginScreen()),
        );
      },
    );
  }
}
