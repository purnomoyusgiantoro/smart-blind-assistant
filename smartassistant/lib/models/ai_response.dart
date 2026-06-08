/// Model respons dari AI (via OpenRouter API).
class AiResponse {
  /// Teks deskripsi dari AI
  final String description;

  /// Waktu respons diterima
  final DateTime timestamp;

  /// Model yang digunakan
  final String? model;

  /// Apakah respons berhasil
  final bool isSuccess;

  /// Pesan error (jika gagal)
  final String? errorMessage;

  const AiResponse({
    required this.description,
    required this.timestamp,
    this.model,
    this.isSuccess = true,
    this.errorMessage,
  });

  /// Factory untuk response sukses
  factory AiResponse.success({
    required String description,
    String? model,
  }) {
    return AiResponse(
      description: description,
      timestamp: DateTime.now(),
      model: model,
      isSuccess: true,
    );
  }

  /// Factory untuk response error
  factory AiResponse.error(String message) {
    return AiResponse(
      description: '',
      timestamp: DateTime.now(),
      isSuccess: false,
      errorMessage: message,
    );
  }

  @override
  String toString() =>
      'AiResponse(success: $isSuccess, desc: ${description.substring(0, description.length.clamp(0, 50))}...)';
}
