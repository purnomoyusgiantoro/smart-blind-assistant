# smartassistant

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


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
