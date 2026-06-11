/// Model payload yang dikirim ke backend/OpenRouter.
///
/// Berisi path gambar hasil capture dan metadata.
class CapturePayload {
  /// Path lokal file gambar
  final String imagePath;

  /// Waktu capture
  final DateTime timestamp;

  /// Informasi perangkat (opsional)
  final String? deviceInfo;

  /// Mode saat ini (describe, read, navigate, custom)
  final String mode;

  /// Custom prompt dari user (opsional, dipakai saat mode=custom)
  final String? customPrompt;

  /// Informasi lokasi GPS (opsional, dipakai saat mode=navigasi)
  final String? locationInfo;

  const CapturePayload({
    required this.imagePath,
    required this.timestamp,
    required this.mode,
    this.deviceInfo,
    this.customPrompt,
    this.locationInfo,
  });

  @override
  String toString() =>
      'CapturePayload(mode: $mode, path: $imagePath, time: $timestamp, prompt: $customPrompt, location: $locationInfo)';
}

