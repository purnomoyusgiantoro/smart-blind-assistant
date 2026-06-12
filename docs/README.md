# 📚 Dokumentasi Smart Blind Assistant (SightAssist)

Selamat datang di dokumentasi proyek **Smart Blind Assistant** — aplikasi mobile berbasis Flutter yang dirancang untuk membantu penyandang tunanetra berinteraksi dengan lingkungan sekitar menggunakan teknologi IoT dan AI.

## Daftar Isi

| Dokumen | Deskripsi |
|---------|-----------|
| [Arsitektur](./architecture.md) | Arsitektur sistem, pola desain, dan alur data |
| [Desain UI/UX](./design.md) | Sistem desain, tema, aksesibilitas, dan komponen UI |
| [Alur Kerja (Workflow)](./workflow.md) | Pipeline capture, navigasi, dan integrasi BLE-AI-TTS |
| [API & Integrasi](./api-integration.md) | OpenRouter API, BLE protocol, dan konfigurasi layanan |
| [Panduan Setup](./setup-guide.md) | Cara instalasi, konfigurasi, dan menjalankan aplikasi |
| [Panduan Hardware](./hardware-guide.md) | Komponen, rangkaian, firmware ESP32, dan pengujian |
| [Struktur Proyek](./project-structure.md) | Penjelasan detail setiap file dan direktori |

## Gambaran Umum

**SightAssist** adalah sistem asisten visual pintar yang menggabungkan:

- 🔵 **Bluetooth Low Energy (BLE)** — Komunikasi dengan perangkat keras ESP32
- 📷 **Kamera** — Pengambilan gambar lingkungan sekitar
- 🤖 **AI Vision** — Analisis gambar menggunakan Gemini via OpenRouter
- 🔊 **Text-to-Speech** — Output suara dalam Bahasa Indonesia
- 🎤 **Speech-to-Text** — Input suara dari pengguna
- ⚙️ **Background Service** — Proses tetap aktif saat layar terkunci

## Tech Stack

| Teknologi | Kegunaan |
|-----------|----------|
| Flutter (Dart) | Framework mobile cross-platform |
| Provider | State management |
| flutter_blue_plus | Komunikasi BLE dengan ESP32 |
| camera | Capture gambar dari kamera perangkat |
| flutter_tts | Text-to-Speech engine |
| speech_to_text | Speech-to-Text engine |
| http | HTTP client untuk API call |
| flutter_background_service | Foreground service (Android/iOS) |
| flutter_dotenv | Manajemen environment variables |
| shared_preferences | Penyimpanan pengaturan lokal |

## Versi

- **Flutter SDK**: ^3.12.1
- **Versi Aplikasi**: 1.0.0+1

---

> 📝 Dokumentasi ini ditulis dalam **Bahasa Indonesia** sesuai dengan bahasa antarmuka aplikasi.
