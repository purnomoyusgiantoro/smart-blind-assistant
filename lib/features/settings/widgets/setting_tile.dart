import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Widget reusable untuk satu baris pengaturan.
class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Ikon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 14),

            // Teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing (opsional)
            ?trailing,

            // Arrow jika ada onTap tapi tidak ada trailing
            if (trailing == null && onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppTheme.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
