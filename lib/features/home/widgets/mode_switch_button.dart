import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/assistant_provider.dart';

/// Tombol untuk berganti mode asisten.
///
/// Mode berputar secara siklis:
/// General → Autopilot → Obrolan → General → ...
class ModeSwitchButton extends StatelessWidget {
  const ModeSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AssistantProvider>(
      builder: (_, assistant, __) {
        // Ikon berdasarkan mode saat ini
        final IconData modeIcon;
        switch (assistant.mode) {
          case AssistantMode.general:
            modeIcon = Icons.visibility;
          case AssistantMode.autopilot:
            modeIcon = Icons.speed;
          case AssistantMode.obrolan:
            modeIcon = Icons.chat;
        }

        return SizedBox(
          height: 64,
          child: OutlinedButton.icon(
            onPressed: () => assistant.switchMode(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentColor,
              side: BorderSide(
                color: AppTheme.accentColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(modeIcon, size: 22),
            label: Text(
              AppStrings.buttonSwitchMode,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
