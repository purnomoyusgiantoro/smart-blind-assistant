import 'package:flutter_tts/flutter_tts.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

/// Level urgensi untuk penyesuaian kecepatan TTS.
enum _UrgencyLevel { danger, caution, normal }

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

      // Reset speech rate ke normal setelah peringatan bahaya selesai
      if (_pendingRateReset) {
        _pendingRateReset = false;
        _tts.setSpeechRate(AppConstants.defaultTtsSpeechRate);
        AppLogger.info(_tag, 'Speech rate direset ke normal');
      }

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

  /// Ucapkan teks dengan deteksi urgensi otomatis.
  ///
  /// Jika teks dimulai dengan "BAHAYA!" → bicara lebih cepat dan keras.
  /// Jika teks dimulai dengan "Hati-hati" → sedikit lebih cepat.
  /// Setelah selesai, kembali ke speech rate normal.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    // Bersihkan karakter markdown agar tidak dibacakan (misal: **, #, _, ~, `)
    final cleanText = text.replaceAll(RegExp(r'[*#_~`]'), '').trim();

    if (_isSpeaking) {
      await stop();
    }

    // Deteksi urgensi dan sesuaikan kecepatan bicara
    final urgency = _detectUrgency(cleanText);
    if (urgency == _UrgencyLevel.danger) {
      await _tts.setSpeechRate(0.65); // Lebih cepat untuk bahaya
      await _tts.setVolume(1.0);
      AppLogger.info(_tag, '⚠️ BAHAYA terdeteksi — kecepatan TTS ditingkatkan');
    } else if (urgency == _UrgencyLevel.caution) {
      await _tts.setSpeechRate(0.55); // Sedikit lebih cepat
      await _tts.setVolume(1.0);
    }
    // Normal: tidak perlu ubah (sudah di rate default)

    AppLogger.info(_tag, 'Mengucapkan: ${cleanText.substring(0, cleanText.length.clamp(0, 50))}...');
    await _tts.speak(cleanText);

    // Kembalikan ke rate normal setelah speak selesai (async, via completion handler)
    if (urgency != _UrgencyLevel.normal) {
      _pendingRateReset = true;
    }
  }

  /// Flag untuk menandai perlu reset speech rate setelah TTS selesai
  bool _pendingRateReset = false;

  /// Deteksi level urgensi dari teks respons AI.
  _UrgencyLevel _detectUrgency(String text) {
    final lower = text.toLowerCase();
    if (lower.startsWith('bahaya')) return _UrgencyLevel.danger;
    if (lower.startsWith('hati-hati') || lower.startsWith('awas')) {
      return _UrgencyLevel.caution;
    }
    return _UrgencyLevel.normal;
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
