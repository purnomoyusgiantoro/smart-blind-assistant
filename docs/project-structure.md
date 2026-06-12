# 📂 Struktur Proyek

Dokumen ini menjelaskan setiap file dan direktori dalam proyek SightAssist secara detail.

---

## Tree Lengkap

```
lib/
├── main.dart                          # Entry point + Provider setup
├── app.dart                           # MaterialApp + Theme + Routes
│
├── core/                              # ── Fondasi Aplikasi ──
│   ├── constants/
│   │   ├── app_constants.dart         # BLE UUIDs, OpenRouter config, TTS defaults
│   │   └── app_strings.dart           # Semua teks UI & TTS dalam Bahasa Indonesia
│   ├── theme/
│   │   └── app_theme.dart             # Dark theme kontras tinggi (warna, tipografi)
│   └── utils/
│       ├── logger.dart                # Debug logger dengan timestamp & tag
│       ├── permissions_handler.dart   # Request & cek izin BLE, kamera, mikrofon
│       └── platform_helper.dart       # Deteksi platform (mobile vs desktop)
│
├── models/                            # ── Data Models (Immutable) ──
│   ├── ai_response.dart               # Respons dari AI (deskripsi, model, error)
│   ├── ble_device.dart                # Perangkat BLE (nama, id, rssi, status)
│   └── capture_payload.dart           # Payload foto (path, mode, prompt, timestamp)
│
├── services/                          # ── Business Logic & External I/O ──
│   ├── api_service.dart               # OpenRouter API client (multimodal image+text)
│   ├── ble_service.dart               # BLE scan, connect, subscribe notifications
│   ├── camera_service.dart            # Init kamera, capture frame, simpan ke temp
│   ├── tts_service.dart               # Text-to-Speech engine (init, speak, stop)
│   ├── stt_service.dart               # Speech-to-Text engine (init, listen, cancel)
│   └── background_service.dart        # Foreground service (Android/iOS)
│
├── providers/                         # ── State Management ──
│   ├── assistant_provider.dart        # Orkestrator utama: state machine + pipeline
│   ├── ble_provider.dart              # State koneksi BLE (scan, connect, trigger)
│   └── settings_provider.dart         # Pengaturan user (TTS, API key, auto-connect)
│
├── features/                          # ── UI Screens ──
│   ├── home/
│   │   ├── home_screen.dart           # Layar utama (preview kamera + kontrol)
│   │   └── widgets/
│   │       ├── assistant_status_indicator.dart  # Indikator status asisten
│   │       ├── connection_status_card.dart      # Status koneksi BLE
│   │       ├── manual_trigger_button.dart       # Tombol trigger manual
│   │       └── mode_switch_button.dart          # Tombol ganti mode
│   ├── scan/
│   │   ├── scan_screen.dart           # Halaman scan perangkat BLE
│   │   └── widgets/
│   │       └── device_list_tile.dart   # Tile per perangkat BLE
│   ├── settings/
│   │   ├── settings_screen.dart       # Halaman pengaturan
│   │   └── widgets/
│   │       └── setting_tile.dart       # Tile per pengaturan
│   └── log/
│       └── log_screen.dart            # Halaman riwayat interaksi
│
└── routes/
    └── app_router.dart                # Named routes: /, /scan, /settings, /log
```

---

## Penjelasan Per-File

### Entry Point

| File | Ukuran | Deskripsi |
|------|--------|-----------|
| `main.dart` | 1.5 KB | Entry point. Inisialisasi binding, orientasi, dotenv, background service, settings. Registrasi 3 provider. |
| `app.dart` | 589 B | Root widget `SightAssistApp`. Konfigurasi MaterialApp dengan dark theme dan named routes. |

### Core

| File | Ukuran | Deskripsi |
|------|--------|-----------|
| `app_constants.dart` | 2.3 KB | Konstanta global: BLE UUIDs, OpenRouter URL/model, kamera resolusi, TTS defaults, HTTP timeout. |
| `app_strings.dart` | 4.2 KB | Semua string UI dan pesan TTS dalam Bahasa Indonesia. 60+ string constants. |
| `app_theme.dart` | 5.5 KB | Definisi ThemeData: palet warna, tipografi, styling untuk AppBar, Card, Button, ListTile, Switch, dll. |
| `logger.dart` | 783 B | Wrapper `debugPrint` dengan format `[timestamp] [level] [tag] message`. Hanya di debug build. |
| `permissions_handler.dart` | 2.7 KB | Request izin BLE, kamera, mikrofon. Platform-aware (Android vs iOS). `requestAll()` dan helpers. |
| `platform_helper.dart` | 926 B | Deteksi platform: `isMobile`, `isDesktop`, `isBleSupported`, `isBackgroundServiceSupported`. |

### Models

| File | Ukuran | Deskripsi |
|------|--------|-----------|
| `ai_response.dart` | 1.1 KB | Model respons AI. Factory `success()` dan `error()`. Fields: description, timestamp, model, isSuccess, errorMessage. |
| `ble_device.dart` | 856 B | Model perangkat BLE. Fields: name, id, rssi, isConnected. Method `copyWith()`. |
| `capture_payload.dart` | 770 B | Model payload capture. Fields: imagePath, timestamp, mode, deviceInfo, customPrompt. |

### Services

| File | Ukuran | Deskripsi |
|------|--------|-----------|
| `api_service.dart` | 5.4 KB | HTTP client ke OpenRouter. Encode gambar ke base64, bangun multimodal request, parse response. 4 mode prompt. |
| `ble_service.dart` | 5.0 KB | Scan BLE, connect, discover services, subscribe ke trigger characteristic. Stream-based trigger events. |
| `camera_service.dart` | 3.2 KB | Init kamera belakang, capture frame, simpan ke temp dir dengan nama unik. |
| `tts_service.dart` | 2.8 KB | Init TTS engine, speak, stop, callbacks (start/completion/error), set language & speech rate. |
| `stt_service.dart` | 3.9 KB | Init STT, start/stop/cancel listening, partial results, locale support. |
| `background_service.dart` | 3.2 KB | Konfigurasi foreground service (Android) dan iOS background. Heartbeat periodik 30 detik. |

### Providers

| File | Ukuran | Deskripsi |
|------|--------|-----------|
| `assistant_provider.dart` | 13.6 KB | Provider terbesar. State machine (7 status), 2 mode operasi, orkestrasi pipeline capture/navigate, voice input, integrasi BLE trigger. |
| `ble_provider.dart` | 3.2 KB | State koneksi BLE: scan, device list, connect/disconnect, trigger stream. |
| `settings_provider.dart` | 3.0 KB | Pengaturan persisten: TTS language, speech rate, API key, auto-connect. SharedPreferences. |

### Features

| File | Ukuran | Deskripsi |
|------|--------|-----------|
| `home_screen.dart` | 15.4 KB | Layar utama: preview kamera, status BLE, voice prompt, action buttons, mode label. |
| `assistant_status_indicator.dart` | 3.9 KB | Widget indikator status asisten dengan warna per state. |
| `connection_status_card.dart` | 3.6 KB | Widget status koneksi BLE (compact). |
| `manual_trigger_button.dart` | 1.8 KB | Tombol trigger manual capture. |
| `mode_switch_button.dart` | 1.8 KB | Tombol ganti mode capture ↔ navigate. |
| `scan_screen.dart` | 3.5 KB | Halaman scan BLE: daftar perangkat, tombol scan. |
| `device_list_tile.dart` | 4.2 KB | Tile per perangkat BLE: nama, RSSI, tombol connect. |
| `settings_screen.dart` | 6.8 KB | Halaman pengaturan: bahasa TTS, kecepatan, API key, auto-connect. |
| `setting_tile.dart` | 2.5 KB | Widget tile per pengaturan (reusable). |
| `log_screen.dart` | 1.2 KB | Halaman riwayat interaksi (placeholder). |

### Routes

| File | Ukuran | Deskripsi |
|------|--------|-----------|
| `app_router.dart` | 1.0 KB | 4 named routes: `/` (home), `/scan`, `/settings`, `/log`. |

---

## File Konfigurasi

| File | Deskripsi |
|------|-----------|
| `pubspec.yaml` | Dependencies, assets, metadata proyek |
| `analysis_options.yaml` | Konfigurasi linter (`flutter_lints`) |
| `.env` | API key (tidak di-commit ke git) |
| `.env.example` | Template `.env` |
| `.gitignore` | File/folder yang diabaikan git |
| `AGENTS.md` | Panduan untuk AI coding assistant |

---

## Statistik

| Metrik | Nilai |
|--------|-------|
| Total file Dart | ~25 |
| Total LOC (estimasi) | ~2000 |
| Dependencies | 12 packages |
| Dev Dependencies | 2 packages |
| Screens | 4 |
| Reusable Widgets | 6 |
| Services | 6 |
| Providers | 3 |
| Models | 3 |
