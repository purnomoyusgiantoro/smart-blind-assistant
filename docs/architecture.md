# 🏗️ Arsitektur Sistem

Dokumen ini menjelaskan arsitektur keseluruhan aplikasi Smart Blind Assistant (SightAssist), termasuk pola desain yang digunakan, layer abstraksi, dan alur data antar komponen.

---

## Diagram Arsitektur Tingkat Tinggi

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │   Home   │  │   Scan   │  │ Settings │  │   Log    │       │
│  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────────┘       │
│       │              │              │                            │
│  ┌────┴──────────────┴──────────────┴────────────────────┐      │
│  │                    WIDGETS (Reusable)                  │      │
│  │  ConnectionStatusCard │ AssistantStatusIndicator       │      │
│  │  ManualTriggerButton  │ ModeSwitchButton               │      │
│  │  DeviceListTile       │ SettingTile                    │      │
│  └───────────────────────────────────────────────────────┘      │
└─────────────────────────────┬───────────────────────────────────┘
                              │ Consumer<Provider>
┌─────────────────────────────┴───────────────────────────────────┐
│                        STATE LAYER (Provider)                    │
│  ┌──────────────────┐  ┌────────────────┐  ┌────────────────┐  │
│  │ AssistantProvider │  │  BleProvider   │  │SettingsProvider│  │
│  │ (Orkestrator)     │  │ (Koneksi BLE)  │  │ (Preferensi)   │  │
│  └────────┬──────────┘  └───────┬────────┘  └───────┬────────┘  │
└───────────┼─────────────────────┼───────────────────┼───────────┘
            │ Mengelola           │ Mengelola         │ Membaca/
            │ Services            │ BleService        │ Menulis
┌───────────┼─────────────────────┼───────────────────┼───────────┐
│           ▼                     ▼                   ▼            │
│                         SERVICE LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ CameraService│  │  BleService  │  │  TtsService  │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
│         │                 │                  │                   │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌──────┴───────┐           │
│  │  ApiService  │  │  SttService  │  │BackgroundSvc │           │
│  └──────┬───────┘  └──────────────┘  └──────────────┘           │
└─────────┼───────────────────────────────────────────────────────┘
          │ HTTP POST
┌─────────┼───────────────────────────────────────────────────────┐
│         ▼                EXTERNAL                                │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │ OpenRouter   │  │    ESP32     │                             │
│  │ API (Gemini) │  │ (BLE Device) │                             │
│  └──────────────┘  └──────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Pola Arsitektur

### Feature-Based Structure

Proyek ini menggunakan struktur berbasis fitur (**feature-based**) dengan pemisahan yang jelas antar layer:

```
lib/
├── core/          → Fondasi (constants, theme, utils)
├── models/        → Data classes (immutable)
├── services/      → Business logic & external I/O
├── providers/     → State management (ChangeNotifier)
├── features/      → UI screens & widgets per fitur
└── routes/        → Definisi navigasi
```

### Layer Responsibilities

| Layer | Tanggung Jawab | Contoh |
|-------|---------------|--------|
| **Core** | Konstanta, tema, utilitas bersama | `AppConstants`, `AppTheme`, `AppLogger` |
| **Models** | Representasi data (immutable) | `BleDevice`, `AiResponse`, `CapturePayload` |
| **Services** | Interaksi dengan platform/API eksternal | `BleService`, `CameraService`, `ApiService` |
| **Providers** | State management & orkestrasi | `AssistantProvider`, `BleProvider` |
| **Features** | Tampilan UI per halaman | `HomeScreen`, `ScanScreen` |
| **Routes** | Pemetaan named routes | `AppRouter` |

---

## State Management

Aplikasi menggunakan **Provider** (`ChangeNotifier`) dengan 3 provider utama:

### 1. `AssistantProvider` — Orkestrator Utama

Provider terbesar yang mengorkestrasi seluruh alur kerja aplikasi.

```
┌─────────────────────────────────────────────────┐
│              AssistantProvider                   │
│                                                  │
│  Mengelola:                                      │
│  ├── CameraService (capture gambar)              │
│  ├── ApiService (kirim ke OpenRouter)             │
│  ├── TtsService (output suara)                   │
│  ├── SttService (input suara)                    │
│  │                                               │
│  State:                                          │
│  ├── AssistantStatus (state machine)             │
│  ├── AssistantMode (capture / navigate)          │
│  ├── AiResponse? (respons terakhir)              │
│  ├── customPrompt (prompt user)                  │
│  ├── voiceText (teks dari STT)                   │
│  └── navigationIntervalSeconds                   │
└─────────────────────────────────────────────────┘
```

**State Machine — `AssistantStatus`:**

```
  ┌──────┐
  │ idle │◄──────────────────────────────────┐
  └──┬───┘                                   │
     │ trigger                               │
  ┌──▼───────┐                               │
  │capturing │                               │
  └──┬───────┘                               │
     │ berhasil                              │
  ┌──▼───────┐                               │
  │uploading │                               │
  └──┬───────┘                               │
     │ dikirim                               │
  ┌──▼────────┐                              │
  │processing │                              │
  └──┬────────┘                              │
     │ AI respons                            │
  ┌──▼───────┐                               │
  │speaking  │───── selesai ─────────────────┘
  └──────────┘

  ┌──────────┐  (mode navigasi terpisah)
  │navigating│◄──► auto-capture periodik
  └──────────┘

  ┌──────┐  (dari state manapun jika error)
  │error │───── 2 detik ──► idle / navigating
  └──────┘
```

### 2. `BleProvider` — Koneksi BLE

```
┌─────────────────────────────────────┐
│           BleProvider               │
│                                      │
│  Mengelola:                          │
│  └── BleService                      │
│                                      │
│  State:                              │
│  ├── isScanning (bool)               │
│  ├── devices (List<BleDevice>)       │
│  ├── connectedDevice (BleDevice?)    │
│  └── triggerStream (Stream<int>)     │
└─────────────────────────────────────┘
```

### 3. `SettingsProvider` — Pengaturan User

```
┌─────────────────────────────────────┐
│        SettingsProvider             │
│                                      │
│  Persisten via SharedPreferences:    │
│  ├── ttsLanguage (String)            │
│  ├── ttsSpeechRate (double)          │
│  ├── apiKey (String)                 │
│  └── autoConnect (bool)             │
└─────────────────────────────────────┘
```

---

## Provider Tree

Provider di-registrasi di `main.dart` menggunakan `MultiProvider`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => BleProvider()),
    ChangeNotifierProvider(create: (_) => AssistantProvider()),
    ChangeNotifierProvider.value(value: settingsProvider),
  ],
  child: const SightAssistApp(),
)
```

> **Catatan**: `SettingsProvider` dimuat terlebih dahulu (`loadSettings()`) sebelum `runApp()` agar pengaturan user langsung tersedia saat aplikasi dimulai.

---

## Alur Inisialisasi Aplikasi

```
main()
  │
  ├── WidgetsFlutterBinding.ensureInitialized()
  ├── SystemChrome.setPreferredOrientations([portraitUp])  ← hanya mobile
  ├── dotenv.load()                                        ← load .env
  ├── BackgroundService.initialize()                       ← hanya mobile
  ├── SettingsProvider.loadSettings()                      ← dari SharedPreferences
  │
  └── runApp(MultiProvider → SightAssistApp)
         │
         └── MaterialApp(
               theme: AppTheme.darkTheme,
               initialRoute: '/',
               routes: AppRouter.routes
             )
               │
               └── HomeScreen.initState()
                     │
                     ├── AssistantProvider.initialize()
                     │     ├── CameraService.initialize()
                     │     ├── SttService.initialize()
                     │     ├── TtsService.initialize()
                     │     └── TtsService.speak("Selamat datang")
                     │
                     └── BleProvider.isConnected?
                           └── AssistantProvider.listenToTrigger(triggerStream)
```

---

## Prinsip Desain

1. **Separation of Concerns** — UI, state, dan business logic dipisahkan ke layer berbeda
2. **Immutable Models** — Data classes menggunakan `final` fields
3. **Platform Awareness** — Fitur mobile-only (BLE, background service) di-skip secara graceful di desktop via `PlatformHelper`
4. **Centralized Config** — Semua konstanta di `AppConstants`, semua string di `AppStrings`
5. **Fail-Safe** — Setiap service mengembalikan nilai default/null saat gagal, tidak throw exception ke UI
6. **Accessibility-First** — Seluruh feedback diberikan melalui suara (TTS), UI hanya sebagai pendamping visual
