import 'dart:io';

/// Helper untuk mengecek platform saat runtime.
///
/// Digunakan untuk men-skip fitur mobile-only (BLE, background service)
/// saat aplikasi dijalankan di desktop (Windows/macOS/Linux).
/// Kamera dan TTS didukung di semua platform.
class PlatformHelper {
  PlatformHelper._();

  /// Apakah berjalan di perangkat mobile (Android/iOS)
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  /// Apakah berjalan di desktop (Windows/macOS/Linux)
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Apakah BLE tersedia di platform ini (hanya mobile)
  static bool get isBleSupported => isMobile;

  /// Apakah kamera tersedia di platform ini (semua platform)
  static bool get isCameraSupported => true;

  /// Apakah background service tersedia di platform ini (hanya mobile)
  static bool get isBackgroundServiceSupported => isMobile;
}

