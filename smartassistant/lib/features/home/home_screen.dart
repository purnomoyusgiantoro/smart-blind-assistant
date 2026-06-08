import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/ble_provider.dart';
import '../../routes/app_router.dart';
import 'widgets/assistant_status_indicator.dart';
import 'widgets/connection_status_card.dart';
import 'widgets/manual_trigger_button.dart';
import 'widgets/mode_switch_button.dart';

/// Layar utama SightAssist.
///
/// Menampilkan:
/// - Status koneksi BLE
/// - Status asisten (idle/capturing/processing/speaking)
/// - Tombol trigger manual
/// - Tombol ganti mode
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Inisialisasi assistant provider setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assistant = context.read<AssistantProvider>();
      assistant.initialize();

      // Subscribe ke BLE trigger jika sudah terhubung
      final ble = context.read<BleProvider>();
      if (ble.isConnected) {
        assistant.listenToTrigger(ble.triggerStream);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          // Tombol scan BLE
          IconButton(
            icon: const Icon(Icons.bluetooth_searching),
            tooltip: AppStrings.bleScanButton,
            onPressed: () => Navigator.pushNamed(context, AppRouter.scan),
          ),
          // Tombol settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.settingsTitle,
            onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ─── Status Koneksi BLE ─────────────────────────
              const ConnectionStatusCard(),

              const SizedBox(height: 24),

              // ─── Status Asisten ─────────────────────────────
              const Expanded(
                child: Center(
                  child: AssistantStatusIndicator(),
                ),
              ),

              const SizedBox(height: 24),

              // ─── 2 Tombol Utama ─────────────────────────────
              Row(
                children: [
                  // Tombol Ganti Mode
                  const Expanded(
                    flex: 2,
                    child: ModeSwitchButton(),
                  ),

                  const SizedBox(width: 16),

                  // Tombol Trigger Utama (lebih besar)
                  const Expanded(
                    flex: 3,
                    child: ManualTriggerButton(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── Mode saat ini ──────────────────────────────
              Consumer<AssistantProvider>(
                builder: (_, assistant, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      assistant.modeLabel,
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
