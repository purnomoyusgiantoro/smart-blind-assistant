# ⚙️ Alur Kerja (Workflow)

Dokumen ini menjelaskan alur kerja utama aplikasi SightAssist, termasuk pipeline capture-analyze-speak dan mode navigasi.

---

## Lima Mode Operasi

SightAssist memiliki **5 mode asisten** yang dapat dipilih pengguna:

| Mode | Deskripsi | Input / Sensor Utama | Perilaku Trigger (Tombol Aksi) |
|------|-----------|----------------------|--------------------------------|
| **General** | Deskripsi umum lingkungan & objek | Kamera + Voice Prompt (STT) | Tanya suara → foto → AI analisis |
| **Autopilot** | Pemantauan berkala otomatis | Kamera (terus menerus) | Toggle mulai/henti autopilot |
| **Navigasi** | Arah jalan & posisi rintangan | Kamera + GPS Lokasi | Deteksi koordinat + foto + rute aman |
| **Obrolan** | Percakapan bebas dengan AI | Suara (tanpa Kamera) | Tanya suara → kirim teks → respons AI |
| **Baca Teks** | Membaca tulisan, papan, label | Kamera | Foto langsung → baca teks (OCR) |

---

## 1. Mode General & Baca Teks — Pipeline

```
┌──────────┐     ┌───────────┐     ┌───────────┐     ┌──────────┐     ┌──────────┐
│  TRIGGER │────▶│ VOICE     │────▶│ CAPTURE   │────▶│ PROCESS  │────▶│ SPEAK    │
│          │     │ INPUT     │     │ (kamera)  │     │ (AI API) │     │ (TTS)    │
└──────────┘     └───────────┘     └───────────┘     └───────────┘     └──────────┘
  BLE/UI           STT id-ID         captureFrame()    analyzeImage()   speak()
```

### Langkah Detail
1. **TRIGGER** — Pengguna menekan tombol aksi (BLE ESP32 atau tombol UI).
2. **VOICE INPUT** (Hanya Mode General):
   - TTS: "Aku dengerin, silakan ngomong."
   - STT mendengarkan instruksi/pertanyaan custom dalam Bahasa Indonesia.
   - Jika kosong/tanpa suara, default menggunakan prompt deskripsi lingkungan.
   - *Catatan: Mode Baca Teks melewati langkah ini dan langsung melakukan capture.*
3. **CAPTURE** — `CameraService.captureFrame()` mengambil satu frame dari kamera belakang.
4. **PROCESS** — `ApiService.analyzeImage(payload)` mengirim gambar base64 ke OpenRouter API (Gemini Vision).
5. **SPEAK** — `TtsService.speak()` membacakan hasil deskripsi AI kepada pengguna.

---

## 2. Mode Autopilot & Navigasi — Analisis Periodik

```
startAutopilot() / startNavigation()
  │
  ├── Inisialisasi kamera (jika belum aktif)
  ├── Status → autopiloting / navigating
  ├── TTS: "Mode autopilot aktif..." / "Mode navigasi aktif..."
  │
  └── Timer.periodic(30 detik)
        │
        └── executePipeline()
              ├── captureFrame()
              ├── Dapatkan GPS koordinat (Khusus Mode Navigasi)
              ├── analyzeImage() dengan prompt asisten yang sesuai
              ├── speak(response)
              └── Status tetap aktif (autopiloting / navigating)
```

---

## 3. Mode Obrolan — Asisten Percakapan (Tanpa Gambar)

```
startChat()
  │
  ├── TTS: "Mode obrolan aktif. Aku jadi asisten pribadimu. Mau ngobrolin apa?"
  ├── isRecording = true
  └── SttService.startListening()
        │
        └── onResult(text, isFinal=true)
              ├── Kirim teks percakapan ke ApiService.chat(text)
              ├── TtsService.speak(aiResponse)
              └── Kembali ke status idle / mendengarkan
```

---

## Integrasi BLE → Pipeline

```
ESP32 (tombol fisik)
  │
  │ BLE Notification (byte value)
  ▼
BleService.triggerStream
  │
  ▼
BleProvider.triggerStream
  │
  ▼
AssistantProvider.listenToTrigger()
  │
  ▼
handleActionTrigger()
  │
  ├── Mode General/Obrolan → startVoiceInput() / stopVoiceInput()
  ├── Mode Autopilot/Navigasi → toggleAutopilot() / toggleNavigation()
  └── Mode Baca Teks → executePipeline() langsung (tanpa tanya suara)
```

---

## Alur Voice Input (STT)

```
toggleVoiceInput()
  │
  ├── Stop TTS (agar mic tidak tangkap suara TTS)
  ├── isRecording = true
  ├── TTS: "Silakan bicara sekarang"
  ├── Delay 1.5 detik (tunggu TTS selesai)
  │
  └── SttService.startListening(locale: 'id-ID')
        │
        ├── onResult(text, isFinal=false)
        │     └── Update voiceText (tampil di UI)
        │
        └── onResult(text, isFinal=true)
              ├── customPrompt = text
              ├── TTS: "Prompt diterima: {text}"
              └── executePipeline()  ← auto-execute
```

---

## Error Handling

```
executePipeline()
  │
  ├── try
  │     ├── capturing → uploading → processing → speaking → idle
  │     └── (jika wasNavigating: kembali ke navigating)
  │
  └── catch
        ├── errorMessage = e.toString()
        ├── Status → error
        ├── TTS: "Maaf, terjadi kesalahan..."
        ├── Delay 2 detik
        └── Status → idle (atau navigating)
```

Semua error ditangani secara graceful tanpa crash. Pengguna selalu mendapat feedback suara.

---

## Lifecycle

```
HomeScreen
  │
  ├── initState() → AssistantProvider.initialize()
  │
  └── dispose() → (auto via Provider)
        ├── CameraService.dispose()
        ├── TtsService.dispose()
        ├── SttService.dispose()
        ├── BleService.dispose()
        └── NavigationTimer.cancel()
```
