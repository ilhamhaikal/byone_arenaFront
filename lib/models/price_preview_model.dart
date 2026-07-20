class PriceBreakdownItem {
  final int minutes;
  final double pricePerHour;
  final double subtotal;
  final bool fallback;

  PriceBreakdownItem({
    required this.minutes,
    required this.pricePerHour,
    required this.subtotal,
    this.fallback = false,
  });

  factory PriceBreakdownItem.fromJson(Map<String, dynamic> json) {
    return PriceBreakdownItem(
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      fallback: json['fallback'] as bool? ?? false,
    );
  }
}

class PricePreviewModel {
  final double baseAmount;
  final List<PriceBreakdownItem> breakdown;

  PricePreviewModel({
    required this.baseAmount,
    required this.breakdown,
  });

  factory PricePreviewModel.fromJson(Map<String, dynamic> json) {
    return PricePreviewModel(
      baseAmount: (json['baseAmount'] as num?)?.toDouble() ?? 0,
      breakdown: (json['priceBreakdown'] as List<dynamic>?)
              ?.map((e) =>
                  PriceBreakdownItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
