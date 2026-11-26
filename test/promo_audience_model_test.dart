import 'package:flutter_test/flutter_test.dart';

import 'package:kiosk_ps/models/promo_bonus_model.dart';

void main() {
  test('7 diterima sebagai alias Minggu pada label hari', () {
    final rule = PromoBonusRuleModel(
      id: 'r1',
      name: 'Bonus Weekend',
      daysOfWeek: '6,7',
      minPaidMinutes: 60,
      bonusMinutes: 30,
    );

    expect(rule.daysLabel, contains('Sabtu'));
    expect(rule.daysLabel, contains('Minggu'));
  });

  test('audience member ikut dikirim ke backend', () {
    final rule = PromoBonusRuleModel(
      id: 'r2',
      name: 'Bonus Weekend Member',
      daysOfWeek: '0,6',
      minPaidMinutes: 60,
      bonusMinutes: 60,
      audience: 'member',
    );

    expect(rule.isMemberAudience, isTrue);
    expect(rule.audienceLabel, 'Member');
    expect(rule.toBody()['audience'], 'member');
  });
}