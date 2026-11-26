class PromoBonusRuleModel {
  final String id;
  final String name;
  final String daysOfWeek;
  final int minPaidMinutes;
  final int bonusMinutes;
  final int maxPerSession; // 0 = bebas berulang
  final String audience; // general | member
  final String? validFrom;
  final String? validTo;
  final bool isActive;

  PromoBonusRuleModel({
    required this.id,
    required this.name,
    required this.daysOfWeek,
    required this.minPaidMinutes,
    required this.bonusMinutes,
    this.maxPerSession = 0,
    this.audience = 'general',
    this.validFrom,
    this.validTo,
    this.isActive = true,
  });

  factory PromoBonusRuleModel.fromJson(Map<String, dynamic> j) => PromoBonusRuleModel(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        daysOfWeek: (j['daysOfWeek'] as String?) ?? '',
        minPaidMinutes: (j['minPaidMinutes'] as num?)?.toInt() ?? 0,
        bonusMinutes: (j['bonusMinutes'] as num?)?.toInt() ?? 0,
        maxPerSession: (j['maxPerSession'] as num?)?.toInt() ?? 0,
        audience: (j['audience'] as String?) ?? 'general',
        validFrom: j['validFrom'] as String?,
        validTo: j['validTo'] as String?,
        isActive: (j['isActive'] as bool?) ?? true,
      );

  /// Label hari ringkas: "Sabtu & Minggu".
  String get daysLabel {
    const names = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final indexes = daysOfWeek
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .map((d) => d == 7 ? 0 : d)
        .where((d) => d >= 0 && d <= 6)
        .toSet()
        .toList()
      ..sort();
    final days = indexes.map((d) => names[d]).toList();
    if (days.isEmpty) return '-';
    if (days.length == 1) return days.first;
    return '${days.sublist(0, days.length - 1).join(', ')} & ${days.last}';
  }

  bool get isMemberAudience => audience == 'member';
  String get audienceLabel => isMemberAudience ? 'Member' : 'Umum';

  /// Aturan cadangan untuk tampilan bila permintaan ke server gagal.
  /// Hanya dipakai pada Sabtu/Minggu agar tidak memunculkan promo di hari lain.
  static PromoBonusRuleModel? weekendFallback({bool isMember = false}) {
    final wd = DateTime.now().weekday; // 6=Sabtu, 7=Minggu
    if (wd != 6 && wd != 7) return null;
    return PromoBonusRuleModel(
      id: '',
      name: isMember ? 'Bonus Weekend Member' : 'Bonus Weekend Umum',
      daysOfWeek: '0,6',
      minPaidMinutes: 60,
      bonusMinutes: isMember ? 60 : 30,
      audience: isMember ? 'member' : 'general',
      isActive: true,
    );
  }

  Map<String, dynamic> toBody() => {
        'name': name,
        'daysOfWeek': daysOfWeek,
        'minPaidMinutes': minPaidMinutes,
        'bonusMinutes': bonusMinutes,
        'maxPerSession': maxPerSession,
        'audience': audience,
        'validFrom': validFrom,
        'validTo': validTo,
        'isActive': isActive,
      };
}

class PromoReportModel {
  final int sessionsWithBonus;
  final int totalBonusMinutes;
  final List<PromoReportDay> daily;

  PromoReportModel({
    required this.sessionsWithBonus,
    required this.totalBonusMinutes,
    required this.daily,
  });

  factory PromoReportModel.fromJson(Map<String, dynamic> j) => PromoReportModel(
        sessionsWithBonus: (j['sessionsWithBonus'] as num?)?.toInt() ?? 0,
        totalBonusMinutes: (j['totalBonusMinutes'] as num?)?.toInt() ?? 0,
        daily: ((j['daily'] as List?) ?? [])
            .map((e) => PromoReportDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PromoReportDay {
  final String date;
  final int sessionsWithBonus;
  final int totalBonusMinutes;

  PromoReportDay({
    required this.date,
    required this.sessionsWithBonus,
    required this.totalBonusMinutes,
  });

  factory PromoReportDay.fromJson(Map<String, dynamic> j) => PromoReportDay(
        date: (j['date'] as String?) ?? '',
        sessionsWithBonus: (j['sessionsWithBonus'] as num?)?.toInt() ?? 0,
        totalBonusMinutes: (j['totalBonusMinutes'] as num?)?.toInt() ?? 0,
      );
}