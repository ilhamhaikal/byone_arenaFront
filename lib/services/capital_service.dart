import '../config/api_config.dart';
import '../models/capital_model.dart';
import 'api_service.dart';

class CapitalService {
  final ApiService _api = ApiService();

  Future<CapitalEntryModel> addEntry(Map<String, dynamic> data) async {
    final res = await _api.post(ApiConfig.capital, data);
    return CapitalEntryModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> deleteEntry(String id) async {
    await _api.delete('${ApiConfig.capital}/$id');
  }

  Future<List<CapitalEntryModel>> listEntries({
    String? startDate,
    String? endDate,
  }) async {
    final res = await _api.get(ApiConfig.capital, {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    });
    final List data = res['data'] ?? [];
    return data
        .map((e) => CapitalEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MonthlyCapitalModel>> monthly() async {
    final res = await _api.get(ApiConfig.capitalMonthly);
    final List data = res['data'] ?? [];
    return data
        .map((e) => MonthlyCapitalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
