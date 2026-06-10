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
  listening,     // Sedang mendengarkan suara user (STT aktif)
  capturing,
  uploading,
  processing,
  speaking,
  error,
  autopiloting,  // Kamera aktif dalam mode autopilot
}

/// Mode operasi asisten (3 mode).
///
/// Cycle: general → autopilot → obrolan → general → ...
enum AssistantMode {
  general,    // Ambil gambar + deskripsikan / jawab pertanyaan
  autopilot,  // Kamera selalu nyala, AI auto analisis berkala
  obrolan,    // Ngobrol bebas tanpa gambar (text-only chat)
}

/// Provider utama yang mengorkestrasi seluruh alur kerja.
///
/// 3 Mode:
/// 1. **General**: Ambil gambar → kirim prompt ke AI → TTS respons
/// 2. **Autopilot**: Kamera selalu aktif → AI analisis otomatis setiap interval
/// 3. **Obrolan**: Suara → STT → AI text-only → TTS respons (tanpa gambar)
///
/// 2 Tombol ESP:
/// - Tombol 1 (trigger=1): Perintah suara (STT)
/// - Tombol 2 (trigger=2): Ganti mode (cycle)
class AssistantProvider extends ChangeNotifier {
  static const String _tag = 'AssistantProvider';

  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();
  final SttService _sttService = SttService();

  StreamSubscription<int>? _triggerSubscription;
  Timer? _autopilotTimer;

  // ─── State ─────────────────────────────────────────────────

  AssistantStatus _status = AssistantStatus.idle;
  AssistantMode _mode = AssistantMode.general;
  AiResponse? _lastResponse;
  String? _errorMessage;
  String _customPrompt = '';
  bool _cameraReady = false;
  bool _sttReady = false;
  bool _isRecording = false;
  String _voiceText = '';

  /// Instruksi persisten untuk mode autopilot.
  /// Perintah ini melekat sampai user mengubahnya.
  /// Contoh: "beritahu kalau ada orang", "kalau ada mobil putih kasih tahu"
  String _autopilotInstruction = '';

  /// Interval autopilot otomatis (dalam detik)
  int _autopilotIntervalSeconds = 30;

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

  /// Interval autopilot (detik)
  int get autopilotIntervalSeconds => _autopilotIntervalSeconds;

  /// Apakah autopilot sedang aktif
  bool get isAutopiloting => _status == AssistantStatus.autopiloting;

  /// Apakah STT tersedia
  bool get sttReady => _sttReady;

  /// Apakah sedang merekam suara
  bool get isRecording => _isRecording;

  /// Teks dari suara yang direkam
  String get voiceText => _voiceText;

  /// Instruksi autopilot persisten (melekat sampai diubah)
  String get autopilotInstruction => _autopilotInstruction;

  /// Label status untuk UI
  String get statusLabel {
    switch (_status) {
      case AssistantStatus.idle:
        return AppStrings.statusIdle;
      case AssistantStatus.listening:
        return AppStrings.statusListening;
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
      case AssistantStatus.autopiloting:
        return AppStrings.statusAutopiloting;
    }
  }

  /// Label mode untuk UI
  String get modeLabel {
    switch (_mode) {
      case AssistantMode.general:
        return AppStrings.modeGeneral;
      case AssistantMode.autopilot:
        return AppStrings.modeAutopilot;
      case AssistantMode.obrolan:
        return AppStrings.modeObrolan;
    }
  }

  /// String mode untuk API prompt
  String get _modeString {
    switch (_mode) {
      case AssistantMode.general:
        return 'general';
      case AssistantMode.autopilot:
        return 'autopilot';
      case AssistantMode.obrolan:
        return 'obrolan';
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
  ///
  /// ESP32 mengirim nilai berbeda untuk masing-masing tombol:
  /// - triggerValue == 1 → Tombol voice (STT)
  /// - triggerValue == 2 → Tombol switch mode
  void listenToTrigger(Stream<int> triggerStream) {
    _triggerSubscription?.cancel();
    _triggerSubscription = triggerStream.listen((triggerValue) {
      AppLogger.info(_tag, 'Trigger diterima: $triggerValue');
      handleActionTrigger(triggerValue);
    });
    AppLogger.info(_tag, 'Listening ke trigger stream');
  }

  /// Handle trigger dari hardware (BLE) atau UI.
  ///
  /// [triggerValue] menentukan aksi:
  /// - 1 = Tombol voice command (mulai/stop STT)
  /// - 2 = Tombol switch mode (cycle mode)
  Future<void> handleActionTrigger(int triggerValue) async {
    switch (triggerValue) {
      case 1:
        // Tombol 1: Voice command
        await _handleVoiceTrigger();
        break;
      case 2:
        // Tombol 2: Switch mode
        await switchMode();
        break;
      default:
        AppLogger.warning(_tag, 'Trigger tidak dikenal: $triggerValue');
    }
  }

  /// Handle tombol voice: mulai/stop recording suara.
  Future<void> _handleVoiceTrigger() async {
    if (_isRecording) {
      await stopVoiceInput();
    } else {
      await startVoiceInput();
    }
  }

  // ─── Mode Switch ───────────────────────────────────────────

  /// Ganti mode (cycle: general → autopilot → obrolan → general).
  Future<void> switchMode() async {
    // Hentikan autopilot jika sedang aktif
    if (_status == AssistantStatus.autopiloting) {
      await stopAutopilot();
    }

    // Hentikan recording jika sedang aktif
    if (_isRecording) {
      await stopVoiceInput();
    }

    // Cycle ke mode berikutnya
    switch (_mode) {
      case AssistantMode.general:
        _mode = AssistantMode.autopilot;
        break;
      case AssistantMode.autopilot:
        _mode = AssistantMode.obrolan;
        break;
      case AssistantMode.obrolan:
        _mode = AssistantMode.general;
        break;
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
      await _ttsService.speak(AppStrings.ttsVoiceNotAvailable);
      return;
    }

    // Stop TTS dulu agar mic tidak menangkap suara TTS
    await _ttsService.stop();

    _isRecording = true;
    _voiceText = '';
    _setStatus(AssistantStatus.listening);

    await _ttsService.speak(AppStrings.ttsListening);
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

          // Auto-execute sesuai mode setelah selesai bicara
          _onVoiceInputComplete(text);
        }
      },
      localeId: 'id-ID',
    );

    AppLogger.info(_tag, 'Voice input dimulai');
  }

  /// Dipanggil setelah STT selesai mengenali suara.
  /// Menentukan aksi berdasarkan mode saat ini.
  Future<void> _onVoiceInputComplete(String text) async {
    switch (_mode) {
      case AssistantMode.general:
        // Mode general: ambil gambar + kirim dengan prompt
        if (text.isNotEmpty) {
          await _ttsService.speak(AppStrings.ttsPromptReceived);
          await executePipeline();
        } else {
          await _ttsService.speak(AppStrings.ttsBleTriggerReceived);
          await executePipeline(promptOverride: 'general');
        }
        break;

      case AssistantMode.autopilot:
        // Mode autopilot: perintah suara menjadi instruksi PERSISTEN
        // Instruksi ini akan melekat dan dipakai di setiap auto-capture
        if (text.isNotEmpty) {
          _autopilotInstruction = text;
          notifyListeners();
          await _ttsService.speak(
            'Oke, aku catat. Mulai sekarang aku bakal perhatiin: $text');
          AppLogger.info(_tag, 'Instruksi autopilot diset: $text');
        }
        // Mulai autopilot kalau belum aktif
        if (!isAutopiloting) {
          await startAutopilot();
        } else {
          // Kalau sudah aktif, langsung analisis instan dengan instruksi baru
          await executePipeline(promptOverride: 'autopilot');
        }
        break;

      case AssistantMode.obrolan:
        // Mode obrolan: kirim teks langsung ke AI tanpa gambar
        if (text.isNotEmpty) {
          await _ttsService.speak(AppStrings.ttsAnalyzing);
          await executeChat(text);
        } else {
          await _ttsService.speak('Hmm, aku nggak dengar apa-apa. Coba lagi ya.');
        }
        break;
    }
  }

  /// Hentikan merekam suara.
  Future<void> stopVoiceInput() async {
    await _sttService.stopListening();
    _isRecording = false;
    if (_status == AssistantStatus.listening) {
      _setStatus(AssistantStatus.idle);
    }
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

  /// Set interval autopilot otomatis.
  void setAutopilotInterval(int seconds) {
    _autopilotIntervalSeconds = seconds;
    notifyListeners();
    AppLogger.info(_tag, 'Interval autopilot: ${seconds}s');
  }

  // ─── General & Autopilot Pipeline ─────────────────────────

  /// Eksekusi pipeline dengan gambar:
  /// Capture → Upload → Process (dengan prompt) → Speak
  ///
  /// Digunakan oleh mode General dan Autopilot.
  Future<void> executePipeline({String? promptOverride}) async {
    // Jangan proses jika sedang sibuk (kecuali autopiloting)
    if (_status != AssistantStatus.idle &&
        _status != AssistantStatus.autopiloting &&
        _status != AssistantStatus.listening) {
      AppLogger.warning(_tag, 'Pipeline diabaikan — status: $_status');
      return;
    }

    final wasAutopiloting = _status == AssistantStatus.autopiloting;

    try {
      // 1. CAPTURING
      _setStatus(AssistantStatus.capturing);
      if (!wasAutopiloting) {
        await _ttsService.speak(AppStrings.ttsBleTriggerReceived);
      }

      final imagePath = await _cameraService.captureFrame();
      if (imagePath == null) {
        throw Exception('Gagal mengambil gambar');
      }

      // 2. UPLOADING
      _setStatus(AssistantStatus.uploading);
      if (!wasAutopiloting) {
        await _ttsService.speak(AppStrings.ttsCaptureSuccess);
      }

      // Tentukan mode prompt
      final String promptMode;
      final String? effectivePrompt;

      if (promptOverride == 'autopilot') {
        // Mode autopilot: selalu gunakan instruksi persisten
        promptMode = 'autopilot';
        effectivePrompt = _autopilotInstruction.isNotEmpty
            ? _autopilotInstruction
            : null;
      } else if (promptOverride == 'general') {
        promptMode = 'general';
        effectivePrompt = null;
      } else {
        // Custom prompt dari voice input
        final String? userPrompt = promptOverride ??
            (_customPrompt.isNotEmpty ? _customPrompt : null);
        if (userPrompt != null && userPrompt.isNotEmpty) {
          promptMode = 'custom';
          effectivePrompt = userPrompt;
        } else {
          promptMode = _modeString;
          effectivePrompt = null;
        }
      }

      final payload = CapturePayload(
        imagePath: imagePath,
        timestamp: DateTime.now(),
        mode: promptMode,
        customPrompt: effectivePrompt,
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
      if (wasAutopiloting) {
        _setStatus(AssistantStatus.autopiloting);
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
      if (wasAutopiloting) {
        _setStatus(AssistantStatus.autopiloting);
      } else {
        _setStatus(AssistantStatus.idle);
      }
    }
  }

  // ─── Chat Pipeline (Mode Obrolan) ─────────────────────────

  /// Eksekusi pipeline obrolan (tanpa gambar):
  /// STT text → AI text-only → TTS respons
  ///
  /// Khusus untuk mode Obrolan dimana pengguna
  /// cukup ngobrol lewat suara tanpa perlu capture gambar.
  Future<void> executeChat(String userMessage) async {
    if (_status != AssistantStatus.idle &&
        _status != AssistantStatus.listening) {
      AppLogger.warning(_tag, 'Chat diabaikan — status: $_status');
      return;
    }

    try {
      // 1. PROCESSING
      _setStatus(AssistantStatus.processing);

      final response = await _apiService.sendChat(userMessage);
      _lastResponse = response;

      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'AI error');
      }

      // 2. SPEAKING
      _setStatus(AssistantStatus.speaking);
      await _ttsService.speak(response.description);

      _setStatus(AssistantStatus.idle);
      AppLogger.info(_tag, 'Chat selesai');
    } catch (e) {
      AppLogger.error(_tag, 'Chat error', e);
      _errorMessage = e.toString();
      _setStatus(AssistantStatus.error);

      await _ttsService.speak(AppStrings.ttsError);

      await Future.delayed(const Duration(seconds: 2));
      _setStatus(AssistantStatus.idle);
    }
  }

  // ─── Autopilot Mode ───────────────────────────────────────

  /// Mulai mode autopilot: kamera aktif + AI analisis periodik.
  Future<void> startAutopilot() async {
    if (!_cameraReady) {
      _cameraReady = await _cameraService.initialize();
      notifyListeners();
    }

    if (!_cameraReady) {
      await _ttsService.speak('Kamera belum siap nih.');
      return;
    }

    _setStatus(AssistantStatus.autopiloting);
    if (_autopilotInstruction.isNotEmpty) {
      await _ttsService.speak(
        '${AppStrings.ttsAutopilotStarted} Aku bakal terus perhatiin: $_autopilotInstruction');
    } else {
      await _ttsService.speak(AppStrings.ttsAutopilotStarted);
    }

    // Mulai timer periodik untuk analisis
    _autopilotTimer?.cancel();
    _autopilotTimer = Timer.periodic(
      Duration(seconds: _autopilotIntervalSeconds),
      (timer) {
        if (_status == AssistantStatus.autopiloting) {
          AppLogger.info(_tag, 'Autopilot: auto-capture #${timer.tick}');
          executePipeline(promptOverride: 'autopilot');
        }
      },
    );

    AppLogger.info(
        _tag, 'Autopilot dimulai (interval: ${_autopilotIntervalSeconds}s)');
  }

  /// Hentikan mode autopilot.
  Future<void> stopAutopilot() async {
    _autopilotTimer?.cancel();
    _autopilotTimer = null;
    _setStatus(AssistantStatus.idle);
    await _ttsService.speak(AppStrings.ttsAutopilotStopped);
    AppLogger.info(_tag, 'Autopilot dihentikan');
  }

  /// Toggle autopilot (start/stop).
  Future<void> toggleAutopilot() async {
    if (_status == AssistantStatus.autopiloting) {
      await stopAutopilot();
    } else {
      await startAutopilot();
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
    _autopilotTimer?.cancel();
    _cameraService.dispose();
    _ttsService.dispose();
    _sttService.dispose();
    super.dispose();
  }
}
