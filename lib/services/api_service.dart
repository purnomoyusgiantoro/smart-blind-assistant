import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../core/utils/time_utils.dart';
import '../models/ai_response.dart';
import '../models/capture_payload.dart';

/// Service untuk komunikasi dengan OpenRouter API.
///
/// Mengirimkan gambar ke Vision Language Model (Gemini)
/// melalui OpenRouter dan mengembalikan deskripsi teks.
/// Juga mendukung mode obrolan (text-only, tanpa gambar).
class ApiService {
  static const String _tag = 'ApiService';

  /// API Key (bisa di-override dari settings)
  String _apiKey = AppConstants.openRouterApiKey;

  /// Model AI yang digunakan
  String _model = AppConstants.aiModel;

  /// Memori riwayat obrolan untuk mode Obrolan
  final List<Map<String, dynamic>> _chatHistory = [];
  bool _historyLoaded = false;

  /// Inisialisasi API service (memuat riwayat chat dari lokal)
  Future<void> initialize() async {
    if (_historyLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString('chat_history');
      if (historyString != null) {
        final List<dynamic> decoded = jsonDecode(historyString);
        _chatHistory.clear();
        for (var item in decoded) {
          _chatHistory.add(Map<String, dynamic>.from(item));
        }
        AppLogger.info(
          _tag,
          'Riwayat chat dimuat: ${_chatHistory.length} pesan',
        );
      }
      _historyLoaded = true;
    } catch (e) {
      AppLogger.error(_tag, 'Gagal memuat riwayat chat', e);
    }
  }

  /// Simpan riwayat chat ke lokal
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_history', jsonEncode(_chatHistory));
    } catch (e) {
      AppLogger.error(_tag, 'Gagal menyimpan riwayat chat', e);
    }
  }

  /// Update API key (dari settings)
  void setApiKey(String key) {
    _apiKey = key;
    AppLogger.info(_tag, 'API key diperbarui');
  }

  /// Update model
  void setModel(String model) {
    _model = model;
    AppLogger.info(_tag, 'Model diubah ke: $model');
  }

  // ─── Prompt Templates ──────────────────────────────────────

  static const String _sinarBasePersona =
      '''Kamu adalah asisten AI bernama "Sinar" untuk membantu tunanetra.
Bahasa: Indonesia. Nada: hangat, jelas, sabar.
Prioritas: keselamatan pengguna.

ATURAN RESPONS:
- SANGAT SINGKAT, maksimal 1-2 kalimat pendek.
- Langsung to the point, TANPA basa-basi, TANPA kata pembuka.
- JANGAN pernah bilang "Saya melihat gambar" atau "Pada gambar ini".
- JANGAN mulai dengan "Baik", "Oke", "Tentu".
- Gunakan arah jam untuk posisi: "rintangan di arah jam 2, sekitar 1 meter".
- Jika gambar tidak jelas, minta foto ulang.''';

  /// Mendapatkan system prompt berdasarkan mode.
  ///
  /// Prompt ditulis dengan gaya santai dan natural agar
  /// agent tidak terkesan kaku saat bicara via TTS.
  String _getSystemPrompt(String mode, {String? customPrompt}) {
    final String base = _sinarBasePersona;

    switch (mode) {
      case 'general':
        return '''$base

TUGAS: Deskripsikan apa yang ada di depan pengguna.
Maksimal 1-2 kalimat. Prioritaskan bahaya/rintangan. Jika ada teks penting, bacakan intinya.''';

      case 'autopilot':
        final autopilotBase = '''$base

TUGAS: Pemantauan jalan. Fokus keselamatan.
Jawab 2-3 kata saja. Contoh: "Aman", "Awas tangga", "Motor di depan".''';

        if (customPrompt != null && customPrompt.isNotEmpty) {
          return '''$autopilotBase

PERHATIAN KHUSUS: Pengguna minta cari "$customPrompt".
Jika terlihat, sebutkan posisinya singkat. Contoh: "Ada di depan", "Di kanan".''';
        }
        return autopilotBase;

      case 'obrolan':
        return '''$base

TUGAS: Jawab pertanyaan pengguna. Singkat dan to the point. Jangan bertele-tele.''';

      case 'custom':
        return '''$base

TUGAS: Jawab HANYA pertanyaan berikut berdasarkan gambar.
Pertanyaan: "${customPrompt ?? 'Apa ini?'}"

ATURAN MUTLAK:
- HANYA jawab pertanyaan di atas, TITIK.
- DILARANG KERAS mendeskripsikan scene/pemandangan/objek lain yang TIDAK ditanyakan.
- Jawab dengan SATU kata atau frasa pendek saja.
- Contoh benar: ditanya "warna baju?" → "Merah". Ditanya "bentuk meja?" → "Persegi".
- Contoh SALAH: "Di depan terlihat seseorang memakai baju merah" ← INI DILARANG.
- Langsung jawab, tanpa penjelasan tambahan.''';

      case 'navigasi':
        final waktuWib = TimeUtils.formatWibTime(null);
        return '''$base

TUGAS: Bantu navigasi. Waktu: $waktuWib.
${customPrompt != null && customPrompt.isNotEmpty ? 'Lokasi: $customPrompt' : ''}
Berikan arahan singkat maksimal 1 kalimat.''';

      case 'read':
        return '''$base

TUGAS: Bacakan teks yang terlihat di gambar. Jika panjang, bacakan intisarinya saja.''';

      default:
        return '''$base

Jawab SANGAT SINGKAT apa yang kamu lihat.''';
    }
  }

  // ─── Send Image to OpenRouter ──────────────────────────────

  /// Kirim gambar ke OpenRouter API dan dapatkan deskripsi AI.
  ///
  /// Gambar dikonversi ke base64 dan dikirim sebagai bagian dari
  /// multimodal message (image_url dengan data URI).
  Future<AiResponse> analyzeImage(CapturePayload payload) async {
    try {
      AppLogger.info(
        _tag,
        'Mengirim gambar ke OpenRouter (mode: ${payload.mode})...',
      );

      // Baca file gambar dan konversi ke base64
      final imageFile = File(payload.imagePath);
      if (!await imageFile.exists()) {
        return AiResponse.error('File gambar tidak ditemukan');
      }

      // Kompresi gambar secara native
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );

      if (compressedBytes == null) {
        return AiResponse.error('Gagal mengompres gambar');
      }

      final base64Image = base64Encode(compressedBytes);

      // Buat user message content
      // Untuk mode custom: pertanyaan user di-embed sebagai instruksi langsung
      // Untuk mode lain: instruksi generik
      final String userText;
      if (payload.mode == 'custom' && payload.customPrompt?.isNotEmpty == true) {
        userText = 'JAWAB PERTANYAAN INI SAJA: ${payload.customPrompt}';
      } else if (payload.customPrompt?.isNotEmpty == true) {
        userText = payload.customPrompt!;
      } else {
        userText = 'Analisis gambar ini.';
      }

      final userContent = <Map<String, dynamic>>[
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
        },
        {
          'type': 'text',
          'text': userText,
        },
      ];

      // Untuk mode navigasi, tambahkan info lokasi
      final String systemPromptCustom;
      if (payload.mode == 'navigasi') {
        systemPromptCustom = payload.locationInfo ?? '';
      } else {
        systemPromptCustom = payload.customPrompt ?? '';
      }

      // Tentukan max_tokens berdasarkan mode
      // Mode custom: jawaban pendek → 100 tokens cukup
      // Mode autopilot: peringatan singkat → 80 tokens
      // Mode lain: deskripsi → 150 tokens (turun dari 300)
      final int maxTokens;
      switch (payload.mode) {
        case 'custom':
          maxTokens = 100;
          break;
        case 'autopilot':
          maxTokens = 80;
          break;
        default:
          maxTokens = 150;
      }

      // Buat request body sesuai format OpenRouter/OpenAI
      final body = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': _getSystemPrompt(
              payload.mode,
              customPrompt: payload.mode == 'navigasi'
                  ? systemPromptCustom
                  : payload.customPrompt,
            ),
          },
          {'role': 'user', 'content': userContent},
        ],
        'max_tokens': maxTokens,
        'temperature': 0.3,
      });

      // Kirim HTTP POST request
      final response = await http
          .post(
            Uri.parse(AppConstants.openRouterBaseUrl),
            headers: _buildHeaders(),
            body: body,
          )
          .timeout(Duration(seconds: AppConstants.httpTimeoutSeconds));

      return _parseResponse(response);
    } catch (e) {
      AppLogger.error(_tag, 'Gagal mengirim ke API', e);
      return AiResponse.error('Gagal menghubungi server: $e');
    }
  }

  // ─── Send Chat (Text-only, tanpa gambar) ───────────────────

  /// Kirim pesan teks ke OpenRouter API tanpa gambar.
  ///
  /// Digunakan di mode obrolan dimana pengguna cukup
  /// bertanya lewat suara tanpa perlu capture kamera.
  Future<AiResponse> sendChat(String userMessage) async {
    if (!_historyLoaded) {
      await initialize();
    }

    try {
      AppLogger.info(_tag, 'Mengirim chat ke OpenRouter...');

      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': _getSystemPrompt('obrolan')},
        ..._chatHistory,
        {'role': 'user', 'content': userMessage},
      ];

      final body = jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 150,
        'temperature': 0.3,
      });

      final response = await http
          .post(
            Uri.parse(AppConstants.openRouterBaseUrl),
            headers: _buildHeaders(),
            body: body,
          )
          .timeout(Duration(seconds: AppConstants.httpTimeoutSeconds));

      final aiResponse = _parseResponse(response);

      // Jika berhasil, simpan ke riwayat
      if (aiResponse.isSuccess) {
        _chatHistory.add({'role': 'user', 'content': userMessage});
        _chatHistory.add({
          'role': 'assistant',
          'content': aiResponse.description,
        });

        // Batasi maksimal 10 pasang (20 pesan)
        if (_chatHistory.length > 20) {
          _chatHistory.removeRange(0, _chatHistory.length - 20);
        }
        _saveChatHistory();
      }

      return aiResponse;
    } catch (e) {
      AppLogger.error(_tag, 'Gagal mengirim chat ke API', e);
      return AiResponse.error('Gagal menghubungi server: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────

  /// Build HTTP headers untuk OpenRouter API.
  Map<String, String> _buildHeaders() {
    return {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://sightassist.app',
      'X-Title': 'SightAssist',
    };
  }

  /// Parse HTTP response dari OpenRouter.
  AiResponse _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final content =
          json['choices']?[0]?['message']?['content'] ?? 'Tidak ada respons';
      final model = json['model'] ?? _model;

      AppLogger.info(_tag, 'Respons diterima dari $model');
      return AiResponse.success(description: content, model: model);
    } else {
      final errorBody = response.body;
      AppLogger.error(_tag, 'API Error ${response.statusCode}: $errorBody');
      return AiResponse.error('Server error: ${response.statusCode}');
    }
  }
}
