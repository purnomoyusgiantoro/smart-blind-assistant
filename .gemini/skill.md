# Smart Blind Assistant – Agent Skill

## Tentang Proyek
Smart Blind Assistant adalah aplikasi Flutter untuk membantu penyandang tunanetra.
Aplikasi ini terhubung ke perangkat ESP32 via WiFi/BLE dan menggunakan AI (OpenRouter API)
untuk menganalisis gambar dari kamera serta menjawab pertanyaan pengguna melalui suara.

## Arsitektur & Teknologi
- **Framework**: Flutter (Dart)
- **State Management**: Provider (ChangeNotifier)
- **Hardware**: ESP32 terhubung via WiFi, dengan 2 tombol fisik
- **AI Backend**: OpenRouter API (model Gemini Vision)
- **Voice**: Speech-to-Text (STT) untuk input, Text-to-Speech (TTS) untuk output
- **Koneksi Hardware**: BLE (Bluetooth Low Energy) ke ESP32

## Struktur Folder
```
lib/
├── main.dart                     # Entry point + Provider setup
├── app.dart                      # MaterialApp + Theme + Routes
├── core/
│   ├── constants/
│   │   ├── app_constants.dart    # BLE UUIDs, API config, TTS defaults
│   │   └── app_strings.dart      # Semua teks UI + TTS (Bahasa Indonesia)
│   ├── theme/
│   │   └── app_theme.dart        # Dark theme kontras tinggi
│   └── utils/
│       ├── logger.dart           # Debug logger
│       ├── platform_helper.dart  # Platform detection
│       └── permissions_handler.dart
├── models/
│   ├── ble_device.dart           # Model perangkat BLE
│   ├── capture_payload.dart      # Model payload foto
│   └── ai_response.dart          # Model respons AI
├── services/
│   ├── ble_service.dart          # Komunikasi BLE dengan ESP32
│   ├── camera_service.dart       # Capture gambar kamera
│   ├── tts_service.dart          # Text-to-Speech
│   ├── stt_service.dart          # Speech-to-Text
│   ├── api_service.dart          # OpenRouter API
│   └── background_service.dart   # Foreground service
├── providers/
│   ├── ble_provider.dart         # State koneksi BLE
│   ├── assistant_provider.dart   # State machine utama + orkestrasi
│   └── settings_provider.dart    # Pengaturan user (persisten)
├── features/
│   ├── home/                     # Layar utama
│   ├── scan/                     # Scan perangkat BLE
│   ├── settings/                 # Pengaturan
│   └── log/                      # Riwayat interaksi
└── routes/
    └── app_router.dart
```

## 3 Mode Operasi

### 1. Mode General
- Ambil gambar dari kamera + kirim ke AI
- AI mendeskripsikan apa yang terlihat di sekitar pengguna
- Bisa ditambah pertanyaan spesifik via suara
- Cocok untuk: "Apa yang ada di depanku?", "Bacakan tulisan ini"

### 2. Mode Autopilot
- Kamera selalu aktif, AI menganalisis otomatis secara berkala
- Mendukung **instruksi persisten**: user kasih perintah via suara,
  perintah itu melekat dan dipakai di setiap auto-capture sampai diubah
- Contoh instruksi: "beritahu kalau ada orang", "kalau ada mobil putih kasih tahu",
  "beritahu kalau ruangan gelap"
- AI selalu cek instruksi user + keselamatan umum di setiap analisis
- Cocok untuk: berjalan di luar, navigasi mandiri, monitoring khusus

### 3. Mode Obrolan
- **Asisten pribadi** lengkap tanpa gambar — bukan cuma ngobrol santai
- Bisa jawab pertanyaan apa aja (pengetahuan, sains, sejarah, dll)
- Bisa kasih saran, solusi masalah, motivasi, dan jadi teman curhat
- Bisa bantu hitung, terjemahin, atau jelasin sesuatu
- Bisa bercanda dan bikin suasana asik
- Cocok untuk: tanya informasi, curhat, belajar, ngobrol santai

## 2 Tombol ESP32
- **Tombol 1 (trigger value = 1)**: Memberi perintah suara (STT → AI → TTS)
  - Di mode autopilot: perintah jadi instruksi persisten
- **Tombol 2 (trigger value = 2)**: Berganti mode (cycle: General → Autopilot → Obrolan)

## Konvensi Kode
- Bahasa komentar dan dokumentasi: **Indonesia**
- Bahasa TTS dan prompt AI: **Indonesia, santai dan natural**
- Gunakan `AppLogger` untuk semua logging
- Gunakan `AppStrings` untuk semua teks UI/TTS
- Gunakan `AppConstants` untuk semua konfigurasi
- State management via Provider pattern (ChangeNotifier)

## Gaya Bicara Agent
- **Santai dan ramah**, bukan formal/kaku — kayak ngobrol sama teman dekat
- Gunakan bahasa sehari-hari, contoh: "Oke, aku lihat dulu ya" bukan "Memproses permintaan Anda"
- Prioritaskan keselamatan: selalu informasikan bahaya duluan
- Jawab singkat dan jelas, maksimal 2-4 kalimat
- Di mode obrolan: boleh bercanda, nanya balik, kasih motivasi
- Kalau user curhat/sedih: dengerin dan kasih respons yang hangat & suportif
