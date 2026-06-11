/// Semua string teks UI dan pesan TTS.
///
/// Disimpan terpusat agar mudah diubah dan dilokalisasi.
/// Gaya bahasa: santai, ramah, natural (bukan kaku/formal).
class AppStrings {
  AppStrings._();

  // ─── Umum ──────────────────────────────────────────────────
  static const String appName = 'SightAssist';
  static const String appTagline = 'Asisten Visual Pintar untuk Tunanetra';

  // ─── Status Asisten ────────────────────────────────────────
  static const String statusIdle = 'Siap';
  static const String statusListening = 'Mendengarkan...';
  static const String statusCapturing = 'Mengambil gambar...';
  static const String statusUploading = 'Mengirim ke server...';
  static const String statusProcessing = 'AI sedang menganalisis...';
  static const String statusSpeaking = 'Membacakan hasil...';
  static const String statusError = 'Terjadi kesalahan';
  static const String statusAutopiloting = 'Autopilot aktif';

  // ─── BLE ───────────────────────────────────────────────────
  static const String bleScanning = 'Mencari perangkat...';
  static const String bleConnected = 'Terhubung';
  static const String bleDisconnected = 'Tidak terhubung';
  static const String bleConnecting = 'Menghubungkan...';
  static const String bleNoDevicesFound = 'Tidak ada perangkat ditemukan';
  static const String bleScanButton = 'Cari Perangkat';

  // ─── Mode (3 Mode) ────────────────────────────────────────
  static const String modeGeneral = 'Mode General';
  static const String modeAutopilot = 'Mode Autopilot';
  static const String modeNavigasi = 'Mode Navigasi';
  static const String modeObrolan = 'Mode Obrolan';
  static const String modeSwitched = 'Ganti ke';

  // ─── TTS Feedback (Natural & Santai) ──────────────────────
  static const String ttsWelcome =
      'Halo! SightAssist sudah siap. '
      'Tekan tombol pertama untuk ngomong, atau tombol kedua untuk ganti mode.';
  static const String ttsBleTriggerReceived =
      'Oke, tunggu sebentar ya. Aku lihat dulu sekelilingmu.';
  static const String ttsCaptureSuccess =
      'Udah difoto. Lagi aku analisis ya.';
  static const String ttsError =
      'Waduh, ada yang salah nih. Coba lagi ya.';
  static const String ttsNoConnection = 'Kayaknya internetnya lagi mati deh.';
  static const String ttsAutopilotStarted =
      'Mode autopilot aktif. Aku bakal pantau sekelilingmu terus ya.';
  static const String ttsAutopilotStopped = 'Autopilot dimatikan.';
  static const String ttsListening = 'Aku dengerin, silakan ngomong.';
  static const String ttsVoiceNotAvailable = 'Fitur suara belum tersedia nih.';
  static const String ttsPromptReceived = 'Oke, aku dengar.';
  static const String ttsAnalyzing = 'Lagi aku pikirkan ya...';
  static const String ttsChatMode =
      'Mode obrolan aktif. Aku jadi asisten pribadimu. Mau ngobrolin apa?';
  static const String ttsAutopilotInstructionHint =
      'Kasih perintah buat autopilot, misalnya: beritahu kalau ada orang.';
  static const String ttsNavigasiStarted =
      'Mode navigasi aktif. Aku bakal bantu kamu tahu posisi dan arah jalan.';
  static const String ttsNavigasiLocationFound =
      'Oke, aku udah dapetin lokasimu.';
  static const String ttsNavigasiLocationFailed =
      'Maaf, aku belum bisa dapetin lokasimu sekarang.';
  static const String ttsNavigasiLocationNotReady =
      'GPS belum siap nih. Coba pastikan lokasi di HP-mu aktif ya.';

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
  static const String buttonVoiceCommand = 'Perintah Suara';
  static const String buttonSwitchMode = 'Ganti Mode';
  static const String buttonStartAutopilot = 'Mulai Autopilot';
  static const String buttonStopAutopilot = 'Hentikan Autopilot';
  static const String buttonNavigasi = 'Cek Lokasi & Navigasi';

  // ─── Prompt ────────────────────────────────────────────────
  static const String promptHint = 'Tulis pertanyaan tentang gambar...';
  static const String promptLabel = 'Custom Prompt';
}
