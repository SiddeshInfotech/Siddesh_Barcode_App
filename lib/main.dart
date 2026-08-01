import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/app_settings_service.dart';

import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService().initialize();
  // Sign in so RLS grants access to inventory data. Non-blocking — data calls also
  // ensure a session, this just warms it up during the splash screen.
  unawaited(SupabaseService().ensureSignedIn());
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
                scaffoldBackgroundColor: const Color(0xFFEFF4FA),
                cardColor: const Color(0xFFFFFFFF),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2563EB),
                  brightness: Brightness.light,
                  surface: const Color(0xFFFFFFFF),
                ),
                fontFamily: 'Inter',
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF090D16),
                cardColor: const Color(0xFF1E293B),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2563EB),
                  brightness: Brightness.dark,
                  surface: const Color(0xFF1E293B),
                ),
                fontFamily: 'Inter',
              ),
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}