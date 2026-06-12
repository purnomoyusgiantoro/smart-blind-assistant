# 🔌 API & Integrasi

Dokumen ini menjelaskan integrasi dengan layanan eksternal: OpenRouter API, protokol BLE ESP32, dan konfigurasi layanan internal.

---

## OpenRouter API (AI Vision)

### Konfigurasi

| Parameter | Nilai | Sumber |
|-----------|-------|--------|
| Base URL | `https://openrouter.ai/api/v1/chat/completions` | `AppConstants` |
| API Key | dari `.env` file | `OPENROUTER_API_KEY` |
| Model | `google/gemini-2.5-flash` | `AppConstants.aiModel` |
| Max Tokens | 300 | Hardcoded |
| Timeout | 30 detik | `AppConstants.httpTimeoutSeconds` |

### Request Format

```json
{
  "model": "google/gemini-2.5-flash",
  "messages": [
    {
      "role": "system",
      "content": "[System prompt berdasarkan mode]"
    },
    {
      "role": "user",
      "content": [
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,{BASE64_IMAGE}"
          }
        },
        {
          "type": "text",
          "text": "Analisis gambar ini."
        }
      ]
    }
  ],
  "max_tokens": 300
}
```

### Headers

```
Authorization: Bearer {API_KEY}
Content-Type: application/json
HTTP-Referer: https://sightassist.app
X-Title: SightAssist
```

### Response Parsing

```dart
// Sukses (200)
final content = json['choices'][0]['message']['content'];
final model = json['model'];
return AiResponse.success(description: content, model: model);

// Error (non-200)
return AiResponse.error('Server error: ${statusCode}');
```

### System Prompts

| Mode | Instruksi Utama |
|------|----------------|
| `describe` | Deskripsikan objek, orang, teks, rintangan. Prioritas keselamatan. Maks 3 kalimat. |
| `read` | Baca semua teks (papan nama, label). Jika tidak ada: "Tidak ada teks yang terlihat." |
| `navigate` | Analisis jalur, arah aman, peringatkan bahaya. Maks 2 kalimat. |
| `custom` | Jawab sesuai instruksi pengguna. Maks 3 kalimat. |

Semua prompt menghasilkan respons dalam **Bahasa Indonesia**.

---

## Protokol BLE (ESP32)

### UUID

| Komponen | UUID |
|----------|------|
| Service | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| Trigger Characteristic | `beb5483e-36e1-4688-b7f5-ea07361b26a8` |

### Alur Koneksi

```
1. FlutterBluePlus.startScan(timeout: 10s)
2. Filter: hanya perangkat dengan nama (platformName.isNotEmpty)
3. User pilih perangkat → BluetoothDevice.connect(timeout: 10s)
4. discoverServices() → cari service UUID
5. Cari characteristic UUID → setNotifyValue(true)
6. Listen onValueReceived → triggerController.add(value[0])
```

### Trigger Format

- ESP32 mengirim **1 byte** melalui BLE notification
- Byte pertama (`value[0]`) diteruskan sebagai trigger event
- `AssistantProvider` merespons trigger ini untuk memulai pipeline

### Platform Support

| Platform | BLE | Background Service |
|----------|-----|--------------------|
| Android | ✅ | ✅ (Foreground Service) |
| iOS | ✅ | ✅ (Background Mode) |
| Windows | ❌ | ❌ |
| macOS | ❌ | ❌ |
| Linux | ❌ | ❌ |

---

## Kamera

### Konfigurasi

- Resolusi: `medium` (ResolutionPreset)
- Prioritas: Kamera belakang (`CameraLensDirection.back`)
- Fallback: Kamera pertama yang tersedia
- Audio: Dimatikan (`enableAudio: false`)

### Output

- Format: JPEG
- Lokasi: `{tempDir}/sight_capture_{timestamp}.jpg`
- Nama unik berdasarkan epoch milliseconds

---

## Text-to-Speech (TTS)

### Konfigurasi Default

| Parameter | Nilai |
|-----------|-------|
| Bahasa | `id-ID` |
| Kecepatan | 0.5 (50%) |
| Pitch | 1.0 (normal) |
| Volume | 1.0 (max) |

### Perilaku

- Jika sedang berbicara, stop dulu sebelum ucapkan teks baru
- Callbacks: `onStart`, `onCompletion`, `onError`
- Bahasa dan kecepatan dapat diubah via Settings

---

## Speech-to-Text (STT)

### Konfigurasi

| Parameter | Nilai |
|-----------|-------|
| Locale | `id-ID` |
| Listen Mode | `ListenMode.dictation` |
| Cancel on Error | `true` |
| Partial Results | `true` |

### Perilaku

- Inisialisasi mengecek ketersediaan dan locale yang didukung
- Stop TTS sebelum mulai listen (hindari mic menangkap suara TTS)
- Delay 1.5 detik setelah TTS instruksi sebelum mulai listen

---

## Background Service

### Android

```dart
AndroidConfiguration(
  onStart: _onStart,
  autoStart: false,              // Manual start
  isForegroundMode: true,        // Foreground service
  notificationChannelId: 'sight_assist_channel',
  initialNotificationTitle: 'SightAssist',
  initialNotificationContent: 'Mendengarkan perangkat BLE...',
  foregroundServiceNotificationId: 888,
)
```

### iOS

```dart
IosConfiguration(
  autoStart: false,
  onForeground: _onStart,
  onBackground: _onIosBackground,
)
```

### Heartbeat

- Timer periodik setiap 30 detik mengirim event `heartbeat` dengan timestamp
- Dapat dihentikan via event `stop`

---

## Environment Variables

File `.env` di root proyek:

```
OPENROUTER_API_KEY=sk-or-v1-xxxxx
```

Dimuat via `flutter_dotenv` dan diakses melalui `AppConstants.openRouterApiKey`.

---

## Izin (Permissions)

### Android

| Izin | Kegunaan |
|------|----------|
| `bluetoothScan` | Scan perangkat BLE |
| `bluetoothConnect` | Koneksi ke perangkat BLE |
| `locationWhenInUse` | Diperlukan BLE di Android |
| `camera` | Capture gambar |
| `microphone` | Voice input (STT) |

### iOS

| Izin | Kegunaan |
|------|----------|
| `bluetooth` | Scan & koneksi BLE |
| `camera` | Capture gambar |
| `microphone` | Voice input (STT) |

Izin **critical**: `camera` + `bluetooth`. Jika ditolak, fitur terkait tidak akan berfungsi.
