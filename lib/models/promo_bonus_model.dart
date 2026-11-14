class PromoBonusRuleModel {
  final String id;
  final String name;
  final String daysOfWeek;
  final int minPaidMinutes;
  final int bonusMinutes;
  final String? validFrom;
  final String? validTo;
  final bool isActive;

  PromoBonusRuleModel({
    required this.id,
    required this.name,
    required this.daysOfWeek,
    required this.minPaidMinutes,
    required this.bonusMinutes,
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
        validFrom: j['validFrom'] as String?,
        validTo: j['validTo'] as String?,
        isActive: (j['isActive'] as bool?) ?? true,
      );

  /// Label hari ringkas: "Sabtu & Minggu".
  String get daysLabel {
    const names = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final days = daysOfWeek
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((d) => d >= 0 && d <= 6)
        .map((d) => names[d])
        .toList();
    if (days.isEmpty) return '-';
    if (days.length == 1) return days.first;
    return '${days.sublist(0, days.length - 1).join(', ')} & ${days.last}';
  }

  Map<String, dynamic> toBody() => {
        'name': name,
        'daysOfWeek': daysOfWeek,
        'minPaidMinutes': minPaidMinutes,
        'bonusMinutes': bonusMinutes,
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