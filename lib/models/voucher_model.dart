class VoucherModel {
  final int id;
  final String code;
  final String name;
  final String discountType; // 'percentage', 'fixed'
  final double discountValue;
  final double? minTransaction;
  final int maxUsage;
  final int usedCount;
  final DateTime expiredAt;
  final bool isActive;

  VoucherModel({
    required this.id,
    required this.code,
    required this.name,
    required this.discountType,
    required this.discountValue,
    this.minTransaction,
    required this.maxUsage,
    required this.usedCount,
    required this.expiredAt,
    required this.isActive,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      discountType: json['discount_type'],
      discountValue: (json['discount_value'] as num).toDouble(),
      minTransaction: json['min_transaction'] != null
          ? (json['min_transaction'] as num).toDouble()
          : null,
      maxUsage: json['max_usage'],
      usedCount: json['used_count'] ?? 0,
      expiredAt: DateTime.parse(json['expired_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_transaction': minTransaction,
        'max_usage': maxUsage,
        'expired_at': expiredAt.toIso8601String(),
        'is_active': isActive,
      };

  String get displayValue {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}%';
    }
    return 'Rp ${discountValue.toStringAsFixed(0)}';
  }

  bool get isExpired => DateTime.now().isAfter(expiredAt);
  bool get isAvailable => isActive && !isExpired && usedCount < maxUsage;
  int get remainingUsage => maxUsage - usedCount;
}
