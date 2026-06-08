import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/app_strings.dart';
import '../core/utils/logger.dart';
import '../models/ai_response.dart';
import '../models/capture_payload.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/tts_service.dart';

/// Status state machine asisten.
enum AssistantStatus {
  idle,
  capturing,
  uploading,
  processing,
  speaking,
  error,
}

/// Mode operasi asisten.
enum AssistantMode {
  describe, // Deskripsi lingkungan
  read,     // Baca teks
  navigate, // Navigasi
}

/// Provider utama yang mengorkestrasi seluruh alur kerja.
///
/// State machine:
/// IDLE → CAPTURING → UPLOADING → PROCESSING → SPEAKING → IDLE
///
/// Mendengarkan trigger dari BLE dan menjalankan:
/// 1. Capture gambar dari kamera
/// 2. Kirim ke OpenRouter API
/// 3. Terima respons AI
/// 4. Bacakan dengan TTS
class AssistantProvider extends ChangeNotifier {
  static const String _tag = 'AssistantProvider';

  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();

  StreamSubscription<int>? _triggerSubscription;

  // ─── State ─────────────────────────────────────────────────

  AssistantStatus _status = AssistantStatus.idle;
  AssistantMode _mode = AssistantMode.describe;
  AiResponse? _lastResponse;
  String? _errorMessage;

  /// Status saat ini
  AssistantStatus get status => _status;

  /// Mode saat ini
  AssistantMode get mode => _mode;

  /// Respons AI terakhir
  AiResponse? get lastResponse => _lastResponse;

  /// Pesan error terakhir
  String? get errorMessage => _errorMessage;

  /// Label status untuk UI
  String get statusLabel {
    switch (_status) {
      case AssistantStatus.idle:
        return AppStrings.statusIdle;
      case AssistantStatus.capturing:
        return AppStrings.statusCapturing;
      case AssistantStatus.uploading:
        return AppStrings.statusUploading;
      case AssistantStatus.processing:
        return AppStrings.statusProcessing;
      case AssistantStatus.speaking:
        return AppStrings.statusSpeaking;
      case AssistantStatus.error:
        return _errorMessage ?? AppStrings.statusError;
    }
  }

  /// Label mode untuk UI
  String get modeLabel {
    switch (_mode) {
      case AssistantMode.describe:
        return AppStrings.modeDescribe;
      case AssistantMode.read:
        return AppStrings.modeRead;
      case AssistantMode.navigate:
        return AppStrings.modeNavigate;
    }
  }

  /// String mode untuk API prompt
  String get _modeString {
    switch (_mode) {
      case AssistantMode.describe:
        return 'describe';
      case AssistantMode.read:
        return 'read';
      case AssistantMode.navigate:
        return 'navigate';
    }
  }

  // ─── Initialize ────────────────────────────────────────────

  /// Inisialisasi semua service.
  Future<void> initialize() async {
    AppLogger.info(_tag, 'Menginisialisasi services...');

    await _cameraService.initialize();
    await _ttsService.initialize();

    // Ucapkan pesan selamat datang
    await _ttsService.speak(AppStrings.ttsWelcome);

    AppLogger.info(_tag, 'Services siap');
  }

  /// Mulai mendengarkan trigger stream dari BLE.
  void listenToTrigger(Stream<int> triggerStream) {
    _triggerSubscription?.cancel();
    _triggerSubscription = triggerStream.listen((triggerValue) {
      AppLogger.info(_tag, 'Trigger diterima: $triggerValue');
      executePipeline();
    });
    AppLogger.info(_tag, 'Listening ke trigger stream');
  }

  // ─── Mode Switch ───────────────────────────────────────────

  /// Ganti mode ke mode berikutnya (cycle: describe → read → navigate).
  Future<void> switchMode() async {
    final modes = AssistantMode.values;
    final nextIndex = (_mode.index + 1) % modes.length;
    _mode = modes[nextIndex];
    notifyListeners();

    // Ucapkan mode baru
    await _ttsService.speak('${AppStrings.modeSwitched} $modeLabel');
    AppLogger.info(_tag, 'Mode diubah ke: $modeLabel');
  }

  // ─── Core Pipeline ────────────────────────────────────────

  /// Eksekusi pipeline utama:
  /// Capture → Upload → Process → Speak
  Future<void> executePipeline() async {
    // Jangan proses jika sedang sibuk
    if (_status != AssistantStatus.idle) {
      AppLogger.warning(_tag, 'Pipeline diabaikan — status: $_status');
      return;
    }

    try {
      // 1. CAPTURING
      _setStatus(AssistantStatus.capturing);
      await _ttsService.speak(AppStrings.ttsBleTriggerReceived);

      final imagePath = await _cameraService.captureFrame();
      if (imagePath == null) {
        throw Exception('Gagal mengambil gambar');
      }

      // 2. UPLOADING
      _setStatus(AssistantStatus.uploading);
      await _ttsService.speak(AppStrings.ttsCaptureSuccess);

      final payload = CapturePayload(
        imagePath: imagePath,
        timestamp: DateTime.now(),
        mode: _modeString,
      );

      // 3. PROCESSING
      _setStatus(AssistantStatus.processing);
      final response = await _apiService.analyzeImage(payload);
      _lastResponse = response;

      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'AI error');
      }

      // 4. SPEAKING
      _setStatus(AssistantStatus.speaking);
      await _ttsService.speak(response.description);

      // Kembali ke IDLE
      _setStatus(AssistantStatus.idle);
      AppLogger.info(_tag, 'Pipeline selesai');
    } catch (e) {
      AppLogger.error(_tag, 'Pipeline error', e);
      _errorMessage = e.toString();
      _setStatus(AssistantStatus.error);

      await _ttsService.speak(AppStrings.ttsError);

      // Kembali ke idle setelah error
      await Future.delayed(const Duration(seconds: 2));
      _setStatus(AssistantStatus.idle);
    }
  }

  /// Update status dan notify listeners.
  void _setStatus(AssistantStatus newStatus) {
    _status = newStatus;
    notifyListeners();
    AppLogger.info(_tag, 'Status: $newStatus');
  }

  // ─── API Key ───────────────────────────────────────────────

  /// Update API key OpenRouter.
  void updateApiKey(String key) {
    _apiService.setApiKey(key);
  }

  // ─── Dispose ───────────────────────────────────────────────

  @override
  void dispose() {
    _triggerSubscription?.cancel();
    _cameraService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
