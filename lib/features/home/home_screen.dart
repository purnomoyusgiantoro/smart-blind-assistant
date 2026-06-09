import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/ble_provider.dart';
import '../../routes/app_router.dart';
import 'widgets/assistant_status_indicator.dart';
import 'widgets/connection_status_card.dart';

/// Layar utama SightAssist.
///
/// Menampilkan:
/// - Preview kamera
/// - Status koneksi BLE
/// - Custom prompt input (mode capture)
/// - Tombol trigger / navigasi
/// - Status asisten
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
  void dispose() {
    super.dispose();
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
        child: Consumer<AssistantProvider>(
          builder: (_, assistant, _) {
            return Column(
              children: [
                // ─── Preview Kamera ──────────────────────────
                Expanded(
                  flex: 3,
                  child: _buildCameraPreview(assistant),
                ),

                // ─── Panel Bawah ─────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status koneksi BLE (compact)
                      const ConnectionStatusCard(),
                      const SizedBox(height: 12),

                      // Status asisten
                      const AssistantStatusIndicator(),
                      const SizedBox(height: 12),

                      // Voice prompt (mode capture)
                      if (assistant.mode == AssistantMode.capture)
                        _buildVoicePrompt(assistant),

                      const SizedBox(height: 12),

                      // Tombol aksi
                      _buildActionButtons(assistant),

                      const SizedBox(height: 8),

                      // Mode label
                      _buildModeLabel(assistant),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build camera preview widget
  Widget _buildCameraPreview(AssistantProvider assistant) {
    final controller = assistant.cameraController;

    if (!assistant.cameraReady || controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off,
                size: 64,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'Kamera belum siap',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        ClipRRect(
          child: CameraPreview(controller),
        ),

        // Navigasi overlay
        if (assistant.isNavigating)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.navigation, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'NAVIGASI AKTIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Status overlay saat processing
        if (assistant.status == AssistantStatus.capturing ||
            assistant.status == AssistantStatus.uploading ||
            assistant.status == AssistantStatus.processing)
          Container(
            color: Colors.black45,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    assistant.statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Build voice prompt section (untuk tunanetra)
  Widget _buildVoicePrompt(AssistantProvider assistant) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: assistant.isRecording
              ? AppTheme.errorColor.withValues(alpha: 0.6)
              : AppTheme.accentColor.withValues(alpha: 0.2),
          width: assistant.isRecording ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Tombol mic + status
          Row(
            children: [
              // Tombol microphone
              GestureDetector(
                onTap: () => assistant.toggleVoiceInput(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: assistant.isRecording
                        ? AppTheme.errorColor
                        : AppTheme.accentColor,
                    boxShadow: assistant.isRecording
                        ? [
                            BoxShadow(
                              color: AppTheme.errorColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    assistant.isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Teks instruksi / hasil
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assistant.isRecording
                          ? 'Mendengarkan...'
                          : 'Tekan mic untuk bicara',
                      style: TextStyle(
                        color: assistant.isRecording
                            ? AppTheme.errorColor
                            : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (assistant.voiceText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '"${assistant.voiceText}"',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else if (assistant.customPrompt.isNotEmpty &&
                        !assistant.isRecording)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Prompt: "${assistant.customPrompt}"',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Recording indicator
              if (assistant.isRecording)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.errorColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(AssistantProvider assistant) {
    final isIdle = assistant.status == AssistantStatus.idle;
    final isNavigating = assistant.isNavigating;

    return Row(
      children: [
        // Tombol Ganti Mode
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => assistant.switchMode(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentColor,
                side: BorderSide(
                  color: AppTheme.accentColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                assistant.mode == AssistantMode.capture
                    ? Icons.camera_alt
                    : Icons.navigation,
                size: 20,
              ),
              label: const Text(
                AppStrings.buttonSwitchMode,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Tombol Utama (tergantung mode)
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 56,
            child: assistant.mode == AssistantMode.capture
                ? _buildCaptureButton(assistant, isIdle)
                : _buildNavigationButton(assistant, isIdle, isNavigating),
          ),
        ),
      ],
    );
  }

  /// Tombol capture (mode ambil gambar)
  Widget _buildCaptureButton(AssistantProvider assistant, bool isIdle) {
    return ElevatedButton.icon(
      onPressed: isIdle ? () => assistant.handleActionTrigger() : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isIdle ? AppTheme.primaryColor : AppTheme.surfaceBg,
        foregroundColor: isIdle ? Colors.black : AppTheme.textMuted,
        disabledBackgroundColor: AppTheme.surfaceBg,
        disabledForegroundColor: AppTheme.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: isIdle ? 4 : 0,
      ),
      icon: Icon(
        isIdle ? Icons.camera_alt : Icons.hourglass_top,
        size: 22,
      ),
      label: Text(
        isIdle ? AppStrings.buttonTrigger : assistant.statusLabel,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Tombol navigasi (mode navigasi)
  Widget _buildNavigationButton(
      AssistantProvider assistant, bool isIdle, bool isNavigating) {
    return ElevatedButton.icon(
      onPressed: (isIdle || isNavigating)
          ? () => assistant.toggleNavigation()
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isNavigating
            ? AppTheme.errorColor
            : (isIdle ? AppTheme.successColor : AppTheme.surfaceBg),
        foregroundColor: (isIdle || isNavigating) ? Colors.white : AppTheme.textMuted,
        disabledBackgroundColor: AppTheme.surfaceBg,
        disabledForegroundColor: AppTheme.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: (isIdle || isNavigating) ? 4 : 0,
      ),
      icon: Icon(
        isNavigating ? Icons.stop : Icons.navigation,
        size: 22,
      ),
      label: Text(
        isNavigating
            ? AppStrings.buttonStopNavigation
            : AppStrings.buttonStartNavigation,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Mode label
  Widget _buildModeLabel(AssistantProvider assistant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        assistant.modeLabel,
        style: TextStyle(
          color: AppTheme.accentColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
