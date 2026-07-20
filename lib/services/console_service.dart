import '../config/api_config.dart';
import '../models/console_model.dart';
import '../models/console_overview_model.dart';
import '../models/price_preview_model.dart';
import 'api_service.dart';

class ConsoleService {
  final ApiService _api = ApiService();

  Future<List<ConsoleModel>> getAll() async {
    final response = await _api.get(ApiConfig.consoles);
    final list = response['data'] as List<dynamic>;
    return list.map((e) => ConsoleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ConsoleModel>> getAvailable() async {
    final response = await _api.get(ApiConfig.availableConsoles);
    final list = response['data'] as List<dynamic>;
    return list.map((e) => ConsoleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ConsoleOverviewModel>> getOverview() async {
    final response = await _api.get(ApiConfig.consolesOverview);
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => ConsoleOverviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConsoleModel> getById(String id) async {
    final response = await _api.get('${ApiConfig.consoles}/$id');
    return ConsoleModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ConsoleModel> create({
    required String name,
    required String consoleType,
    required double pricePerHour,
    String? description,
    String? ipAddress,
    List<Map<String, dynamic>>? pricingTiers,
    double? dailyPrice,
  }) async {
    final response = await _api.post(ApiConfig.consoles, {
      'name': name,
      'consoleType': consoleType,
      'pricePerHour': pricePerHour,
      if (description != null) 'description': description,
      if (ipAddress != null && ipAddress.isNotEmpty) 'ipAddress': ipAddress,
      if (pricingTiers != null && pricingTiers.isNotEmpty)
        'pricingTiers': pricingTiers,
      if (dailyPrice != null && dailyPrice > 0) 'dailyPrice': dailyPrice,
    });
    return ConsoleModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ConsoleModel> update(String id, Map<String, dynamic> fields) async {
    final response = await _api.put('${ApiConfig.consoles}/$id', fields);
    return ConsoleModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConfig.consoles}/$id');
  }

  // ── Price Preview ──────────────────────────────────────────────────────
  Future<PricePreviewModel> getPrice(String consoleId,
      {required int durationMinutes, String? voucherCode, String? customerId}) async {
    final params = <String, String>{
      'duration': durationMinutes.toString(),
    };
    if (voucherCode != null && voucherCode.isNotEmpty) {
      params['voucherCode'] = voucherCode;
    }
    if (customerId != null && customerId.isNotEmpty) {
      params['customerId'] = customerId;
    }
    final response = await _api.get(
        '${ApiConfig.consoles}/$consoleId/price', params);
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return PricePreviewModel.fromJson(data);
    }
    throw ApiException('Response price tidak valid', 500);
  }

  // ── TV Control ──────────────────────────────────────────────────────────
  Future<void> wake(String id) async {
    await _api.post('${ApiConfig.consoles}/$id/wake', {});
  }

  Future<void> sleep(String id) async {
    await _api.post('${ApiConfig.consoles}/$id/sleep', {});
  }
}
