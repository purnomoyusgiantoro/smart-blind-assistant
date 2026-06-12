# 🎨 Desain UI/UX

Dokumen ini menjelaskan sistem desain, tema visual, prinsip aksesibilitas, dan komponen UI.

---

## Filosofi Desain

SightAssist dirancang dengan prinsip **"Audio-First, Visual-Second"**:

- **Pengguna utama** (tunanetra) berinteraksi melalui **suara** (TTS & STT) dan **tombol fisik** (ESP32)
- **Tampilan visual** ditujukan untuk **pendamping** yang membantu mengkonfigurasi aplikasi
- UI menggunakan **dark theme kontras tinggi**

---

## Sistem Warna

### Palet Utama

| Nama | Hex | Kegunaan |
|------|-----|----------|
| Primary (Cyan) | `#00BCD4` | Tombol utama, elemen interaktif |
| Secondary (Teal) | `#26A69A` | Elemen sekunder |
| Accent (Light Cyan) | `#4DD0E1` | Highlight, border aktif |
| Error (Red) | `#EF5350` | Error state, tombol stop |
| Success (Green) | `#66BB6A` | Status sukses, navigasi aktif |
| Warning (Orange) | `#FFA726` | Peringatan |

### Background

| Nama | Hex | Kegunaan |
|------|-----|----------|
| Scaffold | `#0D1117` | Latar belakang utama |
| Card | `#161B22` | Kartu dan container |
| Surface | `#21262D` | Surface element |

### Teks

| Nama | Hex | Kegunaan |
|------|-----|----------|
| Primary | `#F0F6FC` | Teks utama, judul |
| Secondary | `#8B949E` | Teks deskriptif |
| Muted | `#484F58` | Teks non-aktif |

---

## Tipografi (Material Design 3)

| Style | Ukuran | Weight | Kegunaan |
|-------|--------|--------|----------|
| `headlineLarge` | 28px | Bold | Judul halaman |
| `headlineMedium` | 22px | SemiBold | Sub-judul |
| `titleLarge` | 18px | SemiBold | Nama section |
| `titleMedium` | 16px | Medium | Label penting |
| `bodyLarge` | 16px | Regular | Teks body |
| `bodyMedium` | 14px | Regular | Teks secondary |
| `labelLarge` | 12px | Medium | Label kecil |

---

## Komponen UI

### Tombol

- **ElevatedButton**: Full-width, 56px tinggi, radius 14px, warna primary
- **OutlinedButton**: Border 1.5px accent, radius 14px
- **FAB**: Primary color, foreground hitam, elevation 4

### Card

- Background `#161B22`, radius 16px, border 1px surface, elevation 0

### ListTile

- Tile color `#161B22`, radius 12px, padding 16h x 4v

### Switch

- Thumb: Primary (selected) / Muted (unselected)
- Track: Primary 30% (selected) / Surface (unselected)

---

## Layout Halaman

### Home Screen

```
┌───────────────────────┐
│ AppBar [🔵] [⚙️]      │
├───────────────────────┤
│                       │
│   CAMERA PREVIEW      │  ← Flex: 3
│                       │
├───────────────────────┤
│ BLE Status            │
│ Assistant Status      │
│ Voice Prompt (mic)    │
│ [Ganti Mode] [Aksi]  │
│ Mode Label            │
└───────────────────────┘
```

### Scan Screen
- Daftar perangkat BLE dengan RSSI dan tombol connect
- Tombol scan di bawah

### Settings Screen
- Bahasa TTS, Kecepatan Bicara (slider), API Key, Auto-Connect (switch)

---

## Aksesibilitas

### Audio Feedback (TTS)

| Aksi | Pesan TTS |
|------|-----------|
| App dimulai | "Halo! SightAssist sudah siap. Tekan tombol pertama untuk ngomong, atau tombol kedua untuk ganti mode." |
| Tombol ditekan | "Oke, tunggu sebentar ya. Aku lihat dulu sekelilingmu." |
| Gambar berhasil | "Udah difoto. Lagi aku analisis ya." |
| Ganti mode | "Ganti ke [nama mode]" |
| Autopilot mulai | "Mode autopilot aktif. Aku bakal pantau sekelilingmu terus ya." |
| Navigasi mulai | "Mode navigasi aktif. Aku bakal bantu kamu tahu posisi dan arah jalan." |
| Obrolan mulai | "Mode obrolan aktif. Aku jadi asisten pribadimu. Mau ngobrolin apa?" |
| Stop semua | "Semua proses dihentikan ya." |
| Error | "Waduh, ada yang salah nih. Coba lagi ya." |

### Voice Input (STT)
- Locale: `id-ID`, mode dictation
- Partial results real-time, auto-execute setelah final result

### Desain untuk Pendamping
- Kontras tinggi (cerah di atas gelap)
- Teks besar (heading 28px, body 16px)
- Ikon + label di setiap tombol
- Indikator warna per state

---

## Orientasi & Bahasa

- **Mobile**: Dikunci portrait
- **Desktop**: Orientasi bebas
- **Bahasa UI**: Bahasa Indonesia (terpusat di `AppStrings`)
