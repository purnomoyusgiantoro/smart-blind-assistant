import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/logger.dart';
import '../core/utils/time_utils.dart';
import '../models/ai_response.dart';
import '../models/capture_payload.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
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

/// Mode operasi asisten (5 mode).
///
/// Cycle: general → autopilot → navigasi → obrolan → read → general → ...
enum AssistantMode {
  general,    // Ambil gambar + deskripsikan / jawab pertanyaan
  autopilot,  // Kamera selalu nyala, AI auto analisis berkala
  navigasi,   // Navigasi dengan GPS + kamera (tahu lokasi)
  obrolan,    // Ngobrol bebas tanpa gambar (text-only chat)
  read,       // Baca teks pada gambar saja
}

/// Extension untuk metadata mode (label, prompt, isContinuous, next).
extension AssistantModeExtension on AssistantMode {
  /// Label untuk UI & TTS
  String get label {
    switch (this) {
      case AssistantMode.general:
        return AppStrings.modeGeneral;
      case AssistantMode.autopilot:
        return AppStrings.modeAutopilot;
      case AssistantMode.navigasi:
        return AppStrings.modeNavigasi;
      case AssistantMode.obrolan:
        return AppStrings.modeObrolan;
      case AssistantMode.read:
        return AppStrings.modeRead;
    }
  }

  /// String prompt untuk API
  String get promptMode {
    switch (this) {
      case AssistantMode.general:
        return 'general';
      case AssistantMode.autopilot:
        return 'autopilot';
      case AssistantMode.navigasi:
        return 'navigasi';
      case AssistantMode.obrolan:
        return 'obrolan';
      case AssistantMode.read:
        return 'read';
    }
  }

  /// Apakah mode ini memerlukan kamera selalu aktif (continuous)
  bool get isContinuous {
    switch (this) {
      case AssistantMode.autopilot:
        return true;
      default:
        return false;
    }
  }

  /// Mode berikutnya (cycle)
  AssistantMode get next {
    final modes = AssistantMode.values;
    final nextIndex = (index + 1) % modes.length;
    return modes[nextIndex];
  }
}

/// Provider utama yang mengorkestrasi seluruh alur kerja.
///
/// 5 Mode:
/// 1. **General**: Ambil gambar → kirim prompt ke AI → TTS respons
/// 2. **Autopilot**: Kamera selalu aktif → AI analisis otomatis setiap interval
/// 3. **Navigasi**: GPS + Kamera → AI bantu navigasi dengan info lokasi
/// 4. **Obrolan**: Suara → STT → AI text-only → TTS respons (tanpa gambar)
/// 5. **Read**: Ambil gambar → AI baca teks pada gambar → TTS respons
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
  final LocationService _locationService = LocationService();

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
  bool _locationReady = false;
  String _locationDescription = '';
  bool _blockAutoListen = false;

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

  /// Apakah GPS lokasi tersedia
  bool get locationReady => _locationReady;

  /// Deskripsi lokasi terakhir
  String get locationDescription => _locationDescription;

  /// Waktu WIB saat ini (formatted)
  String get currentWibTime => TimeUtils.formatWibTime(null);

  /// Tanggal & waktu WIB saat ini (formatted)
  String get currentWibDateTime => TimeUtils.formatWibDateTime(null);

  /// Label lokasi singkat untuk UI
  String get shortLocationLabel => _locationService.getShortLocationLabel();

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
  String get modeLabel => _mode.label;

  /// String mode untuk API prompt
  String get _modeString => _mode.promptMode;

  // ─── Initialize ────────────────────────────────────────────

  /// Inisialisasi semua service.
  Future<void> initialize() async {
    AppLogger.info(_tag, 'Menginisialisasi services...');

    _cameraReady = await _cameraService.initialize();
    _sttReady = await _sttService.initialize();
    _locationReady = await _locationService.initialize();
    await _ttsService.initialize();
    await _apiService.initialize();

    _ttsService.onSpeechCompleted = _handleTtsCompletion;
    _sttService.onStatusChanged = _handleSttStatus;
    _sttService.onErrorOccurred = _handleSttError;

    // Ucapkan pesan selamat datang
    await _ttsService.speak(AppStrings.ttsWelcome);

    notifyListeners();
    AppLogger.info(_tag, 'Services siap (kamera: $_cameraReady, stt: $_sttReady, lokasi: $_locationReady)');
  }

  /// Mulai mendengarkan trigger stream dari BLE.
  ///
  /// ESP32 mengirim byte command:
  /// - 0x01 (bleCmdVoice): Voice command (STT)
  /// - 0x02 (bleCmdNextMode): Ganti mode (cycle)
  /// - 0x03 (bleCmdStopAll): Hentikan semua proses (Emergency Stop)
  void listenToTrigger(Stream<int> triggerStream) {
    _triggerSubscription?.cancel();
    _triggerSubscription = triggerStream.listen((triggerValue) {
      AppLogger.info(_tag, 'Trigger diterima: 0x${triggerValue.toRadixString(16)}');
      handleActionTrigger(triggerValue);
    });
    AppLogger.info(_tag, 'Listening ke trigger stream');
  }

  /// Handle trigger dari hardware (BLE) atau UI.
  Future<void> handleActionTrigger(int triggerValue) async {
    switch (triggerValue) {
      case AppConstants.bleCmdVoice:
        // Tombol 1: Voice command
        await _handleVoiceTrigger();
        break;
      case AppConstants.bleCmdNextMode:
        // Tombol 2: Switch mode
        await switchMode();
        break;
      case AppConstants.bleCmdStopAll:
        // Tombol 1+2: Emergency stop
        await stopAll();
        break;
      default:
        AppLogger.warning(_tag, 'Trigger tidak dikenal: 0x${triggerValue.toRadixString(16)}');
        await _ttsService.speak(AppStrings.ttsUnknownCommand);
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

  /// Dipanggil ketika TTS selesai berbicara.
  /// Membantu me-restart microphone secara otomatis khusus untuk mode obrolan.
  void _handleTtsCompletion() {
    if (_mode == AssistantMode.obrolan && !_isRecording && _status == AssistantStatus.idle) {
      if (_blockAutoListen) {
        _blockAutoListen = false;
        AppLogger.info(_tag, 'Auto listen diblokir karena stopAll');
        return;
      }
      AppLogger.info(_tag, 'TTS selesai di mode obrolan, mengaktifkan mic otomatis...');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_mode == AssistantMode.obrolan && !_isRecording && _status == AssistantStatus.idle) {
          startVoiceInput(silent: true);
        }
      });
    }
  }

  /// Dipanggil ketika status STT berubah.
  void _handleSttStatus(String status) {
    AppLogger.info(_tag, 'STT Status berubah: $status');
    // Jika STT selesai mendengarkan tapi status internal kita masih merekam,
    // berarti proses mendengarkan terhenti secara otomatis (timeout atau selesai bicara).
    if (status == 'notListening' || status == 'done') {
      if (_isRecording) {
        AppLogger.info(_tag, 'STT terhenti otomatis. Memproses kata terakhir: $_voiceText');
        _isRecording = false;
        _setStatus(AssistantStatus.idle);
        notifyListeners();

        // Panggil penyelesaian input suara
        _onVoiceInputComplete(_voiceText);
      }
    }
  }

  /// Dipanggil ketika terjadi error pada STT.
  void _handleSttError(String errorMsg) {
    AppLogger.error(_tag, 'STT Error terpantau: $errorMsg');
    // Error biasanya akan memicu status perubahan ke 'notListening' / 'done' secara otomatis,
    // tapi jika stuck kita bisa meresetnya ke idle di sini jika statusnya listening.
    if (_isRecording && _status == AssistantStatus.listening) {
      AppLogger.warning(_tag, 'Mereset status listening ke idle karena STT error');
      _isRecording = false;
      _setStatus(AssistantStatus.idle);
      
      if (_voiceText.isNotEmpty) {
        AppLogger.info(_tag, 'Memproses teks parsial sebelum error: $_voiceText');
        _onVoiceInputComplete(_voiceText);
      } else {
        // Jika mode obrolan, kita ingin mic tetap aktif kembali agar user bisa mencoba lagi
        if (_mode == AssistantMode.obrolan) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_mode == AssistantMode.obrolan && !_isRecording && _status == AssistantStatus.idle) {
              startVoiceInput(silent: true);
            }
          });
        }
      }
    }
  }

  // ─── Mode Switch ───────────────────────────────────────────

  /// Ganti mode (cycle ke mode berikutnya).
  Future<void> switchMode() async {
    // Hentikan autopilot jika sedang aktif
    if (_status == AssistantStatus.autopiloting) {
      await stopAutopilot();
    }

    // Hentikan recording jika sedang aktif
    if (_isRecording) {
      await stopVoiceInput();
    }

    // Cycle ke mode berikutnya menggunakan extension
    _mode = _mode.next;
    notifyListeners();

    // Ucapkan mode baru
    if (_mode == AssistantMode.obrolan) {
      await _ttsService.speak(AppStrings.ttsChatMode);
    } else {
      await _ttsService.speak('${AppStrings.modeSwitched} $modeLabel');
    }
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
  Future<void> startVoiceInput({bool silent = false}) async {
    if (!_sttReady) {
      await _ttsService.speak(AppStrings.ttsVoiceNotAvailable);
      return;
    }

    _blockAutoListen = false;

    // Stop TTS dulu agar mic tidak menangkap suara TTS
    await _ttsService.stop();

    _isRecording = true;
    _voiceText = '';
    _setStatus(AssistantStatus.listening);

    if (!silent) {
      await _ttsService.speak(AppStrings.ttsListening);
      // Tunggu TTS selesai bicara sebelum mulai listen
      await Future.delayed(const Duration(milliseconds: 1500));
    } else {
      // Tunggu sebentar agar TTS benar-benar terhenti sebelum mic menyala
      // Ditingkatkan ke 500ms agar audio focus OS benar-benar rilis
      await Future.delayed(const Duration(milliseconds: 500));
    }

    await _sttService.startListening(
      onResult: (text, isFinal) {
        _voiceText = text;
        notifyListeners();

        if (isFinal) {
          _isRecording = false;
          _setStatus(AssistantStatus.idle);
          _customPrompt = text;
          notifyListeners();
          AppLogger.info(_tag, 'Voice prompt: $text');

          // Auto-execute sesuai mode setelah selesai bicara
          _onVoiceInputComplete(text);
        }
      },
      localeId: 'id-ID',
    );

    AppLogger.info(_tag, 'Voice input dimulai (silent: $silent)');
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
          // Kalau sudah aktif, langsung analisis instan jika ada suara, kalau kosong dibatalkan
          if (text.isNotEmpty) {
            await executePipeline(promptOverride: 'autopilot');
          } else {
            _blockAutoListen = true;
            await _ttsService.speak(AppStrings.ttsVoiceCancelled);
          }
        }
        break;

      case AssistantMode.obrolan:
        // Mode obrolan: kirim teks langsung ke AI tanpa gambar
        if (text.isNotEmpty) {
          await _ttsService.speak(AppStrings.ttsAnalyzing);
          await executeChat(text);
        } else {
          _blockAutoListen = true;
          await _ttsService.speak(AppStrings.ttsVoiceMuted);
        }
        break;

      case AssistantMode.navigasi:
        // Mode navigasi: ambil gambar + lokasi GPS → kirim ke AI
        // Default prompt diizinkan jika suara kosong
        if (text.isNotEmpty) {
          await _ttsService.speak(AppStrings.ttsPromptReceived);
        } else {
          await _ttsService.speak(AppStrings.ttsBleTriggerReceived);
        }
        await executeNavigationPipeline(voicePrompt: text);
        break;

      case AssistantMode.read:
        // Mode read: ambil gambar → baca teks saja
        if (text.isNotEmpty) {
          await _ttsService.speak(AppStrings.ttsPromptReceived);
          await executePipeline();
        } else {
          await _ttsService.speak(AppStrings.ttsBleTriggerReceived);
          await executePipeline(promptOverride: 'read');
        }
        break;
    }
  }

  /// Hentikan merekam suara.
  Future<void> stopVoiceInput() async {
    _blockAutoListen = true;
    await _sttService.stopListening();
    
    if (_isRecording) {
      _isRecording = false;
      if (_status == AssistantStatus.listening) {
        _setStatus(AssistantStatus.idle);
      }
      notifyListeners();
      AppLogger.info(_tag, 'Voice input dihentikan manual');

      if (_voiceText.isNotEmpty) {
        AppLogger.info(_tag, 'Memproses teks yang tertangkap sebelum dihentikan: $_voiceText');
        _onVoiceInputComplete(_voiceText);
      }
    }
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

      if (wasAutopiloting) {
        // Mode autopilot: proses secara lokal menggunakan ML Kit
        _setStatus(AssistantStatus.processing);
        
        final options = ObjectDetectorOptions(
          mode: DetectionMode.single,
          classifyObjects: true,
          multipleObjects: true,
        );
        final objectDetector = ObjectDetector(options: options);
        final inputImage = InputImage.fromFilePath(imagePath);
        
        final List<DetectedObject> objects = await objectDetector.processImage(inputImage);
        
        // Kumpulkan label dari objek yang terdeteksi
        final Set<String> detectedLabels = {};
        for (DetectedObject detectedObject in objects) {
          for (Label label in detectedObject.labels) {
            // Filter confidence > 0.5
            if (label.confidence > 0.5) {
              detectedLabels.add(label.text);
            }
          }
        }
        
        objectDetector.close();

        // Jika ada objek terdeteksi, sebutkan
        _setStatus(AssistantStatus.speaking);
        if (detectedLabels.isNotEmpty) {
          // Terjemahkan label sederhana ke bahasa Indonesia jika memungkinkan (secara statis/kasar)
          // Dalam skenario nyata, butuh mapping terjemahan yang lebih baik
          final description = 'Saya melihat: ${detectedLabels.join(', ')}';
          
          // Cek apakah instruction/prompt pengguna terpenuhi (opsional)
          if (_autopilotInstruction.isNotEmpty) {
            final instructionLower = _autopilotInstruction.toLowerCase();
            final matchesInstruction = detectedLabels.any((l) => 
                instructionLower.contains(l.toLowerCase()));
            
            if (matchesInstruction) {
              await _ttsService.speak('Perhatian! $_autopilotInstruction terdeteksi: ${detectedLabels.join(', ')}');
            } else {
              await _ttsService.speak(description);
            }
          } else {
            await _ttsService.speak(description);
          }
        } else {
          // Jika tidak ada yang penting, tetap diam di mode autopilot agar tidak berisik
          AppLogger.info(_tag, 'Tidak ada objek signifikan terdeteksi oleh ML Kit');
        }

      } else {
        // Mode general: kirim ke OpenRouter API
        // 2. UPLOADING
        _setStatus(AssistantStatus.uploading);
        // User requested to remove the "gambar sedang diproses" (ttsCaptureSuccess) voice feedback
        // await _ttsService.speak(AppStrings.ttsCaptureSuccess);

        final String promptMode;
        final String? effectivePrompt;

        if (promptOverride != null) {
          promptMode = promptOverride;
          effectivePrompt = _customPrompt.isNotEmpty ? _customPrompt : null;
        } else {
          if (_customPrompt.isNotEmpty) {
            promptMode = 'custom';
            effectivePrompt = _customPrompt;
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
      }

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
  // ─── Navigation Pipeline ──────────────────────────────────────

  /// Eksekusi pipeline navigasi:
  /// Ambil lokasi GPS + Capture gambar → Upload → Process → Speak
  Future<void> executeNavigationPipeline({String voicePrompt = ''}) async {
    if (_status != AssistantStatus.idle &&
        _status != AssistantStatus.listening) {
      AppLogger.warning(_tag, 'Navigasi diabaikan — status: $_status');
      return;
    }

    try {
      // 1. GET LOCATION
      _setStatus(AssistantStatus.processing); // Pakai status processing sementara untuk lokasi
      
      // Ambil lokasi
      final locationText = await _locationService.getLocationDescription();
      _locationDescription = locationText;
      
      if (!_locationReady || locationText == 'Lokasi tidak tersedia') {
        await _ttsService.speak(AppStrings.ttsNavigasiLocationFailed);
      }

      // 2. CAPTURING IMAGE
      _setStatus(AssistantStatus.capturing);
      
      final imagePath = await _cameraService.captureFrame();
      if (imagePath == null) {
        throw Exception('Gagal mengambil gambar');
      }

      // 3. UPLOADING & PROCESSING
      _setStatus(AssistantStatus.uploading);
      
      final payload = CapturePayload(
        imagePath: imagePath,
        timestamp: DateTime.now(),
        mode: 'navigasi',
        customPrompt: voicePrompt.isNotEmpty ? voicePrompt : null,
        locationInfo: locationText,
      );

      _setStatus(AssistantStatus.processing);
      final response = await _apiService.analyzeImage(payload);
      _lastResponse = response;

      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'AI error');
      }

      // 4. SPEAKING
      _setStatus(AssistantStatus.speaking);
      await _ttsService.speak(response.description);

      _setStatus(AssistantStatus.idle);
      AppLogger.info(_tag, 'Navigasi pipeline selesai');
    } catch (e) {
      AppLogger.error(_tag, 'Navigasi pipeline error', e);
      _errorMessage = e.toString();
      _setStatus(AssistantStatus.error);

      await _ttsService.speak(AppStrings.ttsError);

      await Future.delayed(const Duration(seconds: 2));
      _setStatus(AssistantStatus.idle);
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

      // Set to idle immediately so completion handler can restart the mic once speaking is done
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

  // ─── Stop All ──────────────────────────────────────────────

  /// Hentikan semua proses aktif (emergency stop).
  ///
  /// Menghentikan autopilot, STT, TTS, dan reset ke idle.
  Future<void> stopAll() async {
    _autopilotTimer?.cancel();
    _autopilotTimer = null;
    await _sttService.stopListening();
    await _ttsService.stop();
    _isRecording = false;
    _blockAutoListen = true;
    _setStatus(AssistantStatus.idle);
    await _ttsService.speak(AppStrings.ttsStopAll);
    AppLogger.info(_tag, 'Semua proses dihentikan');
  }

  // ─── Dispose ───────────────────────────────────────────────

  @override
  void dispose() {
    stopAll();
    _triggerSubscription?.cancel();
    _cameraService.dispose();
    _ttsService.dispose();
    _sttService.dispose();
    _locationService.dispose();
    super.dispose();
  }
}
