import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import 'widgets/device_list_tile.dart';

/// Layar untuk scan dan memilih perangkat BLE (ESP32).
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanTitle),
      ),
      body: Consumer<BleProvider>(
        builder: (context, ble, _) {
          return Column(
            children: [
              // ─── Error Banner ──────────────────────────────
              if (ble.lastError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ble.lastError ?? '',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Tombol Scan ──────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: ble.isScanning
                        ? () => ble.stopScan()
                        : () => ble.startScan(),
                    icon: Icon(
                      ble.isScanning
                          ? Icons.stop
                          : Icons.bluetooth_searching,
                    ),
                    label: Text(
                      ble.isScanning ? 'Hentikan Scan' : AppStrings.bleScanButton,
                    ),
                  ),
                ),
              ),

              // ─── Scanning Indicator ───────────────────────
              if (ble.isScanning)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(),
                ),

              // ─── Daftar Perangkat ─────────────────────────
              Expanded(
                child: ble.devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: 64,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              ble.isScanning
                                  ? AppStrings.bleScanning
                                  : AppStrings.bleNoDevicesFound,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            if (!ble.isScanning) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Pastikan ESP32 menyala dan\nBluetooth + Lokasi aktif',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: ble.devices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return DeviceListTile(device: ble.devices[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
