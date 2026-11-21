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
}
