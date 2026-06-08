import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';

/// Layar riwayat interaksi (opsional / untuk debugging).
///
/// Menampilkan log interaksi: timestamp, mode, respons AI.
class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.logTitle),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Riwayat interaksi akan muncul di sini',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
