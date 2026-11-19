# Controller Health (Cek Stick & Tombol)

Halaman **Controller** di aplikasi admin membaca controller yang terpasang di
**perangkat admin**, bukan di TV. Mendukung **Linux, Windows, dan browser**
lewat plugin [`gamepads`](https://pub.dev/packages/gamepads).

## Sumber input

| Mode | Cara mengaktifkan | Keterangan |
|---|---|---|
| `gamepads` (default) | build biasa | Controller nyata di perangkat admin |
| `mock` | `--dart-define=CONTROLLER_SOURCE=mock` | Simulasi untuk demo/testing UI |
| `ws` | `--dart-define=CONTROLLER_SOURCE=ws` | Cadangan untuk integrasi backend (belum dipakai) |

Saat memakai `mock`, AppBar menampilkan badge **SIMULASI**.

## Setup per platform

### Linux
- Colok controller USB, atau pairing Bluetooth lewat OS.
- Pastikan user yang menjalankan aplikasi punya akses ke perangkat input
  (biasanya grup `input`):
  ```bash
  sudo usermod -aG input $USER
  # logout lalu login lagi
  ```
- Cek controller terdeteksi:
  ```bash
  ls /dev/input/js* 2>/dev/null
  cat /proc/bus/input/devices | grep -i -A4 "sony\|dualshock\|dualsense"
  ```

### Windows
- Colok controller; Windows mengenali DS4/DualSense sebagai gamepad.
- Untuk **membangun** aplikasi Windows dibutuhkan Windows SDK (bagian dari
  setup Flutter Windows). Pengguna akhir tidak perlu SDK.
- Jika controller tidak terdeteksi, cek **Device Manager → Human Interface
  Devices**.

### Browser (Web)
- Buka aplikasi di Chrome/Edge.
- Browser baru menampilkan gamepad **setelah ada interaksi**: tekan tombol
  apa pun pada controller.
- Jika halaman kehilangan fokus, tekan tombol lagi.

## Arti metrik stick

| Metrik | Arti | Nilai sehat |
|---|---|---|
| **Jangkauan** | jarak maksimum stick dari pusat | ≥ 85% |
| **Drift** | posisi stick setelah dilepas & diam 0,7 detik | ≤ 0,12 |
| **Lingkaran** | kerataan jangkauan antar kuadran | ≥ 80% |

Cara menguji:
1. Putar stick **penuh ke segala arah** (atas, bawah, kiri, kanan).
2. **Lepaskan** dan diamkan ±1 detik.
3. Baca metrik. Tekan **Uji Ulang** untuk mengulang.

Interpretasi:
- **Drift** tinggi → stick tidak kembali ke tengah (aus/pegas lemah).
- **Jangkauan** rendah → stick tidak mencapai ujung (hardware/ kalibrasi).
- **Lingkaran** rendah → gerakan tidak simetris (sering karena stick kotak
  atau ada sumbu yang lemah).

## Keterbatasan

- **Baterai** tidak dilaporkan plugin `gamepads`; kartu baterai akan
  menampilkan "tidak tersedia".
- **Touchpad** hanya terbaca sebagai tombol klik (jika didukung controller),
  bukan permukaan sentuh.
- Di **Android/TV**, plugin memerlukan `MainActivity` yang mengimplementasikan
  `GamepadsCompatibleActivity` (sudah ditambahkan). Controller di TV box
  opsional; menu ini tetap untuk admin.
