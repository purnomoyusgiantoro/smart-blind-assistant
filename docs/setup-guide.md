# 🚀 Panduan Setup

Dokumen ini menjelaskan cara instalasi, konfigurasi, dan menjalankan aplikasi SightAssist.

---

## Prasyarat

### Software

| Software | Versi | Kegunaan |
|----------|-------|----------|
| Flutter SDK | ^3.12.1 | Framework utama |
| Dart SDK | (bundled dengan Flutter) | Bahasa pemrograman |
| Android Studio / Xcode | Terbaru | IDE & build tools |
| Git | Any | Version control |

### Hardware

| Perangkat | Kegunaan | Wajib? |
|-----------|----------|--------|
| HP Android / iPhone (fisik) | Testing BLE, kamera, TTS | ✅ Ya |
| ESP32 | Perangkat BLE eksternal | Opsional (bisa manual trigger) |
| Kabel USB | Koneksi HP ke komputer | ✅ Ya |

> ⚠️ **Penting**: Emulator **tidak mendukung** BLE, kamera fisik, dan TTS. Selalu gunakan perangkat fisik.

---

## Langkah Instalasi

### 1. Clone Repository

```bash
git clone https://github.com/Fiyanz/smart-blind-assistant.git
cd smart-blind-assistant
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Konfigurasi Environment

Buat file `.env` di root proyek:

```bash
cp .env.example .env
```

Isi dengan API key dari [OpenRouter](https://openrouter.ai):

```
OPENROUTER_API_KEY=sk-or-v1-your-api-key-here
```

### 4. Verifikasi Setup

```bash
flutter doctor       # Cek environment Flutter
flutter analyze      # Cek static analysis
```

---

## Menjalankan Aplikasi

### Di Perangkat Fisik

```bash
# Hubungkan HP via USB, lalu:
flutter run
```

### Di Desktop (Terbatas)

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

> ⚠️ Di desktop, fitur BLE dan Background Service **tidak tersedia**. Kamera dan TTS tetap berfungsi.

---

## Perintah Penting

| Perintah | Kegunaan |
|----------|----------|
| `flutter pub get` | Install dependencies |
| `flutter analyze` | Static analysis |
| `flutter test` | Jalankan widget tests |
| `flutter run` | Jalankan di perangkat |
| `flutter run --release` | Build & jalankan mode release |
| `flutter build apk` | Build APK Android |
| `flutter build ios` | Build iOS |

---

## Konfigurasi ESP32

Untuk menggunakan fitur BLE, ESP32 harus dikonfigurasi dengan UUID yang sesuai:

```cpp
// Di firmware ESP32:
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define TRIGGER_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
```

ESP32 mengirim notifikasi BLE (1 byte) saat tombol fisik ditekan.

---

## Troubleshooting

### Flutter Doctor Error

```bash
flutter doctor -v    # Verbose output untuk diagnosis
```

### BLE Tidak Terdeteksi

1. Pastikan Bluetooth HP **aktif**
2. Pastikan **izin lokasi** diberikan (Android butuh lokasi untuk BLE)
3. Pastikan ESP32 menyala dan dalam mode advertising
4. Coba restart aplikasi

### Kamera Tidak Muncul

1. Pastikan **izin kamera** diberikan
2. Coba tutup dan buka ulang aplikasi
3. Pastikan tidak ada aplikasi lain yang menggunakan kamera

### TTS Tidak Berbicara

1. Cek volume HP
2. Pastikan bahasa `id-ID` tersedia di pengaturan TTS sistem
3. Di Android: Settings → Accessibility → Text-to-Speech

### API Error

1. Pastikan `.env` berisi API key yang valid
2. Pastikan ada koneksi internet
3. Cek saldo/kuota di dashboard OpenRouter

---

## Mendapatkan API Key

1. Buka [openrouter.ai](https://openrouter.ai)
2. Buat akun atau login
3. Buka menu **API Keys**
4. Klik **Create Key**
5. Copy key (format: `sk-or-v1-...`)
6. Paste ke file `.env`
