import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/assistant_provider.dart';

/// Widget compact yang menunjukkan status asisten dan respons terakhir.
class AssistantStatusIndicator extends StatelessWidget {
  const AssistantStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AssistantProvider>(
      builder: (_, assistant, __) {
        final status = assistant.status;

        // Tentukan warna dan ikon berdasarkan status
        final Color statusColor;
        final IconData statusIcon;

        switch (status) {
          case AssistantStatus.idle:
            statusColor = AppTheme.primaryColor;
            statusIcon = Icons.visibility;
          case AssistantStatus.listening:
            statusColor = AppTheme.warningColor;
            statusIcon = Icons.hearing;
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
          case AssistantStatus.autopiloting:
            statusColor = AppTheme.successColor;
            statusIcon = Icons.speed;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status row (compact)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  assistant.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // Respons terakhir (jika ada dan sedang idle/autopiloting)
            if (assistant.lastResponse != null &&
                assistant.lastResponse!.isSuccess &&
                (status == AssistantStatus.idle ||
                    status == AssistantStatus.autopiloting))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    assistant.lastResponse!.description,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
