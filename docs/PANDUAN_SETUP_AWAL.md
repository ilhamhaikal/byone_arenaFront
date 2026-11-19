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

### Menghubungkan TV ke Server & Konsol

TV **tidak perlu** mengetik alamat server atau mengatur IP statis.

1. Pastikan TV Box dan PC server terhubung ke **router yang sama**
2. Buka aplikasi di TV → aplikasi langsung mencari server sendiri
3. TV akan menampilkan layar **"HUBUNGKAN TV INI"** beserta **kode 6 digit**
4. Di aplikasi admin → menu **Konsol** → tombol **"Hubungkan TV"**
5. Ketik kode 6 digit tersebut → pilih konsol → **Hubungkan**
6. TV otomatis beralih ke layar display

> ⚠️ Kode berlaku **15 menit**. Jika kedaluwarsa, tekan **"Minta Kode Baru"** di layar TV.

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

Setiap TV Box dikaitkan dengan satu konsol PlayStation. Prosesnya memakai
**kode 6 digit** — tidak perlu mengatur IP sama sekali.

> ✅ **Tidak perlu IP statis.** TV dikenali dari ID perangkat, jadi IP boleh
> berubah-ubah (DHCP) tanpa membuat TV "hilang".

### 8.1 Di layar TV

1. Buka aplikasi → otomatis tampil layar **HUBUNGKAN TV INI**
2. Catat **kode 6 digit** yang tampil (contoh: `482 913`)
3. TV akan terus menampilkan "Menunggu dihubungkan admin…"

> ⚠️ Kode berlaku **15 menit**. Kalau sudah lewat, tekan **Minta Kode Baru**
> dan tunggu kode baru muncul.

### 8.2 Di aplikasi admin

**Saat menambah konsol baru:**

1. Login → menu **Konsol** → tombol **Tambah**
2. Isi nama, tipe, harga, dan data lain
3. Di bagian bawah, kolom IP sudah diganti dengan **Hubungkan TV**
4. Ketik kode 6 digit dari layar TV → klik **Hubungkan TV**
5. Setelah berhasil, kolom berubah menjadi **IP Address** yang terisi otomatis
6. Klik **Tambah** untuk menyimpan konsol + menghubungkan TV

**Untuk konsol yang sudah ada:**

1. Login → menu **Konsol**
2. Klik ikon **Hubungkan TV** (kanan atas, ikon TV dengan kabel)
3. Ketik kode 6 digit dari layar TV
4. Pilih konsol tujuan (mis. **Unit 1**)
5. Klik **Hubungkan**

```
┌──────────────────────────────────────────┐
│ Hubungkan TV                             │
│                                          │
│  Kode Pairing                            │
│       4 8 2 9 1 3                        │
│                                          │
│  Hubungkan ke Konsol:  [ Unit 1  ▼ ]     │
│                                          │
│              [ Batal ] [ Hubungkan ]     │
└──────────────────────────────────────────┘
```

### 8.3 Setelah terhubung

TV langsung beralih sendiri ke layar display dan menampilkan:

- Status sesi (aktif / idle)
- Durasi berjalan
- Nama pelanggan

### 8.4 Mengganti / melepas TV

Kalau TV diganti atau dipindah ke konsol lain:

1. Menu **Konsol** → **Hubungkan TV**
2. Pilih konsol yang **sudah ada TV** (ditandai hijau)
3. Klik **"Lepaskan TV dari konsol ini"**
4. TV lama akan menampilkan kode pairing baru
5. Hubungkan TV baru dengan kodenya

> 💡 Satu konsol hanya bisa terhubung ke **satu TV**. Sistem menolak kalau
> konsol sudah dipakai TV lain — lepaskan dulu TV lamanya.

### 8.5 Labeli Setiap Unit

Tetap disarankan menempel stiker nomor unit di TV Box & konsol agar mudah
dikenali saat ada masalah:

```
┌─────────────────────┐
│   BYONE ARENA       │
│   UNIT 1            │
│   PS4 SLIM 1TB      │
└─────────────────────┘
```

---

## 9. Troubleshooting

### ❌ "Tidak dapat terhubung ke server"

| Kemungkinan | Solusi |
|---|---|
| Server belum menyala | Pastikan PC server sudah dinyalakan |
| Beda jaringan | Semua device harus di router yang SAMA |
| Firewall | Minta teknisi untuk matikan firewall |
| Admin di PC lain: alamat server salah | Perbaiki di halaman login → 🖥 Server |

### ❌ TV menampilkan kode, tapi tidak bisa dihubungkan

| Kemungkinan | Solusi |
|---|---|
| Kode salah ketik | Cocokkan lagi dengan 6 digit di layar TV |
| Kode sudah kedaluwarsa (15 menit) | Tekan **Minta Kode Baru** di TV, lalu masukkan kode baru |
| Konsol sudah dipakai TV lain | **Lepaskan TV** dulu di dialog Hubungkan TV |
| Kode sudah pernah dipakai | Kode hanya sekali pakai; minta kode baru di TV |

### ❌ TV tadinya normal, tiba-tiba minta kode lagi

- Kemungkinan TV di-**lepas** dari konsol, atau konsolnya dihapus.
- **Solusi**: hubungkan ulang memakai kode yang tampil di TV.
- **Cegah terulang**: jangan menekan "Lepaskan TV" kecuali memang mengganti TV.

---

### ❌ Layar TV hitam / loading terus

- **Normal** jika belum ada sesi — TV akan tampil "READY TO PLAY"
- Jika loading lebih dari 30 detik → cek kabel LAN / WiFi TV Box

### ❌ Login gagal

Akun default saat setup pertama:

| Username | Password | Role | Akses |
|---|---|---|---|
| `owner` | `owner123` | Superadmin | Semua akses, termasuk lisensi |
| `admin` | `admin123` | Admin | Semua menu kecuali lisensi |
| `kasir` | `kasir123` | Kasir | Dashboard, Konsol (CRUD), Controller, Member, menu Penjualan & Rental |

> ⚠️ Ganti password setelah login pertama.
> Jika tetap gagal → hubungi teknisi.

---

## Ringkasan Cepat

```
LANGKAH SETUP (SETELAH SERVER SIAP):

1. Nyalakan PC Server (teknisi)
2. Install APK ke TV Box (via flashdisk) → buka aplikasi
3. TV menampilkan kode 6 digit
4. Buka aplikasi admin → login → menu Konsol → "Hubungkan TV"
5. Ketik kode dari TV → pilih konsol → Hubungkan


SELESAI. 🎉
```

---

> 📝 Dokumen untuk pengguna akhir. Untuk setup backend & build aplikasi, hubungi developer.
