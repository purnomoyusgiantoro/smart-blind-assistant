# 📖 Buku Panduan Pengguna: Smart Blind Assistant (Sinar)

Selamat datang di Buku Panduan Pengguna **Sinar (Smart Blind Assistant)**. Aplikasi ini dirancang sebagai asisten pintar untuk membantu Anda mengetahui keadaan sekitar, menavigasi jalan, serta membacakan teks dengan bantuan Kecerdasan Buatan (AI) dan suara.

Panduan ini akan memandu Anda mulai dari persiapan awal hingga cara penggunaan sehari-hari.

---

## 1. Persiapan Awal

Sebelum mulai menggunakan Sinar, pastikan Anda telah menyiapkan hal-hal berikut:

1. **Smartphone**: Android atau iPhone yang sudah terinstal aplikasi Sinar.
2. **Remote Pintar (ESP32)**: Perangkat kecil dengan dua tombol yang akan Anda genggam untuk mengendalikan aplikasi tanpa harus menyentuh layar HP.
3. **Penyangga HP / Tas Dada (Opsional)**: Untuk meletakkan HP di dada agar kamera HP menghadap ke depan dan dapat "melihat" jalan di depan Anda.

---

## 2. Cara Menghubungkan Aplikasi dengan Remote

Agar remote pintar bisa mengendalikan HP, keduanya harus dihubungkan melalui Bluetooth (BLE).

1. Buka aplikasi **Sinar** di HP Anda.
2. Saat pertama kali dibuka, aplikasi akan meminta izin untuk menggunakan **Kamera**, **Mikrofon**, **Lokasi**, dan **Bluetooth**. Izinkan semua permintaan tersebut agar aplikasi dapat berfungsi normal.
3. Nyalakan Remote Pintar (ESP32) Anda.
4. Di halaman utama aplikasi Sinar, proses pemindaian (scanning) akan mencari perangkat. Pilih perangkat bernama **SightAssist-ESP32** (Aplikasi otomatis membacakan teks menggunakan sistem *Text-to-Speech* bawaan).
5. Jika berhasil terhubung, aplikasi akan mengeluarkan suara konfirmasi bahwa asisten siap digunakan.

---

## 3. Memahami Tombol pada Remote

Remote pintar Anda memiliki **2 tombol utama**. Semua interaksi dengan Sinar dikendalikan melalui kedua tombol ini, sehingga Anda tidak perlu menyentuh layar HP saat berjalan.

| Tombol | Cara Menekan | Fungsi |
|---|---|---|
| **Tombol 1** (Kiri / Atas) | **Tekan & Tahan saat bicara** | **Memberikan Perintah Suara.** Tahan tombol ini, sebutkan instruksi Anda, lalu lepaskan (layaknya *Walkie-Talkie*). |
| **Tombol 2** (Kanan / Bawah) | **Tekan 1 Kali** | **Mengganti Mode.** Berpindah dari satu mode ke mode berikutnya dalam siklus. |
| **Tombol 1 + Tombol 2** | **Tekan Bersamaan** | **Berhenti Darurat.** Menghentikan proses AI yang sedang berjalan atau mematikan suara AI yang sedang membacakan respons. |

---

## 4. Penjelasan 5 Mode Operasi

Aplikasi ini memiliki 5 mode berbeda untuk berbagai kebutuhan. Setiap kali Anda menekan **Tombol 2**, Sinar akan berpindah ke mode berikutnya dan akan langsung mengumumkan nama mode yang aktif.

### 1. Mode General (Umum) 👁️
*   **Kegunaan**: Tanya apa saja tentang objek atau situasi di depan Anda.
*   **Cara Pakai**: Tekan Tombol 1 dan tanyakan sesuatu, misal: *"Apa warna baju orang di depan saya?"* atau *"Apakah pintu itu terbuka?"*. Sinar akan mengambil foto dari kamera, memprosesnya dengan AI, dan menjawab secara lisan.

### 2. Mode Autopilot (Otomatis) 🤖
*   **Kegunaan**: AI akan berjaga otomatis tanpa perlu Anda suruh (Fokus pada Keselamatan).
*   **Cara Pakai**: Setelah mengaktifkan mode ini, Anda cukup berjalan seperti biasa. Sinar akan memindai sekitar setiap beberapa detik dan memperingatkan secara otomatis jika ada objek penting, misal: *"Awas, ada sepeda motor terparkir di depan Anda."*

### 3. Mode Navigasi 🧭
*   **Kegunaan**: Memandu jalan berbasis tujuan menggunakan GPS dan Kamera.
*   **Cara Pakai**: Tekan Tombol 1 dan sebutkan tujuan Anda, misalnya: *"Pandu saya berjalan ke minimarket terdekat."* AI akan menggabungkan data lokasi dan tampilan visual untuk memberi arahan detail (misal: *"Jalan lurus 10 meter, minimarket ada di kanan."*)

### 4. Mode Obrolan 💬
*   **Kegunaan**: Mengobrol ringan dengan AI **tanpa menggunakan kamera**.
*   **Cara Pakai**: Tekan Tombol 1 dan tanyakan apa saja (seperti asisten virtual pada umumnya). Berguna jika Anda hanya butuh info (cuaca, waktu, atau saran umum) karena mode ini menghemat baterai dengan mematikan kamera.

### 5. Mode Read (Membaca Teks) 📖
*   **Kegunaan**: Menggunakan AI *(Optical Character Recognition)* untuk membacakan teks tertulis di dunia nyata.
*   **Cara Pakai**: Arahkan HP ke arah tulisan (seperti menu restoran, bungkus makanan, atau papan nama). Tekan Tombol 1 dan bilang *"Tolong bacakan teks ini."* Sinar akan membacakan semuanya untuk Anda.

---

## 5. Contoh Skenario Penggunaan (Jalan-Jalan ke Luar)

Berikut adalah gambaran bagaimana Sinar membantu Anda melangkah dari rumah hingga tujuan:

1. **Keluar Rumah**: Masukkan HP ke dalam tas dada (kamera menghadap depan). Nyalakan Remote dan buka aplikasi.
2. **Saat Berjalan**: Tekan Tombol 2 sampai Sinar berkata, *"Mode Autopilot aktif"*. Anda bebas melangkah. Tiba-tiba Sinar menegur: *"Berhenti, ada lubang di trotoar di depan."* Anda pun bisa menghindarinya dengan aman.
3. **Mencari Tempat**: Anda ingin mencari toko buku. Anda ubah ke *"Mode Navigasi"* lalu menekan Tombol 1: *"Tolong arahkan ke toko buku maju jaya."* Sinar memandu langkah Anda.
4. **Membaca Tulisan**: Sampai di toko buku, Anda memegang sebuah buku. Anda ganti ke *"Mode Read"*, tekan Tombol 1, dan Sinar membacakan judul buku serta nama pengarang di sampulnya.

---

## 6. Mengakhiri Penggunaan Sinar

Sinar dirancang fleksibel:
1. Cukup tutup aplikasi di HP Anda atau matikan saklar pada Remote Pintar ESP32.
2. Saat koneksi terputus, Sinar otomatis mematikan layanan kamera dan layanan latar belakang (*background service*) untuk menghemat baterai.

---

## 7. Tips Tambahan & Troubleshooting

*   **Kok Sinar diam saja/tidak menjawab?**
    Aplikasi Sinar sangat membutuhkan **Koneksi Internet (Data/Wi-Fi)** yang stabil agar AI dapat memproses gambar dan suara. Pastikan koneksi Anda lancar.
*   **Tebakan Sinar kurang tepat atau buram?**
    Pastikan lensa kamera belakang HP Anda bersih dan tidak tertutup ritsleting jaket, kain tas, atau debu.
*   **Remote ditekan tapi tidak ada respons?**
    Pastikan jarak antara HP Anda dan Remote ESP32 tidak terhalang parah atau berada di luar jangkauan Bluetooth (ideal 1-5 meter).
*   **Sinar bicaranya kepanjangan, saya ingin dia diam!**
    Langsung tekan **Tombol 1 & 2 secara bersamaan**. Pembicaraan akan terpotong (Emergency Stop).

---
*Semoga aplikasi Sinar dapat membantu kemandirian langkah Anda!*
