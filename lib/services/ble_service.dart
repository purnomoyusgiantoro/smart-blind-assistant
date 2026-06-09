import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../core/utils/platform_helper.dart';
import '../models/ble_device.dart';

/// Service untuk komunikasi Bluetooth Low Energy (BLE) dengan ESP32.
///
/// Mengelola scanning, koneksi, dan mendengarkan notifikasi
/// trigger dari tombol fisik ESP32.
/// Hanya aktif di mobile (Android/iOS).
class BleService {
  static const String _tag = 'BleService';

  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _notificationSubscription;

  /// Stream controller untuk trigger events dari ESP32
  final StreamController<int> _triggerController =
      StreamController<int>.broadcast();

  /// Stream yang di-listen oleh provider untuk menerima trigger events
  Stream<int> get triggerStream => _triggerController.stream;

  /// Apakah sedang terhubung ke perangkat
  bool get isConnected => _connectedDevice != null;

  // ─── Scan ──────────────────────────────────────────────────

  /// Mulai scan perangkat BLE di sekitar.
  ///
  /// Mengembalikan stream dari perangkat yang ditemukan.
  Stream<List<BleDevice>> startScan() {
    if (!PlatformHelper.isBleSupported) {
      AppLogger.warning(_tag, 'BLE tidak didukung di platform ini');
      return Stream.value([]);
    }

    AppLogger.info(_tag, 'Mulai scanning BLE...');

    FlutterBluePlus.startScan(
      timeout: Duration(seconds: AppConstants.bleScanTimeoutSeconds),
    );

    return FlutterBluePlus.scanResults.map((results) {
      return results
          .where((r) => r.device.platformName.isNotEmpty)
          .map((r) => BleDevice(
                name: r.device.platformName,
                id: r.device.remoteId.str,
                rssi: r.rssi,
              ))
          .toList();
    });
  }

  /// Hentikan scan BLE.
  Future<void> stopScan() async {
    if (!PlatformHelper.isBleSupported) return;
    await FlutterBluePlus.stopScan();
    AppLogger.info(_tag, 'Scan dihentikan');
  }

  // ─── Connect ───────────────────────────────────────────────

  /// Hubungkan ke perangkat BLE berdasarkan device ID.
  Future<bool> connect(String deviceId) async {
    if (!PlatformHelper.isBleSupported) {
      AppLogger.warning(_tag, 'BLE tidak didukung di platform ini');
      return false;
    }

    try {
      AppLogger.info(_tag, 'Menghubungkan ke $deviceId...');

      final device = BluetoothDevice.fromId(deviceId);
      await device.connect(timeout: const Duration(seconds: 10));

      _connectedDevice = device;
      AppLogger.info(_tag, 'Terhubung ke ${device.platformName}');

      // Discover services & subscribe ke trigger characteristic
      await _discoverAndSubscribe();

      return true;
    } catch (e) {
      AppLogger.error(_tag, 'Gagal menghubungkan ke $deviceId', e);
      return false;
    }
  }

  /// Discover BLE services dan subscribe ke characteristic trigger.
  Future<void> _discoverAndSubscribe() async {
    if (_connectedDevice == null) return;

    final services = await _connectedDevice!.discoverServices();

    for (final service in services) {
      if (service.uuid.str.toLowerCase() ==
          AppConstants.bleServiceUuid.toLowerCase()) {
        AppLogger.info(_tag, 'Service ditemukan: ${service.uuid}');

        for (final char in service.characteristics) {
          if (char.uuid.str.toLowerCase() ==
              AppConstants.bleTriggerCharUuid.toLowerCase()) {
            AppLogger.info(_tag, 'Characteristic ditemukan: ${char.uuid}');

            // Subscribe ke notifikasi
            await char.setNotifyValue(true);
            _notificationSubscription = char.onValueReceived.listen((value) {
              AppLogger.info(_tag, 'Trigger diterima: $value');
              if (value.isNotEmpty) {
                _triggerController.add(value[0]);
              }
            });

            AppLogger.info(_tag, 'Subscribed ke trigger notifications');
            return;
          }
        }
      }
    }

    AppLogger.warning(_tag, 'Characteristic trigger tidak ditemukan!');
  }

  // ─── Disconnect ────────────────────────────────────────────

  /// Putuskan koneksi BLE.
  Future<void> disconnect() async {
    try {
      _notificationSubscription?.cancel();
      _notificationSubscription = null;

      await _connectedDevice?.disconnect();
      _connectedDevice = null;

      AppLogger.info(_tag, 'Koneksi diputus');
    } catch (e) {
      AppLogger.error(_tag, 'Error saat disconnect', e);
    }
  }

  /// Bersihkan resource.
  void dispose() {
    _notificationSubscription?.cancel();
    _triggerController.close();
  }
}

