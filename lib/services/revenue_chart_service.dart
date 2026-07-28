import '../config/api_config.dart';
import '../models/revenue_chart_item.dart';
import 'api_service.dart';

class RevenueChartService {
  final ApiService _api = ApiService();

  Future<List<RevenueChartItem>> getChart({int days = 7}) async {
    final response = await _api.get(
      ApiConfig.dashboardRevenueChart,
      {'days': days.toString()},
    );
    final data = response['data'];
    if (data is List) {
      return data
          .map((e) => RevenueChartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
