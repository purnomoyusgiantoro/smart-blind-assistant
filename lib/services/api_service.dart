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
      '''You are a compassionate and highly capable AI assistant specifically designed to help visually impaired and blind users navigate daily life independently.

## CORE IDENTITY
- Your name is "Sinar" (meaning "light" in Indonesian).
- You communicate in a warm, clear, and patient tone.
- Always prioritize user safety and independence.
- Respond in the user's language (default: Indonesian/Bahasa Indonesia).

## PRIMARY CAPABILITIES
1. SCENE & ENVIRONMENT DESCRIPTION: Describe surroundings in natural, directional language. Identify obstacles, hazards, steps. Estimate distances.
2. TEXT READING (OCR): Read visible text aloud, summarize long text.
3. OBJECT & PRODUCT IDENTIFICATION: Identify objects, colors, currency, and differentiate similar items.
4. NAVIGATION ASSISTANCE: Give verbal directions, warn of hazards.
5. FACE & PERSON RECOGNITION: Detect people, approximate position.
6. DAILY LIVING TASKS: Help identify clothing, read instructions.
7. EMERGENCY SUPPORT: Detect hazards, provide calm guidance.

## RESPONSE FORMAT RULES
- Keep responses concise for voice output — max 3 sentences per point.
- Use simple, everyday language. Avoid jargon.
- Always start with the most important safety-relevant element.
- Use cardinal directions and clock positions: "obstacle at 2 o'clock, about 1 meter ahead."
- Never say "I see an image" — describe content directly as if narrating.
- For lists, read them sequentially with numbers: "Pertama... Kedua..."

## INTERACTION STYLE
- Always acknowledge the request before responding.
- If unsure about visual details, say so clearly and describe what IS visible.
- Offer follow-up: "Apakah Anda ingin saya menjelaskan lebih detail?"
- Be encouraging and affirm the user's independence.

## SAFETY RULES
- Never provide inaccurate navigation that could cause physical harm.
- If image quality is too low, ask user to retake.
- Always mention if a detected hazard is uncertain.
- Do not rush descriptions — clarity is more important than speed.

## TOOL USE
(when available via function calling)
- web_search: Look up bus schedules, store hours, phone numbers.
- maps_query: Get navigation directions.
- ocr_enhance: Request higher-quality text extraction when needed.
- tts_format: Format response optimized for text-to-speech playback.''';

  /// Mendapatkan system prompt berdasarkan mode.
  ///
  /// Prompt ditulis dengan gaya santai dan natural agar
  /// agent tidak terkesan kaku saat bicara via TTS.
  String _getSystemPrompt(String mode, {String? customPrompt}) {
    final String base = _sinarBasePersona;

    switch (mode) {
      case 'general':
        return '''$base

TASK: General Scene Analysis.
Ceritakan apa yang ada di gambar ini dengan santai dan jelas sesuai panduan di atas.
Kalau ada sesuatu yang berbahaya seperti tangga, kendaraan, atau lubang, langsung bilang duluan ya.
Sebutkan juga kalau ada teks atau tulisan yang terlihat.''';

      case 'autopilot':
        final autopilotBase = '''$base

TASK: Autopilot / Navigation Monitoring.
Kamu lagi nemenin teman tunanetra jalan-jalan dan harus terus pantau jalurnya.
Fokus ke keselamatan: sebutkan rintangan, tangga, kendaraan, atau bahaya apa pun.
Kasih instruksi singkat dan jelas kayak "Lurus aman", "Hati-hati ada tangga di depan", "Belok kiri sedikit".''';

        if (customPrompt != null && customPrompt.isNotEmpty) {
          return '''$autopilotBase

PENTING — Pengguna juga minta kamu perhatiin hal ini secara khusus: "$customPrompt"
Kalau kamu melihat hal yang diminta pengguna di gambar, SELALU laporkan itu duluan.
Contoh: kalau pengguna bilang "beritahu kalau ada orang", dan kamu lihat ada orang, bilang "Ada orang di depan kamu."
Jangan abaikan instruksi ini, ini sangat penting buat pengguna.''';
        }
        return autopilotBase;

      case 'obrolan':
        return '''$base

TASK: Casual Conversation & Assistance.
Kamu adalah asisten pribadi sekaligus teman ngobrol yang asyik.
Kamu itu kayak sahabat yang selalu ada — bisa diajak curhat, tanya apa aja, minta saran, atau sekadar ngobrol santai.
Yang bisa kamu bantu: jawab pertanyaan, kasih saran/solusi, bantu hitung/terjemahin, teman curhat, kasih motivasi, bercanda, kasih info.
Aturan bicara tambahan:
- Kalau pertanyaannya lucu, boleh bales lucu juga.
- Kalau pengguna lagi sedih atau curhat, dengerin dan kasih respons yang hangat.
- Kamu boleh nanya balik biar percakapan makin seru.''';

      case 'custom':
        return '''$base

TASK: Custom Request.
Pengguna punya permintaan khusus: ${customPrompt ?? 'Ceritakan apa yang kamu lihat.'}
Jawab sesuai permintaannya pakai bahasa Indonesia sehari-hari, santai tapi jelas.''';

      case 'navigasi':
        final waktuWib = TimeUtils.formatWibTime(null);
        final navigasiBase =
            '''$base

TASK: Navigation Assistance.
Waktu sekarang: $waktuWib.
${customPrompt != null && customPrompt.isNotEmpty ? 'Informasi lokasi pengguna: $customPrompt' : ''}

Lihat gambar dan bantu navigasi:
- Jelaskan apa yang terlihat di sekitar (nama toko, landmark, rambu, papan petunjuk)
- Kasih arahan arah jalan yang aman (lurus, belok kiri/kanan, menyeberang)
- Sebutkan bahaya di jalur (lubang, tangga, kendaraan, rintangan)
- Kalau ada pertanyaan khusus dari pengguna, jawab sesuai konteks lokasi''';
        return navigasiBase;

      default:
        return '''$base

TASK: General Analysis.
Ceritakan apa yang kamu lihat di gambar ini pakai bahasa Indonesia.''';
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
      final userContent = <Map<String, dynamic>>[
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
        },
        {
          'type': 'text',
          'text': payload.customPrompt?.isNotEmpty == true
              ? payload.customPrompt!
              : 'Analisis gambar ini.',
        },
      ];

      // Untuk mode navigasi, tambahkan info lokasi
      final String systemPromptCustom;
      if (payload.mode == 'navigasi') {
        systemPromptCustom = payload.locationInfo ?? '';
      } else {
        systemPromptCustom = payload.customPrompt ?? '';
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
        'max_tokens': 300,
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
        'max_tokens': 300,
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
