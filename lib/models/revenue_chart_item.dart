/// Model untuk GET /api/v1/dashboard/revenue-chart response item.
///
/// Grafik menampilkan dua seri dalam satu chart:
/// - [rentalRevenue] : sewa konsol (sesi) + rental harian (+ membership)
/// - [foodRevenue]   : penjualan makanan/minuman
class RevenueChartItem {
  final String date;
  final double revenue; // total (rental + food)
  final double rentalRevenue;
  final double foodRevenue;
  final int sessions;

  RevenueChartItem({
    required this.date,
    required this.revenue,
    this.rentalRevenue = 0,
    this.foodRevenue = 0,
    required this.sessions,
  });

  factory RevenueChartItem.fromJson(Map<String, dynamic> json) {
    final rental = (json['rentalRevenue'] as num?)?.toDouble() ?? 0;
    final food = (json['foodRevenue'] as num?)?.toDouble() ?? 0;
    return RevenueChartItem(
      date: (json['date'] as String?) ?? '',
      rentalRevenue: rental,
      foodRevenue: food,
      // Fallback: bila backend lama belum mengirim rentalRevenue/foodRevenue,
      // pakai 'revenue' sebagai seri rental agar grafik tetap tampil.
      revenue: (json['revenue'] as num?)?.toDouble() ?? (rental + food),
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
    );
  }
}
