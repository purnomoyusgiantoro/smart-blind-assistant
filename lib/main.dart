import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/utils/logger.dart';
import 'providers/assistant_provider.dart';
import 'providers/ble_provider.dart';
import 'providers/settings_provider.dart';
import 'services/background_service.dart';

/// Entry point aplikasi SightAssist.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kunci orientasi ke portrait (karena app ini headless/minimal UI)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Inisialisasi background service
  await BackgroundService.initialize();

  // Muat pengaturan user
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  AppLogger.info('Main', 'SightAssist dimulai');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleProvider()),
        ChangeNotifierProvider(create: (_) => AssistantProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const SightAssistApp(),
    ),
  );
}
