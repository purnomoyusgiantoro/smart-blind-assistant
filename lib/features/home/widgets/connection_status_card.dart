import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/ble_provider.dart';

/// Card yang menampilkan status koneksi BLE.
///
/// Berubah warna berdasarkan status:
/// - Hijau: Terhubung
/// - Kuning: Scanning
/// - Abu-abu: Tidak terhubung
class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BleProvider>(
      builder: (_, ble, _) {
        final isConnected = ble.isConnected;
        final isScanning = ble.isScanning;

        // Tentukan warna dan teks berdasarkan status
        final Color statusColor;
        final String statusText;
        final IconData statusIcon;

        if (isConnected) {
          statusColor = AppTheme.successColor;
          statusText =
              '${AppStrings.bleConnected} — ${ble.connectedDevice?.name ?? ""}';
          statusIcon = Icons.bluetooth_connected;
        } else if (isScanning) {
          statusColor = AppTheme.warningColor;
          statusText = AppStrings.bleScanning;
          statusIcon = Icons.bluetooth_searching;
        } else {
          statusColor = AppTheme.textMuted;
          statusText = AppStrings.bleDisconnected;
          statusIcon = Icons.bluetooth_disabled;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Ikon status
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              // Teks status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perangkat BLE',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Indikator animasi saat scanning
              if (isScanning)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: statusColor,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
