# Smart Blind Assistant

Smart Blind Assistant adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu penyandang tunanetra. Aplikasi ini terintegrasi dengan perangkat keras eksternal (seperti ESP32) melalui Bluetooth Low Energy (BLE) untuk mengambil gambar, menganalisisnya menggunakan AI (melalui OpenRouter API), dan memberikan umpan balik berupa suara melalui Text-to-Speech (TTS).

## Fitur Utama

- **Konektivitas BLE**: Terhubung secara mulus dengan perangkat eksternal (ESP32) untuk menerima perintah atau pemicu (trigger).
- **Integrasi Kamera**: Mengambil gambar dari lingkungan sekitar pengguna menggunakan kamera belakang.
- **Analisis AI**: Mengirim gambar ke OpenRouter API dengan berbagai mode prompt untuk mendeskripsikan objek, teks, atau lingkungan.
- **Text-to-Speech (TTS)**: Membacakan hasil analisis AI kepada pengguna, memberikan umpan balik secara instan.
- **Mode Latar Belakang (Background Service)**: Memastikan aplikasi tetap berfungsi dan dapat merespons pemicu BLE bahkan saat aplikasi tidak aktif di layar utama.
- **Antarmuka Ramah Aksesibilitas**: Dirancang dengan tema gelap kontras tinggi dan UI berbahasa Indonesia.

## Struktur Direktori

Berikut adalah struktur utama direktori dalam proyek ini:

```text
lib/
├── main.dart                    # Entry point + Provider setup
├── app.dart                     # MaterialApp + Theme + Routes
├── core/
│   ├── constants/
│   │   ├── app_constants.dart   # BLE UUIDs, OpenRouter config, TTS defaults
│   │   └── app_strings.dart     # Semua teks UI dalam Bahasa Indonesia
│   ├── theme/
│   │   └── app_theme.dart       # Dark theme kontras tinggi
│   └── utils/
│       ├── logger.dart          # Debug logger
│       └── permissions_handler.dart  # BLE, Kamera, Mikrofon permissions
├── models/
│   ├── ble_device.dart          # Model perangkat BLE
│   ├── capture_payload.dart     # Model payload foto
│   └── ai_response.dart         # Model respons AI
├── services/
│   ├── ble_service.dart         # Komunikasi BLE dgn ESP32
│   ├── camera_service.dart      # Capture gambar kamera belakang
│   ├── tts_service.dart         # Text-to-Speech
│   ├── api_service.dart         # OpenRouter API (3 mode prompt)
│   └── background_service.dart  # Foreground service
├── providers/
│   ├── ble_provider.dart        # State koneksi BLE
│   ├── assistant_provider.dart  # State machine + orkestrasi pipeline
│   └── settings_provider.dart   # Pengaturan user (persisten)
├── features/
│   ├── home/                    # Layar utama (2 tombol + status)
│   ├── scan/                    # Scan & pilih perangkat BLE
│   ├── settings/                # Pengaturan TTS, API, BLE
│   └── log/                     # Riwayat interaksi
└── routes/
    └── app_router.dart
```

## Persyaratan (Requirements)

- Flutter SDK (Versi terbaru disarankan)
- Perangkat Android/iOS asli (Diperlukan untuk menguji Kamera, BLE, dan TTS)
- Akses API Key dari OpenRouter

## Cara Menjalankan Aplikasi

1. Clone repositori ini.
2. Jalankan `flutter pub get` untuk mengunduh semua dependensi.
3. Hubungkan perangkat fisik Anda dan jalankan aplikasi dengan perintah:
   ```bash
   flutter run
   ```

> **Catatan**: Aplikasi ini sangat bergantung pada fitur perangkat keras (Kamera dan Bluetooth). Karena itu, jalankan pada perangkat fisik (bukan emulator) untuk pengujian yang akurat.
