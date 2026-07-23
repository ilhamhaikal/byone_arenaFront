# 🎮 Panduan Setup Awal — BYONE ARENA

> **Untuk orang awam** | Bahasa Indonesia | Versi Juli 2026

---

## Daftar Isi

1. [Apa yang Dibutuhkan](#1-apa-yang-dibutuhkan)
2. [Aplikasi Admin — Desktop Linux](#2-aplikasi-admin--desktop-linux)
3. [Aplikasi Admin — Desktop Windows](#3-aplikasi-admin--desktop-windows)
4. [Aplikasi Admin — Website (Browser)](#4-aplikasi-admin--website-browser)
5. [Aplikasi Admin — APK (HP Android)](#5-aplikasi-admin--apk-hp-android)
6. [Aplikasi Client TV — APK (Android TV Box)](#6-aplikasi-client-tv--apk-android-tv-box)
7. [Setting Server Pertama Kali](#7-setting-server-pertama-kali)
8. [Menghubungkan TV Box ke Konsol](#8-menghubungkan-tv-box-ke-konsol)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Apa yang Dibutuhkan

### Perangkat

| Perangkat | Jumlah | Fungsi |
|---|---|---|
| PC / Laptop | 1 | Menjalankan aplikasi admin |
| Android TV Box | 1 per TV | Menampilkan status di TV pelanggan |
| Router / Switch | 1 | Jaringan LAN |
| Kabel LAN / WiFi | secukupnya | Menghubungkan perangkat |

> ⚠️ **PENTING**: Semua perangkat harus terhubung ke router yang **SAMA** (satu jaringan LAN).

### File Aplikasi

| File | Untuk |
|---|---|
| `kiosk_ps` (Linux) | Aplikasi admin di PC Linux |
| `kiosk_ps.exe` (Windows) | Aplikasi admin di PC Windows |
| `app-release.apk` | Aplikasi admin HP & client display TV |

> ℹ️ File-file ini disediakan oleh developer. Simpan di flashdisk atau kirim via WhatsApp.

---

## 2. Aplikasi Admin — Desktop Linux

### 2.1 Jalankan aplikasi

1. Copy folder aplikasi ke PC Linux (via flashdisk)
2. Klik 2x file **`kiosk_ps`**
3. Aplikasi akan terbuka

### 2.2 Setting server

Jika admin & server di PC yang **sama** → **tidak perlu setting apa-apa**. Langsung login.

Jika PC admin **berbeda** dari PC server → lihat [Setting Server](#7-setting-server-pertama-kali).

### 2.3 Auto-Start (buka otomatis saat PC menyala)

Agar aplikasi langsung terbuka setiap PC dinyalakan, tanpa perlu klik manual:

1. Buka folder aplikasi → klik kanan file **`kiosk_ps`**
2. Pilih **Copy** (atau tekan `Ctrl+C`)
3. Buka **File Manager** → ketik di address bar:
   ```
   ~/.config/autostart
   ```
4. Jika folder `autostart` belum ada → buat folder baru dengan nama `autostart`
5. Klik kanan di dalam folder → **Paste** (atau `Ctrl+V`)
6. **Restart PC** untuk test — aplikasi akan terbuka sendiri

> 💡 Untuk test tanpa restart: buka terminal → ketik `~/.config/autostart/kiosk_ps` → Enter.

---

## 3. Aplikasi Admin — Desktop Windows

### 3.1 Jalankan aplikasi

1. Copy folder aplikasi ke PC Windows (via flashdisk)
2. Klik 2x file **`kiosk_ps.exe`**
3. Jika muncul peringatan "Windows protected your PC":
   - Klik **"More info"**
   - Klik **"Run anyway"**

### 3.2 Setting server

Jika admin & server di PC yang **sama** → **tidak perlu setting apa-apa**.

Jika PC admin **berbeda** → lihat [Setting Server](#7-setting-server-pertama-kali).

### 3.3 Auto-Start (buka otomatis saat PC menyala)

1. Klik kanan file **`kiosk_ps.exe`** → **Create shortcut**
2. Tekan tombol keyboard **`Win + R`** bersamaan → ketik:
   ```
   shell:startup
   ```
3. Tekan Enter → folder **Startup** akan terbuka
4. Drag file **shortcut** (yang dibuat di langkah 1) ke folder Startup
5. **Restart PC** untuk test — aplikasi akan terbuka sendiri

> 💡 Shortcut bisa di-rename menjadi "Byone Arena Admin" agar lebih rapi.

---

## 4. Aplikasi Admin — Website (Browser)

### 4.1 Buka website

Buka browser (Chrome / Firefox / Edge), kunjungi alamat yang diberikan developer, contoh:
```
http://192.168.1.55:3000
```

Atau jika dibuka dari PC server sendiri:
```
http://localhost:3000
```

### 4.2 Setting server

Jika dibuka dari PC server → langsung login.

Jika dibuka dari PC lain → lihat [Setting Server](#7-setting-server-pertama-kali).

---

## 5. Aplikasi Admin — APK (HP Android)

### 5.1 Install APK

1. Dapatkan file **`app-release.apk`** (via WhatsApp / Bluetooth / flashdisk)
2. Buka file APK di HP
3. Izinkan **"Install from unknown source"** jika diminta
4. Klik **Install**
5. Buka aplikasi **"Kiosk PS"** dari menu HP

### 5.2 Setting server

1. Aplikasi terbuka → halaman login
2. Klik **"Server: localhost:8080"** di bagian bawah
3. Ketik `http://192.168.xxx.xxx:8080/api/v1` (ganti xxx.xxx dengan IP server)
4. Klik tombol **💾 Save**
5. Login seperti biasa

---

## 6. Aplikasi Client TV — APK (TV Box)

> APK yang **sama** dengan admin. Satu file untuk semua keperluan.
> Cocok untuk **Android TV**, **Google TV**, Xiaomi TV Stick, Mi Box, Chromecast, dll.

---

### 6A. Android TV (Tampilan Lama)

TV dengan tampilan baris ikon di kiri/bawah, seperti Sony, Sharp, TCL, Polytron.

#### Install APK

1. Copy `app-release.apk` ke flashdisk
2. Colok flashdisk ke TV Box
3. Buka aplikasi **File Manager** / **File Commander**
4. Cari file APK → klik → **Install**
5. Jika muncul "Install blocked" → **Settings** → **Security & restrictions** → **Unknown sources** → nyalakan

> 💡 **Tips**: Bisa juga install **"Send Files to TV"** dari Play Store untuk transfer APK via WiFi (tanpa flashdisk).

---

### 6B. Google TV (Tampilan Baru)

TV dengan tampilan rekomendasi penuh layar & tab di atas (For You, Movies, Shows, Apps).
Contoh: Chromecast with Google TV, Xiaomi TV Box, Mi Stick, Realme Stick, TCL Google TV, Sony Google TV.

#### Langkah 1: Aktifkan Mode Developer

1. Buka **Settings** (ikon ⚙️ di pojok kanan atas)
2. Pilih **System** → **About**
3. Scroll ke **Android TV OS build** → klik **7x** sampai muncul "You are now a developer!"

#### Langkah 2: Izinkan Install dari USB

1. Kembali ke **Settings** → **Apps** → **Security & restrictions**
2. Pilih **Unknown sources** → nyalakan untuk **File Manager**

#### Langkah 3: Install APK

1. Copy `app-release.apk` ke flashdisk
2. Colok flashdisk ke TV Box
3. Buka **File Manager** (jika tidak ada, install **"File Commander"** dari Play Store)
4. Cari file APK di folder USB → klik → **Install**

> 💡 **Tips Google TV**: Install aplikasi **"Send Files to TV"** dari Play Store. Lebih praktis — kirim APK dari HP langsung ke TV tanpa flashdisk.

---

### 6C. Cara Transfer APK Tanpa Flashdisk (WiFi)

1. Di TV Box: buka Play Store → install **"Send Files to TV"**
2. Di HP: install **"Send Files to TV"** dari Play Store
3. Buka aplikasi di HP → pilih APK → pilih TV Box → **Send**
4. Di TV Box: terima file → buka → **Install**

---

### Setting Server (berlaku untuk SEMUA TV)

1. Buka aplikasi di TV
2. Pilih mode **📺 Client Display**
3. Klik **"Server: localhost:8080"**
4. Ketik `http://192.168.xxx.xxx:8080/api/v1` (IP server)
5. Klik **💾 Save**

> ⚠️ Setting server **hanya 1x**. Selanjutnya otomatis.

---

## 7. Setting Server Pertama Kali

Saat **pertama kali** buka aplikasi di device manapun:

```
┌──────────────────────────────────────────┐
│                                          │
│         [LOGO BYONE ARENA]               │
│     SISTEM MANAJEMEN RENTAL              │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  ▎MASUK KE AKUN                    │  │
│  │                                    │  │
│  │  👤 USERNAME: [________]           │  │
│  │  🔒 PASSWORD: [________]           │  │
│  │                                    │  │
│  │  [═══════ MASUK ═══════]           │  │
│  └────────────────────────────────────┘  │
│                                          │
│  🖥 Server: localhost:8080       ▼      │  ← KLIK DI SINI
│                                          │
└──────────────────────────────────────────┘
```

### Saat diklik:

```
┌──────────────────────────────────────────┐
│  🖥 Server: localhost:8080       ▲      │
│  ┌────────────────────────────────────┐  │
│  │ http://192.168.1.55:8080/api/v1    │  │  ← Ketik IP server
│  │                            [💾]    │  │  ← Klik Save
│  └────────────────────────────────────┘  │
│  ✅ Server disimpan: http://192.168...   │
└──────────────────────────────────────────┘
```

### Kapan perlu setting server?

| Situasi | Yang Diketik |
|---|---|
| **Admin di PC yang sama** dengan server | Tidak perlu ubah (pakai default) |
| Admin di PC/Laptop **berbeda** | `http://192.168.xxx.xxx:8080/api/v1` |
| TV Box / HP Android | `http://192.168.xxx.xxx:8080/api/v1` |
| Website di PC server | Tidak perlu ubah |
| Website di PC lain | `http://192.168.xxx.xxx:8080/api/v1` |

> 💡 **Cara tahu IP server**: Tanya ke developer / teknisi yang setup backend. Biasanya berupa angka seperti `192.168.1.55`.

---

## 8. Menghubungkan TV Box ke Konsol

Setiap TV Box harus dikaitkan dengan konsol PlayStation yang terhubung.

> ⚠️ **WAJIB: Set IP Static!**  
> Jika IP TV Box berubah-ubah (DHCP), konsol bisa **tidak terdeteksi** dan Anda tidak tahu unit mana yang bermasalah.  
> Setiap TV Box harus punya **IP tetap** agar mudah diidentifikasi.

---

### 8.1 Set IP Static di TV Box

#### Android TV (tampilan lama)

1. Buka **Settings** → **Network & Internet**
2. Pilih WiFi/Ethernet yang tersambung
3. Pilih **IP settings** → ubah dari **DHCP** ke **Static**
4. Isi:
   - **IP Address**: `192.168.1.201` (untuk TV unit 1)
   - **Gateway**: `192.168.1.1` (IP router)
   - **DNS**: `8.8.8.8`
5. Klik **Save**

#### Google TV (tampilan baru)

1. Buka **Settings** (⚙️) → **Network & Internet**
2. Klik WiFi/Ethernet yang tersambung
3. Scroll ke **IP settings** → ganti **DHCP** → **Static**
4. Isi IP, Gateway, DNS seperti di atas
5. Klik **Save**

---

### 8.2 Aturan Pemberian IP

Buat daftar IP yang rapi agar mudah mengingat:

| Unit | TV Box | IP Static | Console |
|---|---|---|---|
| Unit 1 | TV Box 1 | `192.168.1.201` | PS4 SLIM 1TB |
| Unit 2 | TV Box 2 | `192.168.1.202` | PS4 PRO |
| Unit 3 | TV Box 3 | `192.168.1.203` | PS5 |
| Unit 4 | TV Box 4 | `192.168.1.204` | PS4 FAT |

> 💡 **Tips**: Sesuaikan angka akhir IP dengan nomor unit. Contoh: Unit 1 → `.201`, Unit 2 → `.202`, dst. Mudah diingat!

---

### 8.3 Masukkan IP ke Admin Panel

1. Buka aplikasi admin → login
2. Menu **Konsol** → klik konsol yang ingin dihubungkan
3. Isi **IP Address** dengan IP static TV Box
4. Klik **Simpan**

```
┌─────────────────────────────────────────┐
│ Edit Konsol                             │
│                                         │
│ Nama:        [PS4 SLIM 1TB            ] │
│ IP Address:  [192.168.1.201           ] │  ← IP static TV Box
│                                         │
│ [ SIMPAN ]                              │
└─────────────────────────────────────────┘
```

---

### 8.4 Labeli Setiap Unit

Tempel stiker di setiap TV Box & konsol:

```
┌─────────────────────┐
│   BYONE ARENA       │
│   UNIT 1            │
│   192.168.1.201     │
│   PS4 SLIM 1TB      │
└─────────────────────┘
```

> Dengan label, saat ada masalah di Unit 3 → langsung tahu IP `192.168.1.203` → cek di halaman Log TV → tahu riwayatnya.

---

### 8.5 Verifikasi

TV Box akan otomatis mendeteksi konsol dan menampilkan:
- Status sesi (aktif / idle)
- Durasi berjalan
- Nama pelanggan

---

## 9. Troubleshooting

### ❌ "Tidak dapat terhubung ke server"

| Kemungkinan | Solusi |
|---|---|
| IP server salah | Cek ulang IP server yang diketik |
| Server belum menyala | Pastikan PC server sudah dinyalakan |
| Beda jaringan | Semua device harus di router yang SAMA |
| Firewall | Minta teknisi untuk matikan firewall |

### ❌ "Konsol tidak ditemukan" (di TV)

| Kemungkinan | Solusi |
|---|---|
| IP TV Box belum di-set | Masukkan IP TV Box di admin panel (lihat Bab 8) |
| IP TV Box berubah (DHCP) | Set IP static — jangan pakai DHCP (lihat Bab 8.1) |
| Konsol belum dibuat | Buka admin → Konsol → Tambah Konsol |

### ❌ TV tadinya normal, tiba-tiba "tidak ditemukan"

- **Penyebab paling umum**: IP TV Box berubah karena DHCP.
- **Solusi**: Set IP static di TV Box (lihat Bab 8.1), lalu update IP di admin panel.
- **Cegah terulang**: Pastikan SEMUA TV Box pakai IP static.

### ❌ Layar TV hitam / loading terus

- **Normal** jika belum ada sesi — TV akan tampil "READY TO PLAY"
- Jika loading lebih dari 30 detik → cek kabel LAN / WiFi TV Box

### ❌ Login gagal

- Username & password default: **`admin`** / **`admin123`**
- Jika tetap gagal → hubungi teknisi

---

## Ringkasan Cepat

```
LANGKAH SETUP (SETELAH SERVER SIAP):

1. Nyalakan PC Server (teknisi)
2. Buka aplikasi admin → login (admin / admin123)
3. Buat konsol → isi IP TV Box
4. Install APK ke TV Box → pilih Client Display
5. Di TV Box → set server ke IP server (1x saja)


SELESAI. 🎉
```

---

> 📝 Dokumen untuk pengguna akhir. Untuk setup backend & build aplikasi, hubungi developer.
