import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_ps/models/tv_notification_model.dart';
import 'package:kiosk_ps/providers/notification_provider.dart';
import 'package:kiosk_ps/services/notification_service.dart';

/// Service palsu: semua request ditahan sampai test menyelesaikannya, supaya
/// urutan request (load vs toggle) bisa diuji secara deterministik.
class _FakeNotificationService extends NotificationService {
  final List<Completer<List<TvNotificationModel>>> getAllCompleters = [];
  final List<Completer<TvNotificationModel>> toggleCompleters = [];

  @override
  Future<List<TvNotificationModel>> getAll({bool activeOnly = false}) {
    final completer = Completer<List<TvNotificationModel>>();
    getAllCompleters.add(completer);
    return completer.future;
  }

  @override
  Future<NotificationLoopStatus> getLoopStatus() async {
    return const NotificationLoopStatus(
      running: false,
      activeLoopNotifications: 0,
    );
  }

  @override
  Future<TvNotificationModel> toggle(String id) {
    final completer = Completer<TvNotificationModel>();
    toggleCompleters.add(completer);
    return completer.future;
  }
}

TvNotificationModel _notification(String id, {required bool isActive}) {
  final now = DateTime.utc(2026, 11, 22, 7);
  return TvNotificationModel(
    id: id,
    title: 'Promo',
    message: 'Pesan',
    priority: 'normal',
    isActive: isActive,
    loopEnabled: false,
    loopInterval: 30,
    targetAll: true,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _seed(
  NotificationProvider provider,
  _FakeNotificationService service,
  List<TvNotificationModel> list,
) async {
  final load = provider.loadAll();
  service.getAllCompleters.removeLast().complete(list);
  await load;
}

void main() {
  test('snapshot loadAll yang basi tidak menimpa hasil toggle', () async {
    final service = _FakeNotificationService();
    final provider = NotificationProvider(service: service);
    addTearDown(provider.dispose);

    await _seed(provider, service, [_notification('n1', isActive: true)]);

    // Load kedua dimulai, tetapi belum selesai.
    final staleLoad = provider.loadAll();

    // Toggle berhasil lebih dulu; status terbaru harus menang.
    final toggleFuture = provider.toggle('n1');
    service.toggleCompleters.removeLast().complete(
          _notification('n1', isActive: false),
        );
    expect(await toggleFuture, isTrue);
    expect(provider.notifications.single.isActive, isFalse);

    // Snapshot lama (masih aktif) baru selesai -> harus dibuang.
    service.getAllCompleters.removeLast().complete(
          [_notification('n1', isActive: true)],
        );
    await staleLoad;

    expect(provider.notifications.single.isActive, isFalse);
  });

  test('toggle ganda saat request pertama berjalan hanya mengirim satu request',
      () async {
    final service = _FakeNotificationService();
    final provider = NotificationProvider(service: service);
    addTearDown(provider.dispose);

    await _seed(provider, service, [_notification('n1', isActive: true)]);

    final first = provider.toggle('n1');
    final second = provider.toggle('n1');
    expect(service.toggleCompleters.length, 1);
    expect(await second, isFalse);

    service.toggleCompleters.removeLast().complete(
          _notification('n1', isActive: false),
        );
    expect(await first, isTrue);
    expect(provider.notifications.single.isActive, isFalse);
  });
}
