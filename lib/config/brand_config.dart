/// Konfigurasi branding terpusat — satu-satunya tempat yang perlu diubah
/// saat aplikasi ini di-white-label / dijual ke client dengan nama bisnis
/// yang berbeda (bukan "Byone Arena").
///
/// Cara pakai saat white-label ke client baru:
/// 1. Ubah nilai [appName], [shortTagline], [loginSubtitle] sesuai brand client.
/// 2. Ganti file `assets/images/logo.png` dengan logo client (ukuran & rasio sama).
/// 3. (Opsional) Sesuaikan warna brand di `lib/config/app_theme.dart`.
/// 4. Untuk nama aplikasi di OS (label ikon Android/iOS/Desktop, judul window,
///    title tab browser), sesuaikan juga file native masing-masing platform:
///    - android/app/src/main/AndroidManifest.xml (android:label)
///    - ios/Runner/Info.plist (CFBundleName/CFBundleDisplayName)
///    - web/index.html & web/manifest.json
///    - linux/CMakeLists.txt, windows/runner/Runner.rc, macos AppInfo.xcconfig
///
/// Semua teks & aset yang tampil di dalam UI Flutter sudah mengacu ke
/// class ini, jadi tidak perlu mencari & mengganti string di banyak file.
class BrandConfig {
  BrandConfig._();

  /// Nama brand/bisnis yang ditampilkan di splash screen, sidebar dashboard,
  /// role select screen, layar idle client, dan footer login.
  static const String appName = 'BYONE ARENA';

  /// Tagline singkat yang tampil di bawah logo pada layar idle client.
  static const String shortTagline = 'ONE PLACE. ALL GAMES.';

  /// Sub-judul yang tampil di bawah logo pada layar login.
  static const String loginSubtitle = 'SISTEM MANAJEMEN RENTAL';

  /// Path asset logo yang dipakai di seluruh aplikasi (login, dashboard,
  /// layar idle client). Ganti file di path ini dengan logo client.
  static const String logoAsset = 'assets/images/logo.png';

  /// Teks copyright di footer login. Tahun mengikuti tahun berjalan saat ini.
  static String get copyrightText => '© ${DateTime.now().year} $appName';
}
