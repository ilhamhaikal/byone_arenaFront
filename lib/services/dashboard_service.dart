import '../config/api_config.dart';
import '../models/dashboard_summary_model.dart';
import 'api_service.dart';

class DashboardService {
  final ApiService _api = ApiService();

  Future<DashboardSummaryModel> getSummary() async {
    final response = await _api.get(ApiConfig.dashboardSummary);
    return DashboardSummaryModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }
}
