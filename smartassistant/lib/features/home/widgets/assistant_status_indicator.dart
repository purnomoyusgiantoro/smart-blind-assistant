import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/assistant_provider.dart';

/// Widget animasi yang menunjukkan status asisten saat ini.
///
/// Menampilkan lingkaran besar di tengah layar dengan:
/// - Animasi pulse saat idle (siap)
/// - Animasi berputar saat capturing/uploading/processing
/// - Animasi berbicara saat speaking
/// - Warna merah saat error
class AssistantStatusIndicator extends StatefulWidget {
  const AssistantStatusIndicator({super.key});

  @override
  State<AssistantStatusIndicator> createState() =>
      _AssistantStatusIndicatorState();
}

class _AssistantStatusIndicatorState extends State<AssistantStatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    // Animasi pulse (idle)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Animasi rotate (processing)
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssistantProvider>(
      builder: (_, assistant, _) {
        final status = assistant.status;

        // Tentukan warna berdasarkan status
        final Color statusColor;
        final IconData statusIcon;

        switch (status) {
          case AssistantStatus.idle:
            statusColor = AppTheme.primaryColor;
            statusIcon = Icons.visibility;
          case AssistantStatus.capturing:
            statusColor = AppTheme.warningColor;
            statusIcon = Icons.camera_alt;
          case AssistantStatus.uploading:
            statusColor = AppTheme.accentColor;
            statusIcon = Icons.cloud_upload;
          case AssistantStatus.processing:
            statusColor = AppTheme.secondaryColor;
            statusIcon = Icons.psychology;
          case AssistantStatus.speaking:
            statusColor = AppTheme.successColor;
            statusIcon = Icons.volume_up;
          case AssistantStatus.error:
            statusColor = AppTheme.errorColor;
            statusIcon = Icons.error_outline;
        }

        final isProcessing = status == AssistantStatus.capturing ||
            status == AssistantStatus.uploading ||
            status == AssistantStatus.processing;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lingkaran utama dengan animasi
            AnimatedBuilder(
              animation: isProcessing ? _rotateController : _pulseController,
              builder: (context, child) {
                final scale = status == AssistantStatus.idle
                    ? 1.0 + (_pulseController.value * 0.08)
                    : 1.0;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress indicator saat processing
                        if (isProcessing)
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: statusColor.withValues(alpha: 0.6),
                            ),
                          ),

                        // Ikon di tengah
                        Icon(
                          statusIcon,
                          size: 56,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Label status
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                assistant.statusLabel,
                key: ValueKey(assistant.statusLabel),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Respons terakhir (jika ada)
            if (assistant.lastResponse != null &&
                assistant.lastResponse!.isSuccess &&
                status == AssistantStatus.idle)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  assistant.lastResponse!.description,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
