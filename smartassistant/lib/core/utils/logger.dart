import 'package:flutter/foundation.dart';

/// Utility logging wrapper.
///
/// Menambahkan timestamp dan tag ke setiap pesan log.
/// Hanya aktif di debug mode (tidak akan muncul di release build).
class AppLogger {
  AppLogger._();

  static void info(String tag, String message) {
    _log('INFO', tag, message);
  }

  static void warning(String tag, String message) {
    _log('WARN', tag, message);
  }

  static void error(String tag, String message, [Object? error]) {
    _log('ERROR', tag, message);
    if (error != null) {
      debugPrint('  └─ $error');
    }
  }

  static void _log(String level, String tag, String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    debugPrint('[$timestamp] [$level] [$tag] $message');
  }
}
