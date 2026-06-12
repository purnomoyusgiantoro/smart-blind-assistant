# 🔧 Panduan Hardware — ESP32-C3 BLE Controller

Dokumen ini menjelaskan cara membuat perangkat keras (hardware) ESP32-C3 Core (SuperMini) yang terintegrasi dengan aplikasi SightAssist melalui Bluetooth Low Energy (BLE).

---

## Daftar Isi

- [Komponen yang Dibutuhkan](#komponen-yang-dibutuhkan)
- [Skema Rangkaian](#skema-rangkaian)
- [Penjelasan Pin](#penjelasan-pin)
- [Protokol BLE](#protokol-ble)
- [Firmware ESP32](#firmware-esp32)
- [Cara Upload Firmware](#cara-upload-firmware)
- [Pengujian](#pengujian)
- [Troubleshooting](#troubleshooting)
- [Pengembangan Lanjutan](#pengembangan-lanjutan)

---

## Komponen yang Dibutuhkan

### Komponen Utama

| No | Komponen | Jumlah | Keterangan |
|----|----------|--------|------------|
| 1 | ESP32-C3 Core (SuperMini atau sejenisnya) | 1 | Modul utama berbasis chip RISC-V dengan BLE 5.0 built-in, berukuran mini |
| 2 | Push Button (Tactile Switch) | 2 | Tombol aksi & tombol mode |
| 3 | Resistor 10kΩ | 2 | Pull-up resistor (opsional jika pakai internal pull-up) |
| 4 | Breadboard | 1 | Untuk prototyping |
| 5 | Kabel Jumper Male-Male | ~6 | Penghubung komponen |
| 6 | Kabel USB-C | 1 | Upload firmware & power |
| 7 | Baterai LiPo 3.7V + modul charger TP4056 | 1 | Power portabel (opsional) |
| 8 | Casing 3D Print / kotak kecil | 1 | Enclosure (opsional) |

### Alat yang Dibutuhkan

| Alat | Kegunaan |
|------|----------|
| Komputer (Windows/macOS/Linux) | Upload firmware |
| Arduino IDE atau PlatformIO | Compile & upload |
| Kabel USB | Koneksi ESP32 ke komputer |
| Multimeter (opsional) | Debug koneksi |

---

## Skema Rangkaian

### Diagram Koneksi

```
                   ESP32-C3 SuperMini / Core
                  ┌─────────────────────────┐
                  │                         │
    BTN_ACTION ──►│ GPIO 4             3V3  │──── VCC (untuk pull-up eksternal, opsional)
                  │                         │
    BTN_MODE ───►│ GPIO 5             GND  │──── GND
                  │                         │
         LED ◄───│ GPIO 8 (built-in)        │     (LED bawaan board, aktif LOW)
                  │                         │
       USB-C ◄────│ Port USB-C              │     (power + programming)
                  │                         │
                  └─────────────────────────┘
```

### Wiring Detail

```
Tombol 1 (AKSI):
  Pin 1 ─── GPIO 4 (ESP32-C3)
  Pin 2 ─── GND

Tombol 2 (MODE):
  Pin 1 ─── GPIO 5 (ESP32-C3)
  Pin 2 ─── GND

LED Indikator (built-in):
  GPIO 8 ─── LED (sudah ada di board ESP32-C3, logika aktif LOW)
```

### Skema Breadboard

```
        GND ──────────────────────────────┐
                                          │
    ┌──[BTN ACTION]──┐    ┌──[BTN MODE]──┐│
    │                │    │              ││
   GPIO 4          GND   GPIO 5        GND
    │                │    │              │
    └───ESP32-C3─────┘    └───ESP32-C3───┘

    Catatan: Menggunakan INPUT_PULLUP internal ESP32-C3
    (tidak perlu resistor eksternal)
```

---

## Penjelasan Pin

| GPIO | Fungsi | Mode | Keterangan |
|------|--------|------|------------|
| GPIO 4 | Tombol Aksi | INPUT_PULLUP | Trigger aksi utama (capture/read/navigate) |
| GPIO 5 | Tombol Mode | INPUT_PULLUP | Cycle mode berikutnya |
| GPIO 8 | LED Status | OUTPUT | Indikator koneksi BLE (built-in LED, aktif LOW) |

### Logika Tombol

- **HIGH (1)** = Tombol tidak ditekan (pull-up)
- **LOW (0)** = Tombol ditekan (terhubung ke GND)
- **Kedua tombol ditekan bersamaan** = Emergency Stop

---

## Protokol BLE

### Service & Characteristic

| Parameter | UUID | Deskripsi |
|-----------|------|-----------|
| **Service** | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` | Service utama SightAssist |
| **Characteristic** | `beb5483e-36e1-4688-b7f5-ea07361b26a8` | Trigger notification (NOTIFY) |

### Byte Commands

ESP32 mengirim **1 byte** melalui BLE notification saat tombol ditekan:

| Byte Value | Hex | Konstanta | Aksi di Aplikasi |
|------------|-----|-----------|------------------|
| 1 | `0x01` | `CMD_ACTION` | Trigger aksi sesuai mode aktif |
| 2 | `0x02` | `CMD_NEXT_MODE` | Ganti ke mode berikutnya |
| 3 | `0x03` | `CMD_STOP_ALL` | Hentikan semua proses |

### Mapping Tombol → Command

| Aksi Fisik | Command | Byte |
|------------|---------|------|
| Tekan Tombol 1 (Aksi) | `CMD_ACTION` | `0x01` |
| Tekan Tombol 2 (Mode) | `CMD_NEXT_MODE` | `0x02` |
| Tekan Tombol 1 + 2 bersamaan | `CMD_STOP_ALL` | `0x03` |

### Perilaku di Aplikasi per Mode

| Mode Aktif | Saat Tombol 1 (Aksi) Ditekan |
|------------|------------------------------|
| **General** | Mulai voice input → capture → AI describe → TTS |
| **Autopilot** | Toggle mulai/henti pemantauan otomatis (autopilot) |
| **Navigasi** | Mulai navigasi dengan GPS + kamera (auto-capture) |
| **Obrolan** | Mulai voice input untuk chat bebas (tanpa gambar) → TTS |
| **Baca Teks** | Langsung capture → AI baca seluruh teks pada gambar → TTS |

---

## Firmware ESP32

### Persiapan Arduino IDE

1. **Install Arduino IDE** dari [arduino.cc](https://www.arduino.cc/en/software)
2. **Tambah ESP32 Board**:
   - Buka **File → Preferences**
   - Di **Additional Board Manager URLs**, tambahkan:
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Buka **Tools → Board → Board Manager**
   - Cari "ESP32" dan install **esp32 by Espressif Systems**
3. **Pilih Board**: Tools → Board → **ESP32C3 Dev Module** (jika menggunakan ESP32-C3 SuperMini/Core)
4. **Pilih Port**: Tools → Port → (pilih port USB CDC yang terdeteksi)

### Kode Firmware Lengkap

Buat file baru di Arduino IDE dan paste kode berikut:

```cpp
/**
 * SightAssist ESP32-C3 BLE Controller
 * 
 * Firmware untuk perangkat IoT yang terhubung dengan
 * aplikasi SightAssist via Bluetooth Low Energy (BLE).
 * 
 * Board: ESP32-C3 SuperMini / Core
 * Tombol 1 (GPIO 4): Trigger aksi utama
 * Tombol 2 (GPIO 5): Ganti mode
 * Tombol 1+2       : Emergency stop
 * 
 * LED bawaan (GPIO 8): Indikator koneksi BLE (Aktif LOW)
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ─── Konfigurasi Pin ─────────────────────────────────────
#define BTN_ACTION_PIN    4     // Tombol aksi utama (G4)
#define BTN_MODE_PIN      5     // Tombol ganti mode (G5)
#define LED_PIN           8     // LED indikator bawaan ESP32-C3 SuperMini (GPIO 8)

// Logika LED Aktif LOW
#define LED_ON            LOW
#define LED_OFF           HIGH

// ─── BLE UUIDs (harus sama dengan di Flutter) ───────────
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define TRIGGER_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ─── BLE Commands ────────────────────────────────────────
#define CMD_ACTION       0x01   // Trigger aksi utama
#define CMD_NEXT_MODE    0x02   // Cycle ke mode berikutnya
#define CMD_STOP_ALL     0x03   // Emergency stop

// ─── Debounce ────────────────────────────────────────────
#define DEBOUNCE_MS      250   // Debounce delay (milidetik)

// ─── Variabel Global ────────────────────────────────────
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
unsigned long lastButtonPress = 0;

// ─── BLE Server Callbacks ────────────────────────────────
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    digitalWrite(LED_PIN, LED_ON);  // LED menyala saat terhubung (LOW)
    Serial.println(">> Perangkat terhubung!");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    digitalWrite(LED_PIN, LED_OFF);   // LED mati saat terputus (HIGH)
    Serial.println(">> Perangkat terputus!");
  }
};

// ─── Kirim Command via BLE ───────────────────────────────
void sendCommand(uint8_t cmd) {
  if (!deviceConnected) {
    Serial.println("!! Tidak ada perangkat terhubung");
    return;
  }

  // Debounce: abaikan jika terlalu cepat
  unsigned long now = millis();
  if (now - lastButtonPress < DEBOUNCE_MS) return;
  lastButtonPress = now;

  // Kirim notification
  pCharacteristic->setValue(&cmd, 1);
  pCharacteristic->notify();

  // Log ke Serial Monitor
  Serial.print(">> Command dikirim: 0x");
  Serial.println(cmd, HEX);

  // Feedback LED: kedip singkat
  digitalWrite(LED_PIN, LED_OFF);
  delay(50);
  digitalWrite(LED_PIN, LED_ON);
}

// ─── Setup ───────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  Serial.println("=== SightAssist ESP32-C3 BLE Controller ===");

  // Setup pin
  pinMode(BTN_ACTION_PIN, INPUT_PULLUP);
  pinMode(BTN_MODE_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LED_OFF); // Matikan di awal

  // ── Inisialisasi BLE ──
  BLEDevice::init("SightAssist-ESP32");

  // Buat BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Buat BLE Service
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // Buat BLE Characteristic (NOTIFY only)
  pCharacteristic = pService->createCharacteristic(
    TRIGGER_CHAR_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );

  // Tambah descriptor agar client bisa subscribe
  pCharacteristic->addDescriptor(new BLE2902());

  // Mulai service
  pService->start();

  // Mulai advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // Bantu koneksi iPhone
  pAdvertising->setMinPreferred(0x12);
  pAdvertising->start();

  Serial.println(">> BLE advertising dimulai...");
  Serial.println(">> Menunggu koneksi dari SightAssist app...");
}

// ─── Loop Utama ──────────────────────────────────────────
void loop() {
  // Baca state tombol (LOW = ditekan karena INPUT_PULLUP)
  bool actionPressed = digitalRead(BTN_ACTION_PIN) == LOW;
  bool modePressed   = digitalRead(BTN_MODE_PIN) == LOW;

  // Cek kombinasi tombol
  if (actionPressed && modePressed) {
    // ── Kedua tombol ditekan = Emergency Stop ──
    sendCommand(CMD_STOP_ALL);
    // Tunggu sampai kedua tombol dilepas
    while (digitalRead(BTN_ACTION_PIN) == LOW || 
           digitalRead(BTN_MODE_PIN) == LOW) {
      delay(10);
    }
  } else if (actionPressed) {
    // ── Tombol Aksi ditekan ──
    sendCommand(CMD_ACTION);
    // Tunggu sampai tombol dilepas
    while (digitalRead(BTN_ACTION_PIN) == LOW) {
      delay(10);
    }
  } else if (modePressed) {
    // ── Tombol Mode ditekan ──
    sendCommand(CMD_NEXT_MODE);
    // Tunggu sampai tombol dilepas
    while (digitalRead(BTN_MODE_PIN) == LOW) {
      delay(10);
    }
  }

  // ── Handle reconnect ──
  // Jika baru saja terputus, mulai advertising lagi
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);  // Beri waktu BLE stack
    pServer->startAdvertising();
    Serial.println(">> Advertising ulang...");
    oldDeviceConnected = deviceConnected;
  }

  // Jika baru saja terhubung
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  delay(20);  // Loop delay
}
```

---

## Cara Upload Firmware

### Langkah-langkah

1. **Hubungkan** ESP32-C3 ke komputer via kabel USB-C
2. **Buka** Arduino IDE
3. **Pilih Board**: Tools → Board → ESP32C3 Dev Module
4. **Pilih Port**: Tools → Port → (pilih port USB CDC yang terdeteksi)
5. **Copy-paste** kode firmware di atas
6. **Klik Upload** (tombol panah →)
7. **Tunggu** sampai muncul "Done uploading"

### Setting Board (Arduino IDE)

| Parameter | Nilai |
|-----------|-------|
| Board | ESP32C3 Dev Module |
| Upload Speed | 921600 |
| USB CDC On Boot | Enabled (Penting untuk Serial Monitor via USB bawaan) |
| CPU Frequency | 160MHz |
| Flash Mode | DIO (sesuai untuk ESP32-C3) |
| Flash Size | 4MB |
| Partition Scheme | Default 4MB with spiffs |

### Menggunakan PlatformIO (Alternatif)

Jika menggunakan VS Code + PlatformIO:

```ini
; platformio.ini
[env:esp32-c3]
platform = espressif32
board = esp32-c3-devkitm-1
framework = arduino
board_build.flash_mode = dio
monitor_speed = 115200
```

---

## Pengujian

### 1. Tes Serial Monitor

1. Buka **Tools → Serial Monitor** (baudrate: 115200)
2. Restart ESP32 — harus muncul:
   ```
   === SightAssist ESP32 BLE Controller ===
   >> BLE advertising dimulai...
   >> Menunggu koneksi dari SightAssist app...
   ```
3. Tekan tombol — harus muncul:
   ```
   >> Command dikirim: 0x1    (tombol aksi)
   >> Command dikirim: 0x2    (tombol mode)
   >> Command dikirim: 0x3    (kedua tombol)
   ```

### 2. Tes Koneksi BLE

1. Buka **aplikasi SightAssist** di HP
2. Buka halaman **Cari Perangkat BLE**
3. Tekan **Cari Perangkat**
4. Cari **"SightAssist-ESP32"** di daftar
5. Tekan **Connect**
6. LED di ESP32 harus **menyala**
7. Di Serial Monitor: `>> Perangkat terhubung!`

### 3. Tes Tombol

| Tes | Aksi | Hasil yang Diharapkan |
|-----|------|----------------------|
| Tombol 1 | Tekan tombol aksi | TTS: "Aku dengerin, silakan ngomong." (pada Mode General) |
| Tombol 2 | Tekan tombol mode | TTS: "Ganti ke Mode Autopilot" |
| Tombol 2 lagi | Tekan lagi | TTS: "Ganti ke Mode Navigasi" |
| Tombol 2 lagi | Tekan lagi | TTS: "Ganti ke Mode Obrolan" |
| Tombol 2 lagi | Tekan lagi | TTS: "Ganti ke Mode Baca Teks" |
| Tombol 2 lagi | Tekan lagi | TTS: "Ganti ke Mode General" (cycle lengkap) |
| Tombol 1+2 | Tekan bersamaan | TTS: "Semua proses dihentikan ya." |

### 4. Tes dengan nRF Connect (Debugging)

Aplikasi **nRF Connect** (gratis di Play Store/App Store) bisa digunakan untuk debug BLE:

1. Install **nRF Connect** di HP
2. Scan → cari "SightAssist-ESP32"
3. Connect → cari service UUID
4. Klik **notification icon** (↓) pada characteristic
5. Tekan tombol di ESP32 → nilai byte muncul di nRF Connect

---

## Troubleshooting

### ESP32 Tidak Muncul di BLE Scan

| Masalah | Solusi |
|---------|--------|
| ESP32 belum dinyalakan | Pastikan USB terhubung / baterai terisi |
| Firmware belum di-upload | Upload ulang firmware |
| BLE advertising berhenti | Reset ESP32 (tombol EN/RST) |
| Terlalu jauh | Dekatkan jarak (BLE efektif ±10 meter) |
| HP Bluetooth mati | Nyalakan Bluetooth di HP |

### Tombol Tidak Merespons

| Masalah | Solusi |
|---------|--------|
| Kabel jumper lepas | Cek koneksi di breadboard |
| Pin GPIO salah | Verifikasi: Aksi=GPIO4, Mode=GPIO5 |
| Tidak terhubung BLE | LED harus menyala (cek koneksi) |
| Debounce terlalu panjang | Kurangi `DEBOUNCE_MS` di firmware |

### LED Tidak Menyala saat Connect

| Masalah | Solusi |
|---------|--------|
| LED_PIN salah | Pastikan `LED_PIN = 8` (built-in LED pada ESP32-C3 SuperMini) |
| Logika LED terbalik | Pastikan menggunakan `LED_ON = LOW` dan `LED_OFF = HIGH` karena built-in LED berlogika aktif LOW |

### Upload Gagal

| Masalah | Solusi |
|---------|--------|
| Port tidak terdeteksi | Gunakan kabel USB-C yang mendukung data transfer. Pastikan port USB CDC bawaan ESP32-C3 terdeteksi. |
| Upload timeout / Gagal | Di board ESP32-C3 SuperMini, tekan dan tahan tombol BOOT (GPIO 9), colokkan USB-C, lalu lepas tombol BOOT untuk masuk download mode. |
| Board salah | Pilih "ESP32C3 Dev Module" di Tools → Board |

---

## Pengembangan Lanjutan

### Menambah Tombol Baru

Untuk menambah tombol ketiga (misalnya tombol volume):

1. **Hubungkan** tombol baru ke GPIO yang tersedia (misal GPIO 18)
2. **Tambah di firmware**:
   ```cpp
   #define BTN_VOLUME_PIN    18
   #define CMD_VOLUME_UP     0x04

   // Di setup():
   pinMode(BTN_VOLUME_PIN, INPUT_PULLUP);

   // Di loop():
   bool volumePressed = digitalRead(BTN_VOLUME_PIN) == LOW;
   if (volumePressed) {
     sendCommand(CMD_VOLUME_UP);
     while (digitalRead(BTN_VOLUME_PIN) == LOW) delay(10);
   }
   ```
3. **Tambah di Flutter** (`app_constants.dart`):
   ```dart
   static const int bleCmdVolumeUp = 0x04;
   ```

### Mode Power-Saving

Untuk menghemat baterai, tambahkan deep sleep:

```cpp
// Masuk deep sleep setelah 5 menit tanpa koneksi
#define SLEEP_TIMEOUT_MS  300000

unsigned long lastActivity = 0;

void loop() {
  // ... kode tombol ...

  if (!deviceConnected && (millis() - lastActivity > SLEEP_TIMEOUT_MS)) {
    Serial.println(">> Masuk deep sleep...");
    esp_deep_sleep_start();
  }

  if (deviceConnected) lastActivity = millis();
}
```

### Indikator Buzzer

Tambah buzzer untuk feedback audio di sisi hardware:

```cpp
#define BUZZER_PIN  15

// Di setup():
pinMode(BUZZER_PIN, OUTPUT);

// Setelah sendCommand():
tone(BUZZER_PIN, 1000, 100);  // Beep 1kHz selama 100ms
```

### Komunikasi 2 Arah (Receive dari App)

Untuk menerima data dari aplikasi (misal: status mode saat ini):

```cpp
// Tambah characteristic READ+WRITE
BLECharacteristic* pStatusChar = pService->createCharacteristic(
  "beb5483e-36e1-4688-b7f5-ea07361b26a9",  // UUID baru
  BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
);

// Callback saat menerima data
class MyCharCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
      Serial.print(">> Data dari app: ");
      Serial.println(value[0], HEX);
    }
  }
};

pStatusChar->setCallbacks(new MyCharCallbacks());
```

---

## Referensi Pin ESP32-C3 SuperMini

```
            ┌───────────────────┐
            │   ESP32-C3 Mini   │
       5V ──┤ [USB-C]           ├── 3V3 (Out)
      GND ──┤                   ├── GND
  GPIO 21 ──┤ TX             G9 ├── GPIO 9 (BOOT)  ◄── Strapping Pin
  GPIO 20 ──┤ RX             G4 ├── GPIO 4         ◄── BTN_ACTION
   GPIO 8 ──┤ G8             G3 ├── GPIO 3
   GPIO 7 ──┤ G7             G2 ├── GPIO 2         ◄── Strapping Pin
   GPIO 6 ──┤ G6             G1 ├── GPIO 1
   GPIO 5 ──┤ G5             G0 ├── GPIO 0
            └───────────────────┘
            Catatan: GPIO 8 adalah LED bawaan (Aktif LOW)
```

### GPIO yang Tersedia & Keterangannya

| GPIO | Status | Catatan |
|------|--------|---------|
| 0 ✅ | Aman | Tersedia untuk umum |
| 1 ✅ | Aman | Tersedia untuk umum |
| 2 ⚠️ | Strapping Pin | Harus bernilai HIGH/Floating saat boot. Hindari pull-down keras saat startup |
| 3 ✅ | Aman | Tersedia untuk umum |
| 4 ✅ | Aman | Digunakan untuk BTN_ACTION |
| 5 ✅ | Aman | Digunakan untuk BTN_MODE |
| 6 ✅ | Aman | Tersedia untuk umum |
| 7 ✅ | Aman | Tersedia untuk umum |
| 8 ⚠️ | Built-in LED | Terhubung ke LED onboard (aktif LOW). Strapping pin. |
| 9 ⚠️ | Tombol BOOT | Terhubung ke tombol BOOT fisik di board. Strapping pin (harus HIGH saat boot). |
| 10 ✅ | Aman | Tersedia untuk umum |
| 20 ✅ | Aman | RX UART (bisa dipakai sebagai GPIO biasa) |
| 21 ✅ | Aman | TX UART (bisa dipakai sebagai GPIO biasa) |
