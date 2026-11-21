import '../models/tv_notification_model.dart';

/// Aturan tampil notifikasi TV. Dipisah dari provider agar bisa diuji tanpa
/// jaringan/Flutter binding.
class NotificationPolicy {
  NotificationPolicy._();

  /// Apakah notifikasi menyasar konsol ini (dan sesi yang sedang aktif).
  static bool matchesTarget(
    TvNotificationModel n, {
    required String? consoleId,
    required bool hasActiveSession,
  }) {
    final targetOk = n.targetAll ||
        (consoleId != null && n.targetConsoleIds.contains(consoleId));
    if (!targetOk) return false;
    if (n.activeSessionsOnly && !hasActiveSession) return false;
    return true;
  }

  /// Apakah notifikasi boleh ditampilkan sekarang.
  ///
  /// - Trigger manual ("Tampilkan") SELALU menang: notifikasi akan tampil
  ///   sekali lagi meskipun sebelumnya sudah pernah tampil. Ini berlaku untuk
  ///   notifikasi manual maupun notifikasi otomatis, sehingga tombol
  ///   "Tampilkan" tidak lagi tidak berefek pada notifikasi autoShow.
  /// - Manual (autoShow=false): tanpa trigger baru tidak pernah tampil.
  /// - Sistem (autoShow=true): tampil sekali otomatis.
  /// - Loop sistem: hanya saat ada event realtime dari backend, bukan setiap
  ///   polling, supaya notifikasi tidak muncul terus setelah loop dihentikan.
  static bool shouldShow(
    TvNotificationModel n, {
    required bool realtime,
    required Set<String> shownIds,
    required Map<String, DateTime> seenTriggeredAt,
  }) {
    final triggered = n.lastTriggeredAt;
    if (triggered != null) {
      final seen = seenTriggeredAt[n.id];
      if (seen == null || triggered.isAfter(seen)) return true;
    }
    if (!n.autoShow) return false;
    if (n.loopEnabled) return realtime;
    return !shownIds.contains(n.id);
  }

  /// Pilih notifikasi yang ditampilkan. Jika event realtime menyebut ID
  /// tertentu, prioritaskan ID itu; kalau tidak ada, pakai yang pertama.
  static TvNotificationModel? pickForDisplay(
    List<TvNotificationModel> notifications, {
    String? preferredId,
  }) {
    if (notifications.isEmpty) return null;
    if (preferredId != null) {
      for (final n in notifications) {
        if (n.id == preferredId) return n;
      }
    }
    return notifications.first;
  }
}
