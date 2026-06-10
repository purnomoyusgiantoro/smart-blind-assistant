import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/assistant_provider.dart';

/// Tombol besar untuk trigger voice command secara manual.
///
/// Berguna untuk testing tanpa ESP32 atau sebagai
/// trigger darurat di layar. Simulasi tombol 1 (voice command).
class ManualTriggerButton extends StatelessWidget {
  const ManualTriggerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AssistantProvider>(
      builder: (_, assistant, __) {
        final isIdle = assistant.status == AssistantStatus.idle;

        return SizedBox(
          height: 64,
          child: ElevatedButton.icon(
            onPressed: isIdle ? () => assistant.handleActionTrigger(1) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isIdle ? AppTheme.primaryColor : AppTheme.surfaceBg,
              foregroundColor: isIdle ? Colors.black : AppTheme.textMuted,
              disabledBackgroundColor: AppTheme.surfaceBg,
              disabledForegroundColor: AppTheme.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: isIdle ? 4 : 0,
            ),
            icon: Icon(
              isIdle ? Icons.mic : Icons.hourglass_top,
              size: 24,
            ),
            label: Text(
              isIdle
                  ? AppStrings.buttonVoiceCommand
                  : assistant.statusLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
