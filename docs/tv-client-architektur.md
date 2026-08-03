# Arsitektur TV Client Byone Arena (KOREKSI PENTING dari user, jangan diulang)

Kesalahan sebelumnya: mengimplementasikan client TV sebagai "launcher hijack"
(moveTaskToBack/bringToForeground, LIVE button manual, dianggap app yang
switch foreground/background seperti app Android biasa). INI SALAH.

## Pemahaman yang BENAR (dari user langsung):
- Client TV app HANYA bertugas menampilkan notifikasi/status dari backend.
  Bukan launcher, tidak perlu moveToBackground/bringToForeground/task switching.
- State yang harus ditampilkan (murni reaktif dari data backend, tidak ada
  aksi native Android task-management):
  1. **Idle Screensaver** — default. Tampil saat: app baru start / TV baru
     dapat arus listrik / tidak ada sesi aktif / tidak ada sinyal "live".
  2. **Live** — saat ada sinyal "live" dari backend (sesi aktif berjalan),
     JANGAN tampilkan idle screensaver (render blank/transparent, biarkan
     konten asli terlihat).
  3. **Warning overlay** — sisa 5 menit terakhir & sisa 10 detik terakhir
     (overlay di atas state manapun yang sedang aktif).
  4. **Waktu Habis** — begitu waktu habis, tampilkan layar "waktu habis",
     lalu lanjut kembali ke Idle Screensaver.
- TIDAK ADA tombol LIVE yang di-tap user untuk minimize app. "Sinyal live"
  datang dari BACKEND (WS/polling), bukan aksi user di app client.
- BootReceiver (auto-launch saat boot) & category LEANBACK_LAUNCHER masih OK
  dipertahankan (sekadar memastikan app jalan otomatis saat listrik nyala),
  tapi TIDAK BOLEH ada moveToBackground/bringToForeground/LIVE-button-tap.

## Root cause bug lama yang perlu diperhatikan:
- `ActiveSessionInfo.remaining`/`isOvertime` di frontend hanya valid kalau
  sesi punya `endScheduledAt` terisi (butuh bookedDurationMinutes > 0 saat
  StartSession). Sesi open-ended (durasi 0/tanpa booking) TIDAK PERNAH
  memicu warning/overtime — ini BY DESIGN, bukan bug, tapi bisa
  disalahpahami sebagai "warning tidak pernah muncul" kalau testing pakai
  sesi open-ended.
- `ClientProvider._state` (dipakai buat nentuin idle/active/overtime) HANYA
  di-update saat `_setConsole` dipanggil (poll HTTP tiap 10 detik atau
  dipicu event WS) — bukan live per detik. Ticker 1 detik di
  client_display_screen.dart cuma buat hitung mundur warning teks &
  animasi, bukan buat update `p.state`.
