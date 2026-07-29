import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'services/app_settings_service.dart';

void main() {
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = AppSettingsService();

    return ValueListenableBuilder<Locale>(
      valueListenable: settingsService.localeNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: settingsService.themeModeNotifier,
          builder: (context, themeMode, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Inventory Management',
              locale: locale,
              themeMode: themeMode,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: const Color(0xFFF7FBFF),
                cardColor: const Color(0xFFFFFFFF),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2D9CFF),
                  brightness: Brightness.light,
                  surface: const Color(0xFFFFFFFF),
                ),
                fontFamily: 'Poppins',
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF0F172A),
                cardColor: const Color(0xFF1E293B),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2D9CFF),
                  brightness: Brightness.dark,
                  surface: const Color(0xFF1E293B),
                ),
                fontFamily: 'Poppins',
              ),
              home: const DashboardScreen(),
            );
          },
        );
      },
    );
  }
}