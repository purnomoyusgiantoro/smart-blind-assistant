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

  /// Mode saat ini (describe, read, navigate)
  final String mode;

  const CapturePayload({
    required this.imagePath,
    required this.timestamp,
    required this.mode,
    this.deviceInfo,
  });

  @override
  String toString() =>
      'CapturePayload(mode: $mode, path: $imagePath, time: $timestamp)';
}
