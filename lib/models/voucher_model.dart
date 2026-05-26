class VoucherModel {
  final String id;
  final String code;
  final String name;
  final String discountType; // 'percentage', 'fixed_amount'
  final double discountValue;
  final double? maxDiscount; // batas maks diskon persen (0 = tidak terbatas)
  final double? minPurchase; // minimal total sebelum voucher berlaku
  final int maxUsage; // 0 = tidak terbatas
  final int usageCount;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VoucherModel({
    required this.id,
    required this.code,
    required this.name,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.minPurchase,
    required this.maxUsage,
    required this.usageCount,
    this.expiresAt,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      discountType: json['discountType'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
      maxDiscount: json['maxDiscount'] != null
          ? (json['maxDiscount'] as num).toDouble()
          : null,
      minPurchase: json['minPurchase'] != null
          ? (json['minPurchase'] as num).toDouble()
          : null,
      maxUsage: (json['maxUsage'] as num?)?.toInt() ?? 0,
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'discountType': discountType,
        'discountValue': discountValue,
        if (maxDiscount != null) 'maxDiscount': maxDiscount,
        if (minPurchase != null) 'minPurchase': minPurchase,
        'maxUsage': maxUsage,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        'isActive': isActive,
      };

  String get displayValue {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}%';
    }
    return 'Rp ${discountValue.toStringAsFixed(0)}';
  }

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isAvailable =>
      isActive &&
      !isExpired &&
      (maxUsage == 0 || usageCount < maxUsage);
  int get remainingUsage => maxUsage == 0 ? -1 : maxUsage - usageCount;
}
