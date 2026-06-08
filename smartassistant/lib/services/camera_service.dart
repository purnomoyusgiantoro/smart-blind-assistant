import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import '../core/utils/logger.dart';

/// Service untuk mengelola kamera perangkat.
///
/// Menginisialisasi kamera belakang dan mengambil satu frame
/// saat trigger diterima dari ESP32.
class CameraService {
  static const String _tag = 'CameraService';

  CameraController? _controller;
  List<CameraDescription>? _cameras;

  /// Apakah kamera sudah diinisialisasi
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  // ─── Initialize ────────────────────────────────────────────

  /// Inisialisasi kamera belakang dengan resolusi medium.
  Future<bool> initialize() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        AppLogger.error(_tag, 'Tidak ada kamera tersedia');
        return false;
      }

      // Pilih kamera belakang
      final backCamera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false, // Tidak perlu audio dari kamera
      );

      await _controller!.initialize();
      AppLogger.info(_tag, 'Kamera diinisialisasi: ${backCamera.name}');

      return true;
    } catch (e) {
      AppLogger.error(_tag, 'Gagal inisialisasi kamera', e);
      return false;
    }
  }

  // ─── Capture ───────────────────────────────────────────────

  /// Ambil satu frame gambar dari kamera.
  ///
  /// Mengembalikan path file gambar yang disimpan di temp directory,
  /// atau `null` jika gagal.
  Future<String?> captureFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      AppLogger.error(_tag, 'Kamera belum diinisialisasi');
      return null;
    }

    try {
      // Ambil gambar
      final XFile image = await _controller!.takePicture();

      // Pindahkan ke temp directory dengan nama unik
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/sight_capture_$timestamp.jpg';

      final File targetFile = File(image.path);
      await targetFile.copy(targetPath);

      AppLogger.info(_tag, 'Gambar disimpan: $targetPath');
      return targetPath;
    } catch (e) {
      AppLogger.error(_tag, 'Gagal mengambil gambar', e);
      return null;
    }
  }

  // ─── Dispose ───────────────────────────────────────────────

  /// Bebaskan resource kamera.
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    AppLogger.info(_tag, 'Kamera disposed');
  }
}
