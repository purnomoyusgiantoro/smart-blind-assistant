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
  String _getSystemPrompt(String mode, {String? customPrompt}) {
    switch (mode) {
      case 'describe':
        return '''Kamu adalah asisten visual untuk tunanetra. Tugas kamu:
- Deskripsikan apa yang ada di depan pengguna dengan jelas dan ringkas.
- Sebutkan objek-objek penting, orang, teks, dan rintangan.
- Prioritaskan informasi yang berkaitan dengan keselamatan (tangga, kendaraan, lubang).
- Gunakan bahasa Indonesia yang mudah dipahami.
- Jawaban maksimal 3 kalimat.''';

      case 'read':
        return '''Kamu adalah asisten pembaca teks untuk tunanetra. Tugas kamu:
- Baca semua teks yang terlihat di gambar.
- Jika ada papan nama, label, atau tulisan, bacakan semuanya.
- Gunakan bahasa Indonesia.
- Jika tidak ada teks, katakan "Tidak ada teks yang terlihat."''';

      case 'navigate':
        return '''Kamu adalah asisten navigasi untuk tunanetra. Tugas kamu:
- Analisis jalur di depan pengguna.
- Sebutkan arah yang aman untuk berjalan.
- Peringatkan tentang rintangan, tangga, atau bahaya.
- Gunakan instruksi singkat: "Lurus aman", "Belok kiri", "Hati-hati tangga", dll.
- Jawaban maksimal 2 kalimat.''';

      case 'custom':
        return '''Kamu adalah asisten visual untuk tunanetra. Pengguna memberikan instruksi khusus.
Instruksi pengguna: ${customPrompt ?? 'Deskripsikan gambar ini.'}
- Jawab sesuai instruksi pengguna dalam bahasa Indonesia.
- Jawaban maksimal 3 kalimat.''';

      default:
        return 'Deskripsikan gambar ini dalam bahasa Indonesia, maksimal 3 kalimat.';
    }
  }

  // ─── Send to OpenRouter ────────────────────────────────────

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
                'text': 'Analisis gambar ini.',
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
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://sightassist.app',
              'X-Title': 'SightAssist',
            },
            body: body,
          )
          .timeout(Duration(seconds: AppConstants.httpTimeoutSeconds));

      // Parse response
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
    } catch (e) {
      AppLogger.error(_tag, 'Gagal mengirim ke API', e);
      return AiResponse.error('Gagal menghubungi server: $e');
    }
  }
}
