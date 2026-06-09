/// Semua string teks UI dan pesan TTS.
///
/// Disimpan terpusat agar mudah diubah dan dilokalisasi.
class AppStrings {
  AppStrings._();

  // ─── Umum ──────────────────────────────────────────────────
  static const String appName = 'SightAssist';
  static const String appTagline = 'Asisten Visual Pintar untuk Tunanetra';

  // ─── Status Asisten ────────────────────────────────────────
  static const String statusIdle = 'Siap';
  static const String statusCapturing = 'Mengambil gambar...';
  static const String statusUploading = 'Mengirim ke server...';
  static const String statusProcessing = 'AI sedang menganalisis...';
  static const String statusSpeaking = 'Membacakan hasil...';
  static const String statusError = 'Terjadi kesalahan';
  static const String statusNavigating = 'Navigasi aktif';

  // ─── BLE ───────────────────────────────────────────────────
  static const String bleScanning = 'Mencari perangkat...';
  static const String bleConnected = 'Terhubung';
  static const String bleDisconnected = 'Tidak terhubung';
  static const String bleConnecting = 'Menghubungkan...';
  static const String bleNoDevicesFound = 'Tidak ada perangkat ditemukan';
  static const String bleScanButton = 'Cari Perangkat';

  // ─── Mode ──────────────────────────────────────────────────
  static const String modeCapture = 'Mode Ambil Gambar';
  static const String modeNavigate = 'Mode Navigasi';
  static const String modeSwitched = 'Mode diubah ke';

  // ─── TTS Feedback ──────────────────────────────────────────
  static const String ttsWelcome = 'SightAssist aktif. Tekan tombol untuk memulai.';
  static const String ttsBleTriggerReceived = 'Tombol ditekan. Mengambil gambar.';
  static const String ttsCaptureSuccess = 'Gambar berhasil diambil. Mengirim ke AI.';
  static const String ttsError = 'Maaf, terjadi kesalahan. Silakan coba lagi.';
  static const String ttsNoConnection = 'Tidak ada koneksi internet.';
  static const String ttsNavigationStarted = 'Mode navigasi dimulai. AI akan menganalisis lingkungan secara berkala.';
  static const String ttsNavigationStopped = 'Mode navigasi dihentikan.';

  // ─── Halaman ───────────────────────────────────────────────
  static const String homeTitle = 'Beranda';
  static const String scanTitle = 'Cari Perangkat BLE';
  static const String settingsTitle = 'Pengaturan';
  static const String logTitle = 'Riwayat';

  // ─── Pengaturan ────────────────────────────────────────────
  static const String settingLanguage = 'Bahasa TTS';
  static const String settingSpeechRate = 'Kecepatan Bicara';
  static const String settingServerUrl = 'URL Server';
  static const String settingApiKey = 'API Key OpenRouter';
  static const String settingAutoConnect = 'Auto-Connect BLE';

  // ─── Tombol ────────────────────────────────────────────────
  static const String buttonTrigger = 'Ambil Gambar & Analisis';
  static const String buttonSwitchMode = 'Ganti Mode';
  static const String buttonStartNavigation = 'Mulai Navigasi';
  static const String buttonStopNavigation = 'Hentikan Navigasi';

  // ─── Prompt ────────────────────────────────────────────────
  static const String promptHint = 'Tulis pertanyaan tentang gambar...';
  static const String promptLabel = 'Custom Prompt';
}
