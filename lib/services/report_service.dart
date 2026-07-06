import '../config/api_config.dart';
import '../models/report_summary_model.dart';
import 'api_service.dart';

class ReportService {
  final ApiService _api = ApiService();

  Future<ReportSummaryModel> getSummary({
    required String startDate,
    required String endDate,
  }) async {
    final res = await _api.get(ApiConfig.reportSummary, {
      'startDate': startDate,
      'endDate': endDate,
    });
    return ReportSummaryModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
