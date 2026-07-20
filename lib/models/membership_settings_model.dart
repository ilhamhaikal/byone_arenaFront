class MembershipSettingsModel {
  final double membershipPrice;
  final DateTime? updatedAt;

  MembershipSettingsModel({
    required this.membershipPrice,
    this.updatedAt,
  });

  factory MembershipSettingsModel.fromJson(Map<String, dynamic> json) {
    final raw = json['membershipPrice'];
    double price;
    if (raw is num) {
      price = raw.toDouble();
    } else if (raw is String) {
      price = double.tryParse(raw) ?? 0;
    } else {
      price = 0;
    }
    return MembershipSettingsModel(
      membershipPrice: price,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
