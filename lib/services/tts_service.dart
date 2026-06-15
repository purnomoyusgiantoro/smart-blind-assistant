import 'package:flutter_tts/flutter_tts.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

/// Service Text-to-Speech (TTS).
///
/// Membacakan teks respons AI kepada pengguna melalui speaker/earphone.
class TtsService {
  static const String _tag = 'TtsService';

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  /// Callback yang dipanggil saat TTS selesai berbicara.
  void Function()? onSpeechCompleted;

  /// Apakah sedang berbicara
  bool get isSpeaking => _isSpeaking;

  // ─── Initialize ────────────────────────────────────────────

  /// Inisialisasi engine TTS dengan pengaturan default.
  Future<void> initialize() async {
    await _tts.setLanguage(AppConstants.defaultTtsLanguage);
    await _tts.setSpeechRate(AppConstants.defaultTtsSpeechRate);
    await _tts.setPitch(AppConstants.defaultTtsPitch);
    await _tts.setVolume(1.0);

    // Callbacks
    _tts.setStartHandler(() {
      _isSpeaking = true;
      AppLogger.info(_tag, 'Mulai berbicara');
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      AppLogger.info(_tag, 'Selesai berbicara');
      if (onSpeechCompleted != null) {
        onSpeechCompleted!();
      }
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      AppLogger.error(_tag, 'TTS Error: $msg');
    });

    AppLogger.info(_tag, 'TTS diinisialisasi (${AppConstants.defaultTtsLanguage})');
  }

  // ─── Speak ─────────────────────────────────────────────────

  /// Ucapkan teks.
  ///
  /// Jika sedang berbicara, hentikan dulu lalu ucapkan teks baru.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    // Bersihkan karakter markdown agar tidak dibacakan (misal: **, #, _, ~, `)
    final cleanText = text.replaceAll(RegExp(r'[*#_~`]'), '').trim();

    if (_isSpeaking) {
      await stop();
    }

    AppLogger.info(_tag, 'Mengucapkan: ${cleanText.substring(0, cleanText.length.clamp(0, 50))}...');
    await _tts.speak(cleanText);
  }

  /// Hentikan pembicaraan yang sedang berlangsung.
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  // ─── Settings ──────────────────────────────────────────────

  /// Ubah bahasa TTS.
  Future<void> setLanguage(String locale) async {
    await _tts.setLanguage(locale);
    AppLogger.info(_tag, 'Bahasa diubah ke: $locale');
  }

  /// Ubah kecepatan bicara (0.0 - 1.0).
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
    AppLogger.info(_tag, 'Kecepatan diubah ke: $rate');
  }

  // ─── Dispose ───────────────────────────────────────────────

  /// Hentikan dan bersihkan resource TTS.
  Future<void> dispose() async {
    await stop();
    AppLogger.info(_tag, 'TTS disposed');
  }
}
