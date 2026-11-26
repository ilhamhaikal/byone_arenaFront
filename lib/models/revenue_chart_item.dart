/// Model untuk GET /api/v1/dashboard/revenue-chart response item.
///
/// Grafik menampilkan tiga seri dalam satu chart:
/// - [rentalRevenue]     : sewa konsol (sesi) + rental harian
/// - [membershipRevenue] : penjualan membership
/// - [foodRevenue]       : penjualan makanan/minuman
class RevenueChartItem {
  final String date;
  final double revenue; // total (rental + membership + food)
  final double rentalRevenue;
  final double membershipRevenue;
  final double foodRevenue;
  final int sessions;

  RevenueChartItem({
    required this.date,
    required this.revenue,
    this.rentalRevenue = 0,
    this.membershipRevenue = 0,
    this.foodRevenue = 0,
    required this.sessions,
  });

  factory RevenueChartItem.fromJson(Map<String, dynamic> json) {
    final rental = (json['rentalRevenue'] as num?)?.toDouble() ?? 0;
    final member = (json['membershipRevenue'] as num?)?.toDouble() ?? 0;
    final food = (json['foodRevenue'] as num?)?.toDouble() ?? 0;
    return RevenueChartItem(
      date: (json['date'] as String?) ?? '',
      rentalRevenue: rental,
      membershipRevenue: member,
      foodRevenue: food,
      // Fallback untuk backend lama.
      revenue: (json['revenue'] as num?)?.toDouble() ??
          (rental + member + food),
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
    );
  }
}
