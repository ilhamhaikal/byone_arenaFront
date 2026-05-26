class DiscountModel {
  final int id;
  final String name;
  final String description;
  final String discountType; // 'percentage', 'fixed'
  final double discountValue;
  final double? minTransaction;
  final String? membershipType; // null = all members
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  DiscountModel({
    required this.id,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minTransaction,
    this.membershipType,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      discountType: json['discount_type'],
      discountValue: (json['discount_value'] as num).toDouble(),
      minTransaction: json['min_transaction'] != null
          ? (json['min_transaction'] as num).toDouble()
          : null,
      membershipType: json['membership_type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_transaction': minTransaction,
        'membership_type': membershipType,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'is_active': isActive,
      };

  String get displayValue {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}%';
    }
    return 'Rp ${discountValue.toStringAsFixed(0)}';
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
}
