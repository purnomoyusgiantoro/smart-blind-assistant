import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import 'logger.dart';

/// Mengelola semua izin runtime yang dibutuhkan aplikasi.
///
/// Izin yang dibutuhkan:
/// - Bluetooth (scan & connect)
/// - Kamera (capture gambar)
/// - Mikrofon (opsional, untuk voice input)
/// - Lokasi (diperlukan oleh BLE di Android)
class AppPermissions {
  AppPermissions._();

  static const String _tag = 'Permissions';

  /// Meminta semua izin yang dibutuhkan sekaligus.
  /// Mengembalikan `true` jika semua izin critical diberikan.
  static Future<bool> requestAll() async {
    final results = <Permission, PermissionStatus>{};

    // Bluetooth permissions (Android 12+)
    if (Platform.isAndroid) {
      results[Permission.bluetoothScan] =
          await Permission.bluetoothScan.request();
      results[Permission.bluetoothConnect] =
          await Permission.bluetoothConnect.request();
      results[Permission.locationWhenInUse] =
          await Permission.locationWhenInUse.request();
    }

    // iOS: Bluetooth permission
    if (Platform.isIOS) {
      results[Permission.bluetooth] =
          await Permission.bluetooth.request();
    }

    // Kamera
    results[Permission.camera] = await Permission.camera.request();

    // Mikrofon (opsional)
    results[Permission.microphone] = await Permission.microphone.request();

    // Log semua hasil
    for (final entry in results.entries) {
      AppLogger.info(
        _tag,
        '${entry.key}: ${entry.value}',
      );
    }

    // Check apakah izin critical diberikan
    final cameraGranted = results[Permission.camera]?.isGranted ?? false;
    final bleGranted = Platform.isAndroid
        ? (results[Permission.bluetoothScan]?.isGranted ?? false) &&
            (results[Permission.bluetoothConnect]?.isGranted ?? false)
        : (results[Permission.bluetooth]?.isGranted ?? false);

    if (!cameraGranted) {
      AppLogger.error(_tag, 'Izin kamera ditolak!');
    }
    if (!bleGranted) {
      AppLogger.error(_tag, 'Izin Bluetooth ditolak!');
    }

    return cameraGranted && bleGranted;
  }

  /// Cek apakah izin kamera sudah diberikan.
  static Future<bool> isCameraGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Cek apakah izin Bluetooth sudah diberikan.
  static Future<bool> isBluetoothGranted() async {
    if (Platform.isAndroid) {
      return await Permission.bluetoothScan.isGranted &&
          await Permission.bluetoothConnect.isGranted;
    }
    return await Permission.bluetooth.isGranted;
  }

  /// Buka halaman pengaturan aplikasi (jika user menolak secara permanen).
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
