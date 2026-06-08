import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ble_device.dart';
import '../../../providers/ble_provider.dart';

/// Widget satu item perangkat BLE dalam daftar scan.
///
/// Menampilkan nama, ID, kekuatan sinyal (RSSI), dan tombol connect.
class DeviceListTile extends StatelessWidget {
  final BleDevice device;

  const DeviceListTile({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.surfaceBg,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ikon BLE
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bluetooth,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          // Info perangkat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  device.id,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // RSSI badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _rssiColor(device.rssi).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${device.rssi} dBm',
              style: TextStyle(
                color: _rssiColor(device.rssi),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Tombol connect
          Consumer<BleProvider>(
            builder: (_, ble, _) {
              final isThisConnected =
                  ble.connectedDevice?.id == device.id;

              return SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: isThisConnected
                      ? () => ble.disconnect()
                      : () async {
                          final success = await ble.connectToDevice(device);
                          if (success && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isThisConnected
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(isThisConnected ? 'Putus' : 'Hubungkan'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Warna RSSI: hijau (kuat) → kuning (sedang) → merah (lemah).
  Color _rssiColor(int rssi) {
    if (rssi >= -60) return AppTheme.successColor;
    if (rssi >= -80) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
