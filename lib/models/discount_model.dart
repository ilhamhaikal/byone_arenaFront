/// Model untuk Discount Rule (aturan diskon otomatis dari backend)
class DiscountModel {
  final String id;
  final String name;
  /// Jenis aturan: always | happy_hour | member | day_of_week
  final String ruleType;
  /// Tipe diskon: percentage | fixed_amount
  final String discountType;
  final double discountValue;
  final int startHour;
  final int endHour;
  final String? daysOfWeek;
  final double minPurchase;
  final double maxDiscount;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiscountModel({
    required this.id,
    required this.name,
    required this.ruleType,
    required this.discountType,
    required this.discountValue,
    required this.startHour,
    required this.endHour,
    this.daysOfWeek,
    required this.minPurchase,
    required this.maxDiscount,
    required this.priority,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ruleType: json['ruleType'] as String,
      discountType: json['discountType'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
      startHour: json['startHour'] as int? ?? 0,
      endHour: json['endHour'] as int? ?? 0,
      daysOfWeek: json['daysOfWeek'] as String?,
      minPurchase: (json['minPurchase'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble() ?? 0.0,
      priority: json['priority'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static const List<String> ruleTypes = [
    'always',
    'happy_hour',
    'member',
    'day_of_week',
  ];

  String get ruleTypeLabel {
    switch (ruleType) {
      case 'always':
        return 'Selalu Aktif';
      case 'happy_hour':
        return 'Happy Hour';
      case 'member':
        return 'Member';
      case 'day_of_week':
        return 'Hari Tertentu';
      default:
        return ruleType;
    }
  }

  String get displayValue {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}%';
    }
    return 'Rp ${discountValue.toStringAsFixed(0)}';
  }
}
