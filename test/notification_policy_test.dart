import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_ps/models/tv_notification_model.dart';
import 'package:kiosk_ps/services/notification_policy.dart';

TvNotificationModel _notification({
  String id = 'n1',
  bool autoShow = false,
  bool loopEnabled = false,
  bool targetAll = true,
  bool activeSessionsOnly = false,
  List<String> targetConsoleIds = const [],
  DateTime? lastTriggeredAt,
}) {
  final now = DateTime.utc(2026, 11, 21, 7);
  return TvNotificationModel(
    id: id,
    title: 'Himbauan',
    message: 'Jangan berisik',
    priority: 'normal',
    isActive: true,
    loopEnabled: loopEnabled,
    loopInterval: 30,
    targetAll: targetAll,
    activeSessionsOnly: activeSessionsOnly,
    targetConsoleIds: targetConsoleIds,
    autoShow: autoShow,
    lastTriggeredAt: lastTriggeredAt,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('TvNotificationModel mem-parse autoShow dan lastTriggeredAt', () {
    final n = TvNotificationModel.fromJson({
      'id': 'n1',
      'title': 'Himbauan',
      'message': 'Jangan berisik',
      'priority': 'normal',
      'isActive': true,
      'loopEnabled': false,
      'loopInterval': 30,
      'targetAll': true,
      'activeSessionsOnly': true,
      'autoShow': false,
      'lastTriggeredAt': '2026-11-21T07:01:00Z',
      'createdAt': '2026-11-21T07:00:00Z',
      'updatedAt': '2026-11-21T07:00:00Z',
    });

    expect(n.autoShow, isFalse);
    expect(n.lastTriggeredAt, DateTime.utc(2026, 11, 21, 7, 1));
  });

  group('NotificationPolicy.matchesTarget', () {
    test('targetAll selalu cocok', () {
      expect(
        NotificationPolicy.matchesTarget(
          _notification(),
          consoleId: 'tv-1',
          hasActiveSession: true,
        ),
        isTrue,
      );
    });

    test('target konsol lain tidak cocok', () {
      expect(
        NotificationPolicy.matchesTarget(
          _notification(targetAll: false, targetConsoleIds: ['tv-2']),
          consoleId: 'tv-1',
          hasActiveSession: true,
        ),
        isFalse,
      );
    });

    test('activeSessionsOnly butuh sesi aktif', () {
      final n = _notification(activeSessionsOnly: true);
      expect(
        NotificationPolicy.matchesTarget(
          n,
          consoleId: 'tv-1',
          hasActiveSession: false,
        ),
        isFalse,
      );
      expect(
        NotificationPolicy.matchesTarget(
          n,
          consoleId: 'tv-1',
          hasActiveSession: true,
        ),
        isTrue,
      );
    });
  });

  group('NotificationPolicy.shouldShow', () {
    bool show(
      TvNotificationModel n, {
      bool realtime = false,
      Set<String> shownIds = const {},
      Map<String, DateTime> seenTriggeredAt = const {},
    }) =>
        NotificationPolicy.shouldShow(
          n,
          realtime: realtime,
          shownIds: shownIds,
          seenTriggeredAt: seenTriggeredAt,
        );

    test('notifikasi sistem tampil sekali otomatis', () {
      final n = _notification(autoShow: true);
      expect(show(n), isTrue);
      expect(show(n, shownIds: {'n1'}), isFalse);
    });

    test('notifikasi manual tidak tampil tanpa trigger admin', () {
      expect(show(_notification()), isFalse);
      expect(show(_notification(), realtime: true), isFalse);
    });

    test('notifikasi manual tetap tidak tampil walau loopEnabled', () {
      expect(
        show(_notification(loopEnabled: true), realtime: true),
        isFalse,
      );
    });

    test('notifikasi manual tampil saat trigger baru', () {
      final triggered = DateTime.utc(2026, 11, 21, 7, 1);
      expect(show(_notification(lastTriggeredAt: triggered)), isTrue);
      expect(
        show(_notification(loopEnabled: true, lastTriggeredAt: triggered)),
        isTrue,
      );
    });

    test('trigger yang sama tidak tampil dua kali', () {
      final triggered = DateTime.utc(2026, 11, 21, 7, 1);
      expect(
        show(
          _notification(lastTriggeredAt: triggered),
          seenTriggeredAt: {'n1': triggered},
        ),
        isFalse,
      );
    });

    test('trigger lebih baru tampil lagi', () {
      final first = DateTime.utc(2026, 11, 21, 7, 1);
      final second = DateTime.utc(2026, 11, 21, 7, 5);
      expect(
        show(
          _notification(lastTriggeredAt: second),
          seenTriggeredAt: {'n1': first},
        ),
        isTrue,
      );
    });

    test('loop sistem hanya tampil saat event realtime', () {
      final n = _notification(autoShow: true, loopEnabled: true);
      expect(show(n), isFalse);
      expect(show(n, realtime: true), isTrue);
    });

    test('tombol Tampilkan tetap bekerja pada notifikasi otomatis yang sudah tampil',
        () {
      final triggered = DateTime.utc(2026, 11, 21, 7, 5);
      final n = _notification(
        autoShow: true,
        lastTriggeredAt: triggered,
      );
      expect(
        show(
          n,
          shownIds: {'n1'},
          seenTriggeredAt: {'n1': DateTime.utc(2026, 11, 21, 7, 1)},
        ),
        isTrue,
      );
    });
  });

  group('NotificationPolicy.pickForDisplay', () {
    test('prioritaskan ID dari event realtime', () {
      final a = _notification(id: 'a');
      final b = _notification(id: 'b');
      expect(
        NotificationPolicy.pickForDisplay([a, b], preferredId: 'b')?.id,
        'b',
      );
    });

    test('fallback ke notifikasi pertama', () {
      final a = _notification(id: 'a');
      final b = _notification(id: 'b');
      expect(NotificationPolicy.pickForDisplay([a, b])?.id, 'a');
      expect(
        NotificationPolicy.pickForDisplay([a, b], preferredId: 'x')?.id,
        'a',
      );
    });

    test('list kosong menghasilkan null', () {
      expect(NotificationPolicy.pickForDisplay(const []), isNull);
    });
  });
}
