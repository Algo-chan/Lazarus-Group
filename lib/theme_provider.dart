import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class ThemeManager {
  static void toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
  }
}
