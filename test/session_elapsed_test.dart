import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_ps/models/console_overview_model.dart';
import 'package:kiosk_ps/models/session_model.dart';

void main() {
  test('elapsed tidak negatif saat start_time masih di depan (setup grace)',
      () {
    final future = DateTime.now().add(const Duration(minutes: 2));

    final session = SessionModel(
      id: 's1',
      consoleId: 'c1',
      status: 'active',
      startTime: future,
    );
    expect(session.elapsed, Duration.zero);

    final active = ActiveSessionInfo(
      id: 's1',
      startTime: future,
      bookedDurationMinutes: 60,
      remainingMinutes: 62,
    );
    expect(active.elapsed, Duration.zero);
    expect(active.progress, 0);
  });

  test('SessionModel mem-parse sisa waktu simpan dan expiry 24 jam', () {
    final session = SessionModel.fromJson({
      'id': 's1',
      'consoleId': 'c1',
      'status': 'interrupted',
      'startTime': '2026-11-26T10:00:00Z',
      'remainingMinutes': 20,
      'savedTimeExpiresAt': '2026-11-27T10:00:00Z',
      'interruptedReason': 'saved_by_admin',
      'isPackage': true,
    });

    expect(session.isInterrupted, isTrue);
    expect(session.remainingRecoveryMinutes, 20);
    expect(session.savedTimeExpiresAt, DateTime.utc(2026, 11, 27, 10));
    expect(session.hasSavedTime, isTrue);
    expect(session.interruptedReason, 'saved_by_admin');
    expect(session.isPackage, isTrue);
  });

  test('ActiveSessionInfo mem-parse status member', () {
    final active = ActiveSessionInfo.fromJson({
      'id': 's1',
      'startTime': '2026-11-26T10:00:00Z',
      'bookedDurationMinutes': 60,
      'remainingMinutes': 30,
      'isMember': true,
      'isPackage': true,
    });

    expect(active.isMember, isTrue);
    expect(active.isPackage, isTrue);
  });
}
