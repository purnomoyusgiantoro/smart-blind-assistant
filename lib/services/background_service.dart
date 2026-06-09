import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';

import '../core/utils/logger.dart';
import '../core/utils/platform_helper.dart';

/// Service untuk menjalankan proses di background.
///
/// Memastikan BLE listener dan workflow tetap aktif
/// meskipun layar HP terkunci atau aplikasi di-minimize.
/// Hanya aktif di mobile (Android/iOS).
class BackgroundService {
  static const String _tag = 'BackgroundService';

  /// Inisialisasi dan konfigurasi background service.
  static Future<void> initialize() async {
    if (!PlatformHelper.isBackgroundServiceSupported) {
      AppLogger.info(_tag, 'Background service tidak didukung di platform ini');
      return;
    }

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'sight_assist_channel',
        initialNotificationTitle: 'SightAssist',
        initialNotificationContent: 'Mendengarkan perangkat BLE...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    AppLogger.info(_tag, 'Background service dikonfigurasi');
  }

  /// Entry point saat service dimulai (Android & iOS foreground).
  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    AppLogger.info(_tag, 'Background service dimulai');

    // Listen untuk perintah stop
    service.on('stop').listen((event) {
      service.stopSelf();
      AppLogger.info(_tag, 'Background service dihentikan');
    });

    // Periodic heartbeat (opsional, untuk monitoring)
    Timer.periodic(const Duration(seconds: 30), (timer) {
      service.invoke('heartbeat', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  /// Entry point untuk iOS background.
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Mulai background service.
  static Future<void> start() async {
    if (!PlatformHelper.isBackgroundServiceSupported) {
      AppLogger.info(_tag, 'Background service tidak didukung di platform ini');
      return;
    }
    final service = FlutterBackgroundService();
    await service.startService();
    AppLogger.info(_tag, 'Background service dimulai');
  }

  /// Hentikan background service.
  static Future<void> stop() async {
    if (!PlatformHelper.isBackgroundServiceSupported) return;
    final service = FlutterBackgroundService();
    service.invoke('stop');
    AppLogger.info(_tag, 'Background service dihentikan');
  }

  /// Cek apakah service sedang berjalan.
  static Future<bool> isRunning() async {
    if (!PlatformHelper.isBackgroundServiceSupported) return false;
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

