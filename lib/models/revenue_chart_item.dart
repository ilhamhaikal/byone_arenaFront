/// Model untuk GET /api/v1/dashboard/revenue-chart response item.
class RevenueChartItem {
  final String date;
  final double revenue;
  final int sessions;

  RevenueChartItem({
    required this.date,
    required this.revenue,
    required this.sessions,
  });

  factory RevenueChartItem.fromJson(Map<String, dynamic> json) {
    return RevenueChartItem(
      date: (json['date'] as String?) ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
    );
  }
}
