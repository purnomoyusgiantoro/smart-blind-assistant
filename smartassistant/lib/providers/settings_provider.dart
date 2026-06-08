import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

/// Provider untuk pengaturan pengguna.
///
/// Menyimpan preferensi ke SharedPreferences agar persisten.
class SettingsProvider extends ChangeNotifier {
  static const String _tag = 'SettingsProvider';

  // ─── Keys ──────────────────────────────────────────────────
  static const String _keyTtsLanguage = 'tts_language';
  static const String _keyTtsSpeechRate = 'tts_speech_rate';
  static const String _keyApiKey = 'api_key';
  static const String _keyAutoConnect = 'auto_connect';

  // ─── State ─────────────────────────────────────────────────
  String _ttsLanguage = AppConstants.defaultTtsLanguage;
  double _ttsSpeechRate = AppConstants.defaultTtsSpeechRate;
  String _apiKey = AppConstants.openRouterApiKey;
  bool _autoConnect = false;

  String get ttsLanguage => _ttsLanguage;
  double get ttsSpeechRate => _ttsSpeechRate;
  String get apiKey => _apiKey;
  bool get autoConnect => _autoConnect;

  // ─── Load ──────────────────────────────────────────────────

  /// Memuat pengaturan dari SharedPreferences.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _ttsLanguage = prefs.getString(_keyTtsLanguage) ?? _ttsLanguage;
    _ttsSpeechRate = prefs.getDouble(_keyTtsSpeechRate) ?? _ttsSpeechRate;
    _apiKey = prefs.getString(_keyApiKey) ?? _apiKey;
    _autoConnect = prefs.getBool(_keyAutoConnect) ?? _autoConnect;

    notifyListeners();
    AppLogger.info(_tag, 'Pengaturan dimuat');
  }

  // ─── Setters ───────────────────────────────────────────────

  Future<void> setTtsLanguage(String language) async {
    _ttsLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTtsLanguage, language);
    notifyListeners();
  }

  Future<void> setTtsSpeechRate(double rate) async {
    _ttsSpeechRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTtsSpeechRate, rate);
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, key);
    notifyListeners();
    AppLogger.info(_tag, 'API key disimpan');
  }

  Future<void> setAutoConnect(bool value) async {
    _autoConnect = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoConnect, value);
    notifyListeners();
  }
}
