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

## Deteksi perangkat di Linux

Selain plugin `gamepads`, aplikasi membaca sysfs Linux untuk melengkapi data:

| Data | Sumber | Contoh DualShock 4 USB |
|---|---|---|
| Transport | `/sys/class/input/jsX/device/id/bustype` | `0003` → **USB** |
| Nama | `/sys/class/input/jsX/device/name` | Sony Interactive Entertainment Wireless Controller |
| Baterai | `/sys/class/power_supply/ps-controller-battery-<MAC>` | `capacity`, `status` (Charging/Discharging) |
| Getaran | `EVIOCGBIT(EV_FF)` + `FF_RUMBLE` | DualShock 4 mendukung |

Jadi DS4 yang dicolok kabel tetap ditampilkan sebagai **USB**, walaupun nama
perangkatnya mengandung kata "Wireless".

### Pemetaan DS4 di Linux

Driver `hid-playstation` memberi urutan tombol/axis `js0` yang **berbeda**
dari entri GameControllerDB bawaan plugin `gamepads`. Karena itu aplikasi
memetakan event mentah DS4 sendiri:

| Input | js button/axis |
|---|---|
| Cross / Circle / Triangle / Square | `0 / 1 / 2 / 3` |
| L1 / R1 / L2 / R2 | `4 / 5 / 6 / 7` |
| Share / Options / PS / L3 / R3 | `8 / 9 / 10 / 11 / 12` |
| Left stick | axis `0` (X), `1` (Y) |
| L2 / R2 analog | axis `2` / `5` |
| Right stick | axis `3` (X), `4` (Y) |
| D-Pad | axis `6` (X), `7` (Y) |

Tanpa pemetaan khusus ini, tombol bisa tertukar (mis. Circle terbaca Cross)
dan trigger/analog kanan salah.

## Keterbatasan

- **Baterai** hanya tersedia di Linux untuk controller yang mengekspos
  `power_supply` (DualShock 4/DualSense via `hid-playstation`). Di platform
  lain, plugin `gamepads` belum melaporkan baterai.
- **Touchpad** klik didukung (dibaca dari event evdev `BTN_LEFT`).
  Permukaan sentuh / gerakan jari di touchpad belum dibaca.
- **L3/R3** (klik stick) dianimasikan sebagai cincin di sekitar knob analog.
- **Motion sensor** (gyro/akselerometer) DualShock 4 belum dibaca; saat ini
  fokus pada tombol, stick, trigger, baterai, dan getaran.
- Di **Android/TV**, plugin memerlukan `MainActivity` yang mengimplementasikan
  `GamepadsCompatibleActivity` (sudah ditambahkan). Controller di TV box
  opsional; menu ini tetap untuk admin.
