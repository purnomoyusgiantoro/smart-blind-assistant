import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/logger.dart';
import '../core/utils/permissions_handler.dart';
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

  /// Status error terakhir (untuk ditampilkan di UI)
  String? _lastError;

  /// Apakah sedang scanning
  bool get isScanning => _isScanning;

  /// Daftar perangkat BLE yang ditemukan
  List<BleDevice> get devices => _devices;

  /// Perangkat yang sedang terhubung
  BleDevice? get connectedDevice => _connectedDevice;

  /// Apakah ada perangkat yang terhubung
  bool get isConnected => _connectedDevice != null;

  /// Error terakhir
  String? get lastError => _lastError;

  /// Stream trigger dari ESP32 (dipakai oleh AssistantProvider)
  Stream<int> get triggerStream => _bleService.triggerStream;

  // ─── Scan ──────────────────────────────────────────────────

  /// Mulai scan perangkat BLE.
  /// Melakukan pengecekan adapter & permission sebelum scan.
  Future<void> startScan() async {
    _lastError = null;

    // 1. Cek permission Bluetooth
    final bleGranted = await AppPermissions.isBluetoothGranted();
    if (!bleGranted) {
      AppLogger.warning(_tag, 'Permission Bluetooth belum diberikan, meminta...');
      final granted = await AppPermissions.requestAll();
      if (!granted) {
        _lastError = 'Izin Bluetooth ditolak. Buka Pengaturan untuk mengizinkan.';
        AppLogger.error(_tag, _lastError!);
        notifyListeners();
        return;
      }
    }

    // 2. Cek adapter state (Bluetooth ON/OFF)
    final adapterOn = await _bleService.isAdapterOn();
    if (!adapterOn) {
      AppLogger.warning(_tag, 'Bluetooth adapter OFF, mencoba menyalakan...');
      await _bleService.turnOnBluetooth();

      // Tunggu sebentar lalu cek lagi
      await Future.delayed(const Duration(seconds: 2));
      final retryOn = await _bleService.isAdapterOn();
      if (!retryOn) {
        _lastError = 'Bluetooth mati. Nyalakan Bluetooth di Pengaturan.';
        AppLogger.error(_tag, _lastError!);
        notifyListeners();
        return;
      }
    }

    // 3. Mulai scan
    _isScanning = true;
    _devices = [];
    notifyListeners();

    AppLogger.info(_tag, 'Semua syarat terpenuhi, mulai scanning...');

    _scanSubscription?.cancel();
    _scanSubscription = _bleService.startScan().listen(
      (foundDevices) {
        _devices = foundDevices;
        AppLogger.info(
            _tag, 'Update: ${foundDevices.length} perangkat ditemukan');
        notifyListeners();
      },
      onError: (error) {
        AppLogger.error(_tag, 'Error saat scanning', error);
        _lastError = 'Error scanning: $error';
        _isScanning = false;
        notifyListeners();
      },
      onDone: () {
        AppLogger.info(_tag, 'Scan stream selesai');
        _isScanning = false;
        notifyListeners();
      },
    );

    // Auto-stop setelah timeout
    Future.delayed(const Duration(seconds: 12), () {
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
