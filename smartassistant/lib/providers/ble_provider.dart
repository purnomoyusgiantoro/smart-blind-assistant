import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/logger.dart';
import '../models/ble_device.dart';
import '../services/ble_service.dart';

/// Provider untuk state koneksi BLE.
///
/// Mengelola scanning, daftar perangkat, koneksi aktif,
/// dan meneruskan trigger events dari ESP32.
class BleProvider extends ChangeNotifier {
  static const String _tag = 'BleProvider';

  final BleService _bleService = BleService();

  // ─── State ─────────────────────────────────────────────────

  bool _isScanning = false;
  List<BleDevice> _devices = [];
  BleDevice? _connectedDevice;
  StreamSubscription<List<BleDevice>>? _scanSubscription;

  /// Apakah sedang scanning
  bool get isScanning => _isScanning;

  /// Daftar perangkat BLE yang ditemukan
  List<BleDevice> get devices => _devices;

  /// Perangkat yang sedang terhubung
  BleDevice? get connectedDevice => _connectedDevice;

  /// Apakah ada perangkat yang terhubung
  bool get isConnected => _connectedDevice != null;

  /// Stream trigger dari ESP32 (dipakai oleh AssistantProvider)
  Stream<int> get triggerStream => _bleService.triggerStream;

  // ─── Scan ──────────────────────────────────────────────────

  /// Mulai scan perangkat BLE.
  Future<void> startScan() async {
    _isScanning = true;
    _devices = [];
    notifyListeners();

    _scanSubscription = _bleService.startScan().listen((foundDevices) {
      _devices = foundDevices;
      notifyListeners();
    });

    // Auto-stop setelah timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (_isScanning) stopScan();
    });

    AppLogger.info(_tag, 'Scanning dimulai');
  }

  /// Hentikan scan BLE.
  Future<void> stopScan() async {
    _isScanning = false;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    await _bleService.stopScan();
    notifyListeners();

    AppLogger.info(_tag, 'Scanning dihentikan, ${_devices.length} perangkat ditemukan');
  }

  // ─── Connect ───────────────────────────────────────────────

  /// Hubungkan ke perangkat BLE.
  Future<bool> connectToDevice(BleDevice device) async {
    final success = await _bleService.connect(device.id);

    if (success) {
      _connectedDevice = device.copyWith(isConnected: true);
      AppLogger.info(_tag, 'Terhubung ke ${device.name}');
    } else {
      AppLogger.error(_tag, 'Gagal terhubung ke ${device.name}');
    }

    notifyListeners();
    return success;
  }

  /// Putuskan koneksi.
  Future<void> disconnect() async {
    await _bleService.disconnect();
    _connectedDevice = null;
    notifyListeners();
    AppLogger.info(_tag, 'Koneksi diputus');
  }

  // ─── Dispose ───────────────────────────────────────────────

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _bleService.dispose();
    super.dispose();
  }
}
