import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
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

  /// Mendapatkan system prompt berdasarkan mode.
  ///
  /// Prompt ditulis dengan gaya santai dan natural agar
  /// agent tidak terkesan kaku saat bicara via TTS.
  String _getSystemPrompt(String mode, {String? customPrompt}) {
    switch (mode) {
      case 'general':
        return '''Kamu adalah teman yang membantu seseorang yang tunanetra melihat dunia.
Ceritakan apa yang kamu lihat di gambar ini dengan santai dan jelas.
Kalau ada sesuatu yang berbahaya seperti tangga, kendaraan, atau lubang, langsung bilang duluan ya.
Sebutkan juga kalau ada teks atau tulisan yang terlihat.
Jawab pakai bahasa Indonesia sehari-hari, maksimal 3 kalimat.''';

      case 'autopilot':
        final basePrompt = '''Kamu lagi nemenin teman tunanetra jalan-jalan dan harus terus pantau jalurnya.
Fokus ke keselamatan: sebutkan rintangan, tangga, kendaraan, atau bahaya apa pun.
Kasih instruksi singkat dan jelas kayak "Lurus aman", "Hati-hati ada tangga di depan", "Belok kiri sedikit".
Maksimal 2 kalimat aja, yang penting cepet dan jelas.''';

        if (customPrompt != null && customPrompt.isNotEmpty) {
          return '''$basePrompt

PENTING — Pengguna juga minta kamu perhatiin hal ini secara khusus: "$customPrompt"
Kalau kamu melihat hal yang diminta pengguna di gambar, SELALU laporkan itu duluan.
Contoh: kalau pengguna bilang "beritahu kalau ada orang", dan kamu lihat ada orang, bilang "Ada orang di depan kamu."
Jangan abaikan instruksi ini, ini sangat penting buat pengguna.''';
        }
        return basePrompt;

      case 'obrolan':
        return '''Kamu adalah asisten pribadi sekaligus teman ngobrol yang asyik untuk seseorang yang tunanetra.
Kamu itu kayak sahabat yang selalu ada — bisa diajak curhat, tanya apa aja, minta saran, atau sekadar ngobrol santai.

Yang bisa kamu bantu:
- Jawab pertanyaan apa aja (pengetahuan umum, sains, sejarah, dll)
- Kasih saran dan solusi kalau pengguna lagi ada masalah atau galau
- Bantu hitung, terjemahin, atau jelasin sesuatu
- Jadi teman curhat yang suportif dan pengertian
- Kasih motivasi kalau pengguna lagi down
- Bercanda dan bikin suasana asyik
- Kasih info cuaca, berita, atau hal lain yang ditanyakan

Aturan bicara:
- Pakai bahasa Indonesia sehari-hari, santai kayak ngobrol sama teman dekat
- Jangan kaku atau terlalu formal
- Kalau pertanyaannya lucu, boleh bales lucu juga
- Kalau pengguna lagi sedih atau curhat, dengerin dan kasih respons yang hangat
- Jawaban maksimal 4 kalimat biar nggak kepanjangan
- Kamu boleh nanya balik biar percakapan makin seru''';

      case 'custom':
        return '''Kamu adalah teman yang membantu seseorang yang tunanetra.
Pengguna punya permintaan khusus: ${customPrompt ?? 'Ceritakan apa yang kamu lihat.'}
Jawab sesuai permintaannya pakai bahasa Indonesia sehari-hari, santai tapi jelas.
Jawaban maksimal 3 kalimat.''';

      default:
        return 'Ceritakan apa yang kamu lihat di gambar ini pakai bahasa Indonesia, maksimal 3 kalimat.';
    }
  }

  // ─── Send Image to OpenRouter ──────────────────────────────

  /// Kirim gambar ke OpenRouter API dan dapatkan deskripsi AI.
  ///
  /// Gambar dikonversi ke base64 dan dikirim sebagai bagian dari
  /// multimodal message (image_url dengan data URI).
  Future<AiResponse> analyzeImage(CapturePayload payload) async {
    try {
      AppLogger.info(_tag, 'Mengirim gambar ke OpenRouter (mode: ${payload.mode})...');

      // Baca file gambar dan konversi ke base64
      final imageFile = File(payload.imagePath);
      if (!await imageFile.exists()) {
        return AiResponse.error('File gambar tidak ditemukan');
      }

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Buat request body sesuai format OpenRouter/OpenAI
      final body = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': _getSystemPrompt(payload.mode, customPrompt: payload.customPrompt),
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                },
              },
              {
                'type': 'text',
                'text': payload.customPrompt?.isNotEmpty == true
                    ? payload.customPrompt!
                    : 'Analisis gambar ini.',
              },
            ],
          },
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
    try {
      AppLogger.info(_tag, 'Mengirim chat ke OpenRouter...');

      final body = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': _getSystemPrompt('obrolan'),
          },
          {
            'role': 'user',
            'content': userMessage,
          },
        ],
        'max_tokens': 300,
      });

      final response = await http
          .post(
            Uri.parse(AppConstants.openRouterBaseUrl),
            headers: _buildHeaders(),
            body: body,
          )
          .timeout(Duration(seconds: AppConstants.httpTimeoutSeconds));

      return _parseResponse(response);
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
      return AiResponse.error(
          'Server error: ${response.statusCode}');
    }
  }
}
