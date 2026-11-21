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
  /// - Manual (autoShow=false): hanya tampil jika admin menekan "Tampilkan"
  ///   (lastTriggeredAt berubah) dan trigger itu belum pernah ditampilkan.
  ///   LoopEnabled TIDAK membuat notifikasi manual tampil sendiri.
  /// - Sistem (autoShow=true): tampil sekali otomatis.
  /// - Loop sistem: hanya saat ada event realtime dari backend (loop aktif),
  ///   bukan setiap polling, supaya notifikasi tidak muncul terus ketika
  ///   loop sudah dihentikan.
  static bool shouldShow(
    TvNotificationModel n, {
    required bool realtime,
    required Set<String> shownIds,
    required Map<String, DateTime> seenTriggeredAt,
  }) {
    if (!n.autoShow) {
      final triggered = n.lastTriggeredAt;
      if (triggered == null) return false;
      final seen = seenTriggeredAt[n.id];
      return seen == null || triggered.isAfter(seen);
    }
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
