import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import 'widgets/setting_tile.dart';

/// Layar pengaturan aplikasi.
///
/// Memungkinkan pengguna mengubah:
/// - Bahasa TTS
/// - Kecepatan bicara TTS
/// - API Key OpenRouter
/// - Auto-connect BLE
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: Consumer<SettingsProvider>(
        builder: (_, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ─── Bagian TTS ──────────────────────────────
              _buildSectionTitle('Text-to-Speech'),
              const SizedBox(height: 8),

              SettingTile(
                icon: Icons.language,
                title: AppStrings.settingLanguage,
                subtitle: settings.ttsLanguage,
                onTap: () => _showLanguagePicker(context, settings),
              ),

              const SizedBox(height: 8),

              SettingTile(
                icon: Icons.speed,
                title: AppStrings.settingSpeechRate,
                subtitle: '${(settings.ttsSpeechRate * 100).toInt()}%',
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: settings.ttsSpeechRate,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) => settings.setTtsSpeechRate(value),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Bagian API ──────────────────────────────
              _buildSectionTitle('OpenRouter API'),
              const SizedBox(height: 8),

              SettingTile(
                icon: Icons.key,
                title: AppStrings.settingApiKey,
                subtitle: settings.apiKey.isEmpty
                    ? 'Belum diatur'
                    : '${settings.apiKey.substring(0, 8)}••••••',
                onTap: () => _showApiKeyDialog(context, settings),
              ),

              const SizedBox(height: 24),

              // ─── Bagian BLE ──────────────────────────────
              _buildSectionTitle('Bluetooth'),
              const SizedBox(height: 8),

              SettingTile(
                icon: Icons.bluetooth_connected,
                title: AppStrings.settingAutoConnect,
                subtitle: settings.autoConnect
                    ? 'Aktif'
                    : 'Nonaktif',
                trailing: Switch(
                  value: settings.autoConnect,
                  onChanged: (value) => settings.setAutoConnect(value),
                ),
              ),

              const SizedBox(height: 32),

              // ─── Info ────────────────────────────────────
              Center(
                child: Text(
                  '${AppStrings.appName} v1.0.0',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final languages = {
          'id-ID': 'Bahasa Indonesia',
          'en-US': 'English (US)',
        };

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Bahasa TTS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...languages.entries.map((entry) {
                final isSelected = settings.ttsLanguage == entry.key;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textMuted,
                  ),
                  title: Text(entry.value),
                  onTap: () {
                    settings.setTtsLanguage(entry.key);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showApiKeyDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.apiKey);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text('API Key OpenRouter'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'sk-or-...',
              hintStyle: TextStyle(color: AppTheme.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                settings.setApiKey(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
