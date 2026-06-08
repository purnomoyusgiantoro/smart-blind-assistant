import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import '../features/log/log_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/settings/settings_screen.dart';

/// Definisi named routes aplikasi.
class AppRouter {
  AppRouter._();

  // ─── Route Names ───────────────────────────────────────────
  static const String home = '/';
  static const String scan = '/scan';
  static const String settings = '/settings';
  static const String log = '/log';

  // ─── Route Map ─────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes {
    return {
      home: (_) => const HomeScreen(),
      scan: (_) => const ScanScreen(),
      settings: (_) => const SettingsScreen(),
      log: (_) => const LogScreen(),
    };
  }
}
