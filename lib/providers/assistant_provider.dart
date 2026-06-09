import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_strings.dart';
import '../core/utils/logger.dart';
import '../models/ai_response.dart';
import '../models/capture_payload.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

/// Status state machine asisten.
enum AssistantStatus {
  idle,
  capturing,
  uploading,
  processing,
  speaking,
  error,
  navigating, // Kamera aktif dalam mode navigasi
}

/// Mode operasi asisten.
enum AssistantMode {
  capture,   // Ambil gambar + custom prompt → AI
  navigate,  // Kamera selalu nyala, AI auto setiap interval
}

/// Provider utama yang mengorkestrasi seluruh alur kerja.
///
/// 2 Mode:
/// 1. **Capture**: Ambil gambar → kirim prompt custom ke AI → TTS respons
/// 2. **Navigate**: Kamera selalu aktif → AI analisis otomatis setiap interval
class AssistantProvider extends ChangeNotifier {
  static const String _tag = 'AssistantProvider';

  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();
  final SttService _sttService = SttService();

  StreamSubscription<int>? _triggerSubscription;
  Timer? _navigationTimer;

  // ─── State ─────────────────────────────────────────────────

  AssistantStatus _status = AssistantStatus.idle;
  AssistantMode _mode = AssistantMode.capture;
  AiResponse? _lastResponse;
  String? _errorMessage;
  String _customPrompt = '';
  bool _cameraReady = false;
  bool _sttReady = false;
  bool _isRecording = false;
  String _voiceText = '';

  /// Interval navigasi otomatis (dalam detik)
  int _navigationIntervalSeconds = 30;

  /// Status saat ini
  AssistantStatus get status => _status;

  /// Mode saat ini
  AssistantMode get mode => _mode;

  /// Respons AI terakhir
  AiResponse? get lastResponse => _lastResponse;

  /// Pesan error terakhir
  String? get errorMessage => _errorMessage;

  /// Custom prompt dari user
  String get customPrompt => _customPrompt;

  /// Apakah kamera sudah siap
  bool get cameraReady => _cameraReady;

  /// Camera controller untuk preview di UI
  CameraController? get cameraController => _cameraService.controller;

  /// Interval navigasi (detik)
  int get navigationIntervalSeconds => _navigationIntervalSeconds;

  /// Apakah navigasi sedang aktif
  bool get isNavigating => _status == AssistantStatus.navigating;

  /// Apakah STT tersedia
  bool get sttReady => _sttReady;

  /// Apakah sedang merekam suara
  bool get isRecording => _isRecording;

  /// Teks dari suara yang direkam
  String get voiceText => _voiceText;

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
      case AssistantStatus.navigating:
        return AppStrings.statusNavigating;
    }
  }

  /// Label mode untuk UI
  String get modeLabel {
    switch (_mode) {
      case AssistantMode.capture:
        return AppStrings.modeCapture;
      case AssistantMode.navigate:
        return AppStrings.modeNavigate;
    }
  }

  /// String mode untuk API prompt
  String get _modeString {
    switch (_mode) {
      case AssistantMode.capture:
        return 'describe';
      case AssistantMode.navigate:
        return 'navigate';
    }
  }

  // ─── Initialize ────────────────────────────────────────────

  /// Inisialisasi semua service.
  Future<void> initialize() async {
    AppLogger.info(_tag, 'Menginisialisasi services...');

    _cameraReady = await _cameraService.initialize();
    _sttReady = await _sttService.initialize();
    await _ttsService.initialize();

    // Ucapkan pesan selamat datang
    await _ttsService.speak(AppStrings.ttsWelcome);

    notifyListeners();
    AppLogger.info(_tag, 'Services siap (kamera: $_cameraReady, stt: $_sttReady)');
  }

  /// Mulai mendengarkan trigger stream dari BLE.
  void listenToTrigger(Stream<int> triggerStream) {
    _triggerSubscription?.cancel();
    _triggerSubscription = triggerStream.listen((triggerValue) {
      AppLogger.info(_tag, 'Trigger diterima: $triggerValue');
      handleActionTrigger();
    });
    AppLogger.info(_tag, 'Listening ke trigger stream');
  }

  /// Handle trigger utama dari hardware (BLE) atau UI
  Future<void> handleActionTrigger() async {
    if (_mode == AssistantMode.capture) {
      if (_isRecording) {
        await stopVoiceInput();
      } else {
        await startVoiceInput();
      }
    } else {
      // Mode navigasi
      if (isNavigating) {
        // Force analisis instan saat navigasi aktif
        executePipeline(promptOverride: 'navigate');
      } else {
        await toggleNavigation();
      }
    }
  }

  // ─── Mode Switch ───────────────────────────────────────────

  /// Ganti mode (toggle antara capture ↔ navigate).
  Future<void> switchMode() async {
    // Hentikan navigasi jika sedang aktif
    if (_status == AssistantStatus.navigating) {
      await stopNavigation();
    }

    if (_mode == AssistantMode.capture) {
      _mode = AssistantMode.navigate;
    } else {
      _mode = AssistantMode.capture;
    }
    notifyListeners();

    // Ucapkan mode baru
    await _ttsService.speak('${AppStrings.modeSwitched} $modeLabel');
    AppLogger.info(_tag, 'Mode diubah ke: $modeLabel');
  }

  // ─── Custom Prompt ────────────────────────────────────────

  /// Set custom prompt dari user.
  void setCustomPrompt(String prompt) {
    _customPrompt = prompt;
    notifyListeners();
  }

  // ─── Voice Input (STT) ────────────────────────────────────

  /// Mulai merekam suara untuk prompt.
  /// Hentikan TTS dulu agar tidak mengganggu microphone.
  Future<void> startVoiceInput() async {
    if (!_sttReady) {
      await _ttsService.speak('Fitur suara tidak tersedia');
      return;
    }

    // Stop TTS dulu agar mic tidak menangkap suara TTS
    await _ttsService.stop();

    _isRecording = true;
    _voiceText = '';
    notifyListeners();

    await _ttsService.speak('Silakan bicara sekarang');
    // Tunggu TTS selesai bicara sebelum mulai listen
    await Future.delayed(const Duration(milliseconds: 1500));

    await _sttService.startListening(
      onResult: (text, isFinal) {
        _voiceText = text;
        notifyListeners();

        if (isFinal) {
          _isRecording = false;
          _customPrompt = text;
          notifyListeners();
          AppLogger.info(_tag, 'Voice prompt: $text');

          // Auto-execute pipeline setelah selesai bicara
          if (text.isNotEmpty) {
            _ttsService.speak('Prompt diterima: $text').then((_) {
              executePipeline();
            });
          } else {
            _ttsService.speak('Menganalisis gambar...').then((_) {
              executePipeline(promptOverride: 'describe');
            });
          }
        }
      },
      localeId: 'id-ID',
    );

    AppLogger.info(_tag, 'Voice input dimulai');
  }

  /// Hentikan merekam suara.
  Future<void> stopVoiceInput() async {
    await _sttService.stopListening();
    _isRecording = false;
    notifyListeners();
    AppLogger.info(_tag, 'Voice input dihentikan');
  }

  /// Toggle voice input.
  Future<void> toggleVoiceInput() async {
    if (_isRecording) {
      await stopVoiceInput();
    } else {
      await startVoiceInput();
    }
  }

  /// Set interval navigasi otomatis.
  void setNavigationInterval(int seconds) {
    _navigationIntervalSeconds = seconds;
    notifyListeners();
    AppLogger.info(_tag, 'Interval navigasi: ${seconds}s');
  }

  // ─── Capture Mode Pipeline ────────────────────────────────

  /// Eksekusi pipeline capture:
  /// Capture → Upload → Process (dengan custom prompt) → Speak
  Future<void> executePipeline({String? promptOverride}) async {
    // Jangan proses jika sedang sibuk (kecuali navigating)
    if (_status != AssistantStatus.idle &&
        _status != AssistantStatus.navigating) {
      AppLogger.warning(_tag, 'Pipeline diabaikan — status: $_status');
      return;
    }

    final wasNavigating = _status == AssistantStatus.navigating;

    try {
      // 1. CAPTURING
      _setStatus(AssistantStatus.capturing);
      if (!wasNavigating) {
        await _ttsService.speak(AppStrings.ttsBleTriggerReceived);
      }

      final imagePath = await _cameraService.captureFrame();
      if (imagePath == null) {
        throw Exception('Gagal mengambil gambar');
      }

      // 2. UPLOADING
      _setStatus(AssistantStatus.uploading);
      if (!wasNavigating) {
        await _ttsService.speak(AppStrings.ttsCaptureSuccess);
      }

      // Tentukan mode prompt
      final String promptMode;
      final String? userPrompt = promptOverride ?? 
          (_customPrompt.isNotEmpty ? _customPrompt : null);

      if (userPrompt != null && userPrompt.isNotEmpty) {
        promptMode = 'custom';
      } else {
        promptMode = _modeString;
      }

      final payload = CapturePayload(
        imagePath: imagePath,
        timestamp: DateTime.now(),
        mode: promptMode,
        customPrompt: userPrompt,
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

      // Kembali ke status sebelumnya
      if (wasNavigating) {
        _setStatus(AssistantStatus.navigating);
      } else {
        _setStatus(AssistantStatus.idle);
      }
      AppLogger.info(_tag, 'Pipeline selesai');
    } catch (e) {
      AppLogger.error(_tag, 'Pipeline error', e);
      _errorMessage = e.toString();
      _setStatus(AssistantStatus.error);

      await _ttsService.speak(AppStrings.ttsError);

      // Kembali ke status sebelumnya setelah error
      await Future.delayed(const Duration(seconds: 2));
      if (wasNavigating) {
        _setStatus(AssistantStatus.navigating);
      } else {
        _setStatus(AssistantStatus.idle);
      }
    }
  }

  // ─── Navigation Mode ─────────────────────────────────────

  /// Mulai mode navigasi: kamera aktif + AI analisis periodik.
  Future<void> startNavigation() async {
    if (!_cameraReady) {
      _cameraReady = await _cameraService.initialize();
      notifyListeners();
    }

    if (!_cameraReady) {
      await _ttsService.speak('Kamera tidak tersedia');
      return;
    }

    _setStatus(AssistantStatus.navigating);
    await _ttsService.speak(AppStrings.ttsNavigationStarted);

    // Mulai timer periodik untuk analisis
    _navigationTimer?.cancel();
    _navigationTimer = Timer.periodic(
      Duration(seconds: _navigationIntervalSeconds),
      (timer) {
        if (_status == AssistantStatus.navigating) {
          AppLogger.info(_tag, 'Navigasi: auto-capture #${timer.tick}');
          executePipeline(promptOverride: 'navigate');
        }
      },
    );

    AppLogger.info(
        _tag, 'Navigasi dimulai (interval: ${_navigationIntervalSeconds}s)');
  }

  /// Hentikan mode navigasi.
  Future<void> stopNavigation() async {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    _setStatus(AssistantStatus.idle);
    await _ttsService.speak(AppStrings.ttsNavigationStopped);
    AppLogger.info(_tag, 'Navigasi dihentikan');
  }

  /// Toggle navigasi (start/stop).
  Future<void> toggleNavigation() async {
    if (_status == AssistantStatus.navigating) {
      await stopNavigation();
    } else {
      await startNavigation();
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
    _navigationTimer?.cancel();
    _cameraService.dispose();
    _ttsService.dispose();
    _sttService.dispose();
    super.dispose();
  }
}
