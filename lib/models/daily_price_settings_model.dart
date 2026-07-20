class DailyPriceSettingsModel {
  final double dailyPrice;
  final DateTime? updatedAt;

  DailyPriceSettingsModel({
    required this.dailyPrice,
    this.updatedAt,
  });

  factory DailyPriceSettingsModel.fromJson(Map<String, dynamic> json) {
    final raw = json['dailyPrice'];
    double price;
    if (raw is num) {
      price = raw.toDouble();
    } else if (raw is String) {
      price = double.tryParse(raw) ?? 0;
    } else {
      price = 0;
    }
    return DailyPriceSettingsModel(
      dailyPrice: price,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
