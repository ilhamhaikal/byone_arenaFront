/// Model untuk entity.PricingTierEntry — tarif bertingkat per jam
class PricingTierEntry {
  final int startMinute; // menit mulai tier (inklusif)
  final int? endMinute; // menit akhir tier (eksklusif), null = unlimited
  final double price; // harga per jam untuk tier ini

  PricingTierEntry({
    required this.startMinute,
    this.endMinute,
    required this.price,
  });

  factory PricingTierEntry.fromJson(Map<String, dynamic> json) {
    return PricingTierEntry(
      startMinute: (json['startMinute'] as num?)?.toInt() ?? 0,
      endMinute: (json['endMinute'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'startMinute': startMinute,
        if (endMinute != null) 'endMinute': endMinute,
        'price': price,
      };

  String get label {
    final startH = startMinute ~/ 60;
    final startM = startMinute % 60;
    if (endMinute == null) {
      return '≥ ${startH}j ${startM}m';
    }
    final endH = endMinute! ~/ 60;
    final endM = endMinute! % 60;
    return '${startH}j$startM - ${endH}j$endM';
  }
}
